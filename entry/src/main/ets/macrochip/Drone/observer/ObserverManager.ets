import { AnalysisListener } from '../../../listeners/AnalysisListener';
import { MessagePacket } from '../core/message/MessagePacket';
import { ProtocolManager } from '../core/protocol/ProtocolManager';
import { VisonObserver } from './VisonObserver';
import { LiHuangObserver } from './LiHuangObserver';
import { LanGuangObserver } from './LanGuangObserver';
import { FeiShaObserver } from './FeiShaObserver';
import { BiTeObserver } from './BiTeObserver';

/**
 * 数据构建与观察管理类，用于根据不同协议类型处理消息包并通知监听器
 */
export class ObserverManager {
  private static mInstance: ObserverManager | null = null;

  /**
   * 获取单例实例
   * 
   * @returns ObserverManager实例
   */
  public static getInstance(): ObserverManager {
    if (ObserverManager.mInstance === null) {
      ObserverManager.mInstance = new ObserverManager();
    }
    return ObserverManager.mInstance;
  }

  /**
   * 私有构造函数，防止外部实例化
   */
  private constructor() {
  }

  /**
   * 订阅数据变化，数据变化后通知监听器
   * 
   * @param analysisListener 分析监听器
   * @param packet 消息包
   */
  public subscribe(analysisListener: AnalysisListener | null, packet: MessagePacket): void {
    const protocolManager: ProtocolManager = ProtocolManager.getInstance();
    
    if (protocolManager.isVison()) {
      VisonObserver.build(analysisListener, packet);
    } else if (protocolManager.isLiHuang()) {
      LiHuangObserver.build(analysisListener, packet);
    } else if (protocolManager.isLanGuang()) {
      LanGuangObserver.build(analysisListener, packet);
    } else if (protocolManager.isFeiSha()) {
      FeiShaObserver.build(analysisListener, packet);
    } else if (protocolManager.isBite()) {
      BiTeObserver.build(analysisListener, packet);
    }
  }
}