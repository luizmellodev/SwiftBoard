import Foundation

public enum Slug {
    public static func make(_ raw: String) -> String {
        let lowered = raw.lowercased()
        var result = ""
        var lastWasSeparator = true
        for scalar in lowered.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                result.unicodeScalars.append(scalar)
                lastWasSeparator = false
            } else if !lastWasSeparator {
                result.append("-")
                lastWasSeparator = true
            }
        }
        while result.hasSuffix("-") {
            result.removeLast()
        }
        return result.isEmpty ? "item" : result
    }
}
