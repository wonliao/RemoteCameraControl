//
//  ViewController.m
//  test2
//
//  Created by wonliao on 13/9/11.
//  Copyright (c) 2013年 wonliao. All rights reserved.
//

#import "ViewController.h"
#import "NSData+Base64.h"
#import "Packet.h"

#import "UIImage+Resize.h"
#import "ImageEditViewController.h"

@interface ViewController ()

@end




@implementation ViewController

@synthesize captureSession = _captureSession;
@synthesize prevLayer = _prevLayer;
@synthesize segmentControl;
@synthesize infoLabel;

#pragma mark -
#pragma mark Initialization
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    mySessionPreset = AVCaptureSessionPresetPhoto;// AVCaptureSessionPresetPhoto;//AVCaptureSessionPresetMedium;
    
    [videoPreviewView setNeedsLayout];
    [videoPreviewView layoutIfNeeded];
    
    
    [photoButton setImage:[UIImage imageNamed:@"Pix_Camera_TakePicture_Highlighted.png"] forState:UIControlStateSelected | UIControlStateHighlighted];
    
    // 顯示最新的照片
    [self takeLastPhoto];
    
    
    [[LeDiscovery sharedInstance] setDiscoveryDelegate:self];
    [[LeDiscovery sharedInstance] setPeripheralDelegate:self];
    [[LeDiscovery sharedInstance] startScanningForUUIDString:kTemperatureServiceUUIDString];
    
    
    [self initCapture];
    
    flashAutoFlag = 1;
    segmentControl.selectedSegmentIndex = 0;
}


// 顯示最新的照片
- (void)takeLastPhoto
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        // Within the group enumeration block, filter to enumerate just photos.
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        
        // Chooses the photo at the last index
        [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:[group numberOfAssets] - 1] options:0 usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {
            
            // The end of the enumeration is signaled by asset == nil.
            if (alAsset) {
                ALAssetRepresentation *representation = [alAsset defaultRepresentation];
                UIImage *latestPhoto = [UIImage imageWithCGImage:[representation fullScreenImage]];
                
                [photoLibaryButton setImage:latestPhoto forState:UIControlStateNormal];
                
                photoLibaryButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
                photoLibaryButton.imageView.clipsToBounds = YES;
                
                [photoLibaryButton sizeToFit];
                
                
                //UIImage *scaledImg = [self getScaledImage:latestPhoto insideButton:photoLibaryButton];
                //[photoLibaryButton setImage:scaledImg forState:UIControlStateNormal];
            }
        }];
    } failureBlock: ^(NSError *error) {
        // Typically you should handle an error more gracefully than this.
        NSLog(@"No groups");
    }];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

/*
 - (void)viewWillDisappear:(BOOL)animated
 {
 [super viewWillDisappear:animated];
 
 // [self.captureSession stopRunning];
 }
 
 - (void)viewWillAppear:(BOOL)animated
 {
 [super viewWillAppear:animated];
 
 //[self.captureSession startRunning];
 }
 */
#pragma mark -
#pragma mark Memory management

- (void)viewDidUnload
{
    self.prevLayer = nil;
    
    [[LeDiscovery sharedInstance] stopScanning];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initCapture
{
    NSError *error = nil;
    
    // Create the session
    self.captureSession = [[AVCaptureSession alloc] init];
    
    
    self.captureSession.sessionPreset = mySessionPreset;
    
    
    //m_device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //input = [AVCaptureDeviceInput deviceInputWithDevice:m_device error:&error];
    
    
    NSArray *devices = [AVCaptureDevice devices];
    
    for (AVCaptureDevice *device in devices) {
        
        NSLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                NSLog(@"Device position : back");
                backCamera = device;
            }
            else {
                NSLog(@"Device position : front");
                frontCamera = device;
            }
        }
    }
    m_device = backCamera;
    input = [AVCaptureDeviceInput deviceInputWithDevice:m_device error:&error];
    
    
    
    [self.captureSession addInput:input];
    
    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [self.captureSession addOutput:output];
    
    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    
    // Specify the pixel format
    output.videoSettings =
    [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    // Start the session running to start the flow of data
    [self.captureSession startRunning];
    
    //建立 AVCaptureStillImageOutput
    myStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *myOutputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [myStillImageOutput setOutputSettings:myOutputSettings];
    [self.captureSession addOutput:myStillImageOutput];
    
    //從 AVCaptureStillImageOutput 中取得正確類型的 AVCaptureConnection
    for (AVCaptureConnection *connection in myStillImageOutput.connections) {
        
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                
                myVideoConnection = connection;
                break;
            }
        }
    }
    
    self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
    self.prevLayer.frame = videoPreviewView.bounds;
    self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //[self.view.layer addSublayer: self.prevLayer];
    [videoPreviewView.layer addSublayer: self.prevLayer];
    
    // Add a single tap gesture to focus on the point tapped, then lock focus
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
    [singleTap setDelegate:self];
    [singleTap setNumberOfTapsRequired:1];
    [videoPreviewView addGestureRecognizer:singleTap];
    
    [self configureCameraForHighestFrameRate];
}

