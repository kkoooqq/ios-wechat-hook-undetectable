#import <objc/message.h>
#import "CRKH00kImplC.h"
#import "CRKH00kNetwork.h"
#import "CRKInjectContext.h"
#import "CRKCommonUtils.h"
#import <libgen.h>
#import "CRKConfigData.h"
#import "CRKFakeDYLDHelper.h"
#include <sys/syscall.h>
#import <mach-o/dyld_images.h>
#import <mach-o/loader.h>
#import "NSDictionary+Extend.h"
#import "CRKHookClasses.h"
#import "CRKServerDeviceInfo.h"
#import "CRKWCDefines.h"
#import "CRKWCTools.h"

int (*Origin_uname)(struct utsname *a1);

int Fake_uname(struct utsname *a1) {
    int origResult = Origin_uname(a1);
    if ([CRKInjectContext shared].platform) {
        __unused NSString *orgPlatform = [NSString stringWithUTF8String:a1->machine];

        const char *platform = [[CRKInjectContext shared].platform UTF8String];
        size_t platformLength = strlen(platform);
        memcpy(a1->machine, platform, platformLength + 1);

        CRKLog(@"#### orgMachine:%@ newMachine:%s", orgPlatform, platform);
    }

    return origResult;
}

int (*Origin_sysctlbyname)(const char *, void *, size_t *, void *, size_t);

int Fake_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    // FIXME: hw.cputype
    // hw.cpusubtype
    //  https://www.jianshu.com/p/5a0f8c394fb8

    int origResult = Origin_sysctlbyname(name, oldp, oldlenp, newp, newlen);
    BOOL changed = NO;
    BOOL changedStr = NO;

    CRKLog(@"#### get name: %s", name);

    // when "oldp" empty, get the length.
    if (name && oldlenp && *oldlenp) {
        if (strcmp(name, "hw.machine") == 0) {
            if ([CRKInjectContext shared].platform) {
                const char *newValue = [[CRKInjectContext shared].platform UTF8String];

                if (oldp) {
                    memcpy(oldp, newValue, strlen(newValue) + 1);
                }

                *oldlenp = strlen(newValue) + 1;
                changed = YES;
                changedStr = YES;
            }
        }

        if (!strcmp(name, "hw.model")) {
            if ([CRKInjectContext shared].hardwareModel) {
                const char *newValue = [[CRKInjectContext shared].hardwareModel UTF8String];

                if (oldp) {
                    memcpy(oldp, newValue, strlen(newValue) + 1);
                }

                *oldlenp = strlen(newValue) + 1;
                changed = YES;
                changedStr = YES;
            }
        }

        if (!strcmp(name, "kern.hostname")) {
            if ([CRKInjectContext shared].kern_hostname) {
                const char *newValue = [[CRKInjectContext shared].kern_hostname UTF8String];

                if (oldp) {
                    memcpy(oldp, newValue, strlen(newValue) + 1);
                }

                *oldlenp = strlen(newValue) + 1;
                changed = YES;
                changedStr = YES;
            }
        }

        // FIXME: boottime uptime
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
        if (0) {
            if (!strcmp(name, "kern.boottime")) {
                if ([CRKInjectContext shared].globalStartTime > 0.0) {
                    long globalStartTime = (long) [CRKInjectContext shared].globalStartTime;
                    if (oldp) {
                        memcpy(oldp, &globalStartTime, 8);
                        changed = YES;
                    }
                }
            }
        }
#pragma clang diagnostic pop

        if (!strcmp(name, "kern.uuid")) {
            if ([CRKInjectContext shared].uuid) {
                const char *newValue = [[CRKInjectContext shared].uuid UTF8String];

                if (oldp) {
                    memcpy(oldp, newValue, strlen(newValue) + 1);
                }

                *oldlenp = strlen(newValue) + 1;
                changed = YES;
                changedStr = YES;
            }
        }

        if (!strcmp(name, "kern.bootsessionuuid")) {
            if ([CRKInjectContext shared].uuid) {
                const char *newValue = [[CRKInjectContext shared].uuid UTF8String];

                if (oldp) {
                    memcpy(oldp, newValue, strlen(newValue) + 1);
                }

                *oldlenp = strlen(newValue) + 1;
                changed = YES;
                changedStr = YES;
            }
        }

        if (!strcmp(name, "hw.ncpu")
                || !strcmp(name, "hw.physicalcpu_max")
                || !strcmp(name, "hw.logicalcpu_max")) {

            if ([CRKInjectContext shared].processInfoProcessorCount > 0) {
                if (oldp) {
                    int *oldpp = (int *) oldp;
                    *oldpp = (int) [CRKInjectContext shared].processInfoProcessorCount;
                    changed = YES;
                }
            }
        }

        if (!strcmp(name, "hw.l2cachesize")) {
            if ([CRKInjectContext shared].hwL2Cachesize) {
                if (oldp) {
                    int *oldpp = (int *) oldp;
                    *oldpp = (int) [CRKInjectContext shared].hwL2Cachesize;
                    changed = YES;
                }
            }
        }

        if (!strcmp(name, "hw.l1icachesize")
                || !strcmp(name, "hw.l1dcachesize")) {

            if ([CRKInjectContext shared].hwL1Cachesize) {
                if (oldp) {
                    int *oldpp = (int *) oldp;
                    *oldpp = (int) [CRKInjectContext shared].hwL1Cachesize;
                    changed = YES;
                }
            }
        }

        if (!strcmp(name, "kern.osversion")) {
            if ([CRKInjectContext shared].BuildVersionValue) {
                const char *newValue = [[CRKInjectContext shared].BuildVersionValue UTF8String];

                if (oldp) {
                    memcpy(oldp, newValue, strlen(newValue) + 1);
                }

                *oldlenp = strlen(newValue) + 1;
                changed = YES;
                changedStr = YES;
            }
        }

        if (!strcmp(name, "kern.osrelease")) {
            if ([CRKInjectContext shared].osversion) {
                NSDictionary *darwinKernelVersions = CRKConfigData.DarwinKernelVersions;
                NSString *version = darwinKernelVersions[[CRKInjectContext shared].osversion];

                if (version) {
                    const char *newValue = [version UTF8String];
                    if (oldp) {
                        memcpy(oldp, newValue, strlen(newValue) + 1);
                    }

                    *oldlenp = strlen(newValue) + 1;
                    changed = YES;
                    changedStr = YES;
                }
            }
        }
    }

    if (changed && oldp) {
        if (changedStr) {
            CRKLog(@"#### name:%s newStringValue:%s", name, (char *) oldp);
        } else {
            CRKLog(@"#### name:%s newIntValue:%ld", name, (long) (*(int *) oldp));
        }
    }

    return origResult;
}

char *(*Origin_getenv)(const char *);

char *Fake_getenv(const char *a1) {
    char *origResult = Origin_getenv(a1);

//    printf("#### Fake_getenv getenv %s, origResult: %s", a1, origResult);

    if (origResult == nil || a1 == nil) {
        return origResult;
    }

    if ([CRKInjectContext shared].isInApp) {
        if (strcmp(a1, "DYLD_INSERT_LIBRARIES") == 0
                || strstr(a1, "_MSSafeMode") != nil
                || strstr(origResult, "Substrate") != nil
                || strstr(origResult, "Cydia") != nil
                || strstr(origResult, "MSSafeMode") != nil) {

            CRKLog(@"#### a1:%s origResult: %s return nil", a1, origResult);
            return nil;
        }
    }

    return origResult;
}

const char *(*Origin_dyld_get_image_name)(uint32_t image_index);

const char *Fake_dyld_get_image_name(uint32_t image_index) {
    const char *result = __CRK_fake_dyld_get_image_name(image_index);

    printf("#### Fake_dyld_get_image_name newResult: %s", result);

    return result;
}

uint32_t (*Origin_dyld_image_count)(void);

uint32_t Fake_dyld_image_count(void) {
    uint32_t result = __CRK_fake_dyld_image_count();

    printf("#### Fake_dyld_image_count newResult: %ld", (long) result);

    return result;
}

const struct mach_header *(*Origin_dyld_get_image_header)(uint32_t image_index);

const struct mach_header *Fake_dyld_get_image_header(uint32_t image_index) {
    return __CRK_fake_dyld_get_image_header(image_index);
}

intptr_t (*Origin_dyld_get_image_vmaddr_slide)(uint32_t image_index);

intptr_t Fake_dyld_get_image_vmaddr_slide(uint32_t image_index) {
    return __CRK_fake_dyld_get_image_vmaddr_slide(image_index);
}

void (*Origin_dyld_register_func_for_add_image)(void (*func)(const struct mach_header *mh, intptr_t vmaddr_slide));

BOOL __CRK_Fake_dyld_register_func_binding = NO;
NSMutableArray<NSValue *> *__CRK_Fake_func_pointers = nil;

/**
 * The func callback was received and needs to be processed.
 */
