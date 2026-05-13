

export const add: (a: number, b: number) => number;
export const createVideoStream: (a: number) => boolean;
export const addVideoStream: (a: Uint8Array, b: number)=>void;
export const getVideoOneFrameArray: (a: Uint8Array, b: boolean)=>ArrayBuffer;
export const CreateFixedArrayBuffer: (a: number) => ArrayBuffer;
export const start: () => void;


/**
 * usb环形buf相关
 * */
export const createUsbStream: () => void;
export const addUsbStream: (data: Uint8Array, length: number)=>void;
export const getUsbOneFrame: (data: Array<number>)=>Uint8Array;

// videodecoder.d.ts 或 VideoDecoder.ts

/**
 * 解码相关
 * */

/**
 * 视频帧对象接口
 */
export interface VideoFrame {
  width: number;       // 帧宽度
  height: number;      // 帧高度
  stride: number;      // 行跨度
  timestamp: number;   // 时间戳（单位：微秒）
  format: number;      // 像素格式
  data: Uint8Array;    // 帧数据（YUV格式）
}

/**
 * 格式变更信息接口
 */
export interface FormatChangedInfo {
  width: number;      // 新的宽度
  height: number;     // 新的高度
  format: number;     // 新的像素格式
}

/**
 * 解码器信息接口
 */
export interface DecoderInfo {
  width: number;      // 当前视频宽度
  height: number;     // 当前视频高度
  initialized: boolean; // 是否已初始化
  started: boolean;   // 是否已启动解码
  surfaceMode: boolean; // 是否为Surface渲染模式
}

/**
 * 帧回调函数类型
 */
export type FrameCallback = (frame: VideoFrame) => void;

/**
 * 错误回调函数类型
 */
export type ErrorCallback = (errorCode: number) => void;

/**
 * 格式变更回调函数类型
 */
export type FormatChangedCallback = (formatInfo: FormatChangedInfo) => void;

/**
 * 视频解码器API
 */
export const initialize: (mimeType: string, width: number, height: number) => boolean;

/**
 * 设置Surface用于渲染模式
 * @param nativeWindow NativeWindow对象，通常从XComponent获取
 */
export const setSurface: (nativeWindow:number|bigint) => boolean;

/**
 * 设置解码器回调函数
 * @param frameCallback 帧数据回调（可为null/undefined）
 * @param errorCallback 错误回调（可为null/undefined）
 * @param formatChangedCallback 格式变更回调（可为null/undefined）
 */
export const setCallbacks: (
  frameCallback: FrameCallback | null | undefined,
  errorCallback: ErrorCallback | null | undefined,
  formatChangedCallback: FormatChangedCallback | null | undefined
) => void;

/**
 * 解码一帧数据（使用TypedArray）
 * @param frameData Uint8Array类型的数据
 * @param timestamp 帧时间戳（单位：微秒）
 */
export const decodeFrame: (frameData: Uint8Array, timestamp: number,isI:boolean) => boolean;

/**
 * 获取已解码的帧（同步方式）
 * @param timeoutMs 可选超时时间（毫秒）
 * @returns VideoFrame对象，或null（超时或无可用帧）
 */
export const getDecodedFrame: (timeoutMs?: number) => VideoFrame | null;

/**
 * 刷新解码器，清空内部缓冲区
 */
export const flush: () => void;

/**
 * 停止解码器
 */
export const stop: () => void;

/**
 * 释放解码器资源
 */
export const release: () => void;

/**
 * 获取解码器状态信息
 */
export const getInfo: () => DecoderInfo;

/**
 * 检查是否支持指定格式
 * @param mimeType 媒体类型（如："video/avc"）
 */
/*export const isSupported: (mimeType: string) => boolean;*/


/**
 * 录制相关
 * */
//开始录制
export const  StreamRecording : (fd:number) => void;

/*停止录制*/
export const  StopRecording : () => void;



