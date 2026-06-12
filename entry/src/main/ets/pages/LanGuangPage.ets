import { LanGuangObserver } from '../macrochip/Drone/observer/LanGuangObserver';
import EntryAbility from '../entryability/EntryAbility';
import { VideoPage } from './VideoPage';
import { common } from '@kit.AbilityKit';
import { emitter } from '@kit.BasicServicesKit';
import { ProtocolManager } from '../macrochip/Drone/core/protocol/ProtocolManager';
import { Protocol } from '../macrochip/Drone/core/protocol/Protocol';
import { ModeType, PageSendData } from '../macrochip/Drone/core/protocol/PageSendData';
import { LanGuangAnalysis } from '../macrochip/FunctionalAnalysis/LanGuangAnalysis';
import { LGPlaneHyBean } from '../macrochip/mode/LGPlaneHyBean';
import { SJHyInfo9CBean } from '../macrochip/mode/SJHyInfo9CBean';
import { LGPlaneGpsBean } from '../macrochip/mode/LGPlaneGpsBean';
import { LGGetFlyLineBean } from '../macrochip/mode/LGGetFlyLineBean';
import { LGInfo3HyBean } from '../macrochip/mode/LGInfo3HyBean';
import { LGInfo3BHyBean } from '../macrochip/mode/LGInfo3BHyBean';
import { LGTestBean } from '../macrochip/mode/LGTestBean';
import { LGPlaneGpsBean2 } from '../macrochip/mode/LGPlaneGpsBean2';
import { SJHyGetSettingBean } from '../macrochip/mode/SJHyGetSettingBean';
import { HyABBean } from '../macrochip/mode/HyABBean';
import { SJHyInfo9BBean } from '../macrochip/mode/SJHyInfo9BBean';
import { SendHyControlThread } from '../macrochip/thread/SendHyControlThread';
import { App, ComponentContent, router, UIContext } from '@kit.ArkUI';
import { SlideUnLockView } from '../macrochip/components/SlideUnLockView';
import { buildText } from '../macrochip/Dialog/sliderDialog';
import { Params, ParamsBuilder, Type } from '../macrochip/Dialog/DialogDataType/Params';
import { buildLeftMore } from '../macrochip/Dialog/LeftMoreDialog';
import { MoreParams } from '../macrochip/Dialog/DialogDataType/MoreParams';
import { MoreType } from '../macrochip/More/MoreType';
import { SettingType, RIGHT_DRAWER_PAGE_TYPES, getSettingTypeName } from '../model/SettingType';
import { WifiUtils } from '../utils/WifiUtils';
import { ObjectUtils } from '../utils/ObjectUtils';
import { Data } from '../macrochip/Dialog/setting/Data';
import { SendSettingParamsUtils } from '../macrochip/utils/SendSettingParamsUtils';
import { SettingCalibration } from '../macrochip/Dialog/setting/SettingCalibration';
import { MessageWhat } from '../macrochip/constant/MessageWhat';
import { CalibrationDialog } from '../macrochip/Dialog/CalibrationDialog';
import { CalibrationParams } from '../macrochip/Dialog/DialogDataType/CalibrationParams';
import { FunctionHelper } from '../helper/FunctionHelper';
import { geoLocationManager } from '@kit.LocationKit';
import { LgFollowThread } from '../macrochip/thread/LgFollowThread';
import { MoreBean } from '../macrochip/More/MoreBean';
import { SendEmitterUtil } from '../utils/SendEmitterUtil';
import { CompassView } from '../components/CompassView';
import { MapPage } from './MapPage';
import NapiBuffer, { VideoFrame } from 'libentry.so';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import fs from '@ohos.file.fs';
import { Resolution } from '../model/PlayInfo';
import { Mode, ShootButton } from '../macrochip/view/ShootButton';
import { buildShootingSelectionDialog } from '../macrochip/Dialog/ShootingSelectionDialog';
import { ShootingSelectionParams, ShootingType } from '../macrochip/Dialog/DialogDataType/ShootingSelectionParams';
import { Utils } from '../macrochip/utils/Utils';
import { RouteHelper } from '../macrochip/utils/RouteHelper';
import { PageNewSendData } from '../macrochip/Drone/core/protocol/PageNewSendData';
import { map } from '@kit.MapKit';
import { LGFlyLineBean } from '../macrochip/mode/LGFlyLineBean';
import { AnimType, SlideAnimParams, SlideAnimParamsBuilder } from '../macrochip/Dialog/DialogDataType/SlideAnimParams';
import { buildSlideAnim } from '../macrochip/Dialog/SlideAnimDialog';
import { TFConsumer } from '../macrochip/utils/TFConsumer';
import { SwitchType } from '../model/SwitchType';


@Entry
@Component
struct LanGuangPage {
  //修改ui变量
  @State drone_power_level: Resource = $r('app.media.ic_plane_power_0'); //飞机电量
  @State rc_power_level: Resource = $r('app.media.ic_rc_power_0'); //遥控器电量
  @State wif_level: Resource = $r('app.media.ic_level');
  @State gps_level: Resource = $r('app.media.ic_level'); //gps数量等级
  @State top_title: string = ''; //头部显示文本
  @State currentMode: Mode = Mode.PHOTO; //拍照模式
  @State isRecording: boolean = false; //是否录像中
  @State TF_S?: string = ''; //tf卡状态
  // 右侧弹窗：是否显示、当前选中的类型（用类型驱动右侧页面，确保点击左侧能切换）
  @State showRightDrawer: boolean = false;
  @State rightDrawerSelectedType: SettingType = SettingType.DATA;
  @State isExpanded: boolean = false; //层级显示
  @State isMap: boolean = false; //是否显示地图
  textTimerController: TextTimerController = new TextTimerController() //计时器控件
  @State format: string = 'mm:ss.SS'
  @State isDeleteWaypoint: Visibility = Visibility.None; //删除航点两个view显示状态
  //参数变量
  private lastBatPer: number = 101;
  private showDefaultMessage: boolean = true;
  private currentMsg: string = '';
  private abilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private sendHyControlThread?: SendHyControlThread; //控制线程
  // 在组件或Ability中获取UIContext
  private uiContext: UIContext = this.getUIContext(); // 组件内使用
  private router = this.uiContext.getRouter(); // 获取绑定当前上下文的Router对象
  private dialogId?: ComponentContent<object> = undefined; //校准弹窗id
  private DialogType: number = 0;
  private callback?: Callback<geoLocationManager.Location>;
  private lgFollowThread?: LgFollowThread;
  private data?: MoreParams; //左侧列表数据
  private isRecord: boolean = false; //是否录制中
  private file: fs.File | null = null; //录像文件
  @State flyHeight: number = 0; //高度

