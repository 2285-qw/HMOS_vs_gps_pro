

import { AnalysisListener } from '../../../listeners/AnalysisListener';
import { MessagePacket } from '../core/message/MessagePacket';
import { geoLocationManager } from '@kit.LocationKit';
import { LngLat } from '../../../base_map/LngLat';


/**
 * 飞沙数据解析类，用于处理飞沙协议的消息包并执行相关操作
 */
export class FeiShaObserver {
  // 导航类型常量
  public static NT_WayPoint: number = 1;
  public static NT_TakeOff: number = 2;
  public static NT_Land: number = 3;
  public static NT_RTH: number = 4;
  public static NT_Single: number = 5;
  public static NT_Circular: number = 6;
  public static NT_UNLOCKMOTO: number = 7;
  public static NT_Nav_STOP: number = 8;
  public static NT_Nav_Go: number = 9;
  public static NT_Nav_DellAll: number = 10;

  // 数据类型常量
  public static readonly TYPE_DRONE_STATUS: number = 5000;   //飞机状态信息
  public static readonly TYPE_PHOTO_VIDEO: number = 5001;   //遥控拍照录像
  public static readonly TYPE_DEVICE_INFO: number = 5002;   //无人机设备信息
  public static readonly TYPE_TEST_INFO: number = 5003;   //test 状态信息
  public static readonly TYPE_SETTING_DATA: number = 5004;   //电子围栏信息

  /**
   * 处理消息包并通知监听器
   * 
   * @param analysisListener 分析监听器
   * @param packet 消息包
   */
  public static build(analysisListener: AnalysisListener | null, packet: MessagePacket): void {
    const data: Uint8Array = packet.payload.getBytes();
    switch (packet.msgid) {
      case 0x1D:   // 状态信息
        if (analysisListener !== null) {
          analysisListener.data(FeiShaObserver.TYPE_DRONE_STATUS, data);
        }
        break;
      case 0x28:   // 拍照录像命令
        if (analysisListener !== null) {
          analysisListener.data(FeiShaObserver.TYPE_PHOTO_VIDEO, data);
        }
        break;
      case 0x0d:   // 无人机设备信息
        break;
      case 0x09:   // test状态信息
        if (analysisListener !== null) {
          analysisListener.data(FeiShaObserver.TYPE_TEST_INFO, data);
        }
        break;
      case 0xbb:
        if (analysisListener !== null) {
          analysisListener.data(FeiShaObserver.TYPE_SETTING_DATA, data);
        }
        break;
    }
  }

  /**
   * 起飞
   */
  public static tackOff(): void {
    const data: Uint8Array = new Uint8Array(30);
    data[0] = 0xa5;
    data[1] = 0x1e;
    data[2] = 0x22;
    data[3] = 0x18;
    data[4] = 0;
    data[5] = 1;
    data[6] = 1;
    data[7] = 0;

    // 注意：FSNavDataInfoByLS和FSDataUtil.convertPointDataByLS可能需要从外部导入或模拟
    // 这里假设FSDataUtil.convertPointDataByLS返回一个Uint8Array
    const newData: Uint8Array = new Uint8Array(20); // 假设长度为20
    data.set(newData, 8);

    // 计算校验和
    let checksum: number = 0;
    for (let i = 2; i < 29; i++) {
      checksum ^= data[i];
    }
    data[28] = checksum;
    data[29] = 0x5a;

    // 注意：MyApplication.getInstance().writeUDPCmd(data)需要替换为鸿蒙系统中的相应方法
    // 这里暂时注释掉，需要根据实际情况调整
    // MyApplication.getInstance().writeUDPCmd(data);
  }

  /**
   * 降落
   */
  public static land(): void {
    const data: Uint8Array = new Uint8Array(30);
    data[0] = 0xa5;
    data[1] = 0x1e;
    data[2] = 0x22;
    data[3] = 0x18;
    data[4] = 0;
    data[5] = 1;
    data[6] = 1;
    data[7] = 0;

    // 注意：FSNavDataInfoByLS和FSDataUtil.convertPointDataByLS可能需要从外部导入或模拟
    const newData: Uint8Array = new Uint8Array(20); // 假设长度为20
    data.set(newData, 8);

    // 计算校验和
    let checksum: number = 0;
    for (let i = 2; i < 29; i++) {
      checksum ^= data[i];
    }
    data[28] = checksum;
    data[29] = 0x5a;

    // 注意：MyApplication.getInstance().writeUDPCmd(data)需要替换为鸿蒙系统中的相应方法
    // 这里暂时注释掉，需要根据实际情况调整
    // MyApplication.getInstance().writeUDPCmd(data);
  }

