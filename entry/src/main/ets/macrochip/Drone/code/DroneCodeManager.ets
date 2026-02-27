import { ObjectUtils } from "../../../utils/ObjectUtils";
import { MessagePacket } from "../core/message/MessagePacket";
import { Protocol } from "../core/protocol/Protocol";
import { util } from '@kit.ArkTS';


export enum State {
  IDLE,
  REQUEST_CODE,
  REQUEST_VERSION
}

export interface OnDroneCodeCallBack {
  onRequestStart(state: State): void;
  onRequestComplete(): void;
  onRequestFailed(errorMsg: string): void;
}

export class DroneCodeManager {
  private static readonly TIMEOUT: number = 500;
  private static RETRY_LIMIT: number = 8;
  private static mInstance: DroneCodeManager | null = null;
  private watchdogHandler: number | null = null;
  private requestCount: number = 0;
  private mProtocol: Protocol = Protocol.NONE;
  private state: State = State.IDLE;
  private visonCode: number = 0;
  private visonChildCode: number = 0;
  private liHuangCode: string = '';
  private lanGuangCode: string = '';
  private lanGuangName: string = '';
  private lanGuangVersion: string = '';
  private feiShaCode: number = 0;
  private callBack: OnDroneCodeCallBack | null = null;

  public getmProtocol(): Protocol {
    return this.mProtocol;
  }

  public static getInstance(): DroneCodeManager {
    if (DroneCodeManager.mInstance === null) {
      DroneCodeManager.mInstance = new DroneCodeManager();
    }
    return DroneCodeManager.mInstance;
  }

  private constructor() {
    // HarmonyOS中使用setTimeout/setInterval代替Handler
  }

  /**
   * 循环线程回调
   */
  private watchdogCallback = (): void => {
    if (this.processTimeOut(++this.requestCount)) {
      this.watchdogHandler = setTimeout(this.watchdogCallback, DroneCodeManager.TIMEOUT);
    }
  };

  /**
   * 开始线程
   */
  private startWatchdog(): void {
    this.stopWatchdog();
    this.watchdogHandler = setTimeout(this.watchdogCallback, DroneCodeManager.TIMEOUT) ;
  }

  /**
   * 停止线程
   */
  private stopWatchdog(): void {
    this.requestCount = 0;
    if (this.watchdogHandler !== null) {
      clearTimeout(this.watchdogHandler);
      this.watchdogHandler = null;
    }
  }

  /**
   * 设置无人机的协议
   *
   * @param mProtocol 协议类型
   */
  public setProtocol(mProtocol: Protocol): void {
    this.mProtocol = mProtocol;
  }

  /**
   * 请求无人机客户码，区分不同的客户
   */
  public requestDroneCode(): void {
    DroneCodeManager.RETRY_LIMIT = 30;
    this.startWatchdog();
    this.state = State.REQUEST_CODE;
    if (this.callBack !== null) {
      this.callBack.onRequestStart(this.state);
    }
  
  }

  /**
   * 请求无人机飞控版本号（目前只支撑黑飞协议）
   */
  public requestDroneVersion(): void {
    DroneCodeManager.RETRY_LIMIT = 8;
    this.startWatchdog();
    this.state = State.REQUEST_VERSION;
    if (this.callBack !== null) {
      this.callBack.onRequestStart(this.state);
    }
  
  }

