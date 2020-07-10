// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let supportsCoreAudio: BuildSettingCondition = .when(platforms: [.iOS, .macOS, .tvOS, .watchOS])
let supportsALSA: BuildSettingCondition = .when(platforms: [.linux])

let package = Package(
    name: "portaudio",
    products: [
		.library(name: "libportaudio", targets: ["libportaudio"]),
        .library(name: "portaudio", targets: ["portaudio"]),
    ],
    dependencies: [
		
    ],
    targets: [
        .target(
            name: "libportaudio",
            dependencies: [],
			cSettings: [
				.define("PA_USE_COREAUDIO", supportsCoreAudio),
				.define("PA_USE_ALSA", supportsALSA)
		    ],
			linkerSettings: [
				.linkedLibrary("asound", supportsALSA),
				.linkedFramework("CoreAudio", supportsCoreAudio),
				.linkedFramework("CoreServices", supportsCoreAudio),
				.linkedFramework("CoreFoundation", supportsCoreAudio),
				.linkedFramework("AudioUnit", supportsCoreAudio),
				.linkedFramework("AudioToolbox", supportsCoreAudio)
			]),
        .target(
            name: "portaudio",
            dependencies: [
				"libportaudio"
			]),
        .testTarget(
            name: "portaudioTests",
            dependencies: ["portaudio"]),
    ]
)
