import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

export class PreferencesUtil {
  public static preference?: preferences.Preferences;
  public static NOVICE = "novice";//新手
  public static DISTANCE = "distance";//距离
  public static FLY_ALTITUDE = "fly_altitude";//高度
  public static RETURN_ALTITUDE = "return_altitude";//返航
  //默认值
  public static mgoHomeDistance: number = 30; //返航高度 默认30米
  public static mflightDistance:number=30;//飞行距离
  public static mflightAltitude:number=30;//飞行高度

  // 初始化首选项实例
  public static initPreferences(context: Context) {
    PreferencesUtil.preference = preferences.getPreferencesSync(context, { name: 'MyPreferences' });
  }

  // 保存数据（同步写入）
  public static saveData(key: string, value: preferences.ValueType) {
    PreferencesUtil.preference?.putSync(key, value);
    PreferencesUtil.preference?.flush((err: BusinessError) => { // 主动持久化
      if (err) {
        console.error('持久化失败:', err.message);
      }
    });
  }

  // 读取数据
  public static getData(key: string, defaultValue: preferences.ValueType): preferences.ValueType {
    if (PreferencesUtil.preference) {
      return PreferencesUtil.preference.getSync(key, defaultValue);
    }
    return defaultValue;
  }


}