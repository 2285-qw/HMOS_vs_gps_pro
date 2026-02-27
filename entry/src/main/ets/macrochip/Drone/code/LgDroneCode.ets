import { DroneCodeManager } from './DroneCodeManager';

/**
 * 蓝光协议飞机类型类，用于定义各种蓝光协议飞机的类型常量
 */
export class LgDroneCode {
  /**
   * 力士
   */
  public static readonly LSLGCY01: string = "LSLGCY01";

  /**
   * 汉诺威
   */
  public static readonly HNWLGC20: string = "HNWLGC20";

  /**
   * 疆域
   */
  public static readonly TXJLGPW0: string = "TXJLGPW0";

  /**
   * 疆域 中继
   */
  public static readonly JYLGMK01: string = "JYLGMK01";

  /**
   * 疆域 5G WIFI版本
   */
  public static readonly JYLGMG01: string = "JYLGMG01";

  /**
   * 疆域
   */
  public static readonly JYLGMJ01: string = "JYLGMJ01";

  /**
   * 美多多-单镜头
   */
  public static readonly MDDHM01X: string = "MDDHM01X";

  /**
   * 美多多-单镜头
   */
  public static readonly MDDHM618: string = "MDDHM618";

  /**
   * 美多多-双镜头
   */
  public static readonly MDDHM02X: string = "MDDHM02X";

  /**
   * 胖胖-单镜头
   */
  public static readonly PPHMH009: string = "PPHMH009";

  /**
   * 胖胖-双镜头
   */
  public static readonly PPHMH108: string = "PPHMH108";

  /**
   * 胖胖
   */
  public static readonly HC7321HM: string = "PPHMH108";

  /**
   * 迪飞达
   */
  public static readonly DFLLG401: string = "DFLLG401";

  /**
   * 科宇双镜头
   */
  public static readonly HC7151HM: string = "HC7151HM";

  /**
   * 华彩单镜头
   */
  public static readonly HC7280HM: string = "HC7280HM";

  /**
   * 飞力特（带我们的云台）
   */
  public static readonly JYLGDB00: string = "JYLGDB00";

  /**
   * 科宇专用
   */
  public static ISKEYU: boolean = false;

  /**
   * 判断是否为支持的无人机类型
   * 
   * @returns 是否为支持的无人机类型
   */
  public static isDroneHas(): boolean {
    const droneCodeManager: DroneCodeManager = DroneCodeManager.getInstance();
    
    if (droneCodeManager.isLanGuangEquals(LgDroneCode.LSLGCY01)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.JYLGMK01)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.JYLGMG01)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.JYLGMJ01)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.HNWLGC20)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.TXJLGPW0)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.MDDHM01X)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.MDDHM618)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.MDDHM02X)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.PPHMH009)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.PPHMH108)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.DFLLG401)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.HC7151HM)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.HC7280HM)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.JYLGDB00)) {
      return true;
    } else if (droneCodeManager.isLanGuangEquals(LgDroneCode.HC7321HM)) {
      return true;
    }
    return false;
  }

  /**
   * 判断是否为迪飞达无人机
   * 
   * @returns 是否为迪飞达无人机
   */
  public static isDFD(): boolean {
    return LgDroneCode.DFLLG401 === DroneCodeManager.getInstance().getLanGuangCode();
  }
}