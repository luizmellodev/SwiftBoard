import FlyingFox
import Foundation

/// Serves the site's static shell (HTML/CSS/JS) bundled as package resources.
enum StaticAssets {
    static func response(for filename: String) -> HTTPResponse {
        guard
            let url = bundleURL(for: filename),
            let data = try? Data(contentsOf: url)
        else {
            return HTTPResponse(statusCode: .notFound)
        }
        return HTTPResponse(statusCode: .ok, headers: [.contentType: contentType(for: filename)], body: data)
    }

    /// `.process("Resources")` flattens files to the bundle root, but check the subdirectory too
    /// in case a toolchain keeps the folder. Shared with `StaticExporter`.
    static func bundleURL(for filename: String) -> URL? {
        if let url = Bundle.module.url(forResource: filename, withExtension: nil) {
            return url
        }
        return Bundle.module.url(forResource: filename, withExtension: nil, subdirectory: "Resources")
    }

    private static func contentType(for filename: String) -> String {
        if filename.hasSuffix(".html") { return "text/html; charset=utf-8" }
        if filename.hasSuffix(".css") { return "text/css; charset=utf-8" }
        if filename.hasSuffix(".js") { return "application/javascript; charset=utf-8" }
        return "application/octet-stream"
    }
}
