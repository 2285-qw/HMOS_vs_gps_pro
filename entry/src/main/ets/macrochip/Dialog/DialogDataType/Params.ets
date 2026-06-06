export class Params {
  title?: string = '请确认是否自动起飞'
  text?: string = "'请确保飞行器处于水平地面，请勿在狭窄空间\\n人群中或者建筑物旁起飞，手切勿触碰螺旋桨'";
  titleImg?: Resource = $r('app.media.ic_unlock_fly')
  dialogId?: ComponentContent;
  uiContext?: UIContext;
  slideText?: string = "向右滑动开始"
  onSuccess?: (type: Type) => void;

  constructor(title?: string, text?: string, titleImg?: Resource, slideText?: string, onSuccess?: (type: Type) => void,
    uiContext?: UIContext) {
    this.title = title;
    this.text = text;
    this.onSuccess = onSuccess;
    this.uiContext = uiContext;
  }
}

export class ParamsBuilder {
  title?: string = '请确认是否自动起飞';
  text?: string = '请确保飞行器处于水平地面，请勿在狭窄空间\\n人群中或者建筑物旁起飞，手切勿触碰螺旋桨';
  titleImg?: Resource = $r('app.media.ic_unlock_fly')
  dialogId?: ComponentContent;
  uiContext?: UIContext;
  slideText?: string = "向右滑动开始"
  onSuccess?: (type: Type) => void;

  setTitle(title: string): ParamsBuilder {
    this.title = title;
    return this;
  }


  setText(text: string): ParamsBuilder {
    this.text = text;
    return this;
  }

  setTitleImg(titleImg: Resource): ParamsBuilder {
    this.titleImg = titleImg;
    return this
  }

  setDialogId(dialogId: ComponentContent): ParamsBuilder {
    this.dialogId = dialogId;
    return this;
  }

  setUiContext(uiContext: UIContext): ParamsBuilder {
    this.uiContext = uiContext;
    return this;
  }

  setOnSuccess(onSuccess: (type: Type) => void): ParamsBuilder {
    this.onSuccess = onSuccess;
    return this;
  }

  setSlideText(slideText?: string): ParamsBuilder {
    this.slideText = slideText;
    return this;
  }

  build(): Params {
    const params = new Params();
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
    if (this.slideText != undefined) {
      params.slideText = this.slideText
    }
    return params;
  }
}


export enum Type {
  SLIDE, //滑动
  CONFIRM, //确认
  CANCEL
}