import { PlayInfo, StreamType, TransportMode, SubCameraType, DeviceType } from '../../model/PlayInfo'
import NapiBuffer, { VideoFrame } from 'libentry.so';
import { WifiCommandHelper } from '../../helper/WifiCommandHelper';
import { HisiCommandHelper } from '../../hisi/HisiCommandHelper';
import { ConfigureInfo } from '../../model/ConfigureInfo'
// 获取当前时间戳（毫秒级）
import { systemDateTime } from '@kit.BasicServicesKit';
import { StreamInfoManager } from '../manager/StreamInfoManager'
// 1. 导入原子类
import AtomicRef from '@ohos.base'; // 官方标准模块，直接导入
import promptAction from '@ohos.promptAction';

// 导入模块
import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';

export class VideoStreamHandle {
  private isCreate: boolean = false;
  private isRequestIFrame: boolean = false; //是否等待关键帧
  private requestKeyFrameMills: number = 0;
  // 头部信息数组
  private header: Uint8Array = new Uint8Array(7);
  private worker: worker.ThreadWorker = new worker.ThreadWorker('entry/ets/workers/Worker.ets');
  private static instance: VideoStreamHandle;



  // 单例模式，确保唯一实例
  private constructor() {
  }

  static getInstance(): VideoStreamHandle {
    if (!VideoStreamHandle.instance) {
      VideoStreamHandle.instance = new VideoStreamHandle();
    }
    return VideoStreamHandle.instance;
  }

  public  setCreate(isCreate: boolean) {
    console.log('初始化视频解码器——————-'+this.isCreate)
    this.isCreate = isCreate;
  }


  /**
   * 创建视频流处理资源。
   * <p>
   * 此方法用于初始化视频流处理所需的资源和组件。它首先检查是否已经初始化，
   * 如果没有，则会进行一系列的初始化操作。
   */
  public create() {

    try {
      // 记录创建过程中的日志信息，包括流类型和初始化状态

      // 只有当initState为false，即未初始化时，才执行初始化操作
   /*   promptAction.showToast({
        message: '初始化视频解码器'+!this.isCreate,
        duration: 2000,  // 显示时长（毫秒）
        bottom: '50vp'   // 距屏幕底部距离
      });*/
      console.log('初始化视频解码器'+!this.isCreate)
      if (!this.isCreate) {

        this.isCreate_f(true);
        // 记录初始化视频流的日志信息

        // 根据播放信息创建视频流
        NapiBuffer.createVideoStream(PlayInfo.streamType)
        // 初始化解码器
        // initDecode();
        // 主线程


        this.worker.onmessage = (e: MessageEvents) => {
          if (e.data.type == "isCreate") {
            this.setCreate(e.data)
          }

        };

        this.worker.postMessage({
          type: "onFetchFrame",
          data:"1"
        });


      }
    } catch (e) {
      // 捕获并打印出任何可能发生的异常，便于调试和错误追踪
      console.error('初始化视频解码器报错'+e)
    }
  }

  public isCreate_f(b:boolean) {
    console.log('初始化视频解码器——————-'+this.isCreate)
    this.isCreate = b
    this.worker.postMessage({
      type: "isCreate",
      data: b
    });
  }


  public getFetchFrame() {
    this.setRequestIFrame();
    this.onFetchFrame();
  }


  /**
   * 设置是否请求关键帧
   */
  public setRequestIFrame() {
    this.isRequestIFrame = true;
    WifiCommandHelper.requestIFrame();
    HisiCommandHelper.requestIFame();
    // 记录请求IDR帧时间
    this.requestKeyFrameMills = systemDateTime.getTime(false); // true返回纳秒级时间戳（false为毫秒）
    console.log("发送请求IDR帧命令");
  }




  public onFetchFrame() {
    console.log("开始获取帧数据", this.isCreate);
    const fetchFrame = () => {
      if (!this.isCreate) {
        console.error(`视频流状态断开`);
        return;
      }
     // console.log("获取到一帧数据", this.isCreate);
      let oneFrame: ArrayBuffer;

      if (PlayInfo.streamType == StreamType.JPEG) {
        oneFrame = NapiBuffer.getVideoOneFrameArray(this.header, false);
      } else if (PlayInfo.streamType == StreamType.YUV) {
        oneFrame = NapiBuffer.getVideoOneFrameArray(this.header, false);
      } else if (PlayInfo.streamType == StreamType.H265) {
        oneFrame = NapiBuffer.getVideoOneFrameArray(this.header, true);
      } else {
        oneFrame = NapiBuffer.getVideoOneFrameArray(this.header, true);
      }
      if(this.header[2]!=0xA1){
        if (this.isRequestIFrame) {
          //需要i帧
          const timestamp = systemDateTime.getTime(false)
          if (timestamp-this.requestKeyFrameMills>500) {
            this.setRequestIFrame();
          }
        }
      }else {
        //得到i帧
        //console.log("获取到一帧数据_==得到i帧",this.header[2],oneFrame);
        this.isRequestIFrame =false;
      }
      // console.log("从buf获取到一帧数据_==", oneFrame);
      if (oneFrame != undefined && oneFrame.byteLength >= 5) {
       let frame= new Uint8Array(oneFrame);
       // console.log("获取到一帧数据_==", frame);
       // console.log("获取到一帧数据_==头",  this.header);
        const timestamp = Date.now() * 1000; // 转换为微秒
      //  let  timestamp: bigint =BigInt( Date.now()) * 1000n; // 转换为微秒
        console.log("时间戳数据==", timestamp);
        //传入数据解码
      let i=  NapiBuffer.decodeFrame(frame, timestamp,this.header[2]==0xA1);

      } else {
        // 如果获取不到帧，可以适当暂停，避免空转

      }
      setTimeout(fetchFrame, 10);
      // 设置下一次获取，例如每33毫秒获取一帧

    };

    fetchFrame();
  }


