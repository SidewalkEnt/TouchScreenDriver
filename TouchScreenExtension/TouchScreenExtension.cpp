//
//  TouchScreenExtension.cpp
//  TouchScreenExtension
//
//  Created by 변희주 on 4/9/25.
//

#include "TouchScreenExtension.h"

#include <os/log.h>
#include <DriverKit/IOUserServer.h>
#include <DriverKit/IOLib.h>
#include <DriverKit/OSCollections.h>

struct TouchScreenExtension_IVars
{
    OSArray *elements;
    
    struct {
        OSArray *collections;
    } digitizer;
};

#define _elements   ivars->elements
#define _digitizer  ivars->digitizer

bool TouchScreenExtension::init()
{
    os_log(OS_LOG_DEFAULT, "TouchScreenExtension init");

    if (!super::init()) {
        return false;
    }
    
    ivars = IONewZero(TouchScreenExtension_IVars, 1);
    if (!ivars) {
        return false;
    }
    
exit:
    return true;
}

void TouchScreenExtension::free()
{
    if (ivars) {
        OSSafeReleaseNULL(_elements);
        OSSafeReleaseNULL(_digitizer.collections);
    }
    
    IOSafeDeleteNULL(ivars, TouchScreenExtension_IVars, 1);
    super::free();
}

kern_return_t
IMPL(TouchScreenExtension, Start)
{
    kern_return_t ret;
    
    ret = Start(provider, SUPERDISPATCH);
    if (ret != kIOReturnSuccess) {
        Stop(provider, SUPERDISPATCH);
        return ret;
    }

    os_log(OS_LOG_DEFAULT, "Hello World");
    
    RegisterService();
    
    return ret;
}
