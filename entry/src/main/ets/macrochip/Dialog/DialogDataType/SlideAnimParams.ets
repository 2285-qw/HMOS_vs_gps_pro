import { Type } from "./Params";

export class SlideAnimParams {
  title?: string = '请确认是否自动起飞'
  text?: string = "'请确保飞行器处于水平地面，请勿在狭窄空间\\n人群中或者建筑物旁起飞，手切勿触碰螺旋桨'";
  titleImg?: Resource = $r('app.media.ic_unlock_fly')
  // 定义图片资源数组 (推荐方式)
  images: ImageFrameInfo[] = [
    { src: $r('app.media.img_anim_gps_follow_0') },
    { src: $r('app.media.img_anim_gps_follow_1') },
    { src: $r('app.media.img_anim_gps_follow_2') },
    { src: $r('app.media.img_anim_gps_follow_3') },
    { src: $r('app.media.img_anim_gps_follow_4') },
    { src: $r('app.media.img_anim_gps_follow_5') },
    { src: $r('app.media.img_anim_gps_follow_6') },
    { src: $r('app.media.img_anim_gps_follow_7') },
    { src: $r('app.media.img_anim_gps_follow_8') },
    { src: $r('app.media.img_anim_gps_follow_9') },
    { src: $r('app.media.img_anim_gps_follow_10') },
    { src: $r('app.media.img_anim_gps_follow_11') },
    { src: $r('app.media.img_anim_gps_follow_12') },
    { src: $r('app.media.img_anim_gps_follow_13') },
    { src: $r('app.media.img_anim_gps_follow_14') },
    { src: $r('app.media.img_anim_gps_follow_15') },
    { src: $r('app.media.img_anim_gps_follow_16') },
    { src: $r('app.media.img_anim_gps_follow_17') },
    { src: $r('app.media.img_anim_gps_follow_18') },
    { src: $r('app.media.img_anim_gps_follow_19') },
    { src: $r('app.media.img_anim_gps_follow_20') },
    { src: $r('app.media.img_anim_gps_follow_21') },
    { src: $r('app.media.img_anim_gps_follow_22') },
    { src: $r('app.media.img_anim_gps_follow_23') },
    { src: $r('app.media.img_anim_gps_follow_24') },
    { src: $r('app.media.img_anim_gps_follow_25') },
  ];
  dialogId?: ComponentContent;
  uiContext?: UIContext;
  onSuccess?: (type: Type) => void;
  animType?: AnimType;

  constructor(title?: string, text?: string, titleImg?: Resource, animType?: AnimType, onSuccess?: (type: Type) => void,
    uiContext?: UIContext) {
    this.title = title;
    this.text = text;
    this.onSuccess = onSuccess;
    this.uiContext = uiContext;
  }
}

export class SlideAnimParamsBuilder {
  title?: string = '请确认是否自动起飞';
  text?: string = '请确保飞行器处于水平地面，请勿在狭窄空间\\n人群中或者建筑物旁起飞，手切勿触碰螺旋桨';
  titleImg?: Resource = $r('app.media.ic_unlock_fly')
  slideText?: string = "向右滑动开始"
  dialogId?: ComponentContent;
  uiContext?: UIContext;
  onSuccess?: (type: Type) => void;
  animType?: AnimType;
  images?: ImageFrameInfo[];

  setTitle(title: string): SlideAnimParamsBuilder {
    this.title = title;
    return this;
  }


  setText(text: string): SlideAnimParamsBuilder {
    this.text = text;
    return this;
  }

  setTitleImg(titleImg: Resource): SlideAnimParamsBuilder {
    this.titleImg = titleImg;
    return this
  }

  setDialogId(dialogId: ComponentContent): SlideAnimParamsBuilder {
    this.dialogId = dialogId;
    return this;
  }

  setUiContext(uiContext: UIContext): SlideAnimParamsBuilder {
    this.uiContext = uiContext;
    return this;
  }



  setAnimType(animType: AnimType) {
    if (animType == AnimType.FOLLOW_GPS) {
      this.title = "提示"
      this.text = "请确保手机GPS定位信号良好，避开玻璃、从林、电线等不直观的障碍物，手机和飞机之间的水平距离不超过50米"
      this.images = [
        { src: $r('app.media.img_anim_gps_follow_0') },
        { src: $r('app.media.img_anim_gps_follow_1') },
        { src: $r('app.media.img_anim_gps_follow_2') },
        { src: $r('app.media.img_anim_gps_follow_3') },
        { src: $r('app.media.img_anim_gps_follow_4') },
        { src: $r('app.media.img_anim_gps_follow_5') },
        { src: $r('app.media.img_anim_gps_follow_6') },
        { src: $r('app.media.img_anim_gps_follow_7') },
        { src: $r('app.media.img_anim_gps_follow_8') },
        { src: $r('app.media.img_anim_gps_follow_9') },
        { src: $r('app.media.img_anim_gps_follow_10') },
        { src: $r('app.media.img_anim_gps_follow_11') },
        { src: $r('app.media.img_anim_gps_follow_12') },
        { src: $r('app.media.img_anim_gps_follow_13') },
        { src: $r('app.media.img_anim_gps_follow_14') },
        { src: $r('app.media.img_anim_gps_follow_15') },
        { src: $r('app.media.img_anim_gps_follow_16') },
        { src: $r('app.media.img_anim_gps_follow_17') },
        { src: $r('app.media.img_anim_gps_follow_18') },
        { src: $r('app.media.img_anim_gps_follow_19') },
        { src: $r('app.media.img_anim_gps_follow_20') },
        { src: $r('app.media.img_anim_gps_follow_21') },
        { src: $r('app.media.img_anim_gps_follow_22') },
        { src: $r('app.media.img_anim_gps_follow_23') },
        { src: $r('app.media.img_anim_gps_follow_24') },
        { src: $r('app.media.img_anim_gps_follow_25') },
      ];
    }
    return this;
  }

  setOnSuccess(onSuccess: (type: Type) => void): SlideAnimParamsBuilder {
    this.onSuccess = onSuccess;
    return this;
  }

  build(): SlideAnimParams {
    const params = new SlideAnimParams();
    if (this.title !== undefined) {
      params.title = this.title;
    }
    if (this.text !== undefined) {
      params.text = this.text;
    }
    if (this.dialogId !== undefined) {
      params.dialogId = this.dialogId;
    }
    if (this.uiContext !== undefined) {
      params.uiContext = this.uiContext;
    }
    if (this.onSuccess !== undefined) {
      params.onSuccess = this.onSuccess;
    }
    if (this.titleImg !== undefined) {
      params.titleImg = this.titleImg;
    }
    if (this.animType !== undefined) {
      params.animType = this.animType;
    }
    if (this.images !== undefined) {
      params.images = this.images
    }
    return params;
  }
}

export enum AnimType {
  CIRCLE,
  FOLLOW_IMAGE,
  FOLLOW_GPS,
  PANORAMIC_PHOTOGRAPHY,
  FLY_SKY,
  FLY_FAR,
  FLY_SPIRAL,
}


