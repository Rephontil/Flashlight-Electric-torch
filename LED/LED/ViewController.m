//
//  ViewController.m
//  LED
//
//  Created by ZhouYong on 16/6/30.
//  Copyright © 2016年 ZhouYong. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *ledEnableBtn;

//创建捕捉对话
@property (nonatomic,strong) AVCaptureSession * captureSession;

//添加输入设备
@property (nonatomic,strong) AVCaptureDevice * captureDevice;

@property (weak, nonatomic) IBOutlet UISlider *frequencyLED;

@property (weak, nonatomic) IBOutlet UISlider *brightnessSlider;

/**定时器**/
@property(nonatomic, strong)NSTimer* timer;

/**紧急模式定时器**/
@property(nonatomic, strong)NSTimer* urgecyTimer;


/**频率显示***/
@property (weak, nonatomic) IBOutlet UILabel *frequencyDisplay;

@property (weak, nonatomic) IBOutlet UILabel *stateLabel;

//指示器属性
@property (nonatomic, strong) CAReplicatorLayer *rep;

@property (weak, nonatomic) IBOutlet UIView *backGroundReferencnView;

/**闪光灯总开关***/
@property (weak, nonatomic) IBOutlet UIButton *flashOnOffControlModeBtn;

/**指示器的宽度**/
@property(nonatomic, assign)CGFloat indicatorWidth;

/**指示器的高度度**/
@property(nonatomic, assign)CGFloat indicatorHeight;

//报警警示灯
@property (weak, nonatomic) IBOutlet UIButton *warningBtn;

//紧急模式
@property (weak, nonatomic) IBOutlet UIButton *urgencyBtn;

/**sosLabel**/
@property(nonatomic, retain)UILabel* sosLabel;




@end


@implementation ViewController


