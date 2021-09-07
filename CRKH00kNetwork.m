#import "CRKH00kNetwork.h"
#import "CRKInjectContext.h"
#import <CydiaSubstrate/CydiaSubstrate.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <net/if.h>
#import <arpa/inet.h>
#import <pthread.h>
#import "NSString+Extend.h"
#import "CRKWCHeaders.h"
#import "CRKNetworkInfo.h"

#define kCRKFake4GSSIDPrefix  "lfo20c1"

static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

NSMutableDictionary<NSNumber *, NSNumber *> *__CRK_SCNetworkReachabilitySetCallbacks = nil;
NSMutableDictionary<NSNumber *, NSNumber *> *__CRK_SCNetworkReachabilityInfos = nil;

BOOL __CRK_IsRealHas4GBaseband(void) {
    struct ifaddrs *interfaces;
    BOOL result = NO;

    if (Origin_getifaddrs(&interfaces) == 0) {
        struct ifaddrs *interface;
        for (interface = interfaces; interface; interface = interface->ifa_next) {
            if (!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }

            NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
            if ([name isEqualToString:@"pdp_ip0"]) {
                result = YES;
                break;
            }
        }

        Origin_freeifaddrs(interfaces);
    }

    return result;
}

struct ifaddrs *__CRK_Set_ifaddrs_interface(struct ifaddrs *last_ifaddr, BOOL isIPV6, char *name, unsigned int flags, NSString *addr, NSString *netmask, NSString *dstaddr) {
   CRKLog(@"name:%s flags:%ld, addr:%@, mask:%@, dstaddr:%@", name, flags, addr, netmask, dstaddr);

    struct ifaddrs *result = (struct ifaddrs *) malloc(sizeof(struct ifaddrs));
    memset((void *) result, 0, sizeof(struct ifaddrs));

    if (last_ifaddr != nil) {
        last_ifaddr->ifa_next = result;
    }

    result->ifa_next = nil;
    result->ifa_name = malloc(strlen(name) + 1);
    strcpy(result->ifa_name, name);

    result->ifa_flags = flags;
    result->ifa_data = nil;

    if (isIPV6) {
        result->ifa_addr = malloc(sizeof(struct sockaddr_in6));
        ((struct sockaddr_in6 *) result->ifa_addr)->sin6_len = 28;
        ((struct sockaddr_in6 *) result->ifa_addr)->sin6_family = AF_INET6;
        ((struct sockaddr_in6 *) result->ifa_addr)->sin6_port = 0;
        ((struct sockaddr_in6 *) result->ifa_addr)->sin6_flowinfo = 0;
        inet_pton(AF_INET6, addr.UTF8String, &(((struct sockaddr_in6 *) result->ifa_addr)->sin6_addr));
        ((struct sockaddr_in6 *) result->ifa_addr)->sin6_scope_id = 0;

        result->ifa_netmask = malloc(sizeof(struct sockaddr_in6));
        ((struct sockaddr_in6 *) result->ifa_netmask)->sin6_len = 28;
        ((struct sockaddr_in6 *) result->ifa_netmask)->sin6_family = AF_INET6;
        ((struct sockaddr_in6 *) result->ifa_netmask)->sin6_port = 0;
        ((struct sockaddr_in6 *) result->ifa_netmask)->sin6_flowinfo = 0;
        inet_pton(AF_INET6, netmask.UTF8String, &(((struct sockaddr_in6 *) result->ifa_netmask)->sin6_addr));
        ((struct sockaddr_in6 *) result->ifa_netmask)->sin6_scope_id = 0;

        result->ifa_dstaddr = malloc(sizeof(struct sockaddr_in6));
        ((struct sockaddr_in6 *) result->ifa_dstaddr)->sin6_len = 28;
        ((struct sockaddr_in6 *) result->ifa_dstaddr)->sin6_family = AF_INET6;
        ((struct sockaddr_in6 *) result->ifa_dstaddr)->sin6_port = 0;
        ((struct sockaddr_in6 *) result->ifa_dstaddr)->sin6_flowinfo = 0;
        inet_pton(AF_INET6, dstaddr.UTF8String, &(((struct sockaddr_in6 *) result->ifa_dstaddr)->sin6_addr));
        ((struct sockaddr_in6 *) result->ifa_dstaddr)->sin6_scope_id = 0;
    } else {
        result->ifa_addr = malloc(sizeof(struct sockaddr_in));
        ((struct sockaddr_in *) result->ifa_addr)->sin_len = 16;
        ((struct sockaddr_in *) result->ifa_addr)->sin_family = AF_INET;
        ((struct sockaddr_in *) result->ifa_addr)->sin_port = 0;
        inet_pton(AF_INET, addr.UTF8String, &(((struct sockaddr_in *) result->ifa_addr)->sin_addr));

        result->ifa_netmask = malloc(sizeof(struct sockaddr_in));
        ((struct sockaddr_in *) result->ifa_netmask)->sin_len = 16;
        ((struct sockaddr_in *) result->ifa_netmask)->sin_family = AF_INET;
        ((struct sockaddr_in *) result->ifa_netmask)->sin_port = 0;
        inet_pton(AF_INET, netmask.UTF8String, &(((struct sockaddr_in *) result->ifa_netmask)->sin_addr));

        result->ifa_dstaddr = malloc(sizeof(struct sockaddr_in));
        ((struct sockaddr_in *) result->ifa_dstaddr)->sin_len = 16;
        ((struct sockaddr_in *) result->ifa_dstaddr)->sin_family = AF_INET;
        ((struct sockaddr_in *) result->ifa_dstaddr)->sin_port = 0;
        inet_pton(AF_INET, dstaddr.UTF8String, &(((struct sockaddr_in *) result->ifa_dstaddr)->sin_addr));
    }

