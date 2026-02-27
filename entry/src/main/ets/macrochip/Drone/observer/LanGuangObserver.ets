import { AnalysisListener } from '../../../listeners/AnalysisListener';
import { MessagePacket } from '../core/message/MessagePacket';
import { DroneCodeManager } from '../code/DroneCodeManager';

import { ObjectUtils } from '../../../utils/ObjectUtils';
import { HyDroneCode } from '../code/HyDroneCode';
import { LgDroneCode } from '../code/LgDroneCode';


/**
 * 蓝光协议解析类，用于处理蓝光/黑飞协议的消息包并通知监听器
 */
export class LanGuangObserver {
  /**
   * 飞机状态信息8b
   */
  public static readonly TYPE_DRONE_STATUS: number = 3000;

  /**
   * 应答环绕提示 0x83
   */
  public static readonly TYPE_AROUND_INFO: number = 3001;

  /**
   * GPS位置信息
   */
  public static readonly TYPE_GPS_INFO_8C: number = 3002;

  /**
   * 航点信息
   */
  public static readonly TYPE_POINT_INFO: number = 3003;

  /**
   * 基本设置信息
   */
  public static readonly TYPE_SETTING_INFO: number = 3004;

  /**
   * 黑飞--返回飞机实时信息3
   */
  public static readonly TYPE_REAL_TIME_INFO_8E: number = 3005;

  /**
   * 黑飞--返回飞机实时信息8f
   */
  public static readonly TYPE_REAL_TIME_INFO_8F: number = 3006;

  /**
   * 黑飞--返回飞机实时信息3B
   */
  public static readonly TYPE_TEST_INFO_8D: number = 3007;

  /**
   * GPS位置信息
   */
  public static readonly TYPE_GPS_INFO_9D: number = 3008;

  /**
   * GPS位置信息
   */
  public static readonly TYPE_GPS_INFO_9C: number = 3009;

  /**
   * 设置信息
   */
  public static readonly TYPE_SETTING_INFO_9A: number = 3010;

  /**
   * 设置信息
   */
  public static readonly TYPE_SETTING_INFO_AB: number = 3011;

  /**
   * 设置信息
   */
  public static readonly TYPE_SETTING_INFO_9B: number = 3012;

  /**
   * 数据解析
   * 
   * @param analysisListener 分析监听器
   * @param packet 消息包
   */
  public static build(analysisListener: AnalysisListener | null, packet: MessagePacket): void {
    const data: Uint8Array = packet.payload.getBytes();
    
    // 注意：RCLogUtils.addLog(packet.message.getBytes())需要根据实际情况实现
    // RCLogUtils.addLog(packet.message.getBytes());
    
    switch (packet.msgid) {
      case 0x8B:  // 飞机状态信息 蓝光 15 黑飞 18
        if (analysisListener !== null) {
          analysisListener.data(LanGuangObserver.TYPE_DRONE_STATUS, data);
        }
        break;

      case 0x83: // 应答环绕数据接收
        if (analysisListener !== null) {
          analysisListener.data(LanGuangObserver.TYPE_AROUND_INFO, data);
        }
        break;

      case 0x8C: // GPS信息
        if (analysisListener !== null) {
          analysisListener.data(LanGuangObserver.TYPE_GPS_INFO_8C, data);
        }
        break;
      case 0x84: // 应答航点数据接收
        if (analysisListener !== null) {
          analysisListener.data(LanGuangObserver.TYPE_POINT_INFO, data);
        }
        break;
      case 0x8D:
        if (analysisListener !== null) {
          analysisListener.data(LanGuangObserver.TYPE_TEST_INFO_8D, data);
        }
        break;
      case 0x8A: // 应答设置信息
        if (analysisListener !== null) {
          analysisListener.data(LanGuangObserver.TYPE_SETTING_INFO, data);
        }
        break;
      case 0x8E:
        if (analysisListener !== null) {
          analysisListener.data(LanGuangObserver.TYPE_REAL_TIME_INFO_8E, data);
        }
        break;
      case 0x8F:
        const lanGuangCode: string = DroneCodeManager.getInstance().getLanGuangCode();
        if ((lanGuangCode !== null && lanGuangCode !== '') && HyDroneCode.isFx()) {
          LgDroneCode.ISKEYU = false;
          // 慧源-黑飞
          if (analysisListener !== null) {
            analysisListener.data(LanGuangObserver.TYPE_REAL_TIME_INFO_8F, data);
          }
        } else {
          LgDroneCode.ISKEYU = true;
        }
        break;
      case 0x9A:
        if (analysisListener !== null) {
          analysisListener.data(LanGuangObserver.TYPE_SETTING_INFO_9A, data);
        }
        break;
      case 0x9C:
        if (analysisListener !== null) {
          analysisListener.data(LanGuangObserver.TYPE_GPS_INFO_9C, data);
        }
        break;
      case 0x9D:
        if (analysisListener !== null) {
          analysisListener.data(LanGuangObserver.TYPE_GPS_INFO_9D, data);
        }
        break;
      case 0xFE:
      case 0xFD:
        // 注意：packet.message.getBytes()需要根据实际情况实现
        // HackFlyUpgradeUtils.getInstance().onResult(packet.message.getBytes());
        break;
      case 0xAB:
        if (analysisListener !== null) {
          analysisListener.data(LanGuangObserver.TYPE_SETTING_INFO_AB, data);
        }
        break;
      case 0x9B:
        if (analysisListener !== null) {
          analysisListener.data(LanGuangObserver.TYPE_SETTING_INFO_9B, data);
        }
        break;
      case 0xBE:
        const beLog: string = ObjectUtils.arrayBufferToHex(data);
        //LogManager.write(beLog);
        break;
    }
  }
}