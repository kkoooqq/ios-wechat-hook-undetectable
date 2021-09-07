#import <objc/runtime.h>
#import <CydiaSubstrate/CydiaSubstrate.h>
#import "CRKH00kWC.h"
#import "CRKHookClasses.h"
#import "CRKH00kImplC.h"
#import "CRKWCDefines.h"
#import "CRKFakeDYLDHelper.h"
#import "CRKWCTools.h"

#define __CRK_Log_HookWCMethods 1

void __CRK_HookWCMethods() {
    // crash monitor
    Class class = objc_getClass("WCCrashBlockMonitor");
    if (class && class_getInstanceMethod(class, NSSelectorFromString(@"installKSCrash:"))) {
        MSHookMessageEx(
                class,
                NSSelectorFromString(@"installKSCrash:"),
                (IMP) &_logos_method$TaskGroup$WCCrashBlockMonitor$installKSCrash$,
                (IMP *) &_logos_orig$TaskGroup$WCCrashBlockMonitor$installKSCrash$);
    }

    // WC 6.7.3
    if (__CRK_IS_WC_673) {
        // sub_102C30
        void *sub_102C30_Ptr = __CRK_WCMMCommon_subOffset(0x102C30);
        if (sub_102C30_Ptr != nil) {
            MSHookFunction(sub_102C30_Ptr, (void *) Fake_sub_102C30, (void **) &Origin_sub_102C30);
        }

        // sub_1185AC
        void *sub_1185AC_Ptr = __CRK_WCMMCommon_subOffset(0x1185AC);
        if (sub_1185AC_Ptr != nil) {
            MSHookFunction(sub_1185AC_Ptr, (void *) Fake_sub_1185AC, (void **) &Origin_sub_1185AC);
        }

        // sub_11F0E0
        // encryptStatusOfMachO
        // force return 1 and indicating that it is encrypted
        // I really don't know how to change mach-o.
        void *sub_11F0E0_Ptr = __CRK_WCMMCommon_subOffset(0x11F0E0);
        if (sub_11F0E0_Ptr != nil) {
            MSHookFunction(sub_11F0E0_Ptr, (void *) Fake_sub_11F0E0, (void **) &Origin_sub_11F0E0);
        }

        // sub_113250
        // Check if version number between 8.0, 11.3, just return 0.
        void *sub_113250_Ptr = __CRK_WCMMCommon_subOffset(0x113250);
        if (sub_113250_Ptr != nil) {
            MSHookFunction(sub_113250_Ptr, (void *) Fake_sub_113250, (void **) &Origin_sub_113250);
        }

        // _md5_digest
        // solve reporting md5OfMachO.
        // It's a disgusting way.
        MSImageRef marsImage = MSGetImageByName("@rpath/mars.framework/mars");

        void (*p_md5_digest)(const char *inBuffer, int len, unsigned char outBuf[16]);
        p_md5_digest = (void (*)(const char *inBuffer, int len, unsigned char outBuf[16])) MSFindSymbol(marsImage, "_md5_digest");
        if (p_md5_digest != nil) {
            MSHookFunction(p_md5_digest, (void *) Fake_md5_digest, (void **) &Origin_md5_digest);
        }
    } else if (__CRK_IS_WC_701) {
        // sub_90198
        void *sub_90198_Ptr = __CRK_WCMMCommon_subOffset(0x90198);
        if (sub_90198_Ptr != nil) {
            MSHookFunction(sub_90198_Ptr, (void *) Fake_sub_102C30, (void **) &Origin_sub_102C30);
        }

        // sub_A095C
        void *sub_A095C_Ptr = __CRK_WCMMCommon_subOffset(0xA095C);
        if (sub_A095C_Ptr != nil) {
            MSHookFunction(sub_A095C_Ptr, (void *) Fake_sub_1185AC, (void **) &Origin_sub_1185AC);
        }

        // sub_AC2B0
        // encryptStatusOfMachO
        void *sub_AC2B0_Ptr = __CRK_WCMMCommon_subOffset(0xAC2B0);
        if (sub_AC2B0_Ptr != nil) {
            MSHookFunction(sub_AC2B0_Ptr, (void *) Fake_sub_11F0E0, (void **) &Origin_sub_11F0E0);
        }

        // sub_A0244
        void *sub_A0244_Ptr = __CRK_WCMMCommon_subOffset(0xA0244);
        if (sub_A0244_Ptr != nil) {
            MSHookFunction(sub_A0244_Ptr, (void *) Fake_sub_113250, (void **) &Origin_sub_113250);
        }

        // _md5_digest
        MSImageRef marsImage = MSGetImageByName("@rpath/mars.framework/mars");

        void (*p_md5_digest)(const char *inBuffer, int len, unsigned char outBuf[16]);
        p_md5_digest = (void (*)(const char *inBuffer, int len, unsigned char outBuf[16])) MSFindSymbol(marsImage, "_md5_digest");
        if (p_md5_digest != nil) {
            MSHookFunction(p_md5_digest, (void *) Fake_md5_digest, (void **) &Origin_md5_digest);
        }
    } else if (__CRK_IS_WC_700) {
        // sub_90158
        void *sub_90158_Ptr = __CRK_WCMMCommon_subOffset(0x90158);
        if (sub_90158_Ptr != nil) {
            MSHookFunction(sub_90158_Ptr, (void *) Fake_sub_102C30, (void **) &Origin_sub_102C30);
        }

        // sub_A091C
        void *sub_A091C_Ptr = __CRK_WCMMCommon_subOffset(0xA091C);
        if (sub_A091C_Ptr != nil) {
            MSHookFunction(sub_A091C_Ptr, (void *) Fake_sub_1185AC, (void **) &Origin_sub_1185AC);
        }

        // sub_AC270
        // encryptStatusOfMachO
        void *sub_AC270_Ptr = __CRK_WCMMCommon_subOffset(0xAC270);
        if (sub_AC270_Ptr != nil) {
            MSHookFunction(sub_AC270_Ptr, (void *) Fake_sub_11F0E0, (void **) &Origin_sub_11F0E0);
        }

        // sub_A0204
        void *sub_A0204_Ptr = __CRK_WCMMCommon_subOffset(0xA0204);
        if (sub_A0204_Ptr != nil) {
            MSHookFunction(sub_A0204_Ptr, (void *) Fake_sub_113250, (void **) &Origin_sub_113250);
        }

        // _md5_digest
        MSImageRef marsImage = MSGetImageByName("@rpath/mars.framework/mars");

        void (*p_md5_digest)(const char *inBuffer, int len, unsigned char outBuf[16]);
        p_md5_digest = (void (*)(const char *inBuffer, int len, unsigned char outBuf[16])) MSFindSymbol(marsImage, "_md5_digest");
        if (p_md5_digest != nil) {
            MSHookFunction(p_md5_digest, (void *) Fake_md5_digest, (void **) &Origin_md5_digest);
        }
    } else if (__CRK_IS_WC_703) {
        // sub_93DA8
        void *sub_93DA8_Ptr = __CRK_WCMMCommon_subOffset(0x93DA8);
        if (sub_93DA8_Ptr != nil) {
            MSHookFunction(sub_93DA8_Ptr, (void *) Fake_sub_102C30, (void **) &Origin_sub_102C30);
        }
        
        // sub_A456C
        void *sub_A456C_Ptr = __CRK_WCMMCommon_subOffset(0xA456C);
        if (sub_A456C_Ptr != nil) {
            MSHookFunction(sub_A456C_Ptr, (void *) Fake_sub_1185AC, (void **) &Origin_sub_1185AC);
        }
        
        // sub_AFEC0
        // encryptStatusOfMachO
        void *sub_AFEC0_Ptr = __CRK_WCMMCommon_subOffset(0xAFEC0);
        if (sub_AFEC0_Ptr != nil) {
            MSHookFunction(sub_AFEC0_Ptr, (void *) Fake_sub_11F0E0, (void **) &Origin_sub_11F0E0);
        }
        
        // sub_A3E54
        void *sub_A3E54_Ptr = __CRK_WCMMCommon_subOffset(0xA3E54);
        if (sub_A3E54_Ptr != nil) {
            MSHookFunction(sub_A3E54_Ptr, (void *) Fake_sub_113250, (void **) &Origin_sub_113250);
        }
        
        // _md5_digest
        MSImageRef marsImage = MSGetImageByName("@rpath/mars.framework/mars");
        
        void (*p_md5_digest)(const char *inBuffer, int len, unsigned char outBuf[16]);
        p_md5_digest = (void (*)(const char *inBuffer, int len, unsigned char outBuf[16])) MSFindSymbol(marsImage, "_md5_digest");
        if (p_md5_digest != nil) {
            MSHookFunction(p_md5_digest, (void *) Fake_md5_digest, (void **) &Origin_md5_digest);
        }
    } else if (__CRK_IS_WC_704) {
        // sub_10071FF40
        void *sub_10071FF40_Ptr = __CRK_WCApp_subOffset(0x10071FF40);
        if (sub_10071FF40_Ptr != nil) {
            MSHookFunction(sub_10071FF40_Ptr, (void *) Fake_sub_102C30, (void **) &Origin_sub_102C30);
        }
        
        // sub_100720344
        void *sub_100720344_Ptr = __CRK_WCApp_subOffset(0x100720344);
        if (sub_100720344_Ptr != nil) {
            MSHookFunction(sub_100720344_Ptr, (void *) Fake_sub_1185AC, (void **) &Origin_sub_1185AC);
        }
        
        // sub_1007950A0
        // encryptStatusOfMachO
        void *sub_1007950A0_Ptr = __CRK_WCApp_subOffset(0x1007950A0);
        if (sub_1007950A0_Ptr != nil) {
            MSHookFunction(sub_1007950A0_Ptr, (void *) Fake_sub_11F0E0, (void **) &Origin_sub_11F0E0);
        }
        
        // sub_1006DA634
        void *sub_1006DA634_Ptr = __CRK_WCApp_subOffset(0x1006DA634);
        if (sub_1006DA634_Ptr != nil) {
            MSHookFunction(sub_1006DA634_Ptr, (void *) Fake_sub_113250, (void **) &Origin_sub_113250);
        }
        
        // _md5_digest
        MSImageRef marsImage = MSGetImageByName("@rpath/mars.framework/mars");
        
        void (*p_md5_digest)(const char *inBuffer, int len, unsigned char outBuf[16]);
        p_md5_digest = (void (*)(const char *inBuffer, int len, unsigned char outBuf[16])) MSFindSymbol(marsImage, "_md5_digest");
        if (p_md5_digest != nil) {
            MSHookFunction(p_md5_digest, (void *) Fake_md5_digest, (void **) &Origin_md5_digest);
        }
    } else if (__CRK_IS_WC_705) {
        // sub_100BC15B0: search "mig_get_reply_port" in main project's IDA imports and check referenced
        void *sub_100BC15B0_Ptr = __CRK_WCApp_subOffset(0x100BC15B0);
        if (sub_100BC15B0_Ptr != nil) {
            MSHookFunction(sub_100BC15B0_Ptr, (void *) Fake_sub_102C30, (void **) &Origin_sub_102C30);
        }
        
        // sub_100BC19B4: search "__dyld_dladdr" in strings window and check referenced
        void *sub_100BC19B4_Ptr = __CRK_WCApp_subOffset(0x100BC19B4);
        if (sub_100BC19B4_Ptr != nil) {
            MSHookFunction(sub_100BC19B4_Ptr, (void *) Fake_sub_1185AC, (void **) &Origin_sub_1185AC);
        }
        
        // sub_100C1E43C：search "syscall error" in strings window, then check referenced,
        // if "if ( *v65 == 33 || *v65 == 44 )" exists in corresponding method, then that is the target method.
        // encryptStatusOfMachO
        void *sub_100C1E43C_Ptr = __CRK_WCApp_subOffset(0x100C1E43C);
        if (sub_100C1E43C_Ptr != nil) {
            MSHookFunction(sub_100C1E43C_Ptr, (void *) Fake_sub_11F0E0, (void **) &Origin_sub_11F0E0);
        }
        
        // sub_100B786A8：search "sdk system compatible test", then check the references,
        // you will find two places, choose the less method implementation (single instance),
        // according to its references can locate single instance method that uses it,
        // and confirm methods call by 5 that involve reading and writing files (folders),
        // Then the method is the target.
        void *sub_100B786A8_Ptr = __CRK_WCApp_subOffset(0x100B786A8);
        if (sub_100B786A8_Ptr != nil) {
            MSHookFunction(sub_100B786A8_Ptr, (void *) Fake_sub_113250, (void **) &Origin_sub_113250);
        }
        
        // _md5_digest
        MSImageRef marsImage = MSGetImageByName("@rpath/mars.framework/mars");
        
        void (*p_md5_digest)(const char *inBuffer, int len, unsigned char outBuf[16]);
        p_md5_digest = (void (*)(const char *inBuffer, int len, unsigned char outBuf[16])) MSFindSymbol(marsImage, "_md5_digest");
        if (p_md5_digest != nil) {
            MSHookFunction(p_md5_digest, (void *) Fake_md5_digest, (void **) &Origin_md5_digest);
        }
    }
}

