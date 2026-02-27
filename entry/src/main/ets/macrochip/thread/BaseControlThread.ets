export abstract class BaseControlThread {
    protected stopValue:number = 0;           //急停

    protected toFlyValue: number = 0;        //一键起飞
    protected toLandValue : number= 0;       //一键降落
    protected goHome :number = 0;         //一键返航
    protected rotate: number = 64;        // 旋转

    protected surroundRadius: number = 0; // 环绕半径
    protected surroundValue : number= 0;
    protected unLockValue : number= 0;//解锁
    protected lockValue: number = 0;//加锁
    protected followValue: number = 0;
    protected controlValue: number = 0;

    protected isRun: boolean = true;
    private intervalId: number | null = null;
    protected controlInterval: number = 100; // 控制循环间隔，单位ms

    constructor() {
        this.isRun = true;
    }

    /**
     * 开始控制线程
     */
    public start(): void {
        this.isRun = true;
        this.controlLoop();
    }

    /**
     * 停止控制线程
     */
    public cancel(): void {
        this.isRun = false;
        if (this.intervalId !== null) {
            clearTimeout(this.intervalId);
            this.intervalId = null;
        }
    }

    /**
     * 控制循环
     */
    private controlLoop(): void {
        if (!this.isRun) {
            return;
        }
        // 这里可以添加实际的控制逻辑
        this.doControl();

        // 使用setTimeout实现循环，避免阻塞主线程
        this.intervalId = setTimeout(() => {
            this.controlLoop();
        }, this.controlInterval);
    }

    /**
     * 实际的控制逻辑，子类可以重写此方法
     */
    protected doControl(): void {
        // 默认实现，可以被子类重写
    }

    public getRun(): boolean {
        return this.isRun;
    }

    public setStopValue(stopValue: number): void {
        this.stopValue = stopValue;
    }

    public setToFlyValue(toFlyValue: number): void {
        this.toFlyValue = toFlyValue;
    }

    public setToLandValue(toLandValue: number): void {
        this.toLandValue = toLandValue;
    }

    public setGoHome(goHome: number): void {
        this.goHome = goHome;
    }

    public setRotate(rotate: number): void {
        this.rotate = rotate;
    }

    public setSurroundRadius(surroundRadius: number): void {
        this.surroundRadius = surroundRadius;
    }

    public setSurroundValue(surroundValue: number): void {
        this.surroundValue = surroundValue;
    }

    public setUnLockValue(unLockValue: number): void {
        this.unLockValue = unLockValue;
    }

    public setFollowValue(followValue: number): void {
        this.followValue = followValue;
    }

    public setLockValue(lockValue: number): void {
        this.lockValue = lockValue;
    }

    public getSurroundValue(): number {
        return this.surroundValue;
    }

    public setControlValue(controlValue: number): void {
        this.controlValue = controlValue;
    }

    public getControlValue(): number {
        return this.controlValue;
    }
}