// utils/GlobalConfig.ts（单独文件）
class ConnectConfig {
  private static instance: ConnectConfig;
  // 全局变量
  hostIp: string = '';

  // 单例模式，确保唯一实例
  private constructor() {}

  static getInstance(): ConnectConfig {
    if (!this.instance) {
      this.instance = new ConnectConfig();
    }
    return this.instance;
  }
}

// 导出单例实例
export const connectConfig = ConnectConfig.getInstance();