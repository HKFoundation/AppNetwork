//
//  AppNetwork.h
//  AppNetwork
//
//  Created by Code on 2017/4/2.
//  Copyright © 2020 北京卡友在线科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  @author 刘森, 2017-04-02 17:04:34
 *
 *  @brief 日志输出
 */
#define _TIME_ [[NSString stringWithFormat:@"%@", [[NSDate date] dateByAddingTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMTForDate:[NSDate date]]]] UTF8String]

#ifdef DEBUG
#define AppLog(k, ...) printf("🇺🇳 %s [%s %03d] - [message: %s]\n", _TIME_, [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:(k), ##__VA_ARGS__] UTF8String]);
#else
#define AppLog(k, ...)
#endif

/**
 *  @brief 进度加载
 *
 *  @param bytesLoad  已加载的进度
 *  @param bytesTotal 总进度的大小
 */
typedef void (^_Nullable AppTaskProgress)(int64_t bytesLoad, int64_t bytesTotal);

typedef NS_ENUM(NSInteger, App_NET_STATE_TYPE) {
    App_NET_STATE_TYPE_UNKONWN = -1,      /**< 未知网络 */
    App_NET_STATE_TYPE_NOTCONNECTED = 0,  /**< 网络无连接 */
    App_NET_STATE_TYPE_CONNECTEDWWAN = 1, /**< 2，3，4G网络 */
    App_NET_STATE_TYPE_CONNECTEDWIFI = 2  /**< WiFi网络 */
};

@class NSURLSessionTask;

typedef NSURLSessionTask AppURLSessionTask;
typedef void (^AppTaskDone)(id done);
typedef void (^AppTaskError)(NSError *error);

@interface AppNetwork : NSObject

/* ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*
 * // MARK: 网络基础配置
 * ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*/

/**
 *  @brief 用于判断当前网络状态
 */
+ (void)configNetworkType:(void (^)(App_NET_STATE_TYPE done))done;

/**
 *  @brief 用于指定网络请求接口的基础URL
 *
 *  @param pURL 网络接口的基础URL
 */
+ (void)configBaseURL:(NSString *)pURL;
+ (NSString *)baseURL:(NSString *)pURL;

/**
 *  @brief 用于设置请求超时时间，默认为 60 秒
 *
 *  @param pTimed 超时时间
 */
+ (void)configLoadTimed:(NSTimeInterval)pTimed;

/**
 *  @brief 获取缓存总大小/MB
 *
 *  @return 缓存大小
 */
+ (CGFloat)bytesTotalCache;

/**
 *  @brief 默认不会自动清除缓存，当指定上限达到时则尝试自动清除缓存
 *
 *  @param MB 缓存上限大小，单位为MB，默认为 0MB，表示不清理
 */
+ (void)configCacheLimitedToMB:(CGFloat)MB;

/**
 *  @brief 清除所有缓存
 */
+ (void)configEmptyCache;

/**
 *  @brief 清除已下载文件
 */
+ (void)configEmptyCache:(NSString *)pURL params:(NSDictionary *)params;

/**
 *  @brief 取消所有请求
 */
+ (void)breakTask;

/**
 *  @brief 取消某个请求
 *
 *  @param pURL 可以是绝对路径，也可以是相对路径（不包含baseURL）
 */
+ (void)breakTaskURL:(NSString *)pURL;

/**
 *  @brief 配置公共请求头
 *
 *  @param header 与服务器商定的参数
 */
+ (void)configHeader:(NSDictionary *)header;

/* ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*
 * // MARK: 接口请求业务
 * ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*/
/**
 *  @brief GET请求接口
 *
 *  @param pURL     接口地址
 *  @param appDone  接口请求完成回调
 *  @param appError 接口请求出错回调
 *
 *  @return 返回请求对象
 */
+ (AppURLSessionTask *)reqForGet:(NSString *)pURL
                         appDone:(AppTaskDone)appDone
                        appError:(AppTaskError)appError;

/**
 *  @brief 增加接口数据缓存
 */