void __CRK_Fake_dyld_register_func(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (Origin_dladdr != nil) {
        if (Origin_dladdr(mh, &info) == 0) {
            return;
        }
    } else {
        if (dladdr(mh, &info) == 0) {
            return;
        }
    }

   CRKLog(@"mh info fname: %s sname: %s", info.dli_fname, info.dli_sname);

    // Determine if the dylib is sensitive.
    if (strstr(info.dli_fname, "deviceinfo.dylib") != 0
            || strstr(info.dli_fname, "AppHook.dylib") != 0
            || strstr(info.dli_fname, "crkInject") != 0
            || strstr(info.dli_fname, "crkAppInject") != 0
            || strstr(info.dli_fname, "crkGeneral") != 0
            || strstr(info.dli_fname, "jetslammed") != 0
            || strstr(info.dli_fname, "Liberty.dylib") != 0
            || strstr(info.dli_fname, "libReveal") != 0
            || strstr(info.dli_fname, "TSTweakEx") != 0
            || strstr(info.dli_fname, "DynamicLibraries") != 0
            ) {

        return;
    }

    // Otherwise, callback
    for (NSValue *funcsPointerValue in __CRK_Fake_func_pointers) {
        void (*func)(const struct mach_header *mh, intptr_t vmaddr_slide) = [funcsPointerValue pointerValue];
        func(mh, vmaddr_slide);
    }
}

// Implement the callback of the already loaded library to the outside.
void __CRK_tmp_Fake_dyld_register_func(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (Origin_dladdr != nil) {
        if (Origin_dladdr(mh, &info) == 0) {
            return;
        }
    } else {
        if (dladdr(mh, &info) == 0) {
            return;
        }
    }

    CRKLog(@"#### xxxxxx mh info fname: %s sname: %s", info.dli_fname, info.dli_sname);

    // sensitive dylibs
    if (strstr(info.dli_fname, "deviceinfo.dylib") != 0
            || strstr(info.dli_fname, "AppHook.dylib") != 0
            || strstr(info.dli_fname, "crkInject") != 0
            || strstr(info.dli_fname, "crkAppInject") != 0
            || strstr(info.dli_fname, "crkGeneral") != 0
            || strstr(info.dli_fname, "jetslammed") != 0
            || strstr(info.dli_fname, "Liberty.dylib") != 0
            || strstr(info.dli_fname, "libReveal") != 0
            || strstr(info.dli_fname, "TSTweakEx") != 0
            || strstr(info.dli_fname, "DynamicLibraries") != 0
            ) {

        return;
    }

    // Otherwise, callback
    if (__CRK_Fake_func_pointers.count > 1) {
        void (*func)(const struct mach_header *mh, intptr_t vmaddr_slide) = [__CRK_Fake_func_pointers.lastObject pointerValue];
        func(mh, vmaddr_slide);
    }

    Origin_dyld_register_func_for_remove_image(__CRK_tmp_Fake_dyld_register_func);
}

/**
 * Hook dyld register func
 */
void Fake_dyld_register_func_for_add_image(void (*func)(const struct mach_header *mh, intptr_t vmaddr_slide)) {
    CRKLog(@"#### no add image: %ld", (long) func);

//    Origin_dyld_register_func_for_add_image(func);

    // I'm in
    NSValue *funcPointerValue = [NSValue valueWithPointer:func];

    if (!__CRK_Fake_dyld_register_func_binding) {
        __CRK_Fake_dyld_register_func_binding = YES;
        __CRK_Fake_func_pointers = [[NSMutableArray alloc] initWithObjects:funcPointerValue, nil];

        Origin_dyld_register_func_for_add_image(__CRK_Fake_dyld_register_func);
    } else {
        [__CRK_Fake_func_pointers addObject:funcPointerValue];
        Origin_dyld_register_func_for_add_image(__CRK_tmp_Fake_dyld_register_func);
    }
}

void (*Origin_dyld_register_func_for_remove_image)(void (*func)(const struct mach_header *mh, intptr_t vmaddr_slide));

/**
 * remove
 */
void Fake_dyld_register_func_for_remove_image(void (*func)(const struct mach_header *mh, intptr_t vmaddr_slide)) {
    CRKLog(@"#### no remove image: %ld", (long) func);

    if (__CRK_Fake_func_pointers != nil) {
        for (NSValue *funcsPointerValue in __CRK_Fake_func_pointers) {
            void *checkFunc = [funcsPointerValue pointerValue];
            if (checkFunc == func) {
                [__CRK_Fake_func_pointers removeObject:funcsPointerValue];

                break;
            }
        }
    }
}

int (*Origin_ptrace)(int _request, pid_t _pid, caddr_t _addr, int _data);

int Fake_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data) {
    if (_request != 31) {
        return Origin_ptrace(_request, _pid, _addr, _data);
    }

    CRKLog(@"#### ptrace request is PT_DENY_ATTACH return 0");

    return 0;
}

int (*Origin_stat)(const char *, struct stat *);

int Fake_stat(const char *a1, struct stat *a2) {
    if (a1) {
        if (strstr(a1, "/System/Library/CoreServices/SystemVersion.bundle") != 0
                || strstr(a1, "/System/Library/PrivateFrameworks/") != 0
                || strstr(a1, "/System/Library/Frameworks/") != 0
                || strstr(a1, "/var/mobile/Library/ConfigurationProfiles/") != 0) {

            return Origin_stat(a1, a2);
        } /*else if (!a1 || strstr(a1, "CydiaSubstrate.framework") != 0) {
            origResult = Origin_stat(a1, a2);
        } */ else {
            if (!CRK_CanAccessFile([NSString stringWithUTF8String:a1], YES)) {
                *__error() = 2;
                CRKLog(@"#### return -1, a1: %s", a1);
                return -1;
            }
        }
    }

    return Origin_stat(a1, a2);
}

int (*Origin_lstat)(const char *, struct stat *);

int Fake_lstat(const char *a1, struct stat *a2) {
    if (!a1) {
        return Origin_lstat(a1, a2);
    }

    if (strcmp(a1, "/etc/fstab") == 0) {
        int result = Origin_lstat(a1, a2);
        a2->st_size = 80;

        CRKLog(@"#### /etc/fstab return org and set st_size=80");

        return result;
    }

    if ([CRKInjectContext shared].isInApp) {
        NSString *path = [NSString stringWithUTF8String:a1];
        if ([CRKInjectContext shared].globalAppPath) {
            if ([path hasPrefix:[CRKInjectContext shared].globalAppPath]) {
                return Origin_lstat(a1, a2);;
            }
        }

        NSArray *paths = @[
                @"/Applications",
                @"/Library/Printers",
                @"/Library/Updates",
                @"/System",
                @"/System/Library",
                @"/System/Library/Frameworks",
                @"/Library/Ringtones",
                @"/Library/Wallpaper",
                @"/usr/include",
                @"/usr/libexec",
                @"/usr/share",
                @"/bin",
                @"/boot",
                @"/cores",
                @"/lib",
                @"/mnt",
                @"/private",
                @"/private/var",
                @"/private/etc",
                @"/sbin",
                @"/usr",
                @"/usr/bin",
                @"/usr/sbin",
                @"/usr/lib"];

        BOOL matched = NO;

        for (NSString *testPath in paths) {
            @autoreleasepool {
                if ([path isEqualToString:testPath]) {
                    matched = YES;
                    break;
                }

                NSString *path1 = [@"/" stringByAppendingString:testPath];
                NSString *path2 = [testPath stringByAppendingString:@"/"];

                if ([path isEqualToString:path1]) {
                    matched = YES;
                    break;
                }

                if ([path isEqualToString:path2]) {
                    matched = YES;
                    break;
                }
            }
        }

        if (matched) {
            a1 = [path UTF8String];
           // CRKLog(@"#### return -1 %@", path);
            CRKLog(@"#### return 0, a1: %@", path);
            a2->st_mode = 16893;

//            *__error() = 13;

//            return -1;

            return 0;
        }
    }

    if (strstr(a1, "/System/Library/CoreServices/SystemVersion.bundle") != 0
            || strstr(a1, "/System/Library/PrivateFrameworks/") != 0
            || strstr(a1, "/System/Library/Frameworks/") != 0
            || strstr(a1, "/var/mobile/Library/ConfigurationProfiles/") != 0
            || strstr(a1, kPathCRKFilesPath) != 0
            || strstr(a1, kPathServerDeviceInfoPrefix) != 0
            || strstr(a1, kPathCRKLicenseFilePrefix) != 0
            || strstr(a1, kPathWebServerPort) != 0
            || strstr(a1, kPathConfigData) != 0
            || strstr(a1, kPathAlertFilterData) != 0
            || strstr(a1, kPathAlertFilterShuaData) != 0
            || strstr(a1, kPathAlertFilterFileName) != 0
            || strstr(a1, kPathCachedDEBPath) != 0
            || strstr(a1, kPathInjectPlistFile) != 0
            || strstr(a1, kPathCRKContactsFilePrefix) != 0
            ) {

        return Origin_lstat(a1, a2);
    } else {
        if (CRK_CanAccessFile([NSString stringWithUTF8String:a1], YES)) {
            return Origin_lstat(a1, a2);
        } else {
//            a2->st_mode = 16893;
            *__error() = 13;
            CRKLog(@"#### return -1 %s", a1);

            return -1;
        }
    }
}

CFHTTPMessageRef (*Origin_CFHTTPMessageCreateRequest)(CFAllocatorRef __nullable alloc, CFStringRef requestMethod, CFURLRef url, CFStringRef httpVersion);

