import { BaseConnection, ConnectionState, ConnectionConfig, ConnectionCallback } from './BaseConnection';
import socket from '@ohos.net.socket';
import { BusinessError } from '@ohos.base';

// UDP连接配置（扩展基类，增加目标IP、端口和本地端口）
export class UdpConfig extends ConnectionConfig {
  targetIp: string;
  targetPort: number;
  localPort?: number;
  constructor(targetIp: string, targetPort: number, localPort?: number, timeoutMs?: number) {
    super(timeoutMs);
    this.targetIp = targetIp;
    this.targetPort = targetPort;
    this.localPort = localPort;
  }
}

// UDP连接实现类（模拟"连接"概念，绑定本地端口并固定目标地址）
export class UdpConnection extends BaseConnection<UdpConfig> {
  private udpSocket?: socket.UDPSocket;
  private targetAddress?:socket.NetAddress;


  async connect(config: UdpConfig): Promise<void> {
    this.config = config;
    this.targetAddress = {address: config.targetIp, port: config.targetPort };

    this.updateState(ConnectionState.CONNECTING);

    try {
      // 创建UDP socket
      this.udpSocket = socket.constructUDPSocketInstance();

      // 绑定本地端口（可选）
      await this.udpSocket.bind({
        address: config.targetIp, // IPv4
        port: config.localPort || 0, // 0表示随机端口
        family: 1
      });

      // 绑定数据接收事件
      this.udpSocket.on('message', (data:socket.SocketMessageInfo) => {
        // 过滤目标地址的数据（可选）
        this.onHandleData(data.message.byteLength,new Uint8Array(data.message))
      });

      // 绑定错误事件
      this.udpSocket.on('error', (err: BusinessError) => {
        this.callback?.onError(`UDP error: ${err.message}`);
        this.disconnect();
      });

      // 绑定关闭事件
      this.udpSocket.on('close', () => {
        this.updateState(ConnectionState.DISCONNECTED);
      });

      this.updateState(ConnectionState.CONNECTED);
      this.receiveData(); // 实际已通过on('message')监听
    } catch (err) {
      const error = err as BusinessError;
      this.callback?.onError(`UDP bind failed: ${error.message}`);
      this.updateState(ConnectionState.DISCONNECTED);
    }
  }

  disconnect(): void {
    if (this.currentState === ConnectionState.DISCONNECTED) return;
    this.updateState(ConnectionState.DISCONNECTING);

    this.udpSocket?.close((err) => {
      if (err) {
        this.callback?.onError(`UDP close failed: ${(err as BusinessError).message}`);
      }
      this.udpSocket = undefined;
      this.targetAddress = undefined;
      this.updateState(ConnectionState.DISCONNECTED);
    });
  }

  sendData(data: Uint8Array): boolean {
    if (this.currentState !== ConnectionState.CONNECTED || !this.udpSocket || !this.targetAddress) {
      return false;
    }

    try {
      this.udpSocket.send({
        data: data.buffer,
        address: {
          address: this.targetAddress.address,
          port: this.targetAddress.port
        }
      });
      return true;
    } catch (err) {
      this.callback?.onError(`UDP send failed: ${(err as BusinessError).message}`);
      return false;
    }
  }

  protected receiveData(): void {
    // UDP通过on('message')监听，此处为空实现
  }
}