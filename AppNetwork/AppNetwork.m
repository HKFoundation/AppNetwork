//
//  AppNetwork.m
//  AppNetwork
//
//  Created by Code on 2017/4/2.
//  Copyright © 2020 北京卡友在线科技有限公司. All rights reserved.
//

#import "AppNetwork.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "AppCacheUtils.h"
#import <CommonCrypto/CommonDigest.h>
#import "AppError.h"
#import "AppURL.h"

static NSString *app_baseURL = nil;             /**< 接口基础地址 */
static CGFloat app_MB;                          /**< 设置的最大缓存空间 */
static NSTimeInterval app_pTimed = 30.f;        /**< 请求超时时间 */
static AFHTTPSessionManager *app_manager = nil; /**< AFHTTPSessionManager实例对象 */
static NSDictionary *app_header = nil;          /**< 设置请求头部参数 */
static NSMutableArray *app_Tasks;               /**< 请求集合 */

@interface NSString (md5)

+ (NSString *)app_md5:(NSString *)md5;

@end

@implementation NSString (md5)

+ (NSString *)app_md5:(NSString *)md5 {
    if (!md5 || md5.length == 0) {
        return nil;
    }

    unsigned char data[CC_MD5_DIGEST_LENGTH];
    CC_MD5([md5 UTF8String], (CC_LONG)[md5 lengthOfBytesUsingEncoding:NSUTF8StringEncoding], data);
    NSMutableString *app_md5 = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH];

    for (NSInteger index = 0; index < CC_MD5_DIGEST_LENGTH; index++) {
        [app_md5 appendFormat:@"%02X", data[index]];
    }
    return app_md5;
}

@end

@implementation AppNetwork

/* ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*
 * // MARK: 网络基础配置
 * ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*/

/**
 *  @brief 如果缓存达到设置上限即自动清空，前提是设置了最大缓存控件，否则该方法无效
 */
+ (void)load {
    static dispatch_once_t pToken;
    dispatch_once(&pToken, ^{
        if (app_MB > 0 && [self bytesTotalCache] > app_MB) {
            [self configEmptyCache];
        }
    });
}

+ (void)configBaseURL:(NSString *)pURL {
    app_baseURL = pURL;
}

+ (NSString *)baseURL:(NSString *)pURL {
    return [AppURL baseURL:pURL];
}

/**
 *  @brief 用于设置请求超时时间，默认为 60 秒
 *
 *  @param pTimed 超时时间
 */
+ (void)configLoadTimed:(NSTimeInterval)pTimed {
    app_pTimed = pTimed;
}

/**
 *  @brief 获取缓存总大小/MB
 *
 *  @return 缓存大小
 */
+ (CGFloat)bytesTotalCache {
    return [AppCacheUtils bytesTotalCache:[AppCacheUtils cacheURL]];
}

/**
 *  @brief 默认不会自动清除缓存，当指定上限达到时则尝试自动清除缓存
 *
 *  @param MB 缓存上限大小，单位为MB，默认为 0MB，表示不清理
 */
+ (void)configCacheLimitedToMB:(CGFloat)MB {
    app_MB = MB;
}

/**
 *  @brief 清除缓存
 */
+ (void)configEmptyCache {
    [AppCacheUtils configEmptyCache:[AppCacheUtils cacheURL]];
}

/**
 *  @brief 清除已下载文件
 */
+ (void)configEmptyCache:(NSString *)pURL params:(NSDictionary *)params {
    NSString *formatURL = [self formatURL:pURL];
    NSString *md5CacheURL = [NSString app_md5:[self appendURL:formatURL params:params]];

    [[self dataTasks] enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([obj isKindOfClass:[NSDictionary class]] && [obj objectForKey:md5CacheURL]) {
            [self breakTaskURL:pURL];
            *stop = YES;
        }
    }];

    NSDictionary *cachedata = [self configDataForFile:md5CacheURL];
    NSString *cacheURL = [cachedata objectForKey:@"cacheURL"];
    if (cacheURL) {
        /// 如果已下载完成则清除
        [AppCacheUtils configEmptyCache:[[AppCacheUtils cacheURL] stringByAppendingPathComponent:[cacheURL componentsSeparatedByString:@"/"].lastObject]];
    }
    /// 清除当前文件的缓存文件
    [AppCacheUtils configEmptyCache:[[AppCacheUtils cacheURL] stringByAppendingPathComponent:md5CacheURL]];
}