  build() {
    Stack() {
      RelativeContainer() {
        MapPage({
          isDeleteWaypoint: this.isDeleteWaypoint
        })
          .zIndex(this.isExpanded ? 2 : 3)
          .width(this.isExpanded ? '100%' : 160)
          .height(this.isExpanded ? '100%' : 80)
          .alignRules({
            // 垂直居中
            bottom: {
              anchor: '__container__',
              align: VerticalAlign.Bottom
            }
          })
          .visibility((this.isExpanded || this.isMap) ? Visibility.Visible : Visibility.None)
          .margin({ left: this.isExpanded ? 0 : 30, bottom: this.isExpanded ? 0 : 10 })
        VideoPage()
          .zIndex(this.isExpanded ? 3 : 2)
          .width(!this.isExpanded ? '100%' : 160)
          .height(!this.isExpanded ? '100%' : 80)
          .alignRules({
            // 垂直居中
            bottom: {
              anchor: '__container__',
              align: VerticalAlign.Bottom
            }
          })
          .margin({ left: !this.isExpanded ? 0 : 30, bottom: !this.isExpanded ? 0 : 10 })
          .visibility((!this.isExpanded || this.isMap) ? Visibility.Visible : Visibility.None);
      }

      RelativeContainer() {
        //头部栏
        Row() {
          Row() {
            Image($r('app.media.ic_back'))
              .width(30)
              .height(30)
              .margin({ left: 20 })
              .objectFit(ImageFit.ScaleDown)
              .onClick(() => {
                // 关闭当前页面并返回上一页
                this.router.back(); // 组件内使用
              })
            Text('N/A').fontColor('#ffffffff').fontWeight(FontWeight.Bold).fontSize(18).margin({ left: 20 })
            Text(this.top_title)
              .borderRadius(15)
              .backgroundColor('#ff131212')
              .margin({ left: 20 })
              .fontColor('#ffffffff')

          }.width('30%')
          .height('100%')

          Row() {
            Line().width(0.5).height('100%').backgroundColor('#ffffffff')

            Image($r('app.media.ic_control_moon'))
              .width(40)
              .height(40)
              .margin({ left: 5 })
              .objectFit(ImageFit.ScaleDown)

            Image(this.gps_level).width(25).height(25).margin({ right: 10 }).objectFit(ImageFit.ScaleDown)


            Line().width(0.5).height('100%').backgroundColor('#ffffffff')

            Image($r('app.media.ic_control_hd')).width(30).height(30).margin({ left: 10 }).objectFit(ImageFit.ScaleDown)

            Image(this.wif_level).width(25).height(25).margin({ right: 10 }).objectFit(ImageFit.ScaleDown)

            Line().width(0.5).height('100%').backgroundColor('#ffffffff')

            Image(this.drone_power_level)
              .width(25)
              .height(25)
              .margin({ right: 10, left: 10 })
              .objectFit(ImageFit.ScaleDown)

            Line().width(0.5).height('100%').backgroundColor('#ffffffff')

            Image(this.rc_power_level)
              .width(25)
              .height(25)
              .margin({ right: 10, left: 10 })
              .objectFit(ImageFit.ScaleDown)

            Line().width(0.5).height('100%').backgroundColor('#ffffffff')

            Image($r('app.media.icon_more'))
              .width(46)
              .height(10)
              .margin({ right: 10 })
              .objectFit(ImageFit.ScaleDown)
              .onClick(() => {
                this.showRightDrawer = true;
                this.rightDrawerSelectedType =
                  RIGHT_DRAWER_PAGE_TYPES.length > 0 ? RIGHT_DRAWER_PAGE_TYPES[0] : SettingType.DATA;
              })


          }.width('70%')
          .height('100%').justifyContent(FlexAlign.End)

        }.backgroundColor('#20000000')
        .width('100%')
        .height('12%')

        //Tf卡
        Row() {
          Text(this.TF_S)
            .backgroundColor('#88535050')
            .height(30)
        }.alignRules({
          right: { anchor: '__container__', align: HorizontalAlign.End }
        })
        .margin({ top: 60, right: 20 })

        //左侧按钮
        Column() {
          Image($r('app.media.ic_control_up'))
            .width(40)
            .height(40)
            .margin({})
            .objectFit(ImageFit.ScaleDown)
            .onClick(() => {
              //起飞
              // 打开弹窗（非模态，不抢占焦点）

              let wrappedBuilder = wrapBuilder<[Params]>(buildText)

              let data: Params = new ParamsBuilder().setTitle("请确认是否自动起飞")
                .setText("请确保飞行器处于水平地面，请勿在狭窄空间\\\\n人群中或者建筑物旁起飞，手切勿触碰螺旋桨")
                .setOnSuccess((type: Type) => {
                  if (type == Type.SLIDE) {
                    //起飞
                    console.log('解锁成功，执行起飞操作！类型：', type);
                    // 这里可以添加解锁后的具体逻辑，比如执行起飞操作
                    //解锁
                    this.onPressUnlock()

                    //起飞
                    setTimeout(() => {
                      this.sendHyControlThread?.setToLandValue(0);
                      this.sendHyControlThread?.setToFlyValue(1);
                    }, 200);

                    setTimeout(() => {
                      this.sendHyControlThread?.setToFlyValue(0);
                    }, 1000);
                  }

                }).build()
              const customContent = new ComponentContent(
                this.uiContext, // 传入UIContext
                wrappedBuilder, // @Builder函数
                data
              );
              data.dialogId = customContent;
              this.uiContext.getPromptAction().openCustomDialog(customContent, {
                alignment: DialogAlignment.Center
              })


            })
          Image($r('app.media.ic_control_turn_back'))
            .width(40)
            .height(40)
            .margin({ top: 20 })
            .objectFit(ImageFit.ScaleDown)
            .onClick(() => {
              this.showRightDrawer = true;
              this.rightDrawerSelectedType =
                RIGHT_DRAWER_PAGE_TYPES.length > 0 ? RIGHT_DRAWER_PAGE_TYPES[0] : SettingType.DATA;
            })
          Image($r('app.media.ic_control_more'))
            .width(40)
            .height(40)
            .margin({ top: 20 })
            .objectFit(ImageFit.ScaleDown)
            .onClick(() => {
              //左侧更多弹窗
              this.leftMoreDialog();
            })
        }.margin({ left: 30 }).justifyContent(FlexAlign.Center).alignRules({
          // 垂直居中
          center: {
            anchor: '__container__',
            align: VerticalAlign.Center
          }
        })

        //左侧底部指北针
        CompassView()
          .margin({ left: 30 })
          .alignRules({
            // 垂直居中
            bottom: {
              anchor: '__container__',
              align: VerticalAlign.Bottom
            }
          }).visibility(this.isMap ? Visibility.None : Visibility.Visible)
          .onClick(() => {
            this.isMap = true
          })

        //地图图传切换按钮
        Row() {
          Image($r('app.media.ic_show_angle_view'))
            .width(30)
            .height(30)
            .onClick(() => {
              this.isMap = false
            })
        }
        .visibility(!this.isMap ? Visibility.None : Visibility.Visible)
        .justifyContent(FlexAlign.End)
        .alignItems(VerticalAlign.Top)
        .width(160)
        .height(80)
        .alignRules({
          // 垂直居中
          bottom: {
            anchor: '__container__',
            align: VerticalAlign.Bottom
          }
        })
        .margin({ left: 30, bottom: 10 })
        .onClick(() => {
          if (this.isMap) {
            this.isExpanded = !this.isExpanded;
            this.isDeleteWaypoint = Visibility.None
          } else {
            this.isMap = true
          }
        });

        //右侧拍照录像部分控件
        Column({ space: 10 }) {
          Image($r('app.media.ic_camera_mode_photo')).width(30).height(30).objectFit(ImageFit.ScaleDown)
            .onClick(() => {
              // this.ShootingMoreDialog()
              if (this.currentMode == Mode.RECORD) {
                this.currentMode = Mode.PHOTO
              } else {
                this.currentMode = Mode.RECORD
              }
            })
          //拍照录像按钮
          ShootButton({
            mode: this.currentMode,
            isRecording: this.isRecording
          }).onClick(() => {
            if (this.currentMode === Mode.PHOTO) {
              console.info("拍照");
              // 在这里调用拍照逻辑
              Utils.sendEvent(ProtocolManager.getInstance().getProtocol(), MessageWhat.MESSAGE_PHOTOS)
            } else if (this.currentMode === Mode.RECORD) {
              // 录像模式：点击开始/停止录像
              this.isRecording = !this.isRecording;
              // 保存到沙箱目录

              if (this.isRecording) {
                const now = new Date();
                const timestampName = `${now.getFullYear()}${(now.getMonth() + 1).toString()
                  .padStart(2, '0')}${now.getDate()}_${now.getHours()}${(now.getMinutes()).toString()
                  .padStart(2, '0')}${now.getSeconds()}`;
                const name = 'video_' + timestampName;
                const targetPath = `${getContext().filesDir}/Video/${name}.mp4`;
                this.file = fs.openSync(targetPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
                let fd = this.file.fd;
                console.info("开始录像");
                this.textTimerController.start()
                this.isRecord = true;
                NapiBuffer.StreamRecording(fd, Resolution.V_1280);
              } else {
                console.info("停止录像");
                this.isRecord = false;
                NapiBuffer.StopRecording();
                this.textTimerController.pause()
                this.textTimerController.reset()
                if (this.file != null) {
                  this.saveVideoToGallery(this.file.path)
                  console.log("视频保存路径", this.file.path)
                }
              }
            } else if (this.currentMode === Mode.SCALE) {
              // 延时模式：点击开始/停止
              this.isRecording = !this.isRecording;
              if (this.isRecording) {
                console.info("开始延时摄影");
              } else {
                console.info("停止延时摄影");
              }
            }
          })

          //计时器
          TextTimer({
            isCountDown: false,
            count: 0,
            controller: this.textTimerController
          })
            .visibility(this.isRecording ? Visibility.Visible : Visibility.None)
            .format(this.format)
            .fontColor(Color.Black)
            .fontSize(8)
            .onTimer((utc: number, elapsedTime: number) => {
              console.info('textTimer notCountDown utc is：' + utc + ', elapsedTime: ' + elapsedTime)
            })

          Image($r('app.media.icon_album')).width(30).height(30).objectFit(ImageFit.ScaleDown)
            .onClick(() => {
              // this.ShootingMoreDialog()
              RouteHelper.pushUrl('pages/MediaAlbum')
            })

        }
        .zIndex(4)
        .alignRules({
          // 垂直居中
          right: { anchor: '__container__', align: HorizontalAlign.End },
          center: { anchor: '__container__', align: VerticalAlign.Center }
        })
        .justifyContent(FlexAlign.Center)
        .margin({ right: 10, top: 0 })
        .height('80%')
        .width(60)

      }.width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent) // 关键设置 //透传点击效果
      .zIndex(4);

      // 右侧弹窗：占屏约 4/5，按 RIGHT_DRAWER_PAGE_TYPES 中配置的类型显示页面（可增删类型）
      if (this.showRightDrawer) {
        Row() {
          Blank()
            .width('20%')
            .height('100%')
            .onClick(() => {
              this.showRightDrawer = false;
            })
          Column() {
            Row() {
              Scroll() {
                Column() {
                  Image($r('app.media.ic_back'))
                    .width(24)
                    .height(24)
                    .objectFit(ImageFit.ScaleDown)
                    .margin({ bottom: 16 })
                    .onClick(() => {
                      this.showRightDrawer = false;
                    })
                  ForEach(RIGHT_DRAWER_PAGE_TYPES, (item: SettingType) => {
                    Row() {
                      Image(getSettingTypeName(item))
                        .width(30)
                        .height(30)
                        .objectFit(ImageFit.ScaleDown)
                        .colorFilter(ObjectUtils.hexToColorMatrix(this.rightDrawerSelectedType === item ? '#ff008ff4' :
                          '#fffcfcfc'))
                      // 原本显示文本，现按需求改为注释
                      // Text('数据参数/环绕半径/…').fontSize(14)
                    }
                    .width('100%')
                    .padding({
                      top: 12,
                      bottom: 12,
                      left: 16,
                      right: 16
                    })
                    .borderRadius(8)
                    .backgroundColor(this.rightDrawerSelectedType === item ? '#112C97DE' : '#00000000')
                    .onClick(() => {
                      this.rightDrawerSelectedType = item;
                    })
                  }, (item: SettingType) => String(item))
                }
                .alignItems(HorizontalAlign.Start)
              }
              .width(110)
              .height('100%')
              .scrollBar(BarState.Off)
              .backgroundColor('#581e1c1c')

              // 右侧内容区：直接根据 rightDrawerSelectedType 分支，确保状态变化触发切换
              Column() {
                /* Image(getSettingTypeName(this.rightDrawerSelectedType))
                   .width(28)
                   .height(28)
                   .objectFit(ImageFit.ScaleDown)
                   .margin({ bottom: 16 })*/
                // 原本显示标题文本，现按需求改为注释
                // Text('数据参数/环绕半径/…').fontSize(16)
                if (this.rightDrawerSelectedType === SettingType.DATA) {
                  //设置围栏
                  Data()
                } else if (this.rightDrawerSelectedType === SettingType.AROUND) {
                  Text('环绕半径')
                    .fontSize(14)
                    .fontColor('#ff666666')
                } else if (this.rightDrawerSelectedType === SettingType.CALIBRATION) {
                  //飞机校准
                  SettingCalibration()
                } else if (this.rightDrawerSelectedType === SettingType.FIRMWARE) {
                  Text('固件升级')
                    .fontSize(14)
                    .fontColor('#ff666666')
                } else if (this.rightDrawerSelectedType === SettingType.TF) {
                  Text('TF卡')
                    .fontSize(14)
                    .fontColor('#ff666666')
                } else if (this.rightDrawerSelectedType === SettingType.TRACK) {
                  Text('飞机飞行轨迹')
                    .fontSize(14)
                    .fontColor('#ff666666')
                } else if (this.rightDrawerSelectedType === SettingType.UNIT) {
                  Text('单位')
                    .fontSize(14)
                    .fontColor('#ff666666')
                } else if (this.rightDrawerSelectedType === SettingType.OTHRE) {
                  Text('其他')
                    .fontSize(14)
                    .fontColor('#ff666666')
                } else if (this.rightDrawerSelectedType === SettingType.ZONE) {
                  Text('禁飞区')
                    .fontSize(14)
                    .fontColor('#ff666666')
                } else if (this.rightDrawerSelectedType === SettingType.CONTROL_FIRMWARE) {
                  Text('飞控固件升级')
                    .fontSize(14)
                    .fontColor('#ff666666')
                }
              }
              .layoutWeight(1)
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Start)
              .alignItems(HorizontalAlign.Start)
              .padding({ left: 16, right: 16, top: 16 })
            }
            .width('100%')
            .layoutWeight(1)
          }
          .width('80%')
          .height('100%')
          .backgroundColor('#cc302f2f')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .height('100%')
        .zIndex(5)
      }


    }
    .hitTestBehavior(HitTestMode.Transparent) // 关键设置
    .width('100%')
    .height('100%')
  }

