#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(PreviewVideo, NSObject)

RCT_EXTERN_METHOD(showPreviewVideo:(NSDictionary *)data
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
