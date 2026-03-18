# PrivMX Endpoint Streams Swift

This repository contains the Streams Module for [PrivMX Endpoint Swift](https://github.com/simplito/privmx-endpoint-streams-swift), leveraging WebRTC library to provide End-to-End Encrypted Audio and Video communication. PrivMX is a privacy-focused platform designed to offer secure collaboration solutions by integrating robust encryption across various data types and communication methods. This project enables seamless integration of PrivMX’s encryption functionalities in Swift applications, preserving the security and performance of the original C++ library while making its capabilities accessible in the Swift ecosystem.

## About PrivMX

[PrivMX](https://privmx.dev) allows developers to build end-to-end encrypted apps used for communication. The Platform works according to privacy-by-design mindset, so all of our solutions are based on Zero-Knowledge architecture. This project extends PrivMX’s commitment to security by making its encryption features accessible to developers using Swift.

## Key Features

- End-to-End Encryption: Ensures that data is encrypted at the source and can only be decrypted by the intended recipient.
- Native C++ Library Integration: Leverages the performance and security of C++ while making it accessible in Swift applications.
- Cross-Platform Compatibility: Designed to support PrivMX on multiple operating systems and environments.
- Simple API: Easy-to-use interface for Swift developers without compromising security.
- Audio and Video: Send and receive E2E Encrypted audio and video via WebRTC. 

## Modules

PrivMX Endpoint Streams Swift is an extension of [`Privmx Endpoint Swift`](https://github.com/simplito/privmx-endpoint-swift). It additionally depends on WebRTC library and manages WebRTC connection and media server sessions.

This package implements:

1. RTC session handling, managing connections with the media server.
2. Stream and Track management for video conferences.
3. `PMXDesktopCapturer` implementation utilising ScreenCaptureKit.
4. [`PrivmxEndpointContainer`](https://docs.privmx.dev/docs/latest/reference/privmx-endpoint-swift-extra/core/privmx-endpoint-container) for managing global sessions.
5. Classes to simplify reading/writing to files using byte arrays and Swift [`FileHandle`](https://developer.apple.com/documentation/foundation/filehandle).


## Dependency Setup

To use this package, add it as a dependency in your Xcode project or in your `Package.swift` file.

### Xcode Integration

In Xcode, navigate to your Project Navigator, right-click, and select **Add Package Dependencies...**. Then, paste the following URL into the **Search or Enter Package URL** field:

```
https://github.com/simplito/privmx-endpoint-streams-swift
```

### Swift Package Manager

To add it directly to a Swift package, include this line in the `dependencies` array in your `Package.swift` file:

```swift
.package(
    url: "https://github.com/simplito/privmx-endpoint-streams-swift",
    .upToNextMinor(from: .init(2, 7, 0))
),
```

## Usage

For more details on PrivMX Platform, including setup guides and API reference, visit [PrivMX documentation](https://docs.privmx.dev).


## License Information

**PrivMX Endpoint Streams Swift**
Copyright © 2026 Simplito sp. z o.o.

This project is part of the PrivMX Platform (https://privmx.dev).
This software is Licensed under the MIT License.

PrivMX Endpoint and PrivMX Bridge are licensed under the [PrivMX Free License](https://github.com/simplito/privmx-endpoint).
See the License for the specific language governing permissions and limitations.
