//
//  TnAsyncQueue.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 9/18/21.
//

import Foundation
import Foundation

class TnAsyncQueue {
    private var queue: DispatchQueue
    
    let name: String
    let handler: (() -> Void)?
    
    private var seconds: TimeInterval = 0
    private var liveInSeconds: TimeInterval = 0
    var onStopped: (() -> Void)? = nil
    
    private var isStarted = false

    private var startTime: Date!

    init(name: String, handler: (() -> Void)?, isSerial: Bool) {
        self.name = name
        self.handler = handler
        self.queue = isSerial ? DispatchQueue(label: name) : DispatchQueue(label: name, attributes: .concurrent)
    }
    
    deinit {
        TnLogger.debug("TnAsyncQueue", "deinit !")
        self.stop()
    }
    
    private func _timerEntry() {
        queue.async {[self] in
            if isStarted {
                self.timerEntry()
                
                // then, trigger the next timer
                if isStarted {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.seconds) {
                        self._timerEntry()
                    }
                }
            }
        }
    }
    
    func timerEntry() {
        self.handler?()
    }
    
    func start(_ seconds: TimeInterval, liveInSeconds: TimeInterval) throws {
        if isStarted {
            return
        }
        if seconds > 0 {
            self.seconds = seconds
        }
        if liveInSeconds > 0 {
            self.liveInSeconds = liveInSeconds
        }
        startTime = Date.now()
        
        // trigger stop
        if self.liveInSeconds > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + self.liveInSeconds) {
                self.stop()
            }
        }
        
        isStarted = true
        TnLogger.debug(name, "started")

        // start the first timer
        _timerEntry()
    }

    func stop()  {
        if isStarted {
            isStarted = false
            TnLogger.debug(name, "stopped")
            self.onStopped?()
        }
    }
    
    func toggle() throws {
        if isStarted {
            self.stop()
        } else {
            try self.start(0, liveInSeconds: 0)
        }
    }
}