CFHTTPMessageRef Fake_CFHTTPMessageCreateRequest(
        CFAllocatorRef __nullable alloc,
        CFStringRef requestMethod,
        CFURLRef url,
        CFStringRef httpVersion) {

    return Origin_CFHTTPMessageCreateRequest(alloc, requestMethod, (__bridge CFURLRef) (CRK_CetEndCacheUrl((__bridge NSURL *) (url))), httpVersion);
}


int (*Origin_system)(const char *);

int Fake_system(const char *a1) {
    if (![CRKInjectContext shared].isInApp) {
        return Origin_system(a1);
    }

    CRKLog(@"#### return 0");

    return 0;
//    return 0x7f00;
}

pid_t (*Origin_fork)(void);

pid_t Fake_fork(void) {
    pid_t origResult;

    if ([CRKInjectContext shared].isInApp) {
        CRKLog(@"#### return -1");
        origResult = -1;
    } else {
        origResult = Origin_fork();
    }

    return origResult;
}

void *(*Origin_dlopen)(const char *__path, int __mode);

void *Fake_dlopen(const char *__path, int __mode) {
    void *result;
    char *v4;

    if (!__path || !strlen(__path)) {
        return Origin_dlopen(__path, __mode);
    }

    if (strstr(__path, "/usr/lib/libcycript") == 0
            || ![CRKInjectContext shared].isInApp) {

        if (strstr(__path, "/Library/MobileSubstrate/DynamicLibraries") != 0
                && strstr(__path, "/Library/MobileSubstrate/DynamicLibraries/TS") == 0
                && strstr(__path, "/Library/MobileSubstrate/DynamicLibraries/libReveal") == 0
                && strstr(__path, "/Library/MobileSubstrate/DynamicLibraries/TaskApp") == 0
                && strstr(__path, "/Library/MobileSubstrate/DynamicLibraries/HookSSL") == 0
                && strstr(__path, "/Library/MobileSubstrate/DynamicLibraries/crk") == 0
                && strstr(__path, "/Library/MobileSubstrate/DynamicLibraries/libobjcipc") == 0) {

            CRKLog(@"#### return nil (%s, %d)", __path, __mode);
            return nil;
        }

//        return Origin_dlopen(__path, __mode);
    }

    if (((void) (v4 = strstr(__path, "MobileSubstrate.dylib")), __mode == 1) && v4) {
        result = nil;
        CRKLog(@"#### return nil (%s, %d)", __path, __mode);
    } else {
        result = Origin_dlopen(__path, __mode);
    }

    return result;
}

FILE *(*Origin_fopen)(const char *__restrict __filename, const char *__restrict __mode);

FILE *Fake_fopen(const char *__restrict __filename, const char *__restrict __mode) {
    if (!__filename) {
        return Origin_fopen(__filename, __mode);
    }

    if (strcmp(__filename, "/etc/fstab") == 0) {
        CRKLog(@"#### return 0, %s", __filename);

        return nil;
    }

    if (![CRKInjectContext shared].isInApp) {
        return Origin_fopen(__filename, __mode);
    }

    NSString *path = [NSString stringWithUTF8String:__filename];
    if (!CRK_CanAccessFile(path, YES)) {
        *__error() = 2;
        CRKLog(@"#### return 0, %s", __filename);

        return nil;
    }

    if (*__filename != 47) {
        return Origin_fopen(__filename, __mode);
    }

    char *fileNameCopy = strdup(__filename);
    char *dirPath = dirname(fileNameCopy);
    if (!dirPath || (strcmp(dirPath, "/private") && strcmp(dirPath, "/var/mobile/") && strcmp(dirPath, "/private/var"))) {
        free(fileNameCopy);
        return Origin_fopen(__filename, __mode);
    }

    CRKLog(@"#### return 0, %s", __filename);

    free(fileNameCopy);

    return nil;
}

DIR *(*Origin_opendir2)(const char *, int);

DIR *Fake_opendir2(const char *a1, int a2) {
    DIR *result;

    if ([CRKInjectContext shared].isInApp
            && a1
            && (strcmp(a1, "/bin") == 0 || !CRK_CanAccessFile([NSString stringWithUTF8String:a1], NO))) {

        CRKLog(@"#### return 0, %s", a1);

        result = nil;
    } else {
        result = Origin_opendir2(a1, a2);
    }

    return result;
}

int (*Origin_dladdr)(const void *, Dl_info *);

//typedef struct dl_info {
//    const char      *dli_fname;     /* Pathname of shared object */
//    void            *dli_fbase;     /* Base address of shared object */
//    const char      *dli_sname;     /* Name of nearest symbol */
//    void            *dli_saddr;     /* Address of nearest symbol */
//} Dl_info;

int Fake_dladdr(const void *a1, Dl_info *a2) {
    int result; // [xsp+Ch] [xbp-14h]
    result = Origin_dladdr(a1, a2);

    if (CRK_FAKE_HIGH_LEVEL) {
        __unused const char *b_dli_fname = a2->dli_fname;
        __unused void *b_dli_fbase = a2->dli_fbase;
        const char *b_dli_sname = a2->dli_sname;
        BOOL changed = NO;

        static NSDictionary *sname_fname_Maps = nil;
        if (sname_fname_Maps == nil) {
            sname_fname_Maps = @{
                    @"Fake_CFBundleGetValueForInfoDictionaryKey": @"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation",
                    @"Fake_CNCopyCurrentNetworkInfo": @"/System/Library/Frameworks/SystemConfiguration.framework/SystemConfiguration",
                    @"Fake_MobileInstallationLookup": @"/System/Library/PrivateFrameworks/MobileInstallation.framework/MobileInstallation",
                    @"Fake_CFCopySystemVersionDictionary": @"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation",
                    @"Fake_CFBundleGetInfoDictionary": @"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation",
                    @"Fake_CFHTTPMessageCreateRequest": @"/System/Library/Frameworks/CFNetwork.framework/CFNetwork",
                    @"Fake_CFURLRequestCreate": @"/System/Library/Frameworks/CFNetwork.framework/CFNetwork",
                    @"Fake_CFURLRequestSetURL": @"/System/Library/Frameworks/CFNetwork.framework/CFNetwork",
                    @"Fake__swift_stdlib_operatingSystemVersion": @"@rpath/libswiftCore.dylib",
                    @"Fake_NSLog": @"/System/Library/Frameworks/Foundation.framework/Foundation",
                    @"Fake_CFBundleGetAllBundles": @"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation",
            };
        };

        if (result && (
                strstr(a2->dli_fname, "deviceinfo.dylib") != 0
                        || strstr(a2->dli_fname, "AppHook.dylib") != 0
                        || strstr(a2->dli_fname, "crkInject") != 0
                        || strstr(a2->dli_fname, "crkAppInject") != 0
                        || strstr(a2->dli_fname, "crkGeneral") != 0
                        || strstr(a2->dli_fname, "jetslammed") != 0
                        || strstr(a2->dli_fname, "Liberty.dylib") != 0
                        || strstr(a2->dli_fname, "libReveal") != 0
                        || strstr(a2->dli_fname, "TSTweakEx") != 0
        )) {
            if (strstr(a2->dli_sname, "$NS") != 0) {
                if (CRK_FAKE_HIGH_LEVEL_CHANGE_NAME) {
                    a2->dli_fname = "/System/Library/Frameworks/Foundation.framework/Foundation";
                    a2->dli_sname = "<redacted>";
                }

                a2->dli_fbase = __CRK_fake_dladdr_dli_fbase_With_dli_fname(a2->dli_fname);
                changed = YES;
            } else if (strstr(a2->dli_sname, "$UI") != 0) {
                if (CRK_FAKE_HIGH_LEVEL_CHANGE_NAME) {
                    a2->dli_fname = "/System/Library/Frameworks/UIKit.framework/UIKit";
                    a2->dli_sname = "<redacted>";
                }

                a2->dli_fbase = __CRK_fake_dladdr_dli_fbase_With_dli_fname(a2->dli_fname);
                changed = YES;
            } else if (strstr(a2->dli_sname, "$ASIdentifierManager") != 0) {
                if (CRK_FAKE_HIGH_LEVEL_CHANGE_NAME) {
                    a2->dli_fname = "/System/Library/Frameworks/AdSupport.framework/AdSupport";
                    a2->dli_sname = "<redacted>";
                }

                a2->dli_fbase = __CRK_fake_dladdr_dli_fbase_With_dli_fname(a2->dli_fname);
                changed = YES;
            } else if (strstr(a2->dli_sname, "$CLLocationManager") != 0) {
                if (CRK_FAKE_HIGH_LEVEL_CHANGE_NAME) {
                    a2->dli_fname = "/System/Library/Frameworks/CoreLocation.framework/CoreLocation";
                    a2->dli_sname = "<redacted>";
                }

                a2->dli_fbase = __CRK_fake_dladdr_dli_fbase_With_dli_fname(a2->dli_fname);
                changed = YES;
            } else {
                NSString *snameStr = [NSString stringWithUTF8String:b_dli_sname];
                NSString *fnameStr = [sname_fname_Maps stringValueForKey:snameStr];

                if (fnameStr.length > 0) {
                    if (CRK_FAKE_HIGH_LEVEL_CHANGE_NAME) {
                        a2->dli_fname = [fnameStr UTF8String];
                        a2->dli_sname = "<redacted>";
                    }

                    a2->dli_fbase = __CRK_fake_dladdr_dli_fbase_With_dli_fname(a2->dli_fname);
                    changed = YES;
                } else {
                    // Not found, return /usr/lib/libSystem.B.dylib uniformly.
                    if (CRK_FAKE_HIGH_LEVEL_CHANGE_NAME) {
                        a2->dli_fname = "/usr/lib/libSystem.B.dylib";
                        a2->dli_sname = "<redacted>";
                    }

                    a2->dli_fbase = __CRK_fake_dladdr_dli_fbase_With_dli_fname(a2->dli_fname);
                    changed = YES;
                }
            }
        }

        if (changed) {
            CRKLog(@"#### changed: %d \nBEFORE dli_fname: %s \n\tdli_fbase: %ld \n\tdli_sname: %s \n\tdli_saddr: %ld\nAFTER dli_fname: %s \n\tdli_fbase: %ld \n\tdli_sname: %s \n\tdli_saddr: %ld", changed, b_dli_fname, b_dli_fbase, b_dli_sname, a2->dli_saddr, a2->dli_fname, a2->dli_fbase, a2->dli_sname, a2->dli_saddr);
        }
    }

    return result;
}