/**
 *  @brief 当前的请求任务集合
 */
+ (NSMutableArray *)dataTasks {
    static dispatch_once_t pToken;
    dispatch_once(&pToken, ^{
        if (!app_Tasks) {
            app_Tasks = [[NSMutableArray alloc] init];
        }
    });
    return app_Tasks;
}

+ (void)breakTask {
    @synchronized(self) {
        [[self dataTasks] enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj isKindOfClass:[AppURLSessionTask class]]) {
                [obj cancel];
            } else if ([obj isKindOfClass:[NSDictionary class]]) {
                [[obj allValues][0] cancel];
            }
        }];
        [[self dataTasks] removeAllObjects];
    }
}

+ (void)breakTaskURL:(NSString *)pURL {
    if (!pURL || pURL.length == 0) {
        return;
    }
    @synchronized(self) {
        [[self dataTasks] enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            AppURLSessionTask *appTask = nil;
            if ([obj isKindOfClass:[AppURLSessionTask class]]) {
                appTask = obj;
            } else if ([obj isKindOfClass:[NSDictionary class]]) {
                appTask = [obj allValues][0];
            }

            if ([appTask.currentRequest.URL.absoluteString hasSuffix:pURL]) {
                [appTask cancel];
                [[self dataTasks] removeObject:obj];
                *stop = YES;
            }
        }];
    }
}

+ (void)configHeader:(NSDictionary *)header {
}

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
                        appError:(AppTaskError)appError {
    return [self reqForGet:pURL params:@{} appDone:appDone appError:appError];
}

/**
 *  @brief 增加接口数据缓存
 */
+ (AppURLSessionTask *)reqForGet:(NSString *)pURL
                           cache:(BOOL)cache
                         appDone:(AppTaskDone)appDone
                        appError:(AppTaskError)appError {
    return [self reqForGet:pURL params:@{} cache:cache progress:nil appDone:appDone appError:appError];
}

/**
 *  @brief 增加接口请求参数
 */
+ (AppURLSessionTask *)reqForGet:(NSString *)pURL
                          params:(NSDictionary *)params
                         appDone:(AppTaskDone)appDone
                        appError:(AppTaskError)appError {
    return [self reqForGet:pURL params:params cache:NO appDone:appDone appError:appError];
}

/**
 *  @brief 增加接口数据缓存
 */
+ (AppURLSessionTask *)reqForGet:(NSString *)pURL
                          params:(NSDictionary *)params
                           cache:(BOOL)cache
                         appDone:(AppTaskDone)appDone
                        appError:(AppTaskError)appError {
    return [self reqForGet:pURL params:params cache:cache progress:nil appDone:appDone appError:appError];
}

/**
 *  @brief 增加接口请求进度
 */
+ (AppURLSessionTask *)reqForGet:(NSString *)pURL
                          params:(NSDictionary *)params
                           cache:(BOOL)cache
                        progress:(AppTaskProgress)progress
                         appDone:(AppTaskDone)appDone
                        appError:(AppTaskError)appError {
    return [self reqForNetwork:pURL mode:@"GET" params:params cache:cache progress:progress appDone:appDone appError:appError];
}

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
                         appError:(AppTaskError)appError {
    return [self reqForForm:pURL params:@{} appDone:appDone appError:appError];
}

/**
 *  @brief 增加接口数据缓存
 */
+ (AppURLSessionTask *)reqForForm:(NSString *)pURL
                            cache:(BOOL)cache
                          appDone:(AppTaskDone)appDone
                         appError:(AppTaskError)appError {
    return [self reqForForm:pURL params:@{} cache:cache progress:nil appDone:appDone appError:appError];
}

/**
 *  @brief 增加接口请求参数
 */
+ (AppURLSessionTask *)reqForForm:(NSString *)pURL
                           params:(NSDictionary *)params
                          appDone:(AppTaskDone)appDone
                         appError:(AppTaskError)appError {
    return [self reqForForm:pURL params:params cache:NO appDone:appDone appError:appError];
}

