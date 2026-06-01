// MediaAlbum.ets (API 12 规范，支持图片/视频多选、分享、删除)
import fs from '@ohos.file.fs';
import router from '@ohos.router';
import { media } from '@kit.MediaKit';
import image from '@ohos.multimedia.image';
import { systemShare } from '@kit.ShareKit';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import want from '@ohos.app.ability.Want';

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
  @State isSelectMode: boolean = false;
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

  toggleSelectMode(): void {
    this.isSelectMode = !this.isSelectMode;
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
              if (this.isSelectMode) {
                this.isSelectMode = false;
              }
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
              if (this.isSelectMode) {
                this.isSelectMode = false;
              }
            })
        }
        .id('tabsContainer')
        .height('100%')
        .alignItems(VerticalAlign.Bottom)
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center },
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
        })

        Text(this.isSelectMode ? '完成' : '选择')
          .fontSize(16)
          .fontColor(Color.White)
          .padding({ left: 12, right: 12 })
          .height('100%')
          .textAlign(TextAlign.Center)
          .alignRules({
            right: { anchor: '__container__', align: HorizontalAlign.End },
            center: { anchor: '__container__', align: VerticalAlign.Center }
          })
          .margin({ right: 20 })
          .onClick(() => {
            this.toggleSelectMode();
          })
      }
      .width('100%')
      .height(44)
      .backgroundColor('#2F2F2F')

      Swiper(this.swiperController) {
        ImageGallery({ context: this.context, isSelectMode: $isSelectMode })
        VideoGallery({ context: this.context, isSelectMode: $isSelectMode })
      }
      .index(this.currentTabIndex)
      .indicator(false)
      .loop(false)
      .width('100%')
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentTabIndex = index;
        if (this.isSelectMode) {
          this.isSelectMode = false;
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ff6d6d6d')
  }
}

async function getFileDate(fileUri: string): Promise<string> {
  try {
    const filePath = fileUri.replace('file://', '');
    const stat = await fs.stat(filePath);
    const date = new Date(stat.mtime * 1000);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  } catch {
    return '未知日期';
  }
}

@Component
struct ImageGallery {
  @Prop context: Context = getContext(this);
  @Link isSelectMode: boolean;
  @State imageGroups: ImageGroup[] = [];
  @State imageList: string[] = [];
  @State selectedSet: Set<string> = new Set();
  @State showPreview: boolean = false;
  @State currentImageIndex: number = 0;

  aboutToAppear(): void {
    this.loadImages();
  }

