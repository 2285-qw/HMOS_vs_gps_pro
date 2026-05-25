// MediaAlbum.ets (API 12 规范)
import fs from '@ohos.file.fs';
import router from '@ohos.router';
import { media } from '@kit.MediaKit';
import image from '@ohos.multimedia.image';

@Entry
@Component
struct MediaAlbum {
  @State currentTabIndex: number = 0;
  private swiperController: SwiperController = new SwiperController();
  private context: Context = getContext(this);

  aboutToAppear(): void {
    this.initDirsAndDemoFiles();
  }

  async initDirsAndDemoFiles(): Promise<void> {
    const imageDir: string = `${this.context.filesDir}/Image`;
    const videoDir: string = `${this.context.filesDir}/Video`;
    await this.ensureDir(imageDir);
    await this.ensureDir(videoDir);
  }

  async ensureDir(dirPath: string): Promise<void> {
    try {
      const exists = await fs.access(dirPath);
      if (!exists) {
        await fs.mkdir(dirPath);
      }
    } catch (err) {
      // 如果 access 抛出异常（如权限错误），也尝试创建目录
      await fs.mkdir(dirPath);
    }
  }

  build() {
    Column() {
      RelativeContainer() {
        Text('←')
          .id('backBtn')
          .fontSize(28)
          .fontColor(Color.White)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.back();
          })
          .alignRules({
            left: { anchor: '__container__', align: HorizontalAlign.Start },
            center: { anchor: '__container__', align: VerticalAlign.Center }
          })
          .margin({ left: 20 })

        Row() {
          Text('图片')
            .fontSize(18)
            .fontWeight(this.currentTabIndex === 0 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentTabIndex === 0 ? Color.White : '#ffa49b9b')
            .padding({ left: 12, right: 12, bottom: 6 })
            .borderWidth({ bottom: 2 })
            .borderColor({ bottom: this.currentTabIndex === 0 ? Color.White : Color.Transparent })
            .onClick(() => {
              this.currentTabIndex = 0;
              this.swiperController.changeIndex(0);
            })

          Text('视频')
            .fontSize(18)
            .fontWeight(this.currentTabIndex === 1 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentTabIndex === 1 ? Color.White : '#ffa49b9b')
            .padding({ left: 12, right: 12, bottom: 6 })
            .borderWidth({ bottom: 2 })
            .borderColor({ bottom: this.currentTabIndex === 1 ? Color.White : Color.Transparent })
            .onClick(() => {
              this.currentTabIndex = 1;
              this.swiperController.changeIndex(1);
            })
        }
        .id('tabsContainer')
        .height('100%')
        .alignItems(VerticalAlign.Bottom)
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center },
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
        })
      }
      .width('100%')
      .height(40)
      .backgroundColor('#2F2F2F')

      Swiper(this.swiperController) {
        ImageGallery({ context: this.context })
        VideoGallery({ context: this.context })
      }
      .index(this.currentTabIndex)
      .indicator(false)
      .loop(false)
      .width('100%')
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentTabIndex = index;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ff6d6d6d')
  }
}

// 图片网格组件
@Component
struct ImageGallery {
  @Prop context: Context = getContext(this);
  @State imageList: string[] = [];
  @State showPreview: boolean = false;
  @State previewImageUri: string = '';

  aboutToAppear(): void {
    this.loadImages();
  }

  async loadImages(): Promise<void> {
    const imageDir: string = `${getContext().filesDir}/Image`;
    // 确保目录存在
    try {
      const exists = await fs.access(imageDir);
      if (!exists) {
        await fs.mkdir(imageDir);
      }
    } catch {
      await fs.mkdir(imageDir);
    }
    try {
      const fileNames: string[] = await fs.listFile(imageDir);
      const images: string[] = fileNames
        .filter((fileName: string) => /\.(jpg|jpeg|png|gif)$/i.test(fileName))
        .map((fileName: string) => `file://${imageDir}/${fileName}`);
      this.imageList = images;
      console.log("图片数量", this.imageList.length);
    } catch (err) {
      console.error(`读取图片目录失败: ${err}`);
    }
  }