    return result;
}

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"
#define IP_MAC    @"mac"

NSDictionary *__CRK_Display_ifaddrs_interfaces(struct ifaddrs *interfaces) {
    struct ifaddrs *interface;
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];

    for (interface = interfaces; interface; interface = interface->ifa_next) {
        if (!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
            continue; // deeply nested code harder to read
        }

        const struct sockaddr_in *addr = (const struct sockaddr_in *) interface->ifa_addr;
        char addrBuf[MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN)];
        NSString *name = [NSString stringWithUTF8String:interface->ifa_name];

       CRKLog(@"name:%@", name);

        if (addr && (addr->sin_family == AF_INET || addr->sin_family == AF_INET6 || addr->sin_family == AF_LINK)) {
            NSString *type;
            if (addr->sin_family == AF_INET) {
                if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                    type = IP_ADDR_IPv4;
                }
            } else if (addr->sin_family == AF_INET6) {
                const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6 *) interface->ifa_addr;
                if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                    type = IP_ADDR_IPv6;
                }
            } else {
                __unused const struct sockaddr_dl *sdl = (const struct sockaddr_dl *) interface->ifa_addr;
//                NSLog(@"name:%@, mac:%s", name, [[self class] sdl2string:sdl]);
            }

            if (type) {
                NSString *key = [NSString stringWithFormat:@"%@/%@ flag:%ld", name, type, (long) interface->ifa_flags];
                addresses[key] = [NSString stringWithUTF8String:addrBuf];
            }
        }
    }

    CRKLog(@"interfaces:%@", addresses);

    return addresses;
}

struct ifaddrs *__CRK_CheckAndRebuild_ifaddrs_interfaces(BOOL isIn4G) {
   CRKLog(@"Inspection and reconstruction interfaces:%@", __CRK_Orig_NSThread_callStackSymbols);

