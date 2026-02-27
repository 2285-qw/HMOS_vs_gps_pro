export  class StreamInfoManager{


  private  mFrameSize:number=0;

  private static instance: StreamInfoManager;

  // 单例模式，确保唯一实例
  private constructor() {}
  static getInstance(): StreamInfoManager {
    if (!StreamInfoManager.instance) {
      StreamInfoManager.instance = new StreamInfoManager();
    }
    return StreamInfoManager.instance;
  }



  /**
   * 设置帧大小
   */
  public  setFrameSize(lan:number) {
  this.mFrameSize += lan;
}




}