+ (AppURLSessionTask *)reqForGet:(NSString *)pURL
                           cache:(BOOL)cache
                         appDone:(AppTaskDone)appDone
                        appError:(AppTaskError)appError;

/**
 *  @brief 增加接口请求参数
 */
+ (AppURLSessionTask *)reqForGet:(NSString *)pURL
                          params:(NSDictionary *)params
                         appDone:(AppTaskDone)appDone
                        appError:(AppTaskError)appError;

/**
 *  @brief 增加接口数据缓存
 */
+ (AppURLSessionTask *)reqForGet:(NSString *)pURL
                          params:(NSDictionary *)params
                           cache:(BOOL)cache
                         appDone:(AppTaskDone)appDone
                        appError:(AppTaskError)appError;

/**
 *  @brief 增加接口请求进度
 */
+ (AppURLSessionTask *)reqForGet:(NSString *)pURL
                          params:(NSDictionary *)params
                           cache:(BOOL)cache
                        progress:(AppTaskProgress)progress
                         appDone:(AppTaskDone)appDone
                        appError:(AppTaskError)appError;

/**
 *  @brief POST请求接口
 *
 *  @param pURL     接口地址
 *  @param appDone  接口请求完成回调
 *  @param appError 接口请求出错回调
 *
 *  @return 返回请求对象
 */
+ (AppURLSessionTask *)reqForForm:(NSString *)pURL
                          appDone:(AppTaskDone)appDone
                         appError:(AppTaskError)appError;

/**
 *  @brief 增加接口数据缓存
 */
+ (AppURLSessionTask *)reqForForm:(NSString *)pURL
                            cache:(BOOL)cache
                          appDone:(AppTaskDone)appDone
                         appError:(AppTaskError)appError;

/**
*  @brief 增加接口请求参数
*/
+ (AppURLSessionTask *)reqForForm:(NSString *)pURL
                           params:(NSDictionary *)params
                          appDone:(AppTaskDone)appDone
                         appError:(AppTaskError)appError;

/**
 *  @brief 增加接口数据缓存
 */
+ (AppURLSessionTask *)reqForForm:(NSString *)pURL
                           params:(NSDictionary *)params
                            cache:(BOOL)cache
                          appDone:(AppTaskDone)appDone
                         appError:(AppTaskError)appError;

/**
 *  @brief 增加接口请求进度
 */
+ (AppURLSessionTask *)reqForForm:(NSString *)pURL
                           params:(NSDictionary *)params
                            cache:(BOOL)cache
                         progress:(AppTaskProgress)progress
                          appDone:(AppTaskDone)appDone
                         appError:(AppTaskError)appError;

/**
 *  @brief 用于头像等图片上传
 *
 *  @param pURL     接口地址
 *  @param image    需要上传的图片
 *  @param name     图片上传的请求参数名，由后端接口的人指定
 *  @param mode     大多情况下传 image/jpeg，可以自定义
 *  @param params   请求参数
 *  @param progress 上传进度
 *  @param appDone  接口请求完成回调
 *  @param appError 接口请求出错回调
 *
 *  @return 返回请求对象
 */
+ (AppURLSessionTask *)reqForUploadImage:(NSString *)pURL
                                   image:(UIImage *)image
                                    name:(NSString *)name
                                    mode:(NSString *)mode
                                  params:(NSDictionary *)params
                                progress:(AppTaskProgress)progress
                                 appDone:(AppTaskDone)appDone
                                appError:(AppTaskError)appError;

/**
 *  @brief 文件下载请求接口
 *
 *  @param pURL     接口地址
 *  @param params   请求参数
 *  @param progress 下载进度
 *  @param appDone  接口请求完成回调
 *  @param appError 接口请求出错回调
 *
 *  @return 返回请求对象
 */
+ (AppURLSessionTask *)reqForDownload:(NSString *)pURL
                               params:(NSDictionary *)params
                             progress:(AppTaskProgress)progress
                              appDone:(AppTaskDone)appDone
                             appError:(AppTaskError)appError;

@end

NS_ASSUME_NONNULL_END
