import Foundation

public enum Slug {
    public static func make(_ raw: String) -> String {
        let lowered = splitCamelCase(raw).lowercased()
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

    /// Inserts a boundary before an uppercase letter that follows a lowercase one, so
    /// "IconButton" and "Icon Button" produce the same slug.
    private static func splitCamelCase(_ raw: String) -> String {
        var result = ""
        var previous: Unicode.Scalar?
        for scalar in raw.unicodeScalars {
            if let previous, CharacterSet.lowercaseLetters.contains(previous), CharacterSet.uppercaseLetters.contains(scalar) {
                result.unicodeScalars.append(" ")
            }
            result.unicodeScalars.append(scalar)
            previous = scalar
        }
        return result
    }
}
