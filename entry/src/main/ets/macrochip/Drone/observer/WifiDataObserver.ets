import { AnalysisListener } from '../../../listeners/AnalysisListener';


/**
 * WiFi数据观察者类，用于处理WiFi相关的消息包并通知监听器
 */
export class WifiDataObserver {
  /**
   * 云台预热状态
   */
  public static readonly NOTIFY_PTZ_STATS: number = 4038;

  /**
   * 云台预热状态
   */
  public static readonly NOTIFY_PTZ_ANGLE: number = 4039;

  /**
   * 云台预热状态
   */
  public static readonly NOTIFY_FLOW: number = 4040;

  /**
   * SD卡分辨率
   */
  public static readonly NOTIFY_SD_CARD_RESOLUTION: number = 4041;

  /**
   * WiFi数据解析
   * 
   * @param analysisListener 分析监听器
   * @param data 数据字节数组
   */
  public static build(analysisListener: AnalysisListener | null, data: Uint8Array): void {
    switch (data[3]) {
      case 0x06:  // 检测中继
       // WifiConnectManager.getInstance().supportRelay(data);
        break;
      case 0x07:  // PTZ预热状态
        if (analysisListener !== null) {
          analysisListener.data(WifiDataObserver.NOTIFY_PTZ_STATS, new Uint8Array([data[4]]));
        }
        break;
      case 0x15:  // PTZ角度
        if (analysisListener !== null) {
          analysisListener.data(WifiDataObserver.NOTIFY_PTZ_ANGLE, new Uint8Array([data[5]]));
        }
        break;
      case 0x28:  // 鑫立光流状态
        if (analysisListener !== null) {
          analysisListener.data(WifiDataObserver.NOTIFY_FLOW, new Uint8Array([data[4]]));
        }
        break;
      case 0x16:  // SD卡分辨率
        if (analysisListener !== null) {
          analysisListener.data(WifiDataObserver.NOTIFY_SD_CARD_RESOLUTION, new Uint8Array([data[4]]));
        }
        break;
      case 0x25:
      //  WifiConnectManager.getInstance().relayVersion(data);
        break;
    }
  }

  /**
   * 判断是否为WiFi数据
   * 
   * @param data 数据字节数组
   * @returns 是否为WiFi数据
   */
  public static isWifiData(data: Uint8Array): boolean {
    return data.length >= 5
      && data[0] === 0xff
      && data[1] === 0x53
      && data[2] === 0x54;
  }
}