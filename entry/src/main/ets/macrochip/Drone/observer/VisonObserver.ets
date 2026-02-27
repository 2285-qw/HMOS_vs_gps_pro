import { AnalysisListener } from '../../../listeners/AnalysisListener';
import { MessagePacket } from '../core/message/MessagePacket';

/**
 * 伟盛协议解析类，用于处理伟盛协议的消息包并通知监听器
 */
export class VisonObserver {
  /**
   * 电量
   */
  public static readonly TYPE_PLANE_V: number = 4000;

  /**
   * 遥控电量
   */
  public static readonly TYPE_CONTROL_V: number = 4001;

  /**
   * 飞机经纬度
   */
  public static readonly TYPE_LOCATION: number = 4002;

  /**
   * GPS信号强度
   */
  public static readonly TYPE_GPS_NUMBER: number = 4003;

  /**
   * 飞机头角度
   */
  public static readonly TYPE_HEAD_ANGLE: number = 4004;

  /**
   * 水平距离
   */
  public static readonly TYPE_LEVEL_DISTANCE: number = 4005;

  /**
   * 垂直距离
   */
  public static readonly TYPE_VERTICAL_DISTANCE: number = 4006;

  /**
   * 垂直速度
   */
  public static readonly TYPE_VERTICAL_SPEED: number = 4007;

  /**
   * 水平速度
   */
  public static readonly TYPE_LEVEL_SPEED: number = 4008;

  /**
   * 遥控拍照或录像
   */
  public static readonly TYPE_PHOTO_VIDEO: number = 4010;

  /**
   * 飞机返回当前设置数据最新定义
   */
  public static readonly TYPE_SETTING_DATA: number = 4011;

  /**
   * 飞机状态
   */
  public static readonly TYPE_DRONE_STATUS: number = 4012;

  /**
   * 飞机设置状态
   */
  public static readonly TYPE_SETTING_STATUS: number = 4013;

  /**
   * 油门，电机转速，电机电流
   */
  public static readonly TYPE_MOTOR_INFO: number = 4014;

  /**
   * 避障
   */
  public static readonly TYPE_OBSTACLE_INFO: number = 4015;

  /**
   * 伟盛数据解析
   * 
   * @param analysisListener 分析监听器
   * @param packet 消息包
   */
  public static build(analysisListener: AnalysisListener | null, packet: MessagePacket): void {
    const data: Uint8Array = packet.payload.getBytes();
    
    switch (packet.msgid) {
      case 0x00:
        // 电量
        if (analysisListener !== null) {
          analysisListener.data(VisonObserver.TYPE_PLANE_V, new Uint8Array([data[0], data[1]]));
          analysisListener.data(VisonObserver.TYPE_CONTROL_V, new Uint8Array([data[2], data[3]]));
          analysisListener.data(VisonObserver.TYPE_LOCATION, new Uint8Array([data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11]]));
          analysisListener.data(VisonObserver.TYPE_GPS_NUMBER, new Uint8Array([data[12]]));
          analysisListener.data(VisonObserver.TYPE_HEAD_ANGLE, new Uint8Array([data[13], data[14]]));
          analysisListener.data(VisonObserver.TYPE_LEVEL_DISTANCE, new Uint8Array([data[15], data[16]]));
          analysisListener.data(VisonObserver.TYPE_VERTICAL_DISTANCE, new Uint8Array([data[17], data[18]]));
          analysisListener.data(VisonObserver.TYPE_LEVEL_SPEED, new Uint8Array([data[19], data[20]]));
          analysisListener.data(VisonObserver.TYPE_VERTICAL_SPEED, new Uint8Array([data[21], data[22]]));
        }
        break;
      case 0x01:
        if (analysisListener !== null) {
          analysisListener.data(VisonObserver.TYPE_PHOTO_VIDEO, data);
        }
        break;
      case 0x02:
        // 飞机状态信息
        if (analysisListener !== null) {
          analysisListener.data(VisonObserver.TYPE_DRONE_STATUS, data);
        }
        break;
      case 0x03:
        if (analysisListener !== null) {
          analysisListener.data(VisonObserver.TYPE_SETTING_DATA, data);
        }
        break;
      case 0x04:
        if (analysisListener !== null) {
          analysisListener.data(VisonObserver.TYPE_MOTOR_INFO, data);
        }
        break;
      case 0x05:
        if (analysisListener !== null) {
          analysisListener.data(VisonObserver.TYPE_SETTING_STATUS, data);
        }
        break;
      case 0x0c:
        if (analysisListener !== null) {
          analysisListener.data(VisonObserver.TYPE_OBSTACLE_INFO, data);
        }
        break;
    }
  }
}