import usbManager from '@ohos.usbManager';
import { BusinessError } from '@ohos.base';
import  promptAction  from '@ohos.promptAction';
import  hilog  from '@ohos.hilog';

const TAG = 'UsbAccessoryMonitor';
const DOMAIN = 0xF811;

@Component
export struct UsbAccessoryMonitor {
  @State accessoryList: Array<usbManager.USBAccessory> = [];
  @State isMonitoring: boolean = false;
  @State connectedAccessory: usbManager.USBAccessory | null = null;
  @State accessoryHandle: usbManager.USBAccessoryHandle | null = null;
  @State connectionStatus: string = '未连接';

  // 存储之前的设备列表用于比较
  private previousAccessoryList: Array<usbManager.USBAccessory> = [];
  private checkIntervalId: number = 0;

  aboutToAppear() {
    this.initUsbAccessory();
  }

  aboutToDisappear() {
    this.stopMonitoring();
    this.closeCurrentAccessory();
  }

  // 初始化USB配件监听
  private initUsbAccessory() {
    try {
      const accessories = usbManager.getAccessoryList();
      this.accessoryList = accessories;
      this.previousAccessoryList = [...accessories];

      if (accessories.length > 0) {
        this.connectedAccessory = accessories[0];
        this.connectionStatus = `已连接: ${accessories[0].manufacturer}`;
      }

      hilog.info(DOMAIN, TAG, 'USB配件初始化完成, 发现 %{public}d 个配件', accessories.length);
    } catch (error) {
      const err = error as BusinessError;
      if (err.code === 14400004) {
        // 没有配件连接，这是正常情况
        hilog.info(DOMAIN, TAG, '当前没有USB配件连接');
      } else {
        hilog.error(DOMAIN, TAG, '初始化USB配件失败: %{public}s', JSON.stringify(err));
      }
    }
  }

  // 开始监听USB配件连接
  startMonitoring() {
    if (this.isMonitoring) {
      return;
    }

    this.isMonitoring = true;

    // 使用轮询方式检查设备列表变化（因为API文档中没有显示有事件监听接口）
    this.checkIntervalId = setInterval(() => {
      this.checkAccessoryChanges();
    }, 1000); // 每秒检查一次

    promptAction.showToast({
      message: 'USB配件监听已启动',
      duration: 2000
    });

    hilog.info(DOMAIN, TAG, 'USB配件监听开始');
  }

  // 停止监听
  stopMonitoring() {
    if (!this.isMonitoring) {
      return;
    }

    this.isMonitoring = false;

    if (this.checkIntervalId) {
      clearInterval(this.checkIntervalId);
      this.checkIntervalId = 0;
    }

    promptAction.showToast({
      message: 'USB配件监听已停止',
      duration: 2000
    });

    hilog.info(DOMAIN, TAG, 'USB配件监听停止');
  }

  // 检查配件变化
  private checkAccessoryChanges() {
    try {
      const currentAccessories = usbManager.getAccessoryList();

      // 检查是否有新配件连接
      const newAccessories = currentAccessories.filter(newAcc =>
      !this.previousAccessoryList.some(oldAcc =>
      this.isSameAccessory(newAcc, oldAcc)
      )
      );

      // 检查是否有配件断开
      const removedAccessories = this.previousAccessoryList.filter(oldAcc =>
      !currentAccessories.some(newAcc =>
      this.isSameAccessory(newAcc, oldAcc)
      )
      );

      // 如果有变化，更新UI
      if (newAccessories.length > 0 || removedAccessories.length > 0) {
        this.accessoryList = currentAccessories;
        this.previousAccessoryList = [...currentAccessories];

        // 处理新连接的配件
        if (newAccessories.length > 0) {
          this.onAccessoryConnected(newAccessories[0]);
        }

        // 处理断开的配件
        if (removedAccessories.length > 0) {
          this.onAccessoryDisconnected(removedAccessories[0]);
        }
      }
    } catch (error) {
      const err = error as BusinessError;
      if (err.code !== 14400004) { // 忽略"没有配件连接"的错误
        hilog.error(DOMAIN, TAG, '检查配件变化失败: %{public}s', JSON.stringify(err));
      }
    }
  }

