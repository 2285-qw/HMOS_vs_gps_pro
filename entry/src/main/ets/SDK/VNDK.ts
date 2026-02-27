/**
 * 循环缓冲区数据操作模块
 * 用于处理不同协议的音视频帧数据缓冲、读取和解析
 */
declare namespace BLoopBufData {
  /**
   * 创建循环缓冲区实例
   * @param dwBufType 缓冲区类型（BLBDATA_TYPE枚举）
   * @param dwMemSize 缓冲区内存大小（字节）
   * @returns 缓冲区句柄（BLHANDLE），失败返回0
   */
  function BLBDATA_Create(dwBufType: number, dwMemSize: number): number;

  /**
   * 销毁循环缓冲区实例
   * @param dwHandle 缓冲区句柄
   * @returns 操作结果（1：成功，0：失败）
   */
  function BLBDATA_Destory(dwHandle: number): number;

  /**
   * 向缓冲区写入数据
   * @param dwHandle 缓冲区句柄
   * @param pSrcBuf 待写入数据的指针
   * @param dwWriteLen 写入数据长度（字节）
   * @returns 操作结果（1：成功，0：失败）
   */
  function BLBDATA_Write(dwHandle: number, pSrcBuf: Uint8Array, dwWriteLen: number): number;

  /**
   * 从缓冲区获取一帧数据
   * @param dwHandle 缓冲区句柄
   * @param pHead 输出参数，帧头部信息（FHNP_Dev_FrameHead）
   * @param pFrame 输出参数，帧数据缓冲区
   * @param bIsIFrame 是否为I帧（1：是，0：否）
   * @returns 操作结果（1：成功，0：失败）
   */
  function BLBDATA_GetOneFrame(
    dwHandle: number,
    pHead: FHNP_Dev_FrameHead,
    pFrame: Uint8Array,
    bIsIFrame: number
  ): number;

  /**
   * 设置缓冲区读取位置
   * @param dwHandle 缓冲区句柄
   * @param dwRead 读取位置偏移量
   * @param bLock 是否加锁（1：加锁，0：不加锁）
   * @returns 操作结果（1：成功，0：失败）
   */
  function BLBDATA_SetReadPos(dwHandle: number, dwRead: number, bLock: number): number;

  /**
   * 锁定缓冲区（线程安全）
   * @param dwHandle 缓冲区句柄
   * @returns 操作结果（1：成功，0：失败）
   */
  function BLBDATA_Lock(dwHandle: number): number;

  /**
   * 解锁缓冲区
   * @param dwHandle 缓冲区句柄
   * @returns 操作结果（1：成功，0：失败）
   */
  function BLBDATA_Unlock(dwHandle: number): number;

  /**
   * 获取缓冲区已使用大小
   * @param dwHandle 缓冲区句柄
   * @returns 已使用大小（字节）
   */
  function BLBDATA_GetUsedSize(dwHandle: number): number;

  /**
   * 获取缓冲区空闲大小
   * @param dwHandle 缓冲区句柄
   * @returns 空闲大小（字节）
   */
  function BLBDATA_GetFreeSize(dwHandle: number): number;
}

// 导出帧头部结构体类型
declare type FHNP_Dev_FrameHead = {
  FrmHd: Uint8Array;
  Vmsflag: number;
  AVOption: number;
  VideoFormat: number;
  AudioFormat: number;
  restart_flag: number;
  frmnum: number;
  Framerate: number;
  Bitrate: number;
  framelen: number;
  HideAlarmStatus: number;
  alarmstatus: number;
  mdstatus: number;
  timestamp: bigint;
  reserve: Uint8Array;
};

export default BLoopBufData;