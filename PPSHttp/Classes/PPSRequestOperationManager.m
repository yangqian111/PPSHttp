//
//  PPSRequestOperationManager.m
//  Pods
//
//  Created by ppsheep on 2017/7/4.
//
//

#import "PPSRequestOperationManager.h"
#import "PPSURLRequestSerialization.h"

@interface PPSRequestOperationManager()<NSURLSessionDataDelegate>

@property(nonatomic, strong) NSString *URL;
@property(nonatomic, strong) NSString *method;
@property(nonatomic, strong) NSDictionary *parameters;
@property(nonatomic, strong) NSMutableURLRequest *request;
@property(nonatomic, strong) NSURLSessionDataTask *task;



@property (nonatomic, strong) NSOperationQueue *queue;
@property(nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) PPSURLRequestSerialization *serializer;

@end

@implementation PPSRequestOperationManager

+ (instancetype)manager {
    static dispatch_once_t onceToken;
    static PPSRequestOperationManager *__manager = nil;
    dispatch_once(&onceToken, ^{
        __manager = [[PPSRequestOperationManager alloc] init];
    });
    return __manager;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _queue = [[NSOperationQueue alloc] init];
    _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:_queue];
    _serializer = [PPSURLRequestSerialization serializer];
    
    return self;
}

- (NSURLSessionDataTask *)method:(NSString *)method URL:(NSString *)URL parameters:(id)parameters success:(void (^)(NSData * _Nullable, NSURLResponse * _Nullable))success failure:(void (^)(NSError * _Nullable))failure {
    NSError *error = nil;
    NSURLRequest *request = [self.serializer requestWithMethod:method URLString:URL parameters:parameters error: &error];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success(data,response);
            }
        }
    }];
    return task;
}


#pragma mark - delegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {

    // 判断服务器返回的证书是否是服务器信任的
    __block NSURLCredential *credential = nil;
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        if (credential)
        {
            disposition = NSURLSessionAuthChallengeUseCredential; // 使用证书
        }
        else
        {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling; // 忽略证书 默认的做法
        }
    }
    else
    {
        disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge; // 取消请求,忽略证书
    }
    if (completionHandler)// 安装证书
    {
        completionHandler(disposition, credential);
    }
}



@end