/**
 *  @brief 增加接口数据缓存
 */
+ (AppURLSessionTask *)reqForForm:(NSString *)pURL
                           params:(NSDictionary *)params
                            cache:(BOOL)cache
                          appDone:(AppTaskDone)appDone
                         appError:(AppTaskError)appError {
    return [self reqForForm:pURL params:params cache:cache progress:nil appDone:appDone appError:appError];
}

/**
 *  @brief 增加接口请求进度
 */
+ (AppURLSessionTask *)reqForForm:(NSString *)pURL
                           params:(NSDictionary *)params
                            cache:(BOOL)cache
                         progress:(AppTaskProgress)progress
                          appDone:(AppTaskDone)appDone
                         appError:(AppTaskError)appError {
    return [self reqForNetwork:pURL mode:@"POST" params:params cache:cache progress:progress appDone:appDone appError:appError];
}

/* ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*
 * // MARK: 处理 GET 和 POST 请求方法
 * ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*/

+ (AppURLSessionTask *)reqForNetwork:(NSString *)pURL
                                mode:(NSString *)mode
                              params:(NSDictionary *)params
                               cache:(BOOL)cache
                            progress:(AppTaskProgress)progress
                             appDone:(AppTaskDone)appDone
                            appError:(AppTaskError)appError {
    /// 1.首先对接口地址做格式化处理，设置域名、拼接地址、格式化地址
    NSString *formatURL = [self formatURL:pURL];

    AFHTTPSessionManager *manager = [self manager];
    AppURLSessionTask *appTask = nil;

    /* clang-format off */
    if ([mode isEqualToString:@"GET"]) {
        appTask = [manager GET:formatURL parameters:params headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            if (progress) {
                progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            /// 2.请求成功回调处理数据
            [self configDoneForTask:task done:responseObject params:params cache:cache appDone:appDone];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            /// 3.请求失败回调处理数据
            [self configErrorForTask:task error:error params:params cache:cache appDone:appDone appError:appError];
        }];
    } else {
        appTask = [manager POST:formatURL parameters:params headers:nil progress:^(NSProgress * _Nonnull uploadProgress) {
            if (progress) {
                progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            /// 2.请求成功回调处理数据
            [self configDoneForTask:task done:responseObject params:params cache:cache appDone:appDone];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            /// 3.请求失败回调处理数据
            [self configErrorForTask:task error:error params:params cache:cache appDone:appDone appError:appError];
        }];
    }
    /* clang-format on */

    if (appTask) {
        [[self dataTasks] addObject:appTask];
    }

    return appTask;
}

/* ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*
 * // MARK: 处理请求成功回调
 * ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*/

+ (void)configDoneForTask:(NSURLSessionDataTask *)appTask
                     done:(id)done
                   params:(NSDictionary *)params
                    cache:(BOOL)cache
                  appDone:(AppTaskDone)appDone {
    /// 1.从请求链接组中移除当前链接
    [[self dataTasks] removeObject:appTask];

    /// 2.控制台打印当前请求信息
    [self configDoneLog:appTask.originalRequest.URL.absoluteString done:done params:params];

    /// 3.如果需要缓存则存储当前数据
    if (cache) {
        NSError *error = nil;
        NSString *md5CacheURL = [NSString app_md5:[self appendURL:appTask.originalRequest.URL.absoluteString params:params]];
        NSData *cachedata = done;

        if (![done isKindOfClass:[NSData class]]) {
            cachedata = [NSJSONSerialization dataWithJSONObject:done options:NSJSONWritingPrettyPrinted error:&error];
        }

        if (cachedata && !error && [AppCacheUtils configCacheFolder:[AppCacheUtils cacheURL]]) {
            BOOL success = [AppCacheUtils configDataToFile:[[AppCacheUtils cacheURL] stringByAppendingPathComponent:md5CacheURL] data:cachedata];
            if (success) {
                AppLog(@"🍀 数据缓存成功\n URL：%@", [NSString stringWithFormat:@"%@/%@", [AppCacheUtils cacheURL], md5CacheURL])
            } else {
                AppLog(@"⚠️ 数据缓存失败");
            }
        } else {
            AppLog(@"⚠️ 数据缓存失败 Error：%@ %ld", [AppError errorCodesForSystem:[NSString stringWithFormat:@"%ld", (long)error.code]], (long)error.code);
        }
    }

    /// 4.返回字典数据
}

+ (void)configDoneLog:(NSString *)pURL
                 done:(id)done
               params:(NSDictionary *)params {
    if (params && params.count) {
        AppLog(@"🍀 数据请求成功\n URL：%@\n 请求参数：%@\n 返回数据：%@", pURL, params, done);
        return;
    }
    AppLog(@"🍀 数据请求成功\n URL：%@\n 返回数据：%@", pURL, done);
}

/* ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*
 * // MARK: 处理请求失败回调
 * ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*/

+ (void)configErrorForTask:(NSURLSessionDataTask *)appTask
                     error:(NSError *)error
                    params:(NSDictionary *)params
                     cache:(BOOL)cache
                   appDone:(AppTaskDone)appDone
                  appError:(AppTaskError)appError {
    /// 1.从请求链接组中移除当前链接
    [[self dataTasks] removeObject:appTask];

    /// 2.控制台打印当前错误信息
    [self configErrorLog:appTask.originalRequest.URL.absoluteString error:error params:params];

    /// 3.如果需要缓存则读取当前数据
    if (cache) {
        NSError *error = nil;
        NSString *md5CacheURL = [NSString app_md5:[self appendURL:appTask.originalRequest.URL.absoluteString params:params]];
        NSData *cachedata = [AppCacheUtils configDataForFile:[[AppCacheUtils cacheURL] stringByAppendingPathComponent:md5CacheURL]];

        if (cachedata) {
            id done = [NSJSONSerialization JSONObjectWithData:cachedata options:NSJSONReadingAllowFragments error:&error];
            if (done && !error) {
                AppLog(@"🍀 缓存加载成功\n URL：%@\n 返回数据：%@", appTask.originalRequest.URL.absoluteURL, done);
                appDone(done);
            } else {
                AppLog(@"⚠️ 缓存加载失败 Error：%@ %ld", [AppError errorCodesForSystem:[NSString stringWithFormat:@"%ld", (long)error.code]], (long)error.code);
            }
        } else {
            AppLog(@"⚠️ 缓存加载失败 Error：没有可以加载的缓存数据");
        }
    }

    /// 4.返回错误信息
    appError(error);
}

+ (void)configErrorLog:(NSString *)pURL
                 error:(NSError *)error
                params:(NSDictionary *)params {
    if (params && params.count) {
        AppLog(@"⚠️ 数据请求失败\n URL：%@\n 请求参数：%@\n Error：%@ %ld", pURL, params, [AppError errorCodesForSystem:[NSString stringWithFormat:@"%ld", (long)error.code]], (long)error.code);
        return;
    }
    AppLog(@"⚠️ 数据请求失败\n URL：%@\n Error：%@ %ld", pURL, [AppError errorCodesForSystem:[NSString stringWithFormat:@"%ld", (long)error.code]], (long)error.code);
}

/* ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*
 * // MARK: 文件上传
 * ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*/
/**
 *  @brief 用于头像等图片上传
 *
 *  @param pURL     接口地址
 *  @param image    需要上传的图片
 *  @param name     图片上传的请求参数名，由后端接口的人指定
 *  @param pType    大多情况下传 image/jpeg，可以自定义
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
                                   pType:(NSString *)pType
                                  params:(NSDictionary *)params
                                progress:(AppTaskProgress)progress
                                 appDone:(AppTaskDone)appDone
                                appError:(AppTaskError)appError {
    /// 1.首先对接口地址做格式化处理，设置域名、拼接地址、格式化地址
    NSString *formatURL = [self formatURL:pURL];

    AFHTTPSessionManager *manager = [self manager];
    AppURLSessionTask *appTask = nil;

    /* clang-format off */
    appTask = [manager POST:formatURL parameters:params headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *data = UIImageJPEGRepresentation(image, 1);
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        format.dateFormat = @"yyyyMMddHHmmss";
        NSString *formatImage = [NSString stringWithFormat:@"%@.jpg", [format stringFromDate:[NSDate date]]];
        
        [formData appendPartWithFileData:data name:name fileName:formatImage mimeType:pType];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self dataTasks] removeObject:task];
        [self configDoneLog:task.originalRequest.URL.absoluteString done:responseObject params:params];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self dataTasks] removeObject:task];
        [self configErrorLog:task.originalRequest.URL.absoluteString error:error params:params];
    }];
    /* clang-format on */

    if (appTask) {
        [[self dataTasks] addObject:appTask];
    }

    return appTask;
}

/* ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*
 * // MARK: 文件下载
 * ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*/
+ (AppURLSessionTask *)reqForDownload:(NSString *)pURL
                               params:(NSDictionary *)params
                             progress:(AppTaskProgress)progress
                              appDone:(AppTaskDone)appDone
                             appError:(AppTaskError)appError {
    /// 1.首先对接口地址做格式化处理，设置域名、拼接地址、格式化地址
    NSString *formatURL = [self formatURL:pURL];

    /// 2.如果需要存储下载文件的目录不存在，就先新建目录
    if (![AppCacheUtils configJudgeFolderExists:[AppCacheUtils cacheURL]]) {
        [AppCacheUtils configCacheFolder:[AppCacheUtils cacheURL]];
    }

    NSString *md5CacheURL = [NSString app_md5:[self appendURL:formatURL params:params]];
    NSMutableDictionary *cachedata = [[NSMutableDictionary alloc] initWithDictionary:[self configDataForFile:md5CacheURL]];

    AFHTTPSessionManager *manager = [self manager];
    AppURLSessionTask *appTask = nil;

    /// 3.判断是否缓存过该文件，如果下载过则继续下载，如果已经下载完成直接返回
    if ([cachedata objectForKey:@"data"] || [[cachedata objectForKey:@"progress"] floatValue] == 1.0) { /// 断点续传的文件
        if ([[cachedata objectForKey:@"progress"] floatValue] == 1.0) {
            /// 当前文件已经下载完成了
            AppLog(@"🍀 文件下载成功\n URL：%@", [cachedata objectForKey:@"cacheURL"]);
            return nil;
        }
        /// 继续下载
        appTask = [self configCachedata:cachedata md5CacheURL:md5CacheURL manager:manager progress:progress appDone:appDone appError:appError];
    } else { /// 首次下载的文件
        appTask = [self configNewdata:cachedata formatURL:formatURL md5CacheURL:md5CacheURL manager:manager progress:progress appDone:appDone appError:appError];
    }

    [appTask resume];

    if (appTask) {
        [[self dataTasks] addObject:@{md5CacheURL : appTask}];
    }

    return appTask;
}

