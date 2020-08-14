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
+ (BOOL)configCacheFolder:(NSString *)pURL {
    /// 先判断目录是否存在
    if ([self configJudgeFolderExists:pURL]) {
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
+ (BOOL)configDataToFile:(NSString *)pURL data:(NSData *)data {
    return [[NSFileManager defaultManager] createFileAtPath:pURL contents:data attributes:nil];
}

/**
 *  @brief 读取数据并返回
 *
 *  @param pURL 文件路径
 */
+ (NSData *)configDataForFile:(NSString *)pURL {
    return [[NSFileManager defaultManager] contentsAtPath:pURL];
}

/**
 *  @brief 获取指定文件路径缓存总大小/bytes
 */
+ (CGFloat)bytesTotalCache:(NSString *)pURL {
    unsigned long long bytes = 0;
    /// 首先判断文件夹是否存在，文件夹是否为空
    if ([self configJudgeFolderExists:pURL] && ![self configJudgeFolderEmpty:pURL]) {
        NSError *error = nil;
        NSArray *arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pURL error:&error];
        if (!error) {
            for (NSString *p in arr) {
                NSString *URL = [pURL stringByAppendingPathComponent:p];
                NSDictionary *data = [[NSFileManager defaultManager] attributesOfItemAtPath:URL error:&error];

                if (!error) {
                    bytes += [data[NSFileSize] unsignedIntegerValue];
                }
            }
        }
    }
    return bytes / (1000.0 * 1000.0);
}

/**
 *  @brief 判断文件夹是否存在
 */
+ (BOOL)configJudgeFolderExists:(NSString *)pURL {
    return [[NSFileManager defaultManager] fileExistsAtPath:pURL];
}

/**
 *  @brief 判断文件夹是否为空 YES 为空文件夹
 */
+ (BOOL)configJudgeFolderEmpty:(NSString *)pURL {
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
+ (void)configEmptyCache:(NSString *)pURL {
    if ([self configJudgeFolderExists:pURL]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:pURL error:&error];
        if (!error) {
            AppLog(@"🍀 清空缓存成功");
        } else {
            AppLog(@"⚠️ 清空缓存失败 Error：%@", error.localizedDescription);
        }
    }
}

@end
