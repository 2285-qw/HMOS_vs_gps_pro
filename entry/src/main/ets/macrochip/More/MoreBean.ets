/**
 * 功能项Bean类
 * 对应无人机的功能项配置
 */
import { MoreType } from './MoreType';

/**
 * 弹出视图接口
 */
export interface MorePopup {
  // 弹出视图相关方法
}

/**
 * 功能项Bean类
 */
export class MoreBean {
  // 使用组合ID确保唯一性（时间戳+随机数）
   id: string = `item_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
  private icon: Resource=$r('app.media.ic_more_rev') ;
  private text: string = '';
  private type: MoreType =MoreType.REV;
  private selected: boolean = false;
  private popupView: MorePopup | undefined;
  private enabled: boolean = true;

  /**
   * 构造函数
   */
  constructor() {
    this.enabled = true;
  }

  /**
   * 获取图标资源ID
   * @returns 图标资源ID
   */
  getIcon(): Resource {
    return this.icon
  }

  /**
   * 设置图标资源ID
   * @param icon 图标资源ID
   */
  setIcon(icon: Resource): void {
    this.icon = icon;
  }

  /**
   * 获取文本资源ID
   * @returns 文本资源ID
   */
  getText(): string {
    return this.text;
  }

  /**
   * 设置文本资源ID
   * @param text 文本资源ID
   */
  setText(text: string): void {
    this.text = text;
  }

  /**
   * 获取功能类型
   * @returns 功能类型
   */
  getType(): MoreType  {
    return this.type;
  }

  /**
   * 设置功能类型
   * @param type 功能类型
   */
  setType(type: MoreType): void {
    this.type = type;
  }

  /**
   * 是否选中
   * @returns 是否选中
   */
  isSelected(): boolean {
    return this.selected;
  }

  /**
   * 设置选中状态
   * @param selected 是否选中
   */
  setSelected(selected: boolean): void {
    this.selected = selected;
  }

  /**
   * 获取弹出视图
   * @returns 弹出视图
   */
  getPopupView(): MorePopup | undefined {
    return this.popupView;
  }

  /**
   * 设置弹出视图
   * @param popupView 弹出视图
   */
  setPopupView(popupView: MorePopup): void {
    this.popupView = popupView;
  }

  /**
   * 是否启用
   * @returns 是否启用
   */
  isEnabled(): boolean {
    return this.enabled;
  }

  /**
   * 设置启用状态
   * @param enabled 是否启用
   */
  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }
}