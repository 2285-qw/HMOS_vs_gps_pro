import { SlideUnLockView } from "../components/SlideUnLockView";
import { Params, Type } from "./DialogDataType/Params";


@Builder
export function buildText(params: Params) {
  Column() {
    Image(params.titleImg).objectFit(ImageFit.ScaleDown).width(30).height(30)
    Text(params.title).fontSize(18).fontColor('#FFEB3B')
    Text(params.text).fontSize(12).fontColor('#fffafafa')
    SlideUnLockView({
      slideBackgroundColor: '#444444',
      componentWidth:260,
      componentHeight:30,
      slideCoverColor: '#00FF00',
      slideText: '向右滑动解锁',
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

  }.borderRadius(15).background('#ff393636').outlineRadius(20).padding({left:30,right:30,top:20,bottom:20}).width(320)
}