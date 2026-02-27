import { common } from "@kit.AbilityKit";
import fs from '@ohos.file.fs';

// LogUtils.ts
export class LogUtils {
  private static instance: LogUtils;
  private logFilePath: string = '';
  private maxFileSize: number = 5 * 1024 * 1024; // 5MB
  private maxLogDays: number = 7; // 保留7天日志

  private constructor() {
    this.initLogFile();
  }

  public static getInstance(): LogUtils {
    if (!LogUtils.instance) {
      LogUtils.instance = new LogUtils();
    }
    return LogUtils.instance;
  }

  private async initLogFile(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const filesDir = context.filesDir;
      const logDir = filesDir + '/logs';

      // 创建日志目录
      await this.ensureDirExists(logDir);

      // 创建以日期命名的日志文件
      const dateStr = this.getCurrentDate();
      this.logFilePath = logDir + `/app_log_${dateStr}.txt`;

      await this.cleanOldLogs(logDir);
    } catch (error) {
      console.error('初始化日志文件失败:', error);
    }
  }

  // 写日志
  public async writeLog(level: string, tag: string, message: string): Promise<void> {
    try {
      const timestamp = this.getCurrentTime();
      const logEntry = `[${timestamp}] [${level}] ${tag}: ${message}\n`;

      // 检查文件大小
      await this.checkFileSize();

      // 追加日志到文件
      await this.appendToFile(this.logFilePath, logEntry);

      // 同时输出到控制台
      console.log(`${level}: ${tag} - ${message}`);
    } catch (error) {
      console.error('写入日志失败:', error);
    }
  }

  // 导出日志
  public async exportLogs(): Promise<string> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const filesDir = context.filesDir;
      const logDir = filesDir + '/logs';

      // 创建压缩文件
      const exportDir = context.filesDir + '/export';
      await this.ensureDirExists(exportDir);

      const exportFileName = `logs_${this.getCurrentDateTime()}.zip`;
      const exportPath = exportDir + '/' + exportFileName;

      // 压缩日志文件
      await this.zipLogs(logDir, exportPath);

      return exportPath;
    } catch (error) {
      console.error('导出日志失败:', error);
      //throw error;
      return "";
    }
  }

  // 清理旧日志
  private async cleanOldLogs(logDir: string): Promise<void> {
    try {
      // 这里需要文件系统API实现，具体实现取决于API版本
      // 伪代码：删除超过maxLogDays的日志文件
    } catch (error) {
      console.error('清理旧日志失败:', error);
    }
  }

  // 检查文件大小
  private async checkFileSize(): Promise<void> {
    // 伪代码：检查当前日志文件大小，超过限制则创建新文件
  }

  private async appendToFile(filePath: string, content: string): Promise<void> {
    try {
      // 使用鸿蒙文件系统API
      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);
    } catch (error) {
      console.error('写入文件失败:', error);
    }
  }

  private async ensureDirExists(dirPath: string): Promise<void> {
    // 确保目录存在
  }

  private async zipLogs(sourceDir: string, targetPath: string): Promise<void> {
    // 压缩日志文件
  }

  private getCurrentDate(): string {
    const now = new Date();
    return `${now.getFullYear()}${(now.getMonth() + 1).toString().padStart(2, '0')}${now.getDate().toString().padStart(2, '0')}`;
  }

  private getCurrentTime(): string {
    const now = new Date();
    return `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
  }

  private getCurrentDateTime(): string {
    const now = new Date();
    return `${this.getCurrentDate()}_${now.getHours().toString().padStart(2, '0')}${now.getMinutes().toString().padStart(2, '0')}`;
  }
}