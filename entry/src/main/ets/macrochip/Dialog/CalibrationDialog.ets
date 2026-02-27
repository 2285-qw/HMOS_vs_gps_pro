import { SlideUnLockView } from "../components/SlideUnLockView";
import { MoreBean } from "../More/MoreBean";
import { MoreParams } from "./DialogDataType/MoreParams";
import { MoreType } from "../More/MoreType";
import { Params, Type } from "./DialogDataType/Params";
import { CalibrationParams } from "./DialogDataType/CalibrationParams";


@Builder
export function CalibrationDialog(params: CalibrationParams) {
  Column() {
    Text(params.title).fontColor(Color.White)
    if (params.isGif) {
      ImageAnimator()
        .images(params.magesData)
        .state(1)
        .iterations(-1)
        .width(200)
        .height(110)
        .margin({top:10,bottom:10})
    }else {
      Image($r('app.media.ic_cal_level_0')).width(200).objectFit(ImageFit.Contain).margin({top:10,bottom:10})
    }

    Text(params.text).fontColor(Color.White)
  }
  .borderRadius(15)
  .background('#66393636')
  .outlineRadius(20)
  .padding({
    left: 30,
    right: 30,
    top: 20,
    bottom: 20
  })
  .width(320)
}