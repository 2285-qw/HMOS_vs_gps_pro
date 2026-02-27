import { AnalysisListener } from '../../../listeners/AnalysisListener';
import { MessagePacket } from '../core/message/MessagePacket';

/**
 * 立煌协议解析类，用于处理立煌协议的消息包并通知监听器
 */
export class LiHuangObserver {
  /**
   * 电量
   */
  public static readonly TYPE_PLANE_V: number = 8000;

  /**
   * 遥控电量
   */
  public static readonly TYPE_CONTROL_V: number = 8001;

  /**
   * 飞机经纬度
   */
  public static readonly TYPE_LOCATION: number = 8002;

  /**
   * GPS信号强度
   */
  public static readonly TYPE_GPS_NUMBER: number = 8003;

  /**
   * 飞机头角度
   */
  public static readonly TYPE_HEAD_ANGLE: number = 8004;

  /**
   * 飞机状态
   */
  public static readonly TYPE_DRONE_STATUS: number = 8012;

  /**
   * 飞机设置状态
   */
  public static readonly TYPE_SETTING_STATUS: number = 8013;

  /**
   * 飞机头水平倾斜角度
   */
  public static readonly TYPE_HEAD_HORIZONTAL_ANGLE: number = 8015;

  /**
   * 飞机高度\距离\速度信息
   */
  public static readonly TYPE_ELEVATION_INFO: number = 8016;

  /**
   * 遥控拍照
   */
  public static readonly TYPE_SEARCH_PHOTO: number = 8017;

  /**
   * 遥控录像
   */
  public static readonly TYPE_SEARCH_VIDEO: number = 8018;

  /**
   * 跟随
   */
  public static readonly TYPE_INFO_FOLLOW: number = 8019;

  /**
   * 指点飞行
   */
  public static readonly TYPE_POINT_FLY: number = 8020;

  /**
   * 飞行提示
   */
  public static readonly TYPE_FLY_ALERT: number = 8021;

  /**
   * 校准状态提示
   */
  public static readonly TYPE_CORRECT_ALERT: number = 8022;

  /**
   * 飞行提示
   */
  public static readonly TYPE_CLEAR_ALERT: number = 8023;

  /**
   * 立煌数据解析
   * 
   * @param analysisListener 分析监听器
   * @param packet 消息包
   */
  public static build(analysisListener: AnalysisListener | null, packet: MessagePacket): void {
    const data: Uint8Array = packet.payload.getBytes();
    
    switch (packet.msgid) {
      case 0x00:  // 电量
        if (analysisListener !== null) {
          analysisListener.data(LiHuangObserver.TYPE_PLANE_V, new Uint8Array([data[0]]));
          analysisListener.data(LiHuangObserver.TYPE_CONTROL_V, new Uint8Array([data[1]]));
          analysisListener.data(LiHuangObserver.TYPE_DRONE_STATUS, new Uint8Array([data[2]]));
        }
        break;
      case 0x01:
        if (analysisListener !== null) {
          // 经纬度
          analysisListener.data(LiHuangObserver.TYPE_LOCATION, new Uint8Array([data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7]]));
          // gps 信号强度
          analysisListener.data(LiHuangObserver.TYPE_GPS_NUMBER, new Uint8Array([data[8]]));
          // 飞机角度
          analysisListener.data(LiHuangObserver.TYPE_HEAD_ANGLE, new Uint8Array([data[9], data[10]]));
          // 水平倾斜角度 byte1 前后倾斜 byte2 左右倾斜
          analysisListener.data(LiHuangObserver.TYPE_HEAD_HORIZONTAL_ANGLE, new Uint8Array([data[11], data[12]]));
        }
        break;
      case 0x02:  // 距离高度等信息
        if (analysisListener !== null) {
          analysisListener.data(LiHuangObserver.TYPE_ELEVATION_INFO, data);
        }
        break;
      case 0x03:  // 遥控拍照
        if (analysisListener !== null) {
          analysisListener.data(LiHuangObserver.TYPE_SEARCH_PHOTO, data);
        }
        break;
      case 0x04: // 遥控录像
        if (analysisListener !== null) {
          analysisListener.data(LiHuangObserver.TYPE_SEARCH_VIDEO, data);
        }
        break;
      case 0x05: // 状态提示（String）
        if (analysisListener !== null) {
          analysisListener.data(LiHuangObserver.TYPE_FLY_ALERT, data);
        }
        break;
      case 0x06:  // 关闭提示
        if (analysisListener !== null) {
          analysisListener.data(LiHuangObserver.TYPE_CLEAR_ALERT);
        }
        break;
      case 0x07:  // 跟随开关 00=关闭 01=启动
        if (analysisListener !== null) {
          analysisListener.data(LiHuangObserver.TYPE_INFO_FOLLOW, data);
        }
        break;
      case 0x08:  // 指点飞行 01=飞机收到数据 02=开始飞行 03=飞行中断 04=飞行完成 05=不适合飞行
        if (analysisListener !== null) {
          analysisListener.data(LiHuangObserver.TYPE_POINT_FLY, data);
        }
        break;
      case 0x0B:  // 设置和飞机飞行
        if (analysisListener !== null) {
          analysisListener.data(LiHuangObserver.TYPE_SETTING_STATUS, data);
        }
        break;
      case 0x0C:  // 校准状态提示
        if (analysisListener !== null) {
          analysisListener.data(LiHuangObserver.TYPE_CORRECT_ALERT, data);
        }
        break;
    }
  }
}