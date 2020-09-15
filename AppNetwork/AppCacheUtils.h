   //
//  AppCacheUtils.h
//  AppNetwork
//
//  Created by Code on 2017/4/2.
//  Copyright © 2020 北京卡友在线科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppCacheUtils : NSObject

/**
 *  @brief 设置缓存数据的目录，默认路径 Documents/AppNetwork，"Documents" 为系统中的文件夹
 *
 *  @param pURL Documents/路径名称
 */
+ (void)configCacheURL:(NSString *)pURL;

/**
 *  @brief 获取缓存数据的目录
 */
+ (NSString *)cacheURL;

/**
 *  @brief 判断文件夹目录是否存在，如果不存在会自动生成对应目录文件夹
 */
+ (BOOL)configCacheFolder:(NSString *)pURL;

/**
 *  @brief 生成文件并存储
 *
 *  @param pURL 文件路径
 *  @param data 需要保存的数据
 */
+ (BOOL)configFileToSaveLocal:(NSString *)pURL data:(NSData *)data;

/**
 *  @brief 读取数据并返回
 *
 *  @param pURL 文件路径
 */
+ (NSData *)configFileForLocal:(NSString *)pURL;

/**
 *  @brief 获取指定文件夹路径缓存总大小/MB
 */
+ (CGFloat)bytesTotalCache:(NSString *)pURL;

/**
 *  @brief 判断文件夹是否存在
 */
+ (BOOL)configJudgeFolderExists:(NSString *)pURL;

/**
 *  @brief 判断文件夹是否为空
 */
+ (BOOL)configJudgeFolderEmpty:(NSString *)pURL;

/**
 *  @brief 清空指定文件路径网络数据缓存
 */
+ (void)configEmptyCache:(NSString *)pURL debugLog:(nullable NSString *)debugLog;

@end

NS_ASSUME_NONNULL_END