bool (*_logos_orig$TaskGroup$WCCrashBlockMonitor$installKSCrash$)(id self, SEL _cmd, id arg);

bool _logos_method$TaskGroup$WCCrashBlockMonitor$installKSCrash$(id self, SEL _cmd, id arg) {
    CRKLog(@"fuck Crash, %@", __CRK_Orig_NSThread_callStackSymbols);
    return true;
}

kern_return_t (*Origin_sub_102C30)(task_name_t target_task, task_flavor_t flavor, task_info_t task_info_out, mach_msg_type_number_t *task_info_outCnt);

kern_return_t Fake_sub_102C30(task_name_t target_task, task_flavor_t flavor, task_info_t task_info_out, mach_msg_type_number_t *task_info_outCnt) {
    CRKLog(@"#### task_name:%ld flavor:%ld", (long) target_task, (long) flavor);
    
    if (__CRK_Log_HookWCMethods) {
        CRKLog(@"$$$$$hook WC sub_102C30 task_info");
    }

    kern_return_t result;

    if (flavor == TASK_DYLD_INFO) {
        result = Fake_task_info(target_task, flavor, task_info_out, task_info_outCnt);
    } else {
        result = Origin_sub_102C30(target_task, flavor, task_info_out, task_info_outCnt);
    }

    return result;
}

