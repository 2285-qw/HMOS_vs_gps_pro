// MediaAlbum.ets
import fs from '@ohos.file.fs';
import router from '@ohos.router';

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
      await fs.access(dirPath);
    } catch (err) {
      await fs.mkdir(dirPath);
    }
  }

  build() {
    Column() {
      // 顶部栏：使用 RelativeContainer 实现左对齐 + 居中标签
      RelativeContainer() {
        // 返回按钮
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
          }).margin({left:20})

/*        // 相册标题
        Text('相册')
          .id('albumTitle')
          .fontSize(20)
          .fontColor(Color.White)
          .margin({ left: 8 })
          .alignRules({
            left: { anchor: 'backBtn', align: HorizontalAlign.End },
            center: { anchor: 'backBtn', align: VerticalAlign.Center }
          })*/

        // 标签容器（图片/视频），水平居中于整个容器
        Row() {
          Text('图片')
            .fontSize(18)
            .fontWeight(this.currentTabIndex === 0 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentTabIndex === 0 ? Color.White : '#ffa49b9b')
            .padding({ left: 12, right: 12, bottom: 6 })
            .borderWidth({ bottom: 2  })
            .borderColor({ bottom:this.currentTabIndex === 0 ? Color.White :Color.Transparent })
            .onClick(() => {
              this.currentTabIndex = 0;
              this.swiperController.changeIndex(0);
            })

          Text('视频')
            .fontSize(18)
            .fontWeight(this.currentTabIndex === 1 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentTabIndex === 1 ? Color.White : '#ffa49b9b')
            .padding({ left: 12, right: 12, bottom: 6 })
            .borderWidth({ bottom:2 })
            .borderColor({ bottom:this.currentTabIndex === 1 ? Color.White :Color.Transparent})
            .onClick(() => {
              this.currentTabIndex = 1;
              this.swiperController.changeIndex(1);
            })
        }
        .id('tabsContainer')
        .height('100%')
        .alignItems(VerticalAlign.Bottom)   // 让文字底部对齐，下划线贴近底部
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center }, // 注意：水平居中用
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
        })
      }
      .width('100%')
      .height(40)
      .backgroundColor('#2F2F2F')
      // 滑动切换区域
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

// 图片网格组件（保持不变）
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
      await fs.access(imageDir);
    } catch {
      await fs.mkdir(imageDir);
    }
    try {
      const fileNames: string[] = await fs.listFile(imageDir);
      const images: string[] = fileNames
        .filter((fileName: string) => /\.(jpg|jpeg|png|gif)$/i.test(fileName))
        .map((fileName: string) => `file://${imageDir}/${fileName}`);
      this.imageList = images;
    } catch (err) {
      console.error(`读取图片目录失败: ${err}`);
    }
  }

  build() {
    Column() {
      if (this.imageList.length === 0) {
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

// 视频网格组件（保持不变）
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
      await fs.access(videoDir);
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
      if (this.videoList.length === 0) {
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
                Image($r('app.media.img_drone_location'))
                  .width('100%')
                  .aspectRatio(16 / 9)
                  .objectFit(ImageFit.Cover)
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
}