/**
 *  @brief 处理有缓存数据的文件下载
 */
+ (AppURLSessionTask *)configCachedata:(NSMutableDictionary *)cachedata
                           md5CacheURL:(NSString *)md5CacheURL
                               manager:(AFURLSessionManager *)manager
                              progress:(AppTaskProgress)progress
                               appDone:(AppTaskDone)appDone
                              appError:(AppTaskError)appError {
    /* clang-format off */
    return [manager downloadTaskWithResumeData:[cachedata objectForKey:@"data"] progress:^(NSProgress * _Nonnull downloadProgress) {
        /// 4.实时监听下载进度
        if (downloadProgress.fractionCompleted <= 1.0) {
            AppLog(@"%f", downloadProgress.fractionCompleted);
            [cachedata setValue:@(downloadProgress.fractionCompleted) forKey:@"progress"];
            [self configDataToFile:cachedata md5CacheURL:md5CacheURL];
        }

        if (progress) {
            progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        /// 文件下载保存的沙盒路径，默认保存在 /Documents/AppNetwork 文件夹中
        NSURL *cacheURL = [[NSURL fileURLWithPath:[AppCacheUtils cacheURL]] URLByAppendingPathComponent:[response suggestedFilename]];
        [cachedata setValue:cacheURL.path forKey:@"cacheURL"];
        [self configDataToFile:cachedata md5CacheURL:md5CacheURL];
        
        return cacheURL;
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [[self dataTasks] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSDictionary class]] && [obj objectForKey:md5CacheURL]) {
                [[self dataTasks] removeObject:obj];
                *stop = YES;
            }
        }];
        
        if (!error) {
            AppLog(@"🍀 文件下载成功\n URL：%@", filePath.path);
        } else {
            AppLog(@"⚠️ 文件下载失败 Error：%@ %ld", [AppError errorCodesForSystem:[NSString stringWithFormat:@"%ld", (long)error.code]], (long)error.code);
            /// 文件下载失败时保存已下载数据，可以在下次下载时继续下载
            if (error.code == -999) {
                return; /// 当取消下载时，不做数据保存（防止在下载中清除当前文件缓存时，清不干净）
            }
            [cachedata setValue:[error.userInfo objectForKey:@"NSURLSessionDownloadTaskResumeData"] forKey:@"data"];
            [self configDataToFile:cachedata md5CacheURL:md5CacheURL];
        }
    }];
    /* clang-format on */
}

