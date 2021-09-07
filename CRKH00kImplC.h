#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CFNetwork/CFNetwork.h>
#import <CFNetwork/CFNetworkDefs.h>
#import <CoreFoundation/CoreFoundation.h>
#import <dirent.h>
#import <dlfcn.h>
#import <ifaddrs.h>
#import <CoreLocation/CoreLocation.h>
#import <ifaddrs.h>
#import <sys/utsname.h>
#import <sys/stat.h>
#import <sys/mount.h>
#import <sys/signal.h>
#import <mach/mach_types.h>
#import <Security/Security.h>

CF_EXPORT CFTypeRef Fake_CFBundleGetValueForInfoDictionaryKey(CFBundleRef bundle, CFStringRef key);

CF_EXPORT CFTypeRef (*Origin_CFBundleGetValueForInfoDictionaryKey)(CFBundleRef bundle, CFStringRef key);

OBJC_EXTERN CFStringRef MGCopyAnswer(CFStringRef prop);

OBJC_EXTERN CFStringRef (*Origin_MGCopyAnswer)(CFStringRef prop, uint32_t *outTypeCode);

OBJC_EXTERN CFStringRef Fake_MGCopyAnswer(CFStringRef prop, uint32_t *outTypeCode);

extern int (*Origin_sysctl)(int *, u_int, void *, size_t *, void *, size_t);

extern int Fake_sysctl(int *, u_int, void *, size_t *, void *, size_t);

extern int (*Origin_uname)(struct utsname *a1);

extern int Fake_uname(struct utsname *a1);

extern int (*Origin_sysctlbyname)(const char *, void *, size_t *, void *, size_t);

extern int Fake_sysctlbyname(const char *, void *, size_t *, void *, size_t);

extern char *(*Origin_getenv)(const char *);

extern char *Fake_getenv(const char *);

extern const char *(*Origin_dyld_get_image_name)(uint32_t image_index);

extern const char *Fake_dyld_get_image_name(uint32_t image_index);

extern uint32_t (*Origin_dyld_image_count)(void);

extern uint32_t Fake_dyld_image_count(void);

extern const struct mach_header *(*Origin_dyld_get_image_header)(uint32_t image_index);

extern const struct mach_header *Fake_dyld_get_image_header(uint32_t image_index);

extern intptr_t (*Origin_dyld_get_image_vmaddr_slide)(uint32_t image_index);

extern intptr_t Fake_dyld_get_image_vmaddr_slide(uint32_t image_index);

extern void (*Origin_dyld_register_func_for_add_image)(void (*func)(const struct mach_header *mh, intptr_t vmaddr_slide));

extern void Fake_dyld_register_func_for_add_image(void (*func)(const struct mach_header *mh, intptr_t vmaddr_slide));

extern void (*Origin_dyld_register_func_for_remove_image)(void (*func)(const struct mach_header *mh, intptr_t vmaddr_slide));

extern void Fake_dyld_register_func_for_remove_image(void (*func)(const struct mach_header *mh, intptr_t vmaddr_slide));

extern int (*Origin_ptrace)(int _request, pid_t _pid, caddr_t _addr, int _data);

extern int Fake_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data);

//extern CFDictionaryRef MobileInstallationLookup(id a1);
extern CFDictionaryRef (*Origin_MobileInstallationLookup)(id a1);

extern CFDictionaryRef Fake_MobileInstallationLookup(id a1);

extern int (*Origin_stat)(const char *, struct stat *);

extern int Fake_stat(const char *, struct stat *);

extern int (*Origin_lstat)(const char *, struct stat *);

extern int Fake_lstat(const char *, struct stat *);

extern CFDictionaryRef _CFCopySystemVersionDictionary(void);

extern CFDictionaryRef (*Origin_CFCopySystemVersionDictionary)(void);

extern CFDictionaryRef Fake_CFCopySystemVersionDictionary(void);

extern CFDictionaryRef (*Origin_CFBundleGetInfoDictionary)(CFBundleRef bundle);

extern CFDictionaryRef Fake_CFBundleGetInfoDictionary(CFBundleRef bundle);

extern CFHTTPMessageRef (*Origin_CFHTTPMessageCreateRequest)(CFAllocatorRef __nullable alloc, CFStringRef requestMethod, CFURLRef url, CFStringRef httpVersion);

