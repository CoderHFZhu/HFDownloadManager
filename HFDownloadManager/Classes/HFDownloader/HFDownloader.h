//
//  HFDownloader.h
//  HFDownloadManager
//
//  Created by zack on 2017/3/28.
//  Copyright © 2017年 CoderHF. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 *  下载完成的通知名
 */
static NSString *const HFDownloadTaskDidFinishDownloadingNotification = @"HFDownloadTaskDidFinishDownloadingNotification";
/**
 *  系统存储空间不足的通知名
 */
static NSString *const HFInsufficientSystemSpaceNotification = @"HFInsufficientSystemSpaceNotification";
/**
 *  下载进度改变的通知
 */
static NSString *const HFProgressDidChangeNotificaiton = @"HFProgressDidChangeNotificaiton";

/**
 进度回调的代码块
 
 @param progress 下载进度、已下载部分大小
 @param sizeString 已下载部分大小/文件大小构成的字符串(如:1.15M/5.27M)
 @param speedString 下载速度字符串(如:512Kb/s)
 */
typedef void (^ProcessHandle)(float progress,NSString *sizeString,NSString *speedString);

/**
 成功回调
 */
typedef void (^CompletionHandle)();

/**
 失败回调
 
 @param error 回调的错误
 */
typedef void (^FailureHandle)(NSError *error);

@interface HFDownloader : NSObject<NSURLSessionDataDelegate>


//下载过程中回调的代码块，会多次调用。
@property(nonatomic,copy,readonly)ProcessHandle process;
//下载完成回调的代码块
@property(nonatomic,copy,readonly)CompletionHandle completion;
//下载失败的回调代码块
@property(nonatomic,copy,readonly)FailureHandle failure;

/**
 * 获取对象的类方法
 */
+(instancetype)downloader;
/**
 *  断点下载
 *
 *  @param urlString        下载的链接
 *  @param destinationPath  下载的文件的保存路径
 *  @param  process         下载过程中回调的代码块，会多次调用
 *  @param  completion      下载完成回调的代码块
 *  @param  failure         下载失败的回调代码块
 */
-(void)downloadWithUrlString:(NSString *)urlString
                      toPath:(NSString *)destinationPath
                     process:(ProcessHandle)process
                  completion:(CompletionHandle)completion
                     failure:(FailureHandle)failure;
/**
 *  取消下载
 */
-(void)cancel;
/**
 * 获取上一次的下载进度
 */
+(float)lastProgress:(NSString *)url;
/**获取文件已下载的大小和总大小,格式为:已经下载的大小/文件总大小,如：12.00M/100.00M。
 *
 * @param url 下载链接
 */
+(NSString *)filesSize:(NSString *)url;





@end
