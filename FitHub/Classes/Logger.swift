//
//  Logger.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/23/25.
//
import Foundation


enum LineBreakPosition { // call with `.before`, `.after`, `.none`
    case before, after, both, none
}

/// Captures a step-by-step transcript of each workout-plan run
final class Logger {
    static let shared = Logger()
    
    // MARK: – Formatters ----------------------------------------------------
    /// Local “normal time” for each line
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none      // just the time
        f.timeStyle = .medium     // “9:19 PM” / “21:19”
        return f
    }()
    
    /// ISO-8601 for filenames (keeps them sortable)
    private static let isoFormatter = ISO8601DateFormatter()
    
    // MARK: – Storage -------------------------------------------------------
    private var lines: [String] = []
    private init() {}
    
    // MARK: – Public API ----------------------------------------------------
    func add(_ message: String, timestamp: Bool = false, lineBreak: LineBreakPosition = .none, numLines: Int = 1, indentTabs: Int = 0) {
        var entry = ""

        switch lineBreak {
        case .before, .both: entry += String(repeating: "\n", count: numLines)
        default: break
        }

        if indentTabs > 0 {
            entry += String(repeating: "\t", count: indentTabs)
        }
        
        if timestamp {
            let stamp = Self.timeFormatter.string(from: Date())
            entry += "[\(stamp)] "
        }
        
        entry += message

        switch lineBreak {
        case .after, .both: entry += String(repeating: "\n", count: numLines)
        default: break
        }

        lines.append(entry)
    }
}

extension Logger {
    /// Documents/ + filename
    static func url(for fileName: String) -> URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            // Fallback to home directory if documents directory is unavailable
            return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(fileName)
        }
        return documentsURL.appendingPathComponent(fileName)
    }

    /// Flush the buffer and return the *filename* (not the URL).
    @discardableResult
    func flush() throws -> String {
        let fileName = "WorkoutGeneration-\(Self.isoFormatter.string(from: Date())).txt"
        let url      = Logger.url(for: fileName)

        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        lines.removeAll()
        return fileName            // ← store this in UserDefaults / CoreData
    }

    /// Delete by filename (convenience)
    static func deleteLog(named fileName: String) -> Bool {
        deleteLog(at: url(for: fileName))
    }

    /// Delete by URL (unchanged, but *private* now—you’ll rarely call it)
    @discardableResult
    private static func deleteLog(at url: URL) -> Bool {
        do    { try FileManager.default.removeItem(at: url); return true }
        catch { return false }
    }
}


import Foundation

extension Logger {
    // MARK: - Timing token
    struct TimingToken {
        let label: String
        let start: DispatchTime
        let indentTabs: Int
        let lineBreak: LineBreakPosition
        let numLines: Int
    }

    /// Begin a timed section. Pair with `end(_:)`.
    @discardableResult
    func start(_ label: String,
               indentTabs: Int = 0,
               lineBreak: LineBreakPosition = .none,
               numLines: Int = 1) -> TimingToken
    {
        TimingToken(
            label: label,
            start: .now(),
            indentTabs: indentTabs,
            lineBreak: lineBreak,
            numLines: numLines
        )
    }

    /// Finish a timed section and emit `⏱ label — N.nn ms`.
    func end(_ token: TimingToken,
             minMs: Double = 0,
             suffix: String? = nil,
             lineBreak: LineBreakPosition? = nil)
    {
        let end = DispatchTime.now()
        let ns  = Double(end.uptimeNanoseconds &- token.start.uptimeNanoseconds)
        let ms  = ns / 1_000_000.0
        guard ms >= minMs else { return }

        let tail = (suffix.map { " (\($0))" }) ?? ""
        let msg  = String(format: "⏱ %@ — %.1f ms%@", token.label, ms, tail)

        add(msg,
            timestamp: false,
            lineBreak: lineBreak ?? token.lineBreak,
            numLines: token.numLines,
            indentTabs: token.indentTabs)
    }

    /// Time a synchronous closure.
    @discardableResult
    func time<T>(_ label: String,
                 indentTabs: Int = 0,
                 minMs: Double = 0,
                 lineBreak: LineBreakPosition = .none,
                 numLines: Int = 1,
                 _ work: () -> T) -> T
    {
        let tok = start(label, indentTabs: indentTabs, lineBreak: lineBreak, numLines: numLines)
        let result = work()
        end(tok, minMs: minMs)
        return result
    }

    /// Time an async closure.
    @discardableResult
    func timeAsync<T>(_ label: String,
                      indentTabs: Int = 0,
                      minMs: Double = 0,
                      lineBreak: LineBreakPosition = .none,
                      numLines: Int = 1,
                      _ work: () async -> T) async -> T
    {
        let tok = start(label, indentTabs: indentTabs, lineBreak: lineBreak, numLines: numLines)
        let result = await work()
        end(tok, minMs: minMs)
        return result
    }

    // MARK: - RAII scope (auto-logs on scope exit)
    final class Scope {
        private let logger: Logger
        private let token: TimingToken
        private let minMs: Double
        private let suffix: () -> String?

        init(logger: Logger, token: TimingToken, minMs: Double, suffix: @escaping () -> String?) {
            self.logger = logger
            self.token  = token
            self.minMs  = minMs
            self.suffix = suffix
        }

        deinit {
            logger.end(token, minMs: minMs, suffix: suffix())
        }
    }

    /// Create a scope that ends automatically on `deinit`.
    func scope(_ label: String,
               indentTabs: Int = 0,
               minMs: Double = 0,
               lineBreak: LineBreakPosition = .none,
               numLines: Int = 1,
               suffix: @escaping () -> String? = { nil }) -> Scope
    {
        let tok = start(label, indentTabs: indentTabs, lineBreak: lineBreak, numLines: numLines)
        return Scope(logger: self, token: tok, minMs: minMs, suffix: suffix)
    }
}


