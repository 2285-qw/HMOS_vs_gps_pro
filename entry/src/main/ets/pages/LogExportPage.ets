// LogExportPage.ets
import { Logger } from '../Log/Logger';
import {LogUtils} from '../Log/LogUtils';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct LogExportPage {
  @State exportStatus: string = '准备导出';
  @State exportPath: string = '';
  @State isLoading: boolean = false;

  private logger = new Logger('LogExportPage');

  build() {
    Column() {
      Text('日志管理')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 40 })

      // 导出日志按钮
      Button('导出日志')
        .width('80%')
        .height(50)
        .fontSize(18)
        .backgroundColor('#007DFF')
        .onClick(() => {
          this.exportLogs();
        })
      //  .disabled(this.isLoading)

      // 状态显示
      Text(this.exportStatus)
        .fontSize(16)
        .margin({ top: 20 })
        .textAlign(TextAlign.Center)

      // 显示导出路径
      if (this.exportPath) {
        Text(`导出路径: ${this.exportPath}`)
          .fontSize(14)
          .margin({ top: 10 })
          .fontColor('#666')
          .textAlign(TextAlign.Center)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      // 加载指示器
      if (this.isLoading) {
        LoadingProgress()
          .color('#007DFF')
          .margin({ top: 20 })
      }

      // 分享按钮
      if (this.exportPath) {
        Button('分享日志文件')
          .width('80%')
          .height(50)
          .fontSize(18)
          .margin({ top: 30 })
          .backgroundColor('#34C759')
          .onClick(() => {
            this.shareLogFile();
          })
      }

     // Spacer()
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }

  private async exportLogs(): Promise<void> {
    this.isLoading = true;
    this.exportStatus = '正在导出日志...';

    try {
      this.logger.info('开始导出日志');

      // 导出日志
      this.exportPath = await Logger.exportLogs();

      this.exportStatus = '导出成功！';
      this.logger.info(`日志导出成功，路径: ${this.exportPath}`);

      // 提示用户
      promptAction.showToast({
        message: '日志导出成功',
        duration: 2000
      });

    } catch (error) {
      this.exportStatus = '导出失败';
      this.logger.error('导出日志失败', error as Error);

      promptAction.showToast({
        message: '导出失败，请重试',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  private async shareLogFile(): Promise<void> {
    try {
      // 使用鸿蒙的分享功能
      // 具体实现需要根据API版本调整
      this.logger.info('分享日志文件');

      promptAction.showToast({
        message: '已打开分享面板',
        duration: 1500
      });
    } catch (error) {
      this.logger.error('分享失败', error as Error);
    }
  }
}