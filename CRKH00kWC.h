#import <Foundation/Foundation.h>
#import <mach/mach_types.h>
#import <dlfcn.h>

extern void __CRK_HookWCMethods(void);

extern bool (*_logos_orig$TaskGroup$WCCrashBlockMonitor$installKSCrash$)(id self, SEL _cmd, id arg);

extern bool _logos_method$TaskGroup$WCCrashBlockMonitor$installKSCrash$(id self, SEL _cmd, id arg);

extern kern_return_t (*Origin_sub_102C30)(task_name_t target_task, task_flavor_t flavor, task_info_t task_info_out, mach_msg_type_number_t *task_info_outCnt);

extern kern_return_t Fake_sub_102C30(task_name_t target_task, task_flavor_t flavor, task_info_t task_info_out, mach_msg_type_number_t *task_info_outCnt);

extern int (*Origin_sub_1185AC)(const void *a1, Dl_info *a2);

extern int Fake_sub_1185AC(const void *a1, Dl_info *a2);

extern int (*Origin_sub_11F0E0)(void);

extern int Fake_sub_11F0E0(void);

extern int (*Origin_sub_113250)(void);

extern int Fake_sub_113250(void);

extern void (*Origin_md5_digest)(const char *inBuffer, int len, unsigned char outBuf[16]);

extern void Fake_md5_digest(const char *inBuffer, int len, unsigned char result[16]);

