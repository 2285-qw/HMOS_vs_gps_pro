// 定义数据类型
export  class PageSendData {
  modeType:ModeType=ModeType.FlightControl//0是飞控数据 1是页面交互数据
  type: number = 0;
  data?: Uint8Array

  constructor(modeType: number, type: number, data?: Uint8Array) {
    this.modeType = modeType;
    this.type = type;
    this.data = data;
  }

}

export enum ModeType{
  FlightControl=0,
  Page=1
}