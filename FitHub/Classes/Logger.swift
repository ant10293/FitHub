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
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                     .appendingPathComponent(fileName)
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