  // 判断两个配件是否相同
  private isSameAccessory(acc1: usbManager.USBAccessory, acc2: usbManager.USBAccessory): boolean {
    return acc1.serialNumber === acc2.serialNumber &&
      acc1.manufacturer === acc2.manufacturer &&
      acc1.product === acc2.product;
  }

  // 配件连接处理
  private async onAccessoryConnected(accessory: usbManager.USBAccessory) {
    hilog.info(DOMAIN, TAG, 'USB配件已连接: %{public}s', accessory.product);

    this.connectedAccessory = accessory;
    this.connectionStatus = `已连接: ${accessory.manufacturer}`;

    // 显示连接通知
    promptAction.showToast({
      message: `USB配件已连接: ${accessory.product}`,
      duration: 3000
    });

    // 自动请求权限
    await this.requestAccessoryPermission(accessory);
  }

  // 配件断开处理
  private onAccessoryDisconnected(accessory: usbManager.USBAccessory) {
    hilog.info(DOMAIN, TAG, 'USB配件已断开: %{public}s', accessory.product);

    // 如果断开的是当前连接的配件
    if (this.connectedAccessory && this.isSameAccessory(this.connectedAccessory, accessory)) {
      this.connectedAccessory = null;
      this.connectionStatus = '未连接';
      this.closeCurrentAccessory();
    }

    promptAction.showToast({
      message: `USB配件已断开: ${accessory.product}`,
      duration: 3000
    });
  }

  // 请求配件权限
  private async requestAccessoryPermission(accessory: usbManager.USBAccessory) {
    try {
      const hasRight = usbManager.hasAccessoryRight(accessory);

      if (!hasRight) {
        hilog.info(DOMAIN, TAG, '请求USB配件权限...');

        const granted = await usbManager.requestAccessoryRight(accessory);

        if (granted) {
          promptAction.showToast({
            message: 'USB配件权限已获取',
            duration: 2000
          });
          hilog.info(DOMAIN, TAG, 'USB配件权限获取成功');

          // 权限获取成功后自动打开配件
          this.openAccessory(accessory);
        } else {
          promptAction.showToast({
            message: 'USB配件权限被拒绝',
            duration: 3000
          });
          hilog.warn(DOMAIN, TAG, 'USB配件权限被拒绝');
        }
      } else {
        hilog.info(DOMAIN, TAG, '已有USB配件权限，直接打开配件');
        this.openAccessory(accessory);
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, '请求配件权限失败: %{public}s', JSON.stringify(err));
    }
  }