  //左侧更多弹窗
  leftMoreDialog() {
    let wrappedBuilder = wrapBuilder<[MoreParams]>(buildLeftMore)
    if (this.data == undefined) {
      this.data = new MoreParams(this.uiContext, (id: number) => {
        this.onLeftMoreOnClick(id);
      })
      this.data.getType()
    }
    if (this.data) {
      const customContent = new ComponentContent(
        this.uiContext, // 传入UIContext
        wrappedBuilder, // @Builder函数
        this.data
      );
      this.data.dialogId = customContent;
      this.uiContext.getPromptAction().openCustomDialog(customContent, {
        alignment: DialogAlignment.Center
      })
    }
  }

  //左侧更多按钮点击
  onLeftMoreOnClick(id: number) {
    let type = this.data?.arrMoreBean[id].getType();
    this.uiContext.getPromptAction().closeCustomDialog(this.data?.dialogId);
    console.log("---------------oooooooo", type)
    switch (type) {
      case MoreType.REV:
        FunctionHelper.switchRev()
        break
      case MoreType.UNLOCK:
        this.onPressUnlock()
        break
      case MoreType.FOLLOW:

        if (this.data?.arrMoreBean[id].isSelected()) {
          //关闭跟随
          this.lgFollowThread?.stopFollowTimer();
          this.data?.arrMoreBean[id].setSelected(!this.data?.arrMoreBean[id].isSelected());
        } else {
          //开启跟随
          //Gps跟随
          let wrappedBuilder = wrapBuilder<[SlideAnimParams]>(buildSlideAnim)
          let data: SlideAnimParams = new SlideAnimParamsBuilder()
            .setAnimType(AnimType.FOLLOW_GPS)
            .setOnSuccess((type: Type) => {
              this.uiContext.getPromptAction().closeCustomDialog(data.dialogId)
              if (type == Type.SLIDE) {
                //跟随
                if (this.lgFollowThread == undefined) {
                  this.lgFollowThread = new LgFollowThread();
                }
                //开启跟随
                this.lgFollowThread?.sendFollowData();

                this.data?.arrMoreBean[id].setSelected(!this.data?.arrMoreBean[id].isSelected());
                this.data?.dialogId?.update(this.data)
              }
            })
            .build()

          const customContent = new ComponentContent(
            this.uiContext, // 传入UIContext
            wrappedBuilder, // @Builder函数
            data
          );
          data.dialogId = customContent;
          this.uiContext.getPromptAction().openCustomDialog(customContent, {
            alignment: DialogAlignment.Center
          })
        }


        break
      case MoreType.POINT:
        //多点

        this.isMap = true
        this.isExpanded = true;
        this.isDeleteWaypoint = Visibility.Visible
        break
      case MoreType.AROUND:

        if (this.data?.arrMoreBean[id].isSelected()) {
          //关闭环绕
          this.sendHyControlThread?.setCancelValue(1)
          setTimeout(() => {
            // 执行异步任务（如更新UI状态）
            this.sendHyControlThread?.setCancelValue(0)
          }, 1000); // 1000毫秒 = 1秒

          this.data?.arrMoreBean[id].setSelected(!this.data?.arrMoreBean[id].isSelected());
        } else {
          //开启环绕
          let wrappedBuilder = wrapBuilder<[SlideAnimParams]>(buildSlideAnim)
          let data: SlideAnimParams = new SlideAnimParamsBuilder()
            .setAnimType(AnimType.FLY_SURROUND)
            .setOnSuccess((type: Type) => {
              this.uiContext.getPromptAction().closeCustomDialog(data.dialogId)
              if (type == Type.SLIDE) {
                this.sendHyControlThread?.setAroundValue(1)
                setTimeout(() => {
                  // 执行异步任务（如更新UI状态）
                  this.sendHyControlThread?.setAroundValue(0)
                }, 1000); // 1000毫秒 = 1秒

                this.data?.arrMoreBean[id].setSelected(!this.data?.arrMoreBean[id].isSelected());
                this.data?.dialogId?.update(this.data)
              }
            })
            .build()
          const customContent = new ComponentContent(
            this.uiContext, // 传入UIContext
            wrappedBuilder, // @Builder函数
            data
          );
          data.dialogId = customContent;
          this.uiContext.getPromptAction().openCustomDialog(customContent, {
            alignment: DialogAlignment.Center
          })
        }
        break
      case MoreType.UNLOCK:
        this.sendHyControlThread?.setLockValue(1)
        setTimeout(() => {
          // 执行异步任务（如更新UI状态）
          this.sendHyControlThread?.setLockValue(0)
        }, 1000); // 1000毫秒 = 1秒
        break

      case MoreType.FAR_FLY:
        //一键远飞
        let wrappedBuilder = wrapBuilder<[Params]>(buildText)
        let data: Params = new ParamsBuilder().setTitle("一键远飞")
          .setText("开始后，飞行器将远离目标斜着往后退25米左右，注意后面空间，避免造成伤害!若遇紧急情况，立即用遥控器中断飞行!")
          .setOnSuccess((type: Type) => {
            if (type == Type.SLIDE) {
              this.sendHyControlThread?.setFarFly(1)
              setTimeout(() => {
                // 执行异步任务（如更新UI状态）
                this.sendHyControlThread?.setFarFly(0)
              }, 1000); // 1000毫秒 = 1秒
            }
            this.uiContext?.getPromptAction().closeCustomDialog(data.dialogId)
          }).build()
        const customContent = new ComponentContent(
          this.uiContext, // 传入UIContext
          wrappedBuilder, // @Builder函数
          data
        );
        data.dialogId = customContent;
        this.uiContext.getPromptAction().openCustomDialog(customContent, {
          alignment: DialogAlignment.Center
        })
        break;
      case MoreType.SKY_FLY:
        //冲天功能
        let wrappedBuilder1 = wrapBuilder<[Params]>(buildText)
        let data1: Params = new ParamsBuilder().setTitle("一键冲天")
          .setText("开始后，飞行器将自动上升15米左右，注意上方障碍物，避免造成伤害!若遇紧急情况，立即用遥控器中断飞行!")
          .setOnSuccess((type: Type) => {
            if (type == Type.SLIDE) {
              this.sendHyControlThread?.setSkyFly(1)
              setTimeout(() => {
                // 执行异步任务（如更新UI状态）
                this.sendHyControlThread?.setSkyFly(0)
              }, 1000); // 1000毫秒 = 1秒
            }
            this.uiContext?.getPromptAction().closeCustomDialog(data1.dialogId)
          }).build()
        const customContent1 = new ComponentContent(
          this.uiContext, // 传入UIContext
          wrappedBuilder1, // @Builder函数
          data1
        );
        data1.dialogId = customContent1;
        this.uiContext.getPromptAction().openCustomDialog(customContent1, {
          alignment: DialogAlignment.Center
        })

        break;
      case MoreType.SPIRAL_FLY:
        //螺旋功能
        let wrappedBuilder2 = wrapBuilder<[Params]>(buildText)
        let data2: Params = new ParamsBuilder().setTitle("一键螺旋")
          .setText("开始后，飞行器将自动螺旋上升(最大半径15米左右)，注意周围环境，避免造成伤害!若遇紧急情况，立即用遥控器中断飞行!")
          .setOnSuccess((type: Type) => {
            if (type == Type.SLIDE) {
              this.sendHyControlThread?.setSpiralFly(1)
              setTimeout(() => {
                // 执行异步任务（如更新UI状态）
                this.sendHyControlThread?.setSpiralFly(0)
              }, 1000); // 1000毫秒 = 1秒
            }
            this.uiContext?.getPromptAction().closeCustomDialog(data2.dialogId)
          }).build()
        const customContent2 = new ComponentContent(
          this.uiContext, // 传入UIContext
          wrappedBuilder2, // @Builder函数
          data2
        );
        data2.dialogId = customContent2;
        this.uiContext.getPromptAction().openCustomDialog(customContent2, {
          alignment: DialogAlignment.Center
        })
        break;
      case MoreType.FIND_DRONE:
        RouteHelper.pushUrl('pages/SeekPlanePage');

        break


    }

  }

