//
//  PPSURLRequestSerialization.h
//  Pods
//
//  Created by ppsheep on 2017/7/4.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PPSURLRequestSerialization : NSObject

@property (nonatomic, assign) NSTimeInterval timeoutInterval; //过期时间

@property (readonly, nonatomic, strong) NSDictionary <NSString *, NSString *> *HTTPRequestHeaders;//request header


+ (instancetype)serializer;


/**
 返回请求的request

 @param method 请求方法
 @param URLString 请求地址
 @param parameters 参数
 @param error 错误
 @return request
 */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(nullable id)parameters
                                     error:(NSError * _Nullable __autoreleasing *)error;


/**
 设置请求头

 @param value 值
 @param field key
 */
- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(NSString *)field;


/**
 根据key查找header

 @param field key
 @return value
 */
- (nullable NSString *)valueForHTTPHeaderField:(NSString *)field;


@end

NS_ASSUME_NONNULL_END
