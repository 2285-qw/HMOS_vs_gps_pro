import { BaseConnection, ConnectionState, ConnectionConfig, ConnectionCallback } from './BaseConnection';
import socket from '@ohos.net.socket';
import { BusinessError } from '@ohos.base';
import { ConnectionType, OnHandleDataListener } from '../listeners/OnHandleDataListener';
import { ExternalDevType } from '../listeners/OnDeviceConnectionListener';


// TCP连接配置（扩展基类，增加IP和端口）
export class TcpConfig extends ConnectionConfig {
  ip: string;
  port: number;
  constructor(ip: string, port: number, timeoutMs?: number) {
    super(timeoutMs);
    this.ip = ip;
    this.port = port;
  }
}

// TCP连接实现类
export class TcpConnection extends BaseConnection<TcpConfig> {
  public  tcpSocket?: socket.TCPSocket;


  async connect(config: TcpConfig): Promise<void> {
    this.config = config;
    this.updateState(ConnectionState.CONNECTING);

    try {
      // 创建TCP socket
      this.tcpSocket = socket.constructTCPSocketInstance();

      // 绑定连接成功事件
      this.tcpSocket.on('connect', () => {
        this.updateState(ConnectionState.CONNECTED);
        this.receiveData(); // 启动接收
      });

      // 绑定错误事件
      this.tcpSocket.on('error', (err: BusinessError) => {
        this.callback?.onError(`TCP error: ${err.message}`);
        this.disconnect();
      });

      // 绑定关闭事件
      this.tcpSocket.on('close', () => {
        this.updateState(ConnectionState.DISCONNECTED);
      });

      // 发起连接
      await this.tcpSocket.connect({
        address: {
          //type: 1, // IPv4
          address: config.ip,
          port: config.port
        },
        timeout: config.timeoutMs
      });
      console.log("tcp连接执行")
    } catch (err) {
      const error = err as BusinessError;
      this.callback?.onError(`TCP connect failed: ${error.message}`);
      console.log(`tcp连接报错：${ config.port}==========`)
      this.updateState(ConnectionState.DISCONNECTED);
    }
  }

  disconnect(): void {
    if (this.currentState === ConnectionState.DISCONNECTED) return;
    this.updateState(ConnectionState.DISCONNECTING);

    this.tcpSocket?.close((err) => {
      if (err) {
        this.callback?.onError(`TCP close failed: ${(err as BusinessError).message}`);
      }
      this.tcpSocket = undefined;
      this.updateState(ConnectionState.DISCONNECTED);
    });
  }

  sendData(data: Uint8Array): boolean {
    if (this.currentState !== ConnectionState.CONNECTED || !this.tcpSocket) {
      return false;
    }

    try {
      this.tcpSocket.send({ data: data.buffer });
      return true;
    } catch (err) {
      this.callback?.onError(`TCP send failed: ${(err as BusinessError).message}`);
      this.disconnect();
      return false;
    }
  }

  //接收tcp通讯心跳
  protected receiveData(): void {
    if (!this.tcpSocket) return;
    this.tcpSocket?.on('message',(data : socket.SocketMessageInfo)=>{
      this.onHandleData(data.message.byteLength,new Uint8Array(data.message))

      this.onHandleDataListener?.onHandleData(ConnectionType.TCP,ExternalDevType.WIFI,new Uint8Array(data.message))
    })
  }


}