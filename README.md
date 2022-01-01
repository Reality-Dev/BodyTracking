# BodyTracking

This package includes classes that enable easy, convenient body tracking in RealityKit.

<p align="center">
  <img src="https://img.shields.io/github/v/release/Reality-Dev/BodyTracking?color=orange&display_name=tag&label=SwiftPM&logo=swift&style=plastic"/>
  <img src="https://img.shields.io/static/v1?label=platform&message=iOS&color=lightgrey&style=plastic"/>
  <img src="https://img.shields.io/static/v1?label=Swift&message=5.5&color=orange&style=plastic&logo=swift"/>
</p>

## What's Included

This package includes code for:
- 3D Body Tracking
- 2D Body Tracking
- 2D Hand Tracking
- 3D Face Tracking
- 3D Eye Tracking
- People Occlusion
- Loading a BodyTrackedEntity (for 3D character animation)


## Requirements

- iOS 13 or macOS 10.15
- Swift 5.2
- Xcode 11
- A12 Processor or later.

## Installation

### Swift Package Manager

Add the URL of this repository to your Xcode 11+ Project under:
    File > Add Packages
    `https://github.com/Reality-Dev/BodyTracking`

## Usage

Add `import BodyTracking` to the top of your swift file to start.

See the [example project](https://github.com/Reality-Dev/BodyTracking/tree/master/BodyTracking-Example) for guidance.


While using `BodyEntity3D` you can access the joint transforms relative to the root/hip joint each frame by using         `jointModelTransform(for:)`.
For example, you could find the right leg's transform like this:

``` swift
        jointModelTransform(for: .right_leg_joint)
```

## Support

If you have questions feel free to message me on [GitHub](https://github.com/Reality-Dev) or on [Twitter](https://twitter.com/GMJ4K)


## More

Pull Requests are welcome and encouraged.
