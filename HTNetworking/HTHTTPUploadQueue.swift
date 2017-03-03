//
//  HTHTTPUploadQueue.swift
//  HTNetworking
//
//  Created by heming on 17/3/3.
//  Copyright © 2017年 Mr.Tai. All rights reserved.
//

/**
 只支持单一配置(默认配置或者自定义配置)
 支持队列进度和单个任务进度
 支持重设单个任务进度回调(Table View Cell重用会用到)
 暂不支持断点续传
 */

import Foundation

class HTHTTPUploadQueue: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate
{
    //队列进度
    var queueProgress: Progress?
    //队列进度回调
    var queueProgressHandler: HTQueueProgressHandler?
    //队列完成回调
    var queueCompletionHandler: HTQueueCompletionHandler?
    
    var session: URLSession?
    var tasks: NSMutableDictionary?
    var operationQueue: OperationQueue?
    
    /**
     初始化，默认配置
     */
    override init()
    {
        _ = HTHTTPUploadQueue(URLSessionConfiguration: URLSessionConfiguration.default)
    }
    
    /**
     初始化，自定义配置
     @param configuration NSURLSession配置
     */
    init(URLSessionConfiguration configuration: URLSessionConfiguration)
    {
        _ = HTHTTPUploadQueue(URLSessionConfiguration: configuration, progressHandler: nil, completionHandler: nil)
    }
    