- (void)configureCameraForHighestFrameRate
{
    
    if ( [m_device lockForConfiguration:NULL] == YES ) {
        
        m_device.activeVideoMinFrameDuration = CMTimeMake(1,16);
        m_device.activeVideoMaxFrameDuration = CMTimeMake(1,20);
        [m_device unlockForConfiguration];
        
        NSLog(@"min(%lld) max(%lld)", m_device.activeVideoMinFrameDuration.value, m_device.activeVideoMaxFrameDuration.value);
    }
    /*
     if (myVideoConnection.isVideoMinFrameDurationSupported && myVideoConnection.isVideoMaxFrameDurationSupported) {
     
     myVideoConnection.videoMinFrameDuration = CMTimeMake(1,10);
     myVideoConnection.videoMaxFrameDuration = CMTimeMake(1,16);
     } else {
     
     NSError* error;
     [_captureSession beginConfiguration];
     if ( [m_device lockForConfiguration:&error] ) {
     [m_device setActiveVideoMinFrameDuration:CMTimeMake(1,16)];
     [m_device setActiveVideoMaxFrameDuration:CMTimeMake(1,20)];
     [m_device unlockForConfiguration];
     }
     [_captureSession commitConfiguration];
     }
     */
}


#pragma mark -
#pragma mark AVCaptureSession delegate

// 輸出連續影像
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool {
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        UIImage* image = [UIImage imageWithCGImage:newImage scale:1 orientation:UIImageOrientationRight];
        
        CGImageRelease(newImage);
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            prepareImage = image;
        });
        
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    }
}

// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a m_device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}


//擷取單張靜態影像
- (IBAction)captureStillImage:(id)sender
{
    NSLog(@"captureStillImage");
    
    
    // 打開閃光燈
    if ([m_device hasTorch] && [m_device hasFlash]){
        
        [self.captureSession beginConfiguration];
        [m_device lockForConfiguration:nil];
        if(flashAutoFlag == 1) {
            
            [m_device setTorchMode:AVCaptureTorchModeAuto];
            [m_device setFlashMode:AVCaptureFlashModeAuto];
        } else {
            [m_device setTorchMode:AVCaptureTorchModeOff];
            [m_device setFlashMode:AVCaptureFlashModeOff];
        }
        
        [m_device unlockForConfiguration];
        [self.captureSession commitConfiguration];
    }
    
    
    //self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
   	[myStillImageOutput captureStillImageAsynchronouslyFromConnection:myVideoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        if (error) {
            
            NSLog(@"Take picture failed");
        } else {
            
            //self.captureSession.sessionPreset = mySessionPreset;
            
            // trivial simple JPEG case
            NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                        imageDataSampleBuffer,
                                                                        kCMAttachmentMode_ShouldPropagate);
            
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            
            [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
                
                // 顯示最新的照片
                [self takeLastPhoto];
                
                if (error) {
                    NSLog(@"Save to camera roll failed");
                }
            }];
            
            if (attachments)  CFRelease(attachments);
        }
    }];
    
    // Flash the screen white and fade it out to give UI feedback that a still image was taken
    UIView *flashView = [[UIView alloc] initWithFrame:videoPreviewView.frame];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    [[[self view] window] addSubview:flashView];
    
    [UIView animateWithDuration:.4f
                     animations:^{
                         
                         [flashView setAlpha:0.f];
                     }
                     completion:^(BOOL finished){
                         
                         [flashView removeFromSuperview];
                     }
     ];
    
}

