import { MessageWhat } from "../../constant/MessageWhat"
import { ProtocolManager } from "../../Drone/core/protocol/ProtocolManager"
import { Utils } from "../../utils/Utils"

@Entry
@Component
export struct SettingCalibration {
  build() {
    Column(){
      Text('水平校准').fontColor(Color.White).fontSize(22)
      Text('需将飞行器放在水平地面上，点击“开始校准”，飞行器会自动校准。飞行器底部灯光快闪后，校准完成').fontColor(Color.White)
      Text('开始校准').onClick(()=>{
        Utils.sendEvent(ProtocolManager.getInstance().getProtocol(),MessageWhat.MESSAGE_HORIZONTAL_CALIBRATION)
      }).background(Color.Blue).padding(10).borderRadius(5).fontColor(Color.White)

      Text('指南校准').fontColor(Color.White).fontSize(22)
      Text('需将飞行器放在水平地面上，点击“开始校准”，飞行器会自动校准。飞行器底部灯光快闪后，校准完成').fontColor(Color.White)
      Text('开始校准').onClick(()=>{
        Utils.sendEvent(ProtocolManager.getInstance().getProtocol(),MessageWhat.MESSAGE_GUIDE_CALIBRATION)
      }).background(Color.Blue).padding(10).borderRadius(5).fontColor(Color.White)


    }.alignItems(HorizontalAlign.Start)

  }
}