//
//  HTHTTPRequest.swift
//  HTNetworking
//
//  Created by heming on 17/2/24.
//  Copyright © 2017年 Mr.Tai. All rights reserved.
//

import Foundation

class HTHTTPRequest
{
    func dataTaskWithURL(baseUrl: URL, parameters: String, httpMethod: HTTPMethod, configuration:@escaping(ConfigurationHandler), completionHandler: URLRequestCompletionHandler) -> URLSessionDataTask
    {
        if baseUrl.absoluteString.lengthOfBytes(using: <#T##String.Encoding#>)
        {
            
        }
    }
    
    + (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)baseURL
    parameters:(NSString *)parameters
    httpMethod:(HTTPMethod)method
    configuration:(ConfigurationHandler)configurationHandler
    completionHandler:(URLRequestCompletionHandler)completionHandler
    {
    if (!baseURL) {
    completionHandler(nil, nil, nil);
    return nil;
    }
    switch (method) {
    case HTTPMethodGET: {
    /*
     URL *baseURL = [URL URLWithString:@"http://example.com/v1/"];
     [NSURL URLWithString:@"foo" relativeToURL:baseURL];  // http://example.com/v1/foo
     [NSURL URLWithString:@"foo?bar=baz" relativeToURL:baseURL];  //
     http://example.com/v1/foo?bar=baz
     [NSURL URLWithString:@"/foo" relativeToURL:baseURL];  // http://example.com/foo
     [NSURL URLWithString:@"foo/" relativeToURL:baseURL];  // http://example.com/v1/foo
     [NSURL URLWithString:@"/foo/" relativeToURL:baseURL];  // http://example.com/foo/
     [NSURL URLWithString:@"http://example2.com/" relativeToURL:baseURL]; //
     http://example2.com/
     */
    NSURL *url = baseURL;
    if ([Utility isValidString:parameters]) {
    url = [NSURL URLWithString:parameters relativeToURL:baseURL];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    if (configurationHandler) {
    configurationHandler (request);
    }
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request
    completionHandler:completionHandler];
    [dataTask resume];
    return dataTask;
    } break;
    
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
