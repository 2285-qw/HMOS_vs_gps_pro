// common/RouteHelper.ets
import { router } from '@kit.ArkUI';
import { LogManager } from '../../Log/LogManager';


export class RouteHelper {
  /**
   * 带日志记录的页面跳转（push）
   * @param url 目标页面路径，如 'pages/LogDetailPage'
   * @param params 传递的参数（可选）
   * @param mode 跳转模式，默认为 standard
   */
  static async pushUrl(
    url: string,
    params?: Record<string, Object>,
    mode: router.RouterMode = router.RouterMode.Standard
  ): Promise<void> {
    // 记录跳转前日志
    const logMsg = `[Navigation] push to: ${url}, params: ${JSON.stringify(params || {})}`;
    LogManager.getInstance().info('Route', logMsg);

    try {
      await router.pushUrl({
        url: url,
        params: params
      }, mode);
      // 记录成功
      LogManager.getInstance().info('Route', `push success: ${url}`);
    } catch (error) {
      // 记录失败
      LogManager.getInstance().error('Route', `push failed: ${url}, error: ${JSON.stringify(error)}`);
     // throw error; // 可选择抛出或静默处理
    }
  }

  /**
   * 带日志记录的页面替换（replace）
   */
  static async replaceUrl(
    url: string,
    params?: Record<string, Object>
  ): Promise<void> {
    LogManager.getInstance().info('Route', `replace to: ${url}, params: ${JSON.stringify(params || {})}`);
    try {
      await router.replaceUrl({
        url: url,
        params: params
      });
      LogManager.getInstance().info('Route', `replace success: ${url}`);
    } catch (error) {
      LogManager.getInstance().error('Route', `replace failed: ${url}, error: ${JSON.stringify(error)}`);
      //throw error;
    }
  }

  /**
   * 返回上一页（带日志）
   */
  static back(): void {
    LogManager.getInstance().info('Route', 'back to previous page');
    router.back();
  }
}