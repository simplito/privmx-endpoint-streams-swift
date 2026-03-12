// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "privmx-endpoint-streams-swift",
    platforms: [
        .macOS(.v14),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "PrivMXEndpointStreamsSwift",
            targets: ["PrivMXEndpointStreamsSwift"]),
	],
	dependencies:[
		.package(path: "../privmx-endpoint-swift"
			//url:"https://github.com/simplito/privmx-endpoint-swift",
				 //.upToNextMinor(from: .init(2, 7, 0))
				 ),
	],
    targets: [
        .target(
            name: "PrivMXEndpointStreamsSwift",
			dependencies: [.product(name: "PrivMXEndpointSwift", package: "privmx-endpoint-swift")],
            swiftSettings: [
				.interoperabilityMode(.Cxx),
						   ]
        ),
		.binaryTarget(
			name:"WebRTC",
			path: "../Frameworks/WebRTC.xcframework"
		),
	],
	cxxLanguageStandard: .cxx17
)
