import Foundation

extension Process {
    
    static func makeBashProcess(withArguments arguments: [String]? = nil) -> Process {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = arguments
        return process
    }
    
    @discardableResult func launchBash(outputHandle: FileHandle? = nil, errorHandle: FileHandle? = nil) throws -> String {
        // Because FileHandle's readabilityHandler might be called from a
        // different queue from the calling queue, avoid a data race by
        // protecting reads and writes to outputData and errorData on
        // a single dispatch queue.
        let outputQueue = DispatchQueue(label: "bash-output-queue")
        
        var outputData = Data()
        var errorData = Data()
        
        let outputPipe = Pipe()
        standardOutput = outputPipe
        
        let errorPipe = Pipe()
        standardError = errorPipe
        
        #if !os(Linux)
        outputPipe.fileHandleForReading.readabilityHandler = { handler in
            outputQueue.async {
                let data = handler.availableData
                outputData.append(data)
                outputHandle?.write(data)
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handler in
            outputQueue.async {
                let data = handler.availableData
                errorData.append(data)
                errorHandle?.write(data)
            }
        }
        #endif
        
        launch()
        
        #if os(Linux)
        outputQueue.sync {
            outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        }
        #endif
        
        waitUntilExit()
        
        outputHandle?.closeFile()
        errorHandle?.closeFile()
        
        #if !os(Linux)
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        #endif
        
        // Block until all writes have occurred to outputData and errorData,
        // and then read the data back out.
        return try outputQueue.sync {
            if terminationStatus != 0 {
                throw ShellOutError(
                    terminationStatus: terminationStatus,
                    errorData: errorData,
                    outputData: outputData
                )
            }
            
            return outputData.shellOutput()
        }
    }
    
    func launchBash(withCompletion completion: @escaping Completion) {
        
        var outputData = Data()
        var errorData = Data()
        
        let outputPipe = Pipe()
        standardOutput = outputPipe
        
        let errorPipe = Pipe()
        standardError = errorPipe
        
        // Because FileHandle's readabilityHandler might be called from a
        // different queue from the calling queue, avoid a data race by
        // protecting reads and writes to outputData and errorData on
        // a single dispatch queue.
        let outputQueue = DispatchQueue(label: "bash-output-queue")
        
        #if !os(Linux)
        outputPipe.fileHandleForReading.readabilityHandler = { handler in
            outputQueue.async {
                let data = handler.availableData
                outputData.append(data)
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handler in
            outputQueue.async {
                let data = handler.availableData
                errorData.append(data)
            }
        }
        #endif
        
        launch()
        
        #if os(Linux)
        outputQueue.sync {
            outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        }
        #endif
        
        waitUntilExit()
        
        #if !os(Linux)
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        #endif
        
        do {
            // Block until all writes have occurred to outputData and errorData,
            // and then read the data back out.
            return try outputQueue.sync {
                if terminationStatus != 0 {
                    throw ShellOutError(
                        terminationStatus: terminationStatus,
                        errorData: errorData,
                        outputData: outputData
                    )
                }
                
                let value = outputData.shellOutput()
                
                DispatchQueue.main.async {
                    completion({return value})
                }
            }
        } catch {
            DispatchQueue.main.async {
                completion({throw error})
            }
        }
    }
}
