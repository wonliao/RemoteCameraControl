//
//  ViewController.h
//  test2
//
//  Created by wonliao on 13/9/11.
//  Copyright (c) 2013年 wonliao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/CGImageSource.h>
#import <ImageIO/CGImageProperties.h>

#import "AppDelegate.h"

#import "LeDiscovery.h"
#import "LeTemperatureAlarmService.h"


@interface ViewController : UIViewController <
AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, LeDiscoveryDelegate, LeTemperatureAlarmProtocol> {
    
    AppDelegate *appDelegate;
    
    AVCaptureSession *_captureSession;
    AVCaptureVideoPreviewLayer *_prevLayer;
    IBOutlet UIView *videoPreviewView;
    
    AVCaptureStillImageOutput *myStillImageOutput;
    AVCaptureConnection *myVideoConnection;
    AVCaptureDevice *m_device;
    AVCaptureDeviceInput *input;
    
    NSString *mySessionPreset;
    
    NSTimer *timer;
    UIImage *prepareImage;
    
    IBOutlet UIButton *photoButton;
    
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    int flashAutoFlag;
    
    //IBOutlet UIImageView *editImageView;
    IBOutlet UIButton *photoLibaryButton;
    
    IBOutlet UILabel *infoLabel;
}

@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *prevLayer;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (strong, nonatomic) UILabel *infoLabel;

- (IBAction)captureStillImage:(id)sender;
- (IBAction)changeCamera:(id)sender;
- (IBAction)showSavedMediaBrowser;
- (IBAction)flashButton:(id)sender;
- (IBAction)valueChanged:(id)sender;


- (void)setAutoFocusByPoints:(CGPoint) tapPoint;
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
- (void)initCapture;
- (void)startTimer;
- (void)stopTimer;
@end
