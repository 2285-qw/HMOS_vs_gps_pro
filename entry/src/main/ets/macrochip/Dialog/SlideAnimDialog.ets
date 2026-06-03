import { SlideUnLockView } from "../components/SlideUnLockView";
import { Params, Type } from "./DialogDataType/Params";
import { SlideAnimParams } from "./DialogDataType/SlideAnimParams";


@Builder
export function buildSlideAnim(params: SlideAnimParams) {
  Column() {
    Text(params.title).fontSize(18).fontColor('#FFEB3B')
    Row(){
      ImageAnimator()
        .images(params.images)       // 设置帧图片数组
        .state(AnimationStatus.Running)     // 设置播放状态
        .duration(2000)             // 每帧播放时长 (ms)
        .reverse(false)  // 设置播放顺序
        .iterations(-1)            // -1 表示无限循环
        .width(100)                // 设置动画整体宽高
        .height(100)

      Text(params.text).fontSize(12).fontColor('#fffafafa').layoutWeight(1)          // 占据剩余宽度

    }.width("100%")
    SlideUnLockView({
      slideBackgroundColor: '#444444',
      componentWidth:260,
      componentHeight:30,
      slideCoverColor: '#00FF00',
      slideText: params.slideText,
      slideTextSize: 14,
      slideTextColor: '#FFFFFF',
      slideCover: false,
      onSuccess: () => {
        console.log('解锁成功！');
        // 触发回调
        if (params.onSuccess) {
          params.onSuccess(Type.SLIDE);
        }
      }
    }).margin({top:10})
    Text('取消').width('100%').fontSize(18).fontColor('#fdffffff').padding(5).textAlign(TextAlign.Center).margin({top:5}).onClick(()=>{
      if (params.onSuccess) {
        params.onSuccess(Type.CANCEL);
        // 方式1：获取当前调用作用域UIContext
        console.log('Dialog ID=:', params.dialogId);
        params.uiContext?.getPromptAction().closeCustomDialog(params.dialogId)
      }
    })

  }.borderRadius(15).background('#ff393636').outlineRadius(20).padding({top:20,bottom:20}).width(320)
}