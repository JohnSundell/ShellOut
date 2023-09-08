import Foundation


/// Git commands
public extension ShellOutCommand {
    /// Initialize a git repository
    static func gitInit() -> ShellOutCommand {
        .init(command: "git", arguments: ["init"])
    }

    /// Clone a git repository at a given URL
    static func gitClone(url: URL, to path: String? = nil, allowingPrompt: Bool = true, quiet: Bool = true) -> ShellOutCommand {
        var command = git(allowingPrompt: allowingPrompt)
            .appending(arguments: ["clone", url.absoluteString])

        path.map { command.append(argument: $0) }

        if quiet {
            command.append(argument: "--quiet")
        }

        return command
    }

    /// Create a git commit with a given message (also adds all untracked file to the index)
    static func gitCommit(message: String, allowingPrompt: Bool = true, quiet: Bool = true) -> ShellOutCommand {
        var command = git(allowingPrompt: allowingPrompt)
            .appending(arguments: ["commit", "-a", "-m", "\(message.quoted)"])

        if quiet {
            command.append(argument: "--quiet")
        }

        return command
    }

    /// Perform a git push
    static func gitPush(remote: String? = nil, branch: String? = nil, allowingPrompt: Bool = true, quiet: Bool = true) -> ShellOutCommand {
        var command = git(allowingPrompt: allowingPrompt)
            .appending(arguments: ["push"])
        remote.map { command.append(argument: $0) }
        branch.map { command.append(argument: $0) }

        if quiet {
            command.append(argument: "--quiet")
        }

        return command
    }

    /// Perform a git pull
    static func gitPull(remote: String? = nil, branch: String? = nil, allowingPrompt: Bool = true, quiet: Bool = true) -> ShellOutCommand {
        var command = git(allowingPrompt: allowingPrompt)
            .appending(arguments: ["pull"])
        remote.map { command.append(argument: $0) }
        branch.map { command.append(argument: $0) }

        if quiet {
            command.append(argument: "--quiet")
        }

        return command
    }

    /// Run a git submodule update
    static func gitSubmoduleUpdate(initializeIfNeeded: Bool = true, recursive: Bool = true, allowingPrompt: Bool = true, quiet: Bool = true) -> ShellOutCommand {
        var command = git(allowingPrompt: allowingPrompt)
            .appending(arguments: ["submodule update"])

        if initializeIfNeeded {
            command.append(argument: "--init")
        }

        if recursive {
            command.append(argument: "--recursive")
        }

        if quiet {
            command.append(argument: "--quiet")
        }

        return command
    }

    /// Checkout a given git branch
    static func gitCheckout(branch: String, quiet: Bool = true) -> ShellOutCommand {
        var command = ShellOutCommand(command: "git",
                                      arguments: ["checkout", branch])

        if quiet {
            command.append(argument: "--quiet")
        }

        return command
    }

    private static func git(allowingPrompt: Bool) -> Self {
        allowingPrompt
        ? .init(command: "git")
        : .init(command: "env",
                arguments: ["GIT_TERMINAL_PROMPT=0", "git"])

    }
}
