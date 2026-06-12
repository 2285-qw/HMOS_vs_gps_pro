import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback, emitter } from '@kit.BasicServicesKit';
import { Protocol } from '../macrochip/Drone/core/protocol/Protocol';
import { ModeType, PageSendData } from '../macrochip/Drone/core/protocol/PageSendData';
import { MessageWhat } from '../macrochip/constant/MessageWhat';
import { ProtocolManager } from '../macrochip/Drone/core/protocol/ProtocolManager';
import { ObjectUtils } from '../utils/ObjectUtils';
import { CompassView } from '../components/CompassView';
import { SendEmitterUtil } from '../utils/SendEmitterUtil';
import { RouteHelper } from '../macrochip/utils/RouteHelper';
import { PreferencesUtil } from '../macrochip/utils/PreferencesUtil';
import { media } from '@kit.MediaKit';

@Entry
@Component
export struct SeekPlanePage {
  private TAG = "HuaweiMapDemo";
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;
  @State myLatLng: mapCommon.LatLng = { latitude: 0, longitude: 0 }; //手机坐标
  @State planeLatLng: mapCommon.LatLng = { latitude: 0, longitude: 0 }; //无人机坐标
  @State planeRotation: number = 0; //无人机旋转角度
  @State phoneRotation: number = 0; //手机旋转角度
  @State radius: number = 500; //圆圈半径
  @State isRotate: boolean = false; //是否旋转
  @State isMoveLocation: Visibility = Visibility.None; //移动我和飞机为中心点显示状态
  @State mapType: number = 0; //地图状态
  @State isMapType: boolean = false; //地图状态显示
  @Prop isDeleteWaypoint: Visibility = Visibility.None; //删除航点两个view显示状态
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

    this.planeLatLng = PreferencesUtil.getData('location', this.planeLatLng) as mapCommon.LatLng


    // 地图初始化的回调
    this.callback = async (err, mapController) => {
      if (!err) {
        // 获取地图的控制器类，用来操作地图
        this.mapController = mapController;
        this.mapController.setZoomControlsEnabled(false);

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
    emitter.on({ eventId: ModeType.Page },
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
                this.rotateMap(this.phoneRotation)
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

  //旋转地图
  rotateMap(bearing: number) {
    if (!this.isRotate) {
      return
    }
    // 1. 获取当前相机状态
    let currentPos = this.mapController?.getCameraPosition();
    // 2. 创建新的相机位置，仅修改 bearing
    let newCameraPos = map.newCameraPosition({
      target: currentPos?.target, // 保持中心点不变
      zoom: currentPos?.zoom, // 保持缩放级别不变
      bearing: bearing, // 设置新角度（0~360）
    });
    this.mapController?.moveCamera(newCameraPos);
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
    if (this.planeLatLng.longitude != 0 && this.planeLatLng.latitude != 0) {
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
    emitter.off(ModeType.Page)

  }

  // 页面每次隐藏时触发一次，包括路由过程、应用进入后台等场景，仅@Entry装饰的自定义组件生效
  onPageHide(): void {
    // 将地图切换到后台
    if (this.mapController) {
      this.mapController.hide();
    }
  }

  build() {
    RelativeContainer() {
      // 调用MapComponent组件初始化地图
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback }).width('100%').height('100%');

      Image($r('app.media.ic_back'))
        .width(30)
        .height(30)
        .margin({ left: 20, top: 20 })
        .objectFit(ImageFit.Contain)
        .background("#ff9b9b9b")
        .onClick(() => {
          RouteHelper.back()
        })

      Image($r('app.media.ic_map_type'))
        .width(30)
        .height(30)
        .alignRules({
          right: {
            anchor: "__container__", align: HorizontalAlign.End
          }
        })
        .margin({ right: 20, top: 20 })
        .onClick(() => {
          this.isMapType = !this.isMapType
        })
        .id("right_view1")

      Row({ space: 10 }) {
        Column() {
          Image($r('app.media.ic_map_type_standard'))
            .width(50)
            .height(50)
            .background(this.mapType == 0 ? '#FF5C72E7' : Color.Transparent) // 对应 <solid> 标签
            .borderRadius(3)
            .padding(1) // 对应 <corners> 标签，3对应Android的3dp
          Text('标准').fontSize(10).fontColor(Color.White)
        }.onClick(() => {
          this.mapType = 0
          this.mapController?.setMapType(mapCommon.MapType.STANDARD);
        })

        Column() {
          Image($r('app.media.ic_map_type_satellite'))
            .width(50)
            .height(50)
            .background(this.mapType == 1 ? '#FF5C72E7' : Color.Transparent) // 对应 <solid> 标签
            .borderRadius(3)
            .padding(1) // 对应 <corners> 标签，3对应Android的3dp // 对应 <corners> 标签，3对应Android的3dp
          Text('卫星').fontSize(10).fontColor(Color.White)
        }.onClick(() => {
          this.mapType = 1
          this.mapController?.setMapType(mapCommon.MapType.SATELLITE);

        })

        Column() {
          Image($r('app.media.ic_map_type_satellite'))
            .width(50)
            .height(50)
            .background(this.mapType == 2 ? '#FF5C72E7' : Color.Transparent) // 对应 <solid> 标签
            .borderRadius(3) // 对应 <corners> 标签，3对应Android的3dp
            .padding(1) // 对应 <corners> 标签，3对应Android的3dp
          Text('夜间').fontSize(10).fontColor(Color.White)
        }.onClick(() => {
          // 切换为夜间模式
          this.mapType = 2
          this.mapController?.setMapType(mapCommon.MapType.STANDARD);
          this.mapController?.setDayNightMode(mapCommon.DayNightMode.NIGHT);
        })

      }
      .alignRules({
        right: {
          anchor: "right_view1", align: HorizontalAlign.End
        },
        top: {
          anchor: "right_view1", align: VerticalAlign.Bottom
        }
      })
      .backgroundImageSize(ImageSize.FILL)
      .backgroundImage($r('app.media.ic_map_type_bg'))
      .justifyContent(FlexAlign.Center)
      .padding({ top: 10, left: 10, right: 10 })
      .visibility(this.isMapType ? Visibility.Visible : Visibility.None)

      Column({ space: 20 }) {
        Image($r('app.media.ic_map_location_my'))
          .width(30)
          .height(30)
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            this.movePhoneCenter()
          })
          .background("#ff9b9b9b")
        Image($r('app.media.ic_map_location_drone'))
          .width(30)
          .height(30)
          .objectFit(ImageFit.Contain)
          .background("#ff9b9b9b")
          .onClick(() => {
            this.movePlaneCenter()
          })
      }.alignRules({
        right: {
          anchor: "__container__", align: HorizontalAlign.End
        },
        center: {
          anchor: "__container__", align: VerticalAlign.Center
        }
      }).margin({ right: 20 })

    }.width('100%').height('100%');
  }
}