# BodyTracking

This package enables easy, convenient body tracking in RealityKit.

<p align="center">
  <img src="https://img.shields.io/github/v/release/Reality-Dev/BodyTracking?color=orange&display_name=tag&label=SwiftPM&logo=swift&style=plastic"/>
  <img src="https://img.shields.io/static/v1?label=platform&message=iOS&color=lightgrey&style=plastic"/>
  <img src="https://img.shields.io/static/v1?label=Swift&message=5.5&color=orange&style=plastic&logo=swift"/>
</p>

## Usage

Course coming soon that includes expert guidance and examples.

## What's Included

This package includes code for:
- 3D Body Tracking
- 2D Body Tracking
- 2D Hand Tracking
- 3D Hand Tracking
- 3D Face Tracking
- Face Geometry Morphing
- 3D Eye Tracking
- People Occlusion

For character animation, see [RKLoader](https://github.com/Reality-Dev/RealityKit-Asset-Loading)
``` swift
import RKLoader

var character: BodyTrackedEntity?

...

func loadCharacter {
        Task(priority: .userInitiated) { [weak self] in
            let character = try await RKLoader.loadBodyTrackedEntityAsync(named: "character")

            self?.character = character

            let bodyAnchor = AnchorEntity(.body)
            
            self?.scene.addAnchor(bodyAnchor)
            
            bodyAnchor.addChild(character)
        }
}
```

## Requirements

- iOS 15
- A12 Processor or later.
- Swift 5.5
- Xcode 11

## Installation

### Swift Package Manager

Add the URL of this repository to your Xcode 11+ Project under:
    File > Add Packages
    `https://github.com/Reality-Dev/BodyTracking`

## Support

If you have questions feel free to message me on [GitHub](https://github.com/Reality-Dev) or on [Twitter](https://twitter.com/GMJ4K)


## More

Pull Requests are welcome and encouraged.
