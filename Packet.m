#import "Packet.h"

#import "NSData+Base64.h"

@implementation Packet



-(id)initWithType:(PacketType)aPacketType withData:(NSData*)data
{
    if(self = [super init]){
        self.type = aPacketType;
        self.sendData = data;
    }
    return self;
}

#pragma mark NSCoder Methods
-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:[self type] forKey:kArchivingTagType];
    [aCoder encodeObject:[self sendData] forKey:kArchivingTagImageData];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super init]){
        
        [self setType:[aDecoder decodeIntForKey:kArchivingTagType]];
        [self setSendData:[aDecoder decodeObjectForKey:kArchivingTagImageData]];
    }
    
    return self;
}



// 傳送影像data
-(id)sendImageDataPacket:(NSData*)__imageData
{
    return [self initWithType:kPacketTypeImageData withData:__imageData];
}

// 呼叫遠端拍照
-(id)sendTakePhotoPacket
{
    return [self initWithType:kPacketTypeTakePhoto withData:nil];
}

// 呼叫遠端開始傳送影像
-(id)sendStartSendPacket
{
    return [self initWithType:kPacketTypeStartSend withData:nil];
}

// 呼叫遠端停止傳送影像
-(id)sendStopSendPacket
{
    return [self initWithType:kPacketTypeStopSend withData:nil];
}

// 呼叫遠端設定焦點
-(id)sendSetFocusPacket:(NSData*)__data
{    
    return [self initWithType:kPacketTypeSetFocus withData:__data];
}

// 呼叫停止連線
-(id)sendDisconnectPacket
{
    return [self initWithType:kPacketTypeDisconnect withData:nil];
}

@end