  async loadImages(): Promise<void> {
    // 强制清空，确保 UI 重建
    this.imageGroups = [];
    this.imageList = [];

    const imageDir: string = `${getContext(this).filesDir}/Image`;
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
      const imageUris: string[] = fileNames
        .filter((name: string) => /\.(jpg|jpeg|png|gif)$/i.test(name))
        .map((name: string) => `file://${imageDir}/${name}`);
      if (imageUris.length === 0) {
        return;
      }
      const dateMap: Map<string, string> = new Map();
      await Promise.all(imageUris.map(async (uri: string) => {
        const date: string = await getFileDate(uri);
        dateMap.set(uri, date);
      }));
      const groupMap: Map<string, string[]> = new Map();
      imageUris.forEach((uri: string) => {
        const date: string = dateMap.get(uri) ?? '未知日期';
        if (!groupMap.has(date)) {
          groupMap.set(date, []);
        }
        groupMap.get(date)!.push(uri);
      });
      const groups: ImageGroup[] = [];
      groupMap.forEach((images: string[], date: string) => {
        groups.push({ date, images });
      });
      groups.sort((a: ImageGroup, b: ImageGroup) => b.date.localeCompare(a.date));
      this.imageGroups = groups;
      this.imageList = groups.flatMap((g: ImageGroup) => g.images);
      this.clearSelection();
    } catch (err) {
      console.error(`读取图片目录失败: ${err}`);
    }
  }

  clearSelection(): void {
    this.selectedSet.clear();
  }

  toggleSelection(uri: string): void {
    if (this.selectedSet.has(uri)) {
      this.selectedSet.delete(uri);
    } else {
      this.selectedSet.add(uri);
    }
    if (this.selectedSet.size === 0 && this.isSelectMode) {
      this.isSelectMode = false;
    }
  }

  handleLongPress(uri: string): void {
    if (!this.isSelectMode) {
      this.isSelectMode = true;
      this.toggleSelection(uri);
    } else {
      this.toggleSelection(uri);
    }
  }

  async deleteSelected(): Promise<void> {
    if (this.selectedSet.size === 0) return;
    const deletePromises: Promise<void>[] = [];
    for (const uri of this.selectedSet) {
      const filePath: string = uri.replace('file://', '');
      deletePromises.push(fs.unlink(filePath).catch((err: Error) => {
        console.error(`删除文件失败 ${filePath}: ${err}`);
      }));
    }
    await Promise.all(deletePromises).then(Awaited=>{
       this.loadImages();
    });
    // 等待文件系统同步，避免立即读取到旧数据
    this.isSelectMode = false;
    this.clearSelection();
  }

  async shareSelected(): Promise<void> {
    if (this.selectedSet.size === 0) {
      return;
    }
    try {
      const records: systemShare.SharedRecord[] = [];
      for (const uri of this.selectedSet) {
        records.push({ utd: 'public.image', uri: uri });
      }
      const sharedData: systemShare.SharedData = new systemShare.SharedData(records[0]);
      for (let i = 1; i < records.length; i++) {
        sharedData.addRecord(records[i]);
      }
      const shareController: systemShare.ShareController = new systemShare.ShareController(sharedData);
      const uiContext: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      await shareController.show(uiContext, { selectionMode: systemShare.SelectionMode.BATCH });
    } catch (err) {
      const firstUri: string = Array.from(this.selectedSet)[0];
      const shareWant: Want = { action: 'ohos.want.action.sendData', uri: firstUri, type: 'image/*' };
      const uiContext: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      await uiContext.startAbility(shareWant);
    }
  }

  @Builder
  DateHeader(date: string) {
    Text(date)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(Color.White)
      .padding({ left: 16, top: 12, bottom: 4 })
      .textAlign(TextAlign.Center)  // 水平居中
      .width('100%')
  }

  @Builder
  BottomActionBar() {
    if (this.isSelectMode && this.selectedSet.size > 0) {
      Row() {
        Button('分享')
          .fontSize(16)
          .backgroundColor('#007BFF')
          .borderRadius(20)
          .height(40)
          .layoutWeight(1)
          .margin({ left: 16, right: 8 })
          .onClick(() => this.shareSelected())
        Button('删除')
          .fontSize(16)
          .backgroundColor('#DC3545')
          .borderRadius(20)
          .height(40)
          .layoutWeight(1)
          .margin({ left: 8, right: 16 })
          .onClick(() => this.deleteSelected())
      }
      .width('100%')
      .height(60)
      .backgroundColor('#1A1A1A')
      .padding({ top: 10, bottom: 10 })
    }
  }

  build() {
    Column() {
      if (this.imageGroups.length === 0) {
        Blank();
        Text('暂无图片，请将图片放入沙箱目录').fontSize(16).fontColor('#999');
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
                      Stack() {
                        Image(uri).width('100%').aspectRatio(1).objectFit(ImageFit.Cover)
                        if (this.isSelectMode) {
                          Image(this.selectedSet.has(uri) ?
                            $r('app.media.icon_album') : $r('app.media.img_drone_location'))
                            .width(28).height(28)
                            .position({ x: '70%', y: '5%' })
                            .onClick(() => this.toggleSelection(uri))
                        }
                      }
                      .borderRadius(8)
                      .onClick(() => {
                        if (this.isSelectMode) {
                          this.toggleSelection(uri);
                        } else {
                          const index: number = this.imageList.indexOf(uri);
                          if (index !== -1) {
                            this.currentImageIndex = index;
                            this.showPreview = true;
                          }
                        }
                      })
                      .gesture(                  // ✅ 复选框也支持长按，保持行为一致
                        LongPressGesture({ duration: 300 })
                          .onAction(() => this.handleLongPress(uri))
                      )
                    }
                  }, (uri: string, idx?: number) => (idx !== undefined ? idx.toString() : uri))
                }
                .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
                .columnsGap(8)
                .rowsGap(8)
                .padding({ left: 12, right: 12, bottom: 12 })
                .width('100%')
              }.width('100%')
            }, (group: ImageGroup) => group.date)
          }
          .width('100%')
          .height(this.imageGroups.length > 1 ? 'auto' : '100%') // ✅ 保留原条件高度
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      this.BottomActionBar()
    }
    .width('100%').height('100%')
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
          Image(uri).width('100%').height('100%').objectFit(ImageFit.Contain)
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

      Button('关闭').margin({ bottom: 30 }).onClick(() => {
        this.showPreview = false;
      })
    }
    .width('100%').height('100%').backgroundColor(Color.Black).justifyContent(FlexAlign.Center)
  }
}

@Component
struct VideoGallery {
  @Prop context: Context = getContext(this);
  @Link isSelectMode: boolean;
  @State videoGroups: VideoGroup[] = [];
  @State videoList: string[] = [];
  @State selectedSet: Set<string> = new Set();
  @State thumbnailMap: Map<string, string> = new Map();
  @State showPlayer: boolean = false;
  @State currentVideoIndex: number = -1;
  @State isVideoPlaying: boolean = false;

  aboutToAppear(): void {
    this.context = getContext(this);
    this.loadVideos();
  }