-(AVCaptureSession *)captureSesion
{
    if(_captureSession == nil)
    {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return _captureSession;
}



-(AVCaptureDevice *)captureDevice
{
    if(_captureDevice == nil)
    {
        _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _captureDevice;
}



#pragma mark**********总开关************
- (IBAction)ledEnableBtn:(UIButton *)sender
{
    /**change state of btn**/
    self.ledEnableBtn.selected = !self.ledEnableBtn.selected;
    if (self.ledEnableBtn.selected == YES)
    {
        self.stateLabel.text = @"关闭";
        self.stateLabel.textColor = [UIColor redColor];
        if([self.captureDevice hasTorch] && [self.captureDevice hasFlash])
        {
            if(self.captureDevice.torchMode == AVCaptureTorchModeOff)
            {
                [self.captureSession beginConfiguration];
                [self.captureDevice lockForConfiguration:nil];
                [self.captureDevice setTorchMode:AVCaptureTorchModeOn];
                [self.captureDevice setFlashMode:AVCaptureFlashModeOn];
                [self.captureDevice unlockForConfiguration];
                [self.captureSession commitConfiguration];
            }
        }
        [self.captureSession startRunning];
    }
    else
    {
        self.stateLabel.text = @"打开";
        self.stateLabel.textColor = [UIColor colorWithRed:96/255.0 green:250/255.0 blue:137/255.0 alpha:1];

//关闭光源
        [self closeLightSource];

        self.flashOnOffControlModeBtn.selected = NO;
        if (self.timer.valid) {
            [self.timer invalidate];
            self.timer = nil;
        }
        [self.rep removeFromSuperlayer];
        [self.sosLabel removeFromSuperview];
        self.warningBtn.selected = NO;
        self.urgencyBtn.selected = NO;
        if (self.urgecyTimer.valid) {
            [self.urgecyTimer invalidate];
            self.urgecyTimer = nil;
        }

    }
}


#pragma mark**********频率调节的滑条************
- (IBAction)frequencyLed:(UISlider *)sender
{
    if (self.flashOnOffControlModeBtn.selected == YES)
    {
        [self.timer invalidate];

        UISlider* slider = (UISlider*)sender;
        /**赋值**/
        self.frequencyLED = slider;
        self.frequencyLED.continuous = YES;

        self.frequencyLED.minimumValue = 0.05; //20Hz
        self.frequencyLED.maximumValue = 1;  //1Hz
        slider.continuous = YES;

        //    频率调节
        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.frequencyLED.value target:self selector:@selector(sosTimer) userInfo:nil repeats:YES];

        self.frequencyDisplay.text = [NSString stringWithFormat:@"-   %.2fHz   +",1.0/slider.value];
    }
}


#pragma mark**********亮度调节的滑条************
- (IBAction)brightness:(UISlider *)sender
{
    
    UISlider* slider = (UISlider*)sender;
    self.brightnessSlider = slider;
    float leval = slider.value;
    slider.continuous = YES;
    self.brightnessSlider.continuous = YES;
    if (self.ledEnableBtn.selected)
    {
        if ([self.captureDevice hasTorch] && leval > 0  && leval <= 1.0) {
            [self.captureDevice lockForConfiguration:nil];
            [self.captureDevice setTorchModeOnWithLevel:slider.value error:nil];
            [self.captureDevice unlockForConfiguration];
        }
        else if([self.captureDevice hasTorch] && leval == 0)
        {
            [self.captureDevice lockForConfiguration:nil];
            [self.captureDevice setTorchMode:AVCaptureTorchModeOff];
            [self.captureDevice unlockForConfiguration];
        }

    }
    if(self.ledEnableBtn.selected == NO && self.urgencyBtn.selected == NO && self.flashOnOffControlModeBtn.selected == NO)
    {
        [self tipsForNoChangingBrightness];
    }
}



- (void)sosTimer
{
    [self.captureSession beginConfiguration];
    [self.captureDevice lockForConfiguration:nil];
    //判断闪光灯是否亮着
    if(self.captureDevice.torchMode == AVCaptureTorchModeOff)
    {
        //打开闪光灯
        [self.captureDevice setTorchMode:AVCaptureTorchModeOn];
        [self.captureDevice setFlashMode:AVCaptureFlashModeOn];
    }
    else
    {
        //关闭闪光灯
        [self.captureDevice setTorchMode:AVCaptureTorchModeOff];
        [self.captureDevice setFlashMode:AVCaptureFlashModeOff];
    }
    [self.captureDevice unlockForConfiguration];
    [self.captureSession commitConfiguration];
    
    
    if(self.captureDevice.torchMode == AVCaptureTorchModeOff)
    {
        [self.captureSession startRunning];
    }
    else
    {
        [self.captureSession stopRunning];
    }
}


//闪光灯模式开关
- (IBAction)flashingEnableOnOff:(UIButton *)sender
{
    UIButton* button = (UIButton*)sender;
    self.flashOnOffControlModeBtn = button;
//    如果总开关关闭了，就弹出提醒视图
    if (self.ledEnableBtn.selected == NO && self.urgencyBtn.selected == NO && self.flashOnOffControlModeBtn.selected == NO)
    {
        [self tips];

        self.flashOnOffControlModeBtn.selected = self.flashOnOffControlModeBtn.selected;
    }
//    如果总开关打开了
    else
    {
        self.flashOnOffControlModeBtn.selected = !self.flashOnOffControlModeBtn.selected;
//        如果SOS模式定时器开启就关闭
        if (self.urgecyTimer.valid == YES)
        {
            [self.urgecyTimer invalidate];
            self.urgecyTimer = nil;
            self.urgencyBtn.selected = NO;
            [self.rep removeFromSuperlayer];
            [self.sosLabel removeFromSuperview];
        }
        if (self.flashOnOffControlModeBtn.selected == YES)
        {
//            直接调用UISlider
            [self frequencyLed:self.frequencyLED];
        }
        else
        {
            if (self.timer.valid == YES) {
                [self.timer invalidate];
                self.timer = nil;
            }
            //关闭光源
            [self closeLightSource];
        }
    }
}



//紧急模式开关
- (IBAction)emergencyEnableBtn:(UIButton *)sender
{
    UIButton* button = (UIButton*)sender;

    self.urgencyBtn = button; //本按钮
//    如果总开关打开
        self.urgencyBtn.selected = !self.urgencyBtn.selected;
//        销毁闪光灯的定时器
        if (self.timer.valid == YES)
        {
            [self.timer invalidate];
            self.timer = nil;
        }

        if (self.urgencyBtn.selected == YES)
        {
            [self sosLayer];
            self.urgecyTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(sosModel) userInfo:nil repeats:YES];
            self.flashOnOffControlModeBtn.selected = NO;

        }
        if (self.urgencyBtn.selected == NO)
        {
//            移除SOS画图
            [self.rep removeFromSuperlayer];
            [self.sosLabel removeFromSuperview];
//            停止自身的定时器
            [self.urgecyTimer invalidate];
            self.urgecyTimer = nil;
            self.warningBtn.selected = NO;

//关闭光源
            [self closeLightSource];
        }
}


