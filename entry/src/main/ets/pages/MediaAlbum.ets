// MediaAlbum.ets
import fs from '@ohos.file.fs';

@Entry
@Component
struct MediaAlbum {
  @State currentTabIndex: number = 0;
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
      await fs.access(dirPath);
    } catch (err) {
      await fs.mkdir(dirPath);
    }
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.Start, index: this.currentTabIndex }) {
        TabContent() {
          ImageGallery({ context: this.context })
        }
        .tabBar(this.TabBuilder('图片', 0)).background('#ff6d6d6d')

        TabContent() {
          VideoGallery({ context: this.context })
        }
        .tabBar(this.TabBuilder('视频', 1)).background('#ff6d6d6d')
      }
      .vertical(false)
      .scrollable(true)
      .width('auto')                 // 👈 让 Tabs 宽度由内容决定
      .barHeight(40)
      .barMode(BarMode.Scrollable)   // 👈 关键：让标签项根据内容宽度排列，不强制均分
      .backgroundColor('#2F2F2F')
      .onChange((index: number) => {
        this.currentTabIndex = index;
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TabBuilder(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(18)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTabIndex === index ? Color.White : '#ffa49b9b')
        .margin({ bottom: 8 })
      Divider()
        .width('50%')
        .height(2)
        .backgroundColor(this.currentTabIndex === index ?  Color.White : 'transparent')
        .margin({ top: 0 })
    }
    .width('200')
    .height('100%')
    .justifyContent(FlexAlign.End)
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
    try {
      const isExistence: boolean = await fs.access(imageDir);
      if (!isExistence) {
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
      if (this.imageList.length == 0) {
        Blank()
        Text('暂无图片，请将图片放入沙箱目录')
          .fontSize(16)
          .fontColor('#999')
          .textAlign(TextAlign.Center)
        Blank()
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
      onDisappear: () => { this.previewImageUri = ''; }
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

// 视频网格组件
@Component
struct VideoGallery {
  @Prop context: Context = getContext(this);
  @State videoList: string[] = [];
  @State showPlayer: boolean = false;
  @State currentVideoUri: string = '';

  aboutToAppear(): void {
    this.loadVideos();
  }

  async loadVideos(): Promise<void> {
    const videoDir: string = `${getContext().filesDir}/Video`;
    try {
      const isExistence: boolean = await fs.access(videoDir);
      if (!isExistence) {
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
    } catch (err) {
      console.error(`读取视频目录失败: ${err}`);
    }
  }

  build() {
    Column() {
      if (this.videoList.length == 0) {
        Blank()
        Text('暂无视频，请将视频放入沙箱目录')
          .fontSize(16)
          .fontColor('#999')
          .textAlign(TextAlign.Center)
        Blank()
      } else {
        Grid() {
          ForEach(this.videoList, (uri: string, idx?: number) => {
            GridItem() {
              Stack() {
                // 使用系统默认图标，建议替换为实际封面图或缩略图
                Image($r('app.media.img_drone_location'))
                  .width('100%')
                  .aspectRatio(16 / 9)
                  .objectFit(ImageFit.Cover)
                Image($r('app.media.img_drone_location'))
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
        .columnsTemplate('1fr 1fr')
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
}