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

class HTHTTPDownloadQueue: NSObject, URLSessionTaskDelegate, URLSessionDownloadDelegate
{
    //队列进度
    var queueProgress: Progress?
    //队列进度回调
    var queueProgressHandler: HTQueueProgressHandler?
    //队列完成回调
    var queueCompletionHandler: HTQueueCompletionHandler?
    //tasks线程锁
    var myLock: NSLock?
    
    var session: URLSession?
    /*
     tasks 的 Key-Value 如下
     *key: String  String(URLString.hashValue)
     *value: NSDictionay ["Task":downloadTask, "ProgressHandler":progressHandler, "CompletionHandler":completionHandler]
     */
    var tasks: NSMutableDictionary?
    var operationQueue: OperationQueue?
    
    /**
     初始化，默认配置
     */
    override init()
    {
        _ = HTHTTPDownloadQueue(URLSessionConfiguration: URLSessionConfiguration.default)
    }
    
    /**
     初始化，自定义配置
     @param configuration NSURLSession配置
     */
    init(URLSessionConfiguration configuration: URLSessionConfiguration)
    {
        _ = HTHTTPDownloadQueue(URLSessionConfiguration: configuration, progressHandler: nil, completionHandler: nil)
    }
    
    /**
     初始化，默认配置
     @param progressHandler 队列进度回调
     @param completionHandler 队列完成回调
     */
    init(queueProgressHandler progressHandler:HTQueueProgressHandler?, completionHandler: HTQueueCompletionHandler?)
    {
        _ = HTHTTPDownloadQueue(URLSessionConfiguration: URLSessionConfiguration.default, progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    /**
     初始化，自定义配置
     @param configuration NSURLSession配置
     @param progressHandler 队列进度回调
     @param completionHandler 队列完成回调
     */
    init(URLSessionConfiguration configuration: URLSessionConfiguration,
         progressHandler: HTQueueProgressHandler?, completionHandler: HTQueueCompletionHandler?)
    {
        super.init()
        //添加线程锁
        myLock = NSLock()
        tasks = NSMutableDictionary()
        operationQueue = OperationQueue()
        operationQueue?.maxConcurrentOperationCount = 3
        session = URLSession.init(configuration: configuration, delegate: self, delegateQueue: operationQueue)
        queueProgress = Progress()
        queueProgressHandler = progressHandler
        queueCompletionHandler = completionHandler
    }
    
    
    /**
     添加下载任务
     @param urlString 下载地址
     @param progressHandler 任务进度回调
     @param completionHandler 任务完成回调
     */
    func addTask(withURLString urlString: String, progressHandler: HTProgressHandler?, completionHandler: HTURLDownloadCompletionHandler?)
    {
        if urlString.isEmpty
        {
            return
        }
        let url = URL(string: urlString)
        guard url != nil else
        {
            completionHandler!(nil, nil, nil)
            return
        }
        let downloadTask = session?.downloadTask(with: url!)
        let taskInfo = NSMutableDictionary()
        guard downloadTask != nil else { return }
        taskInfo["Task"] = downloadTask
        guard progressHandler != nil else { return }
        taskInfo["ProgressHandler"] = progressHandler
        guard completionHandler != nil else { return }
        taskInfo["CompletionHandler"] = completionHandler
        myLock?.lock()
        let key = String(urlString.hashValue)
        self.tasks?[key] = taskInfo
        myLock?.unlock()
        //更新进度
        guard (queueProgress?.isCancelled)! else { return }
        queueProgress?.totalUnitCount += 1
        guard queueProgressHandler != nil else { return }
        queueProgressHandler!(queueProgress!)
        downloadTask?.resume()
    }
    
    /**
     添加下载任务
     @param urlString 下载地址
     @param completionHandler 任务完成回调
     */
    func addTask(withURLString urlString:String, completionHandler: HTURLDownloadCompletionHandler?)
    {
        self.addTask(withURLString: urlString, progressHandler: nil, completionHandler: completionHandler)
    }
    
    /**
     获取单个任务的进度
     @param urlString 下载地址
     @return Progress 任务完成进度
     */
    func getTaskProgress(withURLString urlString: String) -> Progress?
    {
        if urlString.isEmpty
        {
            return nil
        }
        let key = String(urlString.hashValue)
        myLock?.lock()
        let task = ((self.tasks?[key] as! NSDictionary)["Task"]) as! URLSessionTask
        myLock?.unlock()
        let progress = Progress.init(totalUnitCount: task.countOfBytesExpectedToReceive)
        progress.completedUnitCount = task.countOfBytesReceived
        return progress
    }

    /**
     重设单个任务的进度回调
     @param urlString 下载地址
     @param progressHandler 任务完成回调
     */
    func resetTaskProgressHandler(withURLString urlString: String, progressHandler: HTProgressHandler?)
    {
        if urlString.isEmpty
        {
            return;
        }
        let key = String(urlString.hashValue)
        myLock?.lock()
        let taskInfo = (self.tasks?[key] as! NSDictionary).mutableCopy()
        guard progressHandler != nil else
        {
            (taskInfo as! NSMutableDictionary).removeObject(forKey: "ProgressHandler")
            return
        }
        (taskInfo as! NSMutableDictionary)["ProgressHandler"] = progressHandler
        self.tasks?[key] = taskInfo
        myLock?.unlock()
    }

    /**
     取消单个任务
     @param urlString 下载地址
     */
    func cancelTask(withURLString urlString: String)
    {
        if urlString.isEmpty
        {
            return
        }
        myLock?.lock()
        let key = String(urlString.hashValue)
        let task = (self.tasks?[key] as! NSDictionary)["Task"] as! URLSessionTask
        task.cancel()
        myLock?.unlock()
    }
    
    /**
     继续单个任务
     @param urlString 下载地址
     */
    func resumeTask(withURLString urlString: String)
    {
        if urlString.isEmpty
        {
            return
        }
        myLock?.lock()
        let key = String(urlString.hashValue)
        let task = (self.tasks?[key] as! NSDictionary)["Task"] as! URLSessionTask
        task.resume()
        myLock?.unlock()
    }
    
    /**
     挂起单个任务
     @param urlString 下载地址
     */
    func suspendTask(withURLString urlString: String)
    {
        if urlString.isEmpty
        {
            return
        }
        myLock?.lock()
        let key = String(urlString.hashValue)
        let task = (self.tasks?[key] as! NSDictionary)["Task"] as! URLSessionTask
        task.suspend()
        myLock?.unlock()
    }
    
    /**
     清空队列
     */
    func clear()
    {
        myLock?.lock()
        tasks?.enumerateKeysAndObjects({ (id: Any, obj: Any, stop: UnsafeMutablePointer<ObjCBool>) in
            ((obj as! NSDictionary)["task"] as! URLSessionTask).cancel()
        })
        operationQueue?.cancelAllOperations()
        tasks?.removeAllObjects()
        myLock?.unlock()
        queueProgress?.completedUnitCount = 0
        queueProgress?.totalUnitCount = 0
        guard queueCompletionHandler != nil else { return }
        queueCompletionHandler!()
    }

    /**
     销毁队列，不能再添加任务
     */
    func tearDown()
    {
        self.clear()
        self.session?.invalidateAndCancel()
    }
    
    //MARK - URLSessionTaskDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        //didFinishDownloadingToURL已经回调完成了，所以此处无需处理完成，只要处理出错就可以了
        if error != nil
        {
            let key = String(describing: task.originalRequest?.url?.absoluteString.hashValue)
            myLock?.lock()
            let taskInfo = self.tasks?[key] as! NSDictionary?
            myLock?.unlock()
            guard taskInfo != nil else { return }
            let handler = taskInfo?["CompletionHandler"] as! HTURLDownloadCompletionHandler?
            guard handler != nil else { return }
            handler!(nil, task.response, error)
        }
    }
    
    //MARK - NSURLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        let key = String(describing: downloadTask.originalRequest?.url?.absoluteString.hashValue)
        myLock?.lock()
        let taskInfo = self.tasks?[key] as! NSDictionary?
        myLock?.unlock()
        guard taskInfo != nil else { return }
        let handler = taskInfo?["CompletionHandler"] as! HTURLDownloadCompletionHandler?
        guard handler != nil else { return }
        handler!(location, downloadTask.response, downloadTask.error)
        //更新队列进度
        guard (queueProgress?.isCancelled)! else { return }
        queueProgress?.completedUnitCount += 1
        //队列完成
        guard queueCompletionHandler != nil && queueProgress?.fractionCompleted == 1.0 else { return }
        queueCompletionHandler!()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        let key = String(describing: downloadTask.originalRequest?.url?.absoluteString.hashValue)
        myLock?.lock()
        let taskInfo = self.tasks?[key] as! NSDictionary?
        myLock?.unlock()
        guard taskInfo != nil else { return }
        let handler = taskInfo?["ProgressHandler"] as! HTProgressHandler?
        guard handler != nil else { return }
        let progress = Progress.init(totalUnitCount: totalBytesExpectedToWrite)
        progress.completedUnitCount = totalBytesWritten
        handler!(progress)
    }
}
