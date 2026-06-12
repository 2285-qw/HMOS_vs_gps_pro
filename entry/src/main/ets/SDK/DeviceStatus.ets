/**
 * 设备状态信息解析结果类
 */
export class DeviceStatus {
  public version: number = 0; // 版本 (uint8)
  public ptzStatus: number = 0; // 云台状态 (uint8)
  public gimbalPit: number = 0; // 云台俯仰角 (int8)
  public gimbalYaw: number = 0; // 云台偏航角 (int8)
  public sdState: number = 0; // SD卡状态 (int8: 0存在,1无卡,2需格式化)
  public sdTotalSize: number = 0; // SD总容量 (uint64, 字节)
  public sdFreeSize: number = 0; // SD空闲容量 (uint64, 字节)
  public fanStatus: number = 0; // 风扇状态 (uint8)
  public cpuTemperature: number = 0; // CPU温度 (int8, ℃)
  public wifiSignalStrength: number = 0; // WiFi信号强度 (int8)
  public wifiTemperature: number = 0; // WiFi温度 (int8, ℃)
  public wifiChannel: number = 0; // WiFi信道 (uint8)
  public live4gSignalStrength: number = 0; // 4G信号强度 (int8)
  public disCoef: number = 0; // 防抖强度 (uint8)
  public sim_operator: number = 0; // 1=移动 2=联通 3=电信
  public reg_4g_status: number = 0; // 1=4G拨号成功 0=拨号失败
  public rtc_status: number = 0; // 1=RTC启动成功 0=RTC启动失败
  public reserved: Uint8Array = new Uint8Array(26); // 预留 26 字节

  toString(): string {
    return `DeviceStatus{` +
      `version=${this.version}, ` +
      `ptzStatus=${this.ptzStatus}, ` +
      `gimbalPit=${this.gimbalPit}, ` +
      `gimbalYaw=${this.gimbalYaw}, ` +
      `sdState=${this.sdState}, ` +
      `sdTotalSize=${this.sdTotalSize}, ` +
      `sdFreeSize=${this.sdFreeSize}, ` +
      `fanStatus=${this.fanStatus}, ` +
      `cpuTemperature=${this.cpuTemperature}, ` +
      `wifiSignalStrength=${this.wifiSignalStrength}, ` +
      `wifiTemperature=${this.wifiTemperature}, ` +
      `wifiChannel=${this.wifiChannel}, ` +
      `live4gSignalStrength=${this.live4gSignalStrength}, ` +
      `disCoef=${this.disCoef}, ` +
      `sim_operator=${this.sim_operator}, ` +
      `reg_4g_status=${this.reg_4g_status}, ` +
      `rtc_status=${this.rtc_status}` +
      `}`;
  }

  textString(): string {
    // 解析SD卡状态描述
    let sdStateDesc: string;
    switch (this.sdState) {
      case 0:
        sdStateDesc = "存在";
        break;
      case 1:
        sdStateDesc = "无卡";
        break;
      case 2:
        sdStateDesc = "需格式化";
        break;
      default:
        sdStateDesc = `未知(${this.sdState})`;
    }

    const sdTotalSizeDesc = this.formatStorageSize(this.sdTotalSize);
    const sdFreeSizeDesc = this.formatStorageSize(this.sdFreeSize);

    return `DeviceStatus{` +
      `版本=0x${(this.version & 0xFF).toString(16)}, ` +
      `云台状态=${this.ptzStatus & 0xFF}, ` +
      `云台俯仰角=${this.gimbalPit}, ` +
      `云台偏航角=${this.gimbalYaw}, ` +
      `SD卡状态=${this.sdState}:${sdStateDesc}, ` +
      `SD总容量=${sdTotalSizeDesc}, ` +
      `SD空闲容量=${sdFreeSizeDesc}, ` +
      `风扇状态=${this.fanStatus & 0xFF}, ` +
      `CPU温度=${this.cpuTemperature}℃, ` +
      `WiFi信号强度=${this.wifiSignalStrength}, ` +
      `WiFi温度=${this.wifiTemperature}℃, ` +
      `WiFi信道=${this.wifiChannel & 0xFF}, ` +
      `4G信号强度=${this.live4gSignalStrength}, ` +
      `防抖强度=${this.disCoef}` +
      `}`;
  }

