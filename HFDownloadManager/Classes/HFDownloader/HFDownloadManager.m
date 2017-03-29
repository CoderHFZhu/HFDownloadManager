//
//  HFDownloadManager.m
//  HFDownloadManager
//
//  Created by zack on 2017/3/29.
//  Copyright © 2017年 CoderHF. All rights reserved.
//

#import "HFDownloadManager.h"
#import <UIKit/UIKit.h>
@interface HFDownloadManager()

/** 存储下载的HFDownloader
 因为单个任务对应一个HFDownloader 的实例
 */
@property (nonatomic ,strong) NSMutableDictionary *taskDict;
/** 下载排队对列
 存放下载信息，如果最大下载数超过设置的，就把下载信息转换为自定存入数组中
*/
@property (nonatomic ,strong) NSMutableArray *queue;
/** 后台进程id*/
@property (nonatomic ,assign) UIBackgroundTaskIdentifier backgroudTaskId;

@end
@implementation HFDownloadManager





+(instancetype)shredManager
{
    static HFDownloadManager *mgr=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr=[[HFDownloadManager alloc]init];
        mgr.maxTaskCount = 3;
    });
    return mgr;
}

-(instancetype)init
{
    if(self=[super init])
    {
        self.taskDict=[NSMutableDictionary dictionary];
        self.queue=[NSMutableArray array];
        self.backgroudTaskId = UIBackgroundTaskInvalid;
        //注册系统内存不足的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(systemSpaceInsufficient:) name:HFInsufficientSystemSpaceNotification object:nil];
        //注册程序下载完成的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskDidFinishDownloading:) name:HFDownloadTaskDidFinishDownloadingNotification object:nil];
        //注册程序即将失去焦点的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskWillResign:) name:UIApplicationWillResignActiveNotification object:nil];
        //注册程序获得焦点的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskDidBecomActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        //注册程序即将被终结的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskWillBeTerminate:) name:UIApplicationWillTerminateNotification object:nil];
        
    }
    return self;
}
/**
 *  收到系统存储空间不足的通知调用的方法
 *
 *  @param sender 系统存储空间不足的通知
 */
-(void)systemSpaceInsufficient:(NSNotification *)sender{
    
    NSString *urlString=[sender.userInfo objectForKey:@"urlString"];
    [[self.class shredManager] cancelDownloadTaskWithURLString:urlString];
}

/**
 *  收到程序即将失去焦点的通知，开启后台运行
 *
 *  @param sender 通知
 */
-(void)downloadTaskWillResign:(NSNotification *)sender{
    
    if(self.taskDict.count>0){
        
        self.backgroudTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            
        }];
    }
}
/**
 *  收到程序重新得到焦点的通知，关闭后台
 *
 *  @param sender 通知
 */
-(void)downloadTaskDidBecomActive:(NSNotification *)sender{
    
    if(self.backgroudTaskId != UIBackgroundTaskInvalid){
        
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroudTaskId];
        self.backgroudTaskId=UIBackgroundTaskInvalid;
    }
}

/**
 *  程序将要结束时，取消下载
 *
 *  @param sender 通知
 */
-(void)downloadTaskWillBeTerminate:(NSNotification *)sender{
    
    [[self.class shredManager] cancelAllTasks];
}

/**
 *  下载完成通知调用的方法
 *
 *  @param sender 通知
 */
-(void)downloadTaskDidFinishDownloading:(NSNotification *)sender{
    
    //下载完成后，从任务列表中移除下载任务，若总任务数小于最大同时下载任务数，
    //则从排队对列中取出一个任务，进入下载
    NSString *urlString=[sender.userInfo objectForKey:@"urlString"];
    [self.taskDict removeObjectForKey:urlString];
    if(self.taskDict.count < self.maxTaskCount){
        
        if(self.queue.count>0){
            
            NSDictionary *first=[self.queue objectAtIndex:0];
            
            [self downloadWithUrlString:first[@"urlString"]
                                 toPath:first[@"destinationPath"]
                                process:first[@"process"]
                             completion:first[@"completion"]
                                failure:first[@"failure"]];
            //从排队对列中移除一个下载任务
            [_queue removeObjectAtIndex:0];
        }
    }
}


