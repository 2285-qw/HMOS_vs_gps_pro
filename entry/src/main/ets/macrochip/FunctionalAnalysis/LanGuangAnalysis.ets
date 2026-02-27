import { LGPlaneHyBean } from '../../macrochip/mode/LGPlaneHyBean';
import { SJHyInfo9CBean } from '../../macrochip/mode/SJHyInfo9CBean';
import { SJHyGetSettingBean } from '../../macrochip/mode/SJHyGetSettingBean';
import { SJHyInfo9BBean } from '../../macrochip/mode/SJHyInfo9BBean';
import { HyABBean } from '../../macrochip/mode/HyABBean';
import { LGPlaneGpsBean } from '../../macrochip/mode/LGPlaneGpsBean';
import { LGPlaneGpsBean2 } from '../../macrochip/mode/LGPlaneGpsBean2';
import { LGGetFlyLineBean } from '../../macrochip/mode/LGGetFlyLineBean';
import { LGInfo3HyBean } from '../../macrochip/mode/LGInfo3HyBean';
import { LGInfo3BHyBean } from '../../macrochip/mode/LGInfo3BHyBean';
import { LGTestBean } from '../../macrochip/mode/LGTestBean';
import { AnalysisUtils } from './AnalysisUtils';

/**
 * 蓝光无人机数据解析类
 */
export class LanGuangAnalysis {
  /**
   * 单例实例
   */
  private static instance: LanGuangAnalysis | null = null;

  /**
   * 私有构造函数，防止外部实例化
   */
  private constructor() {
    // 防止外部实例化
  }

  /**
   * 获取单例实例
   * @returns LanGuangAnalysis单例
   */
  public static getInstance(): LanGuangAnalysis {
    if (LanGuangAnalysis.instance === null) {
      LanGuangAnalysis.instance = new LanGuangAnalysis();
    }
    return LanGuangAnalysis.instance;
  }