  onPressUnlock() {
    //解锁
    this.sendHyControlThread?.setLockValue(1)
    setTimeout(() => {
      this.sendHyControlThread?.setLockValue(0)
    }, 1000);
  }

  onPageShow(): void {
    // 持续订阅
    emitter.on({ eventId: Protocol.LAN_GUANG }, (eventData: emitter.GenericEventData<PageSendData>) => {
      console.log("收到蓝光功能字信息:", JSON.stringify(eventData));
      if (eventData.data?.modeType == ModeType.FlightControl) {
        //飞控数据
        this.onData(eventData.data)
      }
    });

    //订阅页面数据和底层数据区分开
    emitter.on({ eventId: ModeType.Page }, (eventData: emitter.GenericEventData<PageNewSendData<Object>>) => {
      console.log("页数数据信息:", JSON.stringify(eventData));
      //页面数据
      this.onNewMessage(eventData.data)

    });


    this.sendHyControlThread = new SendHyControlThread();
    this.sendHyControlThread.start();

    //开始定位
    this.GetLocation();

    //每五秒一次读取sd卡状态
    TFConsumer.start();


  }

  //监听位置变化
  GetLocation() {
    // 1. 定义持续定位请求参数
    let request: geoLocationManager.ContinuousLocationRequest = {
      'interval': 1, // 上报间隔（秒）
      'locationScenario': geoLocationManager.UserActivityScenario.TRANSPORT // 场景类型
    };

    // 2. 注册位置变化监听
    this.callback = (location: geoLocationManager.Location): void => {
      console.log('最新位置:', JSON.stringify(location));
      //跟随
      if (this.lgFollowThread != undefined) {
        this.lgFollowThread.setLocation(location)
      }
      console.log('最新位置===:', JSON.stringify(location));
      //传递发送位置信息
      SendEmitterUtil.sendEventLocation(MessageWhat.MESSAGE_LOCATION, location)
    };
    geoLocationManager.on('locationChange', request, this.callback);

  }