    /**
     初始化，默认配置
     @param progressHandler 队列进度回调
     @param completionHandler 队列完成回调
     */
    init(queueProgressHandler progressHandler: HTQueueProgressHandler?, completionHandler: HTQueueCompletionHandler?)
    {
        _ = HTHTTPUploadQueue(URLSessionConfiguration: URLSessionConfiguration.default, progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    /**
     初始化，自定义配置
     @param configuration NSURLSession配置
     @param progressHandler 队列进度回调
     @param completionHandler 队列完成回调
     */
    init(URLSessionConfiguration configuration: URLSessionConfiguration, progressHandler: HTProgressHandler?,
    completionHandler: HTQueueCompletionHandler?)
    {
        super.init()
        tasks = NSMutableDictionary()
        operationQueue = OperationQueue()
        operationQueue?.maxConcurrentOperationCount = 3
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
        queueProgress = Progress()
        queueProgressHandler = progressHandler
        queueCompletionHandler = completionHandler
    }
    
    /**
     添加上传任务
     @param request 上传请求
     @param data 上传数据
     @param progressHandler 任务进度回调
     @param completionHandler 任务完成回调
     */
    func addTask(withURLRequest request: URLRequest?, uploadData data: Data, progressHandler: HTProgressHandler?, completionHandler: HTURLUploadCompletionHandler?)
    {
        if request == nil
        {
            return;
        }
        let uploadTask = session?.uploadTask(with: request!, from: data)
        let key = self.getTaskIdentify(withURLString: (request?.url?.absoluteString)!, data: data)
        let taskInfo = NSMutableDictionary()
        if uploadTask != nil
        {
            taskInfo["Task"] = uploadTask
        }
        if progressHandler != nil
        {
            taskInfo["ProgressHandler"] = progressHandler
        }
        if completionHandler != nil
        {
            taskInfo["CompletionHandler"] = completionHandler
        }
        tasks?[key] = taskInfo
        
        //更新进度
        if !(queueProgress?.isCancelled)!
        {
            queueProgress?.totalUnitCount += 1
        }
        if queueProgressHandler != nil
        {
            queueProgressHandler!(queueProgress!)
        }
        uploadTask?.resume()
    }
    
    /**
     添加上传任务
     @param urlString 上传地址
     @param data 上传数据
     @param configurationHandler 额外配置回调
     @param progressHandler 任务进度回调
     @param completionHandler 任务完成回调
     */
    func addTask(withURLString urlString: String, uploadData data: Data, configurationHandler: HTConfigurationHandler?, progressHandler: HTProgressHandler?, completionHandler: HTURLUploadCompletionHandler?)
    {
        if urlString.isEmpty
        {
            completionHandler!(nil, nil, nil);
            return
        }
        let request = URLRequest(url: URL(string: urlString)!)
        if configurationHandler != nil
        {
            configurationHandler!(request)
        }
        self.addTask(withURLRequest: request, uploadData: data, progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    /**
     添加上传任务
     @param urlString 上传地址
     @param data 上传数据
     @param progressHandler 任务进度回调
     @param completionHandler 任务完成回调
     */
    func addTask(withURLString urlString: String, uploadData data: Data, progressHandler: HTProgressHandler?,
    completionHandler: HTURLUploadCompletionHandler?)
    {
        self.addTask(withURLString: urlString, uploadData: data, configurationHandler: nil, progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    /**
     添加上传任务
     @param urlString 上传地址
     @param data 上传数据
     @param completionHandler 任务完成回调
     */
    func addTask(withURLString urlString: String, uploadData data: Data, completionHandler:HTURLUploadCompletionHandler?)
    {
        self.addTask(withURLString: urlString, uploadData: data, progressHandler: nil, completionHandler: completionHandler)
    }
    
    /**
     获取单个任务的进度
     @param urlString 上传地址
     @return Progress 任务完成进度
     */
    func getTaskProgress(withURLString urlString: String, uploadData data: Data) -> Progress?
    {
        if urlString.isEmpty
        {
            return nil
        }
        let key = self.getTaskIdentify(withURLString: urlString, data: data)
        let task = (tasks![key] as! NSDictionary)["Task"] as! URLSessionTask
        let progress = Progress(totalUnitCount: task.countOfBytesExpectedToSend)
        progress.completedUnitCount = task.countOfBytesSent
        return progress
    }
    
    /**
     重设单个任务的进度回调
     @param urlString 上传地址
     @param data 上传数据
     @param progressHandler 任务进度回调
     */
    func resetTaskProgressHandler(withURLString urlString: String, uploadData data: Data, progressHandler: HTProgressHandler?)
    {
        if urlString.isEmpty
        {
            return
        }
        let key = self.getTaskIdentify(withURLString: urlString, data: data)
        let taskInfo = (tasks?[key] as! NSDictionary).mutableCopy() as! NSMutableDictionary
        if progressHandler != nil
        {
            taskInfo["ProgressHandler"] = progressHandler
        }
        else
        {
            taskInfo.removeObject(forKey: "ProgressHandler")
        }
        tasks?[key] = taskInfo
    }
    
    /**
     取消单个任务
     @param urlString 上传地址
     @param data 上传数据
     */
    func cancelTask(withURLString urlString: String, uploadData data: Data)
    {
        if urlString.isEmpty
        {
            return
        }
        let key = self.getTaskIdentify(withURLString: urlString, data: data)
        let task = (self.tasks?[key] as! NSDictionary)["Task"] as! URLSessionTask
        task.cancel()
    }
    
    /**
     继续单个任务
     @param urlString 上传地址
     @param data 上传数据
     */
    func resumeTask(withURLString urlString: String, uploadData data: Data)
    {
        if urlString.isEmpty
        {
            return
        }
        let key = self.getTaskIdentify(withURLString: urlString, data: data)
        let task = (self.tasks?[key] as! NSDictionary)["Task"] as! URLSessionTask
        task.resume()
    }
    
    /**
     挂起单个任务
     @param urlString 上传地址
     @param data 上传数据
     */
    func suspendTask(withURLString urlString: String, uploadData data: Data)
    {
        if urlString.isEmpty
        {
            return
        }
        let key = self.getTaskIdentify(withURLString: urlString, data: data)
        let task = (self.tasks?[key] as! NSDictionary)["Task"] as! URLSessionTask
        task.suspend()
    }
    
    /**
     清空队列
     */
    func clear()
    {
        tasks?.enumerateKeysAndObjects({ (id: Any, obj: Any, stop: UnsafeMutablePointer<ObjCBool>) in
            ((obj as! NSDictionary)["task"] as! URLSessionTask).cancel()
        })
        operationQueue?.cancelAllOperations()
        tasks?.removeAllObjects()
        queueProgress?.completedUnitCount = 0
        queueProgress?.totalUnitCount = 0
        if queueCompletionHandler != nil
        {
            queueCompletionHandler!()
        }
    }
    
    /**
     销毁队列，不能再添加任务
     */
    func tearDown()
    {
        self.clear()
        self.session?.invalidateAndCancel()
    }
    
    /**
     通过urlString和上传data来作为唯一标识
     */
    func getTaskIdentify(withURLString urlString: String, data: Data) -> String
    {
        if urlString.isEmpty
        {
            return ""
        }
        return String(urlString.hashValue) + String(data.hashValue)
    }
    
    /**
     回调中找不到上传data，所以通过task来找到唯一标识
     */
    func getTaskIdentify(withTask task: URLSessionTask) -> String
    {
        var identify = ""
        tasks?.enumerateKeysAndObjects({ (key: Any, obj: Any, stop: UnsafeMutablePointer<ObjCBool>) in
            if ((obj as! NSDictionary)["task"] as! URLSessionTask).isEqual(task)
            {
                identify = key as! String
                stop.initialize(to: true)
            }
        })
        return identify
    }
    
    //MARK - NSURLSessionDataDelegate
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    {
        let key = self.getTaskIdentify(withTask: dataTask)
        let taskInfo = (tasks?[key] as! NSDictionary).mutableCopy() as! NSMutableDictionary
        taskInfo["ResponseData"] = data
        tasks?[key] = taskInfo
    }
    
    //MARK - NSURLSessionTaskDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        let key = self.getTaskIdentify(withTask: task)
        let taskInfo = tasks?[key] as! NSDictionary
        if taskInfo.count != 0
        {
            let handler = taskInfo["CompletionHandler"] as! HTURLUploadCompletionHandler?
            if handler != nil
            {
                handler!(taskInfo["ResponseData"] as? Data, task.response, error)
            }
            //更新队列进度
            if !(queueProgress?.isCancelled)!
            {
                queueProgress?.completedUnitCount += 1
            }
            //队列完成
            if queueCompletionHandler != nil && queueProgress?.fractionCompleted == 1.0
            {
                queueCompletionHandler!()
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
    {
        let key = self.getTaskIdentify(withTask: task)
        let taskInfo = tasks?[key] as! NSDictionary
        if taskInfo.count != 0
        {
            let handler = taskInfo["ProgressHandler"] as! HTProgressHandler?
            if handler != nil
            {
                let progress = Progress(totalUnitCount: totalBytesExpectedToSend)
                progress.completedUnitCount = totalBytesSent
                handler!(progress)
            }
        }
    }
}
