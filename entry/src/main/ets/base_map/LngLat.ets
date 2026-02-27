/**
 * 经纬度坐标类，用于表示地图上的位置
 */
export class LngLat {
  /**
   * 经度
   */
  private longitude: number;

  /**
   * 纬度
   */
  private latitude: number;

  /**
   * 是否发送成功
   */
  private isSendSuccess: boolean = false;

  /**
   * 构造函数
   * 
   * @param longitude 经度
   * @param latitude 纬度
   */
  constructor(longitude: number, latitude: number) {
    this.longitude = longitude;
    this.latitude = latitude;
  }

  /**
   * 获取经度
   * 
   * @returns 经度值
   */
  public getLongitude(): number {
    return this.longitude;
  }

  /**
   * 获取纬度
   * 
   * @returns 纬度值
   */
  public getLatitude(): number {
    return this.latitude;
  }

  /**
   * 获取是否发送成功
   * 
   * @returns 是否发送成功
   */
  public getSendSuccess(): boolean {
    return this.isSendSuccess;
  }

  /**
   * 设置是否发送成功
   * 
   * @param sendSuccess 是否发送成功
   */
  public setSendSuccess(sendSuccess: boolean): void {
    this.isSendSuccess = sendSuccess;
  }

  /**
   * 转换为字符串表示
   * 
   * @returns 字符串表示
   */
  public toString(): string {
    return `LngLat{longitude=${this.longitude}, latitude=${this.latitude}}`;
  }
}