  /**
   * 解析无人机状态数据为LGPlaneHyBean
   * @param data 二进制数据
   * @returns LGPlaneHyBean对象
   */
  public parseDroneStatus(data: Uint8Array): LGPlaneHyBean {
    // 将数据转换为位数组
    const originalBits = AnalysisUtils.bytesToBits(data);
    // 创建副本，避免修改原数据
    const bits = originalBits.slice();
    // 创建LGPlaneHyBean对象
    const droneStatus: LGPlaneHyBean = new LGPlaneHyBean();

    // 解析数据，基于位位置
    // 注意：由于parseBits方法会修改bits数组，我们使用一个索引来跟踪当前位置
    // 每次调用parseBits后，bits数组会被修改，移除已解析的元素
    
    // AttitudeRoll: short (16 bits)
    droneStatus.AttitudeRoll = AnalysisUtils.parseBits(bits, 16);

    // AttitudePitch: short (16 bits)
    droneStatus.AttitudePitch =AnalysisUtils.parseBits(bits, 16);

    // AttitudeYaw: short (16 bits)
    droneStatus.AttitudeYaw =AnalysisUtils.parseBits(bits,  16);

    // InsInitOk: 0或1 (1 bit)
    droneStatus.InsInitOk =AnalysisUtils.parseBits(bits, 1);

    // BaroInitOk: 0或1 (1 bit)
    droneStatus.BaroInitOk =AnalysisUtils.parseBits(bits,  1);

    // MagInitOk: 0或1 (1 bit)
    droneStatus.MagInitOk =AnalysisUtils.parseBits(bits,  1);

    // GpsInitOk: 0或1 (1 bit)
    droneStatus.GpsInitOk =AnalysisUtils.parseBits(bits , 1);

    // FlowInitOk: 0或1 (1 bit)
    droneStatus.FlowInitOk =AnalysisUtils.parseBits(bits , 1);

    // 预留位 (3 bits，补满1字节)
   //AnalysisUtils.parseBits(bits , 3);

    // InsCalib: 0或1 (1 bit)
    droneStatus.InsCalib =AnalysisUtils.parseBits(bits , 1);

    // MagXYCalib: 0或1 (1 bit)
    droneStatus.MagXYCalib =AnalysisUtils.parseBits(bits , 1);

    // MagZCalib: 0或1 (1 bit)
    droneStatus.MagZCalib =AnalysisUtils.parseBits(bits , 1);

    // CalibProgress: 0~100 (7 bits)
    droneStatus.CalibProgress =AnalysisUtils.parseBits(bits , 7);

    // BatVal: 0~100 (7 bits)
    droneStatus.BatVal =AnalysisUtils.parseBits(bits , 7);

    // LowBat: 0~2 (2 bits)
    droneStatus.LowBat =AnalysisUtils.parseBits(bits , 2);

    // TempOver: 0或1 (1 bit)
    droneStatus.TempOver =AnalysisUtils.parseBits(bits , 1);

    // CurrOver: 0~2 (2 bits)
    droneStatus.CurrOver =AnalysisUtils.parseBits(bits , 2);

    // Armed: 0~2 (2 bits)
    droneStatus.Armed =AnalysisUtils.parseBits(bits , 2);

    // FlyMode: 0~4 (3 bits)
    droneStatus.FlyMode =AnalysisUtils.parseBits(bits , 4);

    // GoHomeStatu: 0~5 (3 bits)
    droneStatus.GoHomeStatu =AnalysisUtils.parseBits(bits , 3);

    // Photo: 0或1 (1 bit)
    droneStatus.Photo =AnalysisUtils.parseBits(bits , 1);

    // Camera: 0或1 (1 bit)
    droneStatus.Camera =AnalysisUtils.parseBits(bits , 1);

    // VideoOn: 0或1 (1 bit)
    droneStatus.VideoOn =AnalysisUtils.parseBits(bits , 1);

    // Takeoff: 0或1 (1 bit)
    droneStatus.Takeoff =AnalysisUtils.parseBits(bits , 1);

    // AutoLand: 0或1 (1 bit)
    droneStatus.AutoLand =AnalysisUtils.parseBits(bits , 1);

    // LandFinish: 0或1 (1 bit)
    droneStatus.LandFinish =AnalysisUtils.parseBits(bits , 1);

    // GpsNum: 0~31 (5 bits)
    droneStatus.GpsNum =AnalysisUtils.parseBits(bits , 5);

    // GpsFine: 0或1 (1 bit)
    droneStatus.GpsFine =AnalysisUtils.parseBits(bits , 1);

    // GpsQuality: 0~100 (7 bits)
    droneStatus.GpsQuality =AnalysisUtils.parseBits(bits , 7);

    // modeGps: 0~2 (2 bits)
    droneStatus.modeGps =AnalysisUtils.parseBits(bits , 2);

    // RcFastMode: 0~3 (2 bits)
    droneStatus.RcFastMode =AnalysisUtils.parseBits(bits , 2);

    // PTZadj: 0~2 (2 bits)
    droneStatus.PTZadj =AnalysisUtils.parseBits(bits , 2);

    // Brightness: 0~2 (2 bits)
    droneStatus.Brightness =AnalysisUtils.parseBits(bits , 2);

    return droneStatus;
  }

