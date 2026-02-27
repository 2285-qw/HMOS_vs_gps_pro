import { DroneCodeManager } from './DroneCodeManager';

/**
 * @Author: Sanerly
 * @Date: 2019/12/12 10:32
 * @Description: 伟盛协议飞机类型
 */
export enum VsDroneCode {
  /**
   * 碧盛禾
   */
  BI_SHENG_HE = 0x00,

  /**
   * 0X01
   */
  JIA_QI = 0x01,

  /**
   * 宝宏
   */
  BAO_HONG = 0x02,

  /**
   * 凯正
   */
  KAI_ZHENG = 0x03,

  /**
   * 奥森码
   */
  AO_SEN_MA = 0x06,

  /**
   * 星海红
   */
  XING_HAI_HONG = 0x07,

  /**
   * 鑫立
   */
  XIN_LI = 0x09,

  /**
   * 正方
   */
  ZHENG_FANG = 0x0a,

  /**
   * 连煌镜头调节
   */
  LIAN_HUANG_0B = 0x0b,

  /**
   * 连煌镜头切换
   */
  LIAN_HUANG_0C = 0x0c,

  /**
   * 发佳
   */
  FA_JA = 0x0d,

  /**
   * 聚成
   */
  JU_CHEN = 0x0f,

  /**
   * 奇诚
   */
  QI_CHENG = 0x11,

  /**
   * 华佳 （带我们的云台-李文军）
   */
  HUA_JIA = 0x12,

  /**
   * 惠鹰
   */
  HUI_YIN = 0x20,

  /**
   * 杜威
   */
  DU_WEI = 0x21,

  /**
   * 华俊
   */
  HUA_JUN = 0x22,

  /**
   * 汉诺威
   */
  HNW = 0x30,

  /**
   * 思阳
   */
  SI_YANG = 0x32,

  /**
   * 银河
   */
  YIN_HE = 0x34,

  /**
   * 凯尔美
   */
  KAI_ER_MEI = 0x35,

  /**
   * 科鹰
   */
  KE_YING = 0x36,

  /**
   * 一可
   */
  YI_KE = 0x37,

  /**
   * 立煌-客户
   */
  LI_HUANG = 0x38,

  /**
   * 立煌-客户
   */
  LI_HUANG_ONE = 0x40
}

export namespace VsDroneCode {
  /**
   * 凯正客板子型号
   */
  export class KaiZheng {
    /**
     * 凯正 X16 型号
     */
    static readonly MODEL_X16: number = 0x01;

    /**
     * 凯正 JJRC 型号
     */
    static readonly MODEL_JJRC: number = 0x02;

    /**
     * 凯正 YL 型号
     */
    static readonly MODEL_YL: number = 0x03;

    /**
     * 凯正 X16 1080P板的型号
     */
    static readonly MODEL_X16_1080P: number = 0x04;
  }

  /**
   * 奥森码子型号
   */
  export class AoSenMa {
    /**
     * 奥森码 033型号
     */
    static readonly MODEL_033: number = 0x01;

    /**
     * 奥森码 活石DE型号 客户未使用
     */
    static readonly MODEL_DE: number = 0x02;

    /**
     * @return 客户未使用
     */
    static isASM_DE(): boolean {
      return DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.AO_SEN_MA) && 
             DroneCodeManager.getInstance().isVisonChildEquals(VsDroneCode.AoSenMa.MODEL_DE);
    }
  }

  /**
   * 思阳飞机型号
   */
  export class SiYang {
    /**
     * 思阳 S16 型号
     */
    static readonly MODEL_X16: number = 0x01;
  }

  /**
   * 鑫立飞机型号
   */
  export class XinLi {
    /**
     * 鑫立距离5000米
     */
    static readonly MODEL_01: number = 0x01;

    /**
     * 鑫立距离插值10000米
     */
    static readonly MODEL_02: number = 0x02;
  }

  /**
   * 科鹰飞机型号
   */
  export class KeYing {
    /**
     * 科鹰-内销插值8k
     */
    static readonly MODEL_01: number = 0x01;

    /**
     * 科鹰-避障功能 内销8k
     */
    static readonly MODEL_02: number = 0x02;

    /**
     * 科鹰-避障功能 外销4k
     */
    static readonly MODEL_03: number = 0x03;

    /**
     * 科鹰-有壁障 距离显示差值10KM 内销8k
     */
    static readonly MODEL_04: number = 0x04;

    /**
     * 科鹰-无壁障 距离显示差值10KM 内销8k
     */
    static readonly MODEL_05: number = 0x05;

    /**
     * 科鹰 视觉避障 特技飞行  8k
     */
    static readonly MODEL_06: number = 0x06;

    /**
     * 科鹰 视觉避障 特技飞行  距离显示差值10KM 8k
     */
    static readonly MODEL_07: number = 0x07;
  }

  /**
   * 奇诚飞机型号
   */
  export class QiCheng {
    /**
     * 中继
     */
    static readonly MODEL_01: number = 0x01;
  }
}