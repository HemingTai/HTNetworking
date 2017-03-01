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
    func dataTask(withURL baseUrl: URL, parameters: String, httpMethod: HTTPMethod, configurationHandler: HTConfigurationHandler?, completionHandler: HTURLRequestCompletionHandler?) -> URLSessionDataTask?
    {
        if !baseUrl.absoluteString.isEmpty
        {
            completionHandler(nil, nil, nil)
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
                let request = NSMutableURLRequest(url: url)
                if configurationHandler != nil
                {
                    configurationHandler!(request)
                }
                let dataTask = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
                dataTask.resume
                return dataTask
        default:
            return nil
        }
    }
    
    case HTTPMethodPOST: {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:baseURL];
    request.HTTPMethod = @"POST";
    
    if (parameters) {
    request.HTTPBody = [parameters dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if (configurationHandler) {
    configurationHandler (request);
    }
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request
    completionHandler:completionHandler];
    [dataTask resume];
    return dataTask;
    } break;
    
    default: {
    NSError *error = [NSError errorWithDomain:@"com.jsmcc"
    code:0
    userInfo:@{
    NSLocalizedDescriptionKey: @"HTTP Method 不支持"
    }];
    completionHandler (nil, nil, error);
    return nil;
    } break;
    }
    
    return nil;
    }
    
    + (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)baseURL
    parameters:(NSString *)parameters
    httpMethod:(HTTPMethod)method
    completionHandler:(URLRequestCompletionHandler)completionHandler
    {
    return [self dataTaskWithURL:baseURL
    parameters:parameters
    httpMethod:method
    configuration:nil
    completionHandler:completionHandler];
    }
    
    + (NSURLSessionDataTask *)postToBaseURLWithURL:(NSURL *)url
    parameters:(NSString *)parameters
    configuration:(ConfigurationHandler)configurationHandler
    completionHandler:(URLRequestCompletionHandler)completionHandler
    {
    NSMutableURLRequest *request =
    [HttpConfiguration getConfiguredPostRequestWithURL:url parameters:parameters];
    if (!request) {
    completionHandler(nil, nil, nil);
    return nil;
    }
    if (configurationHandler) {
    configurationHandler (request);
    }
    NSURLSessionConfiguration *configuration = [HttpConfiguration getSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *dataTask =
    [session dataTaskWithRequest:request completionHandler:completionHandler];
    [dataTask resume];
    return dataTask;
    }
    
    + (NSURLSessionDataTask *)postToBaseURLWithParameters:(NSString *)parameters
    configuration:(ConfigurationHandler)configurationHandler
    completionHandler:(URLRequestCompletionHandler)completionHandler
    {
    NSURL *url = [HttpConfiguration getBaseURL];
    if (!url) {
    completionHandler(nil, nil, nil);
    return nil;
    }
    NSMutableURLRequest *request =
    [HttpConfiguration getConfiguredPostRequestWithURL:url parameters:parameters];
    if (configurationHandler) {
    configurationHandler (request);
    }
    NSURLSessionConfiguration *configuration = [HttpConfiguration getSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *dataTask =
    [session dataTaskWithRequest:request completionHandler:completionHandler];
    [dataTask resume];
    return dataTask;
    }
    
    + (NSURLSessionDataTask *)postToBaseURLWithParameters:(NSString *)parameters
    completionHandler:(URLRequestCompletionHandler)completionHandler
    {
    return [self postToBaseURLWithParameters:parameters
    configuration:nil
    completionHandler:completionHandler];
    }
    
    + (void)cancel:(NSURLSessionTask *)task { [task cancel]; }
    
    + (void)resume:(NSURLSessionTask *)task { [task resume]; }
    
    + (void)suspend:(NSURLSessionTask *)task { [task suspend]; }
}
