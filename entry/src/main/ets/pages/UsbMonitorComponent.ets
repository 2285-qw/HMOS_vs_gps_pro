import { UsbAccessoryMonitor } from '../connect/usb/UsbMonitorComponent';
import { window,promptAction } from '@kit.ArkUI';
@Entry
@Component
struct UsbMonitorComponent {
  @State message: string = 'Hello World';

  build() {
    Column() {
      UsbAccessoryMonitor()
    }
    .width('100%')
    .height('100%')
  }

  onPageShow(): void {
    window.getLastWindow(this.getUIContext().getHostContext(), (err, data) => {
      data.setWindowLayoutFullScreen(true)  // 进入沉浸式
    });
    window.getLastWindow(this.getUIContext().getHostContext(), (err, data) => {
      data.setPreferredOrientation(window.Orientation.PORTRAIT); // 强制竖屏
    });
  }
  // 页面隐藏时恢复横屏
  onPageHide(): void {
    window.getLastWindow(this.getUIContext().getHostContext(), (err, data) => {
      try {
        data.setPreferredOrientation(window.Orientation.LANDSCAPE); // 恢复横屏
      }catch (e) {
      }

    });
  }
}