//
//  AppError.h
//  AppNetwork
//
//  Created by Code on 2020/8/10.
//  Copyright © 2020 北京卡友在线科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppError : NSObject

+ (NSString *)errorCodesForSystem:(NSString *)code;

@end

NS_ASSUME_NONNULL_END