    if (1) {
        // interfaces
        // wifi:
        // awdl0/ipv6
        // en0/ipv4
        // en0/ipv6
        // lo0/ipv4
        // lo0/ipv6
        // pdp_ip0/ipv4
        //
        // 4G:
        // lo0/ipv4
        // lo0/ipv6
        // pdp_ip0/ipv4

        // FIXME: AF_LINK

        struct ifaddrs *firstAddr;

        if (!isIn4G) {
            struct ifaddrs *awdl0_ipv6 = __CRK_Set_ifaddrs_interface(nil, YES, "awdl0", 34883, [CRKNetworkInfo awdl0_ipv6], [CRKNetworkInfo awdl0_ipv6_netmask], [CRKNetworkInfo awdl0_ipv6_dstaddr]);
            struct ifaddrs *en0_ipv4 = __CRK_Set_ifaddrs_interface(awdl0_ipv6, NO, "en0", 34915, [CRKNetworkInfo en0_ipv4], [CRKNetworkInfo en0_ipv4_netmask], [CRKNetworkInfo en0_ipv4_dstaddr]);
            struct ifaddrs *en0_ipv6 = __CRK_Set_ifaddrs_interface(en0_ipv4, YES, "en0", 34915, [CRKNetworkInfo en0_ipv6], [CRKNetworkInfo en0_ipv6_netmask], [CRKNetworkInfo en0_ipv6_dstaddr]);
            struct ifaddrs *lo0_ipv4 = __CRK_Set_ifaddrs_interface(en0_ipv6, NO, "lo0", 32841, [CRKNetworkInfo lo0_ipv4], [CRKNetworkInfo lo0_ipv4_netmask], [CRKNetworkInfo lo0_ipv4_dstaddr]);
            struct ifaddrs *lo0_ipv6 = __CRK_Set_ifaddrs_interface(lo0_ipv4, YES, "lo0", 32841, [CRKNetworkInfo lo0_ipv6], [CRKNetworkInfo lo0_ipv6_netmask], [CRKNetworkInfo lo0_ipv6_dstaddr]);
            __unused struct ifaddrs *pdp_ip0_ipv4 = __CRK_Set_ifaddrs_interface(lo0_ipv6, NO, "pdp_ip0", 32849, [CRKNetworkInfo pdp_ip0_ipv4], [CRKNetworkInfo pdp_ip0_ipv4_netmask], [CRKNetworkInfo pdp_ip0_ipv4_dstaddr]);

            firstAddr = awdl0_ipv6;
        } else {
            struct ifaddrs *lo0_ipv4 = __CRK_Set_ifaddrs_interface(nil, NO, "lo0", 32841, [CRKNetworkInfo lo0_ipv4], [CRKNetworkInfo lo0_ipv4_netmask], [CRKNetworkInfo lo0_ipv4_dstaddr]);
            struct ifaddrs *lo0_ipv6 = __CRK_Set_ifaddrs_interface(lo0_ipv4, YES, "lo0", 32841, [CRKNetworkInfo lo0_ipv6], [CRKNetworkInfo lo0_ipv6_netmask], [CRKNetworkInfo lo0_ipv6_dstaddr]);
            __unused struct ifaddrs *pdp_ip0_ipv4 = __CRK_Set_ifaddrs_interface(lo0_ipv6, NO, "pdp_ip0", 32849, [CRKNetworkInfo pdp_ip0_ipv4], [CRKNetworkInfo pdp_ip0_ipv4_netmask], [CRKNetworkInfo pdp_ip0_ipv4_dstaddr]);

            firstAddr = lo0_ipv4;
        }

//    __CRK_Display_ifaddrs_interfaces(awdl0_ipv6);

        return firstAddr;
    } else {
        // interfaces
        // wifi:
        // awdl0/ipv6
        // en2/ipv4
        // en2/ipv6
        // lo0/ipv4
        // lo0/ipv6
        // pdp_ip0/ipv4
        // pdp_ip0/ipv6
        // en0/ipv4
        // en0/ipv6
        //
        // 4G:
        // awdl0/ipv6
        // en2/ipv4
        // en2/ipv6
        // lo0/ipv4
        // lo0/ipv6
        // pdp_ip0/ipv4
        // pdp_ip0/ipv6

        // FIXME: AF_LINK

        struct ifaddrs *awdl0_ipv6 = __CRK_Set_ifaddrs_interface(nil, YES, "awdl0", 34883, [CRKNetworkInfo awdl0_ipv6], [CRKNetworkInfo awdl0_ipv6_netmask], [CRKNetworkInfo awdl0_ipv6_dstaddr]);
        struct ifaddrs *en2_ipv4 = __CRK_Set_ifaddrs_interface(awdl0_ipv6, NO, "en2", 34915, [CRKNetworkInfo en2_ipv4], [CRKNetworkInfo en2_ipv4_netmask], [CRKNetworkInfo en2_ipv4_dstaddr]);
        struct ifaddrs *en2_ipv6 = __CRK_Set_ifaddrs_interface(en2_ipv4, YES, "en2", 34915, [CRKNetworkInfo en2_ipv6], [CRKNetworkInfo en2_ipv6_netmask], [CRKNetworkInfo en2_ipv6_dstaddr]);
        struct ifaddrs *lo0_ipv4 = __CRK_Set_ifaddrs_interface(en2_ipv6, NO, "lo0", 32841, [CRKNetworkInfo lo0_ipv4], [CRKNetworkInfo lo0_ipv4_netmask], [CRKNetworkInfo lo0_ipv4_dstaddr]);
        struct ifaddrs *lo0_ipv6 = __CRK_Set_ifaddrs_interface(lo0_ipv4, YES, "lo0", 32841, [CRKNetworkInfo lo0_ipv6], [CRKNetworkInfo lo0_ipv6_netmask], [CRKNetworkInfo lo0_ipv6_dstaddr]);
        struct ifaddrs *pdp_ip0_ipv4 = __CRK_Set_ifaddrs_interface(lo0_ipv6, NO, "pdp_ip0", 32849, [CRKNetworkInfo pdp_ip0_ipv4], [CRKNetworkInfo pdp_ip0_ipv4_netmask], [CRKNetworkInfo pdp_ip0_ipv4_dstaddr]);
        struct ifaddrs *pdp_ip0_ipv6 = __CRK_Set_ifaddrs_interface(pdp_ip0_ipv4, YES, "pdp_ip0", 32849, [CRKNetworkInfo pdp_ip0_ipv6], [CRKNetworkInfo pdp_ip0_ipv6_netmask], [CRKNetworkInfo pdp_ip0_ipv6_dstaddr]);

        if (!isIn4G) {
            // en0
            struct ifaddrs *en0_ipv4 = __CRK_Set_ifaddrs_interface(pdp_ip0_ipv6, NO, "en0", 34915, [CRKNetworkInfo en0_ipv4], [CRKNetworkInfo en0_ipv4_netmask], [CRKNetworkInfo en0_ipv4_dstaddr]);
            __unused struct ifaddrs *en0_ipv6 = __CRK_Set_ifaddrs_interface(en0_ipv4, YES, "en0", 34915, [CRKNetworkInfo en0_ipv6], [CRKNetworkInfo en0_ipv6_netmask], [CRKNetworkInfo en0_ipv6_dstaddr]);
        }

//    __CRK_Display_ifaddrs_interfaces(awdl0_ipv6);

        return awdl0_ipv6;
    }
}

