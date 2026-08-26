import FlyingFox
import Foundation

/// Serves the site's static shell (HTML/CSS/JS) bundled as package resources.
enum StaticAssets {
    static func response(for filename: String) -> HTTPResponse {
        guard
            let url = Bundle.module.url(forResource: filename, withExtension: nil, subdirectory: "Resources"),
            let data = try? Data(contentsOf: url)
        else {
            return HTTPResponse(statusCode: .notFound)
        }
        return HTTPResponse(statusCode: .ok, headers: [.contentType: contentType(for: filename)], body: data)
    }

    private static func contentType(for filename: String) -> String {
        if filename.hasSuffix(".html") { return "text/html; charset=utf-8" }
        if filename.hasSuffix(".css") { return "text/css; charset=utf-8" }
        if filename.hasSuffix(".js") { return "application/javascript; charset=utf-8" }
        return "application/octet-stream"
    }
}