  /**
   * 解析0x9c功能字的飞机实时信息3版本C数据
   * @param data 二进制数据
   * @returns SJHyInfo9CBean对象
   */
  public parseSJHyInfo9C(data: Uint8Array): SJHyInfo9CBean {
    // 将数据转换为位数组
    const originalBits = AnalysisUtils.bytesToBits(data);
    // 创建副本，避免修改原数据
    const bits = originalBits.slice();
    // 创建SJHyInfo9CBean对象
    const sjHyInfo9C: SJHyInfo9CBean = new SJHyInfo9CBean();

    // 解析数据，基于位位置
    // 注意：由于parseBits方法会修改bits数组，我们使用一个索引来跟踪当前位置
    // 每次调用parseBits后，bits数组会被修改，移除已解析的元素
    
    // MagInterference: 地磁环境干扰量0-1000 (10 bits)
    sjHyInfo9C.MagInterference = AnalysisUtils.parseBits(bits, 10);

    // BatVal: 电池实际电压 单位mv (12 bits)
    sjHyInfo9C.BatVal = AnalysisUtils.parseBits(bits, 12);

    // GpsQuality: GPS精度 单位cm (10 bits)
    sjHyInfo9C.GpsQuality = AnalysisUtils.parseBits(bits, 10);

    // IndoorMode: 室内模式标志 (1 bit)
    sjHyInfo9C.IndoorMode = AnalysisUtils.parseBits(bits, 1);

    // BatPer: 电量百分比 (7 bits)
    sjHyInfo9C.BatPer = AnalysisUtils.parseBits(bits, 7);

    // IsUseLongDis: 如果该位使能，显示使用距离为0-8191m (1 bit)
    sjHyInfo9C.IsUseLongDis = AnalysisUtils.parseBits(bits, 1);

    // Distance: 距起飞点距离 0~8191m (13 bits)
    sjHyInfo9C.Distance = AnalysisUtils.parseBits(bits, 13);

    // RmoteVol: 遥控器电量 0-100% (7 bits)
    sjHyInfo9C.RmoteVol = AnalysisUtils.parseBits(bits, 7);

    // IMUAccFlag: 0 IMU 正常 1 IMU 误差大 (1 bit)
    sjHyInfo9C.IMUAccFlag = AnalysisUtils.parseBits(bits, 1);

    // YawRotate: 0 未旋转 1 旋转 (1 bit)
    sjHyInfo9C.YawRotate = AnalysisUtils.parseBits(bits, 1);

    // MagErr: 0 地磁正常，1 地磁失效 (1 bit)
    sjHyInfo9C.MagErr = AnalysisUtils.parseBits(bits, 1);

    // HeighLimt: 达到高度限制 (1 bit)
    sjHyInfo9C.HeighLimt = AnalysisUtils.parseBits(bits, 1);

    // DistanceLimit: 达到距离限制 (1 bit)
    sjHyInfo9C.DistanceLimit = AnalysisUtils.parseBits(bits, 1);

    // WiFiTestMode: 1进入WiFi测试模式0正常模式 (1 bit)
    sjHyInfo9C.WiFiTestMode = AnalysisUtils.parseBits(bits, 1);

    // OAWarn: 障碍物报警 (1 bit)
    sjHyInfo9C.OAWarn = AnalysisUtils.parseBits(bits, 1);

    // OADis: 避障传感器距离单位m0-31米 (5 bits)
    sjHyInfo9C.OADis = AnalysisUtils.parseBits(bits, 5);

    // MagNeedCal: 1飞机需要地磁校准0正常状态 (1 bit)
    sjHyInfo9C.MagNeedCal = AnalysisUtils.parseBits(bits, 1);

    // SportMode: 运动模式标志 (1 bit)
    sjHyInfo9C.SportMode = AnalysisUtils.parseBits(bits, 1);

    // OASensor: 1 避障传感器正常 (1 bit)
    sjHyInfo9C.OASensor = AnalysisUtils.parseBits(bits, 1);

    // ZoomInOut: 图像放大缩小0正常，1缩小，2放大 (2 bits)
    sjHyInfo9C.ZoomInOut = AnalysisUtils.parseBits(bits, 2);

    // AutoMode: 自动模式类型 (4 bits) //自动模式类型 //0操控模式1返航到起飞点上空（航向对准起飞点）//2返航到起飞点上空（航向维持返航前角度）//3 返航到起飞点自动降落（航向对准起飞点）//4返航到起飞点自动降落（航向维持返航前角度）//5 返航到围栏内6自动航点模式7环绕模式
    sjHyInfo9C.AutoMode = AnalysisUtils.parseBits(bits, 4);

    // RtlSetp: 返航步骤 (4 bits)
    sjHyInfo9C.RtlSetp = AnalysisUtils.parseBits(bits, 4);

    // CruiseHor: 水平巡航模式 0-1 (1 bit)
    sjHyInfo9C.CruiseHor = AnalysisUtils.parseBits(bits, 1);

    // CruiseVer: 高度巡航模式 0-1 (1 bit)
    sjHyInfo9C.CruiseVer = AnalysisUtils.parseBits(bits, 1);

    // Resv: 保留 (1 bit)
    sjHyInfo9C.Resv = AnalysisUtils.parseBits(bits, 1);

    // SkyFlySta: 自主冲天模式状态 0-3 (2 bits)
    sjHyInfo9C.SkyFlySta = AnalysisUtils.parseBits(bits, 2);

    // FarFlySta: 自主渐远模式状态 0-3 (2 bits)
    sjHyInfo9C.FarFlySta = AnalysisUtils.parseBits(bits, 2);

    // SpiralSta: 自主螺旋模式状态 0-3 (2 bits)
    sjHyInfo9C.SpiralSta = AnalysisUtils.parseBits(bits, 2);

    // BatLegal: 是否正版电池 0非正版 1正版 (1 bit)
    sjHyInfo9C.BatLegal = AnalysisUtils.parseBits(bits, 1);

    return sjHyInfo9C;
  }

