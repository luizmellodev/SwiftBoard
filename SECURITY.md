# Security Policy

## Supported Versions

SwiftBoard is pre-1.0. Only the latest minor release line gets fixes; upgrade to the newest tag before reporting.

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |
| < 0.1   | :x:                |

## Scope

SwiftBoard runs a local HTTP server inside your app, by default only in DEBUG builds. Things worth reporting:

- The server starting in a Release build without `SWIFTBOARD_ENABLE=1`.
- Custom actions (`addAction`) running for requests that do not come from the device itself.
- Reading files or data beyond the registered scenarios, or any path traversal through the server.
- Exported static sites (`StaticExporter`) containing more than the registered scenarios.

By design, the server listens on every network interface, so other devices on the same network can browse the board while the app runs (see *Network exposure* in the README). That alone is not a vulnerability.

## Reporting a Vulnerability

Please **do not open a public issue**. Report it privately through GitHub: go to the repository's **Security** tab and click **Report a vulnerability**.

Include the SwiftBoard version, platform (iOS / macOS, Simulator or device), and steps to reproduce.

What to expect:

- **Acknowledgement** within 7 days.
- **Assessment** (accepted or declined, with the reasoning) within 14 days.
- **If accepted:** a fix in a new patch release, credited to you in the release notes unless you prefer otherwise. Please keep the details private until that release is out.
- **If declined:** an explanation of why, and you are free to discuss it publicly.

This is a personal project maintained in spare time, so these are best-effort targets.
