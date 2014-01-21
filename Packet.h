#import <Foundation/Foundation.h>
#import "PacketEnum.h"

@interface Packet : NSObject <NSCoding>

@property (nonatomic) PacketType type;
@property (nonatomic, copy) NSData *sendData;

-(id)initWithType:(PacketType)aPacketType withData:(NSData*)data;


-(id)sendImageDataPacket:(NSData*)imageData;    // 傳送影像data
-(id)sendTakePhotoPacket;                       // 呼叫遠端拍照
-(id)sendStartSendPacket;                       // 呼叫遠端開始傳送影像
-(id)sendStopSendPacket;                        // 呼叫遠端停止傳送影像
-(id)sendSetFocusPacket:(NSData*)__data;        // 呼叫遠端設定焦點
-(id)sendDisconnectPacket;                      // 呼叫停止連線

@end
