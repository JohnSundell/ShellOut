import Foundation

/// Structure used to pre-define commands for use with ShellOut
public struct ShellOutCommand {
    /// The string that makes up the command that should be run on the command line
    public var string: String
    
    /// Initialize a value using a string that makes up the underlying command
    public init(string: String) {
        self.string = string
    }
}

/// Git commands
public extension ShellOutCommand {
    /// Initialize a git repository
    static func gitInit() -> ShellOutCommand {
        return ShellOutCommand(string: "git init")
    }
    
    /// Clone a git repository at a given URL
    static func gitClone(url: URL, to path: String? = nil) -> ShellOutCommand {
        var command = "git clone \(url.absoluteString)"
        path.map { command.append(argument: $0) }
        command.append(" --quiet")
        
        return ShellOutCommand(string: command)
    }
    
    /// Create a git commit with a given message (also adds all untracked file to the index)
    static func gitCommit(message: String) -> ShellOutCommand {
        var command = "git add . && git commit -a -m"
        command.append(argument: message)
        command.append(" --quiet")
        
        return ShellOutCommand(string: command)
    }
    
    /// Perform a git push
    static func gitPush(remote: String? = nil, branch: String? = nil) -> ShellOutCommand {
        var command = "git push"
        remote.map { command.append(argument: $0) }
        branch.map { command.append(argument: $0) }
        command.append(" --quiet")
        
        return ShellOutCommand(string: command)
    }
    
    /// Perform a git pull
    static func gitPull(remote: String? = nil, branch: String? = nil) -> ShellOutCommand {
        var command = "git pull"
        remote.map { command.append(argument: $0) }
        branch.map { command.append(argument: $0) }
        command.append(" --quiet")
        
        return ShellOutCommand(string: command)
    }
    
    /// Run a git submodule update
    static func gitSubmoduleUpdate(initializeIfNeeded: Bool = true, recursive: Bool = true) -> ShellOutCommand {
        var command = "git submodule update"
        
        if initializeIfNeeded {
            command.append(" --init")
        }
        
        if recursive {
            command.append(" --recursive")
        }
        
        command.append(" --quiet")
        return ShellOutCommand(string: command)
    }
    
    /// Checkout a given git branch
    static func gitCheckout(branch: String) -> ShellOutCommand {
        let command = "git checkout".appending(argument: branch)
            .appending(" --quiet")
        
        return ShellOutCommand(string: command)
    }
}

/// File system commands
public extension ShellOutCommand {
    /// Create a folder with a given name
    static func createFolder(named name: String) -> ShellOutCommand {
        let command = "mkdir".appending(argument: name)
        return ShellOutCommand(string: command)
    }
    
    /// Create a file with a given name and contents (will overwrite any existing file with the same name)
    static func createFile(named name: String, contents: String) -> ShellOutCommand {
        var command = "echo"
        command.append(argument: contents)
        command.append(" > ")
        command.append(argument: name)
        
        return ShellOutCommand(string: command)
    }
    
    /// Move a file from one path to another
    static func moveFile(from originPath: String, to targetPath: String) -> ShellOutCommand {
        let command = "mv".appending(argument: originPath)
            .appending(argument: targetPath)
        
        return ShellOutCommand(string: command)
    }
    
    /// Copy a file from one path to another
    static func copyFile(from originPath: String, to targetPath: String) -> ShellOutCommand {
        let command = "cp".appending(argument: originPath)
            .appending(argument: targetPath)
        
        return ShellOutCommand(string: command)
    }
    
    /// Remove a file
    static func removeFile(from path: String, arguments: [String] = ["-f"]) -> ShellOutCommand {
        let command = "rm".appending(arguments: arguments)
            .appending(argument: path)
        
        return ShellOutCommand(string: command)
    }
    
    /// Open a file using its designated application
    static func openFile(at path: String) -> ShellOutCommand {
        let command = "open".appending(argument: path)
        return ShellOutCommand(string: command)
    }
    
    /// Read a file as a string
    static func readFile(at path: String) -> ShellOutCommand {
        let command = "cat".appending(argument: path)
        return ShellOutCommand(string: command)
    }
    
    /// Create a symlink at a given path, to a given target
    static func createSymlink(to targetPath: String, at linkPath: String) -> ShellOutCommand {
        let command = "ln -s".appending(argument: targetPath)
            .appending(argument: linkPath)
        
        return ShellOutCommand(string: command)
    }
    
    /// Expand a symlink at a given path, returning its target path
    static func expandSymlink(at path: String) -> ShellOutCommand {
        let command = "readlink".appending(argument: path)
        return ShellOutCommand(string: command)
    }
}

/// Marathon commands
public extension ShellOutCommand {
    /// Run a Marathon Swift script
    static func runMarathonScript(at path: String, arguments: [String] = []) -> ShellOutCommand {
        let command = "marathon run".appending(argument: path)
            .appending(arguments: arguments)
        
        return ShellOutCommand(string: command)
    }
    
    /// Update all Swift packages managed by Marathon
    static func updateMarathonPackages() -> ShellOutCommand {
        return ShellOutCommand(string: "marathon update")
    }
}

/// Swift Package Manager commands
public extension ShellOutCommand {
    /// Enum defining available package types when using the Swift Package Manager
    enum SwiftPackageType: String {
        case library
        case executable
    }
    
    /// Enum defining available build configurations when using the Swift Package Manager
    enum SwiftBuildConfiguration: String {
        case debug
        case release
    }
    
    /// Create a Swift package with a given type (see SwiftPackageType for options)
    static func createSwiftPackage(withType type: SwiftPackageType = .library) -> ShellOutCommand {
        let command = "swift package init --type \(type.rawValue)"
        return ShellOutCommand(string: command)
    }
    
    /// Update all Swift package dependencies
    static func updateSwiftPackages() -> ShellOutCommand {
        return ShellOutCommand(string: "swift package update")
    }
    
    /// Generate an Xcode project for a Swift package
    static func generateSwiftPackageXcodeProject() -> ShellOutCommand {
        return ShellOutCommand(string: "swift package generate-xcodeproj")
    }
    
    /// Build a Swift package using a given configuration (see SwiftBuildConfiguration for options)
    static func buildSwiftPackage(withConfiguration configuration: SwiftBuildConfiguration = .debug) -> ShellOutCommand {
        return ShellOutCommand(string: "swift build -c \(configuration.rawValue)")
    }
    
    /// Test a Swift package using a given configuration (see SwiftBuildConfiguration for options)
    static func testSwiftPackage(withConfiguration configuration: SwiftBuildConfiguration = .debug) -> ShellOutCommand {
        return ShellOutCommand(string: "swift test -c \(configuration.rawValue)")
    }
}

/// Fastlane commands
public extension ShellOutCommand {
    /// Run Fastlane using a given lane
    static func runFastlane(usingLane lane: String) -> ShellOutCommand {
        let command = "fastlane".appending(argument: lane)
        return ShellOutCommand(string: command)
    }
}

/// CocoaPods commands
public extension ShellOutCommand {
    /// Update all CocoaPods dependencies
    static func updateCocoaPods() -> ShellOutCommand {
        return ShellOutCommand(string: "pod update")
    }
    
    /// Install all CocoaPods dependencies
    static func installCocoaPods() -> ShellOutCommand {
        return ShellOutCommand(string: "pod install")
    }
}