  /**
   * 格式化存储容量（字节 → MB/GB，保留1位小数）
   * @param sizeInBytes 字节数
   * @returns 格式化后的字符串，如 "1.5GB" 或 "256.0MB"
   */
  private formatStorageSize(sizeInBytes: number): string {
    const mbFactor = 1024 * 1024;
    const gbFactor = mbFactor * 1024;

    if (sizeInBytes >= gbFactor) {
      const gb = sizeInBytes / gbFactor;
      return `${gb.toFixed(1)}GB`;
    } else {
      const mb = sizeInBytes / mbFactor;
      return `${mb.toFixed(1)}MB`;
    }
  }


  /**
   * 从原始字节数组解析设备状态信息
   * @param bytes 原始数据，应至少包含 Device_Status_S 结构体大小：1+1+1+1+1+8+8+1+1+1+1+1+1+1+1+1+1+26 = 58字节
   * @returns DeviceStatus 对象
   */
  public  static DeviceStatusParser(bytes: Uint8Array): DeviceStatus {
    let offset = 0;
    const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);

    const version = view.getUint8(offset);
    offset += 1;
    const ptzStatus = view.getUint8(offset);
    offset += 1;
    // int8_t: 使用 getInt8
    const gimbalPit = view.getInt8(offset);
    offset += 1;
    const gimbalYaw = view.getInt8(offset);
    offset += 1;
    const sdState = view.getInt8(offset);
    offset += 1;
    // uint64_t: 小端，使用 getBigUint64 但需转为 number（假设安全）
    const sdTotalSize = Number(view.getBigUint64(offset, true));
    offset += 8;
    const sdFreeSize = Number(view.getBigUint64(offset, true));
    offset += 8;
    const fanStatus = view.getUint8(offset);
    offset += 1;
    const cpuTemperature = view.getInt8(offset);
    offset += 1;
    const wifiSignalStrength = view.getInt8(offset);
    offset += 1;
    const wifiTemperature = view.getInt8(offset);
    offset += 1;
    const wifiChannel = view.getUint8(offset);
    offset += 1;
    const live4gSignalStrength = view.getInt8(offset);
    offset += 1;
    const disCoef = view.getUint8(offset);
    offset += 1;
    const sim_operator = view.getUint8(offset);
    offset += 1;
    const reg_4g_status = view.getUint8(offset);
    offset += 1;
    const rtc_status = view.getUint8(offset);
    offset += 1;
    // reserved: 26 bytes
    const reserved = new Uint8Array(bytes.buffer, bytes.byteOffset + offset, 26);
    // 注意：不需要偏移增加？但为了完整性
    offset += 26;

    const status = new DeviceStatus();
    status.version = version;
    status.ptzStatus = ptzStatus;
    status.gimbalPit = gimbalPit;
    status.gimbalYaw = gimbalYaw;
    status.sdState = sdState;
    status.sdTotalSize = sdTotalSize;
    status.sdFreeSize = sdFreeSize;
    status.fanStatus = fanStatus;
    status.cpuTemperature = cpuTemperature;
    status.wifiSignalStrength = wifiSignalStrength;
    status.wifiTemperature = wifiTemperature;
    status.wifiChannel = wifiChannel;
    status.live4gSignalStrength = live4gSignalStrength;
    status.disCoef = disCoef;
    status.sim_operator = sim_operator;
    status.reg_4g_status = reg_4g_status;
    status.rtc_status = rtc_status;
    status.reserved = reserved;

    return status;
  }
}