// 切換 camera
- (IBAction)changeCamera:(id)sender
{
    [self toggleCamera];
}


- (BOOL) toggleCamera
{
    BOOL success = NO;
    
    NSError *error;
    AVCaptureDeviceInput *newVideoInput;
    AVCaptureDevicePosition position = [[input device] position];
    
    if (position == AVCaptureDevicePositionBack)
        newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:frontCamera error:&error];
    else if (position == AVCaptureDevicePositionFront)
        newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:backCamera error:&error];
    else
        goto bail;
    
    if (newVideoInput != nil) {
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:input];
        if ([self.captureSession canAddInput:newVideoInput]) {
            [self.captureSession addInput:newVideoInput];
            input = newVideoInput;
        } else {
            [self.captureSession addInput:input];
        }
        [self.captureSession commitConfiguration];
        success = YES;
    } else if (error) {
        
        NSLog(@"%@", error);
    }
    
bail:
    return success;
}

- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[input device] isFocusPointOfInterestSupported]) {
        
        CGPoint tapPoint = [gestureRecognizer locationInView:videoPreviewView];
        
        [self setAutoFocusByPoints:tapPoint];
    }
}

- (void) setAutoFocusByPoints:(CGPoint) tapPoint
{
    CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
    [self autoFocusAtPoint:convertedFocusPoint];
    
    // 顯示 焦點方框
    [self drawFocusRect:CGRectMake(tapPoint.x-50, tapPoint.y-50, 100, 100)];
}

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = [videoPreviewView frame].size;
    
    if ( [[self.prevLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
        
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [input ports]) {
            
            if ([port mediaType] == AVMediaTypeVideo) {
                
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [[self.prevLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    
                    if (viewRatio > apertureRatio) {
                        
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
						// If point is inside letterboxed area, do coordinate conversion; otherwise, don't change the default value returned (.5,.5)
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
                            
							// Scale (accounting for the letterboxing on the left and right of the video preview), switch x and y, and reverse x
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
						// If point is inside letterboxed area, do coordinate conversion. Otherwise, don't change the default value returned (.5,.5)
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
                            
							// Scale (accounting for the letterboxing on the top and bottom of the video preview), switch x and y, and reverse x
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[self.prevLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    
					// Scale, switch x and y, and reverse x
                    if (viewRatio > apertureRatio) {
                        
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2; // Account for cropped height
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2); // Account for cropped width
                        xc = point.y / frameSize.height;
                    }
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}

- (void) autoFocusAtPoint:(CGPoint)point
{
    m_device = [input device];
    if ([m_device isFocusPointOfInterestSupported] && [m_device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        
        NSError *error;
        if ([m_device lockForConfiguration:&error]) {
            
            [m_device setFocusPointOfInterest:point];
            [m_device setFocusMode:AVCaptureFocusModeAutoFocus];
            [m_device unlockForConfiguration];
        } else {
            
            NSLog(@"autoFocusAtPoint Fail!!");
        }
    }
}

// 顯示 焦點方框
-(void) drawFocusRect:(CGRect)rect
{
    UIView *test = [[UIView alloc] initWithFrame:rect];
    test.layer.borderColor = [UIColor yellowColor].CGColor;
    test.layer.borderWidth = 2;
    [[[self view] window] addSubview:test];
    
    [UIView animateWithDuration:1.5f
                     animations:^{
                         
                         [test setAlpha:0.f];
                     }
                     completion:^(BOOL finished){
                         
                         [test removeFromSuperview];
                     }
     ];
}

- (void) startTimer
{
    [self stopTimer];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        timer = [NSTimer timerWithTimeInterval:0.1
                                        target:self
                                      selector:@selector(onTickToSend)
                                      userInfo:nil
                                       repeats:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        });
    });
}

- (void) onTickToSend
{
    if(appDelegate.isConnected == YES ) {
        
        //NSDate *start = [NSDate date];
        //NSTimeInterval time1 = [start timeIntervalSinceNow];
        
        UIImage* image = [prepareImage resizedImage:CGSizeMake(320, 480) interpolationQuality:kCGInterpolationNone];
        
        //NSTimeInterval time2 = [start timeIntervalSinceNow];
        
        NSData *imageData = UIImageJPEGRepresentation(image, 0);   // 圖片壓縮比
        
        //NSTimeInterval time3 = [start timeIntervalSinceNow];
        
        //NSLog(@"width(%f) height(%f) imageData(%d)", image.size.width, image.size.height, [imageData length]);
        
        
        Packet *myPacket;
        myPacket = [[Packet alloc] sendImageDataPacket:imageData];
        
        NSMutableData *data = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:myPacket forKey:AVCamArchiveKey];
        [archiver finishEncoding];
        
        // 送出 image data
        [appDelegate sendData:data withDataMode:GKSendDataUnreliable];
        
        //NSTimeInterval time4 = [start timeIntervalSinceNow];
        
        //NSLog(@"1(%f) 2(%f) 3(%f) total(%f)", time2 - time1, time3 - time2, time4 - time3, time4 - time1);
    }
}

- (void) stopTimer
{
    if (timer) {
        
        [timer invalidate];
        timer = nil;
    }
}


- (IBAction) showSavedMediaBrowser
{
    [self startMediaBrowserFromViewController: self
                                usingDelegate: self];
}


- (BOOL) startMediaBrowserFromViewController: (UIViewController*) controller
                               usingDelegate: (id <UIImagePickerControllerDelegate,
                                               UINavigationControllerDelegate>) delegate
{
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)
        || (delegate == nil)
        || (controller == nil))
        return NO;
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    
    // Displays saved pictures and movies, if both are available, from the
    // Camera Roll album.
    mediaUI.mediaTypes =
    [UIImagePickerController availableMediaTypesForSourceType:
     UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    mediaUI.allowsEditing = NO;
    
    mediaUI.delegate = delegate;
    
    mediaUI.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    //mediaUI.navigationBar.barTintColor = [UIColor clearColor];// .alpha = 0.1;
    //mediaUI.navigationBar.backgroundColor = [UIColor clearColor];
    
    //mediaUI.wantsFullScreenLayout = YES;
    //mediaUI.cameraViewTransform = CGAffineTransformScale(_picker.cameraViewTransform, CAMERA_TRANSFORM, CAMERA_TRANSFORM);
    
    
    [controller presentViewController:mediaUI animated:YES completion:nil];
    
    return YES;
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    //設定影像
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    ImageEditViewController *imageEditViewController = [storyboard instantiateViewControllerWithIdentifier:@"ImageEditViewController"];
    [imageEditViewController setImage:image];
    
    [picker pushViewController:imageEditViewController animated:YES];
}

- (IBAction)flashButton:(id)sender {
    
    if([segmentControl isHidden]) {
        [segmentControl setHidden:NO];
        [infoLabel setHidden:YES];
    } else {
        [segmentControl setHidden:YES];
        [infoLabel setHidden:NO];
    }
    
}

- (IBAction)valueChanged:(id)sender {
    
    NSLog(@"segmentControl.selectedSegmentIndex(%d)", segmentControl.selectedSegmentIndex);
    switch (segmentControl.selectedSegmentIndex) {
        case 0:
            NSLog(@"Auto");
            flashAutoFlag = 1;
            break;
        case 1:
            NSLog(@"Off");
            flashAutoFlag = 0;
            break;
        default:
            break;
    }
}



#pragma mark -
#pragma mark LeDiscoveryDelegate
/****************************************************************************/
/*                       LeDiscoveryDelegate Methods                        */
/****************************************************************************/
- (void) discoveryDidRefresh
{
    //[sensorsTable reloadData];
    NSLog(@"discoveryDidRefresh");
    [[LeDiscovery sharedInstance] stopScanning];
}

- (void) discoveryStatePoweredOff
{
    NSString *title     = @"Bluetooth Power";
    NSString *message   = @"You must turn on Bluetooth in Settings in order to use LE";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    //[alertView release];
    
}


- (void) alarmService:(LeTemperatureAlarmService*)service didSoundAlarmOfType:(AlarmType)alarm {}
- (void) alarmServiceDidStopAlarm:(LeTemperatureAlarmService*)service {}
- (void) alarmServiceDidChangeTemperature:(LeTemperatureAlarmService*)service {}
- (void) alarmServiceDidChangeTemperatureBounds:(LeTemperatureAlarmService*)service {}
- (void) alarmServiceDidChangeStatus:(LeTemperatureAlarmService*)service {}
- (void) alarmServiceDidReset {}
@end
