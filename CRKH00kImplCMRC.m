#import <objc/message.h>
#import "CRKH00kImplC.h"
#import "CRKInjectContext.h"
#import "CRKCommonUtils.h"
#import <sys/sysctl.h>
#import <net/if_dl.h>
#import <net/if.h>
#import "CRKWebServerPortHelper.h"
#import "CRKConfigData.h"
#import "NSString+Extend.h"

CFStringRef (*Origin_MGCopyAnswer)(CFStringRef prop, uint32_t *outTypeCode);

CFStringRef Fake_MGCopyAnswer(CFStringRef prop, uint32_t *outTypeCode) {
    CFStringRef newResult; // [xsp+18h] [xbp-8h]
    CFStringRef origResult = Origin_MGCopyAnswer(prop, outTypeCode);

    if (1) {
        if (prop) {
            newResult = CRK_GetEndCopyAnswer(prop, origResult);

//        if ( CFStringCompare(origResult, newResult, (CFStringCompareFlags) 0) != kCFCompareEqualTo) {
            if (newResult != origResult) {
                CRKLog(@"#### prop: %@ origResult: %@ newResult: %@", prop, origResult, newResult);
            }
        } else {
            newResult = origResult;
        }

        return newResult;
    } else {
        return origResult;
    }
}

CFURLRequestRef (*Origin_CFURLRequestCreate)(
        CFAllocatorRef alloc,
        CFURLRef URL,
        CFURLRequestCachePolicy cachePolicy,
        CFTimeInterval timeout,
        CFURLRef mainDocumentURL);

CFURLRequestRef Fake_CFURLRequestCreate(
        CFAllocatorRef alloc,
        CFURLRef URL,
        CFURLRequestCachePolicy cachePolicy,
        CFTimeInterval timeout,
        CFURLRef mainDocumentURL) {

    return Origin_CFURLRequestCreate(alloc, (__bridge CFURLRef) (CRK_CetEndCacheUrl((__bridge NSURL *) (URL))), cachePolicy, timeout, mainDocumentURL);
}

Boolean (*Origin_CFURLRequestSetURL)(CFMutableURLRequestRef mutableRequest, CFURLRef url);

Boolean Fake_CFURLRequestSetURL(CFMutableURLRequestRef mutableRequest, CFURLRef url) {
    Boolean result; // [xsp+6Fh] [xbp-1h]

    if (url) {
        NSString *urlStr = (NSString *) CFURLGetString(url);

        if (urlStr && [urlStr rangeOfString:@"/xp.apple.com/"].location != NSNotFound) {
            result = Origin_CFURLRequestSetURL(mutableRequest, url);
        } else {
            if (urlStr
                    && [urlStr rangeOfString:@"finance-app.itunes.apple.com/assets"].location != NSNotFound
                    && [urlStr hasSuffix:@".js"]) {

                NSString *encodedURLStr = urlStr.urlEncode;
                NSString *newEncodedURLStr = [NSString stringWithFormat:@"http://127.0.0.1:%lu/getfinanceappjs?url=%@", (unsigned long) [CRKWebServerPortHelper readDaemonPort], encodedURLStr];
                NSURL *newEncodedURL = [NSURL URLWithString:newEncodedURLStr];

                result = Origin_CFURLRequestSetURL(mutableRequest, (CFURLRef) (newEncodedURL));
            } else {
                NSURL *newURL = CRK_CetEndCacheUrl((NSURL *) (url));
                result = Origin_CFURLRequestSetURL(mutableRequest, (CFURLRef) (newURL));
            }
        }
    } else {
        result = Origin_CFURLRequestSetURL(mutableRequest, nil);
    }

    return result;
}


CFTypeRef (*Origin_CFBundleGetValueForInfoDictionaryKey)(CFBundleRef bundle, CFStringRef key);

