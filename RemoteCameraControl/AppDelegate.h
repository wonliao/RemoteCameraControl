//
//  AppDelegate.h
//  RemoteCamera
//
//  Created by wonliao on 13/9/20.
//  Copyright (c) 2013年 wonliao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

#import "CHDraggingCoordinator.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, CHDraggingCoordinatorDelegate, GKSessionDelegate> {
    
    //IBOutlet UIView *m_mainView;
    //IBOutlet UIView *videoPreviewView;
    
    BOOL isConnected;
    
    GKSession *currentSession;  // bluetooth
    
    NSData* m_imageData;
    
    CHDraggableView *draggableView;
}


@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CHDraggingCoordinator *draggingCoordinator;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, retain) GKSession *currentSession;    // bluetooth


- (void) searchPeer;                // bluetooth
- (void) sendData:(NSData *)data withDataMode:(GKSendDataMode)mode;   // bluetooth
- (NSData *)getImageData;           // bluetooth
- (void) bluetoothStartSend;
- (void) bluetoothStopSend;
- (void) callViewControllerStartSend;

@end
