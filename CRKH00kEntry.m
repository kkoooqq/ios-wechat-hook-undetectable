#import "CRKH00kEntry.h"
#import <objc/runtime.h>
#import <mach-o/dyld.h>

#import "CRKSysctlHelper.h"
#import "CRKMGCopyAnswerHelper.h"
#import "CRKRuntimeHelper.h"

#import <CydiaSubstrate/CydiaSubstrate.h>

// private headers
#import "MCProfileConnection.h"
#import "SSDevice.h"
#import "AKDevice.h"
#import "AKAppleIDCheckInHelperService.h"
#import "ISDevice.h"
#import "SSLookupItem.h"
#import "MIFileManager.h"
#import "ASIdentifierManagerPrivate.h"
#import "NSStringPrivate.h"
#import "ISDialogOperation.h"
#import "LSApplicationWorkspace.h"
#import "CTTelephonyNetworkInfoPrivate.h"
#import "UIDevicePrivate.h"

#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreLocation/CoreLocation.h>

#import <mach-o/getsect.h>
#import <sys/stat.h>
#import <sys/mount.h>
#import <sys/utsname.h>
#import <mach/task.h>
#import <sys/sysctl.h>

#import "CRKH00kImplC.h"
#import "CRKH00kNetwork.h"
#import "CRKInjectContext.h"
#import "CRKHookClasses.h"
#import "CRKCommonUtils.h"
#import "CRKFakeDYLDHelper.h"
#import "CRKH00kEntry+OSVersionAPI.h"
#import "CRKWCDefines.h"
#import "CRKWCTools.h"
#import "CRKH00kWC.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

extern char **environ;

@implementation CRKH00kEntry

+ (instancetype)shared {
    static CRKH00kEntry *instance = nil;
    if (instance == nil) {
        instance = [[CRKH00kEntry alloc] init];
    };

    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
    }

    return self;
}

- (void)startHook {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    int module_base = (int) _dyld_get_image_header(0);
    intptr_t base_addr = _dyld_get_image_vmaddr_slide(0);
    int pid = getpid();
    const char *progName = getprogname();

    CRKLog(@"crkInject Hook: %@, image_header: %ld, vmaddr_slide: %ld, pid: %ld, pname: %s", bundleID, module_base, base_addr, pid, progName);

    if (strstr(progName, "mobactivationd") == 0
            && strstr(progName, "mobileactivationd") == 0
//            && strstr(progName, "ReportCrash") == 0
            && strcmp(progName, "bash") != 0
            && strcmp(progName, "crkdaemon") != 0
//            && strcmp(progName, "SpringBoard") != 0
            && strcmp(progName, "Cydia") != 0
            && strcmp(progName, "bootTaskDemo") != 0
            && strcmp(progName, "TaskDemo") != 0
            && strstr(progName, "substrate") == 0
            && strstr(progName, "yalu1") == 0
            && strstr(progName, "PPJail") == 0
            && strcmp(progName, "TSDaemon") != 0
            && strcmp(progName, "Hades") != 0
            && strcmp(progName, "wifid") != 0
            && strcmp(progName, "NewTouchSprite") != 0
            && strcmp(progName, "Weather") != 0
            && strcmp(progName, "TSLn") != 0
            && strcmp(progName, "TSUpdate") != 0
            && strcmp(progName, "TSUpdate") != 0
            && strcmp(progName, "TSInstaller") != 0
            && strcmp(progName, "postinst") != 0
            && strcmp(progName, "postrm") != 0
            && strcmp(progName, "preinst") != 0
            && strcmp(progName, "prerm") != 0
            && strcmp(progName, "PkgInfo") != 0
            && strcmp(progName, "zip") != 0
            && strcmp(progName, "unzip") != 0
            && strcmp(progName, "tar") != 0
            && strcmp(progName, "ssh") != 0
            && strcmp(progName, "sshd") != 0
            && strcmp(progName, "dpkg") != 0
            && strcmp(progName, "bootregiCloudRequest") != 0
            && strcmp(progName, "regiCloudRequest") != 0) {

        [self startHookCore:bundleID pid:pid progName:progName];
    }
}