  //校准弹窗
  setCalibrationDialog(type: number) {
    if (this.dialogId == undefined) {
      this.DialogType = type;
      console.debug("==============", "11111111",)
      let wrappedBuilder = wrapBuilder<[CalibrationParams]>(CalibrationDialog)
      let data = new CalibrationParams()
      if (type == 1) {
        //水平校准
        data.setLevelType()
      } else if (type == 2) {
        //罗盘水平校准
        data.setCompassLevelType()
      } else if (type == 3) {
        //罗盘水平校准
        data.setCompassVerticalType()
      }
      const customContent = new ComponentContent(
        this.uiContext, // 传入UIContext
        wrappedBuilder, // @Builder函数
        data
      );
      this.dialogId = customContent;
      data.dialogId = customContent;
      this.uiContext.getPromptAction().openCustomDialog(customContent, {
        alignment: DialogAlignment.Center
      })
    }

  }

  disCalibrationDialog() {
    if (this.dialogId != undefined) {
      this.uiContext?.getPromptAction().closeCustomDialog(this.dialogId)
      this.dialogId = undefined
    }
  }

  aboutToDisappear(): void {
    //取消订阅
    emitter.off(Protocol.LAN_GUANG)
    //取消订阅
    emitter.off(ModeType.Page)
    this.sendHyControlThread?.cancel();
    // 3. 结束时取消定位监听
    geoLocationManager.off('locationChange', this.callback);
  }

