//
//  PPSRequestOperationManager.h
//  Pods
//
//  Created by ppsheep on 2017/7/4.
//
//

#import <Foundation/Foundation.h>

@interface PPSRequestOperationManager : NSObject

+ (instancetype _Nullable )manager;

- (nullable NSURLSessionDataTask *)method:(nonnull NSString *)method
                             URL:(nonnull NSString *)URL
                      parameters:(nullable id)parameters
                         success:(nullable void(^)(NSData *__nullable data,NSURLResponse * __nullable response))success
                         failure:(nullable void (^)(NSError *__nullable error))failure;

@end
