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

        let url = URL(string: "https://api.douban.com/v2/book/1220562")
        let httpRequest = HTHTTPRequest()
        httpRequest.addTask(withURL: url!, completionHandler: { (data, response, error) in
            guard data != nil else { return }
            do
            {
                let dic = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves)
                print("dic:\(dic)")
            }catch{}
        })
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}

