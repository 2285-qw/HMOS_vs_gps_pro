import { PreferencesUtil } from '../../utils/PreferencesUtil'
import { SendSettingParamsUtils } from '../../utils/SendSettingParamsUtils';
import { emitter } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';


/**
 * 设置数据模型
 */
export class SettingData {
  isBeginnerMode: boolean = true;
  //默认值
  mgoHomeDistance: number = PreferencesUtil.mgoHomeDistance; //返航高度 默认30米
  mflightDistance: number = PreferencesUtil.mflightDistance; //飞行距离
  mflightAltitude: number = PreferencesUtil.mflightAltitude; //飞行高度

  goHomeDistance: number = this.mgoHomeDistance; //返航高度 默认30米
  flightDistance: number = this.mflightDistance; //飞行距离
  flightAltitude: number = this.mflightAltitude; //飞行高度

  //最小值
  mingoHomeDistance: number = 10; //返航高度 默认30米
  minflightDistance: number = 10; //飞行距离
  minflightAltitude: number = 10; //飞行高度

  //最大值
  maxgoHomeDistance: number = 120; //返航高度 默认30米
  maxflightDistance: number = 3000; //飞行距离
  maxflightAltitude: number = 120; //飞行高度
}

/**
 * 设置回调接口
 */
export interface SettingCallback {
  onSave(data: SettingData): void;
}

/**
 * 设置页面组件
 */
@Entry
@Component
export struct Data {
  @State data: SettingData = new SettingData();
  callback: SettingCallback | null = null;
  private dialogCtrl?: CustomDialogController
  public static setting:number=20001;//围栏设置成功通知

  /**
   * 构建UI
   */
  build() {
    Column() {
      // 新手模式开关
      Row() {
        Text('新手模式')
          .fontColor('#ffffff')
          .fontSize(16)

        // 开关样式（Switch）
        Toggle({
          type: ToggleType.Switch,
          isOn: this.data.isBeginnerMode
        })
          .selectedColor('#ff2347fb') // 设置开启状态背景色
          .switchPointColor('#ffffffff') // 设置滑块颜色
          .onChange((isOn: boolean) => {
            this.data.isBeginnerMode = isOn
            if (isOn) {
              this.data.goHomeDistance = this.data.mgoHomeDistance; //返航高度 默认30米
              this.data.flightDistance = this.data.mflightDistance; //飞行距离
              this.data.flightAltitude = this.data.mflightAltitude; //飞行高度
            }
          })
      }.width('100%').justifyContent(FlexAlign.SpaceBetween)

      //飞行距离
      Row() {
        Column() {
          Text('飞行距离')
            .fontColor('#ffffff')
            .fontSize(16)

          Text(`默认${this.data.mflightDistance}m(${this.data.minflightDistance}m-${this.data.maxflightDistance}m)`)
            .fontColor('#A5A5A5')
            .fontSize(10)
        }.justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)

        Row() {
          Slider({
            value: this.data.flightDistance,
            min: this.data.minflightDistance,
            max: this.data.maxflightDistance,
            step: 1
          })
            .enabled(!this.data.isBeginnerMode)
            .width('85%')
            .trackColor('#909497')
            .selectedColor('#ffffff')

            .onChange((value: number) => {
              this.data.flightDistance = value;
            })
          Text(`${Math.round(this.data.flightDistance)}`)
            .fontColor('#ffffff')
            .fontSize(16)
            .width(40)
            .height(28)
            .backgroundColor('#909497')
            .textAlign(TextAlign.Center)
            .borderRadius(4)
        }.margin({ top: 10 }).width('70%').justifyContent(FlexAlign.SpaceBetween)
      }.justifyContent(FlexAlign.SpaceBetween).width("100%")

      //飞行高度
      Row() {
        Column() {
          Text('飞行高度')
            .fontColor('#ffffff')
            .fontSize(16)

          Text(`默认${this.data.mflightAltitude}m(${this.data.minflightAltitude}m-${this.data.maxflightAltitude}m)`)
            .fontColor('#A5A5A5')
            .fontSize(10)
        }.justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)

        Row() {
          Slider({
            value: this.data.flightAltitude,
            min: this.data.minflightAltitude,
            max: this.data.maxflightAltitude,
            step: 1
          })
            .enabled(!this.data.isBeginnerMode)
            .width('85%')
            .trackColor('#909497')
            .selectedColor('#ffffff')

            .onChange((value: number) => {
              this.data.flightAltitude = value;
            })
          Text(`${Math.round(this.data.flightAltitude)}`)
            .fontColor('#ffffff')
            .fontSize(16)
            .width(40)
            .height(28)
            .backgroundColor('#909497')
            .textAlign(TextAlign.Center)
            .borderRadius(4)
        }.margin({ top: 10 }).width('70%').justifyContent(FlexAlign.SpaceBetween)
      }.justifyContent(FlexAlign.SpaceBetween).width("100%")

