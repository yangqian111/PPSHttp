//
//  PPSURLRequestSerialization.m
//  Pods
//
//  Created by ppsheep on 2017/7/4.
//
//

#import "PPSURLRequestSerialization.h"


/**
 这里是为了处理保留字段，因为除了? 其他的保留字段，比如/ ，等等，如果需要当做查询字段，都需要通过百分号转义
 这段代码是通过阅读AFNetworking源码，借鉴过来的，感谢开源
 @param string 需要处理的转义字符串
 @return 处理过后的转义字符串
 */
static NSString * PPSPercentEscapedStringFromString(NSString *string) {
    static NSString * const kLYCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kLYCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kLYCharactersGeneralDelimitersToEncode stringByAppendingString:kLYCharactersSubDelimitersToEncode]];
    
    static NSUInteger const batchSize = 50;
    
    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;
    
    while (index < string.length) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wgnu"
        NSUInteger length = MIN(string.length - index, batchSize);
#pragma GCC diagnostic pop
        NSRange range = NSMakeRange(index, length);
        
        range = [string rangeOfComposedCharacterSequencesForRange:range];
        
        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];
        
        index += range.length;
    }
    
    return escaped;
}



/**
 本类是为了方便处理查询字段的key和value，做出的一个model类
 */
@interface PPSQueryStringPair : NSObject

@property (readwrite, nonatomic, strong) id  value;
@property (readwrite, nonatomic, strong) id  field;

@end

@implementation PPSQueryStringPair

- (id)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.field = field;
    self.value = value;
    
    return self;
}

- (NSString *)URLEncodedStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return PPSPercentEscapedStringFromString([self.field description]);
    } else {
        return [NSString stringWithFormat:@"%@=%@", PPSPercentEscapedStringFromString([self.field description]), PPSPercentEscapedStringFromString([self.value description])];
    }
}
@end

#pragma mark - 这里为了处理get请求的参数，做出的几个常量，用来拼接get请求参数

FOUNDATION_EXPORT NSArray * PPSQueryStringPairsFromDictionary(NSDictionary *dictionary);
FOUNDATION_EXPORT NSArray * PPSQueryStringPairsFromKeyAndValue(NSString *key, id value);
FOUNDATION_EXPORT NSString * PPSQueryStringFromParameters(NSDictionary *parameters);

NSString *PPSQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (PPSQueryStringPair *pair in PPSQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValue]];
    }
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * PPSQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return PPSQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * PPSQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:PPSQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:PPSQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:PPSQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[PPSQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}


@interface PPSURLRequestSerialization()

@property (readwrite, nonatomic, strong) NSMutableDictionary *mutableHTTPRequestHeaders;
@property (readwrite, nonatomic, strong) dispatch_queue_t requestHeaderModificationQueue;

@end

@implementation PPSURLRequestSerialization

+ (instancetype)serializer {
    return [[PPSURLRequestSerialization alloc] init];
}


- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.mutableHTTPRequestHeaders = [NSMutableDictionary dictionary];
    self.requestHeaderModificationQueue = dispatch_queue_create("requestHeaderModificationQueue", DISPATCH_QUEUE_CONCURRENT);
    
    //设置默认的header
    // Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
    NSMutableArray *acceptLanguagesComponents = [NSMutableArray array];
    [[NSLocale preferredLanguages] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        float q = 1.0f - (idx * 0.1f);
        [acceptLanguagesComponents addObject:[NSString stringWithFormat:@"%@;q=%0.1g", obj, q]];
        *stop = q <= 0.5f;
    }];
    [self setValue:[acceptLanguagesComponents componentsJoinedByString:@", "] forHTTPHeaderField:@"Accept-Language"];
    
    NSString *userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
    
    if (userAgent) {
        if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            NSMutableString *mutableUserAgent = [userAgent mutableCopy];
            if (CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false)) {
                userAgent = mutableUserAgent;
            }
        }
        [self setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    //默认支持json格式
    [self setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    return self;
}

//这里使用同步队列取header 是为了取到完整的header
-(void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    dispatch_barrier_async(self.requestHeaderModificationQueue, ^{
        [self.mutableHTTPRequestHeaders setValue:value forKey:field];
    });
}

- (NSString *)valueForHTTPHeaderField:(NSString *)field {
    NSString __block *value;
    dispatch_sync(self.requestHeaderModificationQueue, ^{
        value = [self.mutableHTTPRequestHeaders valueForKey:field];
    });
    return value;
}

- (NSDictionary<NSString *,NSString *> *)HTTPRequestHeaders {
    NSDictionary __block *value;
    dispatch_sync(self.requestHeaderModificationQueue, ^{
        value = [NSDictionary dictionaryWithDictionary:self.mutableHTTPRequestHeaders];
    });
    return value;
}

#pragma mark - 如果是get方法  则拼接字符串放上去  如果是post则直接设置httpbody 暂时就用到这两种方法，后续有了其他方法  再增加
-(NSMutableURLRequest *)requestWithMethod:(NSString *)method URLString:(NSString *)URLString parameters:(id)parameters error:(NSError * _Nullable __autoreleasing *)error {
    
    NSParameterAssert(method);
    NSParameterAssert(URLString);
    
    NSMutableURLRequest *request = nil;
    
    if ([method isEqualToString:@"GET"]) {
        NSString *queryString = PPSQueryStringFromParameters(parameters);
        NSString *queryURL = [NSString stringWithFormat:@"%@?%@",URLString,queryString];
        NSURL *URL = [NSURL URLWithString:queryURL];
        request = [NSMutableURLRequest requestWithURL:URL];
        
    } else if ([method isEqualToString:@"POST"]) {
        NSURL *url = [NSURL URLWithString:URLString];
        request = [NSMutableURLRequest requestWithURL:url];
        NSData *data = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:error];
        [request setHTTPBody:data];
    }
    request.HTTPMethod = method;
    [request setValue:@"85081a6759d44c658f57e8bea484b1fd" forHTTPHeaderField:@"token"];
    
    
    return request;
}

@end