CF_EXPORT CFTypeRef Fake_CFBundleGetValueForInfoDictionaryKey(CFBundleRef bundle, CFStringRef key) {
    if (key) {
        // NSAppTransportSecurity
        if (CFStringCompare(key, CFSTR("NSAppTransportSecurity"), kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
            return (CFDictionaryRef) (@{@"NSAllowsArbitraryLoads": @YES});
        }

        // com.apple.CFNetwork
        CFStringRef bundleID = CFBundleGetIdentifier(bundle);
        if (bundleID
                && CFStringCompare(bundleID, CFSTR("com.apple.CFNetwork"), kCFCompareCaseInsensitive) == kCFCompareEqualTo
                && (CFStringCompare(key, CFSTR("CFBundleVersion"), kCFCompareCaseInsensitive) == kCFCompareEqualTo
                || CFStringCompare(key, CFSTR("CFBundleShortVersionString"), kCFCompareCaseInsensitive) == kCFCompareEqualTo)
                && [CRKInjectContext shared].osversion != nil) {

            NSString *bundleVersionString = CRKConfigData.CFNetworkBundleVersions[[CRKInjectContext shared].osversion];

            if (bundleVersionString != nil) {
                return (CFStringRef) (bundleVersionString);
            }
        }
    }

    CFTypeRef origResult = Origin_CFBundleGetValueForInfoDictionaryKey(bundle, key);

    return origResult;
}

CFDictionaryRef (*Origin_CFBundleGetInfoDictionary)(CFBundleRef bundle);

CFDictionaryRef Fake_CFBundleGetInfoDictionary(CFBundleRef bundle) {
    CFDictionaryRef origResult = Origin_CFBundleGetInfoDictionary(bundle);
    CFStringRef bundleID = CFDictionaryGetValue(origResult, CFSTR("CFBundleIdentifier"));

    if (bundleID != nil && [CRKInjectContext shared].osversion != nil) {
        // 每个iOS版本的appstore对应的bundleVersion
        if (CFStringCompare(bundleID, CFSTR("com.apple.AppStore"), kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
            NSString *version = CRKConfigData.AppStoreBundleVersions[[CRKInjectContext shared].osversion];
            NSString *shortVersion = CRKConfigData.AppStoreBundleShortVersions[[CRKInjectContext shared].osversion];

            if (version != nil && shortVersion != nil) {
                NSMutableDictionary *newResult = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *_Nonnull) (origResult)];
                newResult[@"CFBundleVersion"] = version;
                newResult[@"CFBundleShortVersionString"] = shortVersion;

                return (CFDictionaryRef) (newResult);
            }
        }

        // 每个iOS版本的webkit对应的bundleVersion
        if (CFStringCompare(bundleID, CFSTR("com.apple.WebKitLegacy"), kCFCompareCaseInsensitive) == kCFCompareEqualTo
                || CFStringCompare(bundleID, CFSTR("com.apple.WebCore"), kCFCompareCaseInsensitive) == kCFCompareEqualTo
                || CFStringCompare(bundleID, CFSTR("com.apple.WebKit"), kCFCompareCaseInsensitive) == kCFCompareEqualTo) {

            NSString *version = CRKConfigData.WebkitBundleVersions[[CRKInjectContext shared].osversion];
            NSString *shortVersion = CRKConfigData.WebkitBundleShortVersions[[CRKInjectContext shared].osversion];

            if (version != nil && shortVersion != nil) {
                NSMutableDictionary *newResult = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *_Nonnull) (origResult)];
                newResult[@"CFBundleVersion"] = version;
                newResult[@"CFBundleShortVersionString"] = shortVersion;

                return (CFDictionaryRef) (newResult);
            }
        }

        // CFNetworks
        if (CFStringCompare(bundleID, CFSTR("com.apple.CFNetwork"), kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
            NSString *version = CRKConfigData.CFNetworkBundleVersions[[CRKInjectContext shared].osversion];
            NSString *shortVersion = CRKConfigData.CFNetworkBundleShortVersions[[CRKInjectContext shared].osversion];

            if (version != nil && shortVersion != nil) {
                NSMutableDictionary *newResult = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *_Nonnull) (origResult)];
                newResult[@"CFBundleVersion"] = version;
                newResult[@"CFBundleShortVersionString"] = shortVersion;

                return (CFDictionaryRef) (newResult);
            }
        }
    }

    return origResult;

   CRKLog(@"change NSAllowsArbitraryLoads to YES!");
//
//    NSMutableDictionary *newResult = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *_Nonnull) (origResult)];
//    if ([newResult safetyObjectForKey:@"NSAppTransportSecurity"]) {
//        ((NSMutableDictionary *) [newResult dictionaryObjectForKey:@"NSAppTransportSecurity"])[@"NSAllowsArbitraryLoads"] = @YES;
//    } else {
//        newResult[@"NSAppTransportSecurity"] = @{@"NSAppTransportSecurity": @YES};
//    }
//
//    return (CFDictionaryRef) (newResult);
}

