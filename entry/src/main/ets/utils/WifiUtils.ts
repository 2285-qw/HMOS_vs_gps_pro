
import wifiManager from '@ohos.wifiManager';
import connection from '@ohos.net.connection';
import { matrix4 } from '@kit.ArkUI';



// WiFi详细信息接口
export interface WifiInfo {
  ssid?: string;       // WiFi名称（可能为空，如隐藏SSID）
  bssid?: string;      // 路由器MAC地址
  rssi?: number;       // 信号强度（负值，越接近0信号越强）
  ipAddress?: string;  // 设备获取的IP地址
  isSecure?: boolean;  // 是否加密
}

export class WifiUtils{



 public static   getWIFIIP(): string {
    console.error("开始");
    // 检查网络连接状态
    let netHandle = connection.getDefaultNetSync();
    if (netHandle.netId === 0) {
      console.error("未连接网络");
      return '';
    }
    // 验证是否为WIFI网络
    let netCapability = connection.getNetCapabilitiesSync(netHandle);
    if (!netCapability.bearerTypes.includes(connection.NetBearType.BEARER_WIFI)) {
      console.error("当前非WIFI网络");
      return '';
    }
    console.error("开始11111");
    // 获取WIFI连接信息
    let linkedInfo = wifiManager.getIpInfo();
    /*console.error("IP地址: " + linkedInfo.gateway); // IP地址
    this.ip = WifiUtils.intToIpv4(linkedInfo.gateway);
    console.error("IP地址: " + this.ip); // IP地址
    *//* console.log("MAC地址: " + linkedInfo.macAddress);     // MAC地址（随机地址）
     console.log("SSID: " + linkedInfo.ssid);              // 网络名称
     console.log("信号强度: " + linkedInfo.rssi + "dBm");  // 信号强度*//*

    // this.CreateTCPConnection();

    this.createUdpClient();*/
    return WifiUtils.intToIpv4(linkedInfo.gateway);

  }

  /**
   * 将整数形式的IPv4地址转换为点分十进制格式
   * @param ipInt 整数形式的IPv4地址（如3232235777）
   * @returns 点分十进制IP（如"192.168.1.101"）
   */
  public static  intToIpv4(ipInt: number): string {
    if (ipInt < 0 || ipInt > 0xFFFFFFFF) {
      throw new Error("无效的IPv4整数");
    }
    // 拆分为4个字节（按大端字节序，高位到低位）
    const byte1 = (ipInt >>> 24) & 0xFF; // 最高8位
    const byte2 = (ipInt >>> 16) & 0xFF;
    const byte3 = (ipInt >>> 8) & 0xFF;
    const byte4 = ipInt & 0xFF; // 最低8位
    return `${byte1}.${byte2}.${byte3}.${byte4}`;
  }







  /**
   * 监听WiFi连接状态变化（注册回调）
   * @param callback 状态变化回调
   */
  onWifiStateChange(callback: (info: WifiInfo) => void): void {
    // 监听网络连接变化
    /*   connection.on('netStatusChange', async () => {
         const info = await this.getWifiInfo();
         callback(info);
       });*/
    wifiManager.on('wifiStateChange', (state: number) => {
      if (state === wifiManager.ConnState.CONNECTED) {
        console.log('Wi-Fi已连接');
      } else if (state === wifiManager.ConnState.DISCONNECTED) {
        console.log('Wi-Fi已断开');
      }
    });
  }

  /**
   * 取消监听WiFi状态变化
   */
  offWifiStateChange() {
    wifiManager.off('wifiStateChange');
  }

}