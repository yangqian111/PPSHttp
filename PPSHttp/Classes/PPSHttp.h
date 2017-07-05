//
//  PPSHttp.h
//  Pods
//
//  Created by ppsheep on 2017/7/4.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface PPSHttp : NSObject

+ (void)GET:(NSString *)URLString
 parameters:(nullable id)parameters
    success:(nullable void (^)(NSData *__nullable data,NSURLResponse * __nullable response))success
    failure:(nullable void (^)(NSError *__nullable error))failure;


+ (void)POST:(NSString *)URLString
  parameters:(nullable id)parameters
     success:(nullable void (^)(NSData *__nullable data,NSURLResponse * __nullable response))success
     failure:(nullable void (^)(NSError *__nullable error))failure;

@end

NS_ASSUME_NONNULL_END
