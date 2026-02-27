
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
import { Params, Type } from '../macrochip/Dialog/DialogDataType/Params';
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




@Entry
@Component
struct LanGuangPage {
  //修改ui变量
  @State drone_power_level: Resource = $r('app.media.ic_plane_power_0'); //飞机电量
  @State rc_power_level: Resource = $r('app.media.ic_rc_power_0'); //遥控器电量
  @State wif_level: Resource = $r('app.media.ic_level');
  @State gps_level: Resource = $r('app.media.ic_level'); //gps数量等级
  @State top_title: string = ''; //头部显示文本
  // 右侧弹窗：是否显示、当前选中的类型（用类型驱动右侧页面，确保点击左侧能切换）
  @State showRightDrawer: boolean = false;
  @State rightDrawerSelectedType: SettingType = SettingType.DATA;
  //参数变量
  private lastBatPer: number = 101;
  private showDefaultMessage: boolean = true;
  private currentMsg: string = '';
  private abilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private sendHyControlThread?: SendHyControlThread; //控制线程
  // 在组件或Ability中获取UIContext
  private uiContext: UIContext = this.getUIContext(); // 组件内使用
  private router = this.uiContext.getRouter(); // 获取绑定当前上下文的Router对象
  private dialogId?:ComponentContent<object>=undefined;//校准弹窗id
  private DialogType:number=0;


  build() {
    Stack() {
      VideoPage()
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
              let data: Params = new Params('1111', (type: Type) => {
                console.log('解锁成功，执行起飞操作！类型：', type);
                // 这里可以添加解锁后的具体逻辑，比如执行起飞操作
                //解锁
                this.sendHyControlThread?.setLockValue(1)
                setTimeout(() => {
                  this.sendHyControlThread?.setLockValue(0)
                }, 1000);

                //起飞
                setTimeout(() => {
                  this.sendHyControlThread?.setToLandValue(0);
                  this.sendHyControlThread?.setToFlyValue(1);
                }, 200);

                setTimeout(() => {
                  this.sendHyControlThread?.setToFlyValue(0);
                }, 1000);


              }, this.uiContext)
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

      }.width('100%')
      .height('100%')

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
      }
    }
    .width('100%')
    .height('100%')
  }

  leftMoreDialog() {
    let wrappedBuilder = wrapBuilder<[MoreParams]>(buildLeftMore)
    let data: MoreParams = new MoreParams(this.uiContext, (type: MoreType) => {

    })
    data.getType()
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

  onPageShow(): void {
    // 持续订阅
    emitter.on({ eventId: Protocol.LAN_GUANG }, (eventData: emitter.GenericEventData<PageSendData>) => {
      console.log("收到蓝光功能字信息:", JSON.stringify(eventData));

      if (eventData.data?.modeType == ModeType.FlightControl) {
        //飞控数据
        this.onData(eventData.data)
      } else if (eventData.data?.modeType == ModeType.Page) {
        this.onMessage(eventData.data)
      }


    });

    this.sendHyControlThread = new SendHyControlThread();
    this.sendHyControlThread.start();



  }

  //校准弹窗
  setCalibrationDialog(type:number) {
    if (this.dialogId==undefined) {
      this.DialogType=type;
      console.debug("==============","11111111",)
      let wrappedBuilder = wrapBuilder<[CalibrationParams]>(CalibrationDialog)
      let data = new CalibrationParams()
      if (type==1) {
        //水平校准
        data.setLevelType()
      }else if (type==2){
        //罗盘水平校准
        data.setCompassLevelType()
      } else if (type==3){
        //罗盘水平校准
        data.setCompassVerticalType()
      }
      const customContent = new ComponentContent(
        this.uiContext, // 传入UIContext
        wrappedBuilder, // @Builder函数
        data
      );
      this.dialogId=customContent;
      data.dialogId = customContent;
      this.uiContext.getPromptAction().openCustomDialog(customContent, {
        alignment: DialogAlignment.Center
      })
    }

  }
  disCalibrationDialog(){
    if (this.dialogId!=undefined) {
      console.debug("==============","22222222222",)
      this.uiContext?.getPromptAction().closeCustomDialog(this.dialogId)
      this.dialogId=undefined
    }
  }

  aboutToDisappear(): void {
    //取消订阅
    emitter.off(Protocol.LAN_GUANG)
    this.sendHyControlThread?.cancel();
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
        }else {
          if (this.DialogType==1) {
            this.disCalibrationDialog()
          }
        }
        // TODO: 2019/10/28 指南校准
        if (lgPlaneHyBean.MagXYCalib == 0) {
          //罗盘水平校准
          this.setCalibrationDialog(2)
        } else {
          if (this.DialogType==2) {
            this.disCalibrationDialog()
          }

        }
        if (lgPlaneHyBean.MagZCalib == 0) {
          //罗盘垂直校准
          this.setCalibrationDialog(3)
        } else {
          if (this.DialogType==3) {
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

  onMessage(pageSendData: PageSendData) {
    switch (pageSendData.type) {
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
    }


  }
}



