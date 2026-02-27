import EntryAbility from '../entryability/EntryAbility';
import { AnalysisListener } from '../listeners/AnalysisListener';
import  util  from '@ohos.util';
import {WifiCommandHelper} from '../helper/WifiCommandHelper';




/*class ConcreteAnalysisListener implements AnalysisListener {
  // 持有WelcomePage实例，用于访问@State变量
  private page: WelcomePage;

  // 构造函数接收页面实例
  constructor(page: WelcomePage) {
    this.page = page;
  }

  // 实现接口的回调方法：接收数据并更新页面
  data(type: number, data: Uint8Array): void {
    if (type==1) {
      const uint8:Uint8Array = new Uint8Array([data[4],data[5]]);
      this.page.displayData=new util.TextDecoder().decode(uint8)
    }
    console.log(`处理数据类型：${type}，数据长度：${data.length}+数据${data[4]}+数据${data[5]}`);

    // 2. 更新页面的响应式状态（触发UI刷新）

  }
}*/

@Entry
struct WelcomePage  {

  @State displayData: string = "等待数据";
  @State dataLength: number = 0;


  @StorageLink('udpMessage') udpMessage: string | null = null; // 监听UDP消息

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
              // this.sendUdp(0X0F.toString())
              //EntryAbility.getInstance().writeUDPCmd(0x0f)
              /*  EntryAbility.getInstance().sendUdpMessage(0x0f.toString())
                EntryAbility.getInstance().sendUdpMessage(0x0f.toString())*/
              setInterval(() => {
                WifiCommandHelper.getVersion()
                WifiCommandHelper.getDevType()
              }, 500);

            })


            Text(`收到udp消息：${this.displayData}`)


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



}