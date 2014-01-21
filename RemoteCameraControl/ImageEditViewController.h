//
//  ImageEditViewController.h
//  RemoteCamera
//
//  Created by wonliao on 13/9/30.
//  Copyright (c) 2013年 wonliao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageEditViewController : UIViewController {
    
    IBOutlet UIImageView *editImageView;
    
    UIImage* tempImage;
}

@property (strong, nonatomic) IBOutlet UIImageView *editImageView;

-(void) setImage:(UIImage*)img;

@end