  async loadVideos(): Promise<void> {
    const videoDir: string = `${getContext(this).filesDir}/Video`;
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
      const videoUris: string[] = fileNames
        .filter((name: string) => /\.(mp4|mkv|avi|mov)$/i.test(name))
        .map((name: string) => `file://${videoDir}/${name}`);
      if (videoUris.length === 0) {
        this.videoGroups = [];
        this.videoList = [];
        return;
      }
      const dateMap: Map<string, string> = new Map();
      await Promise.all(videoUris.map(async (uri: string) => {
        const date: string = await getFileDate(uri);
        dateMap.set(uri, date);
      }));
      const groupMap: Map<string, string[]> = new Map();
      videoUris.forEach((uri: string) => {
        const date: string = dateMap.get(uri) ?? '未知日期';
        if (!groupMap.has(date)) {
          groupMap.set(date, []);
        }
        groupMap.get(date)!.push(uri);
      });
      const groups: VideoGroup[] = [];
      groupMap.forEach((videos: string[], date: string) => {
        groups.push({ date, videos });
      });
      groups.sort((a: VideoGroup, b: VideoGroup) => b.date.localeCompare(a.date));
      this.videoGroups = groups;
      this.videoList = groups.flatMap((g: VideoGroup) => g.videos);
      await this.generateThumbnails(videoUris);
      this.clearSelection();
    } catch (err) {
      console.error(`读取视频目录失败: ${err}`);
    }
  }

  async generateThumbnails(videos: string[]): Promise<void> {
    const thumbnailDir: string = `${this.context.filesDir}/Video/.thumbnails`;
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
      const videoFileName: string | undefined = (videoUri.split('/').pop() || '').split('.').shift();
      const thumbPath: string = `${thumbnailDir}/${videoFileName}.jpg`;
      let needGenerate: boolean = false;
      try {
        const stat: fs.Stat = fs.statSync(thumbPath);
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
      const videoPath: string = videoUri.replace('file://', '');
      file = fs.openSync(videoPath, fs.OpenMode.READ_ONLY);
      const fileStats: fs.Stat = fs.statSync(videoPath);
      imageGenerator.fdSrc = { fd: file.fd, offset: 0, length: fileStats.size };
      const pixelMap: image.PixelMap | undefined = await imageGenerator.fetchFrameByTime(
        1000000, media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC, { width: 400, height: 400 }
      );
      if (pixelMap) {
        const imagePacker: image.ImagePacker = image.createImagePacker();
        const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 80 };
        const data: ArrayBuffer | undefined = await imagePacker.packToData(pixelMap, packOpts);
        if (data) {
          const thumbFile: fs.File = fs.openSync(thumbPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
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

  clearSelection(): void {
    this.selectedSet.clear();
  }

  toggleSelection(uri: string): void {
    if (this.selectedSet.has(uri)) {
      this.selectedSet.delete(uri);
    } else {
      this.selectedSet.add(uri);
    }
    if (this.selectedSet.size === 0 && this.isSelectMode) {
      this.isSelectMode = false;
    }
  }

  handleLongPress(uri: string): void {
    if (!this.isSelectMode) {
      this.isSelectMode = true;
      this.toggleSelection(uri);
    } else {
      this.toggleSelection(uri);
    }
  }

  async deleteSelected(): Promise<void> {
    if (this.selectedSet.size === 0) {
      return;
    }
    const deletePromises: Promise<void>[] = [];
    for (const uri of this.selectedSet) {
      const filePath: string = uri.replace('file://', '');
      deletePromises.push(fs.unlink(filePath).catch((err: Error) => console.error(`删除视频失败 ${filePath}: ${err}`)));
      const videoFileName: string | undefined = (uri.split('/').pop() || '').split('.').shift();
      const thumbPath: string = `${this.context.filesDir}/Video/.thumbnails/${videoFileName}.jpg`;
      try {
        await fs.unlink(thumbPath);
      } catch {
      }
    }
    await Promise.all(deletePromises).then(Awaited=>{
      this.thumbnailMap.clear();
       this.loadVideos();
    });


    this.isSelectMode = false;
    this.clearSelection();
  }

  async shareSelected(): Promise<void> {
    if (this.selectedSet.size === 0) {
      return;
    }
    try {
      const records: systemShare.SharedRecord[] = [];
      for (const uri of this.selectedSet) {
        records.push({ utd: 'public.video', uri: uri });
      }
      const sharedData: systemShare.SharedData = new systemShare.SharedData(records[0]);
      for (let i = 1; i < records.length; i++) {
        sharedData.addRecord(records[i]);
      }
      const shareController: systemShare.ShareController = new systemShare.ShareController(sharedData);
      const uiContext: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      await shareController.show(uiContext, { selectionMode: systemShare.SelectionMode.BATCH });
    } catch (err) {
      const firstUri: string = Array.from(this.selectedSet)[0];
      const shareWant: Want = { action: 'ohos.want.action.sendData', uri: firstUri, type: 'video/*' };
      const uiContext: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      await uiContext.startAbility(shareWant);
    }
  }

  // ✅ 保留原有的 VideoLineIsAuto 函数
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

  @Builder
  DateHeader(date: string) {
    Text(date)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(Color.White)
      .padding({ left: 16, top: 12, bottom: 4 })
      .textAlign(TextAlign.Center)  // 水平居中
      .width('100%')
  }

  @Builder
  BottomActionBar() {
    if (this.isSelectMode && this.selectedSet.size > 0) {
      Row() {
        Button('分享')
          .fontSize(16)
          .backgroundColor('#007BFF')
          .borderRadius(20)
          .height(40)
          .layoutWeight(1)
          .margin({ left: 16, right: 8 })
          .onClick(() => this.shareSelected())
        Button('删除')
          .fontSize(16)
          .backgroundColor('#DC3545')
          .borderRadius(20)
          .height(40)
          .layoutWeight(1)
          .margin({ left: 8, right: 16 })
          .onClick(() => this.deleteSelected())
      }
      .width('100%').height(60).backgroundColor('#1A1A1A').padding({ top: 10, bottom: 10 })
    }
  }

  build() {
    Column() {
      if (this.videoGroups.length === 0) {
        Blank();
        Text('暂无视频，请将视频放入沙箱目录').fontSize(16).fontColor('#999');
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
                          .width('100%').aspectRatio(16 / 9).objectFit(ImageFit.Cover)
                      } else {
                        Image($r('app.media.img_drone_location'))
                          .width('100%').aspectRatio(16 / 9).objectFit(ImageFit.Cover)
                      }
                      if (!this.isSelectMode) {
                        Image($r('app.media.ic_media_video_play')).width(48).height(48).opacity(0.8)
                      }
                      if (this.isSelectMode) {
                        Image(this.selectedSet.has(uri) ?
                          $r('app.media.icon_album') : $r('app.media.img_drone_location'))
                          .width(28).height(28)
                          .position({ x: '85%', y: '5%' })
                          .onClick(() => this.toggleSelection(uri))
                      }
                    }
                    .borderRadius(8).backgroundColor('#E0E0E0')
                    .onClick(() => {
                      if (this.isSelectMode) {
                        this.toggleSelection(uri);
                      } else {
                        const index: number = this.videoList.indexOf(uri);
                        if (index !== -1) {
                          this.currentVideoIndex = index;
                          this.isVideoPlaying = false;
                          this.showPlayer = true;
                        }
                      }
                    })
                    .gesture(                  // ✅ 复选框也支持长按，保持行为一致
                      LongPressGesture({ duration: 300 })
                        .onAction(() => this.handleLongPress(uri))
                    )
                  }
                }, (uri: string, idx?: number) => (idx !== undefined ? idx.toString() : uri))
              }
              .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
              .columnsGap(12)
              .rowsGap(12)
              .padding({ left: 12, right: 12, bottom: 12 })
              .width('100%')
            }, (group: VideoGroup) => group.date)
          }
          .width('100%')
          .height(this.VideoLineIsAuto() ? 'auto' : '100%') // ✅ 保留原条件高度
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      this.BottomActionBar()
    }
    .width('100%').height('100%')
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
                  .autoPlay(true)
              } else {
                Stack() {
                  if (this.thumbnailMap.has(uri)) {
                    Image('file://' + this.thumbnailMap.get(uri))
                      .width('100%').height('100%').objectFit(ImageFit.Contain)
                  } else {
                    Image($r('app.media.img_drone_location'))
                      .width('100%').height('100%').objectFit(ImageFit.Contain)
                  }
                  Image($r('app.media.ic_media_video_play')).width(64).height(64).opacity(0.9)
                    .onClick(() => {
                      this.isVideoPlaying = true;
                    })
                }.width('100%').height('100%')
              }
            } else {
              if (this.thumbnailMap.has(uri)) {
                Image('file://' + this.thumbnailMap.get(uri))
                  .width('100%').height('100%').objectFit(ImageFit.Contain)
              } else {
                Image($r('app.media.img_drone_location'))
                  .width('100%').height('100%').objectFit(ImageFit.Contain)
              }
            }
          }
          .width('100%').height('100%')
        }, (uri: string) => uri)
      }
      .index(this.currentVideoIndex)
      .indicator(false)
      .loop(false)
      .width('100%')
      .height('100%')
      .onChange((index: number) => {
        this.currentVideoIndex = index;
        this.isVideoPlaying = false;
      })
    }
    .width('100%').height('100%')
    .backgroundColor('rgba(0,0,0,0.9)')
    .justifyContent(FlexAlign.Center)
  }
}