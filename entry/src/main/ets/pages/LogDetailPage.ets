// pages/LogDetailPage.ets
import { router } from '@kit.ArkUI';
import fs from '@ohos.file.fs';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { LogManager } from '../Log/LogManager';

@Entry
@Component
struct LogDetailPage {
  // 接收路由参数
  private filePath: string = '';
  private fileName: string = '';
  // 日志内容
  @State logContent: string = '';
  @State isLoading: boolean = true;
  @State loadError: string = '';
  // 分页/截取相关
  private readonly MAX_DISPLAY_LINES = 2000; // 最多显示2000行
  private readonly MAX_FILE_SIZE = 2 * 1024 * 1024; // 超过2MB仅读取尾部

  aboutToAppear() {
    // 获取路由传递的参数
    const params = router.getParams() as Record<string, string>;
    if (params && params.filePath) {
      this.filePath = params.filePath;
      this.fileName = params.fileName || this.filePath.split('/').pop() || '日志文件';
      this.loadLogContent();
    } else {
      this.loadError = '未指定文件路径';
      this.isLoading = false;
    }
  }

  async loadLogContent() {
    this.isLoading = true;
    try {
      // 检查文件是否存在
      if (!fs.accessSync(this.filePath)) {
        throw new Error('文件不存在');
      }

      const stat = fs.statSync(this.filePath);
      const fileSize = stat.size;

      // 策略：文件较小 -> 全量读取；文件较大 -> 读取尾部
      let content = '';
      if (fileSize <= this.MAX_FILE_SIZE) {
        // 全量读取
        content = await this.readFullFile();
      } else {
        // 只读尾部（最后2MB）
        content = await this.readTailFile();
        content = `[文件过大，仅显示最后部分内容]\n\n${content}`;
      }

      // 可选：限制行数
      const lines = content.split('\n');
      if (lines.length > this.MAX_DISPLAY_LINES) {
        const tailLines = lines.slice(-this.MAX_DISPLAY_LINES);
        content = `[日志超过${this.MAX_DISPLAY_LINES}行，仅显示最后部分]\n\n${tailLines.join('\n')}`;
      }

      this.logContent = content || '（文件为空）';
    } catch (err) {
      console.error('读取日志失败', JSON.stringify(err));
      this.loadError = `读取失败：${(err as BusinessError).message}`;
    } finally {
      this.isLoading = false;
    }
  }

  // 全量读取
  async readFullFile(): Promise<string> {
    const file = fs.openSync(this.filePath, fs.OpenMode.READ_ONLY);
    const stat = fs.statSync(this.filePath);
    const buffer = new ArrayBuffer(stat.size);
    fs.readSync(file.fd, buffer);
    fs.closeSync(file);
    const decoder = new util.TextDecoder('utf-8');
    return decoder.decode(new Uint8Array(buffer));
  }

  // 只读尾部（最后 2MB）
  async readTailFile(): Promise<string> {
    const file = fs.openSync(this.filePath, fs.OpenMode.READ_ONLY);
    const stat = fs.statSync(this.filePath);
    const tailSize = Math.min(stat.size, this.MAX_FILE_SIZE);
    const buffer = new ArrayBuffer(tailSize);
    // 从文件末尾向前读
    fs.readSync(file.fd, buffer, { offset: stat.size - tailSize });
    fs.closeSync(file);
    const decoder = new util.TextDecoder('utf-8');
    return decoder.decode(new Uint8Array(buffer));
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text(this.fileName)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        // 可以添加分享按钮，复用之前的分享逻辑
        Image($r('app.media.ic_logfile_share'))
          .width(24)
          .height(24)
          .onClick(() => this.shareCurrentLog())
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      // 内容区
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
          Text('加载中...').margin({ top: 12 })
        }.layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.loadError) {
        Column() {
          Text(this.loadError).fontColor('#FF0000').fontSize(14)
          Button('重试').margin({ top: 20 }).onClick(() => this.loadLogContent())
        }.layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        // 可滚动文本框
        Scroll() {
          Column(){
            Text(this.logContent)
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor('#333')
              .width('100%')
              .padding(16)
              .textAlign(TextAlign.JUSTIFY)
          }.height('100%')
        }
        .scrollBar(BarState.Auto)
        .layoutWeight(1)
        .backgroundColor('#F8F8F8')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  async shareCurrentLog() {
    // 调用之前 LogManager 中的分享方法
    // const LogManager = (await import('../common/LogManager')).LogManager;
    LogManager.getInstance().shareLogFile(this.filePath);
  }
}