int (*Origin_statfs)(const char *, struct statfs *);

int Fake_statfs(const char *a1, struct statfs *a2) {
    int origResult = Origin_statfs(a1, a2);
    if (origResult != -1) {
        if ([CRKInjectContext shared].isInApp) {
            if (!CRK_CanAccessFile([NSString stringWithUTF8String:a1], YES)) {
                CRKLog(@"#### return -1, a1: %s", a1);

                return -1;
            }

            uint32_t flags = 0;
            if (strcmp(a1, "/private/var") && strcmp(a1, "/var/mobile")) {
                if (!strcmp(a1, "/")) {
                    flags = 1;
                    goto LABEL_11;
                }
                if (!strstr(a1, "/var/mobile")) {
                    goto LABEL_12;
                }
            }

            flags = 24;

            LABEL_11:
            a2->f_flags = flags;

            LABEL_12:;

            uint64_t blocks = a2->f_blocks;
            uint64_t bavail = a2->f_bavail;
            uint64_t bfree = a2->f_bfree;
            u_int32_t randomValue = arc4random();

            uint64_t newBlocks = blocks - (randomValue - randomValue / (blocks / 0xA) * (blocks / 0xA));
            if ([CRKInjectContext shared].fileSystemSize) {
                a2->f_blocks = [CRKInjectContext shared].fileSystemSize / a2->f_bsize;
            } else {
                a2->f_blocks = newBlocks;
            }

            u_int32_t randomValue1 = arc4random();
            a2->f_bavail = bavail - (randomValue1 - randomValue1 / (bavail / 0xA) * (bavail / 0xA));
            u_int32_t randomValue2 = arc4random();
            a2->f_bfree = bfree - (randomValue2 - randomValue2 / (bfree / 0xA) * (bfree / 0xA));
        }
    }

    return origResult;
}

const struct section_64 *(*Origin_getsectbyname)(
        const char *segname,
        const char *sectname);

const struct section_64 *Fake_getsectbyname(
        const char *segname,
        const char *sectname) {

    const struct section_64 *result; // [xsp+18h] [xbp-8h]

    if (segname
            && sectname
            && strcmp(segname, "__RESTRICT") == 0
            && strcmp(sectname, "__restrict") == 0) {

        CRKLog(@"#### modify __RESTRICT __restrict为__pppppppp");

        result = Origin_getsectbyname(segname, "__pppppppp");
    } else {
        result = Origin_getsectbyname(segname, sectname);
    }

    return result;
}

_SwiftNSOperatingSystemVersion (*Origin__swift_stdlib_operatingSystemVersion)(void);

_SwiftNSOperatingSystemVersion Fake__swift_stdlib_operatingSystemVersion() {
    if (![CRKInjectContext shared].isInApp) {
        return Origin__swift_stdlib_operatingSystemVersion();
    }

    if ([CRKInjectContext shared].osversion.length == 0) {
        return Origin__swift_stdlib_operatingSystemVersion();
    }

    NSArray <NSString *> *callStackSymbols = [NSThread callStackSymbols];
    if (callStackSymbols.count == 0) {
        return Origin__swift_stdlib_operatingSystemVersion();
    }

   CRKLog(@"Fake__swift_stdlib_operatingSystemVersion callStacks: %@", callStackSymbols);

    BOOL inStack = NO;
    for (NSString *symbol in callStackSymbols) {
        @autoreleasepool {
            if (symbol.length == 0) {
                continue;
            }

            if ([symbol rangeOfString:@"libswiftDispatch.dylib"].location != NSNotFound) {
                inStack = YES;
                break;
            }

            if ([symbol rangeOfString:@"libswiftFoundation.dylib"].location != NSNotFound) {
                inStack = YES;
                break;
            }

            if ([symbol rangeOfString:@"swift_rt_swift_allocObject"].location != NSNotFound) {
                inStack = YES;
                break;
            }

            if ([symbol rangeOfString:@"LingoAVFoundation"].location != NSNotFound) {
                inStack = YES;
                break;
            }

            if ([symbol rangeOfString:@"AppShortCuts"].location != NSNotFound) {
                inStack = YES;
                break;
            }

            if ([symbol rangeOfString:@"LoginKit"].location != NSNotFound) {
                inStack = YES;
                break;
            }

            if ([symbol rangeOfString:@"loadWebView"].location != NSNotFound) {
                inStack = YES;
                break;
            }

            if ([symbol rangeOfString:@"FSPagerView"].location != NSNotFound
                    && [symbol rangeOfString:@"UICollection"].location != NSNotFound
                    && [symbol rangeOfString:@"Layout"].location != NSNotFound) {

                inStack = YES;
                break;
            }
        }
    }

    if (!inStack) {
        return Origin__swift_stdlib_operatingSystemVersion();
    }

    NSArray *versionParts = [[[CRKInjectContext shared].origSystemVersion mutableCopy] componentsSeparatedByString:@"."];

    _SwiftNSOperatingSystemVersion result = {0, 0, 0};

    if ([versionParts count]) {
        result.majorVersion = [versionParts[0] intValue];
        result.minorVersion = 0;
        result.patchVersion = 0;
    }

    if ([versionParts count] > 1) {
        result.minorVersion = [versionParts[1] intValue];
    }

    if ([versionParts count] > 2) {
        result.patchVersion = [versionParts[2] intValue];
    }

    return result;
}

extern void (*Origin_NSLog)(NSString *format, ...);

void Fake_NSLog(NSString *format, ...) {
    // It comes in when third party calls it.
    va_list args;
    va_start(args, format);
    NSString *print = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

//    __uint64_t threadID = [CRKLogger currentThreadID];
//    NSString *output = [NSString stringWithFormat:@"$_!T%llu %s:%d\n NSLOG:%@\n", threadID, __func__, __LINE__, print];
//
//    if (Origin_NSLog != nil) {
//        Origin_NSLog(@"%@", output);
//    }

    CRKLog(@"NSLog: %@", print);
}

extern void (*Origin_NSLogv)(NSString *format, va_list args);

void Fake_NSLogv(NSString *format, va_list args) {
    NSString *print = [[NSString alloc] initWithFormat:format arguments:args];

//    __uint64_t threadID = [CRKLogger currentThreadID];
//    NSString *output = [NSString stringWithFormat:@"$_!T%llu %s:%d\n NSLOGV:%@\n", threadID, __func__, __LINE__, print];
//
//    if (Origin_NSLog != nil) {
//        Origin_NSLog(@"%@", output);
//    }

    CRKLog(@"NSLogv: %@", print);
}

// access
int (*Origin_access)(const char *, int);

int Fake_access(const char *a1, int a2) {
    if (a1 != nil && [CRKInjectContext shared].isInApp) {
        NSString *path = [NSString stringWithUTF8String:a1];
        if (!CRK_CanAccessFile(path, YES)) {
            *__error() = 2;

            CRKLog(@"#### return -1: %s", a1);

            return -1;
        }
    }

    return Origin_access(a1, a2);
}

// faccessat
int (*Origin_faccessat)(int, const char *, int, int);

int Fake_faccessat(int a1, const char *a2, int a3, int a4) {
    if (a2 != nil && [CRKInjectContext shared].isInApp) {
        NSString *path = [NSString stringWithUTF8String:a2];
        if (!CRK_CanAccessFile(path, YES)) {
            *__error() = 2;

            if ([CRKInjectContext shared].isInApp) {
                CRKLog(@"#### return -1: %s", a1);
            }

            return -1;
        }
    }

    return Origin_faccessat(a1, a2, a3, a4);
}

// dlsym
void *(*Origin_dlsym)(void *__handle, const char *__symbol);

