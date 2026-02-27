export class  LGPlaneHyBean {
  /** 横滚角 -180~0~180 deg 使用时请减去180度 */
  AttitudeRoll: number=0; // 横滚角 (short in Java)
  /** 俯仰角 -180~0~180 deg 使用时请减去180度 */
  AttitudePitch: number=0; // 俯仰角 (short in Java)
  /** 偏航角 0~360 deg */
  AttitudeYaw: number=0; // 偏航角 (short in Java)
  /** 陀螺仪正常 0无陀螺仪，1陀螺仪初始化正常 */
  InsInitOk: number=0; // 陀螺仪正常 (int in Java)
  /** 气压计正常 0无气压计，1气压计初始化正常 */
  BaroInitOk: number=0; // 气压计正常 (int in Java)
  /** 罗盘正常 0无罗盘，1罗盘初始化正常 */
  MagInitOk: number=0; // 罗盘正常 (int in Java)
  /** GPS正常 0无GPS，1有GPS初始化正常 */
  GpsInitOk: number=0; // GPS正常 (int in Java)
  /** 光流正常 0无光流，1光流初始化正常 */
  FlowInitOk: number=0; // 光流正常 (int in Java)
  /** 加计校准指示 0正在校准，1校准结束 */
  InsCalib: number=0; // 加计校准指示 (int in Java)
  /** 罗盘X校准指示 0正在校准，1校准结束 */
  MagXYCalib: number=0; // 罗盘X校准指示 (int in Java)
  /** 罗盘Y校准指示 0正在校准，1校准结束 */
  MagZCalib: number=0; // 罗盘Y校准指示 (int in Java)
  /** 校准进度 0~100（%） */
  CalibProgress: number=0; // 校准进度 (int in Java)
  /** 电池电压 0~100（%） */
  BatVal: number=0; // 电池电压 (int in Java)
  /** 低电报警 0正常，1一次低电，2二次低电 */
  LowBat: number=0; // 低电报警 (int in Java)
  /** 温度报警 0无，1温度过高 */
  TempOver: number=0; // 温度报警 (int in Java)
  /** 堵转报警 0无，1堵转保护，2倾角保护 */
  CurrOver: number=0; // 堵转报警 (int in Java)
  /** 锁定状态 0上锁，1解锁，2飞行 */
  Armed: number=0; // 锁定状态 (int in Java)
  /** 飞行模式 0室内 1 GPS 2跟随 3环绕4航点 */
  FlyMode: number=0; // 飞行模式 (int in Java)
  /** 返航状态 0无 1掉头 2上升 3回飞 4掉头 5降落 */
  GoHomeStatu: number=0; // 返航状态 (int in Java)
  /** 拍照指令 变高1秒后变低 */
  Photo: number=0; // 拍照指令 (int in Java)
  /** 摄像指令 变高1秒后变低 */
  Camera: number=0; // 摄像指令 (int in Java)
  /** 摄像状态 0无，1正在摄像 */
  VideoOn: number=0; // 摄像状态 (int in Java)
  /** 起飞指示 0无，1正在起飞 */
  Takeoff: number=0; // 起飞指示 (int in Java)
  /** 自动降落状态 0无，1正在降落 */
  AutoLand: number=0; // 自动降落状态 (int in Java)
  /** 降落完成 0无，1降落完成 */
  LandFinish: number=0; // 降落完成 (int in Java)
  /** 卫星颗数 0~31颗 */
  GpsNum: number=0; // 卫星颗数 (int in Java)
  /** GPS定位 0没有定位，1已经定位 */
  GpsFine: number=0; // GPS定位 (int in Java)
  /** GPS质量 0~100（%） */
  GpsQuality: number=0; // GPS质量 (int in Java)
  /** 定点模式 0非定点模式，1 GPS定点模式，2光流定点模式 */
  modeGps: number=0; // 定点模式 (int in Java)
  /** 遥控器快档模式 0慢档，1中档，2快档, 3遥控器关闭 */
  RcFastMode: number=0; // 遥控器快档模式 (int in Java)
  /** 云台上下调节 0不动，1下调，2上调 */
  PTZadj: number=0; // 云台上下调节 (int in Java)
  /** 亮度上下调节 0不动，1下调，2上调 */
  Brightness: number=0; // 亮度上下调节 (int in Java)
}
