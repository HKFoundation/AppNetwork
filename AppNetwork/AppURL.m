//
//  AppURL.m
//  AppNetwork
//
//  Created by Code on 2020/8/19.
//  Copyright © 2020 北京卡友在线科技有限公司. All rights reserved.
//

#import "AppURL.h"

@implementation AppURL

+ (NSString *)baseURL:(NSString *)pURL {
#if DEBUG
    return [self debugURL:pURL];
#else
    return [self appURL:pURL];
#endif
}

/// 测试库接口域名
+ (NSString *)debugURL:(NSString *)pURL {
    /// 用于判断接口地址属于哪个域名
    NSSet *domain_1 = [NSSet setWithArray:@[]];
    if ([domain_1 containsObject:pURL]) {
        return @"";
    }
    return @"";
}

/// 正式库接口域名
+ (NSString *)appURL:(NSString *)pURL {
    /// 用于判断接口地址属于哪个域名
    NSSet *domain_1 = [NSSet setWithArray:@[]];
    if ([domain_1 containsObject:pURL]) {
        return @"";
    }
    return @"";
}

@end