void *Fake_dlsym(void *__handle, const char *__symbol) {
    /*void *result = nil;
    if (!strcmp(__symbol, "access"))
        result = Fake_access;
    if (!strcmp(__symbol, "CFBundleGetAllBundles"))
        result = Fake_CFBundleGetAllBundles;
    if (!strcmp(__symbol, "dlopen"))
        result = Fake_dlopen;
    if (!strcmp(__symbol, "dlsym"))
        result = Fake_dlsym;
    if (!strcmp(__symbol, "_dyld_get_image_name"))
        result = Fake_dyld_get_image_name;
    if (!strcmp(__symbol, "_dyld_image_count"))
        result = Fake_dyld_image_count;
    if (!strcmp(__symbol, "fopen"))
        result = Fake_fopen;
    if (!strcmp(__symbol, "fork"))
        result = Fake_fork;
    if (!strcmp(__symbol, "getenv"))
        result = Fake_getenv;
    if (!strcmp(__symbol, "lstat"))
        result = Fake_lstat;
//    if (!strcmp(__symbol, "open"))
//        result = Fake_open;
//    if (!strcmp(__symbol, "opendir"))
//        result = Fake_opendir;
    if (!strcmp(__symbol, "stat"))
        result = Fake_stat;
    if (!strcmp(__symbol, "statfs"))
        result = Fake_statfs;
    if (!strcmp(__symbol, "symlink"))
        result = Fake_symlink;
    if (!strcmp(__symbol, "sysctl"))
        result = Fake_sysctl;
    if (!strcmp(__symbol, "sysctlbyname"))
        result = Fake_sysctlbyname;
    if (!strcmp(__symbol, "system"))
        result = Fake_system;
    if (!strcmp(__symbol, "vfork"))
        result = Fake_vfork;

    if (result == nil) {
        return Origin_dlsym(__handle, __symbol);
    } else {
        CRKLog(@"#### Fake_dlsym, __symbol: %s", __symbol);

        return result;
    }*/

    void *result = nil;

    if (!strcmp(__symbol, "CFBundleGetValueForInfoDictionaryKey")) {
        result = (void *) Fake_CFBundleGetValueForInfoDictionaryKey;
    }
    if (!strcmp(__symbol, "MGCopyAnswer")) {
        result = (void *) Fake_MGCopyAnswer;
    }
    if (!strcmp(__symbol, "sysctl")) {
        result = (void *) Fake_sysctl;
    }
    if (!strcmp(__symbol, "uname")) {
        result = (void *) Fake_uname;
    }
    if (!strcmp(__symbol, "sysctlbyname")) {
        result = (void *) Fake_sysctlbyname;
    }
    if (!strcmp(__symbol, "getenv")) {
        result = (void *) Fake_getenv;
    }
    if (!strcmp(__symbol, "_dyld_get_image_name")) {
        result = (void *) Fake_dyld_get_image_name;
    }
    if (!strcmp(__symbol, "_dyld_image_count")) {
        result = (void *) Fake_dyld_image_count;
    }
    if (!strcmp(__symbol, "_dyld_get_image_header")) {
        result = (void *) Fake_dyld_get_image_header;
    }
    if (!strcmp(__symbol, "_dyld_get_image_vmaddr_slide")) {
        result = (void *) Fake_dyld_get_image_vmaddr_slide;
    }
    if (!strcmp(__symbol, "_dyld_register_func_for_add_image")) {
        result = (void *) Fake_dyld_register_func_for_add_image;
    }
    if (!strcmp(__symbol, "_dyld_register_func_for_remove_image")) {
        result = (void *) Fake_dyld_register_func_for_remove_image;
    }
    if (!strcmp(__symbol, "MobileInstallationLookup")) {
        result = (void *) Fake_MobileInstallationLookup;
    }
    if (!strcmp(__symbol, "stat")) {
        result = (void *) Fake_stat;
    }
    if (!strcmp(__symbol, "lstat")) {
        result = (void *) Fake_lstat;
    }
    if (!strcmp(__symbol, "_CFCopySystemVersionDictionary")) {
        result = (void *) Fake_CFCopySystemVersionDictionary;
    }
    if (!strcmp(__symbol, "_CFCopySystemVersionDictionary")) {
        result = (void *) Fake_CFCopySystemVersionDictionary;
    }
    if (!strcmp(__symbol, "CFBundleGetInfoDictionary")) {
        result = (void *) Fake_CFBundleGetInfoDictionary;
    }
    if (!strcmp(__symbol, "CFHTTPMessageCreateRequest")) {
        result = (void *) Fake_CFHTTPMessageCreateRequest;
    }
    if (!strcmp(__symbol, "CFURLRequestCreate")) {
        result = (void *) Fake_CFURLRequestCreate;
    }
    if (!strcmp(__symbol, "CFURLRequestSetURL")) {
        result = (void *) Fake_CFURLRequestSetURL;
    }
    if (!strcmp(__symbol, "system")) {
        result = (void *) Fake_system;
    }
    if (!strcmp(__symbol, "fork")) {
        result = (void *) Fake_fork;
    }
    if (!strcmp(__symbol, "dlopen")) {
        result = (void *) Fake_dlopen;
    }
    if (!strcmp(__symbol, "fopen")) {
        result = (void *) Fake_fopen;
    }
    if (!strcmp(__symbol, "opendir2")) {
        result = (void *) Fake_opendir2;
    }
    if (!strcmp(__symbol, "dladdr")) {
        result = (void *) Fake_dladdr;
    }
    if (!strcmp(__symbol, "statfs")) {
        result = (void *) Fake_statfs;
    }
    if (!strcmp(__symbol, "getsectbyname")) {
        result = (void *) Fake_getsectbyname;
    }
    if (!strcmp(__symbol, "_swift_stdlib_operatingSystemVersion")) {
        result = (void *) Fake__swift_stdlib_operatingSystemVersion;
    }
    if (!strcmp(__symbol, "NSLog")) {
        result = (void *) Fake_NSLog;
    }
    if (!strcmp(__symbol, "access")) {
        result = (void *) Fake_access;
    }
    if (!strcmp(__symbol, "CFBundleGetAllBundles")) {
        result = (void *) Fake_CFBundleGetAllBundles;
    }
    if (!strcmp(__symbol, "dlsym")) {
        result = (void *) Fake_dlsym;
    }
    if (!strcmp(__symbol, "getenv")) {
        result = (void *) Fake_getenv;
    }
    if (!strcmp(__symbol, "open")) {
        result = (void *) Fake_open;
    }
//    if (!strcmp(__symbol, "opendir")) {
//        result = (void *) Fake_opendir;
//    }
    if (!strcmp(__symbol, "symlink")) {
        result = (void *) Fake_symlink;
    }
    if (!strcmp(__symbol, "vfork")) {
        result = (void *) Fake_vfork;
    }
    if (strcmp(__symbol, "syscall") == 0) {
        result = (void *) Fake_syscall;
    }
    if (strcmp(__symbol, "remove") == 0) {
        result = (void *) Fake_remove;
    }
    if (strcmp(__symbol, "rename") == 0) {
        result = (void *) Fake_rename;
    }
    if (strcmp(__symbol, "ptrace") == 0) {
        result = (void *) Fake_ptrace;
    }
    if (strcmp(__symbol, "strlen") == 0) {
        result = (void *) Fake_strlen;
    }
    if (strcmp(__symbol, "task_info") == 0) {
        result = (void *) Fake_task_info;
    }
//    if (strcmp(__symbol, "mig_get_reply_port") == 0) {
//        result = (void *) Fake_mig_get_reply_port;
//    }
//    if (strcmp(__symbol, "mig_put_reply_port") == 0) {
//        result = (void *) Fake_mig_put_reply_port;
//    }

    if ([CRKWCTools isInWCProcess]) {
        if (!strcmp(__symbol, "SecItemCopyMatching")) {
            result = (void *) Fake_SecItemCopyMatching;
        }
        if (!strcmp(__symbol, "SecItemUpdate")) {
            result = (void *) Fake_SecItemUpdate;
        }
        if (!strcmp(__symbol, "SecItemAdd")) {
            result = (void *) Fake_SecItemAdd;
        }
        if (!strcmp(__symbol, "SecItemDelete")) {
            result = (void *) Fake_SecItemDelete;
        }
        if (!strcmp(__symbol, "getifaddrs")) {
            result = (void *) Fake_getifaddrs;
        }
        if (!strcmp(__symbol, "freeifaddrs")) {
            result = (void *) Fake_freeifaddrs;
        }
        if (!strcmp(__symbol, "CNCopyCurrentNetworkInfo")) {
            result = (void *) Fake_CNCopyCurrentNetworkInfo;
        }
        if (!strcmp(__symbol, "SCNetworkReachabilityGetFlags")) {
            result = (void *) Fake_SCNetworkReachabilityGetFlags;
        }
        if (!strcmp(__symbol, "SCNetworkReachabilitySetCallback")) {
            result = (void *) Fake_SCNetworkReachabilitySetCallback;
        }
    }

    if (result == nil) {
        return Origin_dlsym(__handle, __symbol);
    } else {
        CRKLog(@"#### __symbol: %s callStack: %@", __symbol, __CRK_Orig_NSThread_callStackSymbols);

        return result;
    }
}

// open
int (*Origin_open)(const char *, int, ...);

