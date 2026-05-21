import { BaseParams } from "./BaseParams";

export  class ShootingSelectionParams extends BaseParams  {
  arrMoreBean: ShootingType = ShootingType.PHOTO;
  onItemClick?: (arrMoreBean: ShootingType) => void
  constructor(uiContext?:UIContext, onItemClick?: (arrMoreBean: ShootingType) => void) {
    super();
    this.uiContext=uiContext;
    this.onItemClick=onItemClick
  }
}

export enum ShootingType{
  PHOTO,//拍照
  RECORD,//录像
  DELAY,//延时
  SLOW,//慢动作
}