int (*Origin_sub_1185AC)(const void *a1, Dl_info *a2);

int Fake_sub_1185AC(const void *a1, Dl_info *a2) {
    CRKLog(@"#### a1:%ld a2:%ld", (long) a1, (long) a2);
    
    if (__CRK_Log_HookWCMethods) {
        CRKLog(@"$$$$$hook WC sub_1185AC __dyld_dladdr");
    }
    
    return Fake_dladdr(a1, a2);
}

int (*Origin_sub_11F0E0)(void);

int Fake_sub_11F0E0() {
    int origResult = Origin_sub_11F0E0();

    if (__CRK_Log_HookWCMethods) {
        CRKLog(@"$$$$$hook WC sub_11F0E0 encrypt status origResult: %ld", (long) origResult);
    }

    return 1;
}

int (*Origin_sub_113250)(void);

int Fake_sub_113250() {
    
    if (__CRK_Log_HookWCMethods) {
        CRKLog(@"$$$$$hook WC sub_113250 8.0->11.3, return 0, %@", __CRK_Orig_NSThread_callStackSymbols);
    }

    return 0;
}

void (*Origin_md5_digest)(const char *inBuffer, int len, unsigned char outBuf[16]);

void Fake_md5_digest(const char *inBuffer, int len, unsigned char result[16]) {
    Origin_md5_digest(inBuffer, len, result);

    if (__CRK_IS_WC_673) {
        BYTE faultResult99[] = {(BYTE) 0xaa, (BYTE) 0x19, (BYTE) 0x5e, (BYTE) 0x7f, (BYTE) 0x15, (BYTE) 0x37, (BYTE) 0x8f, (BYTE) 0x2e, (BYTE) 0xab, (BYTE) 0x4c, (BYTE) 0x4f, (BYTE) 0x04, (BYTE) 0x44, (BYTE) 0x57, (BYTE) 0xa0, (BYTE) 0x74};
        BYTE faultResult0[] = {(BYTE) 0x78, (BYTE) 0x04, (BYTE) 0x07, (BYTE) 0x4c, (BYTE) 0x35, (BYTE) 0x05, (BYTE) 0xce, (BYTE) 0xea, (BYTE) 0x48, (BYTE) 0x89, (BYTE) 0xe1, (BYTE) 0x9e, (BYTE) 0x17, (BYTE) 0x57, (BYTE) 0x73, (BYTE) 0xaf};
        BYTE faultResult6[] = {(BYTE) 0xb1, (BYTE) 0x5f, (BYTE) 0xed, (BYTE) 0x59, (BYTE) 0x5a, (BYTE) 0xd2, (BYTE) 0xb8, (BYTE) 0x22, (BYTE) 0xf1, (BYTE) 0x96, (BYTE) 0x91, (BYTE) 0xef, (BYTE) 0xc1, (BYTE) 0x74, (BYTE) 0x1c, (BYTE) 0xb4};

        //
        if (len == 9288
                && (memcmp(result, faultResult99, 16) == 0 || memcmp(result, faultResult0, 16) == 0 || memcmp(result, faultResult6, 16) == 0)) {

            BYTE correctResult[] = {(BYTE) 0x8f, (BYTE) 0x04, (BYTE) 0xd7, (BYTE) 0x2c, (BYTE) 0x23, (BYTE) 0xa2, (BYTE) 0x80, (BYTE) 0xae, (BYTE) 0xf7, (BYTE) 0x5d, (BYTE) 0xb4, (BYTE) 0x6b, (BYTE) 0x52, (BYTE) 0xe1, (BYTE) 0x9c, (BYTE) 0xe1};
            memcpy(result, correctResult, 16);

            CRKLog(@"6.7.3 inBuffer: %s len: %ld result: %02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                    inBuffer, (long) len,
                    result[0], result[1], result[2], result[3],
                    result[4], result[5], result[6], result[7],
                    result[8], result[9], result[10], result[11],
                    result[12], result[13], result[14], result[15]);
        }
    } else if (__CRK_IS_WC_701) {
        BYTE faultResult0[] = {(BYTE) 0x9b, (BYTE) 0xbb, (BYTE) 0x43, (BYTE) 0xdb, (BYTE) 0x75, (BYTE) 0x4a, (BYTE) 0xad, (BYTE) 0xaf, (BYTE) 0x80, (BYTE) 0xeb, (BYTE) 0x10, (BYTE) 0x42, (BYTE) 0x34, (BYTE) 0xa0, (BYTE) 0x1d, (BYTE) 0xc1};

        if (len == 9344 && memcmp(result, faultResult0, 16) == 0) {
            BYTE correctResult[] = {(BYTE) 0x3a, (BYTE) 0x09, (BYTE) 0x31, (BYTE) 0xe0, (BYTE) 0x36, (BYTE) 0x77, (BYTE) 0x15, (BYTE) 0x18, (BYTE) 0x8f, (BYTE) 0xb5, (BYTE) 0xc6, (BYTE) 0x2c, (BYTE) 0x86, (BYTE) 0x14, (BYTE) 0x26, (BYTE) 0x33};
            memcpy(result, correctResult, 16);

            CRKLog(@"7.0.1 inBuffer: %s len: %ld result: %02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                    inBuffer, (long) len,
                    result[0], result[1], result[2], result[3],
                    result[4], result[5], result[6], result[7],
                    result[8], result[9], result[10], result[11],
                    result[12], result[13], result[14], result[15]);
        }
    } else if (__CRK_IS_WC_703) {
        BYTE faultResult0[] = {(BYTE) 0x34, (BYTE) 0xa6, (BYTE) 0x9e, (BYTE) 0x01, (BYTE) 0x7d, (BYTE) 0x51, (BYTE) 0xdb, (BYTE) 0xca, (BYTE) 0x56, (BYTE) 0x14, (BYTE) 0x0e, (BYTE) 0x54, (BYTE) 0x51, (BYTE) 0x94, (BYTE) 0x67, (BYTE) 0x86};
        
        if (len == 9344 && memcmp(result, faultResult0, 16) == 0) {
            BYTE correctResult[] = {(BYTE) 0x4c, (BYTE) 0x54, (BYTE) 0x1f, (BYTE) 0x4f, (BYTE) 0xca, (BYTE) 0x66, (BYTE) 0xdd, (BYTE) 0x93, (BYTE) 0xa3, (BYTE) 0x51, (BYTE) 0xd4, (BYTE) 0x23, (BYTE) 0x9e, (BYTE) 0xca, (BYTE) 0xf7, (BYTE) 0xae};
            memcpy(result, correctResult, 16);
            
            CRKLog(@"7.0.3 inBuffer: %s len: %ld result: %02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   inBuffer, (long) len,
                   result[0], result[1], result[2], result[3],
                   result[4], result[5], result[6], result[7],
                   result[8], result[9], result[10], result[11],
                   result[12], result[13], result[14], result[15]);
        }
    } else if (__CRK_IS_WC_704) {
        BYTE faultResult0[] = {(BYTE) 0xe9, (BYTE) 0x85, (BYTE) 0x42, (BYTE) 0xd7, (BYTE) 0x79, (BYTE) 0x78, (BYTE) 0xe1, (BYTE) 0x91, (BYTE) 0xe8, (BYTE) 0x50, (BYTE) 0x3d, (BYTE) 0x44, (BYTE) 0xc8, (BYTE) 0xff, (BYTE) 0x97, (BYTE) 0x70};
        
        if (len == 9464 && memcmp(result, faultResult0, 16) == 0) {
            BYTE correctResult[] = {(BYTE) 0x71, (BYTE) 0x58, (BYTE) 0x83, (BYTE) 0xe2, (BYTE) 0xcd, (BYTE) 0x36, (BYTE) 0xfe, (BYTE) 0x39, (BYTE) 0x34, (BYTE) 0x99, (BYTE) 0xd4, (BYTE) 0xa2, (BYTE) 0x8d, (BYTE) 0xb8, (BYTE) 0xee, (BYTE) 0x7e};
            memcpy(result, correctResult, 16);
            
            CRKLog(@"7.0.4 inBuffer: %s len: %ld result: %02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   inBuffer, (long) len,
                   result[0], result[1], result[2], result[3],
                   result[4], result[5], result[6], result[7],
                   result[8], result[9], result[10], result[11],
                   result[12], result[13], result[14], result[15]);
        }
    } else if (__CRK_IS_WC_705) {
        // f937da17cb5da29293e98f6499050f25
        // f9 37 da 17 cb 5d a2 92 93 e9 8f 64 99 05 0f 25
        BYTE faultResult0[] = {(BYTE) 0xf9, (BYTE) 0x37, (BYTE) 0xda, (BYTE) 0x17, (BYTE) 0xcb, (BYTE) 0x5d, (BYTE) 0xa2, (BYTE) 0x92, (BYTE) 0x93, (BYTE) 0xe9, (BYTE) 0x8f, (BYTE) 0x64, (BYTE) 0x99, (BYTE) 0x05, (BYTE) 0x0f, (BYTE) 0x25};
        
        if (len == 9464 && memcmp(result, faultResult0, 16) == 0) {
            // 56a6f20eeef6c06b701bb242a4a8ba60
            // 56 a6 f2 0e ee f6 c0 6b 70 1b b2 42 a4 a8 ba 60
            BYTE correctResult[] = {(BYTE) 0x56, (BYTE) 0xa6, (BYTE) 0xf2, (BYTE) 0x0e, (BYTE) 0xee, (BYTE) 0xf6, (BYTE) 0xc0, (BYTE) 0x6b, (BYTE) 0x70, (BYTE) 0x1b, (BYTE) 0xb2, (BYTE) 0x42, (BYTE) 0xa4, (BYTE) 0xa8, (BYTE) 0xba, (BYTE) 0x60};
            memcpy(result, correctResult, 16);
            
            CRKLog(@"7.0.5 inBuffer: %s len: %ld result: %02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   inBuffer, (long) len,
                   result[0], result[1], result[2], result[3],
                   result[4], result[5], result[6], result[7],
                   result[8], result[9], result[10], result[11],
                   result[12], result[13], result[14], result[15]);
        }
    }
}


