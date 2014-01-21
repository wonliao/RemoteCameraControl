//
//  AppDelegate.m
//  RemoteCamera
//
//  Created by wonliao on 13/9/20.
//  Copyright (c) 2013年 wonliao. All rights reserved.
//
#import <zlib.h>

#import "AppDelegate.h"

#import "NSData+Base64.h"

#import "SecondViewController.h"

#import "CHDraggableView.h"
#import "CHDraggableView+Avatar.h"

#import "Packet.h"

#import "ViewController.h"


@implementation AppDelegate

@synthesize isConnected;
@synthesize currentSession;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    draggableView = [CHDraggableView draggableViewWithImage:[UIImage imageNamed:@"avatar.png"]];
    draggableView.tag = 1;
    
    _draggingCoordinator = [[CHDraggingCoordinator alloc] initWithWindow:self.window draggableViewBounds:draggableView.bounds];
    _draggingCoordinator.delegate = self;
    _draggingCoordinator.snappingEdge = CHSnappingEdgeBoth;
    draggableView.delegate = _draggingCoordinator;
    //[draggableView setHidden:YES];
    
    //[draggableView lightViewSetHidden:NO];
    
    [self.window.rootViewController.view addSubview:draggableView];
    
    CGRect frame = self.window.rootViewController.view.frame;
    float x = frame.size.width-66;
    NSLog(@"width(%f) x(%f)", frame.size.width, x);
    [draggableView setFrame:CGRectMake(x, 60, 66, 66)];
    
    isConnected = NO;
    //[self searchPeer];  // bluetooth
    
    
    
    
    
    return YES;
}



- (UIViewController *)draggingCoordinator:(CHDraggingCoordinator *)coordinator viewControllerForDraggableView:(CHDraggableView *)draggableView
{
    return [[SecondViewController alloc] initWithNibName:@"SecondViewController" bundle:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [currentSession disconnectFromAllPeers];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    
    [self searchPeer];  // bluetooth
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [currentSession disconnectFromAllPeers];
}




- (NSData *)getImageData
{
    return m_imageData;
}

#pragma mark -- GameKit --

- (void) searchPeer
{
	NSLog(@"Search Peer.");
    
	currentSession = [[GKSession alloc] initWithSessionID:@"P2P"
                                              displayName:nil
                                              sessionMode:GKSessionModePeer];
    
	currentSession.delegate = self;
	[currentSession setDataReceiveHandler:self withContext:nil];
    
    currentSession.disconnectTimeout = 5;
	currentSession.available = YES;
    
}

- (void) receiveData:(NSData *)data
            fromPeer:(NSString *)peer
           inSession: (GKSession *)session
             context:(void *)context
{
	//NSLog(@"receive %d(bytes)", [data length]);
    NSData* data2 = [self gzipInflate:data];
    //NSLog(@"receive bytes(%d)(%d)", [data length], [data2 length]);
    
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data2];
    Packet *packet = [unarchiver decodeObjectForKey:AVCamArchiveKey];
    switch (packet.type)
    {
        case kPacketTypeImageData:  // 傳送影像data
        {
            m_imageData = packet.sendData;
            break;
        }
        case kPacketTypeTakePhoto:  // 呼叫遠端拍照
        {
            ViewController *rootViewController = (ViewController*)self.window.rootViewController;
            [rootViewController captureStillImage:nil];
            break;
        }
        case kPacketTypeStartSend:  // 呼叫遠端開始傳送影像
        {
            [self callViewControllerStartSend];
            [draggableView closeDraggableView];
            
            break;
        }
        case kPacketTypeStopSend:   // 呼叫遠端停止傳送影像
        {
            [self callViewControllerStopSend];
            break;
        }
        case kPacketTypeSetFocus:    // 呼叫遠端設定焦點
        {
            NSString *str = [[NSString alloc] initWithData:packet.sendData encoding:NSUTF8StringEncoding];
            NSLog(@"str(%@)", str);
            NSArray *pos = [str componentsSeparatedByString:@","];
            int x = [[pos objectAtIndex:0] intValue];
            int y = [[pos objectAtIndex:1] intValue];
            NSLog(@"x(%d), y(%d)", x , y);
            
            ViewController *rootViewController = (ViewController*)self.window.rootViewController;
            [rootViewController setAutoFocusByPoints:CGPointMake(x, y)];
            break;
        }
        case kPacketTypeReset:
        {
            break;
        }
        case kPacketTypeDisconnect:
        {
            [draggableView closeDraggableView];
            [session disconnectFromAllPeers];
            break;
        }
    }
    
}

- (void) sendData:(NSData *)data withDataMode:(GKSendDataMode)mode
{
    NSData* data2 = [self gzipDeflate:data];
    //NSData* data2 = data;
    //NSLog(@"send bytes(%d)(%d)", [data length], [data2 length]);
    
    
    [currentSession sendDataToAllPeers:data2 withDataMode:mode error:nil];
}

