//
//  HFDownloader.m
//  HFDownloadManager
//
//  Created by zack on 2017/3/28.
//  Copyright © 2017年 CoderHF. All rights reserved.
//

#import "HFDownloader.h"
#import <UIKit/UIKit.h>

@interface HFDownloader()
/** 请求地址*/
@property (nonatomic ,copy) NSString *urlString;
/* 存储路径*/
@property (nonatomic ,copy) NSString *destinationPath;
/** 接受响应体信息 */
@property (nonatomic, strong) NSFileHandle *handle;
@property (nonatomic, assign) NSInteger lastSize;
@property (nonatomic, assign) NSInteger growth;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@end
@implementation HFDownloader
/**
 * 获取对象的类方法
 */
+(instancetype)downloader
{
    return [[[self class] alloc]init];
}

//计算一次文件大小增加部分的尺寸
-(void)getGrowthSize
{
    NSUInteger size=[[[[NSFileManager defaultManager] attributesOfItemAtPath:self.destinationPath error:nil] objectForKey:NSFileSize] integerValue];
    self.growth = size - self.lastSize;
    self.lastSize = size;
}

-(instancetype)init
{
    if(self=[super init])
    {
        //每0.1秒计算一次文件大小增加部分的尺寸
        self.timer=[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(getGrowthSize) userInfo:nil repeats:YES];
    }
    return self;
}


/**
 *  断点下载
 *
 *  @param urlString        下载的链接
 *  @param destinationPath  下载的文件的保存路径
 *  @param  process         下载过程中回调的代码块，会多次调用
 *  @param  completion      下载完成回调的代码块
 *  @param  failure         下载失败的回调代码块
 */
-(void)downloadWithUrlString:(NSString *)urlString toPath:(NSString *)destinationPath process:(ProcessHandle)process completion:(CompletionHandle)completion failure:(FailureHandle)failure
{
    if(urlString && destinationPath)
    {
        self.urlString = urlString;
        self.destinationPath = destinationPath;
        _process = process;
        _completion = completion;
        _failure = failure;
        
        NSURL *url=[NSURL URLWithString:urlString];
        NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
        
        
        NSFileManager *fileManager=[NSFileManager defaultManager];
        BOOL fileExist=[fileManager fileExistsAtPath:destinationPath];
        if(fileExist)
        {
            NSUInteger length = [[[fileManager attributesOfItemAtPath:destinationPath error:nil] objectForKey:NSFileSize] integerValue];
            NSString *rangeString=[NSString stringWithFormat:@"bytes=%ld-",length];
            [request setValue:rangeString forHTTPHeaderField:@"Range"];
        }
        //_con=[NSURLConnection connectionWithRequest:request delegate:self];
        
        NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration  ] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
        self.dataTask = [session dataTaskWithRequest:request];
        
        [self.dataTask resume];
        
    }
}
#pragma mark ----------------------
#pragma mark NSURLSessionDataDelegate
/**
 *  1.接收到服务器的响应 它默认会取消该请求
 *
 *  @param session           会话对象
 *  @param dataTask          请求任务
 *  @param response          响应头信息
 *  @param completionHandler 回调 传给系统
 */
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSString *key=[NSString stringWithFormat:@"%@totalLength",self.urlString];
    NSUserDefaults *usd=[NSUserDefaults standardUserDefaults];
    NSUInteger totalLength=[usd integerForKey:key];
    if(totalLength==0)
    {
        [usd setInteger:response.expectedContentLength forKey:key];
        [usd synchronize];
    }
    NSFileManager *fileManager=[NSFileManager defaultManager];
    BOOL fileExist=[fileManager fileExistsAtPath:self.destinationPath];
    if(!fileExist){
        [fileManager createFileAtPath:self.destinationPath contents:nil attributes:nil];

    }
    /* 打开一个文件准备写入*/
    self.handle = [NSFileHandle fileHandleForWritingAtPath:self.destinationPath];

    completionHandler(NSURLSessionResponseAllow);

}
/**
 *  接收到服务器返回的数据 调用多次
 *
 *  @param session           会话对象
 *  @param dataTask          请求任务
 *  @param data              本次下载的数据
 */
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    //移动指针   跳到文件末尾
    [self.handle seekToEndOfFile];
    
    
    NSUInteger freeSpace=[self systemFreeSpace];
    if(freeSpace<1024*1024*20){
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:@"提示" message:@"系统可用存储空间不足20M" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *confirm=[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:confirm];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
        //发送系统存储空间不足的通知,用户可自行注册该通知，收到通知时，暂停下载，并更新界面
        [[NSNotificationCenter defaultCenter] postNotificationName:HFInsufficientSystemSpaceNotification object:nil userInfo:@{@"urlString":self.urlString}];
        return;
    }

    
    //写入数据到文件
    [self.handle writeData:data];
    
    
    NSUInteger length=[[[[NSFileManager defaultManager] attributesOfItemAtPath:self.destinationPath error:nil] objectForKey:NSFileSize] integerValue];
    NSString *key=[NSString stringWithFormat:@"%@totalLength",self.urlString];
    NSUInteger totalLength=[[NSUserDefaults standardUserDefaults] integerForKey:key];
    
    //计算下载进度
    float progress=(float)length/totalLength;
    [[NSUserDefaults standardUserDefaults]setFloat:progress forKey:[NSString stringWithFormat:@"%@progress",self.urlString]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    //获取文件大小
    NSString *sizeString=[[self class] filesSize:self.urlString];
    
  
    //计算网速
    NSString *speedString=@"0.00Kb/s";
    NSString *growString=[[self class] convertSize:self.growth*(1.0/0.1)];
    speedString=[NSString stringWithFormat:@"%@/s",growString];
    
    //发送进度改变的通知(一般情况下不需要用到，只有在触发下载与显示下载进度在不同界面的时候才会用到)
    NSDictionary *userInfo=@{@"url":self.urlString,@"progress":@(progress),@"sizeString":sizeString,@"speedString":speedString};
    [[NSNotificationCenter defaultCenter] postNotificationName:HFProgressDidChangeNotificaiton object:nil userInfo:userInfo];
    
    //回调下载过程中的代码块
    if(self.process){
        self.process(progress,sizeString,speedString);

    }

}
/**
 *  请求结束或者是失败的时候调用
 *
 *  @param session           会话对象
 *  @param task              请求任务
 *  @param error             错误信息
 */
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    //如果error 有值说明下载出现问题
    if (error) {
        
    }else{
        //关闭文件句柄
        [self.handle closeFile];
        self.handle = nil;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:HFDownloadTaskDidFinishDownloadingNotification object:nil userInfo:@{@"urlString":self.urlString}];
        if(self.completion){
            self.completion();

        }
    }
}



