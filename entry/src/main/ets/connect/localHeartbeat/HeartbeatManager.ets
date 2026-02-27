// HeartbeatManager.ets
import { CommHeartbeat } from './CommHeartbeat';
import { OnHeartbeatListener } from './OnHeartbeatListener';

/**
 * 心跳管理器（单例）
 */
export class HeartbeatManager {
  private static instance: HeartbeatManager | null = null;
  private commHeartbeat: CommHeartbeat;
  private listeners: Set<OnHeartbeatListener> = new Set();

  private constructor() {
    this.commHeartbeat = new CommHeartbeat();
    this.setupListeners();
  }

  /**
   * 获取单例实例
   */
  static getInstance(): HeartbeatManager {
    if (!HeartbeatManager.instance) {
      HeartbeatManager.instance = new HeartbeatManager();
    }
    return HeartbeatManager.instance;
  }

  /**
   * 设置监听器
   */
  setOnHeartbeatListener(listener: OnHeartbeatListener): void {
    this.listeners.add(listener);
    this.commHeartbeat.setOnHeartbeatListener({
      onCommunicationSuccess: () => {
        this.listeners.forEach(l => l.onCommunicationSuccess());
      },
      onCommunicationLost: () => {
        this.listeners.forEach(l => l.onCommunicationLost());
      },
      onCommunicationRestore: () => {
        this.listeners.forEach(l => l.onCommunicationRestore());
      }
    });
  }


  /**
   * 移除监听器
   */
  removeOnHeartbeatListener(listener: OnHeartbeatListener): void {
    this.listeners.delete(listener);
  }

  /**
   * 设备连接中
   */
  connecting(): void {
    this.commHeartbeat.connecting();
  }

  /**
   * 设备断开连接
   */
  disconnect(): void {
    this.commHeartbeat.disconnect();
  }

  /**
   * 接收到心跳
   */
  heartbeat(): void {
    this.commHeartbeat.onHeartbeat();
  }

  /**
   * 检查连接是否正常
   */
  isConnectionAlive(): boolean {
    return this.commHeartbeat.isConnectionAlive();
  }

  /**
   * 检查是否有心跳
   */
  hasHeartbeat(): boolean {
    return this.commHeartbeat.hasHeartbeat();
  }

  /**
   * 获取当前心跳状态
   */
  getHeartbeatState(): string {
    return this.commHeartbeat.getHeartbeatState();
  }

  /**
   * 停止心跳检测
   */
  stop(): void {
    this.commHeartbeat.stop();
  }

  /**
   * 销毁管理器
   */
  destroy(): void {
    this.commHeartbeat.destroy();
    this.listeners.clear();
    HeartbeatManager.instance = null;
  }

  /**
   * 设置监听器（内部使用）
   */
  private setupListeners(): void {
    // 可以在这里添加其他监听逻辑
  }
}