  /**
   * 解析无人机GPS数据为LGPlaneGpsBean
   * @param data 二进制数据
   * @returns LGPlaneGpsBean对象
   */
  public parseLGPlaneGps(data: Uint8Array): LGPlaneGpsBean {
    // 将数据转换为位数组
    const originalBits = AnalysisUtils.bytesToBits(data);
    // 创建副本，避免修改原数据
    const bits = originalBits.slice();
    // 创建LGPlaneGpsBean对象
    const gpsBean: LGPlaneGpsBean = new LGPlaneGpsBean();

    // 解析数据，基于位位置
    // 注意：由于parseBits方法会修改bits数组，我们使用一个索引来跟踪当前位置
    // 每次调用parseBits后，bits数组会被修改，移除已解析的元素
    
    // AirplaneLon: 飞机GPS经度 1 / 10000 000 deg (32 bits)
    gpsBean.AirplaneLon = AnalysisUtils.parseBits(bits, 32);

    // AirplaneLat: 飞机GPS纬度 1 / 10000 000 deg (32 bits)
    gpsBean.AirplaneLat = AnalysisUtils.parseBits(bits, 32);

    // Altitude: 距起飞点高度 -100.0~309.5m（收到数据减去1000）(12 bits)
    gpsBean.Altitude = AnalysisUtils.parseBits(bits, 12);

    // Distance: 距起飞点距离 0~819.1m (13 bits)
    gpsBean.Distance = AnalysisUtils.parseBits(bits, 13);

    // Speed: 水平速度 0~12.7m/s (7 bits)
    gpsBean.Speed = AnalysisUtils.parseBits(bits, 7);

    // Velocity: 垂直速度 -12.7~+12.7m/s (8 bits，带符号)
    gpsBean.Velocity = AnalysisUtils.parseBits(bits, 8);

    return gpsBean;
  }

  /**
   * 解析功能字0x84的应答航点数据接收ok
   * @param data 二进制数据
   * @returns LGGetFlyLineBean对象
   */
  public parsePointNumRespond(data: Uint8Array): LGGetFlyLineBean {
    // 将数据转换为位数组
    const originalBits = AnalysisUtils.bytesToBits(data);
    // 创建副本，避免修改原数据
    const bits = originalBits.slice();
    // 创建LGGetFlyLineBean对象
    const flyLineBean: LGGetFlyLineBean = new LGGetFlyLineBean();

    // 解析数据，基于位位置
    // 注意：由于parseBits方法会修改bits数组，我们使用一个索引来跟踪当前位置
    // 每次调用parseBits后，bits数组会被修改，移除已解析的元素
    
    // PointNum: 航点应答数据，表示收到第几个航点 (8 bits)
    flyLineBean.PointNum = AnalysisUtils.parseBits(bits, 8);

    return flyLineBean;
  }