extern CFHTTPMessageRef Fake_CFHTTPMessageCreateRequest(CFAllocatorRef __nullable alloc, CFStringRef requestMethod, CFURLRef url, CFStringRef httpVersion);

/*
 *  CFURLRequestCachePolicy
 *
 *  Discussion:
 *	The caching policy to be used when processing the request
 */
enum CFURLRequestCachePolicy {

    /*
     * Allow the underlying protocol (like HTTP) to choose the most
     */
            kCFURLRequestCachePolicyProtocolDefault = 0,

    /*
     * Ignore any cached contents, requiring that the content come from
     * the origin server
     */
            kCFURLRequestCachePolicyReloadIgnoringCache = 1,

    /*
     * Return the contents of the cache (if any), otherwise load from the
     * origin server
     */
            kCFURLRequestCachePolicyReturnCacheDataElseLoad = 2,

    /*
     * Return the contents of the cache (if any), otherwise, return
     * nothing
     */
            kCFURLRequestCachePolicyReturnCacheDataDontLoad = 3
};
typedef enum CFURLRequestCachePolicy CFURLRequestCachePolicy;

typedef const struct _CFURLRequest *CFURLRequestRef;

extern CFURLRequestRef CFURLRequestCreate(
        CFAllocatorRef alloc,
        CFURLRef URL,
        CFURLRequestCachePolicy cachePolicy,
        CFTimeInterval timeout,
        CFURLRef mainDocumentURL);

extern CFURLRequestRef (*Origin_CFURLRequestCreate)(
        CFAllocatorRef alloc,
        CFURLRef URL,
        CFURLRequestCachePolicy cachePolicy,
        CFTimeInterval timeout,
        CFURLRef mainDocumentURL);

extern CFURLRequestRef Fake_CFURLRequestCreate(
        CFAllocatorRef alloc,
        CFURLRef URL,
        CFURLRequestCachePolicy cachePolicy,
        CFTimeInterval timeout,
        CFURLRef mainDocumentURL);

typedef struct _CFURLRequest *CFMutableURLRequestRef;

extern Boolean CFURLRequestSetURL(
        CFMutableURLRequestRef mutableRequest,
        CFURLRef url);

extern Boolean (*Origin_CFURLRequestSetURL)(
        CFMutableURLRequestRef mutableRequest,
        CFURLRef url);

extern Boolean Fake_CFURLRequestSetURL(
        CFMutableURLRequestRef mutableRequest,
        CFURLRef url);

extern int (*Origin_system)(const char *);

extern int Fake_system(const char *);

extern pid_t (*Origin_fork)(void);

extern pid_t Fake_fork(void);

extern void *(*Origin_dlopen)(const char *__path, int __mode);

extern void *Fake_dlopen(const char *__path, int __mode);

extern FILE *(*Origin_fopen)(const char *__restrict __filename, const char *__restrict __mode);

extern FILE *Fake_fopen(const char *__restrict __filename, const char *__restrict __mode);

extern DIR *(*Origin_opendir2)(const char *, int);

extern DIR *Fake_opendir2(const char *, int);

extern int (*Origin_dladdr)(const void *, Dl_info *);

extern int Fake_dladdr(const void *, Dl_info *);

extern int (*Origin_statfs)(const char *, struct statfs *);

extern int Fake_statfs(const char *, struct statfs *);

extern const struct section_64 *(*Origin_getsectbyname)(
        const char *segname,
        const char *sectname);

extern const struct section_64 *Fake_getsectbyname(
        const char *segname,
        const char *sectname);

typedef struct {
    intptr_t majorVersion;
    intptr_t minorVersion;
    intptr_t patchVersion;
} _SwiftNSOperatingSystemVersion;

extern _SwiftNSOperatingSystemVersion (*Origin__swift_stdlib_operatingSystemVersion)(void);

extern _SwiftNSOperatingSystemVersion Fake__swift_stdlib_operatingSystemVersion(void);

extern void (*Origin_NSLog)(NSString *format, ...);

extern void Fake_NSLog(NSString *format, ...);

extern void (*Origin_NSLogv)(NSString *format, va_list args);

extern void Fake_NSLogv(NSString *format, va_list args);

