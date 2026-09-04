// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "MediaMelon-AVPlayer-Google-IMA-SDK",

    platforms: [
        .iOS(.v15),
        .tvOS(.v15)
    ],

    products: [
        .library(
            name: "MediaMelon-AVPlayer-Google-IMA-SDK",
            targets: [
                "MediaMelon_AVPlayer_Google_IMA_SDK"
            ]
        )
    ],

    dependencies: [
        .package(
            url: "https://github.com/MediamelonSDK/mm-ios-qoe-sdk-ima",
            exact: "2.16.0"
        )
    ],

    targets: [
        .target(
            name: "MediaMelon_AVPlayer_Google_IMA_SDK",

            dependencies: [
                .product(
                    name: "MediaMelonIMA",
                    package: "mm-ios-qoe-sdk-ima"
                )
            ],

            path: "Source"
        )
    ]
)