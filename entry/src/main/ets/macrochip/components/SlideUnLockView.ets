import {  UIContext } from '@kit.ArkUI';

// 定义滑动解锁监听器接口
interface OnUnLockListener {
  onSuccess(): void;
}

@Component
struct SlideUnLockView {
  // 组件属性
  @Prop slideBackgroundColor: string = '#E0E0E0';
  @Prop slideCoverColor: string = '#FF0000';
  @Prop slideArrow?: Resource;
  @Prop slideThumb: Resource = $r('app.media.icon_more');
  @Prop slideText: string = '向右滑动解锁';
  @Prop slideTextSize: number = 12;
  @Prop slideTextColor: string = '#000000';
  @Prop slideCover: boolean = false;

  // 组件状态
  @State locationX: number = 0;
  @State dragable: boolean = false;
  @State isUnlocked: boolean = false;
  @State slideRectWidth: number = 0;

  // 组件事件
  onSuccess: () => void = () => {};

  // 组件尺寸
  @Prop componentWidth: number = 100;
  @Prop componentHeight: number = 50;
  private thumbWidth: number = 50;
  private thumbHeight: number = 50;
  private backgroundRadius: number = 25;
  private paddingLeft: number = 0;
  private paddingTop: number = 0;
  private paddingRight: number = 0;
  private paddingBottom: number = 0;

  // 初始化方法
  aboutToAppear(): void {
    // 设置组件宽度
   // this.componentWidth = 200;
   // this.componentHeight = 50;
    this.backgroundRadius = this.componentHeight / 2;
    this.thumbHeight=this.componentHeight;
    this.thumbWidth=this.componentHeight;
  }

  // 绘制方法
  build(): void {
    Stack() {
      // 背景
      Row()
        .width(this.componentWidth)
        .height(this.componentHeight)
        .backgroundColor(this.slideBackgroundColor)
        .borderRadius(this.backgroundRadius);

      // 滑动覆盖区域
      Row()
        .width(this.slideRectWidth)
        .height(this.componentHeight)
        .backgroundColor(this.slideCoverColor)
        .borderRadius(this.backgroundRadius);

      // 文本
      Text(this.slideText)
        .fontSize(this.slideTextSize)
        .fontColor(this.slideTextColor)
        .textAlign(TextAlign.Center)
        .width('100%')
        .height(this.componentHeight)
        .alignSelf(ItemAlign.Center);

      // 滑块
      Circle()
        .fill('#fffdfdfd') // 设置填充颜色（如蓝色）
        .width(this.thumbWidth)
        .height(this.thumbHeight)
        .position({
          x: this.locationX,
          y: 0
        })
        .onTouch((event: TouchEvent) => {
          this.handleTouchEvent(event);
        });
    }
    .width(this.componentWidth)
    .height(this.componentHeight)
    .onTouch((event: TouchEvent) => {
      this.handleTouchEvent(event);
    });
  }

  // 处理触摸事件
  private handleTouchEvent(event: TouchEvent): void {
    switch (event.type) {
      case TouchType.Down:
        this.handleTouchStart(event);
        break;
      case TouchType.Move:
        this.handleTouchMove(event);
        break;
      case TouchType.Up:
        this.handleTouchEnd(event);
        break;
      default:
        break;
    }
  }

  // 处理触摸开始事件
  private handleTouchStart(event: TouchEvent): void {
    const touchX = event.touches[0].x;

    // 检查触摸点是否在滑块上
    if (this.isTouchBall(touchX)) {
      this.locationX = touchX - this.thumbWidth / 2;
      this.dragable = true;
    } else {
      this.dragable = false;
    }
  }

  // 处理触摸移动事件
  private handleTouchMove(event: TouchEvent): void {
    if (!this.dragable) return;

    const touchX = event.touches[0].x;
    const rightMax = this.componentWidth - this.thumbWidth;

    // 更新滑块位置
    this.resetLocationX(touchX, rightMax);

    // 计算滑动覆盖区域宽度
    let slideRight = touchX + this.thumbWidth / 2;
    if (slideRight < this.thumbWidth) {
      slideRight = this.thumbWidth;
    } else if (slideRight > this.componentWidth) {
      slideRight = this.componentWidth;
    }
    this.slideRectWidth = slideRight;

    // 检查是否解锁
    if (this.locationX >= rightMax) {
      this.dragable = false;
      this.isUnlocked = true;
      // 触发解锁事件
      if (this.onSuccess) {
        this.onSuccess();
      }
    }
  }

  // 处理触摸结束事件
  private handleTouchEnd(event: TouchEvent): void {
    if (!this.dragable) return;

    // 重置锁定状态
    this.resetLock();
  }

  // 重置锁定状态
  private resetLock(): void {
    // 使用动画重置滑块位置
    animateTo({
      duration: 300,
      curve: Curve.EaseOut
    }, () => {
      this.locationX = 0;
      this.slideRectWidth = 0;
    });

    this.dragable = false;
    this.isUnlocked = false;
  }

  // 重置滑块位置
  private resetLocationX(touchX: number, rightMax: number): void {
    this.locationX = touchX - this.thumbWidth / 2;
    if (this.locationX < 0) {
      this.locationX = 0;
    } else if (this.locationX > rightMax) {
      this.locationX = rightMax;
    }
  }

  // 检测触摸点是否在滑块上
  private isTouchBall(touchX: number): boolean {
    const maxX = this.locationX + this.thumbWidth;
    const minX = this.locationX;
    return touchX >= minX && touchX <= maxX;
  }

  // 设置文本
  setText(text: string): void {
    this.slideText = text;
  }
}

export { SlideUnLockView };
