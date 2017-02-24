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
/*
 typedef void(^ConfigurationHandler)(NSMutableURLRequest *request);
 typedef void(^ProgressHandler)(NSProgress *progress);
 typedef void(^QueueProgressHandler)(NSProgress *progress);
 typedef void(^URLRequestCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);
 typedef void(^URLDownloadCompletionHandler)(NSURL *location, NSURLResponse *response, NSError *error);
 typedef void(^URLUploadCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);
 typedef void(^QueueCompletionHandler)(void);
 */
class HTNetworkConfiguration: NSObject
{
    /**
     * 获取默认的请求服务端的地址
     * - Returns: 返回URL
     */
    func getDefaultURL() -> NSURL
    {
        let defaultURLString = "https://www.baidu.com/service/action.dox"
        return NSURL(string: defaultURLString)!
    }
    
    /**
     * 获取session配置
     * - Returns: 返回session配置
     */
    func getSessionConfiguration() -> URLSessionConfiguration
    {
        let configuration = URLSessionConfiguration.default
        ///设置请求头
        let httpHeader = NSMutableDictionary()
        httpHeader.setValue("application/x-www-form-urlencoded; charset=UTF-8", forKey: "Content-Type")
        httpHeader.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:2.0.1) Gecko/20100101 Firefox/4.0.1", forKey: "User-Agent")
        httpHeader.setValue("iphone", forKey: "platform")
        configuration.httpAdditionalHeaders = httpHeader.copy() as? [AnyHashable : Any]
        return configuration
    }
    
    func getConfiguredURLSession(delegate: URLSessionDelegate, delegateQueue:OperationQueue) -> URLSession
    {
        let session = URLSession(configuration: self.getSessionConfiguration(), delegate: delegate, delegateQueue: delegateQueue)
        return session
    }
    
    func getConfiguredPostRequest(url: NSURL, parameters: String) -> NSMutableURLRequest
    {
        if url.absoluteString != nil
        {
            let request = NSMutableURLRequest(url: url as URL)
            request.httpMethod = "POST";
            
            /**
             * 安全接口认证，防刷机制相关,可自行添加，
             * 主要设置：request.setValue("xxx", forHTTPHeaderField: "xxx")
             */
            
            return request
        }
        return NSMutableURLRequest(url: URL(string: "")!)
    }
}
