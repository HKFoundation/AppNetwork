//
//  AppLogFormat.m
//  AppNetwork
//
//  Created by Code on 2020/8/11.
//  Copyright © 2020 北京卡友在线科技有限公司. All rights reserved.
// 

#import <Foundation/Foundation.h>

/* ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*
 * // MARK: 本类主要用于为格式化控制台 Unicode 字符
 * ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*/

@interface AppLogFormat : NSObject

@end

@implementation AppLogFormat

+ (NSString *)configAppLogFormat:(NSString *)format {
    NSString *p_1 = [format stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    NSString *p_2 = [p_1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *p_3 = [[@"\"" stringByAppendingString:p_2] stringByAppendingString:@"\""];
    NSData *dataLog = [p_3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString *debugLog = [NSPropertyListSerialization propertyListWithData:dataLog options:NSPropertyListImmutable format:NULL error:NULL];
    return debugLog;
}

@end

@implementation NSDictionary (DebugLog)

- (NSString *)descriptionWithLocale:(nullable id)locale {

    if (![self count]) {
        return @"";
    }
    return [AppLogFormat configAppLogFormat:[self description]];
}

@end

@implementation NSArray (DebugLog)

- (NSString *)descriptionWithLocale:(nullable id)locale {

    if (![self count]) {
        return @"";
    }
    return [AppLogFormat configAppLogFormat:[self description]];
}

@end
