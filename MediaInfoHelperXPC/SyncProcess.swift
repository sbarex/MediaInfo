//
//  SyncProcess.swift
//  MediaInfo
//
//  Created by Sbarex on 07/03/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Foundation

func syncProcess() {
    let inflightSemaphore = DispatchSemaphore(value: 0)

    var status: Int32 = 0
    var output: String = ""
    var completed = false
    
    let task = Process()
    
    DispatchQueue.global(qos: .userInitiated).async {
        let pipe = Pipe()
        
        task.terminationHandler = { _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output1 = String(data: data, encoding: .utf8)!
            let status1 = task.terminationStatus
            
            status = status1
            output = output1
            completed = true
            
            inflightSemaphore.signal()
        }
        
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.arguments = arguments
        task.launchPath = command
        do {
            try task.run()
        } catch {
            status = -1
            output = error.localizedDescription
            completed = true
            inflightSemaphore.signal()
        }
    }
    
    let timeoutLimit: DispatchTime = .now() + 3
    
    if !Thread.isMainThread {
        let r = inflightSemaphore.wait(timeout: timeoutLimit)
        if r == .timedOut && !completed {
            status = -1
            output = "Timeout"
        }
        let _ = inflightSemaphore.wait(timeout: .distantFuture)
    } else {
        while inflightSemaphore.wait(timeout: .now()) == .timedOut {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0))
            if DispatchTime.now() >= timeoutLimit {
                if !completed {
                    status = -1
                    output = "Timeout"
                }
                break
            }
        }
    }
    
    if task.isRunning {
        task.terminate()
    }
    
    return (status: status, output: output)
}