CFDictionaryRef (*Origin_CFCopySystemVersionDictionary)(void);

CFDictionaryRef Fake_CFCopySystemVersionDictionary() {
    CFDictionaryRef origResult = Origin_CFCopySystemVersionDictionary();
    if (!origResult) {
        return origResult;
    }

    NSMutableDictionary *newResult = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *) origResult];
    CFRelease(origResult);

    if (newResult[@"ProductVersion"]) {
        if ([CRKInjectContext shared].osversion) {
            newResult[@"ProductVersion"] = [CRKInjectContext shared].osversion;

            if ([CRKInjectContext shared].BuildVersionValue) {
                newResult[@"FullVersionString"] = [NSString stringWithFormat:@"Version %@ (Build %@)", [CRKInjectContext shared].osversion, [CRKInjectContext shared].BuildVersionValue];
                newResult[@"ProductBuildVersion"] = [CRKInjectContext shared].BuildVersionValue;
            } else {
                newResult[@"FullVersionString"] = [NSString stringWithFormat:@"Version %@ (Build %@)", [CRKInjectContext shared].osversion, [CRKInjectContext shared].origBuildVersion];
            }
        }
    }

    return CFRetain((CFDictionaryRef) newResult);
}

typedef struct kinfo_proc _kinfo_proc;

