import {TcpConnection,TcpConfig} from "../connect/TcpConnection"

/**
 * tcp 通讯心跳
 */
export class HeartbeatTcpConnection extends TcpConnection {
  private heartbeatInterval: number = 1000; // 默认5秒间隔
  private heartbeatTimer: number | null = null;
  private heartbeatData: Uint8Array = new Uint8Array([0x0, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x25, 0x25]); // 心跳包内容

  // 设置心跳参数
  setHeartbeatConfig(intervalMs: number, data: Uint8Array) {
    this.heartbeatInterval = intervalMs;
    this.heartbeatData = data;
  }

  // 重写连接方法
  override async connect(config: TcpConfig): Promise<void> {
    await super.connect(config);
    this.startHeartbeat();
  }

  // 开启心跳定时器
  private startHeartbeat() {
    this.heartbeatTimer = setInterval(() => {
      if (this.sendData(this.heartbeatData)) {
        console.log("Heartbeat sent successfully");
      } else {
        console.warn("Failed to send heartbeat");
        this.stopHeartbeat();
      }
    }, this.heartbeatInterval)  as number;
  }

  // 停止心跳
  private stopHeartbeat() {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
  }

  // 重写断开连接
  override disconnect(): void {
    this.stopHeartbeat();
    super.disconnect();
  }
}