#import <objc/runtime.h>
#import "CRKH00kEntry+OSAPI.h"
#import "CRKInjectContext.h"
#import "CRKHookClasses.h"

@import WebKit.WKWebViewConfiguration;
//@import UIKit;

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"

@interface UIScrollView (iOS11)

@property(nonatomic) NSInteger contentInsetAdjustmentBehavior;
@property(nonatomic, readonly) UIEdgeInsets adjustedContentInset;

@end

@interface NSObject (AVAudioSession_iOS10)

- (BOOL)setCategory:(NSString *)category mode:(id)mode options:(NSUInteger)options error:(NSError * _Nullable *)outError;

@end

@interface NSObject (AVPlayer_iOS10)

@property(nonatomic) BOOL automaticallyWaitsToMinimizeStalling;
@property(nonatomic) NSInteger timeControlStatus;

@end

@implementation CRKH00kEntry (OSAPI)

/**
 * Handle crashes caused by different OS version:
 * https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100
 * https://nshipster.com/type-encodings/
 */
- (void)hookOSAPIs {
    // UIPlaceHolderColor
    Class clazz = objc_getClass("UIPlaceholderColor");
    __unused Class metaClazz = objc_getMetaClass("UIPlaceholderColor");

    if (clazz && ![[CRKInjectContext shared].origSystemVersion hasPrefix:@"10."]) {
        if (!class_getInstanceMethod(clazz, @selector(initWithDisplayP3Red:green:blue:alpha:))) {
            class_addMethod(clazz,
                    @selector(initWithDisplayP3Red:green:blue:alpha:),
                    (IMP) &_logos_method$_ungrouped$UIPlaceholderColor$initWithDisplayP3Red$green$blue$alpha$,
                    "@@:ffff"
            );
        }
    }

    // WKWebViewConfiguration
    clazz = [WKWebViewConfiguration class];
    if (clazz && !class_getInstanceMethod(clazz, @selector(setMediaTypesRequiringUserActionForPlayback:))) {
        class_addMethod(clazz,
                @selector(setMediaTypesRequiringUserActionForPlayback:),
                (IMP) &_logos_method$_ungrouped$WKWebViewConfiguration$setMediaTypesRequiringUserActionForPlayback$,
                "v@:I");
    }

    // UIScrollView
    clazz = objc_getClass("UIScrollView");
    metaClazz = objc_getMetaClass("UIScrollView");

    if (clazz && ![[CRKInjectContext shared].origSystemVersion hasPrefix:@"11."]) {
        if (!class_getInstanceMethod(clazz, @selector(setContentInsetAdjustmentBehavior:))) {
            class_addMethod(clazz,
                    @selector(setContentInsetAdjustmentBehavior:),
                    (IMP) &_logos_method$_ungrouped$UIScrollView$setContentInsetAdjustmentBehavior$,
                    "v@:i"
            );
        }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
        @selector(setAutomaticallyAdjustsScrollViewInsets:);
#pragma clang diagnostic pop

        if (!class_getInstanceMethod(clazz, @selector(adjustedContentInset))) {
            class_addMethod(clazz,
                    @selector(adjustedContentInset),
                    (IMP) &_logos_method$_ungrouped$UIScrollView$adjustedContentInset,
                    "{UIEdgeInsets=ffff}@:"
            );
        }
    }

    // UIPasteboard
    clazz = objc_getClass("UIPasteboard");
    metaClazz = objc_getMetaClass("UIPasteboard");

    if (clazz && ![[CRKInjectContext shared].origSystemVersion hasPrefix:@"10."]) {
        if (!class_getInstanceMethod(clazz, @selector(hasStrings))) {
            class_addMethod(clazz,
                    @selector(hasStrings),
                    (IMP) &_logos_method$_ungrouped$UIPasteboard$hasStrings,
                    "B@:"
            );
        }

        if (!class_getInstanceMethod(clazz, @selector(hasURLs))) {
            class_addMethod(clazz,
                    @selector(hasURLs),
                    (IMP) &_logos_method$_ungrouped$UIPasteboard$hasURLs,
                    "B@:"
            );
        }

        if (!class_getInstanceMethod(clazz, @selector(hasImages))) {
            class_addMethod(clazz,
                    @selector(hasImages),
                    (IMP) &_logos_method$_ungrouped$UIPasteboard$hasImages,
                    "B@:"
            );
        }

        if (!class_getInstanceMethod(clazz, @selector(hasColors))) {
            class_addMethod(clazz,
                    @selector(hasColors),
                    (IMP) &_logos_method$_ungrouped$UIPasteboard$hasColors,
                    "B@:"
            );
        }
    }

    // AVAudioSession
    clazz = objc_getClass("AVAudioSession");
    metaClazz = objc_getMetaClass("AVAudioSession");

    if (clazz && ![[CRKInjectContext shared].origSystemVersion hasPrefix:@"10."]) {
        if (!class_getInstanceMethod(clazz, @selector(setCategory:mode:options:error:))) {
            class_addMethod(clazz,
                    @selector(setCategory:mode:options:error:),
                    (IMP) &_logos_method$_ungrouped$AVAudioSession$setCategory$mode$options$error$,
                    "B@:@@I^@");
        }
    }

    // AVPlayer
    clazz = objc_getClass("AVPlayer");
    metaClazz = objc_getMetaClass("AVPlayer");

    if (clazz && ![[CRKInjectContext shared].origSystemVersion hasPrefix:@"10."]) {
        if (!class_getInstanceMethod(clazz, @selector(automaticallyWaitsToMinimizeStalling))) {
            class_addMethod(clazz,
                    @selector(automaticallyWaitsToMinimizeStalling),
                    (IMP) &_logos_method$_ungrouped$AVPlayer$automaticallyWaitsToMinimizeStalling,
                    "B@:");
        }

        if (!class_getInstanceMethod(clazz, @selector(setAutomaticallyWaitsToMinimizeStalling:))) {
            class_addMethod(clazz,
                    @selector(setAutomaticallyWaitsToMinimizeStalling:),
                    (IMP) &_logos_method$_ungrouped$AVPlayer$setAutomaticallyWaitsToMinimizeStalling$,
                    "v@:B");
        }

        if (!class_getInstanceMethod(clazz, @selector(timeControlStatus))) {
            class_addMethod(clazz,
                    @selector(timeControlStatus),
                    (IMP) &_logos_method$_ungrouped$AVPlayer$timeControlStatus,
                    "i@:");
        }

        if (!class_getInstanceMethod(clazz, @selector(setTimeControlStatus:))) {
            class_addMethod(clazz,
                    @selector(setTimeControlStatus:),
                    (IMP) &_logos_method$_ungrouped$AVPlayer$setTimeControlStatus$,
                    "v@:i");
        }
    }

    // AVPlayerItem
    clazz = objc_getClass("AVPlayerItem");
    metaClazz = objc_getMetaClass("AVPlayerItem");

    if (clazz && ![[CRKInjectContext shared].origSystemVersion hasPrefix:@"10."]) {
        if (!class_getInstanceMethod(clazz, @selector(preferredForwardBufferDuration))) {
            class_addMethod(clazz,
                    @selector(preferredForwardBufferDuration),
                    (IMP) &_logos_method$_ungrouped$AVPlayerItem$preferredForwardBufferDuration,
                    "d@:");
        }

        if (!class_getInstanceMethod(clazz, @selector(setPreferredForwardBufferDuration:))) {
            class_addMethod(clazz,
                    @selector(setPreferredForwardBufferDuration:),
                    (IMP) &_logos_method$_ungrouped$AVPlayerItem$setPreferredForwardBufferDuration$,
                    "v@:d");
        }
    }

    // AVPlayerItemAccessLogEvent
    clazz = objc_getClass("AVPlayerItemAccessLogEvent");
    metaClazz = objc_getMetaClass("AVPlayerItemAccessLogEvent");

    if (clazz && ![[CRKInjectContext shared].origSystemVersion hasPrefix:@"10."]) {
        if (!class_getInstanceMethod(clazz, @selector(indicatedAverageBitrate))) {
            class_addMethod(clazz,
                    @selector(indicatedAverageBitrate),
                    (IMP) &_logos_method$_ungrouped$AVPlayerItemAccessLogEvent$indicatedAverageBitrate,
                    "d@:");
        }

        if (!class_getInstanceMethod(clazz, @selector(averageVideoBitrate))) {
            class_addMethod(clazz,
                    @selector(averageVideoBitrate),
                    (IMP) &_logos_method$_ungrouped$AVPlayerItemAccessLogEvent$averageVideoBitrate,
                    "d@:");
        }

        if (!class_getInstanceMethod(clazz, @selector(averageAudioBitrate))) {
            class_addMethod(clazz,
                    @selector(averageAudioBitrate),
                    (IMP) &_logos_method$_ungrouped$AVPlayerItemAccessLogEvent$averageAudioBitrate,
                    "d@:");
        }
    }
}

@end

#pragma clang diagnostic pop