#pragma mark -- GKSessionDelegate --

- (void) session:(GKSession *)session
didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
	//NSLog(@"Request From %@.", peerID);
    
	[session acceptConnectionFromPeer:peerID error:nil];
}

- (void) session:(GKSession *)session
            peer:(NSString *)peerID
  didChangeState:(GKPeerConnectionState)state
{
	//	ピアの状態
	//	0:GKPeerStateAvailable    有効(接続前)
	//	1:GKPeerStateUnavailable  無効
	//	2:GKPeerStateConnected    接続している
	//	3:GKPeerStateDisconnected 接続を切断
	//	4:GKPeerStateConnecting   接続許可を待機中/応答なし
	NSArray *states = [NSArray arrayWithObjects:@"Available", @"Unavailable", @"Connected", @"Disconnected", @"Connecting", nil];
	
	// ステータスを更新
	NSLog(@"%@ State %@", peerID, [states objectAtIndex:state]);
	
    ViewController *rootViewController = (ViewController*)self.window.rootViewController;
    
	switch (state) {
		case GKPeerStateAvailable:
			// ステータスを更新
			NSLog(@"Connect to %@.", peerID);
			// ピアに接続
			[session connectToPeer:peerID withTimeout:5];
            rootViewController.infoLabel.text = @"connecting";
			break;
        case GKPeerStateConnected:
            self.isConnected = YES;
            //[draggableView setHidden:NO];
            [draggableView lightViewSetHidden:NO];
            rootViewController.infoLabel.text = @"connected";
            
            [self startTimer];
            
            break;
        case GKPeerStateDisconnected:
            [session disconnectFromAllPeers];
            [self callViewControllerStopSend];
        case GKPeerStateConnecting:
        case GKPeerStateUnavailable:
            self.isConnected = NO;
            //[draggableView setHidden:YES];
            [draggableView lightViewSetHidden:YES];
            [draggableView closeDraggableView];
            ViewController *rootViewController = (ViewController*)self.window.rootViewController;
            rootViewController.infoLabel.text = @"waiting for connect";
            break;
	}
}

- (void) startTimer
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSTimer *timer = [NSTimer timerWithTimeInterval:3.0
                                                 target:self
                                               selector:@selector(timerFired)
                                               userInfo:nil
                                                repeats:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        });
    });
}

- (void) timerFired
{
    ViewController *rootViewController = (ViewController*)self.window.rootViewController;
    rootViewController.infoLabel.text = @"";
}

- (NSData *)gzipInflate:(NSData*)data
{
    if ([data length] == 0) return data;
    
    unsigned full_length = [data length];
    unsigned half_length = [data length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef *)[data bytes];
    strm.avail_in = [data length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
    while (!done)
    {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length])
            [decompressed increaseLengthBy: half_length];
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = [decompressed length] - strm.total_out;
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) done = YES;
        else if (status != Z_OK) break;
    }
    if (inflateEnd (&strm) != Z_OK) return nil;
    
    // Set real length.
    if (done)
    {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    }
    else return nil;
}

- (NSData *)gzipDeflate:(NSData*)data
{
    if ([data length] == 0) return data;
    
    z_stream strm;
    
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef *)[data bytes];
    strm.avail_in = [data length];
    
    // Compresssion Levels:
    //   Z_NO_COMPRESSION
    //   Z_BEST_SPEED
    //   Z_BEST_COMPRESSION
    //   Z_DEFAULT_COMPRESSION
    
    if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
    
    NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
    
    do {
        
        if (strm.total_out >= [compressed length])
            [compressed increaseLengthBy: 16384];
        
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = [compressed length] - strm.total_out;
        
        deflate(&strm, Z_FINISH);
        
    } while (strm.avail_out == 0);
    
    deflateEnd(&strm);
    
    [compressed setLength: strm.total_out];
    return [NSData dataWithData:compressed];
}

- (void) bluetoothStartSend
{
    Packet *myPacket;
    myPacket = [[Packet alloc] sendStartSendPacket];
    
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:myPacket forKey:AVCamArchiveKey];
    [archiver finishEncoding];
    
    // 送出 image data
    [self sendData:data withDataMode:GKSendDataReliable];
}

- (void) bluetoothStopSend
{
    Packet *myPacket;
    myPacket = [[Packet alloc] sendStopSendPacket];
    
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:myPacket forKey:AVCamArchiveKey];
    [archiver finishEncoding];
    
    // 送出 image data
    [self sendData:data withDataMode:GKSendDataReliable];
}

- (void) callViewControllerStartSend
{
    NSLog(@"callViewControllerStartSend");
    ViewController *rootViewController = (ViewController*)self.window.rootViewController;
    [rootViewController startTimer];
}

- (void) callViewControllerStopSend
{
    NSLog(@"callViewControllerStopSend");
    ViewController *rootViewController = (ViewController*)self.window.rootViewController;
    [rootViewController stopTimer];
}

@end