  private sendNotice(id: number, data?: Uint8Array) {
    // 1. 创建事件对象
    const innerEvent: emitter.InnerEvent = {
      eventId: id, // 事件ID，需与接收方保持一致
      priority: emitter.EventPriority.HIGH  // 优先级控制
    };

    // 2. 创建要发送的数据
    const eventData: emitter.EventData = {
      data: { data: data }
    };

    // 3. 发送事件
    emitter.emit(innerEvent, eventData);
    console.log("事件发送成功");
  }

  //飞控数据处理
  onData(pageSendData: PageSendData) {
    if (!pageSendData.data) {
      return
    }
    const data = pageSendData.data;
    switch (pageSendData.type) {
      case LanGuangObserver.TYPE_DRONE_STATUS:
        // 解析无人机状态数据为LGPlaneHyBean
        const lgPlaneHyBean: LGPlaneHyBean = LanGuangAnalysis.getInstance().parseDroneStatus(data);
        console.log(`无人机状态数据: ${JSON.stringify(lgPlaneHyBean)}`);
        const gpsValue = lgPlaneHyBean.GpsNum;
        if (gpsValue == 0) {
          this.gps_level = $r('app.media.ic_level')
        } else if (gpsValue < 6) {
          this.gps_level = $r('app.media.ic_level1')
        } else if (gpsValue < 12) {
          this.gps_level = $r('app.media.ic_level2')
        } else if (gpsValue < 18) {
          this.gps_level = $r('app.media.ic_level3')
        } else if (gpsValue < 24) {
          this.gps_level = $r('app.media.ic_level4')
        } else {
          this.gps_level = $r('app.media.ic_level5')
        }
        //校准处理
        if (lgPlaneHyBean.InsCalib == 0) {
          //水平校准
          this.setCalibrationDialog(1)
        } else {
          if (this.DialogType == 1) {
            this.disCalibrationDialog()
          }
        }
        // TODO: 2019/10/28 指南校准
        if (lgPlaneHyBean.MagXYCalib == 0) {
          //罗盘水平校准
          this.setCalibrationDialog(2)
        } else {
          if (this.DialogType == 2) {
            this.disCalibrationDialog()
          }

        }
        if (lgPlaneHyBean.MagZCalib == 0) {
          //罗盘垂直校准
          this.setCalibrationDialog(3)
        } else {
          if (this.DialogType == 3) {
            this.disCalibrationDialog()
          }
        }


        /*---------文字提示----------*/
        // 默认显示
        if (this.showDefaultMessage) {
          if (lgPlaneHyBean.modeGps == 1) {
            this.currentMsg = 'GPS模式';
            //isGpsMode = true;
          } else {
            this.currentMsg = '姿态模式';
            // isGpsMode = false;
          }
        }
        this.top_title = this.currentMsg


        break
      case LanGuangObserver.TYPE_GPS_INFO_9C:
        const sjHyInfo9CBean: SJHyInfo9CBean = LanGuangAnalysis.getInstance().parseSJHyInfo9C(data)

        if (this.lastBatPer > sjHyInfo9CBean.BatPer || sjHyInfo9CBean.BatPer - this.lastBatPer >= 10) {
          if (sjHyInfo9CBean.BatPer >= 80) {
            this.drone_power_level = $r('app.media.ic_plane_power_5'); //飞机电量
          } else if (sjHyInfo9CBean.BatPer >= 60) {
            this.drone_power_level = $r('app.media.ic_plane_power_4'); //飞机电量
          } else if (sjHyInfo9CBean.BatPer >= 40) {
            console.log(`SJHyInfo9CBean:===`, '-------------------');
            this.drone_power_level = $r('app.media.ic_plane_power_3'); //飞机电量
          } else if (sjHyInfo9CBean.BatPer >= 30) {
            this.drone_power_level = $r('app.media.ic_plane_power_2'); //飞机电量
          } else if (sjHyInfo9CBean.BatPer >= 20) {
            this.drone_power_level = $r('app.media.ic_plane_power_1'); //飞机电量
          }
        }

        this.lastBatPer = sjHyInfo9CBean.BatPer;

        console.log(`SJHyInfo9CBean: ${JSON.stringify(sjHyInfo9CBean)}`, data.length);
        break
      case LanGuangObserver.TYPE_GPS_INFO_8C:
        const droneGPS: LGPlaneGpsBean = LanGuangAnalysis.getInstance().parseLGPlaneGps(data)
        break
      case LanGuangObserver.TYPE_POINT_INFO:
        const FlyLine: LGGetFlyLineBean = LanGuangAnalysis.getInstance().parsePointNumRespond(data)
        break
      case LanGuangObserver.TYPE_REAL_TIME_INFO_8E:
        const LGInfo3HyBean: LGInfo3HyBean = LanGuangAnalysis.getInstance().parseLGInfo3Hy(data)
        break
      case LanGuangObserver.TYPE_REAL_TIME_INFO_8F:
        const LGInfo3BHyBean: LGInfo3BHyBean = LanGuangAnalysis.getInstance().parseLGInfo3BHy(data)

        break
      case LanGuangObserver.TYPE_TEST_INFO_8D:
        const LGTestBean1: LGTestBean = LanGuangAnalysis.getInstance().parseLGTest(data)
        break
      case LanGuangObserver.TYPE_GPS_INFO_9D:
        const LGPlaneGpsBean2: LGPlaneGpsBean2 = LanGuangAnalysis.getInstance().parseLGPlaneGps2(data)
        break
      case LanGuangObserver.TYPE_SETTING_INFO_9A:
        const SJHyGetSettingBean: SJHyGetSettingBean = LanGuangAnalysis.getInstance().parseSJHyGetSetting(data)
        SendSettingParamsUtils.getInstance().sendsaveSuccess()
        //设置围栏成功
        console.log(`设置围栏成功9a`)
        this.sendNotice(Data.setting)
        break
      case LanGuangObserver.TYPE_SETTING_INFO_AB:
        const HyABBean: HyABBean = LanGuangAnalysis.getInstance().parseHyAB(data)
        SendSettingParamsUtils.getInstance().sendsaveSuccess()
        this.sendNotice(Data.setting)
        //设置围栏成功
        console.log(`设置围栏成功ab`)
        console.log(`设置围栏成功ab: ${JSON.stringify(HyABBean)}`);
        break
      case LanGuangObserver.TYPE_SETTING_INFO_9B:
        const SJHyInfo9BBean: SJHyInfo9BBean = LanGuangAnalysis.getInstance().parseSJHyInfo9B(data)
        break

    }

  }

