import {OnDeviceConnectionListener,ExternalDevType} from '../../listeners/OnDeviceConnectionListener';
import wifiManager from '@ohos.wifiManager';
import connection from '@ohos.net.connection';

export  class NetworkManager {
  private static instance: NetworkManager;
  private onDeviceConnectionListener?:OnDeviceConnectionListener;

  // 单例模式，确保唯一实例
  private constructor() {
  }

  static getInstance(): NetworkManager {
    if (!NetworkManager.instance) {
      NetworkManager.instance = new NetworkManager();
    }
    return NetworkManager.instance;
  }


  public requestNetwork(onDeviceConnectionListener:OnDeviceConnectionListener){
    this.onDeviceConnectionListener=onDeviceConnectionListener;

    this.IfWifi();
    this.onWifiStateChange();
  }

  //是否连接wifi
  IfWifi():void{
    let netHandle = connection.getDefaultNetSync();
    if (netHandle.netId === 0) {
      console.error("未连接网络");
      return;
    }
    // 验证是否为WIFI网络
    let netCapability = connection.getNetCapabilitiesSync(netHandle);
    if (!netCapability.bearerTypes.includes(connection.NetBearType.BEARER_WIFI)) {
      console.error("当前非WIFI网络");
      return;
    }
    this.onDeviceConnectionListener?.onDeviceConnection(ExternalDevType.WIFI)
  }


  /**
   * 监听WiFi连接状态变化（注册回调）
   * @param callback 状态变化回调
   */
  onWifiStateChange(): void {
    wifiManager.on('wifiConnectionChange', (state: number) => {
      if (state === 1) {
        console.log('Wi-Fi已连接');
        this.onDeviceConnectionListener?.onDeviceConnection(ExternalDevType.WIFI)

      } else if (state === 0) {
        console.log('Wi-Fi已断开');
        this.onDeviceConnectionListener?.onDeviceDisconnection(ExternalDevType.WIFI)
      }
    });
  }


  // 注销网络监听
  unregisterNetwork() {
    // 取消订阅前确认事件已注册
    try {
      wifiManager.off('wifiConnectionChange');
    } catch (error) {
      console.error("off failed: " + JSON.stringify(error));
    }
  }



}