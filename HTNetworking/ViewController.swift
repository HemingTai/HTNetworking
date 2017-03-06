//
//  ViewController.swift
//  HTNetworking
//
//  Created by heming on 17/2/23.
//  Copyright © 2017年 Mr.Tai. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()

        let url = URL(string: "https://www.douban.com/service/auth2/auth")
        let httpRequest = HTHTTPRequest()
        httpRequest.getTask(withURL: url!, completionHandler: { (data, response, error) in
            guard data != nil else { return }
//            do
//            {
//                let dic = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves)
//                print("getDic:\(dic)")
//            }catch{}
        })
//        let params = ["client_id":"0b5405e19c58e4cc21fc11a4d50aae64",
//        "client_secret":"edfc4e395ef93375",
//        "redirect_uri":"https://www.example.com/back",
//        "grant_type":"authorization_code",
//        "code":"9b73a4248"]
        let params = "?client_id=0b5405e19c58e4cc21fc11a4d50aae64&client_secret=edfc4e395ef93375&redirect_uri=https://www.example.com/back&grant_type=authorization_code&code=9b73a4248"
        httpRequest.postTask(withParameters:params, configurationHandler: nil, completionHandler: { (data, response, error) in
            guard data != nil else { return }
            do
            {
                let dic = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves)
                print("postDic:\(dic)")
            }catch{}
        })
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}

