#include "SenderBridge.h"
#include <dlfcn.h>
#include <dispatch/dispatch.h>

// These are undocumented macOS functions. Resolve them at runtime so a future
// OS without either symbol can still launch and use conservative wheel defaults.
typedef CFTypeRef (*CopyHIDEvent)(CGEventRef);
typedef uint64_t (*GetSenderID)(CFTypeRef);
static CopyHIDEvent copyHID;
static GetSenderID getSender;
static dispatch_once_t once;
static void initialize(void) {
    dispatch_once(&once, ^{
        dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY | RTLD_LOCAL);
        copyHID = (CopyHIDEvent)dlsym(RTLD_DEFAULT, "CGEventCopyIOHIDEvent");
        getSender = (GetSenderID)dlsym(RTLD_DEFAULT, "IOHIDEventGetSenderID");
    });
}
bool SSSenderLookupAvailable(void) {
    initialize();
    return copyHID && getSender;
}
uint64_t SSScrollSenderID(CGEventRef event) {
    if (!SSSenderLookupAvailable()) return 0;
    CFTypeRef hidEvent = copyHID(event);
    if (!hidEvent) return 0;
    uint64_t result = getSender(hidEvent);
    CFRelease(hidEvent);
    return result;
}
