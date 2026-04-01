import { UsbWriteCommands } from "../../connect/usb/UsbWriteCommands";
import { geoLocationManager } from '@kit.LocationKit';
import EntryAbility from "../../entryability/EntryAbility";

/**
 * @Author: Sanerly 
 * @CreateDate: 2019/7/30 10:54 
 * @Description: 跟随线程
 */
export class LgFollowThread {
  private mLocation: geoLocationManager.Location | null = null;
  private timerId: number | null = null;
  private interval: number = 200; // 默认1秒执行一次

  /**
   * 发送跟随数据
   */
  public sendFollowData(): void {
    if (this.mLocation != null) {
      const lat = Math.round(this.mLocation.latitude * 10000000);
      const lon = Math.round(this.mLocation.longitude * 10000000);
      
      const data = new Uint8Array(12);
      data[0] = 0x68;
      data[1] = 0x02;
      data[2] = 0x08;
      
      // 经度数据（小端模式）
      data[3] = lon & 0xff;
      data[4] = (lon & 0xff00) >> 8;
      data[5] = (lon & 0xff0000) >> 16;
      data[6] = (lon & 0xff000000) >> 24;
      
      // 纬度数据（小端模式）
      data[7] = lat & 0xff;
      data[8] = (lat & 0xff00) >> 8;
      data[9] = (lat & 0xff0000) >> 16;
      data[10] = (lat & 0xff000000) >> 24;
      
      // 计算校验和
      data[11] = data[1] ^ data[2] ^ data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[7] ^ data[8] ^ data[9] ^ data[10];
      
      // 发送数据
      EntryAbility.getInstance().sendUDPCmd(data)
    }
  }

  /**
   * 设置位置信息
   * @param location 位置信息
   */
  public setLocation(location: geoLocationManager.Location): void {
    this.mLocation = location;
  }

  /**
   * 开启定时执行sendFollowData方法
   * @param interval 执行间隔（毫秒），默认1000ms
   */
  public startFollowTimer(interval: number = 200): void {
    // 先停止之前的定时器
    this.stopFollowTimer();
    
    this.interval = interval;
    this.timerId = setInterval(() => {
      this.sendFollowData();
    }, this.interval);
  }

  /**
   * 关闭定时执行
   */
  public stopFollowTimer(): void {
    if (this.timerId !== null) {
      clearInterval(this.timerId);
      this.timerId = null;
    }
  }

  /**
   * 检查定时器是否正在运行
   * @returns 是否正在运行
   */
  public isTimerRunning(): boolean {
    return this.timerId !== null;
  }
}

