// ShootButton.ets
export enum Mode {
  PHOTO,
  RECORD,
  SCALE
}

@Component
export struct ShootButton {
  @Prop mode: Mode = Mode.PHOTO;
  @Prop isRecording: boolean = false;
  @Prop number: number = 50;
  @State private rotateAngle: number = 0;

  // 使用原 Java 代码中的图片资源名称（放在 resources/base/media 下）
  private getIconResource(): Resource {
    switch (this.mode) {
      case Mode.PHOTO:
        return $r('app.media.ic_camera_photo');
      case Mode.RECORD:
        return this.isRecording ? $r('app.media.ic_camera_video_on') : $r('app.media.ic_camera_video_off');
      case Mode.SCALE:
        return this.isRecording ? $r('app.media.ic_camera_time_lapse_photography_on') : $r('app.media.ic_camera_time_lapse_photography_off');
      default:
        return $r('app.media.ic_camera_photo');
    }
  }

  build() {
    Stack() {
      // 底层：按钮背景图标
      Image(this.getIconResource())
        .width(this.number)
        .height(this.number)
        .objectFit(ImageFit.Contain)

      // 旋转动画层（仅 SCALE + 录制时显示）
      if (this.mode === Mode.SCALE && this.isRecording) {
        Image($r('app.media.img_time_lapse_photography_animator'))
          .width(this.number)
          .height(this.number)
          .objectFit(ImageFit.Contain)
          .rotate({ angle: this.rotateAngle })
          .animation({
            duration: 5000,
            iterations: -1,
            curve: Curve.Linear
          })
          .onAppear(() => {
            // 开始旋转：从0到360
            this.rotateAngle = 360;
          })
          .onDisAppear(() => {
            this.rotateAngle = 0;
          })
      }
    }
    .width(this.number)
    .height(this.number)
    .borderRadius(28)
    .backgroundColor(Color.White)
    .shadow({ radius: 4, color: '#40000000' })
    .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.95 })
  }
}