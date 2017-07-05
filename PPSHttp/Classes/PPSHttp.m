//
//  PPSHttp.m
//  Pods
//
//  Created by ppsheep on 2017/7/4.
//
//

#import "PPSHttp.h"
#import "PPSRequestOperationManager.h"

@implementation PPSHttp

+(void)GET:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSData * _Nullable, NSURLResponse * _Nullable))success failure:(void (^)(NSError * _Nullable))failure {
    NSURLSessionDataTask *task = [[PPSRequestOperationManager manager] method:@"GET" URL:URLString parameters:nil success:success failure:failure];
    [task resume];
}

+ (void)POST:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSData * _Nullable, NSURLResponse * _Nullable))success failure:(void (^)(NSError * _Nullable))failure {
    NSURLSessionDataTask *task = [[PPSRequestOperationManager manager] method:@"POST" URL:URLString parameters:parameters success:success failure:failure];
    [task resume];
}

@end
