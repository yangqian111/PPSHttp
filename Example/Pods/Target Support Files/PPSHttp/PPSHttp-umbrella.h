#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "PPSHttp.h"
#import "PPSRequestOperationManager.h"
#import "PPSURLRequestSerialization.h"

FOUNDATION_EXPORT double PPSHttpVersionNumber;
FOUNDATION_EXPORT const unsigned char PPSHttpVersionString[];

