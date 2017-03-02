//
//  HTHTTPRequest.swift
//  HTNetworking
//
//  Created by heming on 17/2/24.
//  Copyright © 2017年 Mr.Tai. All rights reserved.
//

import Foundation

class HTHTTPRequest: NSObject
{
    /**
     添加请求
     @param baseURL 请求URL
     @param parameters 请求参数
     @param httpMethod 请求方法
     @param configurationHandler 额外配置回调
     @param completionHandler 完成回调
     @return NSURLSessionDataTask
     */
    func dataTask(withURL baseUrl: URL, parameters: String, httpMethod: HTTPMethod, configurationHandler: HTConfigurationHandler?, completionHandler: HTURLRequestCompletionHandler?) -> URLSessionDataTask?
    {
        if !baseUrl.absoluteString.isEmpty
        {
            completionHandler!(nil, nil, nil)
            return nil
        }
        switch httpMethod
        {
            case .HTTPMethodGET:
                var url = baseUrl
                if !parameters.isEmpty
                {
                    /*
                     let baseUrl = URL(string: "http://example.com/v1/")//http://example.com/v1/
                     URL(string: "foo", relativeTo: baseUrl)         //http://example.com/v1/foo
                     URL(string: "foo?bar=baz", relativeTo: baseUrl) //http://example.com/v1/foo?bar=baz
                     URL(string: "/foo", relativeTo: baseUrl)        //http://example.com/foo
                     URL(string: "foo/", relativeTo: baseUrl)        //http://example.com/v1/foo
                     URL(string: "/foo/", relativeTo: baseUrl)       //http://example.com/v1/foo/
                     URL(string: "http://example2.com/", relativeTo: baseUrl)//http://example2.com/
                     */
                    url = URL(string: parameters, relativeTo: baseUrl)!
                }
                let request = URLRequest(url: url)
                if configurationHandler != nil
                {
                    configurationHandler!(request)
                }
                let session = URLSession.shared
                let dataTask = session.dataTask(with: request, completionHandler:
                    completionHandler!)
                dataTask.resume()
                return dataTask
            case .HTTPMethodPOST:
                var request = URLRequest(url: baseUrl)
                request.httpMethod = "POST"
                if !parameters.isEmpty
                {
                    request.httpBody = parameters.data(using: String.Encoding.utf8)
                }
                if configurationHandler != nil
                {
                    configurationHandler!(request)
                }
                let dataTask = URLSession.shared.dataTask(with: request, completionHandler: completionHandler!)
                dataTask.resume()
                return dataTask
            default:
                let error = NSError.init(domain: "wwww.baidu", code: 0, userInfo: [NSLocalizedDescriptionKey:"HTTP Method 不支持"])
                completionHandler!(nil, nil, error)
                return nil
        }
    }
    
    /**
     添加请求
     @param baseURL 请求URL
     @param parameters 请求参数
     @param httpMethod 请求方法
     @param completionHandler 完成回调
     @return NSURLSessionDataTask
     */
    func dataTask(withURL baseUrl: URL, parameters: String, httpMethod: HTTPMethod, completionHandler: HTURLRequestCompletionHandler?) -> URLSessionDataTask?
    {
        return self.dataTask(withURL: baseUrl, parameters: parameters, httpMethod: httpMethod, configurationHandler: nil, completionHandler: completionHandler)
    }
    
    /**
     添加POST请求到服务器指定地址
     @param url 指定地址
     @param parameters 参数
     @param configurationHandler 额外配置回调
     @param completionHandler 完成回调
     @return NSURLSessionDataTask
     */
    func postToBaseURL(withURL url: URL, parameters: String, configurationHandler: HTConfigurationHandler?, completionHandler: HTURLRequestCompletionHandler?) -> URLSessionDataTask?
    {
        let request = HTNetworkConfiguration.getConfiguredPostRequest(url: url, parameters: parameters)
        if request != nil
        {
            completionHandler!(nil, nil, nil);
            return nil
        }
        if configurationHandler != nil
        {
            configurationHandler!(request!)
        }
        let configuration = HTNetworkConfiguration.getSessionConfiguration()
        let session = URLSession(configuration: configuration)
        let dataTask = session.dataTask(with: request!, completionHandler: completionHandler!)
        dataTask.resume()
        return dataTask;
    }
    
    /**
     添加POST请求到服务器
     @param parameters 请求参数
     @param configurationHandler 额外配置回调
     @param completionHandler 完成回调
     @return NSURLSessionDataTask
     */
    func postToBaseURL(withParameters parameters: String, configurationHandler: HTConfigurationHandler?, completionHandler: HTURLRequestCompletionHandler?) -> URLSessionDataTask?
    {
        let url = HTNetworkConfiguration.getDefaultURL()
        if !url.absoluteString.isEmpty
        {
            completionHandler!(nil, nil, nil)
            return nil
        }
        let request = HTNetworkConfiguration.getConfiguredPostRequest(url: url, parameters: parameters)
        if configurationHandler != nil
        {
            configurationHandler!(request!)
        }
        let configuration = HTNetworkConfiguration.getSessionConfiguration()
        let session = URLSession(configuration: configuration)
        let dataTask = session.dataTask(with: request!, completionHandler: completionHandler!)
        dataTask.resume()
        return dataTask;
    }
    
    /**
     添加POST请求到服务器
     @param parameters 请求参数
     @param completionHandler 完成回调
     @return NSURLSessionDataTask
     @see postToBaseURL(WithParameters:configuration:completionHandler:)
     */
    func postToBaseURL(withParameters parameters: String, completionHandler: HTURLRequestCompletionHandler?) -> URLSessionDataTask?
    {
        return self.postToBaseURL(withParameters: parameters, configurationHandler: nil, completionHandler: completionHandler)
    }
    
    /**
     * 任务开始
     */
    func resume(task: URLSessionTask)
    {
        task.resume()
    }
    
    /**
     * 任务取消
     */
    func cancel(task: URLSessionTask)
    {
        task.cancel()
    }
    
    /**
     * 任务挂起
     */
    func suspend(task: URLSessionTask)
    {
        task.suspend()
    }
}