/**
 *  @brief 处理新建文件下载
 */
+ (AppURLSessionTask *)configNewdata:(NSMutableDictionary *)cachedata
                           formatURL:(NSString *)formatURL
                         md5CacheURL:(NSString *)md5CacheURL
                             manager:(AFURLSessionManager *)manager
                            progress:(AppTaskProgress)progress
                             appDone:(AppTaskDone)appDone
                            appError:(AppTaskError)appError {
    /* clang-format off */
    return [manager downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:formatURL]] progress:^(NSProgress * _Nonnull downloadProgress) {
        /// 4.实时监听下载进度
        if (downloadProgress.fractionCompleted <= 1.0) {
            AppLog(@"%f", downloadProgress.fractionCompleted);
            [cachedata setValue:@(downloadProgress.fractionCompleted) forKey:@"progress"];
            [self configDataToFile:cachedata md5CacheURL:md5CacheURL];
        }

        if (progress) {
            progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        /// 文件下载保存的沙盒路径，默认保存在 /Documents/AppNetwork 文件夹中
        NSURL *cacheURL = [[NSURL fileURLWithPath:[AppCacheUtils cacheURL]] URLByAppendingPathComponent:[response suggestedFilename]];
        [cachedata setValue:cacheURL.path forKey:@"cacheURL"];
        [self configDataToFile:cachedata md5CacheURL:md5CacheURL];
        
        return cacheURL;
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [[self dataTasks] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSDictionary class]] && [obj objectForKey:md5CacheURL]) {
                [[self dataTasks] removeObject:obj];
                *stop = YES;
            }
        }];
        
        if (!error) {
            AppLog(@"🍀 文件下载成功\n URL：%@", filePath.path);
        } else {
            AppLog(@"⚠️ 文件下载失败 Error：%@ %ld", [AppError errorCodesForSystem:[NSString stringWithFormat:@"%ld", (long)error.code]], (long)error.code);
            /// 文件下载失败时保存已下载数据，可以在下次下载时继续下载
            if (error.code == -999) {
                return; /// 当取消下载时，不做数据保存（防止在下载中清除当前文件缓存时，清不干净）
            }
            [cachedata setValue:[error.userInfo objectForKey:@"NSURLSessionDownloadTaskResumeData"] forKey:@"data"];
            [self configDataToFile:cachedata md5CacheURL:md5CacheURL];
        }
    }];
    /* clang-format on */
}

/**
 *  @brief 文件下载过程中，下载失败缓存下载数据
 *
 *  @param done 需要缓存的数据
 *  @param md5CacheURL 通过下载地址和参数加密后得到的字符串，用于缓存文件的文件名
 */
+ (void)configDataToFile:(NSDictionary *)done md5CacheURL:(NSString *)md5CacheURL {
    [NSKeyedArchiver archiveRootObject:done toFile:[[AppCacheUtils cacheURL] stringByAppendingPathComponent:md5CacheURL]];
}

/**
 *  @brief 读取缓存数据
 *
 *  @param md5CacheURL 通过下载地址和参数加密后得到的字符串，用于缓存文件的文件名
 */
