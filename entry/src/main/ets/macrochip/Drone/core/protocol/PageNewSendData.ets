import { geoLocationManager } from '@kit.LocationKit';

// 定义数据类型
export  class PageNewSendData<T> {
  type: number = 0;
  data?: Uint8Array
  location?:geoLocationManager.Location;//位置
  numberData?:number;//数据、
  // 索引签名允许动态添加任何额外属性
  value?:T;

  constructor(type: number,value?:T) {
    this.type = type;
    this.value=value
  }


}

export enum ModeType{
  FlightControl=0,
  Page=1
}