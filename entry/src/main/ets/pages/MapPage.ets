import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback, emitter } from '@kit.BasicServicesKit';
import { Protocol } from '../macrochip/Drone/core/protocol/Protocol';
import { ModeType, PageSendData } from '../macrochip/Drone/core/protocol/PageSendData';
import { MessageWhat } from '../macrochip/constant/MessageWhat';
import { ProtocolManager } from '../macrochip/Drone/core/protocol/ProtocolManager';
import { ObjectUtils } from '../utils/ObjectUtils';

@Entry
@Component
export struct MapPage {
  private TAG = "HuaweiMapDemo";
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;
  @State myLatLng: mapCommon.LatLng = { latitude: 39.56, longitude: 116.20 }; //手机坐标
  @State planeLatLng: mapCommon.LatLng = { latitude: 0, longitude: 0 }; //无人机坐标
  @State planeRotation: number = 0; //无人机旋转角度
  @State phoneRotation: number = 0; //手机旋转角度
  private isOneLocation = true;
  private myMarker?: map.Marker; //我的位置
  private planeMaker?: map.Marker; //无人机位置

  aboutToAppear(): void {
    // 地图初始化参数，设置地图中心点坐标及层级
    this.mapOptions = {
      position: {
        target: {
          latitude: this.myLatLng.latitude,
          longitude: this.myLatLng.longitude,
        },
        zoom: 16
      }
    };

    // 地图初始化的回调
    this.callback = async (err, mapController) => {
      if (!err) {
        // 获取地图的控制器类，用来操作地图
        this.mapController = mapController;
        this.movePhoneCenter() //移动到手机位置为中心点
        this.addMyMarker()
        this.addPlaneMarker()
        this.mapEventManager = this.mapController.getEventManager();
        let callback = () => {
          console.info(this.TAG, `on-mapLoad`);
        }
        this.mapEventManager.on("mapLoad", callback);
      } else {
        console.error(`Failed to initialize the map, code is：${err.code}, message is ${err.message}`);
      }
    };

    // 持续订阅
    emitter.on({ eventId: ProtocolManager.getInstance().getProtocol() },
      (eventData: emitter.GenericEventData<PageSendData>) => {
        //接收到数据
        if (eventData.data?.modeType == ModeType.FlightControl) {

        } else if (eventData.data?.modeType == ModeType.Page) {
          //页面数据
          switch (eventData.data.type) {
            case MessageWhat.MESSAGE_LOCATION:
              if (eventData.data.location) {
                const location =
                  ObjectUtils.wgs84ToGcj84(eventData.data.location.latitude, eventData.data.location.longitude);
                this.myLatLng = location;
                this.planeLatLng = location;
                if (this.isOneLocation && this.mapController) {
                  this.isOneLocation = false
                  this.movePhoneCenter()
                }
                this.updateMyPosition()
              }
              break
            case MessageWhat.MESSAGE_PLANE_LOCATION:
              if (eventData.data.location) {
                //得到飞机位置
                const location =
                  ObjectUtils.wgs84ToGcj84(eventData.data.location.latitude, eventData.data.location.longitude);
                this.planeLatLng = location;
                this.updatePlanePosition()
              }
              break
            case MessageWhat.MESSAGE_PHONE_ROTATION_ANGLE:
              if (eventData.data.numberData) {
                //得到手机旋转角度
                this.phoneRotation = -eventData.data.numberData - 90
                this.rotatePlane();
              }

              break
          }
        }
      });


  }

  //移动我的位置 为地图中心点
  movePhoneCenter() {
    let cameraUpdate = map.newLatLng(this.myLatLng);
    this.mapController?.moveCamera(cameraUpdate)
  }

  //添加我的位置
  addMyMarker() {
    // 初始化地图后添加标记
    this.mapController?.addMarker({
      position: { latitude: this.myLatLng.latitude, longitude: this.myLatLng.longitude },
      icon: $r('app.media.img_my_loaction'),
      anchorU: 0.5,
      anchorV: 0.5
    }).then(marker => {
      this.myMarker = marker;
    });
  }

  // 更新我的位置坐标
  updateMyPosition() {
    this.myMarker?.setPosition(this.myLatLng);
  }

  //添加飞机位置
  addPlaneMarker() {
    // 初始化地图后添加标记
    this.mapController?.addMarker({
      position: this.planeLatLng,
      icon: $r('app.media.img_drone_location'),
      anchorU: 0.5,
      anchorV: 0.5
    }).then(marker => {
      this.planeMaker = marker;
    });
  }

  //移动飞机的位置 为地图中心点
  movePlaneCenter() {
    let cameraUpdate = map.newLatLng(this.planeLatLng);
    this.mapController?.moveCamera(cameraUpdate)
  }

  // 更新飞机的位置坐标
  updatePlanePosition() {
    this.planeMaker?.setPosition(this.planeLatLng);
  }

  //旋转飞机
  rotatePlane() {
    this.planeMaker?.setRotation(this.planeRotation + this.phoneRotation)
  }

  //


  // 页面每次显示时触发一次，包括路由过程、应用进入前台等场景，仅@Entry装饰的自定义组件生效
  onPageShow(): void {
    // 将地图切换到前台
    if (this.mapController) {
      this.mapController.show();
    }
  }

  aboutToDisappear(): void {
    //取消订阅
    emitter.off(ProtocolManager.getInstance().getProtocol())

  }

  // 页面每次隐藏时触发一次，包括路由过程、应用进入后台等场景，仅@Entry装饰的自定义组件生效
  onPageHide(): void {
    // 将地图切换到后台
    if (this.mapController) {
      this.mapController.hide();
    }
  }

  build() {
    Stack() {
      // 调用MapComponent组件初始化地图
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback }).width('100%').height('100%');
    }.height('100%')
  }
}