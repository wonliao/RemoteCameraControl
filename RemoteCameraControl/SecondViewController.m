//
//  SecondViewController.m
//  RemoteCamera
//
//  Created by wonliao on 13/9/20.
//  Copyright (c) 2013年 wonliao. All rights reserved.
//

#import "SecondViewController.h"

#import "NSData+Base64.h"

#import "Packet.h"


@interface SecondViewController ()

@end

@implementation SecondViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bannerTapped:)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    [imagePreviewView addGestureRecognizer:singleTap];
    [imagePreviewView setUserInteractionEnabled:YES];
    
    [self startTimer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) startTimer
{
    [self stopTimer];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        timer = [NSTimer timerWithTimeInterval:0.1//0.0625
                                        target:self
                                      selector:@selector(onTickToDraw)
                                      userInfo:nil
                                       repeats:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        });
    });
}

- (void) onTickToDraw
{
    //NSLog(@"onTickToDraw");

    if(appDelegate.isConnected == YES) {

        NSData *imageData = [appDelegate getImageData];
        if([imageData length] > 0) {

            // 還原圖片
            UIImage *image = [UIImage imageWithData:imageData];
            [imagePreviewView setImage:image];
        }
    }
}

- (void) stopTimer
{
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
}


- (IBAction)takePhoto:(id)sender
{
    Packet *myPacket;
    myPacket = [[Packet alloc] sendTakePhotoPacket];

    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:myPacket forKey:AVCamArchiveKey];
    [archiver finishEncoding];
    
    // 呼叫遠端拍照
    [appDelegate sendData:data withDataMode:GKSendDataReliable];
    
    
    // Flash the screen white and fade it out to give UI feedback that a still image was taken
    UIView *flashView = [[UIView alloc] initWithFrame:imagePreviewView.frame];
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

- (void)bannerTapped:(UIGestureRecognizer *)gestureRecognizer
{
    //NSLog(@"%@", [gestureRecognizer view]);

    CGPoint location = [gestureRecognizer locationInView:gestureRecognizer.view];
    NSLog(@"x(%f) y(%f)", location.x, location.y);
    
    NSString* str = [NSString stringWithFormat:@"%d,%d", (int)location.x, (int)location.y];
    NSData *posData = [str dataUsingEncoding: NSUTF8StringEncoding];

    
    Packet *myPacket;
    myPacket = [[Packet alloc] sendSetFocusPacket:posData];

    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:myPacket forKey:AVCamArchiveKey];
    [archiver finishEncoding];

    // 呼叫遠端設定焦點
    [appDelegate sendData:data withDataMode:GKSendDataReliable];

    // 顯示 焦點方框
    [self drawFocusRect:CGRectMake(location.x-50, location.y-50, 100, 100)];
}

// 顯示 焦點方框
-(void) drawFocusRect:(CGRect)rect
{
    UIView *test = [[UIView alloc] initWithFrame:rect];
    test.layer.borderColor = [UIColor yellowColor].CGColor;
    test.layer.borderWidth = 2;
    [imagePreviewView addSubview:test];

    [UIView animateWithDuration:1.5f
                     animations:^{
                         [test setAlpha:0.f];
                     }
                     completion:^(BOOL finished){
                         [test removeFromSuperview];
                     }
     ];
}


@end