  onNewMessage(pageSendData?: PageNewSendData<Object>) {
    switch (pageSendData?.type) {
      case MessageWhat.MESSAGE_HORIZONTAL_CALIBRATION:
        //水平校准
        this.sendHyControlThread?.setLevelCor(1)
        // 延迟1秒后执行（非阻塞主线程）
        setTimeout(() => {
          // 执行异步任务（如更新UI状态）
          this.sendHyControlThread?.setLevelCor(0)
        }, 1000); // 1000毫秒 = 1秒
        break
      case MessageWhat.MESSAGE_GUIDE_CALIBRATION:
        //指南校准
        this.sendHyControlThread?.setMagCor(1)
        // 延迟1秒后执行（非阻塞主线程）
        setTimeout(() => {
          // 执行异步任务（如更新UI状态）
          this.sendHyControlThread?.setMagCor(0)
        }, 1000); // 1000毫秒 = 1秒
        break
      case MessageWhat.MESSAGE_WAYPOINT:
        //航点数据
        //  pageSendData.addedMarkers?
        // 打开弹窗（非模态，不抢占焦点）

        let wrappedBuilder = wrapBuilder<[Params]>(buildText)
        let data: Params = new ParamsBuilder().setTitle("请确认是否航点飞行")
          .setText("请确保航点位置安全，避免飞行器撞击建筑物，防止飞行器丢失")
          .setTitleImg($r('app.media.ic_unlock_point'))
          .setOnSuccess((type: Type) => {
            this.uiContext.getPromptAction().closeCustomDialog(data.dialogId)
            if (type == Type.SLIDE) {
              let addedMarkers: map.Marker[] = pageSendData.value as map.Marker[]; // 存储已添加的标记点
              this.sendPointData(addedMarkers);
            }
          })
          .build()

        const customContent = new ComponentContent(
          this.uiContext, // 传入UIContext
          wrappedBuilder, // @Builder函数
          data
        );
        data.dialogId = customContent;
        this.uiContext.getPromptAction().openCustomDialog(customContent, {
          alignment: DialogAlignment.Center
        })
        break
      case SwitchType.NOTIFY_TF_EXIST_CARD:
        // 有tf卡
        this.TF_S = '有tf卡'
        break
      case SwitchType.NOTIFY_TF_NO_CARD:
        // 没有tf卡
        this.TF_S = '没有tf卡'
        break
      case SwitchType.NOTIFY_TF_FORMAT_BEGIN:
        // 开始格式化
        this.TF_S = ' 开始格式化'
        break
      case SwitchType.NOTIFY_TF_FORMAT_FINISHED:
        // 格式化完成
        this.TF_S = ' 格式化完成'
        break
      case SwitchType.NOTIFY_TF_FORMAT_FAIL:
        // 格式化失败
        this.TF_S = ' 格式化失败'
        break
      case SwitchType.NOTIFY_TF_NEED_PLUG:
        // tf 需要重新插拔卡
        this.TF_S = ' 需要重新插拔卡'
        break
      case SwitchType.NOTIFY_TF_FORMAT:
        // tf卡需要格式化
        this.TF_S = ' tf卡需要格式化'
        break

    }
  }

