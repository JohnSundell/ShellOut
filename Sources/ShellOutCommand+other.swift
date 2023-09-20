public extension ShellOutCommand {
    static func bash(arguments: [Argument]) -> Self {
        let arguments = arguments.first == "-c" ? Array(arguments.dropFirst()) : arguments
        return .init(command: "bash", arguments: ["-c", arguments.map(\.description).joined(separator: " ")])
    }
}


/// File system commands
public extension ShellOutCommand {
    /// Create a folder with a given name
    static func createFolder(named name: String) -> ShellOutCommand {
        .init(command: "mkdir", arguments: [name])
    }

    /// Create a file with a given name and contents (will overwrite any existing file with the same name)
    static func createFile(named name: String, contents: String) -> ShellOutCommand {
        .bash(arguments: ["-c", "echo \(contents.quoted) > \(name.quoted)".verbatim])
    }

    /// Move a file from one path to another
    static func moveFile(from originPath: String, to targetPath: String) -> ShellOutCommand {
        .init(command: "mv", arguments: [originPath, targetPath])
    }

    /// Copy a file from one path to another
    static func copyFile(from originPath: String, to targetPath: String) -> ShellOutCommand {
        .init(command: "cp", arguments: [originPath, targetPath])
    }

    /// Remove a file
    static func removeFile(from path: String, arguments: [String] = ["-f"]) -> ShellOutCommand {
        .init(command: "rm", arguments: arguments + [path])
    }

    /// Open a file using its designated application
    static func openFile(at path: String) -> ShellOutCommand {
        .init(command: "open", arguments: [path])
    }

    /// Read a file as a string
    static func readFile(at path: String) -> ShellOutCommand {
        .init(command: "cat", arguments: [path])
    }

    /// Create a symlink at a given path, to a given target
    static func createSymlink(to targetPath: String, at linkPath: String) -> ShellOutCommand {
        .init(command: "ln", arguments: ["-s", targetPath, linkPath])
    }

    /// Expand a symlink at a given path, returning its target path
    static func expandSymlink(at path: String) -> ShellOutCommand {
        .init(command: "readlink", arguments: [path])
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
        .init(command: "swift",
              arguments: ["package", "init", "--type", "\(type)"])
    }

    /// Update all Swift package dependencies
    static func updateSwiftPackages() -> ShellOutCommand {
        .init(command: "swift", arguments: ["package", "update"])
    }

    /// Build a Swift package using a given configuration (see SwiftBuildConfiguration for options)
    static func buildSwiftPackage(withConfiguration configuration: SwiftBuildConfiguration = .debug) -> ShellOutCommand {
        .init(command: "swift",
              arguments: ["build", "-c", "\(configuration)"])
    }

    /// Test a Swift package using a given configuration (see SwiftBuildConfiguration for options)
    static func testSwiftPackage(withConfiguration configuration: SwiftBuildConfiguration = .debug) -> ShellOutCommand {
        .init(command: "swift",
              arguments: ["test", "-c", "\(configuration)"])
    }
}
