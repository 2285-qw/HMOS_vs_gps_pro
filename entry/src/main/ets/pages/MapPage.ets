import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback, emitter } from '@kit.BasicServicesKit';
import { Protocol } from '../macrochip/Drone/core/protocol/Protocol';
import { ModeType, PageSendData } from '../macrochip/Drone/core/protocol/PageSendData';
import { MessageWhat } from '../macrochip/constant/MessageWhat';
import { ProtocolManager } from '../macrochip/Drone/core/protocol/ProtocolManager';
import { ObjectUtils } from '../utils/ObjectUtils';
import { CompassView } from '../components/CompassView';
import { SendEmitterUtil } from '../utils/SendEmitterUtil';

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
  @State radius: number = 500; //圆圈半径
  @State isRotate: boolean = false; //是否旋转
  @State isMoveLocation:Visibility=Visibility.None;//移动我和飞机为中心点显示状态
  @Prop isDeleteWaypoint:Visibility=Visibility.None;//删除航点两个view显示状态
  private isOneLocation = true;
  private myMarker?: map.Marker; //我的位置
  private planeMaker?: map.Marker; //无人机位置
  private mapCircle?: map.MapCircle; // 保存圆圈实例
  private addedMarkers: map.Marker[] = []; // 存储已添加的标记点
  // 在组件或类中定义
  private pointRes: Array<Resource> = [
    $r('app.media.img_point_marker1'),
    $r('app.media.img_point_marker2'),
    $r('app.media.img_point_marker3'),
    $r('app.media.img_point_marker4'),
    $r('app.media.img_point_marker5'),
    $r('app.media.img_point_marker6'),
    $r('app.media.img_point_marker7'),
    $r('app.media.img_point_marker8'),
    $r('app.media.img_point_marker9'),
    $r('app.media.img_point_marker10'),
    $r('app.media.img_point_marker11'),
    $r('app.media.img_point_marker12'),
    $r('app.media.img_point_marker13'),
    $r('app.media.img_point_marker14'),
    $r('app.media.img_point_marker15'),
    $r('app.media.img_point_marker16')
  ];
  //圆圈
  @State mapCircleOptions: mapCommon.MapCircleOptions = {
    center: this.myLatLng,
    radius: this.radius, // 半径，单位：米
    //  fillColor: 0XFF00FFFF, // 填充色（ARGB格式）
    strokeColor: 0xFFFF0000, // 边框颜色
    strokeWidth: 3, // 边框宽度，单位：像素
    zIndex: 16, // 叠加层级
    //clickable: true  // <--- 关键步骤：开启可点击属性
  };

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
        this.mapController.addCircle(this.mapCircleOptions).then((MapCircle) => {
          this.mapCircle = MapCircle;
          console.info('圆圈添加成功');
        }).catch((err: BusinessError) => {
          console.error('圆圈添加失败', err);
        });
        ; //画圆

        //地图点击事件
        this.mapOnClick()


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
                  //更新圆圈中心点
                  this.updateCircleCenter()
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

  //地图点击事件
  mapOnClick() {
    const eventManager = this.mapController?.getEventManager();
    if (eventManager) {
      eventManager?.on("mapClick", (clickPosition: mapCommon.LatLng) => {
        if (this.isDeleteWaypoint!=Visibility.Visible) {
          return
        }
        //圈内点击事件
        //判断点击位置是否在圈内
        if (this.isPointInCircle(clickPosition)) {
          // 限制最多添加16个点
          if (this.addedMarkers.length >= 16) {
            console.info("已达到最大标记点数（16个）");
            return;
          }
          // 获取当前图标
          const icon = this.pointRes[this.addedMarkers.length];
          // 在点击位置添加一个 Marker
          this.mapController?.addMarker({
            position: clickPosition,
            icon: icon, // 请替换为你的图标资源
            anchorU: 0.5,
            anchorV: 0.5
          }).then(marker => {
            this.addedMarkers.push(marker);
            console.info(`Marker added at (${clickPosition.latitude}, ${clickPosition.longitude})`);
          }).catch((err: BusinessError) => {
            console.error(`Failed to add marker: ${err.message}`);
          });
        }
      });
    } else {
      console.error("❌ 获取 EventManager 失败！");
    }
  }

  /**
   * 判断点是否在圆内
   * @param point 点击点坐标
   * @returns 距离圆心 <= 500米则返回true
   */
  private isPointInCircle(point: mapCommon.LatLng): boolean {
    if (!this.mapCircle) {
      return false;
    }
    const center = this.mapCircle.getCenter();
    const radius = this.mapCircle.getRadius(); // 单位：米
    const distance = map.calculateDistance(point, center);
    return distance <= radius;
  }

  //删除所有的航点
  removeAllPoint(){
    this.addedMarkers.forEach(marker => {
      marker.remove();
    });
    this.addedMarkers = []; // 清空数组
    console.info("已删除所有标记点");
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

  // 新增：更新圆的圆心到当前手机位置
  private updateCircleCenter() {
    if (this.mapCircle) {
      this.mapCircle.setCenter(this.myLatLng);
    }
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
    RelativeContainer() {
      // 调用MapComponent组件初始化地图
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback }).width('100%').height('100%');
      //右上角点击按钮
      Row({ space: 10 }) {
        Image($r('app.media.ic_map_single_point_delete')).width(30).height(30)
          .visibility(this.isDeleteWaypoint)
          .onClick(()=>{
            if (this.addedMarkers.length === 0) {
              console.info("没有可删除的标记点");
              return;
            }

            // 获取最后一个标记点
            const lastMarker = this.addedMarkers[this.addedMarkers.length - 1];

            // 从地图上移除
            lastMarker.remove();

            // 从数组中删除最后一个元素
            this.addedMarkers.pop();
            console.info(`已删除一个标记点，剩余 ${this.addedMarkers.length} 个`);
          })
        Image($r('app.media.ic_map_point_delete')).width(30).height(30)
          .visibility(this.isDeleteWaypoint)
          .onClick(()=>{
            this.removeAllPoint()

          })
        Image($r('app.media.ic_map_location')).width(30).height(30).onClick(()=>{
          if (this.isMoveLocation===Visibility.None) {
            this.isMoveLocation=Visibility.Visible
          }else {
            this.isMoveLocation=Visibility.None
          }

        })
        RelativeContainer() {
          Image(this.isRotate ? $r('app.media.img_compass') : $r('app.media.ic_compass_lock'))
            .width(30)
            .height(30)
            .rotate({ angle: this.isRotate ? this.phoneRotation : 0 })  // angle 单位是度
            .objectFit(ImageFit.Contain)
            .onClick(() => {
              this.isRotate = !this.isRotate;
            })

        }.width(30).height(30).backgroundImage($r('app.media.ic_compass_bg'))

        Image($r('app.media.ic_map_type')).width(30).height(30)
      }.width('AUTO')
      .alignRules({
        right: {
          anchor: "__container__", align: HorizontalAlign.End
        }
      }).margin({ top: 50, right: 60 }).id('right_view1')

      Row(){
        Image($r('app.media.ic_map_location_my')).width(20).height(20).objectFit(ImageFit.Contain).layoutWeight(1)  // 均分权重
          .onClick(()=>{
           this.movePhoneCenter()
          })
        Image($r('app.media.ic_map_location_drone')).width(20) .height(20).objectFit(ImageFit.Contain).layoutWeight(1)  // 均分权重
          .onClick(()=>{
            this.movePlaneCenter()
          })
      } .alignRules({
        right: {
          anchor: "right_view1", align: HorizontalAlign.End
        },
        top:{
        anchor: "right_view1", align: VerticalAlign.Bottom
        }
      }).backgroundImageSize(ImageSize.Cover)
      .backgroundImage($r('app.media.ic_map_location_bg'))
      .margin({right:80}).padding({top:5}).width(60).height(35)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)   // 垂直居中   // 水平居中
      .visibility(this.isMoveLocation)
      Image($r('app.media.ic_map_point_fly')).width(50).height(50).alignRules({
        right:{
          anchor:"__container__",align:HorizontalAlign.End
        },
        bottom: {
          anchor: "__container__", align: VerticalAlign.Bottom
        }
      }).margin({right:110,bottom:30}).visibility(this.isDeleteWaypoint).onClick(()=>{
        if (this.addedMarkers.length>0) {
          console.log("------------------dqq")
          //航点数据列表
          SendEmitterUtil.sendEventMapPoint(MessageWhat.MESSAGE_WAYPOINT, this.addedMarkers)
          SendEmitterUtil.sendEventObject(MessageWhat.MESSAGE_WAYPOINT, this.addedMarkers)
          console.log("------------------dqq11111111112222")
        }

      })





    }.width('100%').height('100%');
  }
}