int Fake_sysctl(int *name, u_int len, void *oldValue, size_t *oldLenP, void *newValue, size_t newLen) {
//    if (len >= 4 && *(uint64 *) name == 60129542145 && (name[3] != getpid())) {
    if (len >= 4 && name[0] == CTL_KERN && name[1] == KERN_PROC && (name[3] != getpid())) {
        CRKLog(@"#### name[0] = CTL_KERN name[1] = KERN_PROC return -1");
        return -1;
    }

    int origResult = Origin_sysctl(name, len, oldValue, oldLenP, newValue, newLen);
    int newResult = origResult;

    if (len == 4 && name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID && oldValue && oldLenP && ((int) *oldLenP == sizeof(_kinfo_proc))) {
        struct kinfo_proc *info_ptr = (struct kinfo_proc *) oldValue;

        if (info_ptr && (info_ptr->kp_proc.p_flag & P_TRACED) != 0) {
            CRKLog(@"#### sysctl query trace status.");
            info_ptr->kp_proc.p_flag ^= P_TRACED;
            if ((info_ptr->kp_proc.p_flag & P_TRACED) == 0) {
                CRKLog(@"#### trace status reomve success!");
            }
        }
    }

    if (name[0] == CTL_KERN && name[1] == KERN_OSRELEASE && len == 2) {
        if (oldValue) {
            if ([CRKInjectContext shared].osversion) {
                if (!newResult) {
                    id darwinKernelVersion = CRKConfigData.DarwinKernelVersions[[CRKInjectContext shared].osversion];
                    if (darwinKernelVersion) {
                        const char *v12 = [darwinKernelVersion UTF8String];
                        memcpy(oldValue, v12, strlen(v12) + 1);
                        *oldLenP = strlen(v12) + 1;
                    }
                }
            }
        }
    }

    if (name[0] == CTL_KERN && name[1] == KERN_OSVERSION && len == 2) {
        if (oldValue) {
            if ([CRKInjectContext shared].BuildVersionValue) {
                if (!newResult) {
                    id buildVersionValue = [CRKInjectContext shared].BuildVersionValue;
                    const char *chars = [buildVersionValue UTF8String];
                    size_t charsLen = strlen(chars);
                    memcpy(oldValue, chars, charsLen + 1);
                    *oldLenP = charsLen + 1;
                }
            }
        }
    }

    if (name[0] == CTL_HW && name[1] == HW_MODEL && len == 2) {
        if (oldValue) {
            if ([CRKInjectContext shared].hardwareModel) {
                if (!newResult) {
                    id hardModel = [CRKInjectContext shared].hardwareModel;
                    const char *chars = (const char *) [hardModel UTF8String];
                    size_t v23 = strlen(chars);
                    memcpy(oldValue, chars, v23 + 1);
                    *oldLenP = strlen(chars) + 1;
                }
            }
        }
    }

    if (name[0] == CTL_KERN && name[1] == KERN_VERSION && len == 2) {
        if (oldValue) {
            if ([CRKInjectContext shared].osversion) {
                if (!newResult) {
                    NSString *v157 = [NSString stringWithCString:oldValue encoding:NSASCIIStringEncoding];

                    if (v157 && [v157 length]) {
                        NSArray *v156 = [v157 componentsSeparatedByString:@":"];

                        if (v156 && [v156 count]) {
                            id v26 = v156[0];
                            if ([v26 hasPrefix:@"Darwin Kernel Version"]) {
                                id osversion = [CRKInjectContext shared].osversion;
                                id version = CRKConfigData.DarwinKernelVersions[osversion];

                                if (version) {
                                    NSMutableArray *v31 = [NSMutableArray arrayWithArray:v156];
                                    NSString *v32 = [NSString stringWithFormat:@"Darwin Kernel Version %@", version];
                                    v31[0] = v32;
                                    NSString *v33 = [v31 componentsJoinedByString:@":"];
                                    const char *v34 = [v33 UTF8String];
                                    size_t v35 = strlen(v34);
                                    memcpy(oldValue, v34, v35 + 1);
                                    *oldLenP = strlen(v34) + 1;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // FIXME: boottime uptime
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
    if (0) {
        if (name[0] == CTL_KERN && name[1] == KERN_BOOTTIME && len == 2) {
            if (oldValue) {
                if (!newResult) {
                    NSTimeInterval v37 = [CRKInjectContext shared].globalStartTime;
                    if (v37 > 0.0) {
                        *(NSTimeInterval *) oldValue = v37;
                    }
                }
            }
        }
    }
#pragma clang diagnostic pop

    if (name[0] == CTL_HW && name[1] == HW_MACHINE && len == 2) {
        if (oldValue) {
            if (!newResult) {
                if ([CRKInjectContext shared].platform) {
                    id v42 = [CRKInjectContext shared].platform;
                    const char *v43 = [v42 UTF8String];
                    size_t size = strlen(v43);
                    memcpy(oldValue, v43, size + 1);
                    *oldLenP = strlen(v43) + 1;
                }
            }
        }
    }

    if (name[0] == CTL_HW && (name[1] == HW_PHYSMEM || name[1] == HW_MEMSIZE) && len == 2) {
        if (oldValue) {
            if (!newResult) {
                if ([CRKInjectContext shared].processInfoPhysicalMemory) {
                    *(int *) oldValue = (int) [CRKInjectContext shared].processInfoPhysicalMemory;
                }
            }
        }
    }

    if (name[0] == CTL_HW && name[1] == HW_L2CACHESIZE && len == 2) {
        if (oldValue) {
            if (!newResult) {
                if ([CRKInjectContext shared].hwL2Cachesize) {
                    *(int *) oldValue = (int) [CRKInjectContext shared].hwL2Cachesize;
                }
            }
        }
    }

    if (name[0] == CTL_HW && (name[1] == HW_L1ICACHESIZE || name[1] == HW_L1DCACHESIZE) && len == 2) {
        if (oldValue) {
            if (!newResult) {
                if ([CRKInjectContext shared].hwL1Cachesize) {
                    *(int *) oldValue = (int) [CRKInjectContext shared].hwL1Cachesize;
                }
            }
        }
    }

    if (name[0] == CTL_HW && (name[1] == HW_NCPU || name[1] == HW_AVAILCPU) && len == 2) {
        if (oldValue) {
            if (!newResult) {
                if ([CRKInjectContext shared].processInfoProcessorCount) {
                    *(int *) oldValue = (int) [CRKInjectContext shared].processInfoProcessorCount;
                }
            }
        }
    }

    if (*name == 1) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
        name[1];
#pragma clang diagnostic pop
    }

    const char *progName = getprogname();

    if (name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == 0 && name[3] == 0 && len == 4) {
        if (oldValue) {
            if (newResult == 0
                    && strstr(progName, "SpringBoard") == 0
                    && strstr(progName, "mobile_installation_proxy") == 0
                    && strstr(progName, "backboardd") == 0
                    && strstr(progName, "backupd") == 0
                    && strstr(progName, "searchd") == 0
                    && strcmp(progName, "atc") != 0
                    && strstr(progName, "syncdefaultsd") == 0
                    && strstr(progName, "crkdaemon") == 0
                    && strstr(progName, "TaskDemo") == 0
                    && (*oldLenP % sizeof(struct kinfo_proc)) == 0) {

                NSUInteger nprocess = *oldLenP / sizeof(struct kinfo_proc);
                struct kinfo_proc *process = oldValue;

                for (NSInteger i = nprocess - 1; i >= 0; --i) {
                    @autoreleasepool {
                        NSString *checkProgName = [NSString stringWithUTF8String:(const char *) process[i].kp_proc.p_comm]; //[[[NSString alloc] initWithFormat:@"%s", (const char *) process[i].kp_proc.p_comm] autorelease];
                        checkProgName = [checkProgName lowercaseString];

                        if ([checkProgName rangeOfString:@"cydia"].location != NSNotFound
                                || [checkProgName rangeOfString:@"aptp"].location != NSNotFound
                                || [checkProgName rangeOfString:@"pphelper"].location != NSNotFound
                                || [checkProgName rangeOfString:@"ppjail"].location != NSNotFound
                                || [checkProgName rangeOfString:@"tsdaemon"].location != NSNotFound
                                || [checkProgName rangeOfString:@"hades"].location != NSNotFound
                                || [checkProgName rangeOfString:@"touchsprite"].location != NSNotFound
                                || [checkProgName rangeOfString:@"yalu1"].location != NSNotFound
                                ) {

                            size_t commLen = strlen((const char *) process[i].kp_proc.p_comm);
                            void *tmpComm = malloc(commLen);
                            memset(tmpComm, 49, commLen);
                            memcpy(process[i].kp_proc.p_comm, tmpComm, commLen);
                            free(tmpComm);
                        }

                        // FIXME: boottime uptime
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
                        if (0) {
                            if ([checkProgName isEqualToString:@"kernel_task"]) {
                                NSTimeInterval v83 = [CRKInjectContext shared].globalStartTime;

                                if (v83 > 0.0 && process[i].kp_proc.p_un.__p_starttime.tv_sec > 0) {
                                    process[i].kp_proc.p_un.__p_starttime.tv_sec = (long) [CRKInjectContext shared].globalStartTime;
                                }
                            }
                        }
#pragma clang diagnostic pop
                    }
                }
            }
        }
    }

    if (name[0] == CTL_NET
            && name[1] == AF_ROUTE
            && name[2] == 0
            && name[3] == AF_LINK
            && name[4] == NET_RT_IFLIST
            && len == 6
            && oldValue
            && [CRKInjectContext shared].wifiMac) {

        if (!newResult) {
            struct if_msghdr *ifm = (struct if_msghdr *) oldValue;
            struct sockaddr_dl *sdl = (struct sockaddr_dl *) (ifm + 1);
            unsigned char *ptr = (unsigned char *) LLADDR(sdl);
            unsigned char *v152 = ptr;

            if (v152) {
                NSString *v151 = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                                            v152[0],
                                                            v152[1],
                                                            v152[2],
                                                            v152[3],
                                                            v152[4],
                                                            v152[5]];

                if (![v151 hasPrefix:@"02:00:00"]) {
                    if ([CRKInjectContext shared].isInApp) {
                        NSArray *v150 = [@"02:00:00:00:00:00" componentsSeparatedByString:@":"];

                        if ([v150 count] >= 6) {
                            v152[0] = *(const unsigned char *) [v150[0] hexStringToChar];
                            v152[1] = *(const unsigned char *) [v150[1] hexStringToChar];
                            v152[2] = *(const unsigned char *) [v150[2] hexStringToChar];
                            v152[3] = *(const unsigned char *) [v150[3] hexStringToChar];
                            v152[4] = *(const unsigned char *) [v150[4] hexStringToChar];
                            v152[5] = *(const unsigned char *) [v150[5] hexStringToChar];
                        }
                    } else if ([[[CRKInjectContext shared].origWifiAddress lowercaseString] isEqualToString:v151]) {
                        id v100 = [CRKInjectContext shared].wifiMac;
                        NSArray *v149 = [v100 componentsSeparatedByString:@":"];

                        if ([v149 count] >= 6) {
                            v152[0] = *(const unsigned char *) [v149[0] hexStringToChar];
                            v152[1] = *(const unsigned char *) [v149[1] hexStringToChar];
                            v152[2] = *(const unsigned char *) [v149[2] hexStringToChar];
                            v152[3] = *(const unsigned char *) [v149[3] hexStringToChar];
                            v152[4] = *(const unsigned char *) [v149[4] hexStringToChar];
                            v152[5] = *(const unsigned char *) [v149[5] hexStringToChar];
                        }
                    } else if ([CRKInjectContext shared].bluetooth
                            && [CRKInjectContext shared].origBluetoothAddress
                            && [[[CRKInjectContext shared].origBluetoothAddress uppercaseString] isEqualToString:v151]) {

                        id v113 = [CRKInjectContext shared].bluetooth;
                        NSArray *v148 = [v113 componentsSeparatedByString:@":"];

                        if ([v148 count] >= 6) {
                            v152[0] = *(const unsigned char *) [v148[0] hexStringToChar];
                            v152[1] = *(const unsigned char *) [v148[1] hexStringToChar];
                            v152[2] = *(const unsigned char *) [v148[2] hexStringToChar];
                            v152[3] = *(const unsigned char *) [v148[3] hexStringToChar];
                            v152[4] = *(const unsigned char *) [v148[4] hexStringToChar];
                            v152[5] = *(const unsigned char *) [v148[5] hexStringToChar];
                        }
                    }
                }
            }
        }
    }

    CRKLog(@"#### name[0,1]:[%ld,%ld] origResult:%ld newResult:%ld", (long) name[0], (long) name[1], (long) origResult, (long) newResult);

    return newResult;
}

// MobileInstallationLookup
CFDictionaryRef (*Origin_MobileInstallationLookup)(id a1);

CFDictionaryRef Fake_MobileInstallationLookup(id a1) {
    NSDictionary *newResult;
    NSDictionary *origResult = (NSDictionary *) Origin_MobileInstallationLookup(a1);
    if (origResult
            && [origResult isKindOfClass:[NSDictionary class]]) {

        NSMutableDictionary *newValues = [NSMutableDictionary dictionary];
        NSArray *allKeys = [origResult allKeys];

        for (NSString *key in allKeys) {
            if (key.length > 0) {
                if ([[key lowercaseString] rangeOfString:@"cydia"].location == NSNotFound
                        && [[key lowercaseString] rangeOfString:@"ppjail"].location == NSNotFound
                        && [[key lowercaseString] rangeOfString:@"yalu1"].location == NSNotFound) {

                    NSString *value = origResult[key];
                    newValues[key] = value;
                }
            }
        }

        newResult = newValues;
    } else {
        newResult = origResult;
    }

    return (__bridge CFDictionaryRef) (newResult);
}

// CFBundleGetAllBundles
CFArrayRef (*Origin_CFBundleGetAllBundles)(void);

CFArrayRef Fake_CFBundleGetAllBundles() {
    CFArrayRef origAllBundlesRef = Origin_CFBundleGetAllBundles();
    NSMutableArray *destAllBundles = [NSMutableArray arrayWithArray:(NSArray *) origAllBundlesRef];
    NSMutableArray *removeBundles = [[[NSMutableArray alloc] init] autorelease];

    CFIndex count = CFArrayGetCount(origAllBundlesRef);
    for (CFIndex n = 0; n < count; ++n) {
        CFBundleRef bundleRef = (CFBundleRef) CFArrayGetValueAtIndex(origAllBundlesRef, n);
        CFURLRef urlRef = CFBundleCopyBundleURL(bundleRef);
        NSURL *url = (NSURL *) urlRef;
        NSString *urlStr = url.absoluteString;

        if ([urlStr rangeOfString:@"Cydia"].location != NSNotFound) {
            [removeBundles addObject:(NSBundle *) bundleRef];
        }
    }

    if (removeBundles.count) {
        [destAllBundles removeObjectsInArray:removeBundles];
        CRKLog(@"#### CFBundleGetAllBundles removed by modifications: %@", removeBundles);
        CRKLog(@"#### CFBundleGetAllBundles change to :%@", destAllBundles);
    }

    return (CFArrayRef) destAllBundles;
}


