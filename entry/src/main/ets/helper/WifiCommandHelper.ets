import  EntryAbility  from '../entryability/EntryAbility';

export  class WifiCommandHelper{
  /**
   * 获取版类型
   */
  public static getDevType(){
    EntryAbility.getInstance().sendUDPCmd(new Uint8Array([0x0f]))
  }

  /**
   * 获取wifi版 版本号
   * 返回 V2, V3开头, V5, V6, V8
   */
  public static  getVersion() {
    EntryAbility.getInstance().sendUDPCmd(new Uint8Array([0x28]));
  }


  /**
   * 获取跟随码
   */
  public static  getWifiCode() {
    EntryAbility.getInstance().sendUDPCmd(new Uint8Array([0x0B]));
  }


  /**
   * 获取国家码
   */
  public static  getCountryCode() {
    EntryAbility.getInstance().sendUDPCmd(new Uint8Array([0x47]));
  }


  /**
   * 获取镜头index
   * 0=主、1=副
   */
  public static  getCameraIndex() {
    const  data = new Uint8Array([0XFF,0x53, 0x54, 0x33, 0x16]);
    EntryAbility.getInstance().sendUDPCmd(data);
  }

  /**
   * 请求I帧
   */
  public static  requestIFrame() {
    EntryAbility.getInstance().sendUDPCmd(new Uint8Array([0x27]));
  }


  /**
   * 获取画面方向
   * 返回 mirror=0, mirror=1
   */
  public static  getVideoOrientation() {
    EntryAbility.getInstance().sendUDPCmd(new Uint8Array([0x2c]));
  }

  /**
   * UDP-设置Wi-Fi板时间
   */
  public static  udpSendTime() {
    let d: Date = new Date();
    let  year = d.getFullYear() + 1900;
    let month = d.getMonth() + 1;
    let date = d.getDate();
    let day = d.getDay();
    let hour = d.getHours();
    let minite = d.getMinutes();
    let second = d.getSeconds();

   /* String log=String.format(Locale.CANADA,"%d %d %d - %d %d %d",year,month,day,hour,minite,second);
    //LogUtils.d("发送日期 : "+log);
    LogManager.getInstance().addLog("发送日期 : "+log);*/

    let str: Uint8Array = new Uint8Array(29);
    str[0] = 0x26;
    str[1] =  (year & 0xff);
    str[2] =  ((year & 0xff00) >> 8);
    str[3] =  ((year & 0xff0000) >> 16);
    str[4] =  ((year & 0xff000000) >> 24);
    str[5] =  (month & 0xff);
    str[6] =  ((month & 0xff00) >> 8);
    str[7] =  ((month & 0xff0000) >> 16);
    str[8] =  ((month & 0xff000000) >> 24);

    str[9] =  (date & 0xff);
    str[10] =  ((date & 0xff00) >> 8);
    str[11] =  ((date & 0xff0000) >> 16);
    str[12] =  ((date & 0xff000000) >> 24);
    str[13] =  (day & 0xff);
    str[14] =  ((day & 0xff00) >> 8);
    str[15] =  ((day & 0xff0000) >> 16);
    str[16] =  ((day & 0xff000000) >> 24);

    str[17] =  (hour & 0xff);
    str[18] =  ((hour & 0xff00) >> 8);
    str[19] =  ((hour & 0xff0000) >> 16);
    str[20] =  ((hour & 0xff000000) >> 24);
    str[21] =  (minite & 0xff);
    str[22] =  ((minite & 0xff00) >> 8);
    str[23] =  ((minite & 0xff0000) >> 16);
    str[24] =  ((minite & 0xff000000) >> 24);

    str[25] =  (second & 0xff);
    str[26] =  ((second & 0xff00) >> 8);
    str[27] =  ((second & 0xff0000) >> 16);
    str[28] =  ((second & 0xff000000) >> 24);
    EntryAbility.getInstance().sendUDPCmd(str);
  }



}