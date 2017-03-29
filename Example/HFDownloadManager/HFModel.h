//
//  HFModel.h
//  HFDownloadManager
//
//  Created by zack on 2017/3/29.
//  Copyright © 2017年 zack. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HFModel : NSObject
@property(nonatomic,strong) NSString *name;
@property(nonatomic,strong) NSString *url;
@property(nonatomic,strong) NSString *destinationPath;
@end
