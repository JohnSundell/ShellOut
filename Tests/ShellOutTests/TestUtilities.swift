import Logging
import XCTest

func XCTAssertEqualAsync<T>(
    _ expression1: @autoclosure () async throws -> T,
    _ expression2: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async where T: Equatable {
    do {
        let expr1 = try await expression1()
        let expr2 = try await expression2()

        return XCTAssertEqual(expr1, expr2, message(), file: file, line: line)
    } catch {
        // Trick XCTest into behaving correctly for a thrown error.
        return XCTAssertEqual(try { () -> Bool in throw error }(), false, message(), file: file, line: line)
    }
}

func XCTAssertThrowsErrorAsync<ResultType>(
    _ expression: @autoclosure () async throws -> ResultType,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line,
    _ callback: Optional<(Error) -> Void> = nil
) async {
    do {
        _ = try await expression()
        XCTFail("Did not throw: \(message())", file: file, line: line)
    } catch {
        callback?(error)
    }
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = ProcessInfo.processInfo.environment["LOG_LEVEL"].flatMap { Logger.Level(rawValue: $0) } ?? .debug
        return handler
    }
    return true
}()


