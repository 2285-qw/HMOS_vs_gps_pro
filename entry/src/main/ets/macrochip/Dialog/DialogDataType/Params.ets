export  class Params {
  text: string = "";
  dialogId?:  ComponentContent;
  uiContext?: UIContext;
  onSuccess?: (type:Type) => void;
  constructor(text: string, onSuccess?: (type:Type) => void,uiContext?:UIContext) {
    this.text = text;
    this.onSuccess = onSuccess;
    this.uiContext=uiContext;
  }
}
export enum Type{
  SLIDE,//滑动
  CONFIRM,//确认
  CANCEL
}