- (void)startHookCore:(NSString *)bundleID pid:(int)pid progName:(const char *)progName {
    // specific programs:
    if ([bundleID isEqualToString:@"com.touchsprite.ios"]) {
        return;
    }

    if (strcmp(progName, "ReportCrash") == 0) {
        return;
    }

    NSString *origSystemVersion = [[UIDevice currentDevice] systemVersion];

    // hook nslog
    // ios9 => hook NSLog
//    if ([origSystemVersion compare:@"10.0" options:NSNumericSearch] == NSOrderedAscending) {
    if (/* DISABLES CODE */ (0)) {
        MSHookFunction((void *) NSLog, (void *) Fake_NSLog, (void **) &Origin_NSLog);
        MSHookFunction((void *) NSLogv, (void *) Fake_NSLogv, (void **) &Origin_NSLogv);
    }

    // fake DYLD
    __CRK_filterDYLDs();

    MSHookFunction(
            &CFBundleGetValueForInfoDictionaryKey,
            (void *) Fake_CFBundleGetValueForInfoDictionaryKey,
            (void **) &Origin_CFBundleGetValueForInfoDictionaryKey);

    // aacplatform
    NSString *AACPlatform = [CRKSysctlHelper AACPlatform];

    // system version
    // the initial value
    [CRKInjectContext shared].origSystemVersion = origSystemVersion;
    CRK_setAIKeyValue(@"globalOldSystemVersion", origSystemVersion);

    [CRKInjectContext shared].origAACPlatform = AACPlatform;
    [CRKInjectContext shared].origBluetoothAddress = [CRKMGCopyAnswerHelper dumpDeviceInfoWithKey:CFSTR("BluetoothAddress")];
    [CRKInjectContext shared].origWifiAddress = [CRKMGCopyAnswerHelper dumpDeviceInfoWithKey:CFSTR("WifiAddress")];
    [CRKInjectContext shared].origBuildVersion = [CRKMGCopyAnswerHelper dumpDeviceInfoWithKey:CFSTR("BuildVersion")];

    // change environ
    if (strcmp(progName, "SpringBoard") != 0
            && strcmp(progName, "backboardd") != 0) {

        int i = 0;
        while (environ[i]) {
            NSString *oldEnv = [[NSString alloc] initWithUTF8String:environ[i]];

            if (0) {
                CRKLog(@"request environ: %@", oldEnv);
            }

//            if (strcmp(environ[i], "_MSSafeMode=1") == 0) {
//                strncpy(environ[i], "_MSSafeMode=0", strlen(environ[i]));
//            }

            if (strstr(environ[i], "_MSSafeMode") != 0) {
                memcpy(environ[i], "", 1);
            }

            if (strstr(environ[i], "MobileSubstrate") != 0) {
                // find out substrate
                NSString *environStr = [NSString stringWithUTF8String:environ[i]];

                environStr = [environStr stringByReplacingOccurrencesOfString:@":/Library/MobileSubstrate/MobileSubstrate.dylib" withString:@""];
                environStr = [environStr stringByReplacingOccurrencesOfString:@"/Library/MobileSubstrate/MobileSubstrate.dylib" withString:@""];
                environStr = [environStr stringByReplacingOccurrencesOfString:@"MobileSubstrate/MobileSubstrate.dylib" withString:@""];

                const char *environStrChars = [environStr UTF8String];
                memcpy(environ[i], environStrChars, strlen(environStrChars) + 1);
            }

            NSString *newEnv = [[NSString alloc] initWithUTF8String:environ[i]];
            if (![oldEnv isEqualToString:newEnv]) {
                // CRKLog(@"#### check environ\nBEFORE: %@\nAFTER: %@", oldEnv, newEnv); // prints in form of "variable=value"
            }

            ++i;
        }
    }

    [[CRKInjectContext shared] applyDeviceInfoChanged];

    // LSApplicationWorkspace
    __unused Class metaClazz = nil;
    __unused Class clazz = nil;

    metaClazz = objc_getMetaClass("LSApplicationWorkspace");
    clazz = objc_getClass("LSApplicationWorkspace");

    if (clazz && class_getInstanceMethod(clazz, @selector(allApplications))) {
        MSHookMessageEx(clazz,
                @selector(allApplications),
                (IMP) &_logos_method$_ungrouped$LSApplicationWorkspace$allApplications,
                (IMP *) &_logos_orig$_ungrouped$LSApplicationWorkspace$allApplications);
    }

    if (clazz && class_getInstanceMethod(clazz, @selector(allInstalledApplications))) {
        MSHookMessageEx(
                clazz,
                @selector(allInstalledApplications),
                (IMP) &_logos_method$_ungrouped$LSApplicationWorkspace$allInstalledApplications,
                (IMP *) &_logos_orig$_ungrouped$LSApplicationWorkspace$allInstalledApplications);
    }

    if (clazz && class_getInstanceMethod(clazz, @selector(applicationsOfType:))) {
        MSHookMessageEx(
                clazz,
                @selector(applicationsOfType:),
                (IMP) &_logos_method$_ungrouped$LSApplicationWorkspace$applicationsOfType$,
                (IMP *) &_logos_orig$_ungrouped$LSApplicationWorkspace$applicationsOfType$);
    }

    // UIAlertController
    clazz = objc_getClass("UIAlertController");

#if defined(CRK_ALERTCONTROLLER_SETS) && CRK_ALERTCONTROLLER_SETS == 1
    if (clazz && class_getInstanceMethod(clazz, sel_registerName("dealloc"))) {
        MSHookMessageEx(
                clazz,
                sel_registerName("dealloc"),
                (IMP) &_logos_method$_ungrouped$UIAlertController$dealloc,
                (IMP *) &_logos_orig$_ungrouped$UIAlertController$dealloc);
    }

    if (clazz && class_getInstanceMethod(clazz, @selector(viewDidDisappear:))) {
        MSHookMessageEx(
                clazz,
                @selector(viewDidDisappear:),
                (IMP) &_logos_method$_ungrouped$UIAlertController$viewDidDisappear$,
                (IMP *) &_logos_orig$_ungrouped$UIAlertController$viewDidDisappear$);
    }

    if (clazz && class_getInstanceMethod(clazz, @selector(viewWillDisappear:))) {
        MSHookMessageEx(
                clazz,
                @selector(viewWillDisappear:),
                (IMP) &_logos_method$_ungrouped$UIAlertController$viewWillDisappear$,
                (IMP *) &_logos_orig$_ungrouped$UIAlertController$viewWillDisappear$);
    }
#endif

    if (clazz && class_getInstanceMethod(clazz, @selector(viewDidAppear:))) {
        MSHookMessageEx(
                clazz,
                @selector(viewDidAppear:),
                (IMP) &_logos_method$_ungrouped$UIAlertController$viewDidAppear$,
                (IMP *) &_logos_orig$_ungrouped$UIAlertController$viewDidAppear$);
    }

    // CLLocationManager
    clazz = objc_getClass("CLLocationManager");
    if (0) {
//        if (clazz && class_getInstanceMethod(clazz, @selector(setDelegate:))) {
//            MSHookMessageEx(
//                    clazz,
//                    @selector(setDelegate:),
//                    (IMP) &_logos_method$_ungrouped$CLLocationManager$setDelegate$,
//                    (IMP *) &_logos_orig$_ungrouped$CLLocationManager$setDelegate$);
//        }
    }

    if (clazz && class_getInstanceMethod(clazz, @selector(location))) {
        MSHookMessageEx(
                clazz,
                @selector(location),
                (IMP) &_logos_method$_ungrouped$CLLocationManager$location,
                (IMP *) &_logos_orig$_ungrouped$CLLocationManager$location);
    }

    // AKDevice
    clazz = objc_getClass("AKDevice");
    metaClazz = objc_getMetaClass("AKDevice");

    if (clazz && metaClazz) {
        if (class_getInstanceMethod(clazz, @selector(uniqueDeviceIdentifier))) {
            MSHookMessageEx(
                    clazz,
                    @selector(uniqueDeviceIdentifier),
                    (IMP) &_logos_method$TaskGroup$AKDevice$uniqueDeviceIdentifier,
                    (IMP *) &_logos_orig$TaskGroup$AKDevice$uniqueDeviceIdentifier);
        }

        if (class_getInstanceMethod(clazz, @selector(userChosenName))) {
            MSHookMessageEx(
                    clazz,
                    @selector(userChosenName),
                    (IMP) &_logos_method$TaskGroup$AKDevice$userChosenName,
                    (IMP *) &_logos_orig$TaskGroup$AKDevice$userChosenName);
        }

        if (class_getInstanceMethod(clazz, @selector(mobileEquipmentIdentifier))) {
            MSHookMessageEx(
                    clazz,
                    @selector(mobileEquipmentIdentifier),
                    (IMP) &_logos_method$TaskGroup$AKDevice$mobileEquipmentIdentifier,
                    (IMP *) &_logos_orig$TaskGroup$AKDevice$mobileEquipmentIdentifier);
        }

        if (class_getInstanceMethod(clazz, @selector(phoneNumber))) {
            MSHookMessageEx(
                    clazz,
                    @selector(phoneNumber),
                    (IMP) &_logos_method$TaskGroup$AKDevice$phoneNumber,
                    (IMP *) &_logos_orig$TaskGroup$AKDevice$phoneNumber);
        }

        if (class_getInstanceMethod(clazz, @selector(serialNumber))) {
            MSHookMessageEx(
                    clazz,
                    @selector(serialNumber),
                    (IMP) &_logos_method$TaskGroup$AKDevice$serialNumber,
                    (IMP *) &_logos_orig$TaskGroup$AKDevice$serialNumber);
        }

        if (class_getInstanceMethod(clazz, @selector(serializedData))) {
            MSHookMessageEx(
                    clazz,
                    @selector(serializedData),
                    (IMP) &_logos_method$TaskGroup$AKDevice$serializedData,
                    (IMP *) &_logos_orig$TaskGroup$AKDevice$serializedData);
        }

        if (class_getInstanceMethod(clazz, @selector(integratedCircuitCardIdentifier))) {
            MSHookMessageEx(
                    clazz,
                    @selector(integratedCircuitCardIdentifier),
                    (IMP) &_logos_method$TaskGroup$AKDevice$integratedCircuitCardIdentifier,
                    (IMP *) &_logos_orig$TaskGroup$AKDevice$integratedCircuitCardIdentifier);
        }

        if (class_getInstanceMethod(clazz, @selector(internationalMobileEquipmentIdentity))) {
            MSHookMessageEx(
                    clazz,
                    @selector(internationalMobileEquipmentIdentity),
                    (IMP) &_logos_method$TaskGroup$AKDevice$internationalMobileEquipmentIdentity,
                    (IMP *) &_logos_orig$TaskGroup$AKDevice$internationalMobileEquipmentIdentity);
        }

        if (class_getClassMethod(clazz, @selector(_hardwareModel))) {
            MSHookMessageEx(
                    metaClazz,
                    @selector(_hardwareModel),
                    (IMP) &_logos_meta_method$TaskGroup$AKDevice$_hardwareModel,
                    (IMP *) &_logos_meta_orig$TaskGroup$AKDevice$_hardwareModel);
        }

        if (class_getClassMethod(clazz, @selector(_buildNumber))) {
            MSHookMessageEx(
                    metaClazz,
                    @selector(_buildNumber),
                    (IMP) &_logos_meta_method$TaskGroup$AKDevice$_buildNumber,
                    (IMP *) &_logos_meta_orig$TaskGroup$AKDevice$_buildNumber);
        }

        if (class_getClassMethod(clazz, @selector(_lookUpCurrentUniqueDeviceID))) {
            MSHookMessageEx(
                    metaClazz,
                    @selector(_lookUpCurrentUniqueDeviceID),
                    (IMP) &_logos_meta_method$TaskGroup$AKDevice$_lookUpCurrentUniqueDeviceID,
                    (IMP *) &_logos_meta_orig$TaskGroup$AKDevice$_lookUpCurrentUniqueDeviceID);
        }

        if (class_getClassMethod(clazz, @selector(_osVersion))) {
            MSHookMessageEx(
                    metaClazz,
                    @selector(_osVersion),
                    (IMP) &_logos_meta_method$TaskGroup$AKDevice$_osVersion,
                    (IMP *) &_logos_meta_orig$TaskGroup$AKDevice$_osVersion);
        }
    }

    // AKAppleIDCheckInHelperService
    clazz = objc_getClass("AKAppleIDCheckInHelperService");
    if (clazz) {
        if (class_getInstanceMethod(clazz, @selector(_postCheckInDataToIDMSWithAccount:pushToken:event:completion:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(_postCheckInDataToIDMSWithAccount:pushToken:event:completion:),
                    (IMP) &_logos_method$TaskGroup$AKAppleIDCheckInHelperService$_postCheckInDataToIDMSWithAccount$pushToken$event$completion$,
                    (IMP *) &_logos_orig$TaskGroup$AKAppleIDCheckInHelperService$_postCheckInDataToIDMSWithAccount$pushToken$event$completion$);
        }
    }

    // NSFileManager
    clazz = objc_getClass("NSFileManager");
    if (clazz) {
        if (class_getInstanceMethod(clazz, @selector(fileExistsAtPath:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(fileExistsAtPath:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$fileExistsAtPath$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$fileExistsAtPath$);
        }

        if (class_getInstanceMethod(clazz, @selector(fileExistsAtPath:isDirectory:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(fileExistsAtPath:isDirectory:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$fileExistsAtPath$isDirectory$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$fileExistsAtPath$isDirectory$);
        }

        if (class_getInstanceMethod(clazz, @selector(isReadableFileAtPath:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(isReadableFileAtPath:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$isReadableFileAtPath$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$isReadableFileAtPath$);
        }

        if (class_getInstanceMethod(clazz, @selector(isWritableFileAtPath:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(isWritableFileAtPath:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$isWritableFileAtPath$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$isWritableFileAtPath$);
        }

        if (class_getInstanceMethod(clazz, @selector(isExecutableFileAtPath:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(isExecutableFileAtPath:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$isExecutableFileAtPath$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$isExecutableFileAtPath$);
        }

        if (class_getInstanceMethod(clazz, @selector(isDeletableFileAtPath:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(isDeletableFileAtPath:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$isDeletableFileAtPath$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$isDeletableFileAtPath$);
        }

        if (class_getInstanceMethod(clazz, @selector(enumeratorAtPath:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(enumeratorAtPath:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$enumeratorAtPath$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$enumeratorAtPath$);
        }

        if (class_getInstanceMethod(clazz, @selector(subpathsAtPath:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(subpathsAtPath:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$subpathsAtPath$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$subpathsAtPath$);
        }

        if (class_getInstanceMethod(clazz, @selector(contentsAtPath:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(contentsAtPath:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$contentsAtPath$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$contentsAtPath$);
        }

        if (class_getInstanceMethod(clazz, @selector(createFileAtPath:contents:attributes:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(createFileAtPath:contents:attributes:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$createFileAtPath$contents$attributes$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$createFileAtPath$contents$attributes$);
        }

        if (class_getInstanceMethod(clazz, @selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$createDirectoryAtPath$withIntermediateDirectories$attributes$error$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$createDirectoryAtPath$withIntermediateDirectories$attributes$error$);
        }

        if (class_getInstanceMethod(clazz, @selector(contentsOfDirectoryAtPath:error:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(contentsOfDirectoryAtPath:error:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$contentsOfDirectoryAtPath$error$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$contentsOfDirectoryAtPath$error$);
        }

        if (class_getInstanceMethod(clazz, @selector(subpathsOfDirectoryAtPath:error:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(subpathsOfDirectoryAtPath:error:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$subpathsOfDirectoryAtPath$error$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$subpathsOfDirectoryAtPath$error$);
        }

        if (class_getInstanceMethod(clazz, @selector(attributesOfItemAtPath:error:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(attributesOfItemAtPath:error:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$attributesOfItemAtPath$error$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$attributesOfItemAtPath$error$);
        }

        if (class_getInstanceMethod(clazz, @selector(attributesOfFileSystemForPath:error:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(attributesOfFileSystemForPath:error:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$attributesOfFileSystemForPath$error$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$attributesOfFileSystemForPath$error$);
        }

        if (class_getInstanceMethod(clazz, @selector(copyItemAtPath:toPath:error:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(copyItemAtPath:toPath:error:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$copyItemAtPath$toPath$error$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$copyItemAtPath$toPath$error$);
        }

        if (class_getInstanceMethod(clazz, @selector(moveItemAtPath:toPath:error:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(moveItemAtPath:toPath:error:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$moveItemAtPath$toPath$error$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$moveItemAtPath$toPath$error$);
        }

        if (class_getInstanceMethod(clazz, @selector(linkItemAtPath:toPath:error:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(linkItemAtPath:toPath:error:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$linkItemAtPath$toPath$error$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$linkItemAtPath$toPath$error$);
        }

        if (class_getInstanceMethod(clazz, @selector(createDirectoryAtPath:attributes:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(createDirectoryAtPath:attributes:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$createDirectoryAtPath$attributes$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$createDirectoryAtPath$attributes$);
        }

        if (class_getInstanceMethod(clazz, @selector(directoryContentsAtPath:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(directoryContentsAtPath:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$directoryContentsAtPath$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$directoryContentsAtPath$);
        }

        if (class_getInstanceMethod(clazz, @selector(fileSystemAttributesAtPath:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(fileSystemAttributesAtPath:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$fileSystemAttributesAtPath$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$fileSystemAttributesAtPath$);
        }

        if (class_getInstanceMethod(clazz, @selector(fileAttributesAtPath:traverseLink:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(fileAttributesAtPath:traverseLink:),
                    (IMP) &_logos_method$TaskGroup$NSFileManager$fileAttributesAtPath$traverseLink$,
                    (IMP *) &_logos_orig$TaskGroup$NSFileManager$fileAttributesAtPath$traverseLink$);
        }
    }

    // UIApplication
    clazz = objc_getClass("UIApplication");
    if (clazz) {
        if (class_getInstanceMethod(clazz, @selector(openURL:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(openURL:),
                    (IMP) &_logos_method$TaskGroup$UIApplication$openURL$,
                    (IMP *) &_logos_orig$TaskGroup$UIApplication$openURL$);
        }

        if (class_getInstanceMethod(clazz, @selector(openURL:options:completionHandler:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(openURL:options:completionHandler:),
                    (IMP) &_logos_method$TaskGroup$UIApplication$openURL$options$completionHandler$,
                    (IMP *) &_logos_orig$TaskGroup$UIApplication$openURL$options$completionHandler$);
        }

        if (class_getInstanceMethod(clazz, @selector(canOpenURL:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(canOpenURL:),
                    (IMP) &_logos_method$TaskGroup$UIApplication$canOpenURL$,
                    (IMP *) &_logos_orig$TaskGroup$UIApplication$canOpenURL$);
        }
    }

    // NSProcessInfo
    clazz = objc_getClass("NSProcessInfo");
    if (clazz) {
        if (class_getInstanceMethod(clazz, @selector(physicalMemory))) {
            MSHookMessageEx(
                    clazz,
                    @selector(physicalMemory),
                    (IMP) &_logos_method$TaskGroup$NSProcessInfo$physicalMemory,
                    (IMP *) &_logos_orig$TaskGroup$NSProcessInfo$physicalMemory);
        }

        if (class_getInstanceMethod(clazz, @selector(processorCount))) {
            MSHookMessageEx(
                    clazz,
                    @selector(processorCount),
                    (IMP) &_logos_method$TaskGroup$NSProcessInfo$processorCount,
                    (IMP *) &_logos_orig$TaskGroup$NSProcessInfo$processorCount);
        }

        if (class_getInstanceMethod(clazz, @selector(activeProcessorCount))) {
            MSHookMessageEx(
                    clazz,
                    @selector(activeProcessorCount),
                    (IMP) &_logos_method$TaskGroup$NSProcessInfo$activeProcessorCount,
                    (IMP *) &_logos_orig$TaskGroup$NSProcessInfo$activeProcessorCount);
        }


        if (class_getInstanceMethod(clazz, @selector(hostName))) {
            MSHookMessageEx(
                    clazz,
                    @selector(hostName),
                    (IMP) &_logos_method$TaskGroup$NSProcessInfo$hostName,
                    (IMP *) &_logos_orig$TaskGroup$NSProcessInfo$hostName);
        }

        if (class_getInstanceMethod(clazz, @selector(operatingSystemVersionString))) {
            MSHookMessageEx(
                    clazz,
                    @selector(operatingSystemVersionString),
                    (IMP) &_logos_method$TaskGroup$NSProcessInfo$operatingSystemVersionString,
                    (IMP *) &_logos_orig$TaskGroup$NSProcessInfo$operatingSystemVersionString);
        }

        if (class_getInstanceMethod(clazz, @selector(operatingSystemVersion))) {
            MSHookMessageEx(
                    clazz,
                    @selector(operatingSystemVersion),
                    (IMP) &_logos_method$TaskGroup$NSProcessInfo$operatingSystemVersion,
                    (IMP *) &_logos_orig$TaskGroup$NSProcessInfo$operatingSystemVersion);
        }

        if (class_getInstanceMethod(clazz, @selector(systemUptime))) {
            MSHookMessageEx(
                    clazz,
                    @selector(systemUptime),
                    (IMP) &_logos_method$TaskGroup$NSProcessInfo$systemUptime,
                    (IMP *) &_logos_orig$TaskGroup$NSProcessInfo$systemUptime);
        }

        if (class_getInstanceMethod(clazz, @selector(environment))) {
            MSHookMessageEx(
                    clazz,
                    @selector(environment),
                    (IMP) &_logos_method$TaskGroup$NSProcessInfo$environment,
                    (IMP *) &_logos_orig$TaskGroup$NSProcessInfo$environment);
        }
    }

    // UIDevice
    clazz = objc_getClass("UIDevice");
    if (clazz) {
        if (class_getInstanceMethod(clazz, @selector(batteryLevel))) {
            MSHookMessageEx(
                    clazz,
                    @selector(batteryLevel),
                    (IMP) &_logos_method$TaskGroup$UIDevice$batteryLevel,
                    (IMP *) &_logos_orig$TaskGroup$UIDevice$batteryLevel);
        }

        if (class_getInstanceMethod(clazz, @selector(batteryState))) {
            MSHookMessageEx(
                    clazz,
                    @selector(batteryState),
                    (IMP) &_logos_method$TaskGroup$UIDevice$batteryState,
                    (IMP *) &_logos_orig$TaskGroup$UIDevice$batteryState);
        }

        if (class_getInstanceMethod(clazz, @selector(systemVersion))) {
            MSHookMessageEx(
                    clazz,
                    @selector(systemVersion),
                    (IMP) &_logos_method$TaskGroup$UIDevice$systemVersion,
                    (IMP *) &_logos_orig$TaskGroup$UIDevice$systemVersion);
        }

        if (class_getInstanceMethod(clazz, @selector(name))) {
            MSHookMessageEx(
                    clazz,
                    @selector(name),
                    (IMP) &_logos_method$TaskGroup$UIDevice$name,
                    (IMP *) &_logos_orig$TaskGroup$UIDevice$name);
        }

        if (class_getInstanceMethod(clazz, @selector(model))) {
            MSHookMessageEx(
                    clazz,
                    @selector(model),
                    (IMP) &_logos_method$TaskGroup$UIDevice$model,
                    (IMP *) &_logos_orig$TaskGroup$UIDevice$model);
        }

        if (class_getInstanceMethod(clazz, @selector(uniqueIdentifier))) {
            MSHookMessageEx(
                    clazz,
                    @selector(uniqueIdentifier),
                    (IMP) &_logos_method$TaskGroup$UIDevice$uniqueIdentifier,
                    (IMP *) &_logos_orig$TaskGroup$UIDevice$uniqueIdentifier);
        }

        if (class_getInstanceMethod(clazz, @selector(identifierForVendor))) {
            MSHookMessageEx(
                    clazz,
                    @selector(identifierForVendor),
                    (IMP) &_logos_method$TaskGroup$UIDevice$identifierForVendor,
                    (IMP *) &_logos_orig$TaskGroup$UIDevice$identifierForVendor);
        }
    }

    // NSBundle
    clazz = objc_getClass("NSBundle");
    if (clazz) {
        if (class_getInstanceMethod(clazz, @selector(objectForInfoDictionaryKey:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(objectForInfoDictionaryKey:),
                    (IMP) &_logos_method$TaskGroup$NSBundle$objectForInfoDictionaryKey$,
                    (IMP *) &_logos_orig$TaskGroup$NSBundle$objectForInfoDictionaryKey$);
        }

        if (class_getInstanceMethod(clazz, @selector(bundleIdentifier))) {
            MSHookMessageEx(
                    clazz,
                    @selector(bundleIdentifier),
                    (IMP) &_logos_method$TaskGroup$NSBundle$bundleIdentifier,
                    (IMP *) &_logos_orig$TaskGroup$NSBundle$bundleIdentifier);
        }

        if (class_getInstanceMethod(clazz, @selector(infoDictionary))) {
            MSHookMessageEx(
                    clazz,
                    @selector(infoDictionary),
                    (IMP) &_logos_method$TaskGroup$NSBundle$infoDictionary,
                    (IMP *) &_logos_orig$TaskGroup$NSBundle$infoDictionary);
        }

        if (class_getInstanceMethod(clazz, @selector(localizedInfoDictionary))) {
            MSHookMessageEx(
                    clazz,
                    @selector(localizedInfoDictionary),
                    (IMP) &_logos_method$TaskGroup$NSBundle$localizedInfoDictionary,
                    (IMP *) &_logos_orig$TaskGroup$NSBundle$localizedInfoDictionary);
        }
    }

    // ASIdentifierManager
    clazz = objc_getClass("ASIdentifierManager");
    if (clazz) {
        if (class_getInstanceMethod(clazz, @selector(advertisingIdentifier))) {
            MSHookMessageEx(
                    clazz,
                    @selector(advertisingIdentifier),
                    (IMP) &_logos_method$TaskGroup$ASIdentifierManager$advertisingIdentifier,
                    (IMP *) &_logos_orig$TaskGroup$ASIdentifierManager$advertisingIdentifier);
        }
    }

    // NSDictionary
    clazz = objc_getClass("NSDictionary");
    metaClazz = objc_getMetaClass("NSDictionary");

    if (clazz && metaClazz) {
        if (class_getClassMethod(clazz, @selector(dictionaryWithContentsOfURL:))) {
            MSHookMessageEx(
                    metaClazz,
                    @selector(dictionaryWithContentsOfURL:),
                    (IMP) &_logos_meta_method$TaskGroup$NSDictionary$dictionaryWithContentsOfURL$,
                    (IMP *) &_logos_meta_orig$TaskGroup$NSDictionary$dictionaryWithContentsOfURL$);
        }

        if (class_getClassMethod(clazz, @selector(dictionaryWithContentsOfFile:))) {
            MSHookMessageEx(
                    metaClazz,
                    @selector(dictionaryWithContentsOfFile:),
                    (IMP) &_logos_meta_method$TaskGroup$NSDictionary$dictionaryWithContentsOfFile$,
                    (IMP *) &_logos_meta_orig$TaskGroup$NSDictionary$dictionaryWithContentsOfFile$);
        }

        if (class_getInstanceMethod(clazz, @selector(initWithContentsOfURL:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(initWithContentsOfURL:),
                    (IMP) &_logos_method$TaskGroup$NSDictionary$initWithContentsOfURL$,
                    (IMP *) &_logos_orig$TaskGroup$NSDictionary$initWithContentsOfURL$);
        }

        if (class_getInstanceMethod(clazz, @selector(initWithContentsOfFile:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(initWithContentsOfFile:),
                    (IMP) &_logos_method$TaskGroup$NSDictionary$initWithContentsOfFile$,
                    (IMP *) &_logos_orig$TaskGroup$NSDictionary$initWithContentsOfFile$);
        }
    }

    // NSData
    clazz = objc_getClass("NSData");
    metaClazz = objc_getMetaClass("NSData");

    if (clazz && metaClazz) {
        if (class_getClassMethod(clazz, @selector(dataWithContentsOfFile:))) {
            MSHookMessageEx(
                    metaClazz,
                    @selector(dataWithContentsOfFile:),
                    (IMP) &_logos_meta_method$TaskGroup$NSData$dataWithContentsOfFile$,
                    (IMP *) &_logos_meta_orig$TaskGroup$NSData$dataWithContentsOfFile$);
        }

        if (class_getClassMethod(clazz, @selector(dataWithContentsOfFile:options:error:))) {
            MSHookMessageEx(
                    metaClazz,
                    @selector(dataWithContentsOfFile:options:error:),
                    (IMP) &_logos_meta_method$TaskGroup$NSData$dataWithContentsOfFile$options$error$,
                    (IMP *) &_logos_meta_orig$TaskGroup$NSData$dataWithContentsOfFile$options$error$);
        }

        if (class_getInstanceMethod(clazz, @selector(initWithContentsOfFile:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(initWithContentsOfFile:),
                    (IMP) &_logos_method$TaskGroup$NSData$initWithContentsOfFile$,
                    (IMP *) &_logos_orig$TaskGroup$NSData$initWithContentsOfFile$);
        }

        if (class_getInstanceMethod(clazz, @selector(initWithContentsOfFile:options:error:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(initWithContentsOfFile:options:error:),
                    (IMP) &_logos_method$TaskGroup$NSData$initWithContentsOfFile$options$error$,
                    (IMP *) &_logos_orig$TaskGroup$NSData$initWithContentsOfFile$options$error$);
        }
    }

    // __NSCFConstantString
    clazz = objc_getClass("__NSCFConstantString");
    if (clazz && class_getInstanceMethod(clazz, @selector(hasPrefix:))) {
        MSHookMessageEx(
                clazz,
                @selector(hasPrefix:),
                (IMP) &_logos_method$TaskGroup$__NSCFConstantString$hasPrefix$,
                (IMP *) &_logos_orig$TaskGroup$__NSCFConstantString$hasPrefix$);
    }

    // __NSCFString
    clazz = objc_getClass("__NSCFString");
    if (clazz) {
        if (class_getInstanceMethod(clazz, @selector(hasPrefix:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(hasPrefix:),
                    (IMP) &_logos_method$TaskGroup$__NSCFString$hasPrefix$,
                    (IMP *) &_logos_orig$TaskGroup$__NSCFString$hasPrefix$);
        }

        if (class_getInstanceMethod(clazz, @selector(substringToIndex:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(substringToIndex:),
                    (IMP) &_logos_method$TaskGroup$__NSCFString$substringToIndex$,
                    (IMP *) &_logos_orig$TaskGroup$__NSCFString$substringToIndex$);
        }
    }

    // NSString
    clazz = objc_getClass("NSString");
    metaClazz = objc_getMetaClass("NSString");

    if (clazz && metaClazz) {
        if (class_getInstanceMethod(clazz, @selector(substringToIndex:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(substringToIndex:),
                    (IMP) &_logos_method$TaskGroup$NSString$substringToIndex$,
                    (IMP *) &_logos_orig$TaskGroup$NSString$substringToIndex$);
        }

        if (class_getInstanceMethod(clazz, @selector(hasPrefix:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(hasPrefix:),
                    (IMP) &_logos_method$TaskGroup$NSString$hasPrefix$,
                    (IMP *) &_logos_orig$TaskGroup$NSString$hasPrefix$);
        }

        if (class_getInstanceMethod(clazz, @selector(compareVersionNumberWithString:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(compareVersionNumberWithString:),
                    (IMP) &_logos_method$TaskGroup$NSString$compareVersionNumberWithString$,
                    (IMP *) &_logos_orig$TaskGroup$NSString$compareVersionNumberWithString$);
        }

        if (class_getInstanceMethod(clazz, @selector(intValue))) {
            MSHookMessageEx(
                    clazz,
                    @selector(intValue),
                    (IMP) &_logos_method$TaskGroup$NSString$intValue,
                    (IMP *) &_logos_orig$TaskGroup$NSString$intValue);
        }

        if (class_getInstanceMethod(clazz, @selector(integerValue))) {
            MSHookMessageEx(
                    clazz,
                    @selector(integerValue),
                    (IMP) &_logos_method$TaskGroup$NSString$integerValue,
                    (IMP *) &_logos_orig$TaskGroup$NSString$integerValue);
        }

        if (class_getInstanceMethod(clazz, @selector(floatValue))) {
            MSHookMessageEx(
                    clazz,
                    @selector(floatValue),
                    (IMP) &_logos_method$TaskGroup$NSString$floatValue,
                    (IMP *) &_logos_orig$TaskGroup$NSString$floatValue);
        }

        if (class_getInstanceMethod(clazz, @selector(doubleValue))) {
            MSHookMessageEx(
                    clazz,
                    @selector(doubleValue),
                    (IMP) &_logos_method$TaskGroup$NSString$doubleValue,
                    (IMP *) &_logos_orig$TaskGroup$NSString$doubleValue);
        }

        if (class_getInstanceMethod(clazz, @selector(componentsSeparatedByString:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(componentsSeparatedByString:),
                    (IMP) &_logos_method$TaskGroup$NSString$componentsSeparatedByString$,
                    (IMP *) &_logos_orig$TaskGroup$NSString$componentsSeparatedByString$);
        }

        if (class_getInstanceMethod(clazz, @selector(compare:options:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(compare:options:),
                    (IMP) &_logos_method$TaskGroup$NSString$compare$options$,
                    (IMP *) &_logos_orig$TaskGroup$NSString$compare$options$);
        }

        if (class_getInstanceMethod(clazz, @selector(initWithContentsOfFile:encoding:error:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(initWithContentsOfFile:encoding:error:),
                    (IMP) &_logos_method$TaskGroup$NSString$initWithContentsOfFile$encoding$error$,
                    (IMP *) &_logos_orig$TaskGroup$NSString$initWithContentsOfFile$encoding$error$);
        }

        if (/* DISABLES CODE */ (0)) {
            if (class_getInstanceMethod(clazz, @selector(initWithFormat:arguments:))) {
                MSHookMessageEx(
                        clazz,
                        @selector(initWithFormat:arguments:),
                        (IMP) &_logos_method$TaskGroup$NSString$initWithFormat$arguments$,
                        (IMP *) &_logos_orig$TaskGroup$NSString$initWithFormat$arguments$);
            }

            if (class_getInstanceMethod(clazz, @selector(initWithFormat:))) {
                MSHookMessageEx(
                        clazz,
                        @selector(initWithFormat:),
                        (IMP) &_logos_method$TaskGroup$NSString$initWithFormat$,
                        (IMP *) &_logos_orig$TaskGroup$NSString$initWithFormat$);
            }
        }

        if (class_getClassMethod(clazz, @selector(stringWithContentsOfFile:encoding:error:))) {
            MSHookMessageEx(
                    metaClazz,
                    @selector(stringWithContentsOfFile:encoding:error:),
                    (IMP) &_logos_meta_method$TaskGroup$NSString$stringWithContentsOfFile$encoding$error$,
                    (IMP *) &_logos_meta_orig$TaskGroup$NSString$stringWithContentsOfFile$encoding$error$);
        }
    }

    // NSConcreteScanner
    clazz = objc_getClass("NSConcreteScanner");
    if (clazz && class_getInstanceMethod(clazz, @selector(initWithString:))) {
        MSHookMessageEx(
                clazz,
                @selector(initWithString:),
                (IMP) &_logos_method$TaskGroup$NSConcreteScanner$initWithString$,
                (IMP *) &_logos_orig$TaskGroup$NSConcreteScanner$initWithString$);
    }

    // NSArray
    clazz = objc_getClass("NSArray");
    metaClazz = objc_getMetaClass("NSArray");

    if (clazz && metaClazz) {
        if (class_getInstanceMethod(clazz, @selector(initWithContentsOfFile:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(initWithContentsOfFile:),
                    (IMP) &_logos_method$TaskGroup$NSArray$initWithContentsOfFile$,
                    (IMP *) &_logos_orig$TaskGroup$NSArray$initWithContentsOfFile$);
        }

        if (class_getClassMethod(clazz, @selector(arrayWithContentsOfFile:))) {
            MSHookMessageEx(
                    metaClazz,
                    @selector(arrayWithContentsOfFile:),
                    (IMP) &_logos_meta_method$TaskGroup$NSArray$arrayWithContentsOfFile$,
                    (IMP *) &_logos_meta_orig$TaskGroup$NSArray$arrayWithContentsOfFile$);
        }
    }

    // UIPasteboard
    clazz = objc_getClass("UIPasteboard");
    if (clazz && class_getInstanceMethod(clazz, @selector(setPersistent:))) {
        MSHookMessageEx(
                clazz,
                @selector(setPersistent:),
                (IMP) &_logos_method$TaskGroup$UIPasteboard$setPersistent$,
                (IMP *) &_logos_orig$TaskGroup$UIPasteboard$setPersistent$);
    }

    // NSURL
    clazz = objc_getClass("NSURL");
    if (clazz && class_getInstanceMethod(clazz, @selector(checkResourceIsReachableAndReturnError:))) {
        MSHookMessageEx(
                clazz,
                @selector(checkResourceIsReachableAndReturnError:),
                (IMP) &_logos_method$TaskGroup$NSURL$checkResourceIsReachableAndReturnError$,
                (IMP *) &_logos_orig$TaskGroup$NSURL$checkResourceIsReachableAndReturnError$);
    }

    // NSURLRequest
    clazz = objc_getClass("NSURLRequest");
    metaClazz = objc_getMetaClass("NSURLRequest");

    if (clazz && metaClazz) {
        if (class_getClassMethod(clazz, @selector(requestWithURL:))) {
            MSHookMessageEx(
                    metaClazz,
                    @selector(requestWithURL:),
                    (IMP) &_logos_meta_method$TaskGroup$NSURLRequest$requestWithURL$,
                    (IMP *) &_logos_meta_orig$TaskGroup$NSURLRequest$requestWithURL$);
        }

        if (class_getClassMethod(clazz, @selector(requestWithURL:cachePolicy:timeoutInterval:))) {
            MSHookMessageEx(
                    metaClazz,
                    @selector(requestWithURL:cachePolicy:timeoutInterval:),
                    (IMP) &_logos_meta_method$TaskGroup$NSURLRequest$requestWithURL$cachePolicy$timeoutInterval$,
                    (IMP *) &_logos_meta_orig$TaskGroup$NSURLRequest$requestWithURL$cachePolicy$timeoutInterval$);
        }

        if (class_getInstanceMethod(clazz, @selector(initWithURL:cachePolicy:timeoutInterval:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(initWithURL:cachePolicy:timeoutInterval:),
                    (IMP) &_logos_method$TaskGroup$NSURLRequest$initWithURL$cachePolicy$timeoutInterval$,
                    (IMP *) &_logos_orig$TaskGroup$NSURLRequest$initWithURL$cachePolicy$timeoutInterval$);
        }

        if (class_getInstanceMethod(clazz, @selector(initWithURL:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(initWithURL:),
                    (IMP) &_logos_method$TaskGroup$NSURLRequest$initWithURL$,
                    (IMP *) &_logos_orig$TaskGroup$NSURLRequest$initWithURL$);
        }
    }

    // NSMutableURLRequest
    clazz = objc_getClass("NSMutableURLRequest");
    if (clazz) {
        if (class_getInstanceMethod(clazz, @selector(setAllHTTPHeaderFields:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(setAllHTTPHeaderFields:),
                    (IMP) &_logos_method$TaskGroup$NSMutableURLRequest$setAllHTTPHeaderFields$,
                    (IMP *) &_logos_orig$TaskGroup$NSMutableURLRequest$setAllHTTPHeaderFields$);
        }

        if (class_getInstanceMethod(clazz, @selector(setValue:forHTTPHeaderField:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(setValue:forHTTPHeaderField:),
                    (IMP) &_logos_method$TaskGroup$NSMutableURLRequest$setValue$forHTTPHeaderField$,
                    (IMP *) &_logos_orig$TaskGroup$NSMutableURLRequest$setValue$forHTTPHeaderField$);
        }

        if (class_getInstanceMethod(clazz, @selector(addValue:forHTTPHeaderField:))) {
            MSHookMessageEx(
                    clazz,
                    @selector(addValue:forHTTPHeaderField:),
                    (IMP) &_logos_method$TaskGroup$NSMutableURLRequest$addValue$forHTTPHeaderField$,
                    (IMP *) &_logos_orig$TaskGroup$NSMutableURLRequest$addValue$forHTTPHeaderField$);
        }
    }

    // ISDevice
    clazz = objc_getClass("ISDevice");
    if (clazz) {
        if (class_getInstanceMethod(clazz, @selector(guid))) {
            MSHookMessageEx(
                    clazz,
                    @selector(guid),
                    (IMP) &_logos_method$TaskGroup$ISDevice$guid,
                    (IMP *) &_logos_orig$TaskGroup$ISDevice$guid);
        }

        if (class_getInstanceMethod(clazz, @selector(serialNumber))) {
            MSHookMessageEx(
                    clazz,
                    @selector(serialNumber),
                    (IMP) &_logos_method$TaskGroup$ISDevice$serialNumber,
                    (IMP *) &_logos_orig$TaskGroup$ISDevice$serialNumber);
        }
    }

    // WebGeolocationCoreLocationProvider
    clazz = objc_getClass("WebGeolocationCoreLocationProvider");
    if (clazz && class_getInstanceMethod(clazz, @selector(locationManager:didUpdateLocations:))) {
        MSHookMessageEx(
                clazz,
                @selector(locationManager:didUpdateLocations:),
                (IMP) &_logos_method$TaskGroup$WebGeolocationCoreLocationProvider$locationManager$didUpdateLocations$,
                (IMP *) &_logos_orig$TaskGroup$WebGeolocationCoreLocationProvider$locationManager$didUpdateLocations$);
    }

    // MKCoreLocationProvider
    clazz = objc_getClass("MKCoreLocationProvider");
    if (clazz && class_getInstanceMethod(clazz, @selector(locationManager:didUpdateLocations:))) {
        MSHookMessageEx(
                clazz,
                @selector(locationManager:didUpdateLocations:),
                (IMP) &_logos_method$TaskGroup$MKCoreLocationProvider$locationManager$didUpdateLocations$,
                (IMP *) &_logos_orig$TaskGroup$MKCoreLocationProvider$locationManager$didUpdateLocations$);
    }

    // MIFileManager
    clazz = objc_getClass("MIFileManager");
    if (clazz && class_getInstanceMethod(clazz, @selector(urlsForItemsInDirectoryAtURL:ignoringSymlinks:error:))) {
        MSHookMessageEx(
                clazz,
                @selector(urlsForItemsInDirectoryAtURL:ignoringSymlinks:error:),
                (IMP) &_logos_method$TaskGroup$MIFileManager$urlsForItemsInDirectoryAtURL$ignoringSymlinks$error$,
                (IMP *) &_logos_orig$TaskGroup$MIFileManager$urlsForItemsInDirectoryAtURL$ignoringSymlinks$error$);
    }

    // CTTelephonyNetworkInfo
    clazz = objc_getClass("CTTelephonyNetworkInfo");
    if (clazz) {
        if (class_getInstanceMethod(clazz, @selector(subscriberCellularProvider))) {
            MSHookMessageEx(
                    clazz,
                    @selector(subscriberCellularProvider),
                    (IMP) &_logos_method$TaskGroup$CTTelephonyNetworkInfo$subscriberCellularProvider,
                    (IMP *) &_logos_orig$TaskGroup$CTTelephonyNetworkInfo$subscriberCellularProvider);
        }

        if (class_getInstanceMethod(clazz, @selector(currentRadioAccessTechnology))) {
            MSHookMessageEx(
                    clazz,
                    @selector(currentRadioAccessTechnology),
                    (IMP) &_logos_method$TaskGroup$CTTelephonyNetworkInfo$currentRadioAccessTechnology,
                    (IMP *) &_logos_orig$TaskGroup$CTTelephonyNetworkInfo$currentRadioAccessTechnology);
        }
    }

    // NSException
    if (CRK_FAKE_HIGH_LEVEL) {
        clazz = [NSException class];
        if (clazz) {
            if (class_getInstanceMethod(clazz, @selector(callStackSymbols))) {
                MSHookMessageEx(
                        clazz,
                        @selector(callStackSymbols),
                        (IMP) &_logos_method$TaskGroup$NSException$callStackSymbols,
                        (IMP *) &_logos_orig$TaskGroup$NSException$callStackSymbols);
            }

            if (class_getInstanceMethod(clazz, @selector(callStackReturnAddresses))) {
                MSHookMessageEx(
                        clazz,
                        @selector(callStackReturnAddresses),
                        (IMP) &_logos_method$TaskGroup$NSException$callStackReturnAddresses,
                        (IMP *) &_logos_orig$TaskGroup$NSException$callStackReturnAddresses);
            }

            if (class_getInstanceMethod(clazz, @selector(name))) {
                MSHookMessageEx(
                        clazz,
                        @selector(name),
                        (IMP) &_logos_method$TaskGroup$NSException$name,
                        (IMP *) &_logos_orig$TaskGroup$NSException$name);
            }
        }
    }

    // NSThread
    if (CRK_FAKE_HIGH_LEVEL) {
        clazz = [NSThread class];
        metaClazz = objc_getMetaClass("NSThread");

        if (clazz && metaClazz) {
            if (class_getClassMethod(clazz, @selector(callStackSymbols))) {
                MSHookMessageEx(
                        metaClazz,
                        @selector(callStackSymbols),
                        (IMP) &_logos_method$TaskGroup$NSThread$callStackSymbols,
                        (IMP *) &_logos_orig$TaskGroup$NSThread$callStackSymbols);
            }

            if (class_getClassMethod(clazz, @selector(callStackReturnAddresses))) {
                MSHookMessageEx(
                        metaClazz,
                        @selector(callStackReturnAddresses),
                        (IMP) &_logos_method$TaskGroup$NSThread$callStackReturnAddresses,
                        (IMP *) &_logos_orig$TaskGroup$NSThread$callStackReturnAddresses);
            }
        }
    }

    // Inject api related to the system:
    [self hookOSVersionAPIs];

    // methods
    MSHookFunction(
            (char *) &MGCopyAnswer + 8,
            (void *) Fake_MGCopyAnswer,
            (void **) &Origin_MGCopyAnswer);

    MSHookFunction(
            (void *) sysctl,
            (void *) Fake_sysctl,
            (void **) &Origin_sysctl);
    MSHookFunction(
            &_CTServerConnectionCellMonitorCopyCellInfo,
            (void *) Fake_CTServerConnectionCellMonitorCopyCellInfo,
            (void **) &Origin_CTServerConnectionCellMonitorCopyCellInfo);
    MSHookFunction(
            &_CTServerConnectionGetLocationAreaCode,
            (void *) Fake_CTServerConnectionGetLocationAreaCode,
            (void **) &Origin_CTServerConnectionGetLocationAreaCode);
    MSHookFunction(
            &_CTServerConnectionGetCellID,
            (void *) Fake_CTServerConnectionGetCellID,
            (void **) &Origin_CTServerConnectionGetCellID);
    MSHookFunction(
            &_CTServerConnectionGetSIMStatus,
            (void *) Fake_CTServerConnectionGetSIMStatus,
            (void **) &Origin_CTServerConnectionGetSIMStatus);
    MSHookFunction(
            &_CTServerConnectionGetSIMTrayStatus,
            (void *) Fake_CTServerConnectionGetSIMTrayStatus,
            (void **) &Origin_CTServerConnectionGetSIMTrayStatus);
    MSHookFunction(
            &_CTServerConnectionCopySIMIdentity,
            (void *) Fake_CTServerConnectionCopySIMIdentity,
            (void **) &Origin_CTServerConnectionCopySIMIdentity);
    MSHookFunction(
            &_CTServerConnectionCopyMobileSubscriberIdentity,
            (void *) Fake_CTServerConnectionCopyMobileSubscriberIdentity,
            (void **) &Origin_CTServerConnectionCopyMobileSubscriberIdentity);
    MSHookFunction(
            &_CTServerConnectionCopyEffectiveSimInfo,
            (void *) Fake_CTServerConnectionCopyEffectiveSimInfo,
            (void **) &Origin_CTServerConnectionCopyEffectiveSimInfo);
    MSHookFunction(
            &_CTServerConnectionCopyPhoneNumber,
            (void *) Fake_CTServerConnectionCopyPhoneNumber,
            (void **) &Origin_CTServerConnectionCopyPhoneNumber);
    MSHookFunction(
            &CTSettingCopyMyPhoneNumberExtended,
            (void *) Fake_CTSettingCopyMyPhoneNumberExtended,
            (void **) &Origin_CTSettingCopyMyPhoneNumberExtended);
    MSHookFunction(
            &CTRegistrationGetDataIndicator,
            (void *) Fake_CTRegistrationGetDataIndicator,
            (void **) &Origin_CTRegistrationGetDataIndicator);
    MSHookFunction(
            &_CTServerConnectionCopyGid1,
            (void *) Fake_CTServerConnectionCopyGid1,
            (void **) &Origin_CTServerConnectionCopyGid1);
    MSHookFunction(
            &_CTServerConnectionCopyGid2,
            (void *) Fake_CTServerConnectionCopyGid2,
            (void **) &Origin_CTServerConnectionCopyGid2);
    MSHookFunction(
            &_CTServerConnectionCopyMobileCountryCode,
            (void *) Fake_CTServerConnectionCopyMobileCountryCode,
            (void **) &Origin_CTServerConnectionCopyMobileCountryCode);
    MSHookFunction(
            &_CTServerConnectionCopyMobileSubscriberCountryCode,
            (void *) Fake_CTServerConnectionCopyMobileSubscriberCountryCode,
            (void **) &Origin_CTServerConnectionCopyMobileSubscriberCountryCode);
    MSHookFunction(
            &_CTServerConnectionCopyMobileNetworkCode,
            (void *) Fake_CTServerConnectionCopyMobileNetworkCode,
            (void **) &Origin_CTServerConnectionCopyMobileNetworkCode);
    MSHookFunction(
            &_CTServerConnectionCopyMobileSubscriberNetworkCode,
            (void *) Fake_CTServerConnectionCopyMobileSubscriberNetworkCode,
            (void **) &Origin_CTServerConnectionCopyMobileSubscriberNetworkCode);
    MSHookFunction(
            &_CTServerConnectionCopyPostponementStatus,
            (void *) Fake_CTServerConnectionCopyPostponementStatus,
            (void **) &Origin_CTServerConnectionCopyPostponementStatus);
    MSHookFunction(
            &_CTServerConnectionCopyCarrierBundleInfoArray,
            (void *) Fake_CTServerConnectionCopyCarrierBundleInfoArray,
            (void **) &Origin_CTServerConnectionCopyCarrierBundleInfoArray);
    MSHookFunction(
            &_CTServerConnectionCopyProviderNameUsingCarrierBundle,
            (void *) Fake_CTServerConnectionCopyProviderNameUsingCarrierBundle,
            (void **) &Origin_CTServerConnectionCopyProviderNameUsingCarrierBundle);
    MSHookFunction(
            &_CTServerConnectionCopyMobileEquipmentInfo,
            (void *) Fake_CTServerConnectionCopyMobileEquipmentInfo,
            (void **) &Origin_CTServerConnectionCopyMobileEquipmentInfo);
    MSHookFunction(
            &_CTServerConnectionCopyMobileIdentity,
            (void *) Fake_CTServerConnectionCopyMobileIdentity,
            (void **) &Origin_CTServerConnectionCopyMobileIdentity);
    MSHookFunction(
            &_CTServerConnectionGetActiveWirelessTechnology,
            (void *) Fake_CTServerConnectionGetActiveWirelessTechnology,
            (void **) &Origin_CTServerConnectionGetActiveWirelessTechnology);
    MSHookFunction(
            &_CTServerConnectionGetPhoneNumberRegistrationState,
            (void *) Fake_CTServerConnectionGetPhoneNumberRegistrationState,
            (void **) &Origin_CTServerConnectionGetPhoneNumberRegistrationState);
    MSHookFunction(
            (void *) uname,
            (void *) Fake_uname,
            (void **) &Origin_uname);
    MSHookFunction(
            (void *) sysctlbyname,
            (void *) Fake_sysctlbyname,
            (void **) &Origin_sysctlbyname);
    MSHookFunction(
            (void *) getenv,
            (void *) Fake_getenv,
            (void **) &Origin_getenv);
    MSHookFunction(
            (void *) _dyld_get_image_name,
            (void *) Fake_dyld_get_image_name,
            (void **) &Origin_dyld_get_image_name);
    MSHookFunction(
            (void *) _dyld_image_count,
            (void *) Fake_dyld_image_count,
            (void **) &Origin_dyld_image_count);
    MSHookFunction(
            (void *) _dyld_get_image_header,
            (void *) Fake_dyld_get_image_header,
            (void **) &Origin_dyld_get_image_header);
    MSHookFunction(
            (void *) _dyld_get_image_vmaddr_slide,
            (void *) Fake_dyld_get_image_vmaddr_slide,
            (void **) &Origin_dyld_get_image_vmaddr_slide);
    MSHookFunction(
            (void *) _dyld_register_func_for_add_image,
            (void *) Fake_dyld_register_func_for_add_image,
            (void **) &Origin_dyld_register_func_for_add_image);
    MSHookFunction(
            (void *) _dyld_register_func_for_remove_image,
            (void *) Fake_dyld_register_func_for_remove_image,
            (void **) &Origin_dyld_register_func_for_remove_image);
    MSHookFunction(
            (void *) MSFindSymbol(NULL, "_ptrace"),
            (void *) Fake_ptrace,
            (void **) &Origin_ptrace);

    // MobileInstallationLookup
    void *mobileInstallationFrameworkHandle = dlopen("/System/Library/PrivateFrameworks/MobileInstallation.framework/MobileInstallation", RTLD_NOW);
    if (mobileInstallationFrameworkHandle) {
        CFDictionaryRef (*MobileInstallationLookup)(CFDictionaryRef) = dlsym(mobileInstallationFrameworkHandle, "MobileInstallationLookup");

        MSHookFunction((void *) MobileInstallationLookup, (void *) Fake_MobileInstallationLookup, (void **) &Origin_MobileInstallationLookup);
    }

    MSHookFunction((void *) stat, (void *) Fake_stat, (void **) &Origin_stat);
    MSHookFunction((void *) lstat, (void *) Fake_lstat, (void **) &Origin_lstat);
    MSHookFunction((void *) _CFCopySystemVersionDictionary, (void *) Fake_CFCopySystemVersionDictionary, (void **) &Origin_CFCopySystemVersionDictionary);
    MSHookFunction((void *) CFBundleGetInfoDictionary, (void *) Fake_CFBundleGetInfoDictionary, (void **) &Origin_CFBundleGetInfoDictionary);

    if (![[CRKInjectContext shared].origSystemVersion hasPrefix:@"10."]) {
        MSHookFunction((void *) CFHTTPMessageCreateRequest, (void *) Fake_CFHTTPMessageCreateRequest, (void **) &Origin_CFHTTPMessageCreateRequest);
        MSHookFunction((void *) CFURLRequestCreate, (void *) Fake_CFURLRequestCreate, (void **) &Origin_CFURLRequestCreate);
        MSHookFunction((void *) CFURLRequestSetURL, (void *) Fake_CFURLRequestSetURL, (void **) &Origin_CFURLRequestSetURL);
    }

    if ([CRKInjectContext shared].isInApp) {
        MSHookFunction((void *) system, (void *) Fake_system, (void **) &Origin_system);
        MSHookFunction((void *) fork, (void *) Fake_fork, (void **) &Origin_fork);
        MSHookFunction((void *) dlopen, (void *) Fake_dlopen, (void **) &Origin_dlopen);
        MSHookFunction((void *) fopen, (void *) Fake_fopen, (void **) &Origin_fopen);
        MSHookFunction((void *) __opendir2, (void *) Fake_opendir2, (void **) &Origin_opendir2);
        MSHookFunction((void *) dladdr, (void *) Fake_dladdr, (void **) &Origin_dladdr);
        MSHookFunction((void *) statfs, (void *) Fake_statfs, (void **) &Origin_statfs);
        MSHookFunction((void *) getsectbyname, (void *) Fake_getsectbyname, (void **) &Origin_getsectbyname);

        void *libSwiftCoreHandle = dlopen("@rpath/libswiftCore.dylib", RTLD_NOW);
        if (libSwiftCoreHandle) {
            _SwiftNSOperatingSystemVersion (*_swift_stdlib_operatingSystemVersion)(void) = dlsym(libSwiftCoreHandle, "_swift_stdlib_operatingSystemVersion");

            if (_swift_stdlib_operatingSystemVersion) {
                MSHookFunction(
                        (void *) _swift_stdlib_operatingSystemVersion,
                        (void *) Fake__swift_stdlib_operatingSystemVersion,
                        (void **) &Origin__swift_stdlib_operatingSystemVersion);
            }
        }

        // liberty
        MSHookFunction((void *) access, (void *) Fake_access, (void **) &Origin_access);
        MSHookFunction((void *) faccessat, (void *) Fake_faccessat, (void **) &Origin_faccessat);
        MSHookFunction((void *) CFBundleGetAllBundles, (void *) Fake_CFBundleGetAllBundles, (void **) &Origin_CFBundleGetAllBundles);
        MSHookFunction((void *) dlsym, (void *) Fake_dlsym, (void **) &Origin_dlsym);

//        rebind_symbols((struct rebinding[1]) {{"open", fakefish_open, (void *) &origfish_open}}, 1);

        MSHookFunction((void *) open, (void *) Fake_open, (void **) &Origin_open);
//        MSHookFunction((void *) opendir, (void *) Fake_opendir, (void **) &Origin_opendir);
        MSHookFunction((void *) symlink, (void *) Fake_symlink, (void **) &Origin_symlink);
        MSHookFunction((void *) vfork, (void *) Fake_vfork, (void **) &Origin_vfork);
        MSHookFunction((void *) syscall, (void *) Fake_syscall, (void **) &Origin_syscall);

        // WC
        MSHookFunction((void *) remove, (void *) Fake_remove, (void **) &Origin_remove);
        MSHookFunction((void *) rename, (void *) Fake_rename, (void **) &Origin_rename);
//        MSHookFunction((void *) mig_get_reply_port, (void *) Fake_mig_get_reply_port, (void **) &Origin_mig_get_reply_port);
//        MSHookFunction((void *) mig_put_reply_port, (void *) Fake_mig_put_reply_port, (void **) &Origin_mig_put_reply_port);

//        MSHookFunction((void *) strlen, (void *) Fake_strlen, (void **) &Origin_strlen);
        MSHookFunction((void *) task_info, (void *) Fake_task_info, (void **) &Origin_task_info);

        // crash
        MSHookFunction((void *) NSSetUncaughtExceptionHandler, (void *) Fake_NSSetUncaughtExceptionHandler, (void **) &Origin_NSSetUncaughtExceptionHandler);
        MSHookFunction((void *) signal, (void *) Fake_signal, (void **) &Origin_signal);
        MSHookFunction((void *) task_set_exception_ports, (void *) Fake_task_set_exception_ports, (void **) &Origin_task_set_exception_ports);
        MSHookFunction((void *) sigaltstack, (void *) Fake_sigaltstack, (void **) &Origin_sigaltstack);
        MSHookFunction((void *) sigaction, (void *) Fake_sigaction, (void **) &Origin_sigaction);

        // sub_102C30
        if ([CRKWCTools isInWCProcess]) {

            // keychain
            MSHookFunction((void *) SecItemCopyMatching,
                    (void *) Fake_SecItemCopyMatching,
                    (void **) &Origin_SecItemCopyMatching);

            MSHookFunction((void *) SecItemUpdate,
                    (void *) Fake_SecItemUpdate,
                    (void **) &Origin_SecItemUpdate);

            MSHookFunction((void *) SecItemAdd,
                    (void *) Fake_SecItemAdd,
                    (void **) &Origin_SecItemAdd);

            MSHookFunction((void *) SecItemDelete,
                    (void *) Fake_SecItemDelete,
                    (void **) &Origin_SecItemDelete);

            MSHookFunction(
                    (void *) getifaddrs,
                    (void *) Fake_getifaddrs,
                    (void **) &Origin_getifaddrs);
            MSHookFunction(
                    (void *) freeifaddrs,
                    (void *) Fake_freeifaddrs,
                    (void **) &Origin_freeifaddrs);
            MSHookFunction(
                    &CNCopyCurrentNetworkInfo,
                    (void *) Fake_CNCopyCurrentNetworkInfo,
                    (void **) &Origin_CNCopyCurrentNetworkInfo);
            MSHookFunction(
                    &SCNetworkReachabilityGetFlags,
                    (void *) Fake_SCNetworkReachabilityGetFlags,
                    (void **) &Origin_SCNetworkReachabilityGetFlags);
//            MSHookFunction(
//                    &SCNetworkReachabilitySetCallback,
//                    (void *) Fake_SCNetworkReachabilitySetCallback,
//                    (void **) &Origin_SCNetworkReachabilitySetCallback);

            __CRK_HookWCMethods();
        }
    }

    // UIScreen
    clazz = objc_getClass("UIScreen");
    if (clazz) {
        if (class_getInstanceMethod(clazz, NSSelectorFromString(@"_mainSceneBoundsForInterfaceOrientation:"))) {
            MSHookMessageEx(
                    clazz,
                    NSSelectorFromString(@"_mainSceneBoundsForInterfaceOrientation:"),
                    (IMP) &_logos_method$ScreenGroup$UIScreen$_mainSceneBoundsForInterfaceOrientation$,
                    (IMP *) &_logos_orig$ScreenGroup$UIScreen$_mainSceneBoundsForInterfaceOrientation$);
        }

        if (class_getInstanceMethod(clazz, NSSelectorFromString(@"_boundsForInterfaceOrientation:"))) {
            MSHookMessageEx(
                    clazz,
                    NSSelectorFromString(@"_boundsForInterfaceOrientation:"),
                    (IMP) &_logos_method$ScreenGroup$UIScreen$_boundsForInterfaceOrientation$,
                    (IMP *) &_logos_orig$ScreenGroup$UIScreen$_boundsForInterfaceOrientation$);
        }

        if (class_getInstanceMethod(clazz, NSSelectorFromString(@"_mainSceneReferenceBoundsForSettings:"))) {
            MSHookMessageEx(
                    clazz,
                    NSSelectorFromString(@"_mainSceneReferenceBoundsForSettings:"),
                    (IMP) &_logos_method$ScreenGroup$UIScreen$_mainSceneReferenceBoundsForSettings$,
                    (IMP *) &_logos_orig$ScreenGroup$UIScreen$_mainSceneReferenceBoundsForSettings$);
        }

        if (class_getInstanceMethod(clazz, NSSelectorFromString(@"_scale"))) {
            MSHookMessageEx(
                    clazz,
                    NSSelectorFromString(@"_scale"),
                    (IMP) &_logos_method$ScreenGroup$UIScreen$_scale,
                    (IMP *) &_logos_orig$ScreenGroup$UIScreen$_scale);
        }
    }

    if (![CRKInjectContext shared].lmDidUpdateLocationsDelegates) {
        [CRKInjectContext shared].lmDidUpdateLocationsDelegates = [[NSMutableDictionary alloc] init];
        [CRKInjectContext shared].lmDidUpdateToLocationFromLocationDelegates = [[NSMutableDictionary alloc] init];
        [CRKInjectContext shared].lmLocationFailDelegates = [[NSMutableDictionary alloc] init];
        [CRKInjectContext shared].remoteDeviceTokenDelegates = [[NSMutableDictionary alloc] init];
    }

    if ([CRKInjectContext shared].isInApp
            || strcmp(progName, "MobileSafari") == 0) {

        int allClazzesCount = objc_getClassList(nil, 0);
        if (allClazzesCount > 0) {
            Class *allClazzes = (Class *) malloc(sizeof(Class) * allClazzesCount);

            if (allClazzes) {
                allClazzesCount = objc_getClassList(allClazzes, (unsigned int) allClazzesCount);

                for (int i = 0; i < allClazzesCount; ++i) {
                    @autoreleasepool {
                        Class theClazz = allClazzes[i];
                        NSString *theClazzName = NSStringFromClass(theClazz);

//                        if (class_conformsToProtocol(theClazz, @protocol(CLLocationManagerDelegate))) {
//                            IMP locationMethod = __CRK_FindMethod(theClazz, @"locationManager:didUpdateLocations:");
//                            if (locationMethod) {
//                                if (![theClazzName isEqualToString:@"WebGeolocationCoreLocationProvider"]
//                                        && ![theClazzName isEqualToString:@"MKCoreLocationProvider"]
//                                        && ![theClazzName isEqualToString:@"PKPaymentTransactionProcessor"]
//                                        && ![theClazzName isEqualToString:@"PKPaymentDevice"]
//                                        ) {
//
//                                    IMP *origMethod;
//                                    MSHookMessageEx(theClazz,
//                                            @selector(locationManager:didUpdateLocations:),
//                                            (IMP) &replaced_didUpdateLocations,
//                                            (IMP *) &origMethod);
//
//                                    [CRKInjectContext shared].lmDidUpdateLocationsDelegates[theClazzName] = [NSString stringWithFormat:@"%lld", (long long int) origMethod];
//                                }
//                            }
//                        }
//
//                        if (class_conformsToProtocol(theClazz, @protocol(CLLocationManagerDelegate))) {
//                            if (__CRK_FindMethod(theClazz, @"locationManager:didUpdateToLocation:fromLocation:")) {
//                                IMP *origMethod;
//                                MSHookMessageEx(theClazz,
//                                        @selector(locationManager:didUpdateToLocation:fromLocation:),
//                                        (IMP) &replaced_didUpdateToLocation_fromLocation,
//                                        (IMP *) &origMethod);
//
//                                [CRKInjectContext shared].lmDidUpdateToLocationFromLocationDelegates[theClazzName] = [NSString stringWithFormat:@"%lld", (long long int) origMethod];
//                            }
//                        }

                        if ([CRKInjectContext shared].isInApp) {
                            if (class_conformsToProtocol(theClazz, @protocol(UIApplicationDelegate))
                                    && class_getInstanceMethod(theClazz, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:))) {

                                IMP *origMethod;
                                MSHookMessageEx(
                                        theClazz,
                                        @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:),
                                        (IMP) &Fake_application_didRegisterForRemoteNotificationsWithDeviceToken,
                                        (IMP *) &origMethod);

                                [CRKInjectContext shared].remoteDeviceTokenDelegates[theClazzName] = [NSString stringWithFormat:@"%lld", (long long int) origMethod];
                            }
                        }
                    }
                }

                free(allClazzes);
            }
        }
    }

    CRKLog(@"start hook :D");
}

@end

#pragma clang diagnostic pop
