//
//  NetworkObserver.swift
//  ZYReachAbility
//
//  Created by Zhangyao on 18/4/2016.
//  Copyright © 2016 TZPT. All rights reserved.
//

import UIKit

let kRealReachabilityStatusChanged = "kRealReachabilityStatusChanged"

class NetworkObserver: NSObject, SimplePingDelegate {
    
    typealias handler = (isNetworkAvailable: Bool) -> Void
    private var pinger: SimplePing?
    private var reachability: Reachability!
    private let hostName = "192.168.3.10"
    private var handlers: [handler] = []
    
    deinit {
        self.removeObserver(self, forKeyPath: kReachabilityChangedNotification)
    }
    
    class func shareInstance() -> NetworkObserver {
        dispatch_once(&Inner.token) {
            Inner.instane = NetworkObserver()
        }
        return Inner.instane!
    }
    
    class func checkRealtimeNetwork(pingResultHandler: handler)  {
        let instance = self.shareInstance()
        instance.handlers.append(pingResultHandler)
        let status = instance.reachability.currentReachabilityStatus()
        let isNetworkAvailable = status.rawValue == NotReachable.rawValue
        if isNetworkAvailable {
           shareInstance().handleAllPingResultHandlers(false)
        } else {
            shareInstance().initializeSimplePing()
        }
    }
    
    private struct Inner {
        static var instane: NetworkObserver?
        static var token: dispatch_once_t = 0
    }
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NetworkObserver.networkStatusChangedNotification), name: kReachabilityChangedNotification, object: nil)
        self.reachability = Reachability(hostName: self.hostName)
        self.reachability.startNotifier()
    }
    
//    public checkNetworkStatus()
    
    // MARK: - Private methods
    
    private func handleAllPingResultHandlers(isNetworkAvailable: Bool) {
        objc_sync_enter(self)
        for handler in self.handlers {
            handler(isNetworkAvailable: isNetworkAvailable)
        }
        self.handlers.removeAll()
        objc_sync_exit(self)
    }
    
    internal func networkStatusChangedNotification() {
        let status = self.reachability.currentReachabilityStatus()
        if status != NotReachable {
            self.initializeSimplePing()
        } else {
            self.pingFailed()
        }
    }
    
    private func initializeSimplePing() {
        if self.pinger == nil {
            self.pinger = SimplePing(hostName: self.hostName)
            self.pinger!.delegate = self
            self.pinger!.start()
            weak var weakSelf = self
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                weakSelf?.pingFailed()
            })
        }
    }
    
    private func pingFailed() {
        self.pinger!.stop()
        self.pinger = nil
        self.handleAllPingResultHandlers(false)
        NSNotificationCenter.defaultCenter().postNotificationName(kRealReachabilityStatusChanged, object: NSNumber(bool: false))
    }
    
    private func pingSuccessed() {
        self.pinger!.stop()
        self.pinger = nil
        self.handleAllPingResultHandlers(true)
        NSNotificationCenter.defaultCenter().postNotificationName(kRealReachabilityStatusChanged, object: NSNumber(bool: true))
    }
    
    // MARK: - SimplePingDelegate
    
    func simplePing(pinger: SimplePing!, didStartWithAddress address: NSData!) {
        pinger.sendPingWithData(NSData(base64EncodedString: "tyrone", options: NSDataBase64DecodingOptions(rawValue: 0)))
    }
    
    func simplePing(pinger: SimplePing!, didReceivePingResponsePacket packet: NSData!) {
        self.pingSuccessed()
    }
    
    func simplePing(pinger: SimplePing!, didFailToSendPacket packet: NSData!, error: NSError!) {
        self.pingFailed()
    }
    
    func simplePing(pinger: SimplePing!, didFailWithError error: NSError!) {
        self.pingFailed()
    }
}
