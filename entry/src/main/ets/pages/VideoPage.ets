// VideoPage.ets
import NapiBuffer, { VideoFrame } from 'libentry.so';
import { ObjectUtils } from '../utils/ObjectUtils';
import { ConfigureInfo } from '../model/ConfigureInfo'
import { window, promptAction } from '@kit.ArkUI';
import EntryAbility from '../entryability/EntryAbility';
import { PlayInfo, StreamType } from '../model/PlayInfo';
import { ConnectionStatusListener } from '../listeners/ConnectionStatusListener';
//import image from '@ohos.multimedia.image';
import { BusinessError } from '@ohos.base';
import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import fs from '@ohos.file.fs';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { media } from '@kit.MediaKit';
import { fileIo } from "@kit.CoreFileKit";
import { emitter } from '@kit.BasicServicesKit';


@Entry
@Component
export struct VideoPage {
  @State message: string = 'Hello World'
  myXComponentController: XComponentController = new XComponentController()
  @State surfaceId: string = '';
  pixelMap?: image.PixelMap; // 声明PixelMap变量
  @State p: boolean = false;
  private xComponentController: XComponentController = new XComponentController();
  private cameraManager?: camera.CameraManager;
  private previewWidth: number = 0;
  private previewHeight: number = 0;
  private avRecorder?: media.AVRecorder;



  build() {
    Column() {
      Stack({}) {

        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          XComponent({
            type: XComponentType.SURFACE,
            controller: this.myXComponentController
          })
            .onLoad(() => {
              // 修改


              let surfaceId: string = this.myXComponentController.getXComponentSurfaceId();
              console.info("XComponent SurfaceId: " + surfaceId);

              this.surfaceId = surfaceId;


              let state = "";
              if (PlayInfo.streamType == StreamType.H264
                || PlayInfo.streamType == StreamType.H264_VGA
                || PlayInfo.streamType == StreamType.YUV) {
                // 初始化h264 解码器
                // const success = NapiBuffer.initialize('video/avc', 1280, 720);
                console.log("初始化解码类型h264")
                state = 'video/avc';
              } else {
                // 初始化h265 解码器
                state = 'video/hevc';
                console.log("初始化解码类型h265")
              }

              // 1. 初始化解码器
              const success = NapiBuffer.initialize(state, 1280, 720);
              if (!success) {
                console.error('解码器初始化失败');
                return;
              }

              //开始心跳
              this.setHeart(true);
              // 不设置Surface，直接启动解码器
             // NapiBuffer.start();
                  // 2. 设置回调
                /*  NapiBuffer.setCallbacks(
                    (frame) => {
                      console.log(`回调数据收到帧: ${frame.width}x${frame.height}, timestamp: ${frame.timestamp}， data: ${frame.data}`);
                      // 处理帧数据...
                    },
                    (errorCode) => {
                      console.error(`回调数据解码错误: ${errorCode}`);
                    },
                    (formatInfo) => {
                      console.log(`回调数据格式变更: ${formatInfo.width}x${formatInfo.height}, format: ${formatInfo.format}`);
                    }
                  );*/
              const i = NapiBuffer.setSurface(BigInt(surfaceId));

              console.error(`绑定ui: ${i}`);

              /*  // 获取NativeWindow
                let nativeWindow = this.getUIContext.getNativeWindow()
                if (nativeWindow) {
                  // 调用Native方法，设置Surface
                  // 假设有一个Native方法叫setNativeWindow
                  NapiBuffer.setSurface(nativeWindow);
                  // 这里需要调用Native模块
                  // 例如：nativeModule.setNativeWindow(nativeWindow)
                  console.log('获取到NativeWindow')
                }*/


              AppStorage.Set<boolean>('isDecode', true);
              /*   const b=   AppStorage.get<boolean>('isDecode')
                 promptAction.showToast({
                   message: 'Hello World:${b}'+b,
                   duration: 2000
                 });*/


              // 3. 解码数据
              const data: Uint8Array | null = this.readHexFile();
              console.log(`数据` + ObjectUtils.arrayBufferToHex(data));
              console.log(`数据长度` + data?.length);
              if (data != null) {
                const timestamp = Date.now() * 1000; // 转换为微秒
                NapiBuffer.decodeFrame(data, timestamp, true);


                // 4. 获取解码器信息
                const info = NapiBuffer.getInfo();
                console.log(`解码器信息: ${JSON.stringify(info)}`);

                // 5. 使用完毕后释放资源
                // NapiBuffer.release()
              } else {
                console.log(`数据为空`);
              }

              const data1: VideoFrame | null = NapiBuffer.getDecodedFrame()

              console.log(`解码器信息: ${data1}`);


            })
        }.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]) // 关键代码：扩展底部安全区
        .width('100%')
        .height('100%').onClick(() => {
          /*  const data1:VideoFrame|null = NapiBuffer.getDecodedFrame()
            console.log(`解码器信息: ${data1}`);*/
          this.captureImage()
        })



