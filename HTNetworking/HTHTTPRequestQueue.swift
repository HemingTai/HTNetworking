//
//  HTHTTPRequestQueue.swift
//  HTNetworking
//
//  Created by heming on 17/3/2.
//  Copyright © 2017年 Mr.Tai. All rights reserved.
//

/************************************
 *只支持请求已设置请求头的服务端
 *不支持其他请求，其他请求请用HttpRequest
 ************************************/

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
        _ = HTHTTPRequestQueue()
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
                if (url?.absoluteString.isEmpty)!
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
    
    //MARK -----NSURLSessionDelegate-----
    /**
     *@Https     当客户端第一次发送请求的时候，服务器会返回一个包含公钥的受保护空间（也称为证书），当我们发送请求的时候，公钥会将请求加密再发送给服务器，服务器接到请求之后，用自带的私钥进行解密，如果正确再返回数据。
     *@abstract  只要访问的是HTTPS的路径就会调用，该方法的作用就是处理服务器返回的证书, 需要在该方法中告诉系统是否需要安装服务         器返回的证书
     *@param     session 请求的URLSession
     *@param     challenge  授权质问
     *@param     NSURLSessionAuthChallengeDisposition  处理证书策略的枚举
     *@param     NSURLCredential  授权
     *@param     completionHandler  回调block来告诉NSURLSession要怎么处理证书  第一个参数: 代表如何处理证书 第二个参数: 代表需要处理哪个证书
     */
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        /* 从服务器返回的受保护空间中拿到证书的类型并判断是否是服务器信任的证书
         * NSURLAuthenticationMethodServerTrust  服务器信任的证书
         */
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust
        {
            //根据服务器返回的受保护空间创建一个证书
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            /* 安装证书
             * NSURLSessionAuthChallengeUseCredential = 0, 使用（信任）证书
             * NSURLSessionAuthChallengePerformDefaultHandling = 1, 默认，忽略
             * NSURLSessionAuthChallengeCancelAuthenticationChallenge = 2, 取消
             * NSURLSessionAuthChallengeRejectProtectionSpace = 3, 这次取消，下次重试
             */
            completionHandler(.useCredential, credential)
        }
    }
}