  /**
   * 返航
   */
  public static goHome(): void {
    const data: Uint8Array = new Uint8Array(30);
    data[0] = 0xa5;
    data[1] = 0x1e;
    data[2] = 0x22;
    data[3] = 0x18;
    data[4] = 0;
    data[5] = 1;
    data[6] = 1;
    data[7] = 0;

    // 注意：FSNavDataInfoByLS和FSDataUtil.convertPointDataByLS可能需要从外部导入或模拟
    const newData: Uint8Array = new Uint8Array(20); // 假设长度为20
    data.set(newData, 8);

    // 计算校验和
    let checksum: number = 0;
    for (let i = 2; i < 29; i++) {
      checksum ^= data[i];
    }
    data[28] = checksum;
    data[29] = 0x5a;

    // 注意：MyApplication.getInstance().writeUDPCmd(data)需要替换为鸿蒙系统中的相应方法
    // 这里暂时注释掉，需要根据实际情况调整
    // MyApplication.getInstance().writeUDPCmd(data);
  }

  /**
   * 发送航点数据
   * 
   * @param lngLats 经纬度列表
   * @param altitudel 高度
   */
  public static sendPointData(lngLats:Array<LngLat>, altitudel: number): void {
    for (let i = 0; i < lngLats.length; i++) {
      const data: Uint8Array = new Uint8Array(30);
      data[0] = 0xa5;
      data[1] = 0x1e;
      data[2] = 0x22;
      data[3] = 0x18;
      data[4] = i;
      data[5] = 1;
      data[6] = lngLats.length;
      data[7] = 0;

      // 注意：FSNavDataInfoByLS和FSDataUtil.convertPointDataByLS需要根据实际情况实现
      // 这里假设已经实现了这些类和方法
      /*
      const navDataInfo = {
        NavType: FeiShaObserver.NT_WayPoint,
        Id: i,
        Speed: 40,
        Altitudel: altitudel,
        HoveTime: 0,
        Head: 0,
        Lng: lngLats[i].getLongitude() * 10000000,
        Lat: lngLats[i].getLatitude() * 10000000
      };
      
      const newData: Uint8Array = FSDataUtil.convertPointDataByLS(navDataInfo);
      data.set(newData, 8);
      */

      // 计算校验和
      let checksum: number = 0;
      for (let j = 2; j < 29; j++) {
        checksum ^= data[j];
      }
      data[28] = checksum;
      data[29] = 0x5a;

      // 注意：MyApplication.getInstance().writeTCPCmd(data)需要替换为鸿蒙系统中的相应方法
      // 这里暂时注释掉，需要根据实际情况调整
      // MyApplication.getInstance().writeTCPCmd(data);
    }
  }

  /**
   * 航点执行
   */
  public static pointGo(): void {
    const data: Uint8Array = new Uint8Array(30);
    data[0] = 0xa5;
    data[1] = 0x1e;
    data[2] = 0x22;
    data[3] = 0x18;
    data[4] = 0;
    data[5] = 1;
    data[6] = 1;
    data[7] = 0;

    // 注意：FSNavDataInfoByLS和FSDataUtil.convertPointDataByLS需要根据实际情况实现
    /*
    const dataInfo = {
      NavType: FeiShaObserver.NT_Nav_Go
    };
    
    const newData: Uint8Array = FSDataUtil.convertPointDataByLS(dataInfo);
    data.set(newData, 8);
    */

    // 计算校验和
    let checksum: number = 0;
    for (let j = 2; j < 29; j++) {
      checksum ^= data[j];
    }
    data[28] = checksum;
    data[29] = 0x5a;

    // 注意：MyApplication.getInstance().writeUDPCmd(data)需要替换为鸿蒙系统中的相应方法
    // 这里暂时注释掉，需要根据实际情况调整
    // MyApplication.getInstance().writeUDPCmd(data);
  }

  /**
   * 停止
   */
  public static Stop(): void {
    const data: Uint8Array = new Uint8Array(30);
    data[0] = 0xa5;
    data[1] = 0x1e;
    data[2] = 0x22;
    data[3] = 0x18;
    data[4] = 0;
    data[5] = 1;
    data[6] = 1;
    data[7] = 0;

    // 注意：FSNavDataInfoByLS和FSDataUtil.convertPointDataByLS需要根据实际情况实现
    /*
    const dataInfo = {
      NavType: FeiShaObserver.NT_Nav_STOP
    };
    
    const newData: Uint8Array = FSDataUtil.convertPointDataByLS(dataInfo);
    data.set(newData, 8);
    */

    // 计算校验和
    let checksum: number = 0;
    for (let j = 2; j < 29; j++) {
      checksum ^= data[j];
    }
    data[28] = checksum;
    data[29] = 0x5a;

    // 注意：MyApplication.getInstance().writeUDPCmd(data)需要替换为鸿蒙系统中的相应方法
    // 这里暂时注释掉，需要根据实际情况调整
    // MyApplication.getInstance().writeUDPCmd(data);
  }