int Fake_getifaddrs(struct ifaddrs **arg) {
    // check if have 4G card.
    if (__CRK_IsRealHas4GBaseband()) {
        int origResult = Origin_getifaddrs(arg);
        return origResult;
    }

    BOOL isIn4G = CRK_IsIn4GWifiNetwork();
    struct ifaddrs *interfaces = __CRK_CheckAndRebuild_ifaddrs_interfaces(isIn4G);

    if (arg != nil) {
        *arg = interfaces;
    }

    return 0;

    if (0) {
        // TODO: Check the logic here, affecting wifi reconnection.
        int origResult = Origin_getifaddrs(arg);

        if (!origResult) {
            NSString *mac = [CRKInjectContext shared].wifiMac;

            if (mac) {
                for (struct ifaddrs *i = *arg; i; i = i->ifa_next) {
                    if (strcmp(i->ifa_name, "en0")
                            && strcmp(i->ifa_name, "en1")
                            && strcmp(i->ifa_name, "ap1")
                            && strcmp(i->ifa_name, "awdl0")
                            && strcmp(i->ifa_name, "pdp_ip0")) {

                        continue;
                    }

                    struct sockaddr *ifaAddr = i->ifa_addr;
                    char *v37 = &ifaAddr->sa_data[ifaAddr->sa_data[3] + 6];

                    NSMutableString *newIfaAddrStr = [NSMutableString string];
                    for (int j = 0; j < (unsigned char) ifaAddr->sa_data[4]; ++j) {
                        NSString *tmpStr;
                        if (j) {
                            tmpStr = @":%02x";
                        } else {
                            tmpStr = @"%02x";
                        }

                        [newIfaAddrStr appendFormat:tmpStr, *(unsigned char *) (v37 + j)];
                    }

                    if ([newIfaAddrStr length] > 0x10
                            && ![newIfaAddrStr hasPrefix:@"02:00:00"]) {

                        NSArray *macParts = [mac componentsSeparatedByString:@":"];
                        if ([CRKInjectContext shared].isInApp) {
                            macParts = [@"02:00:00:00:00:00" componentsSeparatedByString:@":"];
                        }

                        for (NSUInteger k = 0;; ++k) {
                            BOOL v31 = NO;
                            if (k < (unsigned char) ifaAddr->sa_data[4]) {
                                v31 = [macParts count] > k;
                            }

                            if (!v31) {
                                break;
                            }

                            id v16 = macParts[k];
                            NSData *v17 = [v16 hexStringToData];
                            *(unsigned char *) (v37 + k) = *(unsigned char *) [v17 bytes];
                        }
                    }

                    if (i->ifa_addr->sa_family == 2 && !(i->ifa_flags & 8)) {
                        NSString *wifiIP = [CRKInjectContext shared].wifiIP;

                        if (wifiIP) {
                            struct in_addr *ifaAddr1 = (struct in_addr *) i->ifa_addr;
                            const char *wifiIPChrs = [wifiIP UTF8String];
                            inet_aton(wifiIPChrs, ifaAddr1 + 1);

                            NSArray *wifiIPParts = [wifiIP componentsSeparatedByString:@"."];
                            if (wifiIPParts && [wifiIPParts count] == 4) {
                                NSString *part0 = wifiIPParts[0];
                                NSString *part1 = wifiIPParts[1];
                                NSString *part2 = wifiIPParts[2];

                                NSString *newWifiIP = [NSString stringWithFormat:@"%@.%@.%@.255", part0, part1, part2];
                                const char *newWifiIPChrs = [newWifiIP UTF8String];
                                inet_aton(newWifiIPChrs, (struct in_addr *) &i->ifa_dstaddr->sa_data[2]);
                            }
                        }
                    }
                }
            }
        }

        return origResult;
    }
}

