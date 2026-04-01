import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { SendEmitterUtil } from '../utils/SendEmitterUtil';
import { MessageWhat } from '../macrochip/constant/MessageWhat';


@Entry
@Component
export struct CompassView {
  @State directionMsg: string = '北';
  @State rotationAngle: number = 0; // 指针旋转角度


  private startOrientationUpdates() {
    sensor.on(sensor.SensorId.ORIENTATION, (data) => {
      const alpha = data.alpha; // 获取方位角(0°-360°)
    //  this.directionMsg = this.calcDirection(alpha);

      // 更新指针旋转角度(逆时针旋转取负值)
      animateTo({ duration: 200 }, () => {
        this.rotationAngle = -alpha-90;
        //传递发送位置信息
        SendEmitterUtil.sendEventNumber(MessageWhat.MESSAGE_PHONE_ROTATION_ANGLE,  alpha)
      });
    }, { interval: 100000000 }); // 100毫秒采样间隔
  }

  aboutToAppear() {
    sensor.getSensorList((error: BusinessError, sensors: sensor.Sensor[]) => {
      if (error) {
        console.error("传感器不可用: " + JSON.stringify(error));
        return;
      }
      const hasOrientation = sensors.some(item =>
      item.sensorId === sensor.SensorId.ORIENTATION
      );
      if (hasOrientation) {
        console.info("设备支持方向传感器");
        // 此处添加传感器订阅逻辑
        this.startOrientationUpdates();
      }else {
        console.error("设备不支持方向传感器");
      }

    });
  }
  aboutToDisappear(): void {
    try {
      // 注销方向传感器监听
      sensor.off(sensor.SensorId.ORIENTATION);
    } catch (error) {

    }
  }

  build() {
    Column() {
     /* // 方向文字
      Text(this.directionMsg).fontSize(20)*/

      // 指北针图形
      Stack() {
        Image($r('app.media.img_angle_bg')) // 表盘背景图
          .width(100)

        // 指针(需根据旋转角度动态调整)
        Image($r('app.media.ic_angle_north'))
          .width(90)
          .height(90)
          .rotate({ angle: this.rotationAngle })
      }
    }
  }
}