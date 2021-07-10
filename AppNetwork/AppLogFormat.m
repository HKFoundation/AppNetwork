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

@end

@implementation NSDictionary (DebugLog)

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level {
    NSMutableString *debugLog = [NSMutableString string];
    NSMutableString *p = [[NSMutableString alloc] initWithCapacity:level];
    for (NSUInteger index = 0; index < level; ++index) {
        [p appendString:@"\t"];
    }

    NSString *p_1 = @"";
    if (level > 0) {
        p_1 = p;
    }

    [debugLog appendString:@"{\n"];

    for (id key in self.allKeys) {
        id obj = [self objectForKey:key];

        if ([obj isKindOfClass:[NSString class]]) {
            [debugLog appendFormat:@"%@\t%@ = \"%@\",\n", p_1, key, obj];
        } else if ([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSSet class]]) {
            [debugLog appendFormat:@"%@\t%@ = %@,\n", p_1, key, [obj descriptionWithLocale:locale indent:level + 1]];
        } else if ([obj isKindOfClass:[NSData class]]) {
            NSError *error = nil;
            NSObject *format =  [NSJSONSerialization JSONObjectWithData:obj options:NSJSONReadingMutableContainers error:&error];

            if (error == nil && format != nil) {
                if ([format isKindOfClass:[NSDictionary class]] || [format isKindOfClass:[NSArray class]] || [format isKindOfClass:[NSSet class]]) {
                    NSString *temp = [((NSDictionary *)format) descriptionWithLocale:locale indent:level + 1];
                    [debugLog appendFormat:@"%@\t%@ = %@,\n", p_1, key, temp];
                } else if ([obj isKindOfClass:[NSString class]]) {
                    [debugLog appendFormat:@"%@\t%@ = \"%@\",\n", p_1, key, format];
                }
            } else {
                @try {
                    NSString *temp = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
                    if (temp != nil) {
                        [debugLog appendFormat:@"%@\t%@ = \"%@\",\n", p_1, key, temp];
                    } else {
                        [debugLog appendFormat:@"%@\t%@ = %@,\n", p_1, key, obj];
                    }
                } @catch (NSException *exception) {
                    [debugLog appendFormat:@"%@\t%@ = %@,\n", p_1, key, obj];
                }
            }
        } else {
            [debugLog appendFormat:@"%@\t%@ = %@,\n", p_1, key, obj];
        }
    }

    [debugLog appendFormat:@"%@}", p_1];

    return debugLog;
}

@end

@implementation NSArray (DebugLog)

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level {
    NSMutableString *debugLog = [NSMutableString string];
    NSMutableString *p = [[NSMutableString alloc] initWithCapacity:level];
    for (NSUInteger index = 0; index < level; ++index) {
        [p appendString:@"\t"];
    }

    NSString *p_1 = @"";
    if (level > 0) {
        p_1 = p;
    }
    [debugLog appendString:@"(\n"];

    for (id obj in self) {
        if ([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSSet class]]) {
            NSString *temp = [((NSDictionary *)obj) descriptionWithLocale:locale indent:level + 1];
            [debugLog appendFormat:@"%@\t%@,\n", p_1, temp];
        } else if ([obj isKindOfClass:[NSString class]]) {
            [debugLog appendFormat:@"%@\t\"%@\",\n", p_1, obj];
        } else if ([obj isKindOfClass:[NSData class]]) {
            NSError *error = nil;
            NSObject *format =  [NSJSONSerialization JSONObjectWithData:obj options:NSJSONReadingMutableContainers error:&error];

            if (error == nil && format != nil) {
                if ([format isKindOfClass:[NSDictionary class]] || [format isKindOfClass:[NSArray class]] || [format isKindOfClass:[NSSet class]]) {
                    NSString *temp = [((NSDictionary *)format) descriptionWithLocale:locale indent:level + 1];
                    [debugLog appendFormat:@"%@\t%@,\n", p_1, temp];
                } else if ([obj isKindOfClass:[NSString class]]) {
                    [debugLog appendFormat:@"%@\t\"%@\",\n", p_1, format];
                }
            } else {
                @try {
                    NSString *temp = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
                    if (temp != nil) {
                        [debugLog appendFormat:@"%@\t\"%@\",\n", p_1, temp];
                    } else {
                        [debugLog appendFormat:@"%@\t%@,\n", p_1, obj];
                    }
                } @catch (NSException *exception) {
                    [debugLog appendFormat:@"%@\t%@,\n", p_1, obj];
                }
            }
        } else {
            [debugLog appendFormat:@"%@\t%@,\n", p_1, obj];
        }
    }

    [debugLog appendFormat:@"%@)", p_1];

    return debugLog;
}

@end

@implementation NSSet (DebugLog)

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level {
    NSMutableString *debugLog = [NSMutableString string];
    NSMutableString *p = [[NSMutableString alloc] initWithCapacity:level];
    for (NSUInteger i = 0; i < level; ++i) {
        [p appendString:@"\t"];
    }

    NSString *p_1 = @"";
    if (level > 0) {
        p_1 = p;
    }
    [debugLog appendString:@"{(\n"];

    for (id obj in self) {
        if ([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSSet class]]) {
            NSString *temp = [((NSDictionary *)obj) descriptionWithLocale:locale indent:level + 1];
            [debugLog appendFormat:@"%@\t%@,\n", p_1, temp];
        } else if ([obj isKindOfClass:[NSString class]]) {
            [debugLog appendFormat:@"%@\t\"%@\",\n", p_1, obj];
        } else if ([obj isKindOfClass:[NSData class]]) {
            NSError *error = nil;
            NSObject *format =  [NSJSONSerialization JSONObjectWithData:obj options:NSJSONReadingMutableContainers error:&error];

            if (error == nil && format != nil) {
                if ([format isKindOfClass:[NSDictionary class]] || [format isKindOfClass:[NSArray class]] || [format isKindOfClass:[NSSet class]]) {
                    NSString *temp = [((NSDictionary *)format) descriptionWithLocale:locale indent:level + 1];
                    [debugLog appendFormat:@"%@\t%@,\n", p_1, temp];
                } else if ([obj isKindOfClass:[NSString class]]) {
                    [debugLog appendFormat:@"%@\t\"%@\",\n", p_1, format];
                }
            } else {
                @try {
                    NSString *temp = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
                    if (temp != nil) {
                        [debugLog appendFormat:@"%@\t\"%@\",\n", p_1, temp];
                    } else {
                        [debugLog appendFormat:@"%@\t%@,\n", p_1, obj];
                    }
                } @catch (NSException *exception) {
                    [debugLog appendFormat:@"%@\t%@,\n", p_1, obj];
                }
            }
        } else {
            [debugLog appendFormat:@"%@\t%@,\n", p_1, obj];
        }
    }

    [debugLog appendFormat:@"%@)}", p_1];

    return debugLog;
}

@end