void Fake_freeifaddrs(struct ifaddrs *interfaces) {
    if (__CRK_IsRealHas4GBaseband()) {
        Origin_freeifaddrs(interfaces);
        return;
    }

    for (struct ifaddrs *head = interfaces; head != nil;) {
        struct ifaddrs *lastHead = head;
        head = lastHead->ifa_next;

        if (lastHead->ifa_name) {
            free(lastHead->ifa_name);
        }
        if (lastHead->ifa_addr) {
            free(lastHead->ifa_addr);
        }
        if (lastHead->ifa_netmask) {
            free(lastHead->ifa_netmask);
        }
        if (lastHead->ifa_dstaddr) {
            free(lastHead->ifa_dstaddr);
        }
        if (lastHead->ifa_data) {
            free(lastHead->ifa_data);
        }
        free(lastHead);
    }

    interfaces = nil;
}

extern void __CRK_CheckIn4G(BOOL isInFake4G);

CFDictionaryRef (*Origin_CNCopyCurrentNetworkInfo)(CFStringRef interfaceName);

CFDictionaryRef Fake_CNCopyCurrentNetworkInfo(CFStringRef interfaceName) {
    CFDictionaryRef origResult = Origin_CNCopyCurrentNetworkInfo(interfaceName);

    if (__CRK_IsRealHas4GBaseband()) {
        return origResult;
    }

    NSString *fakeSSID = [CRKInjectContext shared].wifiSSID;
    NSString *fakeMac = [CRKInjectContext shared].wifiMac;

    if (origResult == nil || fakeSSID.length == 0) {
        return origResult;
    }

    NSMutableDictionary *newResult = [NSMutableDictionary dictionaryWithDictionary:(__bridge NSDictionary *_Nonnull) (origResult)];
    CFRelease(origResult);

    NSString *origSSID = newResult[@"SSID"];
    if (origSSID != nil && [[origSSID lowercaseString] rangeOfString:@kCRKFake4GSSIDPrefix].location == 0) {
       CRKLog(@"Hook_Network in 4G mode, get wifi return null");
        __CRK_CheckIn4G(YES);

        // If it is a simulated 4G, then simply return null.
        return nil;
    }

    __CRK_CheckIn4G(NO);

    if (fakeMac) {
        newResult[@"BSSID"] = fakeMac;
    }

    newResult[@"SSID"] = fakeSSID;
    newResult[@"SSIDDATA"] = [fakeSSID dataUsingEncoding:NSUTF8StringEncoding];

   CRKLog(@"Hook_Network Get the current Wifi information: newResult:%@", newResult);

    return CFBridgingRetain(newResult);
}