  // 打开USB配件
  private openAccessory(accessory: usbManager.USBAccessory) {
    try {
      if (this.accessoryHandle) {
        // 如果已有打开的配件，先关闭
        this.closeCurrentAccessory();
      }

      const handle = usbManager.openAccessory(accessory);
      this.accessoryHandle = handle;

      hilog.info(DOMAIN, TAG, 'USB配件打开成功，文件描述符: %{public}d', handle.accessoryFd);

      promptAction.showToast({
        message: 'USB配件已打开，可以开始通信',
        duration: 2000
      });

      // 这里可以开始与配件进行数据通信
      // 例如：监听配件数据、发送命令等

    /*  usbManager.bulkTransfer(handle, outEndpoint, sendData, 15000)
        .then((dataLength: number) => {
          console.info(`Send data success, length: ${dataLength}`);
        })
        .catch((error: BusinessError) => {
          console.error(`Send failed: ${error}`);
        });
*/

    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, '打开USB配件失败: %{public}s', JSON.stringify(err));

      let errorMsg = '打开配件失败';
      switch (err.code) {
        case 14400001:
          errorMsg = '没有访问权限';
          break;
        case 14401001:
          errorMsg = '配件不匹配';
          break;
        case 14401002:
          errorMsg = '无法打开配件节点';
          break;
        case 14401003:
          errorMsg = '配件已打开';
          break;
      }

      promptAction.showToast({
        message: errorMsg,
        duration: 3000
      });
    }
  }

  // 关闭当前配件
  private closeCurrentAccessory() {
    if (this.accessoryHandle) {
      try {
        usbManager.closeAccessory(this.accessoryHandle);
        this.accessoryHandle = null;
        hilog.info(DOMAIN, TAG, 'USB配件已关闭');
      } catch (error) {
        hilog.error(DOMAIN, TAG, '关闭配件失败: %{public}s', JSON.stringify(error));
      }
    }
  }

  // 刷新配件列表
  refreshAccessoryList() {
    try {
      const accessories = usbManager.getAccessoryList();
      this.accessoryList = accessories;
      this.previousAccessoryList = [...accessories];

      if (accessories.length > 0) {
        this.connectedAccessory = accessories[0];
        this.connectionStatus = `已连接: ${accessories[0].manufacturer}`;
      } else {
        this.connectedAccessory = null;
        this.connectionStatus = '未连接';
      }

      promptAction.showToast({
        message: `发现 ${accessories.length} 个USB配件`,
        duration: 2000
      });
    } catch (error) {
      const err = error as BusinessError;
      if (err.code === 14400004) {
        this.accessoryList = [];
        this.connectedAccessory = null;
        this.connectionStatus = '未连接';
      }
    }
  }

  // 获取配件信息字符串
  private getAccessoryInfo(accessory: usbManager.USBAccessory): string {
    return `厂商: ${accessory.manufacturer || '未知'}
产品: ${accessory.product || '未知'}
描述: ${accessory.description || '无'}
版本: ${accessory.version || '未知'}
序列号: ${accessory.serialNumber || '无'}`;
  }

  build() {
    Column({ space: 20 }) {
      // 标题
      Text('USB配件监听器')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .margin({ top: 20 })

      // 连接状态
      Row() {
        Text('连接状态: ')
          .fontSize(16)
          .fontColor(Color.Black)

        Text(this.connectionStatus)
          .fontSize(16)
          .fontColor(this.connectedAccessory ? Color.Green : Color.Red)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .padding( 20)

      // 监听状态
      Row() {
        Text('监听状态: ')
          .fontSize(14)
          .fontColor(Color.Gray)

        Text(this.isMonitoring ? '运行中' : '已停止')
          .fontSize(14)
          .fontColor(this.isMonitoring ? Color.Green : Color.Gray)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .padding( 20 )

      // 配件列表
      if (this.accessoryList.length === 0) {
        Column() {
          Image($r('app.media.background'))
            .width(120)
            .height(120)
            .margin({ bottom: 15 })
            .opacity(0.6)

          Text('暂无USB配件连接')
            .fontSize(16)
            .fontColor(Color.Gray)

          Text('请连接USB配件（如Arduino、USB调试器等）')
            .fontSize(12)
            .fontColor(Color.Gray)
            .margin({ top: 5 })
        }
        .height('40%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.accessoryList, (accessory: usbManager.USBAccessory, index: number) => {
            ListItem() {
              Column({ space: 10 }) {
                // 配件标题行
                Row() {
                  Image($r('app.media.background'))
                    .width(24)
                    .height(24)
                    .margin({ right: 10 })

                  Text(accessory.product || `USB配件${index + 1}`)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Color.Black)
                    .layoutWeight(1)

                  if (this.connectedAccessory && this.isSameAccessory(this.connectedAccessory, accessory)) {
                    Text('已连接')
                      .fontSize(12)
                      .fontColor(Color.White)
                      .backgroundColor(Color.Green)
                      .borderRadius(10)
                  }
                }
                .width('100%')

                // 配件详细信息
                Column({ space: 4 }) {
                  if (accessory.manufacturer) {
                    Text(`厂商: ${accessory.manufacturer}`)
                      .fontSize(14)
                      .fontColor(Color.Gray)
                      .width('100%')
                      .textAlign(TextAlign.Start)
                  }

                  if (accessory.description) {
                    Text(`描述: ${accessory.description}`)
                      .fontSize(14)
                      .fontColor(Color.Gray)
                      .width('100%')
                      .textAlign(TextAlign.Start)
                  }

                  Text(`序列号: ${accessory.serialNumber || '无'}`)
                    .fontSize(14)
                    .fontColor(Color.Gray)
                    .width('100%')
                    .textAlign(TextAlign.Start)
                }
                .width('100%')

                // 操作按钮
                Row({ space: 10 }) {
                  if (this.connectedAccessory && this.isSameAccessory(this.connectedAccessory, accessory)) {
                    Button('断开')
                      .onClick(() => {
                        this.closeCurrentAccessory();
                        this.connectedAccessory = null;
                        this.connectionStatus = '未连接';
                      })
                      .backgroundColor(Color.Red)
                      .fontColor(Color.White)
                      .height(36)
                      .layoutWeight(1)
                  } else {
                    Button('连接')
                      .onClick(() => {
                        this.connectedAccessory = accessory;
                        this.connectionStatus = `已连接: ${accessory.manufacturer}`;
                        this.requestAccessoryPermission(accessory);
                      })
                      .backgroundColor(Color.Blue)
                      .fontColor(Color.White)
                      .height(36)
                      .layoutWeight(1)
                  }

                  Button('详情')
                    .onClick(() => {
                      promptAction.showDialog({
                        title: '配件信息',
                        message: this.getAccessoryInfo(accessory),
                        buttons: [ {
                          text: '确定',  // 按钮文本
                          color: '#000000' // 可选，按钮文字颜色
                        }]
                      });
                    })
                    .backgroundColor(Color.Gray)
                    .fontColor(Color.White)
                    .height(36)
                    .layoutWeight(1)
                }
                .width('100%')
                .margin({ top: 5 })
              }
              .padding(15)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .shadow({ radius: 4, color: '#20000000', offsetX: 1, offsetY: 1 })
            }
            .margin(15)
          })
        }
        .layoutWeight(1)
        .margin({ top: 10 })
      }

      // 控制按钮
      Row({ space: 15 }) {
        Button(this.isMonitoring ? '停止监听' : '开始监听')
          .onClick(() => {
            if (this.isMonitoring) {
              this.stopMonitoring();
            } else {
              this.startMonitoring();
            }
          })
          .backgroundColor(this.isMonitoring ? Color.Orange : Color.Blue)
          .fontColor(Color.White)
          .width(150)
          .height(40)

        Button('刷新列表')
          .onClick(() => this.refreshAccessoryList())
          .backgroundColor(Color.Green)
          .fontColor(Color.White)
          .width(150)
          .height(40)
      }
      .padding( 20 )

      // 当前连接信息
      if (this.connectedAccessory && this.accessoryHandle) {
        Column() {
          Divider()
            .color('#E0E0E0')
            .margin(10 )

          Text('当前连接')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.Black)
            .width('100%')
            .textAlign(TextAlign.Start)
            .margin({ bottom: 10 })

          Row() {
            Text('文件描述符: ')
              .fontSize(14)
              .fontColor(Color.Gray)

            Text(this.accessoryHandle.accessoryFd.toString())
              .fontSize(14)
              .fontColor(Color.Black)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)

          Button('发送测试数据')
            .onClick(() => {
              // 这里可以添加发送测试数据的代码
              promptAction.showToast({
                message: '发送测试数据（功能待实现）',
                duration: 2000
              });
            })
            .backgroundColor(Color.White)
            .fontColor(Color.White)
            .width('100%')
            .height(36)
            .margin({ top: 10 })
        }
        .padding(15)
        .backgroundColor('#F8F8F8')
        .borderRadius(10)
        .margin(20)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}