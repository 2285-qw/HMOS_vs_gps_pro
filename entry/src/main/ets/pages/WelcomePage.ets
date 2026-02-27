import EntryAbility from '../entryability/EntryAbility';
import { AnalysisListener } from '../listeners/AnalysisListener';
import util from '@ohos.util';
import { WifiCommandHelper } from '../helper/WifiCommandHelper';
import NapiBuffer from 'libentry.so';
import { MimeType } from '../utils/VideoUtil'
import { fileIo as fs } from '@kit.CoreFileKit'; // 标准写法
import ability from '@ohos.ability.ability';
import taskpool from '@ohos.taskpool';
import { window, promptAction } from '@kit.ArkUI';

import resourceManager from '@ohos.resourceManager';
import router from '@ohos.router';
import commonEventManager from '@ohos.commonEventManager';
import prompt from '@ohos.prompt';

import Ability from '@ohos.app.ability.Ability';
import { PlayInfo } from '../model/PlayInfo';
import { PermissionRequestUtil } from '../utils/PermissionRequestUtil';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';

import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { dataSharePredicates } from '@kit.ArkData';
import  picker  from '@kit.MediaLibraryKit';



// 定义函数类型
type SendUdpMessageFunc = (data: string) => void;


/*class ConcreteAnalysisListener implements AnalysisListener {
  // 持有WelcomePage实例，用于访问@State变量
  private page: WelcomePage;

  // 构造函数接收页面实例
  constructor(page: WelcomePage) {
    this.page = page;
  }

  // 实现接口的回调方法：接收数据并更新页面
  data(type: number, data: Uint8Array): void {
    if (type == 1) {
      const uint8: Uint8Array = new Uint8Array([data[4], data[5]]);
      //this.page.displayData=new util.TextDecoder().decode(uint8)
    }
    console.log(`处理数据类型：${type}，数据长度：${data.length}+数据${data[4]}+数据${data[5]}`);

    // 2. 更新页面的响应式状态（触发UI刷新）

  }
}*/

@Entry
struct WelcomePage {
  @State displayData: string = "等待数据";
  @State dataLength: number = 0;
  @StorageLink('udpMessage') udpMessage: string | null = null; // 监听UDP消息
  private sendUdp: SendUdpMessageFunc = AppStorage.Get('sendUdpMessage') as SendUdpMessageFunc; // 获取发送方法
  @State message: string = 'Hello World';
  @State currentIndex: number = 0;

  /*  private listener: AnalysisListener = {
      data:(type: number, data: Uint8Array)=> {
        // 实现逻辑
      }

    } ;*/

  aboutToAppear() {
    console.log('WelcomePage：开始渲染'); // 看DevEco Studio的Logcat是否输出
   // EntryAbility.getInstance().setAnalysisListener(new ConcreteAnalysisListener(this))

  /*  let photoPicker = new photoAccessHelper.PhotoViewPicker();
    let options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE; // 仅选择图片
    options.maxSelectNumber = 5; // 最多选5张

    try {
      photoPicker.select(options).then((result: photoAccessHelper.PhotoSelectResult) => {
        console.info('选择成功，结果集: ' + JSON.stringify(result.photoUris)); // 返回图片URI数组
      }).catch((err: BusinessError) => {
        console.error('选择失败，错误码: ' + err.code + ', 错误信息: ' + err.message);
      });
    } catch (error) {
      let err = error as BusinessError;
      console.error('捕获异常，错误码: ' + err.code);
    }*/
    this.queryDemo()
  }

  aboutToDisappear() {

  }

  onPageShow(): void {
    window.getLastWindow(this.getUIContext().getHostContext(), (err, data) => {
      data.setWindowLayoutFullScreen(true) // 进入沉浸式
    });
    window.getLastWindow(this.getUIContext().getHostContext(), (err, data) => {
      data.setPreferredOrientation(window.Orientation.PORTRAIT); // 强制竖屏
    });
    this.getPlayInfo();
  }

  // 页面隐藏时恢复横屏
  onPageHide(): void {
    window.getLastWindow(this.getUIContext().getHostContext(), (err, data) => {
      try {
        data.setPreferredOrientation(window.Orientation.LANDSCAPE); // 恢复横屏
      } catch (e) {
      }

    });


  }