  /**
   * 处理无人机回传数据，解析客户码
   *
   * @param packet 数据包
   */
  public processPacket(packet: MessagePacket): void {
    if (this.state === State.IDLE) {
      return;
    }
    switch (this.mProtocol) {
      case Protocol.VISON:
        if (packet.msgid === 0x06) {
          packet.payload.resetIndex();
          this.visonCode = packet.payload.getByte();
          if (packet.payload.size() >= 2) {
            this.visonChildCode = packet.payload.getByte();
          }
          console.log("伟盛客户码", this.visonCode, this.visonChildCode);
          this.state = State.IDLE;
          this.stopWatchdog();
          if (this.callBack !== null) {
            this.callBack.onRequestComplete();
          }
        }
        break;
      case Protocol.LI_HUANG:
        if (packet.msgid === 0x09) {
          if (packet.payload.size() < 8) {
            break;
          }
          this.liHuangCode = this.getBytesToString(packet.payload.getBytes(), 0, 8);
          console.log("立煌客户码", this.liHuangCode);
          this.state = State.IDLE;
          this.stopWatchdog();
          if (this.callBack !== null) {
            this.callBack.onRequestComplete();
          }
        }
        break;
      case Protocol.LAN_GUANG:
        if (packet.msgid === 0x8A) {
          console.log(ObjectUtils.arrayBufferToHex(packet.payload.getBytes()));
          this.lanGuangCode = this.getBytesToString(packet.payload.getBytes(), 0, 8);
          console.log("蓝光/黑飞客户码", this.lanGuangCode);
          this.state = State.IDLE;
          this.stopWatchdog();
          if (this.callBack !== null) {
            this.callBack.onRequestComplete();
          }
        } else if (packet.msgid === 0xFE) {
          this.lanGuangName = this.getBytesToString(packet.payload.getBytes(), 0, 12);
          this.lanGuangVersion = this.getBytesToString(packet.payload.getBytes(), 12, 12);
          console.log("黑飞飞控版本号", this.lanGuangCode, this.lanGuangName, this.lanGuangVersion);
         // LogManager.writeHyPlaneVer(this.lanGuangName, this.lanGuangVersion);
          this.state = State.IDLE;
          this.stopWatchdog();
          if (this.callBack !== null) {
            this.callBack.onRequestComplete();
          }
        }
        break;
      case Protocol.FEI_SHA:
        if (packet.msgid === 0x0D) {
       /*   const info: FSDeviceInfo = FSDataUtil.convertDeviceInfo(packet.payload.getBytes());
          this.feiShaCode = info.SysId;
          console.log("飞鲨客户码", this.feiShaCode);
          this.state = State.IDLE;
          this.stopWatchdog();
          if (this.callBack !== null) {
            this.callBack.onRequestComplete();
          }*/
        }
        break;
    }
  }

  /**
   * 设置伟盛客户码
   *
   * @param visonCode
   */
  public setVisonCode(visonCode: number): void {
    this.visonCode = visonCode;
  }

  /**
   * 设置伟盛客户码
   *
   * @param visonChildCode
   */
  public setVisonChildCode(visonChildCode: number): void {
    this.visonChildCode = visonChildCode;
  }

  /**
   * 设置立煌客户码
   *
   * @param liHuangCode
   */
  public setLiHuangCode(liHuangCode: string): void {
    this.liHuangCode = liHuangCode;
  }

  /**
   * 设置蓝光/黑飞客户码
   *
   * @param lanGuangCode
   */
  public setLanGuangCode(lanGuangCode: string): void {
    this.lanGuangCode = lanGuangCode;
  }

  /**
   * 设置飞鲨客户码
   *
   * @param feiShaCode
   */
  public setFeiShaCode(feiShaCode: number): void {
    this.feiShaCode = feiShaCode;
  }

  /**
   * 获取伟盛客户码
   *
   * @return 客户码
   */
  public getVisonCode(): number {
    return this.visonCode;
  }

  /**
   * 获取伟盛子客户码
   *
   * @return 子客户码
   */
  public getVisonChildCode(): number {
    return this.visonChildCode;
  }

  /**
   * 获取立煌客户码
   *
   * @return 客户码
   */
  public getLiHuangCode(): string {
    return this.liHuangCode;
  }

  /**
   * 获取蓝光/黑飞客户码
   * 
   * @return 客户码
   */
  public getLanGuangCode(): string {
    return this.lanGuangCode;
  }

