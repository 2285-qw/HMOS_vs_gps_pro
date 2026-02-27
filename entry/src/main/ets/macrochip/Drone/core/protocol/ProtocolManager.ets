/**
 * @Author: Sanerly
 * @CreateDate: 2021/10/21 16:28
 * @Description: 协议管理类，用于识别和管理不同类型的协议
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Protocol } from './Protocol';
import { ProtocolHeader } from './ProtocolHeader';

const DOMAIN = 0x0000;

/**
 * 字节工具类
 */
class ByteUtils {
  /**
   * 将byte转换为int
   * @param byteValue 字节值
   * @returns int值
   */
  static byteToInt(byteValue: number): number {
    return byteValue & 0xFF;
  }
}

export class ProtocolManager {
  private static mInstance: ProtocolManager | null = null;
  // 协议类型
  private  protocol: Protocol = Protocol.NONE;

  /**
   * 获取单例实例
   * @returns ProtocolManager实例
   */
  public static getInstance(): ProtocolManager {
    if (ProtocolManager.mInstance == null) {
      ProtocolManager.mInstance = new ProtocolManager();
    }
    return ProtocolManager.mInstance;
  }

  /**
   * 私有构造函数，防止外部实例化
   */
  private constructor() {
    // 初始化时读取保存的协议
    // this.readProtocol(); // 暂时注释，等待上下文处理
  }

  /**
   * 通过数据识别协议
   * @param data 待识别的数据
   */
  public checkProtocol(data: Uint8Array): void {
    if (data[0] === ProtocolHeader.VISON_0 && data[1] === ProtocolHeader.VISON_1) {
      this.protocol = Protocol.VISON;
    } else if (data[0] === ProtocolHeader.LI_HUANG_0 && data[1] === ProtocolHeader.LI_HUANG_1) {
      this.protocol = Protocol.LI_HUANG;
    } else if (data[0] === ProtocolHeader.LAN_GUANG) {
      this.protocol = Protocol.LAN_GUANG;
    } else if (data[0] === ProtocolHeader.FEI_SHA_START) {
      const length = ByteUtils.byteToInt(data[1]);
      if (data.length >= length && data[length - 1] === ProtocolHeader.FEI_SHA_END) {
        this.protocol = Protocol.FEI_SHA;
      }
    } else if (data.length >= 7 && data[0] === ProtocolHeader.BI_TE_0 &&
      data[1] === ProtocolHeader.BI_TE_1 && data[2] === ProtocolHeader.BI_TE_DIRECTION) {
      this.protocol = Protocol.BI_TE;
    }

    // 日志记录
    const protocolName = this.getProtocolName();
    hilog.info(DOMAIN, 'ProtocolManager', '当前协议 = %{public}s', protocolName);
  }

  /**
   * 获取当前协议类型
   * @returns 协议类型
   */
  public getProtocol(): Protocol {
    return this.protocol;
  }
  // 映射函数
  public getNewProtocolName(): string {
    return Protocol[this.getProtocol()];
  }

  /**
   * 设置协议类型
   * @param protocol 协议类型
   */
  public setProtocol(protocol: Protocol): void {
    this.protocol = protocol;
  }

  /**
   * 检查是否为无协议状态
   * @returns 是否为无协议
   */
  public isNone(): boolean {
    return this.protocol === Protocol.NONE;
  }

  /**
   * 检查是否已识别到协议
   * @returns 是否已识别到协议
   */
  public hasProtocol(): boolean {
    return this.isVison() || this.isLanGuang() || this.isLiHuang() || this.isFeiSha() || this.isBite();
  }

  /**
   * 检查是否为伟盛协议
   * @returns 是否为伟盛协议
   */
  public isVison(): boolean {
    return this.protocol === Protocol.VISON;
  }

  /**
   * 检查是否为蓝光/黑飞协议
   * @returns 是否为蓝光协议
   */
  public isLanGuang(): boolean {
    return this.protocol === Protocol.LAN_GUANG;
  }

  /**
   * 检查是否为立煌协议
   * @returns 是否为立煌协议
   */
  public isLiHuang(): boolean {
    return this.protocol === Protocol.LI_HUANG;
  }

  /**
   * 检查是否为飞沙协议
   * @returns 是否为飞沙协议
   */
  public isFeiSha(): boolean {
    return this.protocol === Protocol.FEI_SHA;
  }

  /**
   * 检查是否为比特协议
   * @returns 是否为比特协议
   */
  public isBite(): boolean {
    return this.protocol === Protocol.BI_TE;
  }

  /**
   * 获取协议名称
   * @returns 协议名称
   */
  public getProtocolName(): string {
    return this.getProtocolNameInner(this.protocol);
  }

  /**
   * 根据协议类型获取协议名称
   * @param protocol 协议类型
   * @returns 协议名称
   */
  private getProtocolNameInner(protocol: Protocol): string {
    switch (protocol) {
      case Protocol.VISON:
        return 'Vison';
      case Protocol.LAN_GUANG:
        return 'LanGuang';
      case Protocol.FEI_SHA:
        return 'FeiSha';
      case Protocol.BI_TE:
        return 'Bite';
      case Protocol.LI_HUANG:
        return 'LiHuang';
      default:
        return 'None';
    }
  }

  /**
   * 根据协议名称获取协议类型
   * @param name 协议名称
   * @returns 协议类型
   */
  public getNameProtocol(name: string): Protocol {
    switch (name) {
      case 'Vison':
        return Protocol.VISON;
      case 'LanGuang':
        return Protocol.LAN_GUANG;
      case 'FeiSha':
        return Protocol.FEI_SHA;
      case 'Bite':
        return Protocol.BI_TE;
      case 'LiHuang':
        return Protocol.LI_HUANG;
      default:
        return Protocol.NONE;
    }
  }
}