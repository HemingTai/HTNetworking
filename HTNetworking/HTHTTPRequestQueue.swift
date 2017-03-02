//
//  HTHTTPRequestQueue.swift
//  HTNetworking
//
//  Created by heming on 17/3/2.
//  Copyright © 2017年 Mr.Tai. All rights reserved.
//

import Foundation

class HTHTTPRequestQueue: NSObject, URLSessionDelegate
{
    //队列进度
    var queueProgress: Progress?
    //队列进度回调
    var queueProgressHandler: HTQueueProgressHandler?
    //队列完成回调
    var queueCompletionHandler: HTQueueCompletionHandler?
    
    var session: URLSession?
    var tasks: NSMutableDictionary?
    
    /**
     初始化
     */
    override init()
    {
        super.init()
        let configuration = HTNetworkConfiguration.getSessionConfiguration()
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
        queueProgress = Progress()
        tasks = NSMutableDictionary()
    }
    
    /**
     请求添加了请求头的配置信息，用来请求服务端
     @param progressHandler 队列进度回调
     @param completionHandler 队列完成回调
     */
    init(progressHandler: @escaping HTQueueProgressHandler, completionHandler: @escaping HTQueueCompletionHandler)
    {
        super.init()
        let configuration = HTNetworkConfiguration.getSessionConfiguration()
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
        queueProgress = Progress()
        tasks = NSMutableDictionary()
        queueProgressHandler = progressHandler
        queueCompletionHandler = completionHandler
    }
    
    /**
     添加请求
     @param parameters 参数
     @param method 请求方法
     @param comfigurationHandler 额外配置
     @param completionHandler 任务完成回调
     */
    func addTaskToBaseURL(withParameters parameters: String, httpMethod: HTTPMethod, configurationHandler: HTConfigurationHandler?, completionHandler: @escaping HTURLRequestCompletionHandler)
    {
        let baseURL = HTNetworkConfiguration.getDefaultURL()
        switch (httpMethod)
        {
            case .HTTPMethodGET:
                let url = URL(string: parameters, relativeTo: baseURL)
                if !(url?.absoluteString.isEmpty)!
                {
                    completionHandler(nil, nil, nil);
                    return ;
                }
                //Get请求未配置安全认证和防刷机制
                let request = URLRequest(url: url!)
                if configurationHandler != nil
                {
                    configurationHandler!(request);
                }
                let dataTask = session?.dataTask(with: request, completionHandler: { (data, response, error) in
                    if !(self.queueProgress?.isCancelled)!
                    {
                        self.queueProgress?.completedUnitCount += 1
                    }
                    //更新队列进度
                    if self.queueProgressHandler != nil
                    {
                        self.queueProgressHandler!(self.queueProgress!)
                    }
                    //队列完成
                    if self.queueCompletionHandler != nil && self.queueProgress?.fractionCompleted == 1.0
                    {
                        self.queueCompletionHandler!()
                    }
                    if !(self.queueProgress?.isCancelled)!
                    {
                        self.queueProgress?.totalUnitCount += 1
                    }
                })
                self.tasks?.setObject(dataTask! as URLSessionDataTask, forKey: String(parameters.hashValue) as NSCopying)
                dataTask?.resume()
            case .HTTPMethodPOST:
                let request = HTNetworkConfiguration.getConfiguredPostRequest(url: baseURL, parameters: parameters)
                if request != nil
                {
                    completionHandler(nil, nil, nil);
                    return ;
                }
                if configurationHandler != nil
                {
                    configurationHandler!(request!)
                }
                let dataTask = self.session?.dataTask(with: request!, completionHandler: { (data, response, error) in
                    if !(self.queueProgress?.isCancelled)!
                    {
                        self.queueProgress?.completedUnitCount += 1
                    }
                    //更新队列进度
                    if self.queueProgressHandler != nil
                    {
                        self.queueProgressHandler!(self.queueProgress!)
                    }
                    //队列完成
                    if self.queueCompletionHandler != nil && self.queueProgress?.fractionCompleted == 1.0
                    {
                        self.queueCompletionHandler!()
                    }
                })
                self.tasks?.setObject(dataTask! as URLSessionDataTask, forKey: String(parameters.hashValue) as NSCopying)
                dataTask?.resume()
            default:
                let error = NSError.init(domain: "wwww.baidu", code: 0, userInfo: [NSLocalizedDescriptionKey:"HTTP Method 不支持"])
                completionHandler(nil, nil, error)
        }
        //更新队列进度
        if self.queueProgressHandler != nil
        {
            self.queueProgressHandler!(self.queueProgress!);
        }
    }
    
    /**
     添加Post请求
     @param parameters 参数
     @param completionHandler 任务完成回调
     */
    func addPostTaskToBaseURL(withParameters parameters:String, completionHandler: @escaping HTURLRequestCompletionHandler)
    {
        self.addTaskToBaseURL(withParameters: parameters, httpMethod: .HTTPMethodPOST, configurationHandler:nil,  completionHandler: completionHandler)
    }
    
    /**
     取消单个任务，根据parameters来标识任务
     */
    func cancelTask(withParameters parameters:String)
    {
        if !parameters.isEmpty
        {
            let key = String(parameters.hashValue)
            let task = tasks?[key] as! URLSessionTask;
            task.cancel()
        }
    }
    
    /**
     清空队列
     */
    func clear()
    {
        tasks?.enumerateKeysAndObjects({ (key:Any, obj:Any, stop:UnsafeMutablePointer<ObjCBool>) in
            (obj as! URLSessionTask).cancel()
        })
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
        session?.invalidateAndCancel()
    }
}
