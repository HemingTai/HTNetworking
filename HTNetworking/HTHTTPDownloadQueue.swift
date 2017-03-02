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
        
    }
    
    /**
     添加下载任务
     @param urlString 下载地址
     @param completionHandler 任务完成回调
     @see addTaskWithURLString:progressHandler:completionHandler:
     */
    func addTask(withURLString urlString:String, completionHandler: HTURLDownloadCompletionHandler?)
    {
        
    }
    
    //! 获取单个任务的进度
    func getTaskProgress(withURLString urlString: String) -> Progress
    {
        
    }

    //! 重设单个任务的进度回调
    func resetTaskProgressHandler(withURLString urlString: String, progressHandler: HTProgressHandler?)
    {
        
    }
    
    //! 取消单个任务
    func cancelTask(withURLString urlString: String)
    {
        
    }
    //! 继续单个任务
    func resumeTask(withURLString urlString: String)
    {
        
    }
    //! 挂起单个任务
    func suspendTask(withURLString urlString: String)
    {
        
    }
    //! 清空队列
    func clear()
    {
    
    }
    //! 销毁队列，不能再添加任务
    func tearDown()
    {
        
    }
}
