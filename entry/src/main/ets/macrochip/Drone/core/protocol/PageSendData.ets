import { geoLocationManager } from '@kit.LocationKit';
import { map } from '@kit.MapKit';
import { add } from 'libentry.so';

// 定义数据类型
export  class PageSendData{
  modeType:ModeType=ModeType.FlightControl//0是飞控数据 1是页面交互数据
  type: number = 0;
  data?: Uint8Array
  location?:geoLocationManager.Location;//位置
  numberData?:number;//数据、
  public  addedMarkers?: map.Marker[] = []; // 存储已添加的标记点

  constructor(modeType: number, type: number, data?: Uint8Array, location?:geoLocationManager.Location,numberData?:number,addedMarkers?: map.Marker[]) {
    this.modeType = modeType;
    this.type = type;
    this.data = data;
    this.location=location;
    this.numberData=numberData
    this.addedMarkers=addedMarkers
  }




}

export enum ModeType{
  FlightControl=0,
  Page=1
}