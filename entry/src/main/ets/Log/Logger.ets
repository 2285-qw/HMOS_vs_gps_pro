import { LogUtils } from "./LogUtils";

// Logger.ts
export enum LogLevel {
  DEBUG = 'DEBUG',
  INFO = 'INFO',
  WARN = 'WARN',
  ERROR = 'ERROR'
}

export class Logger {
  private tag: string;

  constructor(tag: string) {
    this.tag = tag;
  }

  public debug(message: string): void {
    LogUtils.getInstance().writeLog(LogLevel.DEBUG, this.tag, message);
  }

  public info(message: string): void {
    LogUtils.getInstance().writeLog(LogLevel.INFO, this.tag, message);
  }

  public warn(message: string): void {
    LogUtils.getInstance().writeLog(LogLevel.WARN, this.tag, message);
  }

  public error(message: string, error?: Error): void {
    let errorMessage = message;
    if (error) {
      errorMessage += `\nError: ${error.message}\nStack: ${error.stack}`;
    }
    LogUtils.getInstance().writeLog(LogLevel.ERROR, this.tag, errorMessage);
  }

  // 导出日志
  public static async exportLogs(): Promise<string> {
    return await LogUtils.getInstance().exportLogs();
  }
}