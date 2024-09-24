//
//  TnTimerQueue.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 04/08/2021.
//

import Foundation

class TnTimerQueue: ObservableObject {
    private var timer : Timer?
    private var queue: DispatchQueue
    
    let name: String
    var handler: (() -> Void)? = nil
    var seconds: TimeInterval = 0
    var liveInSeconds: TimeInterval = 0
    var onStopped: (() -> Void)? = nil

    private var startTime: Date!

    init(name: String, handler: (() -> Void)? = nil, isSerial: Bool = true) {
        self.name = name
        self.handler = handler
        self.queue = isSerial ? DispatchQueue(label: name) : DispatchQueue(label: name, attributes: .concurrent)
        TnLogger.debug(name, "inited")
    }
    
    deinit {
        TnLogger.debug("TnTimerQueue", "deinit !")
        self.stop()
    }
    
    func isStarted() -> Bool {
        self.timer != nil
    }
    
    @objc private func _timerEntry() {
        if !isStarted() {
            return
        }
        
        if liveInSeconds > 0 {
            let duration = Date.now().timeIntervalSince(startTime)
            if duration >= liveInSeconds {
                self.stop()
                return
            }
        }
        
        queue.async {[self] in
            if isStarted() {
                self.timerEntry()
            }
        }
    }
    
    func timerEntry() {
        self.handler?()
    }
    
    func start(_ seconds: TimeInterval = 0, liveInSeconds: TimeInterval = 0, handler: (() -> Void)? = nil) {
        if isStarted() {
            return
        }        
        if seconds > 0 {
            self.seconds = seconds
        }
        if liveInSeconds > 0 {
            self.liveInSeconds = liveInSeconds
        }
        if handler != nil {
            self.handler = handler
        }
        
        startTime = Date.now()
        timer = Timer.scheduledTimer(timeInterval: self.seconds, target: self, selector: #selector(_timerEntry), userInfo: nil, repeats: true)
        TnLogger.debug(name, "started")
    }

    func stop()  {
        if isStarted() {
            self.timer!.invalidate()
            self.timer = nil
            TnLogger.debug(name, "stopped")
            
            self.onStopped?()
        }
    }
    
    func toggle()  {
        if isStarted() {
            self.stop()
        } else {
            self.start()
        }
    }
}
