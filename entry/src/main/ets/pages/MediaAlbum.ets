// MediaAlbum.ets (API 12 规范，按日期分组显示图片/视频)
import fs from '@ohos.file.fs';
import router from '@ohos.router';
import { media } from '@kit.MediaKit';
import image from '@ohos.multimedia.image';

// ---------- 接口定义 ----------
interface ImageGroup {
  date: string;
  images: string[];
}

interface VideoGroup {
  date: string;
  videos: string[];
}

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

// 辅助函数：从文件路径获取日期字符串 (YYYY-MM-DD)
async function getFileDate(fileUri: string): Promise<string> {
  try {
    const filePath = fileUri.replace('file://', '');
    const stat = await fs.stat(filePath);
    const date = new Date(stat.mtime * 1000);
    console.log("文件时间", stat.mtime)
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  } catch {
    return '未知日期';
  }
}

// 图片网格组件（支持左右滑动预览）
@Component
struct ImageGallery {
  @Prop context: Context = getContext(this);
  @State imageGroups: ImageGroup[] = [];
  @State imageList: string[] = [];
  @State showPreview: boolean = false;
  @State currentImageIndex: number = 0;

  aboutToAppear(): void {
    this.loadImages();
  }

  async loadImages(): Promise<void> {
    const imageDir: string = `${getContext().filesDir}/Image`;
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
      const imageUris = fileNames
        .filter((name: string) => /\.(jpg|jpeg|png|gif)$/i.test(name))
        .map((name: string) => `file://${imageDir}/${name}`);

      if (imageUris.length === 0) {
        this.imageGroups = [];
        this.imageList = [];
        return;
      }

      const dateMap = new Map<string, string>();
      const datePromises = imageUris.map(async (uri) => {
        const date = await getFileDate(uri);
        dateMap.set(uri, date);
      });
      await Promise.all(datePromises);

      const groupMap = new Map<string, string[]>();
      imageUris.forEach((uri) => {
        const date = dateMap.get(uri) ?? '未知日期';
        if (!groupMap.has(date)) {
          groupMap.set(date, []);
        }
        groupMap.get(date)!.push(uri);
      });

      const groups: ImageGroup[] = [];
      groupMap.forEach((images, date) => {
        groups.push({ date, images });
      });
      groups.sort((a, b) => b.date.localeCompare(a.date));
      this.imageGroups = groups;
      this.imageList = groups.flatMap(g => g.images);
    } catch (err) {
      console.error(`读取图片目录失败: ${err}`);
    }
  }

  @Builder
  DateHeader(date: string) {
    Text(date)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(Color.White)
      .padding({ left: 16, top: 12, bottom: 4 })
      .textAlign(TextAlign.Center)
      .width('100%')
  }

  build() {
    Column() {
      if (this.imageGroups.length === 0) {
        Blank();
        Text('暂无图片，请将图片放入沙箱目录')
          .fontSize(16)
          .fontColor('#999')
          .textAlign(TextAlign.Center);
        Blank();
      } else {
        Scroll() {
          Column() {
            ForEach(this.imageGroups, (group: ImageGroup) => {
              Column() {
                this.DateHeader(group.date)
                Grid() {
                  ForEach(group.images, (uri: string, idx?: number) => {
                    GridItem() {
                      Image(uri)
                        .width('100%')
                        .aspectRatio(1)
                        .objectFit(ImageFit.Cover)
                        .onClick(() => {
                          const index = this.imageList.indexOf(uri);
                          if (index !== -1) {
                            this.currentImageIndex = index;
                            this.showPreview = true;
                          }
                        })
                    }
                    .borderRadius(8)
                  }, (uri: string, idx?: number) => idx?.toString() ?? uri)
                }
                .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
                .columnsGap(8)
                .rowsGap(8)
                .padding({ left: 12, right: 12, bottom: 12 })
                .width('100%')
              }.width('100%').height('auto')
            }, (group: ImageGroup) => group.date)
          }
          .width('100%')
          .height(this.imageGroups.length > 1 ? 'auto' : '100%')
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .bindContentCover(this.showPreview, this.ImagePreviewBuilder(), {
      modalTransition: ModalTransition.NONE,
      onDisappear: () => {
        this.showPreview = false;
      }
    })
  }

  @Builder
  ImagePreviewBuilder() {
    Column() {
      Swiper() {
        ForEach(this.imageList, (uri: string) => {
          Image(uri)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
        }, (uri: string) => uri)
      }
      .index(this.currentImageIndex)
      .indicator(false)
      .loop(false)
      .width('100%')
      .height('100%')
      .onChange((index: number) => {
        this.currentImageIndex = index;
      })

      Button('关闭')
        .margin({ bottom: 30 })
        .onClick(() => {
          this.showPreview = false;
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .justifyContent(FlexAlign.Center)
  }
}

// 视频网格组件（全屏预览时默认显示缩略图，点击播放后自动播放视频）
@Component
struct VideoGallery {
  @Prop context: Context = getContext(this);
  @State videoGroups: VideoGroup[] = [];
  @State videoList: string[] = [];
  @State thumbnailMap: Map<string, string> = new Map();
  @State showPlayer: boolean = false;
  @State currentVideoIndex: number = -1;
  @State isVideoPlaying: boolean = false;

  aboutToAppear(): void {
    this.context = getContext(this);
    this.loadVideos();
  }

  async loadVideos(): Promise<void> {
    const videoDir: string = `${getContext().filesDir}/Video`;
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
      const videoUris = fileNames
        .filter((name: string) => /\.(mp4|mkv|avi|mov)$/i.test(name))
        .map((name: string) => `file://${videoDir}/${name}`);

      if (videoUris.length === 0) {
        this.videoGroups = [];
        this.videoList = [];
        return;
      }

      const dateMap = new Map<string, string>();
      const datePromises = videoUris.map(async (uri) => {
        const date = await getFileDate(uri);
        dateMap.set(uri, date);
      });
      await Promise.all(datePromises);

      const groupMap = new Map<string, string[]>();
      videoUris.forEach((uri) => {
        const date = dateMap.get(uri) ?? '未知日期';
        if (!groupMap.has(date)) {
          groupMap.set(date, []);
        }
        groupMap.get(date)!.push(uri);
      });

      const groups: VideoGroup[] = [];
      groupMap.forEach((videos, date) => {
        groups.push({ date, videos });
      });
      groups.sort((a, b) => b.date.localeCompare(a.date));
      this.videoGroups = groups;
      this.videoList = groups.flatMap(g => g.videos);

      await this.generateThumbnails(videoUris);
    } catch (err) {
      console.error(`读取视频目录失败: ${err}`);
    }
  }

  async generateThumbnails(videos: string[]): Promise<void> {
    const thumbnailDir = `${this.context.filesDir}/Video/.thumbnails`;
    try {
      const dirExists = await fs.access(thumbnailDir);
      if (!dirExists) {
        await fs.mkdir(thumbnailDir, true);
      }
    } catch {
      await fs.mkdir(thumbnailDir, true);
    }

    const tasks: Promise<void>[] = [];
    for (const videoUri of videos) {
      const videoFileName = (videoUri.split('/').pop() || '').split('.').shift();
      const thumbPath = `${thumbnailDir}/${videoFileName}.jpg`;

      let needGenerate = false;
      try {
        const stat = fs.statSync(thumbPath);
        if (stat.size > 0) {
          this.thumbnailMap.set(videoUri, thumbPath);
        } else {
          needGenerate = true;
        }
      } catch {
        needGenerate = true;
      }

      if (needGenerate) {
        tasks.push(this.generateThumbnail(videoUri, thumbPath));
      }
    }
    await Promise.all(tasks);
  }

  async generateThumbnail(videoUri: string, thumbPath: string): Promise<void> {
    let imageGenerator: media.AVImageGenerator | null = null;
    let file: fs.File | null = null;
    try {
      imageGenerator = await media.createAVImageGenerator();
      const videoPath = videoUri.replace('file://', '');
      file = fs.openSync(videoPath, fs.OpenMode.READ_ONLY);
      const fileStats = fs.statSync(videoPath);
      imageGenerator.fdSrc = {
        fd: file.fd,
        offset: 0,
        length: fileStats.size
      };
      const pixelMap = await imageGenerator.fetchFrameByTime(
        1000000,
        media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC,
        { width: 400, height: 400 }
      );
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

  @Builder
  DateHeader(date: string) {
    Text(date)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(Color.White)
      .padding({ left: 16, top: 12, bottom: 4 })
      .textAlign(TextAlign.Center)
      .width('100%')
  }

  build() {
    Column() {
      if (this.videoGroups.length === 0) {
        Blank();
        Text('暂无视频，请将视频放入沙箱目录')
          .fontSize(16)
          .fontColor('#999')
          .textAlign(TextAlign.Center);
        Blank();
      } else {
        Scroll() {
          Column() {
            ForEach(this.videoGroups, (group: VideoGroup) => {
              this.DateHeader(group.date)
              Grid() {
                ForEach(group.videos, (uri: string, idx?: number) => {
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
                      const index = this.videoList.indexOf(uri);
                      if (index !== -1) {
                        this.currentVideoIndex = index;
                        this.isVideoPlaying = false;
                        this.showPlayer = true;
                      }
                    })
                    .borderRadius(8)
                    .backgroundColor('#E0E0E0')
                  }
                }, (uri: string, idx?: number) => idx?.toString() ?? uri)
              }
              .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
              .columnsGap(12)
              .rowsGap(12)
              .padding({ left: 12, right: 12, bottom: 12 })
              .width('100%')
            }, (group: VideoGroup) => group.date)
          }
          .width('100%')
          .height(this.VideoLineIsAuto() ? 'auto' : '100%')
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .bindContentCover(this.showPlayer, this.VideoPlayerBuilder(), {
      modalTransition: ModalTransition.NONE,
      onDisappear: () => {
        this.showPlayer = false;
        this.currentVideoIndex = -1;
        this.isVideoPlaying = false;
      }
    })
  }

  @Builder
  VideoPlayerBuilder() {
    Column() {
      Swiper() {
        ForEach(this.videoList, (uri: string, index: number) => {
          Stack() {
            if (index === this.currentVideoIndex) {
              if (this.isVideoPlaying) {
                Video({ src: uri, controller: new VideoController() })
                  .width('100%')
                  .height('100%')
                  .objectFit(ImageFit.Contain)
                  .controls(true)
                  .autoPlay(true)   // 关键修复：自动播放
              } else {
                Stack() {
                  if (this.thumbnailMap.has(uri)) {
                    Image('file://' + this.thumbnailMap.get(uri))
                      .width('100%')
                      .height('100%')
                      .objectFit(ImageFit.Contain)
                  } else {
                    Image($r('app.media.img_drone_location'))
                      .width('100%')
                      .height('100%')
                      .objectFit(ImageFit.Contain)
                  }
                  Image($r('app.media.icon_album'))
                    .width(64)
                    .height(64)
                    .opacity(0.9)
                    .onClick(() => {
                      this.isVideoPlaying = true;
                    })
                }
                .width('100%')
                .height('100%')

              }
            } else {
              if (this.thumbnailMap.has(uri)) {
                Image('file://' + this.thumbnailMap.get(uri))
                  .width('100%')
                  .height('100%')
                  .objectFit(ImageFit.Contain)
              } else {
                Image($r('app.media.img_drone_location'))
                  .width('100%')
                  .height('100%')
                  .objectFit(ImageFit.Contain)
              }
            }
          }
          .width('100%')
          .height('100%')
        }, (uri: string) => uri)
      }
      .index(this.currentVideoIndex)
      .indicator(false)
      .loop(false)
      .width('100%')
      .height('100%')
      .key(this.currentVideoIndex+'')
      .onChange((index: number) => {
        this.currentVideoIndex = index;
        this.isVideoPlaying = false;
      })

     /* Button('关闭')
        .margin({ top: 20 })
        .onClick(() => {
          this.showPlayer = false;
        })*/
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.9)')
    .justifyContent(FlexAlign.Center)
  }

  aboutToReuse(params: Record<string, Object | null | undefined>): void {
    // 预留钩子
  }

  VideoLineIsAuto(): boolean {
    let isAuto: boolean = false;
    if (this.videoGroups.length > 2) {
      isAuto = true;
    }
    if (this.videoGroups.length === 2) {
      if (this.videoGroups[0].videos.length > 5 || this.videoGroups[1].videos.length > 5) {
        isAuto = true;
      }
    }
    return isAuto;
  }
}

function updateRowsTemplate(length: number): string {
  return Array(length).fill('1fr').join(' ');
}