#pragma mark**********亮度调节杆的提醒视图************
- (void) tips
{
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"请先打开LED开关" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* actionTip = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action)
                                {
                                    [alertController dismissViewControllerAnimated:YES completion:nil];
                                }];
    [alertController addAction:actionTip];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void) tipsForNoChangingBrightness
{
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"手电筒没有开启，无法调节亮度" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* actionTip = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action)
                                {
                                    [alertController dismissViewControllerAnimated:YES completion:nil];
                                }];
    [alertController addAction:actionTip];
    [self presentViewController:alertController animated:YES completion:nil];
}



#pragma mark**********紧急模式************
- (void)sosModel
{
    [self sosTimer];
    self.warningBtn.selected = !self.warningBtn.selected;
}


#pragma mark--------指示器------------
- (void)sosLayer
{
    
    self.rep = [CAReplicatorLayer layer];

    self.rep.frame = CGRectMake((self.indicatorWidth - self.indicatorHeight) /2, 0, self.indicatorHeight, self.indicatorHeight);

    self.rep.backgroundColor = [UIColor clearColor].CGColor;
    CALayer *layer = [CALayer layer];
    layer.position = CGPointMake(self.rep.bounds.size.width / 2, 20);
    layer.bounds = CGRectMake(0, 0, 8, 8);
    layer.cornerRadius = 4;
    layer.backgroundColor = [UIColor redColor].CGColor;
    layer.transform = CATransform3DMakeScale(0, 0, 0);

    
    CABasicAnimation *animation = [CABasicAnimation animation];
    // 进行缩放
    animation.keyPath = @"transform.scale";
    animation.fromValue = @1;
    animation.toValue = @0;
    // 动画执行时间
    animation.duration = 0.8;
    animation.repeatCount = MAXFLOAT;
    animation.autoreverses = YES;
    // 给视图层添加动画效果
    [layer addAnimation:animation forKey:nil];

    
    [self.rep addSublayer:layer];


    int count = 30;
    self.rep.instanceCount = count;
    // 弧度
    CGFloat angle = M_PI * 2 / count;
    // 旋转
    self.rep.instanceTransform = CATransform3DMakeRotation(angle, 0, 0, 1);
    
    self.rep.instanceDelay = animation.duration / count;
    
    [self.backGroundReferencnView.layer addSublayer:self.rep];

    self.sosLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.indicatorWidth/2 - 40, self.indicatorHeight/2 - 20, 80, 40)];
    self.sosLabel.backgroundColor = [UIColor clearColor];
    self.sosLabel.text = @"SOS";
    self.sosLabel.font = [UIFont boldSystemFontOfSize:30];
    self.sosLabel.textAlignment = NSTextAlignmentCenter;
    self.sosLabel.textColor = [UIColor redColor];
    [self.backGroundReferencnView addSubview:self.sosLabel];
}


#pragma mark**********关闭光源************
- (void)closeLightSource
{
    [self.captureSession beginConfiguration];
    [self.captureDevice lockForConfiguration:nil];
    if(self.captureDevice.torchMode == AVCaptureTorchModeOn)
    {
        [self.captureDevice setTorchMode:AVCaptureTorchModeOff];
        [self.captureDevice setFlashMode:AVCaptureFlashModeOff];
    }
    [self.captureDevice unlockForConfiguration];
    [self.captureSession commitConfiguration];
    [self.captureSession stopRunning];

}



- (void)viewDidLoad
{
    [super viewDidLoad];
    self.ledEnableBtn.selected = NO;
    //    创建输入设备
    AVCaptureDeviceInput* deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDevice error:nil];
    //    添加输入设备
    [self.captureSession addInput:deviceInput];
    
    
    UIImageView* backgroundImageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [backgroundImageView setImage:[UIImage imageNamed:@"mainBackground.jpg"]];
    [self.view insertSubview:backgroundImageView atIndex:0];
    
    /**调整滚动条的方向**/
    //    [self.brightnessSlider setTransform:CGAffineTransformMakeRotation(270*M_PI/180)];
    
    self.frequencyDisplay.text = [NSString stringWithFormat:@"-   0.00Hz   +"];
}


- (void)viewWillAppear:(BOOL)animated
{
    [self.backGroundReferencnView layoutIfNeeded];
    self.indicatorHeight = self.backGroundReferencnView.frame.size.height ;
    self.indicatorWidth = self.backGroundReferencnView.frame.size.width ;

}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}



@end