      //返航高度
      Row() {
        Column() {
          Text('返航高度')
            .fontColor('#ffffff')
            .fontSize(16)

          Text(`默认${this.data.mgoHomeDistance}m(${this.data.mingoHomeDistance}m-${this.data.maxgoHomeDistance}m)`)
            .fontColor('#A5A5A5')
            .fontSize(10)
        }.justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)

        Row() {
          Slider({
            value: this.data.goHomeDistance,
            min: this.data.mingoHomeDistance,
            max: this.data.maxgoHomeDistance,
            step: 1
          })
            .enabled(!this.data.isBeginnerMode)
            .width('85%')
            .trackColor('#909497')
            .selectedColor('#ffffff')

            .onChange((value: number) => {
              this.data.goHomeDistance = value;
            })
          Text(`${Math.round(this.data.goHomeDistance)}`)
            .fontColor('#ffffff')
            .fontSize(16)
            .width(40)
            .height(28)
            .backgroundColor('#909497')
            .textAlign(TextAlign.Center)
            .borderRadius(4)
        }.margin({ top: 10 }).width('70%').justifyContent(FlexAlign.SpaceBetween)
      }.justifyContent(FlexAlign.SpaceBetween).width("100%")


      // 保存按钮
      Button('保存设置')
        .width(150)
        .height(40)
        .fontColor('#ffffff')
        .fontSize(15)
        .backgroundColor('#4CAF50')
        .borderRadius(8)
        .margin({ top: 20 })
        .onClick(() => {
          this.save()
          if (this.callback) {
            this.callback.onSave(this.data);
          }
        })
    }.width('100%')
    .height('100%')
    .padding(20)
  }

  onPageShow(): void {


  }

  aboutToAppear(): void {

    this.data.isBeginnerMode = PreferencesUtil.getData(PreferencesUtil.NOVICE, true) as boolean
    this.data.goHomeDistance =
      PreferencesUtil.getData(PreferencesUtil.RETURN_ALTITUDE, PreferencesUtil.mgoHomeDistance) as number
    this.data.flightDistance =
      PreferencesUtil.getData(PreferencesUtil.DISTANCE, PreferencesUtil.mflightDistance) as number
    this.data.flightAltitude =
      PreferencesUtil.getData(PreferencesUtil.FLY_ALTITUDE, PreferencesUtil.mflightAltitude) as number


    // 持续订阅
    emitter.on({ eventId:Data.setting  }, (eventData: emitter.GenericEventData<Uint8Array>) => {
      // 基础吐司（默认2秒）
      promptAction.showToast({ message: "设置成功" });


    });
  }

  aboutToDisappear(): void {
    //取消订阅
    emitter.off(Data.setting)
  }

  save() {
    /*  PreferencesUtil.saveData(PreferencesUtil.RETURN_ALTITUDE,this.data.goHomeDistance)
      PreferencesUtil.saveData(PreferencesUtil.DISTANCE,this.data.flightDistance)
      PreferencesUtil.saveData(PreferencesUtil.FLY_ALTITUDE,this.data.flightAltitude)*/

    SendSettingParamsUtils.getInstance()
      .sendSetting(this.data.isBeginnerMode, this.data.flightDistance, this.data.flightAltitude,
        this.data.goHomeDistance)
    console.log("----------", this.data.flightDistance, this.data.flightAltitude,
      this.data.goHomeDistance)


  }
}
