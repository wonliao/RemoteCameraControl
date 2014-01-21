//
//  SecondViewController.h
//  RemoteCamera
//
//  Created by wonliao on 13/9/20.
//  Copyright (c) 2013年 wonliao. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"



@interface SecondViewController : UIViewController <UIGestureRecognizerDelegate> {
    
    AppDelegate *appDelegate;

    IBOutlet UIImageView *imagePreviewView;
    
    NSTimer *timer;

}

- (IBAction)takePhoto:(id)sender;


@end
