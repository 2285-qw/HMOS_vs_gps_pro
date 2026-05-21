// LogManager.ets
import fs from '@ohos.file.fs';
import { common, Want, wantConstant } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileUri } from '@kit.CoreFileKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';


/**
 * 日志文件信息
 */
export interface LogFileInfo {
  name: string; // 文件名，如 "2026-05-15.log"
  path: string; // 完整路径
  size: number; // 文件大小（字节）
  lastModified: number; // 最后修改时间戳（毫秒）
  lastModifiedStr: string; // 格式化的最后修改时间
}

export class LogManager {

  private static instance: LogManager;
  private logDir: string = '';
  private static context: common.UIAbilityContext;  // 用于启动分享

  private constructor() {
  }

  public static getInstance(): LogManager {
    if (!LogManager.instance) {
      LogManager.instance = new LogManager();
    }
    return LogManager.instance;
  }

  // 初始化，传入Context以获取沙箱路径
  public init(context: common.UIAbilityContext) {
    this.logDir = `${context.filesDir}/logs`;
    LogManager.context = context;
    // 确保日志目录存在（原有逻辑）
    if (!fs.accessSync(this.logDir)) {
      fs.mkdirSync(this.logDir, true);
    }
  }

  // 对外暴露的日志方法
  public async info(tag: string, message: string) {
    await this.writeLog(`INFO`, tag, message);
  }

  public async error(tag: string, message: string) {
    await this.writeLog(`ERROR`, tag, message);
  }

  private async getTodayLogFilePath(): Promise<string> {
    // 这部分逻辑和之前一样...
    const today = new Date();
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const day = String(today.getDate()).padStart(2, '0');
    const fileName = `${year}-${month}-${day}.log`;
    const filePath = `${this.logDir}/${fileName}`;

    if (!fs.accessSync(this.logDir)) {
      fs.mkdirSync(this.logDir, true);
    }

    try {
      fs.statSync(filePath);
    } catch (err) {
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      fs.closeSync(file);
    }
    return filePath;
  }

  private async writeLog(level: string, tag: string, message: string) {
    const filePath = await this.getTodayLogFilePath();
    const now = new Date();
    const timestamp = `${now.getFullYear()}-${now.getMonth() +
      1}-${now.getDate()} ${now.getHours()}:${now.getMinutes()}:${now.getSeconds()}.${now.getMilliseconds()}`;
    const logLine = `${timestamp} ${level} ${tag}: ${message}\n`;

    let file: fs.File | null = null;
    try {
      file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.APPEND);
      fs.writeSync(file.fd, logLine);
    } catch (error) {
      console.error(`写入文件失败: ${error.message}`);
    } finally {
      if (file) {
        fs.closeSync(file);
      }
    }
  }

  /**
   * 获取所有日志文件列表（按日期倒序）
   * @returns Promise<LogFileInfo[]> 日志文件信息数组
   */
  public async getLogFileList(): Promise<LogFileInfo[]> {
    // 确保日志目录已初始化
    if (!this.logDir) {
      console.error('LogManager 未初始化，请先调用 init()');
      return [];
    }

    const fileList: LogFileInfo[] = [];

    try {
      // 1. 检查目录是否存在
      if (!fs.accessSync(this.logDir)) {
        return []; // 目录不存在，返回空列表
      }

      // 2. 读取目录下所有文件
      const files = fs.listFileSync(this.logDir);

      // 3. 过滤出 .log 文件
      const logFiles = files.filter(file => file.endsWith('.log'));

      // 4. 获取每个文件的详细信息
      for (const fileName of logFiles) {
        const filePath = `${this.logDir}/${fileName}`;
        try {
          const stat = fs.statSync(filePath);
          fileList.push({
            name: fileName,
            path: filePath,
            size: stat.size,
            lastModified: stat.mtime,
            lastModifiedStr: new Date(stat.mtime).toLocaleString(),
          });
        } catch (err) {
          console.error(`获取文件信息失败: ${fileName}`, (err as BusinessError).message);
        }
      }

      // 5. 按文件名（日期）倒序排列，最新的在前
      // 文件名格式为 "YYYY-MM-DD.log"，可直接字符串比较
      fileList.sort((a, b) => b.name.localeCompare(a.name));

      return fileList;
    } catch (error) {
      console.error('获取日志文件列表失败', (error as BusinessError).message);
      return [];
    }
  }


 public  async shareLogFile(fileName: string) {
   console.info('文件名称'+fileName);
    let filePath = LogManager.context.filesDir + '/logs/' + fileName;
    let uri = fileUri.getUriFromPath(filePath);
    let utdTypeId = utd.getUniformDataTypeByFilenameExtension('.log', utd.UniformDataType.TEXT);

    let shareData = new systemShare.SharedData({ utd: utdTypeId, uri: uri });
    let shareController = new systemShare.ShareController(shareData);

    // 可选：监听分享面板关闭事件
    shareController.on('dismiss', () => {
      console.info('分享面板已关闭');
    });

    // 可选：监听分享结果（需要HarmonyOS 5.1.0及以上版本）[reference:6]
    shareController.on('shareCompleted', (result) => {
      console.info(`分享完成，渠道: ${result.targetAbilityInfo.name}`);
    });
   // 3. 配置分享面板选项
   const options: systemShare.ShareControllerOptions = {
     selectionMode: systemShare.SelectionMode.SINGLE, // 单选模式
   };
    try {
      await shareController.show(LogManager.context,options);
      console.info('成功拉起系统分享面板');
    } catch (error) {
      console.error(`拉起分享面板失败: ${error.code}`);
    }
  }

}