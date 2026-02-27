export class ConfigureInfo {
  private static instance: ConfigureInfo;

  // 单例模式，确保唯一实例
  private constructor() {}
  static getInstance(): ConfigureInfo {
    if (!ConfigureInfo.instance) {
      ConfigureInfo.instance = new ConfigureInfo();
    }
    return ConfigureInfo.instance;
  }

  //public static  VERSION_NAME:string = BuildConfig.BUILD_NAME;
  //public static  BUILD_DATE:number = BuildConfig.BUILD_DATE;
  public static  exitAppDelayed:number = 30 * 1000;       // 退出app延时时间
  //public static LogSaveType LOG_SAVE_TYPE = LogSaveType.DAY; // 日志保存模式
  public static  LOG_SHOW_DELETE_ALL:boolean = true; //日志界面是否显示删除按钮
  public static  LOG_SHOW_PASSWORD:boolean = false; //日志界面是否需要输入密码才能查看
  public static  CAUGHT_EXCEPTION:boolean = true;  // 是否捕获异常
  public static  ORIGINAL_FILTER:boolean = true;//原图是否渲染滤镜
  public static  SUB_CAMERA_SCALE:boolean = true; //副镜头是否拍照录像插值
  public static  NETWORK_TRANSPORT_CONTROL:boolean = true; //是否打开网络通道控制
  public static  USB_TRANSPORT:boolean = false; //是否打开USB通讯
  public static  WIFI_SCAN :boolean= false; //Wi-Fi自动扫描连接
  public static  RECORD_CMD_START:boolean = true; //是否发送录像开始指令,默认发送
  public static  RECORD_CMD_STOP:boolean = true; //是否发送录像停止指令,默认发送
  //public static RemoteImageHelper.SaveType IMAGE_SAVE_TYPE = RemoteImageHelper.SaveType.LOCAL_REMOTE_ORIGINAL;  // 拍照保存类型
  public static  EXIF_MAKE:string;  // 照片设备制造商
  public static  EXIF_MODEL:string; // 照片设备型号
  public static  GET_VIDEO_STREAM:boolean = true; // 是否获取视频流，默认可获取
  public static  IS_ORDER_NAME:boolean = false; // 使用序号做文件名
  public static  useUsbDelayAccumulation:boolean = false; // 是否使用延时累计USB数据
  public static  MAX_FIND_USB_COUNT:number=20;
  public static  IS_FAME_LOG:boolean = false;
  public static  LOG_SIZE:number = 1024 * 124 * 5;       // id日志大小
  readonly  isDecode :boolean= false; //是否开始解码





}