  /**
   * 解析功能字0x8E的定时应答飞机实时信息3（广州--黑飞）
   * @param data 二进制数据
   * @returns LGInfo3HyBean对象
   */
  public parseLGInfo3Hy(data: Uint8Array): LGInfo3HyBean {
    // 将数据转换为位数组
    const originalBits = AnalysisUtils.bytesToBits(data);
    // 创建副本，避免修改原数据
    const bits = originalBits.slice();
    // 创建LGInfo3HyBean对象
    const info3HyBean: LGInfo3HyBean = new LGInfo3HyBean();

    // 解析数据，基于位位置
    // 注意：由于parseBits方法会修改bits数组，我们使用一个索引来跟踪当前位置
    // 每次调用parseBits后，bits数组会被修改，移除已解析的元素
    
    // MagInterference: 地磁环境干扰量0-1000 (10 bits)
    info3HyBean.MagInterference = AnalysisUtils.parseBits(bits, 10);

    // BatVal: 电池实际电压 单位mv (12 bits)
    info3HyBean.BatVal = AnalysisUtils.parseBits(bits, 12);

    // GpsQuality: GPS精度 单位cm (10 bits)
    info3HyBean.GpsQuality = AnalysisUtils.parseBits(bits, 10);

    return info3HyBean;
  }

  /**
   * 解析功能字0x8F的定时应答飞机实时信息3B（广州--黑飞）
   * @param data 二进制数据
   * @returns LGInfo3BHyBean对象
   */
  public parseLGInfo3BHy(data: Uint8Array): LGInfo3BHyBean {
    // 将数据转换为位数组
    const originalBits = AnalysisUtils.bytesToBits(data);
    // 创建副本，避免修改原数据
    const bits = originalBits.slice();
    // 创建LGInfo3BHyBean对象
    const info3BHyBean: LGInfo3BHyBean = new LGInfo3BHyBean();

    // 解析数据，基于位位置
    // 注意：由于parseBits方法会修改bits数组，我们使用一个索引来跟踪当前位置
    // 每次调用parseBits后，bits数组会被修改，移除已解析的元素
    
    // MagInterference: 地磁环境干扰量0-1000 (10 bits)
    info3BHyBean.MagInterference = AnalysisUtils.parseBits(bits, 10);

    // BatVal: 电池实际电压 单位mv (12 bits)
    info3BHyBean.BatVal = AnalysisUtils.parseBits(bits, 12);

    // GpsQuality: GPS精度 单位cm (10 bits)
    info3BHyBean.GpsQuality = AnalysisUtils.parseBits(bits, 10);

    // UnlockFlowMode: 光流模式解锁标志 (1 bit)
    info3BHyBean.UnlockFlowMode = AnalysisUtils.parseBits(bits, 1);

    // BatPer: 电量百分比 (7 bits)
    info3BHyBean.BatPer = AnalysisUtils.parseBits(bits, 7);

    // IsUseLongDis: 如果该位使能，显示使用距离为0-8191m (1 bit)
    info3BHyBean.IsUseLongDis = AnalysisUtils.parseBits(bits, 1);

    // Distance: 距起飞点距离 0~8191m (13 bits)
    info3BHyBean.Distance = AnalysisUtils.parseBits(bits, 13);

    // RmoteVol: 遥控器电量百分比 (7 bits)
    info3BHyBean.RmoteVol = AnalysisUtils.parseBits(bits, 7);

    // IMUACCFlag: 0 IMU 正常 1 IMU误差大 (1 bit)
    info3BHyBean.IMUACCFlag = AnalysisUtils.parseBits(bits, 1);

    // YawRotate: 偏航旋转状态 (1 bit)
    info3BHyBean.YawRotate = AnalysisUtils.parseBits(bits, 1);

    // MagErr: 地磁错误标志 (1 bit)
    info3BHyBean.MagErr = AnalysisUtils.parseBits(bits, 1);

    return info3BHyBean;
  }

