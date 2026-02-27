export  class CalibrationParams {
  title: string = "";
  text:string='';
  img:Resource=$r('app.media.ic_cal_level_0');
  dialogId?: ComponentContent;
  uiContext?: UIContext;
  isGif:boolean=false;
  magesData: Array<ImageFrameInfo> = [
    { src: $r('app.media.ic_cal_level_0'), duration: 100 }, // 每帧图片和持续时间(ms)

  ];//动图列表

  constructor() {

  }

  setLevelType(){
    this.title="水平校准"
    this.text="请把飞行器水平放置"
    this.img=$r('app.media.ic_cal_level_0');
    this.isGif=false;
  }

  setCompassLevelType(){
    this.title="罗盘水平校准"
    this.text="请把飞行器水平旋转2–3圈"
    this.magesData=[
      { src: $r('app.media.ic_cal_level_0'), duration: 100 },
      { src: $r('app.media.ic_cal_level_1'), duration: 100 },
      { src: $r('app.media.ic_cal_level_2'), duration: 100 },
      { src: $r('app.media.ic_cal_level_3'), duration: 100 },
      { src: $r('app.media.ic_cal_level_4'), duration: 100 },
      { src: $r('app.media.ic_cal_level_5'), duration: 100 },
      { src: $r('app.media.ic_cal_level_6'), duration: 100 }, // 每帧图片和持续时间(ms)

    ];//动图列表
    this.isGif=true;

  }

  setCompassVerticalType(){
    this.title="罗盘水平校准"
    this.text="请握住飞行器，机头朝下，旋转2–3圈"
    this.magesData=[
      { src: $r('app.media.ic_cal_vertical_0'), duration: 100 },
      { src: $r('app.media.ic_cal_vertical_1'), duration: 100 },
      { src: $r('app.media.ic_cal_vertical_2'), duration: 100 },
      { src: $r('app.media.ic_cal_vertical_3'), duration: 100 },
      { src: $r('app.media.ic_cal_vertical_4'), duration: 100 },
      { src: $r('app.media.ic_cal_vertical_5'), duration: 100 },
      { src: $r('app.media.ic_cal_vertical_6'), duration: 100 }, // 每帧图片和持续时间(ms)

    ];//动图列表
    this.isGif=true;

  }


}