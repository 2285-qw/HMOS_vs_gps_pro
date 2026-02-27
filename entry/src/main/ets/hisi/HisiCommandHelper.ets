import EntryAbility from '../entryability/EntryAbility';






export class HisiCommandHelper {


  /**
   * 获取传感器
   */
  public static  getSensor(){
    HisiCommandHelper.sendDataNew(0x02);
  }


  /**
   * 获取版类型
   */
  public static getDevType() {
    EntryAbility.getInstance().sendUDPCmd(new Uint8Array([0x0f]))
  }


  /**
   * 设置IFame级别
   */
  public static setIFameLevel(value: number) {
    HisiCommandHelper.sendData(0x47,value);
  }

  /**
   * 获取录像分辨率
   */
  public static  getRecordResolution(){
    HisiCommandHelper.sendDataNew(0x1f);
  }




  /**
   * 请求I帧
   */
  public static requestIFame() {
    const data = new Uint8Array([0XFF, 0x35, 0x19, 0x0a, 0x16]);
    EntryAbility.getInstance().sendUDPCmd(data);
  }

  private static sendDataNew(type: number) {
    const data = new Uint8Array([0XFF, 0x35, 0x19, 0x0a, type]);
    EntryAbility.getInstance().sendUDPCmd(data);
    //SendDataManager.getInstance().addMessage(bytes,type);
  }

  private static sendData(type: number,mode:number) {
    const data = new Uint8Array([0XFF, 0x35, 0x19, 0x0a, type,mode]);
    EntryAbility.getInstance().sendUDPCmd(data);
    //SendDataManager.getInstance().addMessage(bytes,type);
  }


  public static  sendSystemTime() {
    let d: Date = new Date();

    let year = d.getFullYear() + 1900;
    let month = d.getMonth() + 1;
    let date = d.getDate();
    let day = d.getDay();
    let hour = d.getHours();
    let minite = d.getMinutes();
    let second = d.getSeconds();

    //byte str[] = new byte[28];
    let str: Uint8Array = new Uint8Array(28);
    str[0] = (year & 0xff);
    str[1] =  ((year & 0xff00) >> 8);
    str[2] =  ((year & 0xff0000) >> 16);
    str[3] =  ((year & 0xff000000) >> 24);
    str[4] =  (month & 0xff);
    str[5] =  ((month & 0xff00) >> 8);
    str[6] =  ((month & 0xff0000) >> 16);
    str[7] =  ((month & 0xff000000) >> 24);

    str[8] =  (date & 0xff);
    str[9] =  ((date & 0xff00) >> 8);
    str[10] =  ((date & 0xff0000) >> 16);
    str[11] =  ((date & 0xff000000) >> 24);
    str[12] =  (day & 0xff);
    str[13] =  ((day & 0xff00) >> 8);
    str[14] =  ((day & 0xff0000) >> 16);
    str[15] =  ((day & 0xff000000) >> 24);

    str[16] =  (hour & 0xff);
    str[17] = ((hour & 0xff00) >> 8);
    str[18] =  ((hour & 0xff0000) >> 16);
    str[19] =  ((hour & 0xff000000) >> 24);
    str[20] = (minite & 0xff);
    str[21] =  ((minite & 0xff00) >> 8);
    str[22] =  ((minite & 0xff0000) >> 16);
    str[23] =  ((minite & 0xff000000) >> 24);

    str[24] =  (second & 0xff);
    str[25] = ((second & 0xff00) >> 8);
    str[26] = ((second & 0xff0000) >> 16);
    str[27] =  ((second & 0xff000000) >> 24);


    let bytes: Uint8Array = new Uint8Array(str.length + 5);
    bytes[0] =  0xff;
    bytes[1] =  0x35;
    bytes[2] = 0x19;
    bytes[3] =  0x0a;
    bytes[4] =  0x03;

    for (let  i = 0; i < str.length; i++) {
      bytes[i + 5] = str[i];
    }
    EntryAbility.getInstance().sendUDPCmd(bytes);
  }


}