-(void)downloadWithUrlString:(NSString *)urlString toPath:(NSString *)destinationPath process:(ProcessHandle)process completion:(CompletionHandle)completion failure:(FailureHandle)failure
{
    
    /* 防止同一任务点击过多次*/
    NSArray *keysArr = [self.taskDict allKeys];
    if ([keysArr containsObject:urlString]) {
        return;
    }
    
    
    //若同时下载的任务数超过最大同时下载任务数，
    //则把下载任务存入对列，在下载完成后，自动进入下载。
    if(_taskDict.count >= self.maxTaskCount){
        
        NSDictionary *dict=@{@"urlString":urlString,
                             @"destinationPath":destinationPath,
                             @"process":process,
                             @"completion":completion,
                             @"failure":failure};
        [self.queue addObject:dict];
        return;
    }
    HFDownloader *downloader=[HFDownloader downloader];
    
    /* 防止对象在同一时间内被其它线程访问，起到线程的保护作用*/
    @synchronized (self) {
        [self.taskDict setObject:downloader forKey:urlString];
    }
    [downloader downloadWithUrlString:urlString
                               toPath:destinationPath
                              process:process
                           completion:completion
                              failure:failure];
}
/**
 *  取消下载任务
 *
 *  @param urlString 下载的链接
 */
-(void)cancelDownloadTaskWithURLString:(NSString *)urlString
{
    HFDownloader *downloader=[self.taskDict objectForKey:urlString];
    [downloader cancel];
    
    @synchronized (self) {
        [self.taskDict removeObjectForKey:urlString];
    }
    if(self.queue.count>0){
        
        NSDictionary *dic=[self.queue objectAtIndex:0];
        
        [self downloadWithUrlString:dic[@"urlString"]
                             toPath:dic[@"destinationPath"]
                            process:dic[@"process"]
                         completion:dic[@"completion"]
                            failure:dic[@"failure"]];
        //从排队对列中移除一个下载任务
        [self.queue removeObjectAtIndex:0];
    }
}

/**
 *  彻底移除下载任务 并删除下载文件
 *
 *  @param urlString  下载链接
 *  @param path 文件路径
 */
-(void)removeForUrl:(NSString *)urlString file:(NSString *)path{
    
    HFDownloader *downloader=[self.taskDict objectForKey:urlString];
    if(downloader){
        [downloader cancel];
    }
    @synchronized (self) {
        [self.taskDict removeObjectForKey:urlString];
    }
    NSUserDefaults *usd=[NSUserDefaults standardUserDefaults];
    NSString *totalLebgthKey=[NSString stringWithFormat:@"%@totalLength",urlString];
    NSString *progressKey=[NSString stringWithFormat:@"%@progress",urlString];
    [usd removeObjectForKey:totalLebgthKey];
    [usd removeObjectForKey:progressKey];
    [usd synchronize];
    
    NSFileManager *fileManager=[NSFileManager defaultManager];
    BOOL fileExist=[fileManager fileExistsAtPath:path];
    if(fileExist){
        
        [fileManager removeItemAtPath:path error:nil];
    }
}

/**
 *  暂停所有下载
 */
-(void)cancelAllTasks
{
    [_taskDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        HFDownloader *downloader=obj;
        [downloader cancel];
        [_taskDict removeObjectForKey:key];
    }];
}
/**
 *  获取上一次的下载进度
 *
 *  @param url 下载链接
 *
 *  @return 下载进度
 */
-(float)lastProgress:(NSString *)url
{
    return [HFDownloader lastProgress:url];
}
/**
 *  获取文件已下载的大小和总大小,格式为:已经下载的大小/文件总大小,如：12.00M/100.00M。
 *
 *  @param url 下载链接
 *
 *  @return 有文件大小及总大小组成的字符串
 */
-(NSString *)filesSize:(NSString *)url
{
    return [HFDownloader filesSize:url];
}
-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}




@end