  /**
   * 解析功能字0x8d的定时应答飞机实时测试信息
   * @param data 二进制数据
   * @returns LGTestBean对象
   */
  public parseLGTest(data: Uint8Array): LGTestBean {
    // 将数据转换为位数组
    const originalBits = AnalysisUtils.bytesToBits(data);
    // 创建副本，避免修改原数据
    const bits = originalBits.slice();
    // 创建LGTestBean对象
    const testBean: LGTestBean = new LGTestBean();

    // 解析数据，基于位位置
    // 注意：由于parseBits方法会修改bits数组，我们使用一个索引来跟踪当前位置
    // 每次调用parseBits后，bits数组会被修改，移除已解析的元素
    
    // gyro_x: 陀螺仪X轴 -32767~32767 (16 bits)
    testBean.gyro_x = AnalysisUtils.parseBits(bits, 16);

    // gyro_y: 陀螺仪Y轴 -32767~32767 (16 bits)
    testBean.gyro_y = AnalysisUtils.parseBits(bits, 16);

    // gyro_z: 陀螺仪Z轴 -32767~32767 (16 bits)
    testBean.gyro_z = AnalysisUtils.parseBits(bits, 16);

    // acc_x: 加速度X轴 -32767~32767 (16 bits)
    testBean.acc_x = AnalysisUtils.parseBits(bits, 16);

    // acc_y: 加速度Y轴 -32767~32767 (16 bits)
    testBean.acc_y = AnalysisUtils.parseBits(bits, 16);

    // acc_z: 加速度Z轴 -32767~32767 (16 bits)
    testBean.acc_z = AnalysisUtils.parseBits(bits, 16);

    // mag_x: 罗盘X轴 -32767~32767 (16 bits)
    testBean.mag_x = AnalysisUtils.parseBits(bits, 16);

    // mag_y: 罗盘Y轴 -32767~32767 (16 bits)
    testBean.mag_y = AnalysisUtils.parseBits(bits, 16);

    // mag_z: 罗盘Z轴 -32767~32767 (16 bits)
    testBean.mag_z = AnalysisUtils.parseBits(bits, 16);

    // BatVal: 电池电压 20.48 V (11 bits)
    testBean.BatVal = AnalysisUtils.parseBits(bits, 11);

    // GpsNum: 卫星颗数 0~31颗 (5 bits)
    testBean.GpsNum = AnalysisUtils.parseBits(bits, 5);

    // AttitudeRoll: 横滚角 -180~0~180 deg 使用时请减去180度 (9 bits)
    testBean.AttitudeRoll = AnalysisUtils.parseBits(bits, 9);

    // AttitudePitch: 俯仰角 -180~0~180 deg 使用时请减去180度 (9 bits)
    testBean.AttitudePitch = AnalysisUtils.parseBits(bits, 9);

    // AttitudeYaw: 偏航角 0~360 deg (9 bits)
    testBean.AttitudeYaw = AnalysisUtils.parseBits(bits, 9);

    // InsInitOk: 陀螺仪正常 0无陀螺仪，1陀螺仪初始化正常 (1 bit)
    testBean.InsInitOk = AnalysisUtils.parseBits(bits, 1);

    // BaroInitOk: 气压计正常 0无气压计，1气压计初始化正常 (1 bit)
    testBean.BaroInitOk = AnalysisUtils.parseBits(bits, 1);

    // MagInitOk: 罗盘正常 0无罗盘，1罗盘初始化正常 (1 bit)
    testBean.MagInitOk = AnalysisUtils.parseBits(bits, 1);

    // GpsInitOk: GPS正常 0无GPS，1有GPS初始化正常 (1 bit)
    testBean.GpsInitOk = AnalysisUtils.parseBits(bits, 1);

    // FlowInitOk: 光流正常 0无光流，1光流初始化正常 (1 bit)
    testBean.FlowInitOk = AnalysisUtils.parseBits(bits, 1);

    // AirplaneLon: GPS经度 1 / 10000 000 deg (32 bits)
    testBean.AirplaneLon = AnalysisUtils.parseBits(bits, 32);

    // AirplaneLat: GPS纬度 1 / 10000 000 deg (32 bits)
    testBean.AirplaneLat = AnalysisUtils.parseBits(bits, 32);

    // temperature: 温度 -127~127 (degree Celsius) (8 bits)
    testBean.temperature = AnalysisUtils.parseBits(bits, 8);

    // baro_alt: 气压计高度 -100.0~309.5m（收到数据减去1000）(12 bits)
    testBean.baro_alt = AnalysisUtils.parseBits(bits, 12);

    // GpsFine: GPS定位 0没有定位，1已经定位 (1 bit)
    testBean.GpsFine = AnalysisUtils.parseBits(bits, 1);

    // GpsQuality: GPS定位精度 0~20.48m (11 bits)
    testBean.GpsQuality = AnalysisUtils.parseBits(bits, 11);

    // current1: 电流检测1 0~63 (6 bits)
    testBean.current1 = AnalysisUtils.parseBits(bits, 6);

    // current2: 电流检测2 0~63 (6 bits)
    testBean.current2 = AnalysisUtils.parseBits(bits, 6);

    return testBean;
  }