  build() {
    Column() {
      if (this.imageList.length === 0) {
        Blank();
        Text('暂无图片，请将图片放入沙箱目录')
          .fontSize(16)
          .fontColor('#999')
          .textAlign(TextAlign.Center);
        Blank();
      } else {
        Grid() {
          ForEach(this.imageList, (uri: string, idx?: number) => {
            GridItem() {
              Image(uri)
                .width('100%')
                .aspectRatio(1)
                .objectFit(ImageFit.Cover)
                .onClick(() => {
                  this.previewImageUri = uri;
                  this.showPreview = true;
                })
            }
            .borderRadius(8)
            .backgroundColor('#F0F0F0')
          }, (uri: string, idx?: number) => idx?.toString() ?? uri)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .padding(12)
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .bindContentCover(this.showPreview, this.ImagePreviewBuilder(), {
      modalTransition: ModalTransition.NONE,
      onDisappear: () => {
        this.previewImageUri = '';
      }
    })
  }

  @Builder
  ImagePreviewBuilder() {
    Column() {
      Image(this.previewImageUri)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
        .onClick(() => {
          this.showPreview = false;
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}

// 视频网格组件（符合 API 12 规范）
@Component
struct VideoGallery {
  @Prop context: Context = getContext(this);
  @State videoList: string[] = [];
  @State thumbnailMap: Map<string, string> = new Map();
  @State showPlayer: boolean = false;
  @State currentVideoUri: string = '';

  aboutToAppear(): void {
    this.context = getContext(this);
    this.loadVideos();
  }

  async loadVideos(): Promise<void> {
    const videoDir: string = `${getContext().filesDir}/Video`;
    // 确保目录存在
    try {
      const exists = await fs.access(videoDir);
      if (!exists) {
        await fs.mkdir(videoDir);
      }
    } catch {
      await fs.mkdir(videoDir);
    }
    try {
      const fileNames: string[] = await fs.listFile(videoDir);
      const videos: string[] = fileNames
        .filter((fileName: string) => /\.(mp4|mkv|avi|mov)$/i.test(fileName))
        .map((fileName: string) => `file://${videoDir}/${fileName}`);
      this.videoList = videos;
      await this.generateThumbnails(videos);
    } catch (err) {
      console.error(`读取视频目录失败: ${err}`);
    }
  }

  async generateThumbnails(videos: string[]): Promise<void> {
    console.error(`生成缩略图 `, 11111111111);
    const thumbnailDir = `${this.context.filesDir}/Video/.thumbnails`;
    try {
      console.error(`生成缩略图 `, 2222222222, thumbnailDir);
      const dirExists = await fs.access(thumbnailDir);
      console.error(`生成缩略图 `, 22222222222222222211111, thumbnailDir, dirExists);
      if (!dirExists) {
        await fs.mkdir(thumbnailDir);
      }
    } catch (e) {
      console.error(`生成缩略图 `, 3333333333, e);
      await fs.mkdir(thumbnailDir);
    }
    console.error(`生成缩略图 `, 3333333333);
    const tasks: Promise<void>[] = [];
    for (const videoUri of videos) {
      const videoFileName = (videoUri.split('/').pop() || '').split('.').shift();
      const thumbPath = `${thumbnailDir}/${videoFileName}.jpg`;
      console.error(`生成缩略图 `, videoFileName);
      let thumbExists = false;
      try {
        thumbExists = await fs.access(thumbPath);
      } catch {
        // 如果 access 抛出异常，视为不存在 创建他
        fs.mkdir(thumbPath)
      }
      try {
        const stat = fs.statSync(thumbPath);
        const fileSize = stat.size; // 单位：字节
        if (fileSize == 0) {
          tasks.push(this.generateThumbnail(videoUri, thumbPath));
        } else {
          this.thumbnailMap.set(videoUri, thumbPath);
          console.error(`生成缩略图 `, videoUri, thumbPath);
        }
      } catch(e) {
        console.error(`生成缩略图 失败 `,e);
      }
    }
    await Promise.all(tasks);
  }

  async generateThumbnail(videoUri: string, thumbPath: string): Promise<void> {
    let imageGenerator: media.AVImageGenerator | null = null;
    let file: fs.File | null = null;
    try {

      console.error(`生成缩略图 `, 'pp1111111');
      imageGenerator = await media.createAVImageGenerator();
      const videoPath = videoUri.replace('file://', '');
      file = fs.openSync(videoPath, fs.OpenMode.READ_ONLY);
      const fileStats = fs.statSync(videoPath);
      imageGenerator.fdSrc = {
        fd: file.fd,
        offset: 0,
        length: fileStats.size
      };
      console.error(`生成缩略图 `, 'pp22222222');
      const pixelMap = await imageGenerator.fetchFrameByTime(
        1000000,
        media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC,
        { width: 400, height: 400 }
      );
      console.error(`生成缩略图 `, 'pp33333333333');
      if (pixelMap) {
        const imagePacker = image.createImagePacker();
        const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 80 };
        const data = await imagePacker.packToData(pixelMap, packOpts);
        if (data) {
          const thumbFile = fs.openSync(thumbPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
          fs.writeSync(thumbFile.fd, data);
          fs.closeSync(thumbFile);
        }
        imagePacker.release();
        pixelMap.release();
      }

      this.thumbnailMap.set(videoUri, thumbPath);
      const stat = fs.statSync(thumbPath);
      const fileSize = stat.size; // 单位：字节
      //console.error(`生成缩略图 完成`,videoUri, thumbPath,fileSize);
    } catch (err) {
      console.error(`生成缩略图失败 ${videoUri}: ${err}`);
    } finally {
      if (imageGenerator) {
        imageGenerator.release();
      }
      if (file) {
        fs.closeSync(file);
      }
    }
  }

  build() {
    Column() {
      if (this.videoList.length === 0) {
        Blank();
        Text('暂无视频，请将视频放入沙箱目录')
          .fontSize(16)
          .fontColor('#999')
          .textAlign(TextAlign.Center);
        Blank();
      } else {
        Grid() {
          ForEach(this.videoList, (uri: string, idx?: number) => {
            GridItem() {
              Stack() {
                if (this.thumbnailMap.has(uri)) {
                  Image('file://' + this.thumbnailMap.get(uri))
                    .width('100%')
                    .aspectRatio(16 / 9)
                    .objectFit(ImageFit.Cover)
                } else {
                  Image($r('app.media.img_drone_location'))
                    .width('100%')
                    .aspectRatio(16 / 9)
                    .objectFit(ImageFit.Cover)
                }
                Image($r('app.media.icon_album'))
                  .width(48)
                  .height(48)
                  .opacity(0.8)
              }
              .onClick(() => {
                this.currentVideoUri = uri;
                this.showPlayer = true;
              })
              .borderRadius(8)
              .backgroundColor('#E0E0E0')
            }
          }, (uri: string, idx?: number) => idx?.toString() ?? uri)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .padding(12)
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .bindContentCover(this.showPlayer, this.VideoPlayerBuilder(), {
      modalTransition: ModalTransition.NONE,
      onDisappear: () => {
        this.currentVideoUri = '';
      }
    })
  }

  @Builder
  VideoPlayerBuilder() {
    Column() {
      Video({
        src: this.currentVideoUri,
        controller: new VideoController()
      })
        .width('100%')
        .height('50%')
        .objectFit(ImageFit.Contain)
        .controls(true)
      Text('点击空白区域关闭')
        .fontSize(14)
        .fontColor(Color.White)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.9)')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.showPlayer = false;
    })
  }

  aboutToReuse(params: Record<string, Object | null | undefined>): void {

  }
}