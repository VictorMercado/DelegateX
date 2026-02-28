import Foundation

class CommandExecutor {
    var onOutput: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var onTermination: ((Int32) -> Void)?

    private var process: Process?

    func execute(command: CommandItem) {
        var finalCommand = command.template

        let sortedParams = command.parameters.sorted { $0.order < $1.order }

        for param in sortedParams {
            if let range = finalCommand.range(of: "{}") {
                finalCommand.replaceSubrange(range, with: param.value)
            }
        }

        let process = Process()
        self.process = process

        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", finalCommand]

        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: command.workingDirectory, isDirectory: &isDir), isDir.boolValue {
            process.currentDirectoryURL = URL(fileURLWithPath: command.workingDirectory)
        } else {
            // Fallback to home directory if invalid path
            process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path)
            DispatchQueue.main.async {
                self.onError?("Warning: Invalid working directory. Defaulting to Home.\n")
            }
        }

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.onOutput?(string)
                }
            }
        }

        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.onError?(string)
                }
            }
        }

        process.terminationHandler = { [weak self] p in
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async {
                self?.onTermination?(p.terminationStatus)
            }
        }

        do {
            try process.run()
        } catch {
            DispatchQueue.main.async {
                self.onError?("Failed to start process: \(error.localizedDescription)\n")
                self.onTermination?(-1)
            }
        }
    }

    func stop() {
        if let process = process, process.isRunning {
            process.terminate()
        }
    }
}
