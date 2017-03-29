//
//  HFDownloadManager.h
//  HFDownloadManager
//
//  Created by zack on 2017/3/29.
//  Copyright © 2017年 CoderHF. All rights reserved.
//

/*
 HFDownloadManager用法简介
 ---------------------------------------------------------------------------------------------
 基于NSURLSession封装的断点续传类，用于大文件下载，退出程序后，下次接着下载。
 
 -->1.在项目中导入HFDownloadManager.h头文件；
 -->2.搭建UI时，设置显示进度的UIProgressView的进度值:[[HFDownloadManager sharedManager] lastProgressWithUrl:url],
 这个方法的返回值是float类型的；
 设置显示文件大小/文件总大小的Label的文字：[[HFDownloadManager sharedManager]fileSize:url]；
 
 -->3.开始或恢复下载任务的方法：[HFDownloadManager sharedManager] downloadWithUrlString:(NSString *)urlString
 toPath:(NSString *)destinationPath
 process:(ProcessHandle)process
 completion:(CompletionHandle)completion
 failure:(FailureHandle)failure];
 
 这个方法包含三个回调代码块，分别是：
 
 1)下载过程中的回调代码块，带3个参数：下载进度参数progress，已下载文件大小sizeString，文件下载速度speedString；
 2)下载成功回调的代码块，没有参数；
 3)下载失败的回调代码块，带一个下载错误参数error。
 
 -->4.在下载出错的回调代码块中处理出错信息。在出错的回调代码块中或者暂停下载任务时，
 调用[[HFDownloadManager sharedManager] cancelDownloadTask:url]方法取消/暂停下载任务；
 
 -->5.如果在非下载界面监听下载进去 注册通知 监听 《HFProgressDidChangeNotificaiton》 返回参数里有一个字典，里面包含四个参数 @{@"url":self.urlString, 请求下载的url
                @"progress":@(progress), 下载进度
                @"sizeString":sizeString,下载的大小
                @"speedString":speedString} 下载速度
 
 ==============================================================================================
  Copyright © 2017年 CoderHF. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "HFDownloader.h"
@interface HFDownloadManager : NSObject
/** 最大同时下载任务数，超过将自动存入排队对列中,默认为3*/
@property (nonatomic ,assign) NSInteger maxTaskCount;
+(instancetype)shredManager;

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
 *  暂停下载
 *
 *  @param url 下载的链接
 */
-(void)cancelDownloadTaskWithURLString:(NSString *)url;
/**
 *  暂停所有下载
 */
-(void)cancelAllTasks;
/**
 *  彻底移除下载任务 并删除下载文件
 *
 *  @param urlString  下载链接
 *  @param path 文件路径
 */
-(void)removeForUrl:(NSString *)urlString file:(NSString *)path;
/**
 *  获取上一次的下载进度
 *
 *  @param url 下载链接
 *
 *  @return 下载进度
 */
-(float)lastProgress:(NSString *)url;
/**
 *  获取文件已下载的大小和总大小,格式为:已经下载的大小/文件总大小,如：12.00M/100.00M。
 *
 *  @param url 下载链接
 *
 *  @return 有文件大小及总大小组成的字符串
 */
-(NSString *)filesSize:(NSString *)url;

@end