int Fake_open(const char *path, int oflag, ...) {
    if (!path || ![CRKInjectContext shared].isInApp) {
        int result = 0;
        if (oflag & O_CREAT) {
            mode_t mode;
            va_list args;

            va_start(args, oflag);
            mode = (mode_t) va_arg(args, int);
            va_end(args);
            result = Origin_open(path, oflag, mode);
        } else {
            result = Origin_open(path, oflag);
        }

        return result;
    }

    if (strcmp(path, "/etc/fstab") == 0
            || !CRK_CanAccessFile([NSString stringWithUTF8String:path], YES)) {

        CRKLog(@"#### return -1, a1: %s, callStack: %@", path, __CRK_Orig_NSThread_callStackSymbols);

        return -1;
    }

    if (*path != 47) {
        int result = 0;

        // Handle the optional third argument
        if (oflag & O_CREAT) {
            mode_t mode;
            va_list args;

            va_start(args, oflag);
            mode = (mode_t) va_arg(args, int);
            va_end(args);
            result = Origin_open(path, oflag, mode);
        } else {
            result = Origin_open(path, oflag);
        }

        return result;
    }

    char *a1copy = strdup(path);
    char *a1dir = dirname(a1copy);
    if (!a1dir || (strcmp(a1dir, "/private") && strcmp(a1dir, "/var/mobile/") && strcmp(a1dir, "/private/var"))) {
        free(a1copy);
        int result = 0;

        // Handle the optional third argument
        if (oflag & O_CREAT) {
            mode_t mode;
            va_list args;

            va_start(args, oflag);
            mode = (mode_t) va_arg(args, int);
            va_end(args);
            result = Origin_open(path, oflag, mode);
        } else {
            result = Origin_open(path, oflag);
        }

        return result;
    }

    free(a1copy);

    CRKLog(@"#### return -1, a1: %s, callStack: %@", path, __CRK_Orig_NSThread_callStackSymbols);

    return -1;
}

open_ptr_t origfish_open = NULL;

int fakefish_open(const char *a1, int a2, va_list args) {
    va_list newArgs;
    va_copy(newArgs, args);

//    Origin_NSLog(@"!!!! fakefish_open: %s", a1);

    if (!a1 || ![CRKInjectContext shared].isInApp) {
//        Origin_NSLog(@"!!!! fakefish_open 1");

        return origfish_open(a1, a2, newArgs);
    }

//    Origin_NSLog(@"!!!! fakefish_open 2");

    if (strcmp(a1, "/etc/fstab") == 0
            || !CRK_CanAccessFile([NSString stringWithUTF8String:a1], YES)) {

        CRKLog(@"#### return -1, a1: %s", a1);

        return -1;
    }

//    Origin_NSLog(@"!!!! fakefish_open 3");

    if (*a1 != 47) {
//        Origin_NSLog(@"!!!! fakefish_open 4");

        return origfish_open(a1, a2, newArgs);
    }

//    Origin_NSLog(@"!!!! fakefish_open 5");

    char *a1copy = strdup(a1);
    char *a1dir = dirname(a1copy);
//    Origin_NSLog(@"!!!! fakefish_open 6");

    if (!a1dir || (strcmp(a1dir, "/private") && strcmp(a1dir, "/var/mobile/") && strcmp(a1dir, "/private/var"))) {
        free(a1copy);
//        Origin_NSLog(@"!!!! fakefish_open 7");

        return origfish_open(a1, a2, newArgs);
    }

    free(a1copy);

    CRKLog(@"#### return -1, a1: %s", a1);

    return -1;
}

// opendir
DIR *(*Origin_opendir)(const char *);

DIR *Fake_opendir(const char *a1) {
    if (a1
            && [CRKInjectContext shared].isInApp
            && !CRK_CanAccessFile([NSString stringWithUTF8String:a1], YES)) {

        CRKLog(@"#### return 0, a1: %s", a1);

        *__error() = 13;

        return 0;
    }

    DIR *origResult = Origin_opendir(a1);
    return origResult;
}

// symlink
int (*Origin_symlink)(const char *, const char *);

int Fake_symlink(const char *a1, const char *a2) {
    if ([CRKInjectContext shared].isInApp && a1 && a2) {
        if (!CRK_CanAccessFile([NSString stringWithUTF8String:a1], YES)
                || !CRK_CanAccessFile([NSString stringWithUTF8String:a2], YES)) {

            CRKLog(@"#### return -1, a1: %s, a2: %s", a1, a2);

            return -1;
        }
    }

    return Origin_symlink(a1, a2);
}

// vfork
pid_t (*Origin_vfork)(void);

pid_t Fake_vfork() {
    CRKLog(@"#### return -1");

    return -1;
}

// syscall
int (*Origin_syscall)(int code, va_list args);

int Fake_syscall(int code, ...) {
//    va_list newArgs;
//    va_copy(newArgs, args);

    if (code != 180 && code != 427) {
        CRKLog(@"#### Fake_syscall code: %ld", (long) code);
    }

    if (/* DISABLES CODE */ (0) /*code == SYS_fsgetpath*/) {
        // ssize_t fsgetpath_np(char *restrict buf, size_t bufsize, fsid_t fsid, uint64_t objid);

//        Origin_NSLog(@"#### SYS_fsgetpath callStackSymbols: %@", [NSThread callStackSymbols]);

        va_list args;
        va_start(args, code);
        va_list args1 = args;

        int result = Origin_syscall(code, args);
        char *buf = va_arg(args1, char *);
        size_t bufsize = va_arg(args1, size_t);
        __unused fsid_t fsid = va_arg(args1, fsid_t);
        uint64_t objid = va_arg(args1, uint64_t);

        __CRK_Orig_NSLog(@"#### SYS_fsgetpath result: %d buf: %s bufsize: %ld objid: %llu", result, buf, (long) bufsize, objid);

        va_end(args);

        return result;
    } else if (code == SYS_ptrace) {
        va_list args;
        va_start(args, code);
        int request = va_arg(args, int);
        va_end(args);

        if (request == 31) {
            CRKLog(@"#### syscall call ptrace, and request is PT_DENY_ATTACH");
            return 0;
        }
    } else if (code == SYS_stat) {
        va_list args;
        va_start(args, code);
        char const *file_name = va_arg(args, char const *);
        struct stat *buf = va_arg(args, struct stat *);
        va_end(args);

        return Fake_stat(file_name, buf);
    } else if (code == SYS_open) {
//        const char *path, int oflag
        va_list args;
        va_start(args, code);
        const char *path = va_arg(args, const char *);
        int oflag = va_arg(args, int);

        if (!path || ![CRKInjectContext shared].isInApp) {
            int result = 0;
            if (oflag & O_CREAT) {
                mode_t mode;
                mode = (mode_t) va_arg(args, int);
                result = Origin_open(path, oflag, mode);
            } else {
                result = Origin_open(path, oflag);
            }
            va_end(args);

            return result;
        }

        if (strcmp(path, "/etc/fstab") == 0
                || !CRK_CanAccessFile([NSString stringWithUTF8String:path], YES)) {

            CRKLog(@"####QQ return -1, a1: %s", path);
            va_end(args);

            return -1;
        }

        if (*path != 47) {
            int result = 0;

            // Handle the optional third argument
            if (oflag & O_CREAT) {
                mode_t mode;
                mode = (mode_t) va_arg(args, int);
                result = Origin_open(path, oflag, mode);
            } else {
                result = Origin_open(path, oflag);
            }
            va_end(args);

            return result;
        }

        char *a1copy = strdup(path);
        char *a1dir = dirname(a1copy);
        if (!a1dir || (strcmp(a1dir, "/private") && strcmp(a1dir, "/var/mobile/") && strcmp(a1dir, "/private/var"))) {
            free(a1copy);
            int result = 0;

            // Handle the optional third argument
            if (oflag & O_CREAT) {
                mode_t mode;
                mode = (mode_t) va_arg(args, int);
                result = Origin_open(path, oflag, mode);
            } else {
                result = Origin_open(path, oflag);
            }
            va_end(args);

            return result;
        }

        free(a1copy);

        CRKLog(@"####QQ return -1, a1: %s", path);
        va_end(args);

        return -1;
    } else if (code == SYS_access) {
//        const char *a1, int a2

        va_list args;
        va_start(args, code);
        const char *a1 = va_arg(args, const char *);
        int a2 = va_arg(args, int);
        va_end(args);

        return Fake_access(a1, a2);
    } else if (code == SYS_lstat64) {
//        const char *a1, struct stat *a2

        va_list args;
        va_start(args, code);
        const char *a1 = va_arg(args, const char *);
        struct stat *a2 = va_arg(args, struct stat *);
        va_end(args);

        return Fake_lstat(a1, a2);
    }

    va_list args;
    va_start(args, code);
    int result = Origin_syscall(code, args);
    va_end(args);

    return result;
}

// WC
int (*Origin_remove)(const char *);

int Fake_remove(const char *a1) {
    if (a1
            && [CRKInjectContext shared].isInApp
            && !CRK_CanAccessFile([NSString stringWithUTF8String:a1], YES)) {

        CRKLog(@"#### return -1, a1: %s", a1);

        *__error() = 6;

        return -1;
    }

    int origResult = Origin_remove(a1);
    return origResult;
}

int (*Origin_rename)(const char *__old, const char *__new);

int Fake_rename(const char *__old, const char *__new) {
    if ([CRKInjectContext shared].isInApp
            &&
            (
                    (__old && !CRK_CanAccessFile([NSString stringWithUTF8String:__old], YES))
                            || (__new && !CRK_CanAccessFile([NSString stringWithUTF8String:__new], YES))
            )
            ) {

        CRKLog(@"#### return -1, __old: %s, __new: %s", __old, __new);

        *__error() = 6;

        return -1;
    }

    int origResult = Origin_rename(__old, __new);
    return origResult;
}

