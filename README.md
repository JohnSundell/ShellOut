
# 🐚 ShellOut

Welcome to ShellOut, a simple package that enables you to easily “shell out” from a Swift script or command line tool.

Even though you can accomplish most of the tasks you need to do in native Swift code, sometimes you need to invoke the power of the command line from a script or tool - and this is exactly what ShellOut makes so simple.

## Usage

 Just call `shellOut()`, and specify what command you want to run, along with any arguments you want to pass:

```swift
let output = try shellOut(to: "echo", arguments: ["Hello world"])
print(output) // Hello world
```

In case of an error, ShellOut will automatically read `STDERR` and format it nicely into a typed Swift error:
```swift
do {
    try shellOut(to: "totally-invalid")
} catch {
    let error = error as! ShellOutError
    print(error.message) // Prints STDERR
    print(error.output) // Prints STDOUT
}
```

## Installation

### For scripts

- Install [Marathon](https://github.com/johnsundell/marathon).
- Add ShellOut to Marathon using `$ marathon add git@github.com:JohnSundell/ShellOut.git`.
- Alternatively, add `git@github.com:JohnSundell/ShellOut.git` to your `Marathonfile`.
- Write your script, then run it using `$ marathon run yourScript.swift`.

### For command line tools

- Add `.Package(url: "https://github.com/JohnSundell/ShellOut.git", majorVersion: 1)` to your `Package.swift` file.
- Update your packages using `$ swift package update`.

## Help, feedback or suggestions?

- [Open an issue](https://github.com/JohnSundell/ShellOut/issues/new) if you need help, if you found a bug, or if you want to discuss a feature request.
- [Open a PR](https://github.com/JohnSundell/ShellOut/pull/new/master) if you want to make some change to ShellOut.
- Contact [@johnsundell on Twitter](https://twitter.com/johnsundell) for discussions, news & announcements about ShellOut & other projects.
