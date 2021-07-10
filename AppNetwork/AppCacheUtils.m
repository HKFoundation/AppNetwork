//
//  AppCacheUtils.m
//  AppNetwork
//
//  Created by Code on 2017/4/2.
//  Copyright © 2020 北京卡友在线科技有限公司. All rights reserved.
//

#import "AppCacheUtils.h"
#import "AppNetwork.h"

static NSString *app_cache = @"Documents/AppNetwork";

@implementation AppCacheUtils

/**
 *  @brief 设置缓存数据的目录，默认路径 Documents/AppNetwork，"Documents" 为系统中的文件夹
 *
 *  @param pURL Documents/路径名称
 */
+ (void)configCacheURL:(NSString *)pURL {
    app_cache = pURL;
}

/**
 *  @brief 获取缓存数据的目录
 */
+ (NSString *)cacheURL {
    return [NSHomeDirectory() stringByAppendingPathComponent:app_cache];
}

/**
 *  @brief 判断文件夹目录是否存在，如果不存在会自动生成对应目录文件夹
 */
+ (BOOL)configNewDocument:(NSString *)pURL {
    /// 先判断目录是否存在
    if ([self configDocumentExists:pURL]) {
        return YES;
    }

    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:pURL withIntermediateDirectories:YES attributes:nil error:&error];
    if (!error) {
        AppLog(@"🍀 缓存目录新建成功");
        return YES;
    } else {
        AppLog(@"⚠️ 缓存目录新建失败 Error：%@", error.localizedDescription);
        return NO;
    }
}

/**
 *  @brief 生成文件并存储
 *
 *  @param pURL 文件路径
 *  @param data 需要保存的数据
 */
+ (BOOL)configContentSaveLocal:(NSString *)pURL data:(NSData *)data {
    return [[NSFileManager defaultManager] createFileAtPath:pURL contents:data attributes:nil];
}

/**
 *  @brief 读取数据并返回
 *
 *  @param pURL 文件路径
 */
+ (NSData *)configContentLocal:(NSString *)pURL {
    return [[NSFileManager defaultManager] contentsAtPath:pURL];
}

/**
 *  @brief 获取指定文件夹路径缓存总大小/MB
 */
+ (CGFloat)bytesTotalCache:(NSString *)pURL {
    unsigned long long bytes = 0;
    /// 首先判断文件夹是否存在，文件夹是否为空
    if ([self configDocumentExists:pURL] && ![self configDocumentrEmpty:pURL]) {
        NSError *error = nil;
        NSArray *arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pURL error:&error];
        if (!error) { /// 获取此文件夹下所有目录结构返回大小
            for (NSString *p in arr) {
                error = nil;
                NSString *URL = [pURL stringByAppendingPathComponent:p];
                NSDictionary *data = [[NSFileManager defaultManager] attributesOfItemAtPath:URL error:&error];

                if (!error) {
                    bytes += [data[NSFileSize] unsignedIntegerValue];
                }
            }
        } else { /// 如果获取不到文件夹，则按照文件大小获取
            error = nil;
            NSDictionary *data = [[NSFileManager defaultManager] attributesOfItemAtPath:pURL error:&error];

            if (!error) {
                bytes += [data[NSFileSize] unsignedIntegerValue];
            }
        }
    }
    return bytes / (1000.0 * 1000.0);
}

/**
 *  @brief 判断文件夹是否存在
 */
+ (BOOL)configDocumentExists:(NSString *)pURL {
    return [[NSFileManager defaultManager] fileExistsAtPath:pURL];
}

/**
 *  @brief 判断文件夹是否为空 YES 为空文件夹
 */
+ (BOOL)configDocumentrEmpty:(NSString *)pURL {
    NSError *error = nil;
    NSArray *arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pURL error:&error];
    if (!error && arr.count == 0) {
        return YES;
    }
    return NO;
}

/**
 *  @brief 清空指定文件路径网络数据缓存
 */
+ (void)configEmptyCache:(NSString *)pURL debugLog:(nullable NSString *)debugLog {
    if ([self configDocumentExists:pURL]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:pURL error:&error];
        if (!error) {
            AppLog(@"%@", !debugLog ? @"🍀 清空缓存成功" : [NSString stringWithFormat:@"🍀 %@ 文件删除成功", debugLog]);
        } else {
            AppLog(@"%@ Error：%@", !debugLog ? @"⚠️ 清空缓存失败" : [NSString stringWithFormat:@"⚠️ %@ 文件删除失败", debugLog], error.localizedDescription);
        }
    }
}

@end
