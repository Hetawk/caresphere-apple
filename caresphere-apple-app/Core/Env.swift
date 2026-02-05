import Foundation
import SwiftUI

/// Simple environment access helper for multiplatform Swift apps.
/// Reads from ProcessInfo.processInfo.environment at runtime.
/// For values you set in Xcode schemes, build settings, or an exported env, this will pick them up.
enum Env {
    static func string(_ key: String, default defaultValue: String? = nil) -> String? {
        if let val = ProcessInfo.processInfo.environment[key] {
            return val
        }
        return defaultValue
    }

    static func bool(_ key: String, default defaultValue: Bool = false) -> Bool {
        guard let s = string(key) else { return defaultValue }
        return ["1","true","yes","on"].contains(s.lowercased())
    }

    static func int(_ key: String, default defaultValue: Int? = nil) -> Int? {
        guard let s = string(key) else { return defaultValue }
        return Int(s)
    }
}

// SwiftUI preview helper example
@available(iOS 15.0, macOS 12.0, *)
struct EnvPreview_Previews: PreviewProvider {
    static var previews: some View {
        let api = Env.string("API_BASE_URL", default: "https://localhost") ?? ""
        return Text("API: \(api)")
            .padding()
    }
}