/**
 *  取消下载
 */
-(void)cancel
{
    [self.dataTask cancel];
    self.dataTask = nil;
    if(self.timer)
    {
        [self.timer invalidate];
    }
}


    
#pragma mark ----------------------
#pragma mark 计算空间 的

/**
 *  获取系统可用存储空间
 *
 *  @return 系统空用存储空间，单位：字节
 */
-(NSUInteger)systemFreeSpace{
    
    NSString *docPath=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSDictionary *dict=[[NSFileManager defaultManager] attributesOfFileSystemForPath:docPath error:nil];
    return [[dict objectForKey:NSFileSystemFreeSize] integerValue];
}
/**
 * 获取上一次的下载进度
 */
+(float)lastProgress:(NSString *)url
{
    if(url){
        return [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"%@progress",url]];
 
    }
    return 0.0;
}

/**
 获取文件已下载的大小和总大小

 @param url 下载文件的url
 @return 已经下载的大小/文件总大小 如：12.00M/100.00M
 */
+(NSString *)filesSize:(NSString *)url
{
    NSString *totalLebgthKey=[NSString stringWithFormat:@"%@totalLength",url];
    NSUserDefaults *usd=[NSUserDefaults standardUserDefaults];
    /* 文件总大小*/
    NSUInteger totalLength=[usd integerForKey:totalLebgthKey];
    if(totalLength==0)
    {
        return @"0.00K/0.00K";
    }
    NSString *progressKey=[NSString stringWithFormat:@"%@progress",url];
    float progress=[[NSUserDefaults standardUserDefaults] floatForKey:progressKey];
    /* 已经下载的大小*/
    NSUInteger currentLength = progress * totalLength;
    
    NSString *currentSize = [self convertSize:currentLength];
    NSString *totalSize = [self convertSize:totalLength];
    return [NSString stringWithFormat:@"%@/%@",currentSize,totalSize];
}

/**
 * 计算缓存的占用存储大小
 *
 * @prama length  文件大小
 */
+(NSString *)convertSize:(NSUInteger)length
{
    if(length < 1024)
        return [NSString stringWithFormat:@"%ldB",(NSUInteger)length];
    else if(length >= 1024 && length < 1024 * 1024)
        return [NSString stringWithFormat:@"%.0fK",(float)length/1024];
    else if(length >= 1024 * 1024 && length < 1024 * 1024 * 1024)
        return [NSString stringWithFormat:@"%.1fM",(float)length/(1024*1024)];
    else
        return [NSString stringWithFormat:@"%.1fG",(float)length/(1024*1024*1024)];
}



@end
