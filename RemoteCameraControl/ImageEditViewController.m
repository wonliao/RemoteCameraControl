//
//  ImageEditViewController.m
//  RemoteCamera
//
//  Created by wonliao on 13/9/30.
//  Copyright (c) 2013年 wonliao. All rights reserved.
//

#import "ImageEditViewController.h"

@interface ImageEditViewController ()

@end

@implementation ImageEditViewController
@synthesize editImageView;

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
	// Do any additional setup after loading the view.
    
    if(tempImage != NULL) {
    
        [editImageView setImage:tempImage];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) setImage:(UIImage*)img
{
    //[editImageView setImage:img];
    tempImage = img;
}

@end