  /**
   * 删除所有航点
   */
  public static dellAll(): void {
    const data: Uint8Array = new Uint8Array(30);
    data[0] = 0xa5;
    data[1] = 0x1e;
    data[2] = 0x22;
    data[3] = 0x18;
    data[4] = 0;
    data[5] = 1;
    data[6] = 1;
    data[7] = 0;

    // 注意：FSNavDataInfoByLS和FSDataUtil.convertPointDataByLS需要根据实际情况实现
    /*
    const dataInfo = {
      NavType: FeiShaObserver.NT_Nav_DellAll
    };
    
    const newData: Uint8Array = FSDataUtil.convertPointDataByLS(dataInfo);
    data.set(newData, 8);
    */

    // 计算校验和
    let checksum: number = 0;
    for (let j = 2; j < 29; j++) {
      checksum ^= data[j];
    }
    data[28] = checksum;
    data[29] = 0x5a;

    // 注意：MyApplication.getInstance().writeUDPCmd(data)需要替换为鸿蒙系统中的相应方法
    // 这里暂时注释掉，需要根据实际情况调整
    // MyApplication.getInstance().writeUDPCmd(data);
  }

  /**
   * 获取设置数据
   */
  public static getSettingData(): void {
    const data: Uint8Array = new Uint8Array(7);
    data[0] = 0xa5;
    data[1] = 0x07;
    data[2] = 0xbb;
    data[3] = 0x03;
    data[4] = 0;
    data[5] = data[2] ^ data[3] ^ data[4];
    data[6] = 0x5a;

    // 注意：MyApplication.getInstance().writeUDPCmd(data)需要替换为鸿蒙系统中的相应方法
    // 这里暂时注释掉，需要根据实际情况调整
    // MyApplication.getInstance().writeUDPCmd(data);
  }

  /**
   * 发送设置数据
   * 
   * @param height 高度限制
   * @param distance 距离限制
   * @param isNovice 是否新手模式
   * @param lastData 上次数据
   */
  public static sendSettingData(height: number, distance: number, isNovice: boolean, lastData: Uint8Array): void {
    // t_fc_setting结构体定义：
    // typedef struct{
    //     uint8_t   set_optflowCtr[2];
    //     uint8_t   vCtrScale;  //垂直操控比例 0 - 128
    //     uint8_t   set_gps_loc;
    //     uint8_t   reservedField3[3];
    //     uint8_t   alarmVtg[2];
    //     uint8_t   reservedField1;   //無效,BIT0:新手模式非新手模式
    //     uint8_t   rthSpeed;
    //     uint8_t   GyroPid[3][6];
    //     uint8_t   AttPid[6];
    //     uint8_t   AltPid[6];
    //     uint8_t   GpsSpdPid[6];
    //     uint16_t  AltLimit;       //高度限制 单位 厘米
    //     uint32_t  DistanceLimit;  //距离限制  单位 厘米
    // }t_fc_setting;

    const data: Uint8Array = new Uint8Array(63);
    data[0] = 0xa5;
    data[1] = 0x3f;
    data[2] = 0xbb;
    data[3] = 0x39;
    data[4] = 0xA3;

    // 复制上次数据
    for (let i = 0; i < lastData.length; i++) {
      data[i + 5] = lastData[i];
    }

    // 新手模式设置
    const novice: number = isNovice ? 1 : 0;
    data[14] = novice;

    // 高度设置（范围0-250厘米）
    // 注意：这里需要实现bytesToShort方法，或者使用其他方式转换
    // 暂时使用简单的转换方式
    data[53] = (height >> 8) & 0xff;
    data[54] = height & 0xff;

    // 距离设置（范围0-250厘米）
    // 注意：这里需要实现intToBytes方法，或者使用其他方式转换
    // 暂时使用简单的转换方式
    data[57] = (distance >> 24) & 0xff;
    data[58] = (distance >> 16) & 0xff;
    data[59] = (distance >> 8) & 0xff;
    data[60] = distance & 0xff;

    // 计算校验和
    data[61] = 0;
    for (let i = 2; i < data.length - 3; i++) {
      data[61] ^= data[i];
    }
    data[62] = 0x5a;

    // 注意：MyApplication.getInstance().writeUDPCmd(data)需要替换为鸿蒙系统中的相应方法
    // 这里暂时注释掉，需要根据实际情况调整
    // MyApplication.getInstance().writeUDPCmd(data);
  }

  /**
   * 解锁
   */
  public static unLock(): void {
    const data: Uint8Array = new Uint8Array(30);
    data[0] = 0xa5;
    data[1] = 0x1e;
    data[2] = 0x22;
    data[3] = 0x18;
    data[4] = 0;
    data[5] = 1;
    data[6] = 1;
    data[7] = 0;

    // 注意：FSNavDataInfoByLS和FSDataUtil.convertPointDataByLS需要根据实际情况实现
    /*
    const dataInfo = {
      NavType: FeiShaObserver.NT_TakeOff,
      Altitudel: 0
    };
    
    const newData: Uint8Array = FSDataUtil.convertPointDataByLS(dataInfo);
    data.set(newData, 8);
    */

    // 计算校验和
    let checksum: number = 0;
    for (let j = 2; j < 29; j++) {
      checksum ^= data[j];
    }
    data[28] = checksum;
    data[29] = 0x5a;

    // 注意：MyApplication.getInstance().writeUDPCmd(data)需要替换为鸿蒙系统中的相应方法
    // 这里暂时注释掉，需要根据实际情况调整
    // MyApplication.getInstance().writeUDPCmd(data);
  }
}