#pragma mark -

void CRK_replaced_SCNetworkReachabilityConnectionCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    SCNetworkReachabilityCallBack origFunction = (SCNetworkReachabilityCallBack) [__CRK_SCNetworkReachabilitySetCallbacks[@((long long) target)] longLongValue];

    if (origFunction != nil) {
        CRKLog(@"Hook_Network Network status changed target:%ld, origFunction:%lld", (long) target, (long long) origFunction);

        SCNetworkReachabilityFlags newFlags = flags;
        BOOL isIn4G = CRK_IsIn4GWifiNetwork();

        CRKLog(@"Hook_Network network status has changed, currently under 4G: %ld", (long) isIn4G);

        __unused BOOL is4GConfigChange = [CRKNetworkInfo check_pdp_ip0_MakeNew:isIn4G];

        if (isIn4G) {
            // under 4G, if WWAN is not included:
            if (!(newFlags & kSCNetworkReachabilityFlagsIsWWAN)) {
                newFlags |= kSCNetworkReachabilityFlagsIsWWAN;
            }
        } else {
            // not under 4G, remove WWAN:
            if (newFlags & kSCNetworkReachabilityFlagsIsWWAN) {
                newFlags ^= kSCNetworkReachabilityFlagsIsWWAN;
            }
        }

        CRKLog(@"Hook_Network flags:%ld, newFlags:%ld, info:%lld", (long) flags, (long) newFlags, (long long) info);
        origFunction(target, newFlags, info);
    }
}

Boolean (*Origin_SCNetworkReachabilitySetCallback)(SCNetworkReachabilityRef target, SCNetworkReachabilityCallBack callout, SCNetworkReachabilityContext *context);

Boolean Fake_SCNetworkReachabilitySetCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityCallBack callout, SCNetworkReachabilityContext *context) {
    if (__CRK_IsRealHas4GBaseband()) {
        return Origin_SCNetworkReachabilitySetCallback(target, callout, context);
    }

    pthread_mutex_lock(&mutex);
    if (__CRK_SCNetworkReachabilitySetCallbacks == nil) {
        __CRK_SCNetworkReachabilitySetCallbacks = [[NSMutableDictionary alloc] init];
    }
    if (__CRK_SCNetworkReachabilityInfos == nil) {
        __CRK_SCNetworkReachabilityInfos = [[NSMutableDictionary alloc] init];
    }
    pthread_mutex_unlock(&mutex);

    NSNumber *key = @((long long) target);
    if (callout == nil) {
        [__CRK_SCNetworkReachabilitySetCallbacks removeObjectForKey:key];
        [__CRK_SCNetworkReachabilityInfos removeObjectForKey:key];
    } else {
        void **origFunction;
        MSHookFunction((void *) callout, (void *) CRK_replaced_SCNetworkReachabilityConnectionCallback, (void **) &origFunction);

        __CRK_SCNetworkReachabilitySetCallbacks[key] = @((long long) origFunction);
        __CRK_SCNetworkReachabilityInfos[key] = @((long long) context->info);
    }

    return Origin_SCNetworkReachabilitySetCallback(target, callout, context);
}

