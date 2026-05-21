import { SlideUnLockView } from "../components/SlideUnLockView";
import { ShootingSelectionParams, ShootingType } from "./DialogDataType/ShootingSelectionParams";


@Builder
export function buildShootingSelectionDialog(params: ShootingSelectionParams) {
  Column({ space: 10 }) {
    Image($r('app.media.ic_camera_mode_photo')).objectFit(ImageFit.ScaleDown).width(30).height(30)
      .onClick(() => {

      })
    Image($r('app.media.ic_camera_mode_video')).objectFit(ImageFit.ScaleDown).width(30).height(30)
   /* Image($r('app.media.ic_unlock_fly')).objectFit(ImageFit.ScaleDown).width(30).height(30)
    Image($r('app.media.ic_unlock_fly')).objectFit(ImageFit.ScaleDown).width(30).height(30)*/
  }
  .borderRadius(15)
  .background('#ff393636')
  .outlineRadius(20)
  .padding({
    left: 30,
    right: 30,
    top: 20,
    bottom: 20
  })
  .width(50)
}