  //发送航点数据
  async sendPointData(addedMarkers: map.Marker[]) {
    for (let i = 0; i < addedMarkers.length; i++) {
      // 构建固定头部 16 字节数组
      let data = new Uint8Array(16);
      data[0] = 0x68;
      data[1] = 0x04;
      data[2] = 0x0c;

      // 填充航点参数
      let bean = new LGFlyLineBean();
      bean.PointGpsLon = Math.floor(addedMarkers[i].getPosition().longitude * 10000000);
      bean.PointGpsLat = Math.floor(addedMarkers[i].getPosition().latitude * 10000000);
      bean.PointNum = i;
      bean.PointAltitude = Math.floor(this.flyHeight * 10);
      bean.PointSpeed = 4;
      bean.PointTime = 0;
      // 调用转换函数，假设返回 Uint8Array
      let newData = LanGuangAnalysis.getInstance().convertFlyLine(bean);
      // 将转换后的数据复制到 data 的索引 3 开始的位置
      data.set(newData, 3);

      // 计算校验和（异或）
      let xor: number = data[1];
      for (let j = 2; j <= 14; j++) {
        xor ^= data[j];
      }
      data[15] = xor;

      // 发送 TCP 命令
      EntryAbility.getInstance().sendUDPCmd(data);
      // 等待 50ms
      await sleep(50);
    }
  }

  //可成功保存沙盒路径文件到相册
  async saveVideoToGallery(fileFd: string) {
    const context = getContext() as common.UIAbilityContext;
    let photoAccessHelperObj = photoAccessHelper.getPhotoAccessHelper(context);
    // 1. 创建媒体资源变更请求
    let assetChangeRequest =
      photoAccessHelper.MediaAssetChangeRequest.createAssetRequest(context, photoAccessHelper.PhotoType.VIDEO, "mp4");
    // 2. 添加视频资源到请求中
    let file = fs.openSync(fileFd, fs.OpenMode.READ_ONLY);
    assetChangeRequest.addResource(photoAccessHelper.ResourceType.VIDEO_RESOURCE, fileFd);
    fs.closeSync(file);
    // 3. 应用变更，将视频保存到图库
    await photoAccessHelperObj.applyChanges(assetChangeRequest);
    console.info('视频已成功保存到图库！');
  }
}


function sleep(arg0: number) {
  throw new Error('Function not implemented.');
}
