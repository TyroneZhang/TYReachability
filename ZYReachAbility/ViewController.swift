//
//  ViewController.swift
//  ZYReachAbility
//
//  Created by Zhangyao on 18/4/2016.
//  Copyright © 2016 TZPT. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.networkChanged(_:)), name: kRealReachabilityStatusChanged, object: nil)
        NetworkObserver.shareInstance()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startPing(sender: AnyObject) {
        for _ in 0 ..< 10 {
            NetworkObserver.checkRealtimeNetwork { (isNetworkAvailable) in
                if isNetworkAvailable {
                    self.showErrorMessage("network is available")
                } else {
                    self.showErrorMessage("network is disable")
                }
            }
        }
    }
    
    internal func networkChanged(noti: NSNotification) {
        if let number = noti.object as? NSNumber {
            if number.boolValue {
                self.showErrorMessage("network recovered")
            } else {
                self.showErrorMessage("network  down")
            }
        }
    }
    
    private func showErrorMessage(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: { (action) in
            alert.dismissViewControllerAnimated(true, completion: nil)
        })
        alert.addAction(cancelAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

