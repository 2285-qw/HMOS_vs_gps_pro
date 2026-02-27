import {TcpConnection,TcpConfig} from "../connect/TcpConnection"
import {PlayInfo} from "../model/PlayInfo"
import socket from '@ohos.net.socket';
import { ObjectUtils } from '../utils/ObjectUtils'
import {VideoStreamHandle} from  '../connect/stream/VideoStreamHandle'
//视频流心跳
export class StreamTcpConnection extends TcpConnection {
  private heartbeatInterval: number = 1000; // 默认5秒间隔
  private heartbeatTimer: number | null = null;

  private heart28: Uint8Array = new Uint8Array([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x28, 0x28]); // 心跳包内容

  private heart30: Uint8Array = new Uint8Array([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x30, 0x30]); // 心跳包内容

  private heartbeatData: Uint8Array = this.heart28; // 心跳包内容

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
        console.log("成功发送心跳");
      } else {
        console.warn("心跳发送失败");
        this.stopHeartbeat();
      }
    }, this.heartbeatInterval) ;
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

  /**
   * 更改心跳数据。
   * 根据当前选择的摄像头索引，选择不同的心跳数据。
   */
  public  changeHeartbeatData() {
    if (PlayInfo.cameraIndex == 0) {
     this.heartbeatData = this.heart28;
    } else {
      this.heartbeatData = this.heart30;
    }
  }
  //收到视频流数据
  protected receiveData(): void {
    if (!this.tcpSocket) return;
    this.tcpSocket?.on('message',(data : socket.SocketMessageInfo)=>{
     // this.onHandleData(data.message.byteLength,new Uint8Array(data.message))
     // console.log("视频流数据",ObjectUtils.arrayBufferToHex(new Uint8Array(data.message)))
      VideoStreamHandle.getInstance().addVideoStream(new Uint8Array(data.message),data.message.byteLength)
    })
  }
}