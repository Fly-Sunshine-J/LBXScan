//
//
//  
//
//  Created by lbxia on 15/10/21.
//  Copyright © 2015年 lbxia. All rights reserved.
//

#import "LBXScanZBarViewController.h"


@interface LBXScanZBarViewController ()
@end

@implementation LBXScanZBarViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.view.backgroundColor = [UIColor blackColor];
    self.title = @"ZBar";
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self drawScanView];
    
    [self requestCameraPemissionWithResult:^(BOOL granted) {

        if (granted) {

            //不延时，可能会导致界面黑屏并卡住一会
            [self performSelector:@selector(startScan) withObject:nil afterDelay:0.3];

        }else{
            [self.qRScanView stopDeviceReadying];
        }
    }];
   
}

//绘制扫描区域
- (void)drawScanView
{
    if (!self.qRScanView)
    {
        CGRect rect = self.view.frame;
        rect.origin = CGPointMake(0, 0);
        
        self.qRScanView = [[LBXScanView alloc]initWithFrame:rect style:self.style];
        
        [self.view addSubview:self.qRScanView];
    }
    
    if (!self.cameraInvokeMsg) {
        
//        _cameraInvokeMsg = NSLocalizedString(@"wating...", nil);
    }
    [self.qRScanView startDeviceReadyingWithText:self.cameraInvokeMsg];
}

- (void)reStartDevice
{
    [_zbarObj start];
}

//启动设备
- (void)startScan
{
    UIView *videoView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    videoView.backgroundColor = [UIColor clearColor];
    [self.view insertSubview:videoView atIndex:0];
    
    self.cameraPreView = videoView;
    __weak __typeof(self) weakSelf = self;
    
    if (!_zbarObj) {
        
        self.zbarObj = [[LBXZBarWrapper alloc]initWithPreView:videoView barCodeType:self.zbarType block:^(NSArray<LBXZbarResult *> *result) {
            
            [weakSelf handZBarResult:result];
        }];
    }
    [_zbarObj start];
    
    
    [self.qRScanView stopDeviceReadying];
    [self.qRScanView startScanAnimation];
    
    
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)handZBarResult:(NSArray<LBXZbarResult *> *)result
{
    //测试，只使用扫码结果第一项
    LBXZbarResult *firstObj = result[0];
    
    LBXScanResult *scanResult = [[LBXScanResult alloc]init];
    scanResult.strScanned = firstObj.strScanned;
    scanResult.imgScanned = firstObj.imgScanned;
    scanResult.strBarCodeType = [LBXZBarWrapper convertFormat2String:firstObj.format];
    
    CGRect bounds = firstObj.bounds;
    CGSize imgSize = firstObj.imgScanned.size;
    CGSize preViewSize = self.cameraPreView.frame.size;
//    CGFloat left = bounds.origin.x / imgSize.width * preViewSize.width;
//    CGFloat top =  bounds.origin.y / imgSize.height * preViewSize.height;
    
//    bounds.origin = CGPointMake(left, top);

    CGFloat minx = bounds.origin.x;
    CGFloat miny= bounds.origin.y;
    CGFloat maxx = bounds.origin.x + bounds.size.width;
    CGFloat maxy= bounds.origin.y + bounds.size.height;
    
    minx = minx / imgSize.width * preViewSize.width;
    maxx = maxx / imgSize.width * preViewSize.width;
    miny = miny / imgSize.height * preViewSize.height;
    maxy = maxy / imgSize.height * preViewSize.height;
    
    
    CGFloat w = maxx - minx;
    CGFloat h = maxy - miny;
    
    miny = minx;
    minx = preViewSize.width - minx;

    scanResult.bounds = CGRectMake(minx, miny, w, h);
        
    [self scanResultWithArray:@[scanResult]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
 
    [self stopScan];
    
    [self.qRScanView stopScanAnimation];
}

- (void)stopScan
{
    [_zbarObj stop];
}

//开关闪光灯
- (void)openOrCloseFlash
{
    [_zbarObj openOrCloseFlash];
    self.isOpenFlash =!self.isOpenFlash;
}


#pragma mark --打开相册并识别图片

/*!
 *  打开本地照片，选择图片识别
 */
- (void)openLocalPhoto:(BOOL)allowsEditing
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    picker.delegate = self;
   
    //部分机型有问题
    picker.allowsEditing = allowsEditing;
    
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)recognizeImageWithImage:(UIImage*)image
{
    __weak typeof(self) weakSelf = self;
    [LBXZBarWrapper recognizeImage:image block:^(NSArray<LBXZbarResult *> *result) {
        
        //测试，只使用扫码结果第一项
        LBXZbarResult *firstObj = result[0];
        
        LBXScanResult *scanResult = [[LBXScanResult alloc]init];
        scanResult.strScanned = firstObj.strScanned;
        scanResult.imgScanned = firstObj.imgScanned;
        scanResult.strBarCodeType = [LBXZBarWrapper convertFormat2String:firstObj.format];
        
        [weakSelf scanResultWithArray:@[scanResult]];
        
    }];

}

@end