  /**
   * 伟盛
   * 对比输入客户码和当前无人机客户码
   * 
   * @param code 要比较的客户码
   * @return 如果相等则返回true，否则返回false
   */
  public isVisonEquals(code: number): boolean {
    return code === this.getVisonCode();
  }

  /**
   * 伟盛子
   * 对比输入客户码和当前无人机客户码
   * 
   * @param code 要比较的客户码
   * @return 如果相等则返回true，否则返回false
   */
  public isVisonChildEquals(code: number): boolean {
    return code === this.getVisonChildCode();
  }

  /**
   * 蓝光/黑飞
   * 对比输入客户码和当前无人机客户码
   * 
   * @param code 要比较的客户码
   * @return 如果相等则返回true，否则返回false
   */
  public isLanGuangEquals(code: string): boolean {
    return code === this.getLanGuangCode();
  }

  /**
   * 蓝光/黑飞
   * 对比输入客户码和当前无人机客户码
   * 
   * @param code 要比较的客户码
   * @return 如果包含则返回true，否则返回false
   */
  public containsLanGuangEquals(code: string): boolean {
    const filteredCode = DroneCodeManager.filterSpecialCharacters(this.getLanGuangCode());
    if (filteredCode !== null) {
      return filteredCode.includes(code);
    }
    return false;
  }

  /**
   * 过滤特殊字符
   * 
   * @param str 要过滤的字符串
   * @return 过滤后的字符串
   */
  public static filterSpecialCharacters(str: string): string {
    // 正则表达式匹配所有非字母数字的字符
    const regex = /[^a-zA-Z0-9]/g;
    // 使用replaceAll方法替换掉匹配的字符
    const filteredStr = str.replace(regex, "");
    console.log("博洋匹配" + filteredStr);
    return filteredStr;
  }

  /**
   * 立煌
   * 对比输入客户码和当前无人机客户码
   * 
   * @param code 要比较的客户码
   * @return 如果相等则返回true，否则返回false
   */
  public isLiHuangEquals(code: string): boolean {
    return code === this.getLiHuangCode();
  }

  /**
   * 飞鲨
   * 对比输入客户码和当前无人机客户码
   * 
   * @param code 要比较的客户码
   * @return 如果相等则返回true，否则返回false
   */
  public isFeishaEquals(code: number): boolean {
    return code === this.getFeiShaCode();
  }

  /**
   * 获取飞鲨客户码
   *
   * @return 客户码
   */
  public getFeiShaCode(): number {
    return this.feiShaCode;
  }

  /**
   * 获取黑飞名称
   *
   * @return 黑飞名称
   */
  public getLanGuangName(): string {
    return this.lanGuangName;
  }

  /**
   * 获取黑飞版本号
   *
   * @return 版本号
   */
  public getLanGuangVersion(): string {
    return this.lanGuangVersion;
  }

  /**
   * 设置回调接口
   *
   * @param callBack 回调接口
   */
  public setCallBack(callBack: OnDroneCodeCallBack): void {
    this.callBack = callBack;
  }

  /**
   * 处理超时逻辑，超过重试次数后回调失败
   *
   * @param count 重试次数
   * @return 是否继续执行
   */
  private processTimeOut(count: number): boolean {
    if (count > DroneCodeManager.RETRY_LIMIT) {
      // 请求超时，通知上层
      this.stopWatchdog();
      this.state = State.IDLE;
      if (this.callBack !== null) {
        this.callBack.onRequestFailed("请求超时");
      }
      return false;
    }
    return true;
  }

  /**
   * 将字节数组转换为字符串
   *
   * @param data 字节数组
   * @param offset 偏移量
   * @param length 长度
   * @return 转换后的字符串
   */
  private getBytesToString(data: Uint8Array, offset: number, length: number): string {
    if (data === null || data.length < offset + length) {
      return "";
    }
    const subArray = data.slice(offset, offset + length);
    return new util.TextDecoder().decode(subArray);
  }
}