+ (NSDictionary *)configDataForFile:(NSString *)md5CacheURL {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[[AppCacheUtils cacheURL] stringByAppendingPathComponent:md5CacheURL]];
}

/* ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*
 * // MARK: 私有工具方法
 * ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄＊ ┄┅┄┅┄┅┄┅┄*/

+ (AFHTTPSessionManager *)manager {
    @synchronized(self) {
        if (!app_manager) {
            [AFNetworkActivityIndicatorManager sharedManager].enabled = YES; /// 开启转圈圈

            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            manager.responseSerializer = [AFJSONResponseSerializer serializer];

            NSArray *arr = @[ @"application/json",
                              @"text/html",
                              @"text/json",
                              @"text/plain",
                              @"text/javascript",
                              @"text/xml",
                              @"image/*" ];
            manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:arr];

            for (NSString *key in app_header.allKeys) {
                if (app_header[key] != nil) {
                    [manager.requestSerializer setValue:app_header[key] forHTTPHeaderField:key];
                }
            }

            manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
            manager.requestSerializer.timeoutInterval = app_pTimed;
            manager.operationQueue.maxConcurrentOperationCount = 3; /// 设置允许同时最大并发数量

            manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
            manager.securityPolicy.allowInvalidCertificates = YES;
            [manager.securityPolicy setValidatesDomainName:NO];

            app_manager = manager;
        }
    }
    return app_manager;
}

/**
 *  @brief 用于拼接完整的请求URL，并格式化
 */
+ (NSString *)formatURL:(NSString *)pURL {
    if (pURL.length == 0 || !pURL) {
        return @"";
    }

    if ([self baseURL:pURL].length == 0 || ![self baseURL:pURL]) {
        return pURL;
    }

    if ([pURL hasPrefix:@"http://"] || [pURL hasPrefix:@"https://"]) {
        return [pURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }

    NSString *appendURL = pURL;
    if (![pURL hasPrefix:@"http://"] && ![pURL hasPrefix:@"https://"]) {
        if ([[self baseURL:pURL] hasSuffix:@"/"]) { /** baseURL末尾有"/" */
            if ([pURL hasPrefix:@"/"]) {
                appendURL = [NSString stringWithFormat:@"%@%@", [self baseURL:pURL], [pURL substringFromIndex:1]];
            } else {
                appendURL = [NSString stringWithFormat:@"%@%@", [self baseURL:pURL], pURL];
            }
        } else { /** baseURL末尾没有"/" */
            if ([pURL hasPrefix:@"/"]) {
                appendURL = [NSString stringWithFormat:@"%@%@", [self baseURL:pURL], pURL];
            } else {
                appendURL = [NSString stringWithFormat:@"%@/%@", [self baseURL:pURL], pURL];
            }
        }
    }

    return [appendURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

/**
 *  @brief 用于拼接完整参数，方便在控制台显示当前请求链接的完整链接及参数
 */
+ (NSString *)appendURL:(NSString *)pURL params:(id)params {
    if (!params || ![params isKindOfClass:[NSDictionary class]] || ![params count]) {
        return pURL;
    }

    NSString *p = @"";
    for (NSString *key in params) {
        id value = [params objectForKey:key];
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSSet class]]) {
            continue;
        } else {
            p = [NSString stringWithFormat:@"%@%@=%@&", p.length == 0 ? @"&" : p, key, value];
        }
    }

    if (p.length > 1) { /// 消除末尾最后一个 &
        p = [p substringToIndex:p.length - 1];
    }

    if (([pURL hasPrefix:@"http://"] || [pURL hasPrefix:@"https://"]) && p.length > 1) {
        if ([pURL rangeOfString:@"?"].location != NSNotFound || [pURL rangeOfString:@"#"].location != NSNotFound) {
            pURL = [NSString stringWithFormat:@"%@%@", pURL, p];
        } else {
            p = [p substringFromIndex:1];
            pURL = [NSString stringWithFormat:@"%@?%@", pURL, p];
        }
    }
    return pURL.length == 0 ? p : pURL;
}

@end