  /**
   * 处理一帧数据，送入解码器/或显示
   *
   * @param oneFrame
   * @param header
   */
  private processOneFrame(oneFrame: Uint8Array, header: Uint8Array) {
    let order: number = header[0];
    let len = header[1];
    let type = header[2];

    // LogUtils.d("processOneFrame = ", order, len, type, PlayInfo.streamType);

    /* 测试log打印 */
    /*    if (ConfigureInfo.IS_FAME_LOG) {
          // 按二进制单位（1KB=1024字节）
          double
          kbBinary = (double)
          len / 1024;
          long
          currentTimeMillis = System.currentTimeMillis();
          int
          iFrameInterval = (int)(currentTimeMillis - lastAddTimeMillis);
          if (type == 161) {
            StreamInfoManager.getInstance().setIFrameInterval(iFrameInterval);
          }
          String
          log = String.format(Locale.US, "帧间隔: %s , %s , %.2f , %d", type, iFrameInterval, kbBinary, order);
          LogUtils.print(log);
          LogManager.getInstance().addLog(log);
          lastAddTimeMillis = currentTimeMillis;
        }*/

    //拍照时，卡帧避免P帧花屏
    /* if (type == 161) {
       this.isRequestIFrame=false;

       if (FileStreamManager.isStart) {
         isStartRecord = true;
       }

       if (isStartRecord && FileStreamManager.isStart) {
         FileStreamManager.getInstance().writeFile(oneFrame, oneFrame.length);
       }
     }*/

    if (this.isRequestIFrame) {
      console.log("主动等待I帧");
    } else if (oneFrame.length == 5) {
      this.setRequestIFrame();
      console.log("检查I帧");
    } else if (oneFrame[len - 4] != header[3]
      && oneFrame[len - 3] != header[4]
      && oneFrame[len - 2] != header[5]
      && oneFrame[len - 1] != header[6]
      && PlayInfo.isGK()) {
      console.log("国科校验数据，错误");
      //LogManager.getInstance().addLog("校验数据错误,主动等待I帧");
    } else {
      try {
        //根据类型解码
        /*  if (PlayInfo.streamType == StreamType.YUV) {
            decodeFrameYUV(oneFrame);
          } else if (PlayInfo.streamType == PlayInfo.StreamType.JPEG) {
            decodeFrameJpeg(oneFrame);
          } else {
            //LogUtils.d("oneFrame", ObjectUtils.bytesToHexString(oneFrame));
            FrameType
            frameType = detectCodecType(oneFrame, type);
            handleDecodingByFrameType(oneFrame, frameType);
          }*/
      } catch (e) {
        e.printStackTrace();
        console.log(e);
      }
    }
  }

  /**
   * 添加视频流数据到处理流程中。
   * <p>
   * 此方法用于将视频流数据（如从网络或本地文件中获取的）添加到系统中，
   * 以便进行进一步的处理，如解码、显示等。
   *
   * @param data   视频流数据的字节数组。
   * @param length 数据的有效长度，表示字节数组中实际包含的视频流数据的长度。
   */
  public addVideoStream(data: Uint8Array, length: number) {
    try {
      // 检查系统是否已经初始化，如果没有初始化则记录错误并返回
      console.log("添加数据", this.isCreate, PlayInfo.is872());
      if (!this.isCreate) {
        console.log("请先初始化 addVideoStream"); // 使用日志工具记录错误信息
        return;
      }
      // 如果系统中存在心跳管理对象，则触发心跳事件，以维持连接活跃等
      //HeartbeatManager.getInstance().heartbeat();

      // 根据播放信息判断是否为特定格式（如872格式），并调用相应的处理方法
      if (PlayInfo.is872()) {
        // NapiBuffer.add872Stream(data, length); // 特定格式的视频流数据添加方法
        console.log("872板方法未处理"); // 使用日志工具记录错误信息
      } else {

        // console.log("添加数据"+data); // 使用日志工具记录错误信息
        NapiBuffer.addVideoStream(data, length); // 通用视频流数据添加方法
      }
      // 更新流信息管理器中记录的当前帧大小
      // StreamInfoManager.getInstance().setFrameSize(length);
    } catch (e) {
      // 捕获并打印出任何可能发生的异常，便于调试和错误追踪
      console.error(e)
    }
  }

  public release(){
    //设置状态停止
    this.isCreate_f(false);

  }

}