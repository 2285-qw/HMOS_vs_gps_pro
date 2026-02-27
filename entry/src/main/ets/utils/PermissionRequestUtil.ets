import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { bundleManager } from '@kit.AbilityKit';

export class PermissionRequestUtil {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  // 检查单个权限状态
 static  async checkPermission(permissionName: Permissions): Promise<abilityAccessCtrl.GrantStatus> {

    // 获取当前Ability的context（EntryAbility的context）
    let tokenId: number = 0;
    try {
      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to get bundle info for self, code: ${err.code}, message: ${err.message}`);
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const grantStatus = await atManager.checkAccessToken(tokenId, permissionName);
      return grantStatus;
    } catch (error) {
      console.error(`检查权限失败: ${permissionName}`, error);
      return abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    }
  }

  // 请求单个权限
 static  async requestPermission(permissionName: Permissions,context: Context): Promise<abilityAccessCtrl.GrantStatus> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      // 请求权限
      const result = await atManager.requestPermissionsFromUser(context, [permissionName]);
      return result.authResults[0] === 0 ?
        abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED : abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    } catch (error) {
      console.error(`请求权限失败: ${permissionName}`, error);
      return abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    }
  }

  // 请求多个权限
  static  async  requestPermissions(permissions: Array<Permissions>,context: Context): Promise<Array<[permission: Permissions, grantStatus: abilityAccessCtrl.GrantStatus]>> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      const grantResults: Array<[permission: Permissions, grantStatus: abilityAccessCtrl.GrantStatus]> = [];
      for (let i = 0; i < permissions.length; i++) {
        grantResults.push([
          permissions[i],
         result.authResults[i] === 0 ? abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED : abilityAccessCtrl.GrantStatus.PERMISSION_DENIED
        ]);
      }
      return grantResults;
    } catch (error) {
      console.error('请求多个权限失败', error);
      return permissions.map(permission => [
        permission,
        abilityAccessCtrl.GrantStatus.PERMISSION_DENIED
      ] as [Permissions, abilityAccessCtrl.GrantStatus]);
    }
  }

  // 检查并请求单个权限（如果未授权）
static   async checkAndRequestPermission(permission: Permissions,context: Context): Promise<abilityAccessCtrl.GrantStatus> {
    let grantStatus = await PermissionRequestUtil.checkPermission(permission);
    if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      grantStatus = await PermissionRequestUtil.requestPermission(permission,context);
    }
    return grantStatus;
  }

  // 检查并请求多个权限
  static  async checkAndRequestPermissions(permissions: Array<Permissions>,context: Context): Promise<Array<[permission: Permissions, grantStatus: abilityAccessCtrl.GrantStatus]>> {
    const results: Array<[permission: Permissions, grantStatus: abilityAccessCtrl.GrantStatus]> = [];
    for (const permission of permissions) {
      const grantStatus = await PermissionRequestUtil.checkAndRequestPermission(permission,context);
      results.push([permission, grantStatus]);
    }
    return results;
  }

  // 显示提示信息（可选，用于解释为什么需要权限）
  static async showPermissionExplanation(permission: string, explanation: string) {
    await promptAction.showToast({
      message: explanation,
      duration: 3000
    });
  }
}