  @Builder
  tabBuilder(title: string, targetIndex: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
        .size({ width: 25, height: 25 })
      Text(title)
        .fontColor(this.currentIndex === targetIndex ? '#2C97DE' : '#66000000')
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    RelativeContainer() {
      Tabs({ barPosition: BarPosition.End }) {
        TabContent() {
          RelativeContainer() {
            Image($r('app.media.ic_welcome_bg'))
              .gesture(
                LongPressGesture({ repeat: true })
                  .onAction((event: GestureEvent) => {
                    // 长按触发（持续触发）
                    router.pushUrl({
                      url: 'pages/LogExportPage'  // 目标页路径
                    }, router.RouterMode.Standard, (err) => { // Standard模式可省略
                      if (err) {
                        console.error(`跳转失败: ${err.message}`);
                      }
                    });
                    console.log("长按中...");
                  })
                  .onActionEnd(() => {
                    // 长按结束

                    console.log("长按结束");
                  })
              ).onClick(() => {

              router.pushUrl({
                url: 'pages/LogExportPage'  // 目标页路径
              }, router.RouterMode.Standard, (err) => { // Standard模式可省略
                if (err) {
                  console.error(`跳转失败: ${err.message}`);
                }
              });
            })

            Stack() {
              // 背景图（底层）
              Image($r("app.media.ic_control_play")) // 引用本地图片资源
                .width(120)
                .height(40)
                .objectFit(ImageFit.Auto) // 图片缩放模式
              /*  // 文本（上层）
                Text('开启飞行之旅')
                  .fontColor(Color.White)*/
            }.alignRules({
              bottom: { anchor: "__container__", align: VerticalAlign.Bottom },
              middle: { anchor: "__container__", align: HorizontalAlign.Center }
            }).margin({ bottom: 30 })
            .onClick(() => {

              /*  router.pushUrl({
                  url: 'pages/BasePage'  // 目标页路径
                }, router.RouterMode.Standard, (err) => {  // Standard模式可省略
                  if (err) console.error(`跳转失败: ${err.message}`);
                });
  */


              const permissionResults = PermissionRequestUtil.checkAndRequestPermissions(['ohos.permission.WRITE_MEDIA',
                'ohos.permission.READ_MEDIA'], getContext(this) as Context).then()
              // 假设 getPermissionStatusList 是返回目标 Promise 的方法
              permissionResults.then((result: Array<[Permissions, abilityAccessCtrl.GrantStatus]>) => {

                let isR = true;

                // 遍历结果数组
                result.forEach((permission, grantStatus) => {
                  if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
                    isR = false;
                  }
                  console.info(`权限名: ${permission}, 授权状态: ${grantStatus}`);
                });

                if (isR) {
                  //有权限跳转页面
                  router.pushUrl({
                    url: 'pages/LanGuangPage'  // 目标页路径
                  }, router.RouterMode.Standard, (err) => { // Standard模式可省略
                    if (err) {
                      console.error(`跳转失败: ${err.message}`);
                    }
                  });
                } else {
                  //没有权限
                  promptAction.showToast({
                    message: '请同意对应权限',
                    duration: 2000, // 显示时长（毫秒）
                    bottom: '50vp'   // 距屏幕底部距离
                  });

                }

              }).catch((err: BusinessError) => {
                console.error(`查询失败, 错误码: ${err.code}, 错误信息: ${err.message}`);
              });


              /* router.pushUrl({
                 url: 'pages/UsbMonitorComponent'  // 目标页路径
               }, router.RouterMode.Standard, (err) => {  // Standard模式可省略
                 if (err) console.error(`跳转失败: ${err.message}`);
               });*/

              /*   router.pushUrl({
                 url: 'pages/Index'  // 目标页路径
               }, router.RouterMode.Standard, (err) => {  // Standard模式可省略
                 if (err) console.error(`跳转失败: ${err.message}`);
               });*/


            })


            Text(`firmware ver：${this.displayData}`).alignRules({}).margin({ top: 40 })


          }.width('100%')
          .height('100%')
        }.tabBar(this.tabBuilder('操作', 0, $r('app.media.ic_control_press'), $r('app.media.ic_control_normal')))

        TabContent() {

        }.tabBar(this.tabBuilder('图库', 1, $r('app.media.ic_gallery_press'), $r('app.media.ic_gallery_normal')))

        TabContent() {
          RelativeContainer() {
            Column() {
              Text('帮助')
                .width('100%')
                .textAlign(TextAlign.Center)
                .fontColor('#000000')
                .backgroundColor('#ffffffff')
                .padding({ top: 10, bottom: 10 })

              Text('找飞机')
                .width('100%')
                .textAlign(TextAlign.Start)
                .fontColor('#000000')
                .backgroundColor('#ffffffff')
                .padding({ top: 10, bottom: 10, left: 20 })
                .margin({ top: 10 })
              Text('飞行记录')
                .width('100%')
                .textAlign(TextAlign.Start)
                .fontColor('#000000')
                .backgroundColor('#ffffffff')
                .padding({ top: 10, bottom: 10, left: 20 })
                .margin({ top: 10 })
              Text('帮助图')
                .width('100%')
                .textAlign(TextAlign.Start)
                .fontColor('#000000')
                .backgroundColor('#ffffffff')
                .padding({ top: 10, bottom: 10, left: 20 })
                .margin({ top: 10 })
              Text('语言选择')
                .width('100%')
                .textAlign(TextAlign.Start)
                .fontColor('#000000')
                .backgroundColor('#ffffffff')
                .padding({ top: 10, bottom: 10, left: 20 })
                .margin({ top: 10 })
              Text('扫一扫')
                .width('100%')
                .textAlign(TextAlign.Start)
                .fontColor('#000000')
                .backgroundColor('#ffffffff')
                .padding({ top: 10, bottom: 10, left: 20 })
                .margin({ top: 10 })

            }.width('100%')

            Text('ICP备案号：粤ICP备2013150355号-1A').alignRules({
              bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
            }).textAlign(TextAlign.Center).width('100%').margin({ bottom: 20 })
          }.width('100%').height('100%').backgroundColor('#fff3f4f5')

        }.tabBar(this.tabBuilder('帮助', 2, $r('app.media.ic_help_press'), $r('app.media.ic_help_normal')))

      }.scrollable(false)
      .onSelected((index: number) => {
        this.currentIndex = index;
      })
    }
    .height('100%')
    .width('100%')
  }

  public readHexFile(): Uint8Array | null {
    try {
      // 获取resourceManager对象
      const context = getContext(this);
      const resourceMgr = context.resourceManager;

      // 获取rawfile目录下的文件描述符
      let fileDescriptor: Uint8Array = resourceMgr.getRawFileContentSync('1111.logbin');

      return fileDescriptor;
    } catch (error) {
      console.error('Failed to read hex file: ' + error);
    }
    return null;
  }

  private getPlayInfo() {
    // 获取主线程任务分发器（UI线程）
    // 定义周期性任务

    // 每1000ms（1秒）执行一次
    const intervalId = setInterval(() => {
      this.setfirVersion();
    }, 1000, 20);

    // 取消定时任务
    // clearInterval(intervalId);

  }

  private setfirVersion() {
    this.displayData = PlayInfo.firmwareVer;
    //console.log('获取版本号: ' + PlayInfo.firmwareVer);
  }

  queryDemo() {
  try {
    // 1. 初始化Predicates
    let predicates = new dataSharePredicates.DataSharePredicates();


    predicates.equalTo(photoAccessHelper.PhotoKeys.PHOTO_TYPE,
      photoAccessHelper.PhotoType.IMAGE);

    // 设置筛选条件
  //  predicates.equalTo(photoAccessHelper.PhotoKeys.DISPLAY_NAME, "img"); // 名称包含"img
    // 设置文件名包含"img"的条件
   // predicates.equalTo('displayName', 'img'); // 关键参数：displayName表示文件名


    // 示例1：按相册名称筛选
    //predicates.equalTo(photoAccessHelper.AlbumKeys.ALBUM_NAME, 'label');

    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext(this));


    // 2. 配置FetchOptions
    let fetchOptions: photoAccessHelper.FetchOptions = {
      predicates: predicates,
      fetchColumns: ['uri']
    };

    // 3. 执行查询
    let fetchResult =  phAccessHelper.getAssets(fetchOptions);
    let asset =  fetchResult.then((router:photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset>)=>{
      router.getAllObjects().then((all:Array<photoAccessHelper.PhotoAsset>)=>{
        //得到所有的图片信息
        console.error(`获取图片数量===`, all.length);
      })
      router.getCount()
      console.error(`获取图片数量`, router.getCount());
    })
  } catch (err) {
    console.error(`Error code ${err.code}: ${err.message}`);
  }
}



}