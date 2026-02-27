import { OnHandleDataListener } from "../listeners/OnHandleDataListener";

// 连接状态枚举
export enum ConnectionState {
  DISCONNECTED = 'DISCONNECTED', // 未连接
  CONNECTING = 'CONNECTING',     // 连接中
  CONNECTED = 'CONNECTED',       // 已连接
  DISCONNECTING = 'DISCONNECTING' // 断开中
}

// 连接回调接口（通知状态、数据、错误）
export interface ConnectionCallback {
  onStateChanged:(state: ConnectionState) => void;
  onDataReceived:(data: Uint8Array) =>  void;
  onError:(errorMsg: string) =>  void;
}

// 连接配置基类（子类可扩展具体参数）
export class ConnectionConfig {
  timeoutMs: number = 5000; // 默认超时时间（5秒）
  constructor(timeoutMs?: number) {
    if (timeoutMs) this.timeoutMs = timeoutMs;
  }
}

// 抽象连接管理类
export abstract class BaseConnection<T extends ConnectionConfig> {
  protected currentState: ConnectionState = ConnectionState.DISCONNECTED;
  protected callback?: ConnectionCallback;
  protected onHandleDataListener?: OnHandleDataListener;
  protected config?: T;

  // 设置回调
  setCallback(callback: ConnectionCallback): void {
    this.callback = callback;
  }

  //设置回调
  setonHandleDataListener(callback: OnHandleDataListener): void {
    this.onHandleDataListener = callback;
  }


  // 获取当前状态
  getState(): ConnectionState {
    return this.currentState;
  }

  // 更新状态并通知回调（通用逻辑）
  protected updateState(newState: ConnectionState): void {
    if (this.currentState !== newState) {
      this.currentState = newState;
      this.callback?.onStateChanged(newState);
      console.log(`Connection state changed: ${newState}`);
    }
  }

  public onHandleData(bufferSize:number,data:Uint8Array){
    this.callback?.onDataReceived(data);
  }

  // 抽象方法：连接（由子类实现）
  abstract connect(config: T): void;

  // 抽象方法：断开连接（由子类实现）
  abstract disconnect(): void;

  // 抽象方法：发送数据（由子类实现）
  abstract sendData(data: Uint8Array): boolean;

  // 抽象方法：接收数据（由子类实现，通常通过回调返回）
  protected abstract receiveData(): void;
}