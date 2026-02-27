// CommHeartbeat.ets
import { OnHeartbeatListener } from './OnHeartbeatListener';
import { HeartbeatState, HeartbeatEvent } from './HeartbeatState';
import emitter from '@ohos.events.emitter';


/**
 * 心跳检测管理类
 * 用于监测设备通信的心跳状态
 */
export class CommHeartbeat {
  // 超时时间配置
  private static readonly CONNECTION_TIMEOUT: number = 1000 * 10;    // 连接超时：10秒
  private static readonly HEARTBEAT_NORMAL_TIMEOUT: number = 1000 * 10;  // 正常心跳超时：10秒
  private static readonly HEARTBEAT_LOST_TIMEOUT: number = 1000 * 10;    // 心跳丢失超时：10秒

  private heartbeatState: HeartbeatState = HeartbeatState.NONE;  // 当前心跳状态
  private onHeartbeatListener: OnHeartbeatListener | null = null;  // 心跳监听器
  private watchdogTimerId: number = -1;  // 定时器ID
  private isRunning: boolean = false;    // 是否正在运行

  /**
   * 设置心跳监听器
   */
  setOnHeartbeatListener(listener: OnHeartbeatListener): void {
    this.onHeartbeatListener = listener;
  }

  /**
   * 处理心跳超时
   */
  private onHeartbeatTimeout(): void {
    console.info('CommHeartbeat', '客户端心跳：连接丢失');

    // 通知监听器
    if (this.onHeartbeatListener) {
      this.onHeartbeatListener.onCommunicationLost();
    }

    // 发送事件通知
    this.emitEvent(HeartbeatEvent.COMMUNICATION_LOST);

    // 更新状态
    this.heartbeatState = HeartbeatState.LOST;

    // 重启定时器
    this.restartWatchdog(CommHeartbeat.HEARTBEAT_LOST_TIMEOUT);
  }

  /**
   * 当接收到心跳时调用
   */
  onHeartbeat(): void {
    switch (this.heartbeatState) {
      case HeartbeatState.NONE:
        console.info('CommHeartbeat', '客户端心跳：连接成功');

        if (this.onHeartbeatListener) {
          this.onHeartbeatListener.onCommunicationSuccess();
        }

        this.emitEvent(HeartbeatEvent.COMMUNICATION_SUCCESS);
        break;

      case HeartbeatState.LOST:
        console.info('CommHeartbeat', '客户端心跳：连接断开后，重新恢复');

        if (this.onHeartbeatListener) {
          this.onHeartbeatListener.onCommunicationRestore();
        }

        this.emitEvent(HeartbeatEvent.COMMUNICATION_RESTORE);
        break;

      // HeartbeatState.NORMAL 正常心跳不需要额外处理
    }

    // 更新状态为正常
    this.heartbeatState = HeartbeatState.NORMAL;

    // 重启定时器
    this.restartWatchdog(CommHeartbeat.HEARTBEAT_NORMAL_TIMEOUT);
  }

  /**
   * 重启心跳检测定时器
   * @param timeout 超时时间(毫秒)
   */
  private restartWatchdog(timeout: number): void {
    // 清除之前的定时器
    this.clearWatchdog();

    // 设置新的定时器
    this.watchdogTimerId = setTimeout(() => {
      this.onHeartbeatTimeout();
    }, timeout);

    this.isRunning = true;
  }

  /**
   * 清除定时器
   */
  private clearWatchdog(): void {
    if (this.watchdogTimerId !== -1) {
      clearTimeout(this.watchdogTimerId);
      this.watchdogTimerId = -1;
    }
  }

  /**
   * 设备连接中
   */
  connecting(): void {
    this.restartWatchdog(CommHeartbeat.CONNECTION_TIMEOUT);
  }

  /**
   * 设备断开连接
   * 马上通知心跳丢失
   */
  disconnect(): void {
    this.restartWatchdog(100);  // 100ms后触发心跳丢失
  }

  /**
   * 停止心跳检测
   */
  stop(): void {
    this.clearWatchdog();
    this.heartbeatState = HeartbeatState.NONE;
    this.isRunning = false;
  }

  /**
   * 检查是否有心跳
   */
  hasHeartbeat(): boolean {
    return this.heartbeatState !== HeartbeatState.NONE;
  }

  /**
   * 检查连接是否正常
   */
  isConnectionAlive(): boolean {
    return this.heartbeatState === HeartbeatState.NORMAL;
  }

  /**
   * 获取当前心跳状态
   */
  getHeartbeatState(): HeartbeatState {
    return this.heartbeatState;
  }

  /**
   * 发送事件
   * @param event 事件类型
   */
  private emitEvent(event: HeartbeatEvent): void {
    const innerEvent: emitter.InnerEvent = {
      eventId: 1,  // 事件ID
      priority: emitter.EventPriority.HIGH
    };

    // 创建事件数据
    let eventData: Record<string, Object> = {
      "event": String(event),
      "timestamp": Date.now(),
      "state": String(this.heartbeatState)
    };

    // 使用事件发射器发送事件
    emitter.emit(innerEvent, eventData);
  }

  /**
   * 销毁资源
   */
  destroy(): void {
    this.stop();
    this.onHeartbeatListener = null;
  }
}