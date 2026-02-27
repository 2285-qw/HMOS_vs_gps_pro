/**
 * @Author: Sanerly
 * @CreateDate: 2021/10/20 18:18
 * @Description: 协议头-用于识别协议
 */
export class ProtocolHeader {
  /**
   * 伟盛协议
   */
  public static readonly VISON_0: number = 0xFF;
  public static readonly VISON_1: number = 0xFE;
  public static readonly VISON_GZ: number = 0xAE;

  /**
   * 立煌协议
   */
  public static readonly LI_HUANG_0: number = 0x5A;
  public static readonly LI_HUANG_1: number = 0x60;

  /**
   * 蓝光/黑飞协议
   */
  public static readonly LAN_GUANG: number = 0x58;

  /**
   * 飞鲨协议
   */
  public static readonly FEI_SHA_START: number = 0xA5;
  public static readonly FEI_SHA_END: number = 0x5A;

  /**
   * 比特协议
   */
  public static readonly BI_TE_0: number = 0x42;
  public static readonly BI_TE_1: number = 0x54;
  public static readonly BI_TE_DIRECTION: number = 0x3E;

  /**
   * 私有构造函数，防止实例化
   */
  private constructor() {
    // 防止实例化
  }
}