mach_port_t (*Origin_mig_get_reply_port)(void);

mach_port_t Fake_mig_get_reply_port() {
//    if ([InjectContext shared].isInApp) {
//        Origin_NSLog(@"#### return 0 callStack: %@", [NSThread callStackSymbols]);

//        return 0;
//    }

    return Origin_mig_get_reply_port();
}

void (*Origin_mig_put_reply_port)(mach_port_t reply_port);

void Fake_mig_put_reply_port(mach_port_t reply_port) {
//    if ([InjectContext shared].isInApp) {
//    Origin_NSLog(@"#### return callStack: %@", [NSThread callStackSymbols]);
//    } else {
    Origin_mig_put_reply_port(reply_port);
//    }
}

int __CRK_strcmp(const char *s1, const char *s2) {
    for (; *s1 == *s2; s1++, s2++)
        if (*s1 == '\0')
            return 0;
    return ((*(unsigned char *) s1 < *(unsigned char *) s2) ? -1 : +1);
}

size_t (*Origin_strlen)(const char *__s);

size_t Fake_strlen(const char *__s) {
    size_t result = Origin_strlen(__s);

//    if (
//            __crk_strcmp(__s, "com.tencent.xin0") == 0
////            __crk_strcmp(__s, "isJailbreak") == 0
////                    || __crk_strcmp(__s, "aa195e7f15378f2eab4c4f044457a074") == 0
////                    || __crk_strcmp(__s, "md5OfMachOHeader") == 0
////                    || __crk_strcmp(__s, "encryptStatusOfMachO") == 0
////                    || __crk_strcmp(__s, "/Library/MobileSubstrate/DynamicLibraries/TSTweakEx.dylib") == 0
////                    || __crk_strcmp(__s, "/private/var/containers/Bundle/Application/A86D0FDF-C229-4A91-9EF7-322B9D47751E/WC.app/Frameworks/ConfSDK.framework/ConfSDK") == 0
////                    || __crk_strcmp(__s, "/Applications/TaskDemo.app/Resource/crkAppInject.framework/crkAppInject") == 0
//
//            ) {
//
////        Origin_NSLog(@"#### **** Fake_strlen %s, %@", __s, __CRK_Orig_NSThread_callStackSymbols);
//        Origin_NSLog(@"#### **** Fake_strlen com.tencent.xin0, %@", __CRK_Orig_NSThread_callStackSymbols);
//    }

//    if (__crk_strcmp(__s, "/Library/MobileSubstrate") == 0
//            || __crk_strcmp(__s, "/Library/MobileSubstrate/MobileSubstrate.dylib") == 0
//            || __crk_strcmp(__s, "/Applications/Cydia.app") == 0
//            || __crk_strcmp(__s, "/bin/bash") == 0
//            || __crk_strcmp(__s, "/usr/sbin/sshd") == 0
//            || __crk_strcmp(__s, "/etc/apt") == 0
//            || __crk_strcmp(__s, "/usr/bin/ssh") == 0
//            || __crk_strcmp(__s, "/tmp/test.txt") == 0
//            || __crk_strcmp(__s, "/private/jailbreak.txt") == 0
//            || __crk_strcmp(__s, "/bin") == 0
//            || __crk_strcmp(__s, "/etc") == 0
//            ) {
//
//        result = result / 2;
//        CRKLog(@"#### Fake_strlen %s", __s);
//    }

    return result;
}

BOOL __CRK_can_access_dyld_name(const char *image_name) {
    if (/*!CRK_FAKE_HIGH_LEVEL
            ||*/ (strstr(image_name, "Cydia") == 0
            && strstr(image_name, "SubstrateLoader") == 0
            && strstr(image_name, "MobileSubstrate") == 0
            && strstr(image_name, "ubstrate") == 0
            && strstr(image_name, "jetslammed") == 0
            && strstr(image_name, "Liberty.dylib") == 0
            && strstr(image_name, "TaskDemo.app") == 0
            && strstr(image_name, "TSTweakEx") == 0
            && strstr(image_name, "libReveal") == 0
            && strstr(image_name, "RHRevealLoader") == 0
            && strstr(image_name, "SSLKillSwitch2") == 0
            && strstr(image_name, "CydiaSubstrate") == 0
            && strstr(image_name, "crkInject") == 0
            && strstr(image_name, "crkAppInject") == 0
            && strstr(image_name, "crkGeneral") == 0
    )) {

        return CRK_CanAccessFile([NSString stringWithUTF8String:image_name], YES);
    }

    return NO;
}

BOOL __CRK_can_access_mach_header_dylib_name(const struct mach_header_64 *mheader) {
    if ((mheader->magic == MH_MAGIC_64 || mheader->magic == MH_CIGAM_64) && mheader->ncmds > 0) {
        void *loadCmd = (void *) (mheader + 1);
        struct segment_command_64 *sc = (struct segment_command_64 *) loadCmd;

        for (int index = 0; index < mheader->ncmds; ++index, sc = (struct segment_command_64 *) ((int8 *) sc + sc->cmdsize)) {
            if (sc->cmd == LC_ID_DYLIB) {
                struct dylib_command *dc = (struct dylib_command *) sc;
                struct dylib dy = dc->dylib;
                char *str = (char *) dc + dy.name.offset;

                // The second usage.
                // Can also use vm_read_overwrite to read the information.

                if (!__CRK_can_access_dyld_name(str)) {
//                    strcpy(str, "");

                    return NO;
                }

                break;
            }
        }
    }

    return YES;
}

kern_return_t (*Origin_task_info)(task_name_t target_task, task_flavor_t flavor, task_info_t p_task_info_out, mach_msg_type_number_t *task_info_outCnt);

kern_return_t Fake_task_info(task_name_t target_task, task_flavor_t flavor, task_info_t p_task_info_out, mach_msg_type_number_t *task_info_outCnt) {
    if (/* DISABLES CODE */ (0)) {
        kern_return_t result = Origin_task_info(target_task, flavor, p_task_info_out, task_info_outCnt);
        return result;
    } else {
        // Reference: https://opensource.apple.com/source/dyld/dyld-421.1/src/dyld_process_info.cpp
        static BOOL __is_dyld_info_cached = NO;
        static struct task_dyld_info __cached_dyld_info;
        static struct dyld_all_image_infos *__p_cached_dyld_all_image_infos = nil;

        if (flavor == TASK_DYLD_INFO) {
            if (__is_dyld_info_cached) {
                memcpy(p_task_info_out, &__cached_dyld_info, sizeof(struct task_dyld_info));
                return KERN_SUCCESS;
            }
        }

        kern_return_t result = Origin_task_info(target_task, flavor, p_task_info_out, task_info_outCnt);
        if (flavor == TASK_DYLD_INFO) {
            if (result == KERN_SUCCESS) {
                struct task_dyld_info dyld_info = *(struct task_dyld_info *) (void *) (p_task_info_out);
                struct dyld_all_image_infos *p_infos = (struct dyld_all_image_infos *) dyld_info.all_image_info_addr;

                // copy
                __p_cached_dyld_all_image_infos = (struct dyld_all_image_infos *) malloc(dyld_info.all_image_info_size);

                memcpy(&__cached_dyld_info, &dyld_info, sizeof(struct task_dyld_info));
                memcpy(__p_cached_dyld_all_image_infos, p_infos, dyld_info.all_image_info_size);

                __cached_dyld_info.all_image_info_addr = (mach_vm_address_t) __p_cached_dyld_all_image_infos;

                // The important thing to replace
                // __cached_dyld_all_image_infos.infoArray
                // __cached_dyld_all_image_infos.uuidArray
                // ^^

                // info array
                {
                    uint32_t origCount = p_infos->infoArrayCount;
                    uint32_t canAccessCount = 0;
                    __p_cached_dyld_all_image_infos->infoArray = (struct dyld_image_info *) malloc(sizeof(struct dyld_image_info) * origCount);
                    struct dyld_image_info *p_info = (struct dyld_image_info *) p_infos->infoArray;

                    for (int i = 0; i < origCount; i++, p_info += 1) {
                        const struct mach_header_64 *mheader = (const struct mach_header_64 *) p_info->imageLoadAddress;
                        BOOL canAccess1 = YES;
                        BOOL canAccess2 = YES;

                        // mheader
                        if (mheader->filetype == MH_DYLIB) {
                            canAccess1 = __CRK_can_access_mach_header_dylib_name(mheader);
                        }

                        // file path
                        const char *imageFilePath = p_info->imageFilePath;
                        canAccess2 = __CRK_can_access_dyld_name(imageFilePath);

                        if (canAccess1 && canAccess2) {
                            memcpy((void *) ((long) __p_cached_dyld_all_image_infos->infoArray + (long) (canAccessCount * sizeof(struct dyld_image_info))), p_info, sizeof(struct dyld_image_info));

                            ++canAccessCount;
                        }
                    }

                    __p_cached_dyld_all_image_infos->infoArrayCount = canAccessCount;
                }

                // uuid array
                {
                    uintptr_t origCount = p_infos->uuidArrayCount;
                    uint32_t canAccessCount = 0;
                    __p_cached_dyld_all_image_infos->uuidArray = (struct dyld_uuid_info *) malloc(sizeof(struct dyld_uuid_info) * origCount);
                    struct dyld_uuid_info *p_info = (struct dyld_uuid_info *) p_infos->uuidArray;

                    for (int i = 0; i < origCount; i++, p_info += 1) {
                        const struct mach_header_64 *mheader = (const struct mach_header_64 *) p_info->imageLoadAddress;
                        BOOL canAccess = YES;

                        if (mheader->filetype == MH_DYLIB) {
                            canAccess = __CRK_can_access_mach_header_dylib_name(mheader);
                        }

                        if (canAccess) {
                            memcpy((void *) ((long) __p_cached_dyld_all_image_infos->uuidArray + (long) (canAccessCount * sizeof(struct dyld_uuid_info))), p_info, sizeof(struct dyld_uuid_info));
                            ++canAccessCount;
                        }
                    }

                    __p_cached_dyld_all_image_infos->uuidArrayCount = canAccessCount;
                }

                // dyldAllImageInfosAddress
                __p_cached_dyld_all_image_infos->dyldAllImageInfosAddress = __p_cached_dyld_all_image_infos;

                // already cached
                __is_dyld_info_cached = YES;
                memcpy(p_task_info_out, &__cached_dyld_info, sizeof(struct task_dyld_info));
            }
        }

        return result;
    }
}