extern int (*Origin_access)(const char *, int);

extern int Fake_access(const char *, int);

extern int (*Origin_faccessat)(int, const char *, int, int);

extern int Fake_faccessat(int, const char *, int, int);

extern CFArrayRef (*Origin_CFBundleGetAllBundles)(void);

extern CFArrayRef Fake_CFBundleGetAllBundles(void);

extern void *(*Origin_dlsym)(void *__handle, const char *__symbol);

extern void *Fake_dlsym(void *__handle, const char *__symbol);

extern int (*Origin_open)(const char *, int, ...);

extern int Fake_open(const char *, int, ...);

typedef int (*open_ptr_t)(const char *, int, ...);

extern open_ptr_t origfish_open;

extern int fakefish_open(const char *, int, va_list);

extern DIR *(*Origin_opendir)(const char *);

extern DIR *Fake_opendir(const char *);

extern int (*Origin_symlink)(const char *, const char *);

extern int Fake_symlink(const char *, const char *);

extern pid_t (*Origin_vfork)(void);

extern pid_t Fake_vfork(void);

extern int (*Origin_syscall)(int code, va_list args);

extern int Fake_syscall(int code, ...);

// WC
extern int (*Origin_remove)(const char *);

extern int Fake_remove(const char *);

extern int (*Origin_rename)(const char *__old, const char *__new);

extern int Fake_rename(const char *__old, const char *__new);

extern mach_port_t (*Origin_mig_get_reply_port)(void);

extern mach_port_t Fake_mig_get_reply_port(void);

extern void (*Origin_mig_put_reply_port)(mach_port_t reply_port);

extern void Fake_mig_put_reply_port(mach_port_t reply_port);

extern size_t (*Origin_strlen)(const char *__s);

extern size_t Fake_strlen(const char *__s);

extern kern_return_t (*Origin_task_info)(task_name_t target_task, task_flavor_t flavor, task_info_t task_info_out, mach_msg_type_number_t *task_info_outCnt);

extern kern_return_t Fake_task_info(task_name_t target_task, task_flavor_t flavor, task_info_t task_info_out, mach_msg_type_number_t *task_info_outCnt);

// crash
extern void (*Origin_NSSetUncaughtExceptionHandler)(NSUncaughtExceptionHandler *handler);

extern void Fake_NSSetUncaughtExceptionHandler(NSUncaughtExceptionHandler *handler);

extern int (*Origin_signal)(int, void (*)(int));

extern int Fake_signal(int, void (*)(int));

extern kern_return_t (*Origin_task_set_exception_ports)(
        task_t task,
        exception_mask_t exception_mask,
        mach_port_t new_port,
        exception_behavior_t behavior,
        thread_state_flavor_t new_flavor
);

extern kern_return_t Fake_task_set_exception_ports(
        task_t task,
        exception_mask_t exception_mask,
        mach_port_t new_port,
        exception_behavior_t behavior,
        thread_state_flavor_t new_flavor
);

extern int (*Origin_sigaltstack)(const stack_t *ss, stack_t *oss);

extern int Fake_sigaltstack(const stack_t *ss, stack_t *oss);

extern int (*Origin_sigaction)(int signo, const struct sigaction *restrict act, struct sigaction *restrict oact);

extern int Fake_sigaction(int signo, const struct sigaction *restrict act, struct sigaction *restrict oact);

// ----

// keychain

extern OSStatus (*Origin_SecItemCopyMatching)(CFDictionaryRef query, CFTypeRef *__nullable CF_RETURNS_RETAINED result);

extern OSStatus Fake_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *__nullable CF_RETURNS_RETAINED result);

extern OSStatus (*Origin_SecItemUpdate)(CFDictionaryRef query, CFDictionaryRef attributesToUpdate);

extern OSStatus Fake_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate);

extern OSStatus (*Origin_SecItemAdd)(CFDictionaryRef attributes, CFTypeRef *__nullable CF_RETURNS_RETAINED result);

extern OSStatus Fake_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *__nullable CF_RETURNS_RETAINED result);

extern OSStatus (*Origin_SecItemDelete)(CFDictionaryRef query);

extern OSStatus Fake_SecItemDelete(CFDictionaryRef query);
