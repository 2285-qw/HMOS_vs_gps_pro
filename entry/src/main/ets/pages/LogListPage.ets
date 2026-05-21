import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { LogFileInfo, LogManager } from '../Log/LogManager';


@Entry
@Component
struct LogListPage {
  // 日志文件列表数据源
  @State logFiles: LogFileInfo[] = [];
  // 加载状态标志
  @State isLoading: boolean = true;

  // 页面显示时自动加载日志列表
  async aboutToAppear() {
    await this.loadLogList();
  }

  // 加载日志列表的方法
  async loadLogList() {
    this.isLoading = true;
    try {
      // 从LogManager获取已排序的日志文件列表
      this.logFiles = await LogManager.getInstance().getLogFileList();
    } catch (error) {
      console.error('加载日志列表失败:', JSON.stringify(error));
      promptAction.showToast({
        message: '加载日志列表失败'
      });
    } finally {
      this.isLoading = false;
    }
  }

  // 格式化文件大小（字节转易读格式）
  formatFileSize(size: number): string {
    if (size < 1024) {
      return `${size} B`;
    } else if (size < 1024 * 1024) {
      return `${(size / 1024).toFixed(1)} KB`;
    } else {
      return `${(size / (1024 * 1024)).toFixed(1)} MB`;
    }
  }

  // 格式化日期（显示更友好的格式）
  formatDate(dateStr: string): string {
    // 文件名格式为 "2026-05-15.log"
    const fileName = dateStr.replace('.log', '');
    const parts = fileName.split('-');
    if (parts.length === 3) {
      return `${parts[0]}年${parts[1]}月${parts[2]}日`;
    }
    return dateStr;
  }

  // 点击日志文件时的分享功能
  async shareLogFile(logFile: LogFileInfo) {
    try {
      // 调用LogManager的分享方法（下面第2节会实现）
      const result = await LogManager.getInstance().shareLogFile(logFile.name);
     /* if (result) {
        promptAction.showToast({
          message: `已打开分享面板，请选择${result}分享`
        });
      }*/
    } catch (error) {
      console.error('分享失败:', JSON.stringify(error));
      promptAction.showToast({
        message: '分享失败，请重试'
      });
    }
  }

  build() {
    Column() {
      // 标题栏
      this.buildHeader();

      // 主体内容区（列表或空状态）
      if (this.isLoading) {
        // 加载中
        this.buildLoadingView();
      } else if (this.logFiles.length === 0) {
        // 空状态：没有日志文件
        this.buildEmptyView();
      } else {
        // 日志列表
        this.buildLogList();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // 标题栏构建
  @Builder
  buildHeader() {
    Row() {
      // 返回按钮
      Image($r('app.media.ic_back'))
        .width(24)
        .height(24)
        .margin({ left: 16 })
        .onClick(() => {
          router.back();
        })

      Text('日志列表')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 刷新按钮
   /*   Image($r('app.media.ic_refresh'))
        .width(24)
        .height(24)
        .margin({ right: 16 })
        .onClick(() => {
          this.loadLogList();
        })*/
    }
    .width('100%')
    .height(56)
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.SpaceBetween)
  }

  // 日志列表构建
  @Builder
  buildLogList() {
    List({ space: 12 }) {
      ForEach(this.logFiles, (logFile: LogFileInfo, index: number) => {
        ListItem() {
          // 日志文件卡片
          this.buildLogCard(logFile)
        }
        .onClick(() => {
          this.shareLogFile(logFile);
        }).gesture(
          LongPressGesture({ duration: 300 })
            .onAction(() => {
              // 点击 -> 查看日志内容
              router.pushUrl({
                url: 'pages/LogDetailPage',
                params: {
                  filePath: logFile.path,
                  fileName: logFile.name
                }
              });
            })
        )
      }, (logFile: LogFileInfo, index: number) => logFile.name)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .scrollBar(BarState.Auto)
  }

  // 单个日志卡片构建
  @Builder
  buildLogCard(logFile: LogFileInfo) {
    Row() {
      // 左侧图标区
      Column() {
      /*  Image($r('app.media.img_drone_location'))
          .width(40)
          .height(40)
          .margin({ bottom: 4 })*/

        Text('LOG')
          .fontSize(10)
          .fontColor('#999999')
      }
      .width(60)
      .alignItems(HorizontalAlign.Center)

      // 中间信息区
      Column() {
        Text(logFile.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ bottom: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text(`大小：${this.formatFileSize(logFile.size)}`)
            .fontSize(12)
            .fontColor('#666666')
          Blank()
        /*  Text(`修改：${logFile.lastModifiedStr}`)
            .fontSize(12)
            .fontColor('#666666')*/
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧操作图标（分享按钮）
      Image($r('app.media.ic_logfile_share'))
        .width(24)
        .height(24)
        .margin({ left: 8 })
        .opacity(0.6)
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })
  }

  // 加载视图
  @Builder
  buildLoadingView() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color('#007DFF')
      Text('加载中...')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 12 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // 空状态视图
  @Builder
  buildEmptyView() {
    Column() {
     /* Image($r('app.media.ic_empty_log'))
        .width(120)
        .height(120)
        .opacity(0.5)*/
      Text('暂无日志文件')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 16 })
      Text('运行应用后会在此处显示日志记录')
        .fontSize(12)
        .fontColor('#CCCCCC')
        .margin({ top: 8 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}