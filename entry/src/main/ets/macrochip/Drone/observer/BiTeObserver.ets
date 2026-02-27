import { AnalysisListener } from '../../../listeners/AnalysisListener';
import { MessagePacket } from '../core/message/MessagePacket';

/**
 * 比特协议观察者类，用于处理比特协议的消息包并通知监听器
 */
export class BiTeObserver {
  /**
   * 遥控拍照或录像 1: 开始录像 2：停止录像 3：拍照
   */
  public static readonly TYPE_PHOTO_VIDEO: number = 6010;

  /**
   * 距离信息
   */
  public static readonly TYPE_DISTANCE_INFO: number = 6011;

  /**
   * GPS星数
   */
  public static readonly TYPE_GPS_NUMBER: number = 6012;

  /**
   * GPS定位标志
   */
  public static readonly TYPE_GPS_LOCATED: number = 6013;

  /**
   * 飞机经纬度
   */
  public static readonly TYPE_LOCATION: number = 6014;

  /**
   * 电量百分比
   */
  public static readonly TYPE_VOLTAGE: number = 6015;

  /**
   * 各种状态
   */
  public static readonly TYPE_STATUS: number = 6016;

  /**
   * 偏航角
   */
  public static readonly TYPE_ANGLE: number = 6017;

  /**
   * 校准
   */
  public static readonly TYPE_CALIBRATION_STATUS: number = 6018;

  /**
   * 保存距离信息状态
   */
  public static readonly TYPE_SAVE_DISTANCE_STATUS: number = 6019;

  /**
   * 校准2
   */
  public static readonly TYPE_CALIBRATION_STATUS2: number = 6020;

  /**
   * 处理消息包并通知监听器
   * 
   * @param analysisListener 分析监听器
   * @param packet 消息包
   */
  public static build(analysisListener: AnalysisListener | null, packet: MessagePacket): void {
    const data: Uint8Array = packet.payload.getBytes();
    switch (packet.msgid) {
      case 0x6C:
        if (analysisListener !== null) {
          analysisListener.data(BiTeObserver.TYPE_PHOTO_VIDEO, data);
        }
        break;
      case 0x67:
        if (analysisListener !== null) {
          analysisListener.data(BiTeObserver.TYPE_DISTANCE_INFO, new Uint8Array([data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7]]));
          analysisListener.data(BiTeObserver.TYPE_GPS_NUMBER, new Uint8Array([data[8]]));
          analysisListener.data(BiTeObserver.TYPE_GPS_LOCATED, new Uint8Array([data[9]]));
          analysisListener.data(BiTeObserver.TYPE_LOCATION, new Uint8Array([data[10], data[11], data[12], data[13],
                  data[14], data[15], data[16], data[17]]));
          analysisListener.data(BiTeObserver.TYPE_VOLTAGE, new Uint8Array([data[18]]));
        }
        break;
      case 0x66:
        if (analysisListener !== null) {
          analysisListener.data(BiTeObserver.TYPE_ANGLE, new Uint8Array([data[4], data[5]]));
          analysisListener.data(BiTeObserver.TYPE_STATUS, new Uint8Array([data[6]]));
        }
        break;
      case 0x65:
        if (analysisListener !== null) {
          analysisListener.data(BiTeObserver.TYPE_CALIBRATION_STATUS, data);
        }
        break;
      case 0x71:
        if (analysisListener !== null) {
          analysisListener.data(BiTeObserver.TYPE_SAVE_DISTANCE_STATUS, data);
        }
        break;
      case 0x28:
        if (analysisListener !== null) {
          analysisListener.data(BiTeObserver.TYPE_CALIBRATION_STATUS2, new Uint8Array([data[2]]));
        }
        break;
    }
  }
}