        Column({ space: 35 }) {
          Row({ space: 20 }) {
            Text('开始录制').fontSize(15).fontColor(Color.Gray).backgroundColor(Color.Black).onClick(() => {
              this.startRecording()
            })
            Text('停止录制').fontSize(15).fontColor(Color.Gray).backgroundColor(Color.Black).onClick(() => {
              this.stopVideo()
            })
            Text('拍照').fontSize(15).fontColor(Color.Gray).backgroundColor(Color.Black).onClick(() => {
              this.captureImage()
            })
            Text('屏幕录制').fontSize(15).fontColor(Color.Gray).backgroundColor(Color.Black).onClick(() => {
              this.startRecording1()
            })
            Text('停止屏幕录制').fontSize(15).fontColor(Color.Gray).backgroundColor(Color.Black).onClick(() => {
              this.stopRecording()
            })
          }.width('100%').padding(20)
        }.width('90%').height('100%').justifyContent(FlexAlign.Start)

      }.width('100%').height('100%')
    }

  }



  public readHexFile(): Uint8Array | null {
    try {
      // 获取resourceManager对象
      const context = getContext(this);
      const resourceMgr = context.resourceManager;

      // 获取rawfile目录下的文件描述符
      let fileDescriptor: Uint8Array = resourceMgr.getRawFileContentSync('1111.logbin');

      return fileDescriptor;
    } catch (error) {
      console.error('Failed to read hex file: ' + error);
    }
    return null;
  }

  onPageShow(): void {

    //监听连接状态开始视频流心跳
    EntryAbility.getInstance().setConnectionStatusListener(this.connectionStatusListener);
    // 持续订阅
    emitter.on({ eventId: 1001 }, (eventData) => {
      console.log("Received event data:", JSON.stringify(eventData.data));
      // 显示接收到的文本
      promptAction.showToast({
        message: `接收到文本: ${eventData.data}`,
        duration: 2000
      });
    });

  }

  aboutToDisappear(): void {
    // 5. 使用完毕后释放资源
    NapiBuffer.release()
    //取消订阅
    emitter.off(1001)
  }

  onPageHide(): void {
    //停止心跳
    this.setHeart(false);
  }

  // 初始化相机
  async initCamera() {
    try {
      this.cameraManager = await camera.getCameraManager(getContext());
      const cameras = await this.cameraManager.getSupportedCameras();
      // ... 相机配置逻辑
      //  await this.getPreviewSize(); // 获取预览流宽高
    } catch (error) {
      console.error(`Camera init failed: ${error}`);
    }
  }

  // 保存 PixelMap 到指定路径
  async savePixelMapToPath(pixelMap: image.PixelMap, filePath: string): Promise<boolean> {
    try {
      // 1. 创建 ImagePacker 实例
      const imagePackerApi = image.createImagePacker();

      // 2. 配置打包选项（可选）
      const packOptions: image.PackingOption = {
        format: 'image/jpeg', // 或 'image/png'
        quality: 100 // 质量 0-100
      };

      // 3. 将 PixelMap 打包为 ArrayBuffer
      const data: ArrayBuffer = await imagePackerApi.packing(pixelMap, packOptions);

      // 4. 写入文件
      const file = await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.write(file.fd, data);
      await fs.close(file.fd);

      // 释放资源
      imagePackerApi.release();
      console.error('保存成功 ');
      return true;
    } catch (error) {
      console.error('保存失败: ' + JSON.stringify(error));
      return false;
    }
  }

  /*  // 步骤1：获取预览流尺寸
    private async getPreviewSize(): Promise<void> {
      const cameraOutputCapability = this.cameraManager!.getOutputCapability(cameras);
      const previewProfiles = cameraOutputCapability.previewProfiles;
      if (previewProfiles.length > 0) {
        this.previewWidth = previewProfiles.size.width;
        this.previewHeight = previewProfiles.size.height;
      }
    }*/

  private  tempFile?: fs.File
  private   tempFilePath?:string;

  async startRecording() {
    // 1. 创建 AVRecorder
   await media.createAVRecorder().then(async (av:media.AVRecorder)=>{
      this.avRecorder=av;


     // 1. 创建临时文件
     const tempDir = getContext(this).cacheDir; // 临时目录
     const tempFileName = `video_${Date.now()}.mp4`;
     this. tempFilePath = `${tempDir}/${tempFileName}`;

     console.log("临时文件路径:",  this. tempFilePath);

     // 2. 创建临时文件并获取文件描述符
     this.tempFile = fs.openSync( this. tempFilePath, fs.OpenMode.READ_WRITE| fs.OpenMode.CREATE );
     let fd=this.tempFile.fd;
     // 2. 同步获取文件信息
     let fileInfo: fs.Stat = fs.statSync(fd);

     fs.access( this. tempFilePath).then((b:boolean)=>{
       console.log("录制开始=== 文件是否存在", b,fileInfo.size)
     })

     try {
     //fs.closeSync(tempFile);
     } catch (err) {
         console.log("测试失败:", err);
       }


     let helper = photoAccessHelper.getPhotoAccessHelper(getContext(this));
     let options: photoAccessHelper.CreateOptions = {
       title: 'video_3', // 文件名（不带扩展名）
       // subRelativePath: 'subfolder/' // 需系统相册内已存在该路径
     };


     // 创建视频资源（MP4格式）
     let videoUri = await helper.createAsset(
       photoAccessHelper.PhotoType.VIDEO, // 资源类型设为VIDEO
       'mp4', // 视频文件后缀（支持'mp4'、'mov'等）
       options
     );

     // 2. 配置参数
     const config: media.AVRecorderConfig = {
       videoSourceType: media.VideoSourceType.VIDEO_SOURCE_TYPE_SURFACE_YUV,
       profile: {
         fileFormat: media.ContainerFormatType.CFT_MPEG_4,
         videoCodec: media.CodecMimeType.VIDEO_AVC,
         videoBitrate: 2000000, // 必须设置
         videoFrameWidth: 1280,
         videoFrameHeight: 720,
         videoFrameRate: 30
       },
       url: `fd://${fd}`  // 关键：使用 fd:// 格式

     };
     console.log("录制开始===", 111111177777771, this.avRecorder)
     // 3. 准备录制器
     this.avRecorder.prepare(config).then(()=>{
       console.log("录制开始===", '0000000000000000')
       const surfaceId = this.surfaceId
       this.avRecorder?.getInputSurface().then((surface) => {
         console.log("录制开始===11111111", surface,surfaceId,surface === surfaceId)
         this.avRecorder?.start(); // 开始录制
         console.log("录制开始ttttttttt")
         if (surface === surfaceId) {


         }
       }).catch((err:BusinessError) => console.error("流程错误1:", err,err.code));
     }).catch((err:BusinessError) => console.error("流程错误2:", err,err.code));;
     console.log("录制开始===", '11111117777770000071',config,this.surfaceId)
     // 4. 绑定 XComponent 的 SurfaceId


     console.log("录制开始===", '11119999999991111')
    });


  }

  stopVideo() {
    console.log("录制停止")
    this.avRecorder?.stop();
    this.avRecorder?.release();

    let fd=this.tempFile?.fd;
    // 2. 同步获取文件信息
    let fileInfo: fs.Stat = fs.statSync(fd);
    console.log("录制大小",fileInfo.size)


this.stopRecordingAndSave()

  }



  // 停止录制后保存到相册的方法
  async  stopRecordingAndSave() {
  //if (!this.avRecorder) return;

  try {
 /*   // 1. 停止录制
    await this.avRecorder.stop();
    await this.avRecorder.release();*/

    // 2. 创建相册资源
    let helper = photoAccessHelper.getPhotoAccessHelper(getContext(this));
    let options: photoAccessHelper.CreateOptions = {
      title: 'video_' + Date.now(),
    };


    // 3. 读取临时文件内容
    const tempFilePath = this.tempFilePath; // 保存临时文件路径
    let file = fs.openSync(tempFilePath, fs.OpenMode.READ_ONLY);
    let stat = fs.statSync(file.fd);

    // 4. 创建相册视频资源
    let videoAsset = await helper.createAsset(
      photoAccessHelper.PhotoType.VIDEO,
      'mp4',
      options
    );

    // 5. 打开相册资源写入
    const file1 = await fs.open(videoAsset, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    let photoFd =  file1.fd;
    console.log("保存",file1)

    // 6. 复制文件内容
    const bufferSize = 1024 * 1024; // 1MB缓冲区
    let buffer = new ArrayBuffer(bufferSize);
    let offset = 0;

    while (offset < stat.size) {
      let readSize = Math.min(bufferSize, stat.size - offset);
      let readBuffer = new ArrayBuffer(readSize);
      fs.readSync(file.fd, readBuffer, { offset: offset });
      fs.writeSync(photoFd, readBuffer);
      offset += readSize;
    }

    // 7. 关闭文件
    fs.closeSync(file.fd);
    fs.closeSync(photoFd);

    // 8. 删除临时文件
    fs.unlinkSync(tempFilePath);

    console.log("视频保存成功:", videoAsset);

  } catch (err) {
    console.error("保存视频失败:", err);
  }
}

  private setHeart(isHeartbeat: boolean) {
    EntryAbility.getInstance().setVideoHeartbeat(isHeartbeat);
  }

  private connectionStatusListener: ConnectionStatusListener = {
    onDeviceConnection: () => {
      this.setHeart(true);

    },
    onDeviceDisconnection: () => {
      this.setHeart(false);
    }
  };

  // 步骤2：执行截图
  private async captureImage(): Promise<void> {
    //if (this.previewWidth === 0 || this.previewHeight === 0) return;


    try {
      this.pixelMap = await image.createPixelMapFromSurface(this.surfaceId);
      this.p = true;
      /*  let  region: image.Region = {
          x: 0, y: 0,
          size:{width:1080,height:720}

        };*/
      /*   console.log("1111111111111=========",imageSource,this.surfaceId)
         const pixelMap = await imageSource.createPixelMap();*/
      console.log("1111111111111", this.pixelMap)
      this.saveImage(this.pixelMap)
      // 保存或使用pixelMap
    } catch (error) {
      console.error(`Capture failed: ${error}`);
    }
  }

  private async saveImage(pixelMap: image.PixelMap) {

    //当前时间戳
    const timestamp: number = Date.now(); // 或 new Date().getTime()
    const name = 'img_' + timestamp;
    // 保存到沙箱目录
    const targetPath = `${getContext().filesDir}/Image/${name}.jpg`;

    let helper = photoAccessHelper.getPhotoAccessHelper(getContext(this));
    let options: photoAccessHelper.CreateOptions = {
      title: name, // 文件名（不带扩展名）
      // subRelativePath: 'subfolder/' // 需系统相册内已存在该路径
    };
    let uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpeg', options);


    try {
      //保存图片
      this.savePixelMapToPath(pixelMap, uri)
      // console.info('图片已保存至: ' + targetPath);
    } catch (err) {
      // console.error('保存失败: ' + JSON.stringify(err));
    }
  }


  private  screenCapture?:media.AVScreenCaptureRecorder;

  async  startRecording1() {

    // 1. 创建临时文件
    const tempDir = getContext(this).cacheDir; // 临时目录
    const tempFileName = `video_${Date.now()}.mp4`;
    this. tempFilePath = `${tempDir}/${tempFileName}`;

    console.log("临时文件路径:",  this. tempFilePath);

    // 2. 创建临时文件并获取文件描述符
    this.tempFile = fs.openSync( this. tempFilePath, fs.OpenMode.READ_WRITE| fs.OpenMode.CREATE );
    let fd=this.tempFile.fd;
    // 2. 同步获取文件信息
    let fileInfo: fs.Stat = fs.statSync(fd);

  // 1. 创建实例
   this.screenCapture = await media.createAVScreenCaptureRecorder();

  // 2. 配置参数（沙箱路径）
  const filesDir = getContext().filesDir; // 应用沙箱目录
  const filePath = `${filesDir}/record.mp4`;
  const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);

  const avConfig: media.AVScreenCaptureRecordConfig = {
    fd: fd, // 文件对象
    frameWidth: 1280, // 宽度需为16倍数（H.264）
    frameHeight: 720,  // 高度需为16倍数
   // audioSource: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC // 麦克风输入
  };

  // 3. 初始化并开始录制
  await this.screenCapture.init(avConfig);
    this.screenCapture.startRecording();

  // 4. 监听状态和错误
    this.screenCapture.on("stateChange", (state) => {
    console.log(`状态1: ${state}`); // started/stopped/paused
  });
    this. screenCapture.on("error", (err) => {
    console.error(`错误1: ${JSON.stringify(err)}`);
  });
}

  // 停止录制
   stopRecording() {
     this.screenCapture?.stopRecording();
     this.screenCapture?.release();

     let fd=this.tempFile?.fd;
     // 2. 同步获取文件信息
     let fileInfo: fs.Stat = fs.statSync(fd);
     console.log("录制大小",fileInfo.size,this.tempFile?.path,this.tempFile?.name)


     this.stopRecordingAndSave()

   }


}