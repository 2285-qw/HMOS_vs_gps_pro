/** 
 * @Author:         Sanerly 
 * @CreateDate:     2024/05/08 07:32 
 * @Description:    用于不同事件的通知,触发特定的行为或响应 
 */ 

export enum SwitchType {
  /*************************************上层调用 开始**************************************************/ 
  // 遥控拍照 
  NOTIFY_REMOTE_PHOTO = 2008, 
  // 遥控录像 
  NOTIFY_REMOTE_RECORD = 2009, 
  // 遥控录像(开始) 
  NOTIFY_REMOTE_RECORD_START = 2010, 
  // 遥控录像（停止） 
  NOTIFY_REMOTE_RECORD_STOP = 2011, 
  // 设备 断开(USB和Wi-Fi断开) 
  NOTIFY_DEVICE_DISCONNECTED = 2013, 
  // 设备 连接(USB和Wi-Fi连接) 
  NOTIFY_DEVICE_CONNECTED = 2014, 
  // 连接上 wifi 
  NOTIFY_WIFI_CONNECTED = 2015, 
  // wifi 断开 
  NOTIFY_WIFI_DISCONNECTED = 2016, 
  // 有tf卡 
  NOTIFY_TF_EXIST_CARD = 2018, 
  // 没有tf卡 
  NOTIFY_TF_NO_CARD = 2019, 
  // 开始格式化 
  NOTIFY_TF_FORMAT_BEGIN = 2020, 
  // 格式化完成 
  NOTIFY_TF_FORMAT_FINISHED = 2021, 
  // 格式化失败 
  NOTIFY_TF_FORMAT_FAIL = 2022, 
  // tf 需要重新插拔卡 
  NOTIFY_TF_NEED_PLUG = 2023, 
  // tf卡需要格式化 
  NOTIFY_TF_FORMAT = 2024, 
  // 切换到主镜头 
  NOTIFY_SWITCH_CAMERA_MAIN = 2026, 
  // 切换到副镜头 
  NOTIFY_SWITCH_CAMERA_SUB = 2027, 
  // USB连接信息 
  NOTIFY_USB_CONNECT_INFO = 2028, 
  // 通信第一次成功 
  NOTIFY_COMMUNICATION_SUCCESS = 2029, 
  // 通信丢失，表示15秒未收到任何数据 
  NOTIFY_COMMUNICATION_LOST = 2030, 
  // 通信丢失后，重新恢复 
  NOTIFY_COMMUNICATION_RESTORE = 2031, 
  // 目标检测结果 
  NOTIFY_TARGET_DETECTION = 2301, 
  // 目标跟踪结果 
  NOTIFY_TARGET_TRACK = 2302, 
  // 深度信息 
  NOTIFY_DEPTH_INFO = 2303, 

  /*************************************上层调用 结束**************************************************/ 
  
  
  // 隐藏背景 
  NOTIFY_HIDE_BG = 3004, 
  // 起飞 
  NOTIFY_TO_FLY = 3005, 
  // 降落 
  NOTIFY_TO_LAND = 3006, 
  // 停止 
  NOTIFY_TO_STOP = 3007, 
  // 无头模式 
  NOTIFY_TO_WUTOU = 3014, 
  // 反转 
  NOTIFY_TO_REVESER = 3015, 
  // 隐藏内容界面 
  NOTIFY_HIDE_CONTENT_VIEW = 3012, 
  // 校准 
  NOTIFY_CALIBRATION = 3013, 
  // 解锁 
  NOTIFY_UNLOCK = 3014, 
  // 返航 
  NOTIFY_GO_HOME = 3017, 
}