#pragma mark -

BOOL CRK_IsIn4GWifiNetwork(void) {
    NSString *wifiSSID = CRK_OriginWifiSSID();
    BOOL result;

    // kCRKFake4GSSIDPrefix starts
    if (wifiSSID != nil && [[wifiSSID lowercaseString] rangeOfString:@kCRKFake4GSSIDPrefix].location == 0) {
        result = YES;
    } else {
        result = NO;
    }

    return result;
}

NSString *CRK_OriginWifiSSID(void) {
    NSString *result = nil;
    CFArrayRef wifiInterfaces = CNCopySupportedInterfaces();

    if (!wifiInterfaces) {
        return nil;
    }

    NSArray *interfaces = (__bridge NSArray *) wifiInterfaces;
    for (NSString *interfaceName in interfaces) {
        CFDictionaryRef dictRef;

        if (Origin_CNCopyCurrentNetworkInfo != nil) {
            dictRef = Origin_CNCopyCurrentNetworkInfo((__bridge CFStringRef) (interfaceName));
        } else {
            dictRef = CNCopyCurrentNetworkInfo((__bridge CFStringRef) (interfaceName));
        }

        if (dictRef) {
            NSDictionary *networkInfo = (__bridge NSDictionary *) dictRef;
            result = networkInfo[(__bridge NSString *) kCNNetworkInfoKeySSID];
            CFRelease(dictRef);
        }
    }

    CFRelease(wifiInterfaces);

    return result;
}

Boolean (*Origin_SCNetworkReachabilityGetFlags)(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags *flags);

Boolean Fake_SCNetworkReachabilityGetFlags(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags *flags) {
    Boolean result = Origin_SCNetworkReachabilityGetFlags(target, flags);
    if (__CRK_IsRealHas4GBaseband()) {
        return result;
    }

    if (flags != nil) {
       CRKLog(@"Hook_Network original flags:%ld", (long) *flags);

        // already connected:
        if ((*flags) & kSCNetworkReachabilityFlagsReachable) {
            // whether the hotspot is connecting to 4G
            BOOL isIn4G = CRK_IsIn4GWifiNetwork();
            CRKLog(@"Hook_Network connecting to 4G: %ld", (long) isIn4G);

//            __CRK_CheckIn4G(isIn4G);

            if (isIn4G) {
                if (!((*flags) & kSCNetworkReachabilityFlagsIsWWAN)) {
                    (*flags) |= kSCNetworkReachabilityFlagsIsWWAN;
                }
            } else {
                if ((*flags) & kSCNetworkReachabilityFlagsIsWWAN) {
                    (*flags) ^= kSCNetworkReachabilityFlagsIsWWAN;
                }
            }
        }

       CRKLog(@"Hook_Network new flags: %ld", (long) *flags);
    }

    return result;
}

void __CRK_CheckIn4G(BOOL isInFake4G) {
    // make sure it's right:
    MMServiceCenter *center = (MMServiceCenter *) [NSClassFromString(@"MMServiceCenter") defaultCenter];
    CNetworkStatus *status = [center getService:NSClassFromString(@"CNetworkStatus")];

    BOOL isMMIn4G = [status isOnWWan];

    if (isInFake4G != isMMIn4G) {
        // If WC and this are not equal, get it up:
        NSArray <NSNumber *> *targetObjs = __CRK_SCNetworkReachabilitySetCallbacks.allKeys;
        for (NSNumber *targetObj in targetObjs) {
            SCNetworkReachabilityRef target = (SCNetworkReachabilityRef) [targetObj longLongValue];
            SCNetworkReachabilityFlags flags;

            if (Origin_SCNetworkReachabilityGetFlags(target, &flags)) {
                void *info = (void *) [__CRK_SCNetworkReachabilityInfos[targetObj] longLongValue];
                CRK_replaced_SCNetworkReachabilityConnectionCallback(target, flags, info);
            }
        }

        // Check if need to generate a new operator ip when entering 4G:
        __unused BOOL is4GConfigChange = [CRKNetworkInfo check_pdp_ip0_MakeNew:isInFake4G];
    }
}
