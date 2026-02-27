import { AnalysisListener } from '../listeners/AnalysisListener';


// 创建事件管理类
class AnalysisEventManager {
  private listeners: AnalysisListener[] = [];

  // 注册监听
  registerListener(listener: AnalysisListener) {
    this.listeners.push(listener);
  }

  // 触发事件（传递Uint8Array类型数据）
  notifyData(type: number, data: Uint8Array) {
    this.listeners.forEach(listener => listener.data(type, data));
  }

  // 取消监听
  unregisterListener(listener: AnalysisListener) {
    const index = this.listeners.indexOf(listener);
    if (index !== -1) {
      this.listeners.splice(index, 1);
    }
  }
}
// 全局实例
const analysisManager = new AnalysisEventManager();