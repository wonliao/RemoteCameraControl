#ifndef AVCam_AVCam_h
#define AVCam_AVCam_h

#define AVCamSessionID     @"com.apporchard.AVCam.session"
#define AVCamArchiveKey    @"com.apporchard.AVCam"

#define kArchivingTagType           @"PacketType"
#define kArchivingTagImageData      @"ImageData"

typedef enum PacketTypes{
    kPacketTypeImageData,   // 傳送影像data
    kPacketTypeTakePhoto,   // 呼叫遠端拍照
    kPacketTypeStartSend,   // 呼叫遠端開始傳送影像
    kPacketTypeStopSend,    // 呼叫遠端停止傳送影像
    kPacketTypeSetFocus,    // 呼叫遠端設定焦點
    
    kPacketTypeReset,
    kPacketTypeDisconnect   // 呼叫停止連線
}PacketType;

#endif
