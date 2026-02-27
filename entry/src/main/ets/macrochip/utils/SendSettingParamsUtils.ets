/**
 * 距离等参数设置
 * Created by XiaoShu
 * 2021/7/16
 */

import { PreferencesUtil } from './PreferencesUtil';

import { BusinessError } from '@kit.BasicServicesKit';
import { DroneCodeManager } from '../Drone/code/DroneCodeManager';
import { Protocol } from '../Drone/core/protocol/Protocol';
import { SJHySettingBean } from '../mode/SJHySettingBean';
import { LanGuangDataConverter } from '../FunctionalAnalysis/LanGuangDataConverter';
import EntryAbility from '../../entryability/EntryAbility';
import { PlayInfo } from '../../model/PlayInfo';
import { Hy1BBean } from '../mode/Hy1BBean';
import { taskpool } from '@kit.ArkTS';





// 1. 定义并发函数（需用@Concurrent装饰器标记）
@Concurrent
function repeatMethod(distance: number, altitude: number, returnAltitude: number,SendSettingParamsUtils:SendSettingParamsUtils): void {
  console.log(`执行第 ============ 次`);
  // 此处替换为实际业务逻辑
  SendSettingParamsUtils.setdata( distance,altitude,returnAltitude);
}

/**
 * 发送设置参数工具类
 */
export class SendSettingParamsUtils {
  private static instance: SendSettingParamsUtils | null = null;

  private chinese: boolean = true; // 暂时硬编码，需要根据实际情况修改
  private sendSuccess: boolean = false;
  private isNovice: boolean = false;
  private distance: number = 0;
  private altitude: number = 0;
  private returnAltitude: number = 0;
  private settingDistance: number = 0; // 已设置的距离
  public static isSetSave: boolean = false;

  /**
   * 构造函数
   */
  private constructor() {


  }

  /**
   * 获取单例实例
   * @returns SendSettingParamsUtils 实例
   */
  public static getInstance(): SendSettingParamsUtils {
    if (SendSettingParamsUtils.instance === null) {
      SendSettingParamsUtils.instance = new SendSettingParamsUtils();
    }
    return SendSettingParamsUtils.instance;
  }

  /**
   * 请求发送设置数据
   */
  public requestSet(): void {
    const isNovice: boolean =PreferencesUtil.getData(PreferencesUtil.NOVICE, false) as boolean;
    const distance: number = PreferencesUtil.getData(PreferencesUtil.DISTANCE, PreferencesUtil.mflightDistance) as number;
    const flyAltitude: number = PreferencesUtil.getData(PreferencesUtil.FLY_ALTITUDE, PreferencesUtil.mflightAltitude) as number;
    const returnAltitude: number =PreferencesUtil.getData(PreferencesUtil.RETURN_ALTITUDE, PreferencesUtil.RETURN_ALTITUDE) as number;
    this.settingDistance = distance;
    
    // CustomMapView.CIRCLE_RADIUS = Math.min(distance, 300);

    this.setdata(distance,flyAltitude,returnAltitude);

  }

  public setdata(distance: number, altitude: number, returnAltitude: number){
    let  data:Uint8Array;
    if (DroneCodeManager.getInstance().getmProtocol()==Protocol.LAN_GUANG) {
      if (PlayInfo.isHisi()) {
        data = new Uint8Array(14);
        data[0] = 0x68;
        data[1] = 0x1b;
        data[2] = 0x0a;
        let bean: Hy1BBean = new Hy1BBean()
        bean.UseMagDec = 0;
        bean.MagDec = 0;
        bean.Limhigh = altitude;
        bean.Limdistance = distance;
        bean.Gohomehigh = returnAltitude;
        bean.Gohomehigh2 = 0;
        let newData = LanGuangDataConverter.convertHy1BBean(bean)
        data.set(newData, 3)
        data[13] = (data[1] ^ data[2] ^ data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[7]
          ^ data[8] ^ data[9] ^ data[10] ^ data[11] ^ data[12]);
        EntryAbility.getInstance().sendUDPCmd(data)
      } else {
        data = new Uint8Array(10);
        data[0] = 0x68;
        data[1] = 0x1a;
        data[2] = 0x06;
        let bean: SJHySettingBean = new SJHySettingBean();
        bean.Limhigh = altitude;
        bean.Limdistance = (distance);
        bean.Gohomehigh = returnAltitude;

        let newData = LanGuangDataConverter.convertSJHySettingBean(bean)
        data.set(newData, 3)
        data[9] = (data[1] ^ data[2] ^ data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[7]
          ^ data[8] ^ data[9]);

        EntryAbility.getInstance().sendUDPCmd(data)
      }
    }
  }

  /**
   * 发送设置
   * @param isNovice 是否新手模式
   * @param distance 距离
   * @param altitude 高度
   * @param returnAltitude 返航高度
   */
  public sendSetting(isNovice: boolean, distance: number, altitude: number, returnAltitude: number): void {
    this.sendSuccess = false;
    this.isNovice = isNovice;
    this.distance = distance;
    this.altitude = altitude;
    this.returnAltitude = returnAltitude;



    setTimeout(() => {
      this.setdata( distance,altitude,returnAltitude);
    }, 1000);

    for (let i = 0; i < 5; i++) {
      try {
        // 将任务提交到任务池
        taskpool.execute(repeatMethod,distance,altitude,returnAltitude,SendSettingParamsUtils.instance);
      } catch (err) {
        console.error(`第 ${i + 1} 次执行失败:`, err);
      }
    }


  }


  /**
   * 设置成功 保存参数
   */
  public sendsaveSuccess(): void {

    this.sendSuccess = true;
    this.settingDistance = this.distance;
    
    // 保存参数
   PreferencesUtil.saveData(PreferencesUtil.NOVICE, this.isNovice);
   PreferencesUtil.saveData(PreferencesUtil.DISTANCE, this.distance);
   PreferencesUtil.saveData(PreferencesUtil.FLY_ALTITUDE, this.altitude);
   PreferencesUtil.saveData(PreferencesUtil.RETURN_ALTITUDE, this.returnAltitude);
  }

  /**
   * 获取已设置的距离
   * @returns 已设置的距离
   */
  public getSettingDistance(): number {
    return this.settingDistance;
  }


  /**
   * short转byte数组
   * @param value short值
   * @returns byte数组
   */
  private shortToByte(value: number): number[] {
    const bytes: number[] = [0, 0];
    bytes[0] = value & 0xff;
    bytes[1] = (value >> 8) & 0xff;
    return bytes;
  }
}