void (*Origin_NSSetUncaughtExceptionHandler)(NSUncaughtExceptionHandler *handler);

void Fake_NSSetUncaughtExceptionHandler(NSUncaughtExceptionHandler *handler) {
    CRKLog(@"fuck Crash, %@", __CRK_Orig_NSThread_callStackSymbols);
}

int (*Origin_signal)(int, void (*)(int));

int Fake_signal(int a1, void (*a2)(int)) {
    if (a1 == SIGABRT
            || a1 == SIGBUS
            || a1 == SIGFPE
            || a1 == SIGILL
            || a1 == SIGPIPE
            || a1 == SIGSEGV
            || a1 == SIGSYS
            || a1 == SIGTRAP
            ) {

        CRKLog(@"fuck Crash signal %ld, %@", (long) a1, __CRK_Orig_NSThread_callStackSymbols);
        return 0;
    } else {
        CRKLog(@"fuck Crash signal %ld, %@", (long) a1, __CRK_Orig_NSThread_callStackSymbols);
        return Origin_signal(a1, a2);
    }
}

kern_return_t (*Origin_task_set_exception_ports)(
        task_t task,
        exception_mask_t exception_mask,
        mach_port_t new_port,
        exception_behavior_t behavior,
        thread_state_flavor_t new_flavor
);

kern_return_t Fake_task_set_exception_ports(
        task_t task,
        exception_mask_t exception_mask,
        mach_port_t new_port,
        exception_behavior_t behavior,
        thread_state_flavor_t new_flavor
) {
    CRKLog(@"fuck Crash, %@", __CRK_Orig_NSThread_callStackSymbols);
    return KERN_SUCCESS;
}

int (*Origin_sigaltstack)(const stack_t *ss, stack_t *oss);

int Fake_sigaltstack(const stack_t *ss, stack_t *oss) {
    CRKLog(@"fuck Crash, %@", __CRK_Orig_NSThread_callStackSymbols);
    return 0;
}

int (*Origin_sigaction)(int signo, const struct sigaction *restrict act, struct sigaction *restrict oact);

int Fake_sigaction(int signo, const struct sigaction *restrict act, struct sigaction *restrict oact) {
    CRKLog(@"fuck Crash, %@", __CRK_Orig_NSThread_callStackSymbols);
    return 0;
}

NSDictionary *__CRK_optimizedSecQuery(CFDictionaryRef query) {
    NSDictionary *nsQuery = (__bridge NSDictionary *) query;

    NSString *service = nsQuery[(__bridge id) kSecAttrService];
    if (service != nil) {
        NSMutableDictionary *newQuery = [[NSMutableDictionary alloc] initWithDictionary:nsQuery];

        NSString *bundleID = __CRK_GetOriginalBundleID();
        NSString *svcePrefix = [NSString stringWithFormat:@"crk_%@_", bundleID];
        NSString *newService = [NSString stringWithFormat:@"%@%@", svcePrefix, service];
        [newQuery setObject:newService forKey:(__bridge id) kSecAttrService];

        nsQuery = newQuery;
    }
    return nsQuery;
}

NSMutableDictionary *__CRK_changeSecDicts(NSDictionary *origResult, BOOL *changed, BOOL *ignore) {
    NSMutableDictionary *newResult = nil;

    if (origResult[@"svce"] != nil) {
        NSString *bundleID = __CRK_GetOriginalBundleID();
        NSString *svcePrefix = [NSString stringWithFormat:@"crk_%@_", bundleID];

        if ([origResult[@"svce"] hasPrefix:svcePrefix]) {
            if (newResult == nil) {
                newResult = [NSMutableDictionary dictionaryWithDictionary:origResult];
            }

            if (changed != nil) {
                *changed = YES;
            }

            newResult[@"svce"] = [origResult[@"svce"] substringFromIndex:svcePrefix.length];
        } else if ([origResult[@"svce"] hasPrefix:@"crk_com.tencent.xin"]) {
            if (ignore != nil) {
                *ignore = YES;
            }

            return nil;
        }
    }

    if (origResult[@"agrp"] != nil) {
        if (newResult == nil) {
            newResult = [NSMutableDictionary dictionaryWithDictionary:origResult];
        }

        if (changed != nil) {
            *changed = YES;
        }

        newResult[@"agrp"] = @"532LCLCWL6.com.tencent.xin";
    }

    return newResult;
}

OSStatus (*Origin_SecItemCopyMatching)(CFDictionaryRef query, CFTypeRef *__nullable CF_RETURNS_RETAINED result);

OSStatus Fake_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *__nullable CF_RETURNS_RETAINED result) {
    NSDictionary *newQuery = __CRK_optimizedSecQuery(query);
    OSStatus error = Origin_SecItemCopyMatching((__bridge CFDictionaryRef) newQuery, result);

    if (result != NULL) {
        CFTypeID typeID = *result == NULL ? 0 : CFGetTypeID(*result);
       CRKLog(@"dict:%ld,data:%ld,string:%ld", (long)CFDictionaryGetTypeID(), (long)CFDataGetTypeID(), (long)CFStringGetTypeID());

        CRKLog(@"origQuery:%@ \n newQuery:%@, \nresultType:%ld, \norigResult:%@", (__bridge NSDictionary *) query, newQuery, (long) typeID, (__bridge id) *result);

        if (typeID == CFDictionaryGetTypeID()) {
            // 如果是dictionary
            BOOL changed = NO;
            BOOL ignore = NO;
            NSMutableDictionary *newResult = __CRK_changeSecDicts((__bridge id) *result, &changed, &ignore);

            if (ignore) {
                CRKLog(@"newResult ignore org dict:%@", (__bridge id) *result);
                CFRelease(*result);
                *result = nil;
            } else if (changed) {
                CFRelease(*result);
                *result = (__bridge_retained CFTypeRef) newResult;

                CRKLog(@"newResult Dict:%@", newResult);
            }
        } else if (typeID == CFArrayGetTypeID()) {
            NSArray *origResult = (__bridge id) *result;
            NSMutableArray *newResult = [NSMutableArray array];

            for (id item in origResult) {
                if ([item isKindOfClass:NSDictionary.class]) {
                    BOOL ignore = NO;
                    NSMutableDictionary *newItem = __CRK_changeSecDicts(item, nil, &ignore);

                    if (ignore) {
                        CRKLog(@"newResult ignore org dict in array:%@", item);
                        continue;
                    }

                    if (newItem == nil) {
                        newItem = item;
                    }

                    [newResult addObject:newItem];
                } else {
                    [newResult addObject:item];
                }
            }

            CFRelease(*result);
            *result = (__bridge_retained CFTypeRef) newResult;

            CRKLog(@"newResult Array:%@", newResult);
        }
    }

    return error;
}

OSStatus (*Origin_SecItemUpdate)(CFDictionaryRef query, CFDictionaryRef attributesToUpdate);

OSStatus Fake_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    NSDictionary *newQuery = __CRK_optimizedSecQuery(query);
    return Origin_SecItemUpdate((__bridge CFDictionaryRef) newQuery, attributesToUpdate);
}

OSStatus (*Origin_SecItemAdd)(CFDictionaryRef attributes, CFTypeRef *__nullable CF_RETURNS_RETAINED result);

OSStatus Fake_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *__nullable CF_RETURNS_RETAINED result) {
    NSDictionary *newQuery = __CRK_optimizedSecQuery(attributes);
    return Origin_SecItemAdd((__bridge CFDictionaryRef) newQuery, result);
}

OSStatus (*Origin_SecItemDelete)(CFDictionaryRef query);

OSStatus Fake_SecItemDelete(CFDictionaryRef query) {
    NSDictionary *newQuery = __CRK_optimizedSecQuery(query);
    return Origin_SecItemDelete((__bridge CFDictionaryRef) newQuery);
}
