#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CFNetwork/CFNetwork.h>
#import <CFNetwork/CFNetworkDefs.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <dirent.h>
#import <dlfcn.h>
#import <ifaddrs.h>
#import <ifaddrs.h>
#import <sys/utsname.h>
#import <sys/stat.h>
#import <sys/mount.h>
#import <sys/signal.h>
#import <mach/mach_types.h>
#import <Security/Security.h>

extern int (*Origin_getifaddrs)(struct ifaddrs **);

extern int Fake_getifaddrs(struct ifaddrs **);

extern void (*Origin_freeifaddrs)(struct ifaddrs *);

extern void Fake_freeifaddrs(struct ifaddrs *);

extern CFDictionaryRef (*Origin_CNCopyCurrentNetworkInfo)(CFStringRef interfaceName);

extern CFDictionaryRef Fake_CNCopyCurrentNetworkInfo(CFStringRef interfaceName);

extern Boolean (*Origin_SCNetworkReachabilityGetFlags)(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags *flags);

extern Boolean Fake_SCNetworkReachabilityGetFlags(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags *flags);

extern Boolean (*Origin_SCNetworkReachabilitySetCallback)(SCNetworkReachabilityRef target, SCNetworkReachabilityCallBack callout, SCNetworkReachabilityContext *context);

extern Boolean Fake_SCNetworkReachabilitySetCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityCallBack callout, SCNetworkReachabilityContext *context);

extern BOOL CRK_IsIn4GWifiNetwork(void);

extern NSString *CRK_OriginWifiSSID(void);

extern NSDictionary * __CRK_Display_ifaddrs_interfaces(struct ifaddrs *interfaces);
