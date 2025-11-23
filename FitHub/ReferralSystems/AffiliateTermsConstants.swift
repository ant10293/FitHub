//
//  AffiliateTermsConstants.swift
//  FitHub
//
//  Service for affiliate program terms and conditions versioning
//  Fetches version directly from GitHub repository
//

import Foundation

struct AffiliateTermsConstants {
    /// GitHub raw content URL for the affiliate terms markdown file
    private static let githubRawURL = "https://raw.githubusercontent.com/ant10293/fithub-legal/main/affiliate-terms.md"
    
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        return URLSession(configuration: configuration)
    }()
    
    /// Fetches the current terms version from GitHub by parsing the `version` field
    /// from the markdown file's front matter
    /// Returns nil if unable to fetch (falls back to requiring acceptance)
    static func getCurrentVersion() async -> String? {
        guard let url = URL(string: githubRawURL) else {
            print("⚠️ Invalid GitHub URL for affiliate terms")
            return nil
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                print("⚠️ Failed to fetch affiliate terms from GitHub: invalid response")
                return nil
            }
            
            guard let content = String(data: data, encoding: .utf8) else {
                print("⚠️ Failed to decode affiliate terms content")
                return nil
            }
            
            // Parse YAML front matter to extract version
            return parseVersion(from: content)
            
        } catch {
            print("⚠️ Failed to fetch affiliate terms version from GitHub: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Parses the `version` field from YAML front matter
    /// Format: version: v1.0.1 or version: "v1.0.1"
    private static func parseVersion(from content: String) -> String? {
        // Find the front matter section (between --- markers)
        guard let frontMatterStart = content.range(of: "---"),
              let frontMatterEnd = content.range(of: "---", range: frontMatterStart.upperBound..<content.endIndex) else {
            print("⚠️ No front matter found in affiliate terms")
            return nil
        }
        
        let frontMatter = String(content[frontMatterStart.upperBound..<frontMatterEnd.lowerBound])
        
        // Look for version field
        let lines = frontMatter.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("version:") {
                // Extract the value (handles both quoted and unquoted)
                let value = trimmed
                    .replacingOccurrences(of: "version:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                
                // Validate it's a semantic version format (v1.0.1 or 1.0.1)
                if value.range(of: #"^v?\d+\.\d+\.\d+$"#, options: .regularExpression) != nil {
                    return value
                } else {
                    print("⚠️ Invalid version format: \(value)")
                    return nil
                }
            }
        }
        
        print("⚠️ version field not found in front matter")
        return nil
    }
}

