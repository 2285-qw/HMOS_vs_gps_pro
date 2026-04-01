import { geoLocationManager } from '@kit.LocationKit';

// 定义数据类型
export  class PageSendData {
  modeType:ModeType=ModeType.FlightControl//0是飞控数据 1是页面交互数据
  type: number = 0;
  data?: Uint8Array
  location?:geoLocationManager.Location;//位置
  numberData?:number;//数据

  constructor(modeType: number, type: number, data?: Uint8Array, location?:geoLocationManager.Location,numberData?:number) {
    this.modeType = modeType;
    this.type = type;
    this.data = data;
    this.location=location;
    this.numberData=numberData
  }




}

export enum ModeType{
  FlightControl=0,
  Page=1
}