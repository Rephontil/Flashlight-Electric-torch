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
        self.stateLabel.textColor = [UIColor colorWithRed:96/255.0 green:250/255.0 blue:137/255.0 alpha:1];;
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
        
//        查看闪光模式是否开启如果开启，则关闭.查看sos模式是否开启，如果开启则关闭。
        if (self.flashOnOffControlModeBtn.selected) {
            [self.timer invalidate];
            [self.flashOnOffControlModeBtn setBackgroundImage:[UIImage imageNamed:@"OFF"] forState:UIControlStateNormal];
            
        }
        if (self.urgencyBtn.selected) {
            [self.urgecyTimer invalidate];
            [self.warningBtn setBackgroundImage:[UIImage imageNamed:@"waring_green"] forState:UIControlStateNormal];
        }
        [self.rep removeFromSuperlayer];
        
    }
}



- (IBAction)frequencyLed:(UISlider *)sender
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



- (IBAction)brightness:(UISlider *)sender
{
    
    UISlider* slider = (UISlider*)sender;
    self.brightnessSlider = slider;
    float leval = slider.value;
    slider.continuous = YES;
    self.brightnessSlider.continuous = YES;
    if (self.ledEnableBtn.selected) {
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

    }else{
//        tips
        [self tips];
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
    self.flashOnOffControlModeBtn = button ;
    button.selected = !button.selected;
    
//    开启闪光模式
    if (button.selected)
    {
        [self frequencyLed:self.frequencyLED];
        [self.urgecyTimer invalidate];
    }
//    关闭闪光模式
    else
    {

    }
}


//紧急模式开关
- (IBAction)flashingEnableBtn:(UIButton *)sender
{
    UIButton* button = (UIButton*)sender;
    self.urgencyBtn = button;
    if (self.ledEnableBtn.selected)
    {
         button.selected = !button.selected;
        if (button.selected)
        {
            [self.urgecyTimer invalidate];
            [self sosLayer];
            
            self.urgecyTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(sosModel) userInfo:nil repeats:YES];
            
            [self.timer invalidate];
            
        }
        else
        {
            self.warningBtn.selected = NO;
            [self.rep removeFromSuperlayer];
            [self.urgecyTimer invalidate];
            [self.warningBtn setBackgroundImage:[UIImage imageNamed:@"waring_green"] forState:UIControlStateNormal];
        }
    }
    /**创建提醒视图**/
    else
    {
        button.selected = button.selected;
        [self tips];
        [self.urgecyTimer invalidate];
    }
}


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


//紧急模式
- (void)sosModel
{
    [self sosTimer];
    self.warningBtn.enabled = !self.warningBtn.enabled;

    [self.warningBtn setBackgroundImage:[UIImage imageNamed:@"waring_red"] forState:UIControlStateNormal];
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
}



- (void)viewDidLoad
{
    [super viewDidLoad];
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
    self.indicatorHeight = self.backGroundReferencnView.frame.size.height;
    self.indicatorWidth = self.backGroundReferencnView.frame.size.width;

}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



@end
