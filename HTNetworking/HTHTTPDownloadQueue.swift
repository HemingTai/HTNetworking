//
//  HTHTTPDownloadQueue.swift
//  HTNetworking
//
//  Created by heming on 17/3/2.
//  Copyright © 2017年 Mr.Tai. All rights reserved.
//

/************************************************
 * 只支持单一配置(默认配置或者自定义配置)
 * 支持队列进度和单任务进度
 * 支持重设单个任务进度回调（TableView Cell重用会用到）
 * 暂不支持断点续传
 ************************************************/
import Foundation

class HTHTTPDownloadQueue: NSObject
{
    //队列进度
    var queueProgress: Progress?
    //队列进度回调
    var queueProgressHandler: HTQueueProgressHandler?
    //队列完成回调
    var queueCompletionHandler: HTQueueCompletionHandler?
    // _tasks线程锁
    var myLock: NSLock?
    
    var session: URLSession?
    var tasks: NSMutableDictionary?
    var operationQueue: OperationQueue?
    
    /**
     初始化，默认配置
     */
    override init()
    {
        super.init()
        
    }
    
    /**
     初始化，默认配置
     @param progressHandler 队列进度回调
     @param completionHandler 队列完成回调
     */
    init(queueProgressHandler progressHandler:HTQueueProgressHandler?, queueCompletionHandler: HTQueueCompletionHandler?)
    {
        [self initWithURLSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] queueProgressHandler:progressHandler andQueueCompletionHandler:completionHandler];
    }
    /**
     初始化，自定义配置
     @param configuration NSURLSession配置
     */
    init(URLSessionConfiguration configuration: URLSessionConfiguration)
    {
        self.initWithURLSessionConfiguration:configuration queueProgressHandler:nil andQueueCompletionHandler:nil];
    }
    
    /**
     初始化，自定义配置
     @param configuration NSURLSession配置
     @param progressHandler 队列进度回调
     @param completionHandler 队列完成回调
     */
    init(URLSessionConfiguration configuration: URLSessionConfiguration,
         queueProgressHandler: HTQueueProgressHandler?, queueCompletionHandler: HTQueueCompletionHandler?)
    {
    if (!configuration) {
    configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    }
    if (self = [super init]) {
    // 添加线程锁
    _myLock = [[NSLock alloc] init];
    
    _tasks = [[NSMutableDictionary alloc] init];
    
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.maxConcurrentOperationCount = 3;
    
    _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:_operationQueue];
    
    _queueProgress = [[NSProgress alloc] init];
    
    _queueProgressHandler = progressHandler;
    _queueCompletionHandler = completionHandler;
    }

    }
    
    /**
     添加下载任务
     @param urlString 下载地址
     @param progressHandler 任务进度回调
     @param completionHandler 任务完成回调
     */
    func addTask(withURLString urlString: String, progressHandler: HTProgressHandler?, completionHandler: HTURLDownloadCompletionHandler?)
    {
        if (![Utility isValidString:urlString]) {
            return;
        }
        NSURL *url = [NSURL URLWithString:urlString];
        if (url) {
            NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithURL:url];
            
            NSMutableDictionary *taskInfo = [NSMutableDictionary dictionary];
            if (downloadTask) {
                taskInfo[@"Task"] = downloadTask;
            }
            if (progressHandler) {
                taskInfo[@"ProgressHandler"] = progressHandler;
            }
            if (completionHandler) {
                taskInfo[@"CompletionHandler"] = completionHandler;
            }
            [_myLock lock];
            self.tasks[@(urlString.hash).stringValue] = taskInfo;
            [_myLock unlock];
            // update progress
            if (!self.queueProgress.isCancelled) {
                self.queueProgress.totalUnitCount++;
            }
            if (self.queueProgressHandler) {
                self.queueProgressHandler(self.queueProgress);
            }
            
            [downloadTask resume];
        } else {
            completionHandler(nil, nil, nil);
        }
    }
    
    /**
     添加下载任务
     @param urlString 下载地址
     @param completionHandler 任务完成回调
     @see addTaskWithURLString:progressHandler:completionHandler:
     */
    func addTask(withURLString urlString:String, completionHandler: HTURLDownloadCompletionHandler?)
    {
        [self addTaskWithURLString:urlString progressHandler:nil completionHandler:completionHandler];
    }
    
    //! 获取单个任务的进度
    func getTaskProgress(withURLString urlString: String) -> Progress
    {
        if (![Utility isValidString:urlString]) {
            return nil;
        }
        NSString *key = @(urlString.hash).stringValue;
        [_myLock lock];
        NSURLSessionTask *task = self.tasks[key][@"Task"];
        [_myLock unlock];
        NSProgress *progress = [NSProgress progressWithTotalUnitCount:task.countOfBytesExpectedToReceive];
        progress.completedUnitCount = task.countOfBytesReceived;
        return progress;
    }

    //! 重设单个任务的进度回调
    func resetTaskProgressHandler(withURLString urlString: String, progressHandler: HTProgressHandler?)
    {
        if (![Utility isValidString:urlString]) {
            return;
        }
        NSString *key = @(urlString.hash).stringValue;
        [_myLock lock];
        NSMutableDictionary *taskInfo = [self.tasks[key] mutableCopy];
        if (progressHandler) {
            taskInfo[@"ProgressHandler"] = progressHandler;
        } else {
            [taskInfo removeObjectForKey:@"ProgressHandler"];
        }
        self.tasks[key] = taskInfo;
        [_myLock unlock];
    }
    
    //! 取消单个任务
    func cancelTask(withURLString urlString: String)
    {
        if (![Utility isValidString:urlString]) {
            return;
        }
        NSString *key = @(urlString.hash).stringValue;
        [_myLock lock];
        NSURLSessionTask *task = self.tasks[key][@"Task"];
        [task cancel];
        [_myLock unlock];
    }
    //! 继续单个任务
    func resumeTask(withURLString urlString: String)
    {
        if (![Utility isValidString:urlString]) {
            return;
        }
        [_myLock lock];
        NSString *key = @(urlString.hash).stringValue;
        NSURLSessionTask *task = self.tasks[key][@"Task"];
        [task resume];
        [_myLock unlock];
    }
    //! 挂起单个任务
    func suspendTask(withURLString urlString: String)
    {
        if (![Utility isValidString:urlString]) {
            return;
        }
        [_myLock lock];
        NSString *key = @(urlString.hash).stringValue;
        NSURLSessionTask *task = self.tasks[key][@"Task"];
        [task suspend];
        [_myLock unlock];
    }
    //! 清空队列
    func clear()
    {
        [_myLock lock];
        [self.tasks enumerateKeysAndObjectsUsingBlock:^(id key, NSDictionary *obj, BOOL *stop) {
            [obj[@"Task"] cancel];
            }];
        [self.operationQueue cancelAllOperations];
        [self.tasks removeAllObjects];
        [_myLock unlock];
        self.queueProgress.completedUnitCount = 0;
        self.queueProgress.totalUnitCount = 0;
        if (self.queueCompletionHandler) {
            self.queueCompletionHandler();
        }
    }
    //! 销毁队列，不能再添加任务
    func tearDown()
    {
        [self clear];
        [self.session invalidateAndCancel];
    }
    
    #pragma mark - NSURLSessionDelegate
    - (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
    {
    // didFinishDownloadingToURL已经回调完成了，所以此处无需处理完成，只要处理出错就可以了
    if (error) {
    NSString *key = @(task.originalRequest.URL.absoluteString.hash).stringValue;
    [_myLock lock];
    NSDictionary *taskInfo = self.tasks[key];
    [_myLock unlock];
    if (taskInfo) {
    URLDownloadCompletionHandler handler = taskInfo[@"CompletionHandler"];
    if (handler) {
    handler(nil, task.response, error);
    }
    }
    }
    }
    
    #pragma mark - NSURLSessionDownloadDelegate
    - (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
    {
    NSString *key = @(downloadTask.originalRequest.URL.absoluteString.hash).stringValue;
    [_myLock lock];
    NSDictionary *taskInfo = self.tasks[key];
    [_myLock unlock];
    if (taskInfo) {
    URLDownloadCompletionHandler handler = taskInfo[@"CompletionHandler"];
    if (handler) {
    handler(location, downloadTask.response, downloadTask.error);
    }
    
    // update progress
    if (!self.queueProgress.isCancelled) {
    self.queueProgress.completedUnitCount++;
    }
    if (self.queueProgressHandler) {
    self.queueProgressHandler(self.queueProgress);
    }
    
    // queue has completed
    if (self.queueCompletionHandler && self.queueProgress.fractionCompleted == 1.0) {
    self.queueCompletionHandler();
    }
    }
    }
    
    - (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
    {
    NSString *key = @(downloadTask.originalRequest.URL.absoluteString.hash).stringValue;
    [_myLock lock];
    NSDictionary *taskInfo = self.tasks[key];
    [_myLock unlock];
    if (taskInfo) {
    ProgressHandler handler = taskInfo[@"ProgressHandler"];
    if (handler) {
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:totalBytesExpectedToWrite];
    progress.completedUnitCount = totalBytesWritten;
    handler(progress);
    }
    }
    }
}