  /**
   * 解析功能字0x9D的定时应答飞机实时信息2，仅在GPS模式下应答
   * @param data 二进制数据
   * @returns LGPlaneGpsBean2对象
   */
  public parseLGPlaneGps2(data: Uint8Array): LGPlaneGpsBean2 {
    // 将数据转换为位数组
    const originalBits = AnalysisUtils.bytesToBits(data);
    // 创建副本，避免修改原数据
    const bits = originalBits.slice();
    // 创建LGPlaneGpsBean2对象
    const gpsBean2: LGPlaneGpsBean2 = new LGPlaneGpsBean2();

    // 解析数据，基于位位置
    // 注意：由于parseBits方法会修改bits数组，我们使用一个索引来跟踪当前位置
    // 每次调用parseBits后，bits数组会被修改，移除已解析的元素
    
    // AirplaneLon: 飞机GPS经度 1 / 10000 000 deg (32 bits)
    gpsBean2.AirplaneLon = AnalysisUtils.parseBits(bits, 32);

    // AirplaneLat: 飞机GPS纬度 1 / 10000 000 deg (32 bits)
    gpsBean2.AirplaneLat = AnalysisUtils.parseBits(bits, 32);

    // Altitude: 距起飞点高度 -3276.8m ~ 3276.7m (16 bits)
    gpsBean2.Altitude = AnalysisUtils.parseBits(bits, 16);

    // Distance: 距起飞点距离 0~65535m (16 bits)
    gpsBean2.Distance = AnalysisUtils.parseBits(bits, 16);

    // Speed: 水平速度 0~25.5m/s (8 bits)
    gpsBean2.Speed = AnalysisUtils.parseBits(bits, 8);

    // Velocity: 垂直速度 -12.7~+12.7m/s (8 bits，带符号)
    gpsBean2.Velocity = AnalysisUtils.parseBits(bits, 8);

    return gpsBean2;
  }

  /**
   * 解析功能字0x9a的应答飞机基本信息
   * @param data 二进制数据
   * @returns SJHyGetSettingBean对象
   */
  public parseSJHyGetSetting(data: Uint8Array): SJHyGetSettingBean {
    // 创建SJHyGetSettingBean对象
    const settingBean: SJHyGetSettingBean = new SJHyGetSettingBean();

    // 直接处理字节数组，不需要转换为位数组，因为字符串字段是连续的字节
    let offset = 0;

    // 解析UavName: 12个字符
    for (let i = 0; i < 12; i++) {
      settingBean.UavName[i] = data[offset + i];
    }
    offset += 12;

    // 解析UavVersion: 12个字符
    for (let i = 0; i < 12; i++) {
      settingBean.UavVersion[i] = data[offset + i];
    }
    offset += 12;

    // 剩余的10+12+10=32 bits需要使用位数组解析
    const remainingData = data.slice(offset);
    const originalBits = AnalysisUtils.bytesToBits(remainingData);
    const bits = originalBits.slice();

    // Maxhigh: 最大飞行高度 0~1023 米 (10 bits)
    settingBean.Maxhigh = AnalysisUtils.parseBits(bits, 10);

    // Maxdistance: 最大飞行距离 0~4096 米 (12 bits)
    settingBean.Maxdistance = AnalysisUtils.parseBits(bits, 12);

    // Gohomehigh: 返航高度 0~限距高度 (10 bits)
    settingBean.Gohomehigh = AnalysisUtils.parseBits(bits, 10);

    return settingBean;
  }

