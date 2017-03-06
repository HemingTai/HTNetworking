//
//  HTNetworkConfiguration.swift
//  HTNetworking
//
//  Created by heming on 17/2/23.
//  Copyright © 2017年 Mr.Tai. All rights reserved.
//

import Foundation

enum HTTPMethod
{
    case HTTPMethodGET
    case HTTPMethodPOST
}

typealias HTConfigurationHandler         = (_ request: URLRequest)->()
typealias HTProgressHandler              = (_ progress: Progress)->()
typealias HTQueueProgressHandler         = (_ progress: Progress)->()
typealias HTURLRequestCompletionHandler  = (_ data: Data?, _ response: URLResponse?, _ error: Error?)->()
typealias HTURLDownloadCompletionHandler = (_ location: URL?, _ response: URLResponse?, _ error: Error?)->()
typealias HTURLUploadCompletionHandler   = (_ data: Data?, _ response: URLResponse?, _ error: Error?)->()
typealias HTQueueCompletionHandler       = ()->()

class HTNetworkConfiguration: NSObject
{
    /**
     * 获取默认的请求地址（填写对应的服务端地址）
     * - Returns: 返回URL
     */
    class func getDefaultURL() -> URL
    {
        let defaultURLString = "https://www.douban.com/service/auth2/token"
        return URL(string: defaultURLString)!
    }
    
    /**
     * 获取session配置
     * - Returns: 返回session配置
     */
    class func getSessionConfiguration() -> URLSessionConfiguration
    {
        let configuration = URLSessionConfiguration.default
        //设置请求头
        let httpHeader = NSMutableDictionary()
        httpHeader.setValue("application/x-www-form-urlencoded; charset=UTF-8", forKey: "Content-Type")
        httpHeader.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:2.0.1) Gecko/20100101 Firefox/4.0.1", forKey: "User-Agent")
        httpHeader.setValue("iphone", forKey: "platform")
        configuration.httpAdditionalHeaders = httpHeader.copy() as? [AnyHashable : Any]
        return configuration
    }
    
    /**
     * 获取默认URLSession，未配置HTTPHeader
     * - Returns: 返回URLSession
     */
    class func getConfiguredURLSession(delegate: URLSessionDelegate, delegateQueue:OperationQueue) -> URLSession
    {
        let session = URLSession(configuration: self.getSessionConfiguration(), delegate: delegate, delegateQueue: delegateQueue)
        return session
    }
    
    /**
     * 获取默认PostRequest，未添加安全接口认证和防刷机制
     * - Returns: 返回URLRequest
     */
    class func getConfiguredPostRequest(url: URL, parameters: String) -> URLRequest?
    {
        if !url.absoluteString.isEmpty
        {
            var request = URLRequest(url: url)
            request.httpMethod = "POST";
            /**
             * 安全接口认证，主要设置：request.httpBody，可自行添加
             * 防刷机制相关，主要设置：request.setValue("xxx", forHTTPHeaderField: "xxx")，可自行添加
             */
            return request
        }
        return nil
    }
}
