#import "NfcInFlutterPlugin.h"

#if TARGET_OS_IOS
#import <CoreNFC/CoreNFC.h>
#endif

@implementation NfcInFlutterPlugin {
    dispatch_queue_t dispatchQueue;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    dispatch_queue_t dispatchQueue = dispatch_queue_create("me.andisemler.nfc_in_flutter.dispatch_queue", NULL);
    
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"nfc_in_flutter"
                                     binaryMessenger:[registrar messenger]];
    
    FlutterEventChannel* tagChannel = [FlutterEventChannel
                                       eventChannelWithName:@"nfc_in_flutter/tags"
                                       binaryMessenger:[registrar messenger]];
    
    NfcInFlutterPlugin* instance = [[NfcInFlutterPlugin alloc]
                                    init:dispatchQueue
                                    channel:channel];
  
    [registrar addMethodCallDelegate:instance channel:channel];
    [tagChannel setStreamHandler:instance->wrapper];
}
    
- (id)init:(dispatch_queue_t)dispatchQueue channel:(FlutterMethodChannel*)channel {
    self->dispatchQueue = dispatchQueue;
#if TARGET_OS_IOS
    if (@available(iOS 13.0, *)) {
        wrapper = [[NFCWritableWrapperImpl alloc] init:channel dispatchQueue:dispatchQueue];
    } else if (@available(iOS 11.0, *)) {
        wrapper = [[NFCWrapperImpl alloc] init:channel dispatchQueue:dispatchQueue];
    } else {
        wrapper = [[NFCUnsupportedWrapper alloc] init];
    }
#else
    // No-op for non-iOS platforms
    wrapper = nil;
#endif
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    dispatch_async(dispatchQueue, ^{
        [self handleMethodCallAsync:call result:result];
    });
}

- (void)handleMethodCallAsync:(FlutterMethodCall*)call result:(FlutterResult)result {
#if TARGET_OS_IOS
    if ([@"readNDEFSupported" isEqualToString:call.method]) {
        result([NSNumber numberWithBool:[wrapper isEnabled]]);
    } else if ([@"startNDEFReading" isEqualToString:call.method]) {
        NSDictionary* args = call.arguments;
        [wrapper startReading:[args[@"scan_once"] boolValue] alertMessage:args[@"alert_message"]];
        result(nil);
    } else if ([@"writeNDEF" isEqualToString:call.method]) {
        NSDictionary* args = call.arguments;
        [wrapper writeToTag:args completionHandler:^(FlutterError * _Nullable error) {
            result(error);
        }];
    } else {
        result(FlutterMethodNotImplemented);
    }
#else
    // No-op for non-iOS platforms
    result(FlutterMethodNotImplemented);
#endif
}

@end