  /**
   * 解析功能字0xAB的应答飞机基本信息
   * @param data 二进制数据
   * @returns HyABBean对象
   */
  public parseHyAB(data: Uint8Array): HyABBean {
    // 创建HyABBean对象
    const abBean: HyABBean = new HyABBean();

    // 直接处理字节数组，不需要转换为位数组，因为字符串字段是连续的字节
    let offset = 0;

    // 解析UavName: 12个字符
    for (let i = 0; i < 12; i++) {
      abBean.UavName[i] = data[offset + i];
    }
    offset += 12;

    // 解析UavVersion: 12个字符
    for (let i = 0; i < 12; i++) {
      abBean.UavVersion[i] = data[offset + i];
    }
    offset += 12;

    // 剩余的16+16+16+16=64 bits需要使用位数组解析
    const remainingData = data.slice(offset);
    const originalBits = AnalysisUtils.bytesToBits(remainingData);
    const bits = originalBits.slice();

    // Maxhigh: 最大飞行高度 0~1023 米 (16 bits)
    abBean.Maxhigh = AnalysisUtils.parseBits(bits, 16);

    // Maxdistance: 最大飞行距离 0~4096 米 (16 bits)
    abBean.Maxdistance = AnalysisUtils.parseBits(bits, 16);

    // Gohomehigh: 返航高度 0~限距高度 (16 bits)
    abBean.Gohomehigh = AnalysisUtils.parseBits(bits, 16);

    // Gohomehigh2: 返航高度 0~限距高度 (16 bits，保留)
    abBean.Gohomehigh2 = AnalysisUtils.parseBits(bits, 16);

    return abBean;
  }

  /**
   * 解析功能字0x9b的传感器及摇杆信息
   * @param data 二进制数据
   * @returns SJHyInfo9BBean对象
   */
  public parseSJHyInfo9B(data: Uint8Array): SJHyInfo9BBean {
    // 将数据转换为位数组
    const originalBits = AnalysisUtils.bytesToBits(data);
    // 创建副本，避免修改原数据
    const bits = originalBits.slice();
    // 创建SJHyInfo9BBean对象
    const hyInfo9BBean: SJHyInfo9BBean = new SJHyInfo9BBean();

    // 解析数据，基于位位置
    // 注意：由于parseBits方法会修改bits数组，我们使用一个索引来跟踪当前位置
    // 每次调用parseBits后，bits数组会被修改，移除已解析的元素
    
    // Acc: 加速度传感器数据，3个int16_t，每个16 bits
    for (let i = 0; i < 3; i++) {
      hyInfo9BBean.Acc[i] = AnalysisUtils.parseBits(bits, 16);
    }

    // Gyr: 陀螺仪数据，3个int16_t，每个16 bits
    for (let i = 0; i < 3; i++) {
      hyInfo9BBean.Gyr[i] = AnalysisUtils.parseBits(bits, 16);
    }

    // Mag: 磁力计数据，3个int16_t，每个16 bits
    for (let i = 0; i < 3; i++) {
      hyInfo9BBean.Mag[i] = AnalysisUtils.parseBits(bits, 16);
    }

    // baro: 气压计数据，int32_t，32 bits
    hyInfo9BBean.baro = AnalysisUtils.parseBits(bits, 32);

    // ImuTemp: IMU温度，uint8_t，8 bits
    hyInfo9BBean.ImuTemp = AnalysisUtils.parseBits(bits, 8);

    // BaroTemp: 气压计温度，uint8_t，8 bits
    hyInfo9BBean.BaroTemp = AnalysisUtils.parseBits(bits, 8);

    // Roll: 横滚角，uint8_t，8 bits
    hyInfo9BBean.Roll = AnalysisUtils.parseBits(bits, 8);

    // Pitch: 俯仰角，uint8_t，8 bits
    hyInfo9BBean.Pitch = AnalysisUtils.parseBits(bits, 8);

    // Thor: 油门，uint8_t，8 bits
    hyInfo9BBean.Thor = AnalysisUtils.parseBits(bits, 8);

    // Yaw: 偏航角，uint8_t，8 bits
    hyInfo9BBean.Yaw = AnalysisUtils.parseBits(bits, 8);

    // Motor: 电机数据，4个uint16_t，每个16 bits
    for (let i = 0; i < 4; i++) {
      hyInfo9BBean.Motor[i] = AnalysisUtils.parseBits(bits, 16);
    }

    return hyInfo9BBean;
  }
}
