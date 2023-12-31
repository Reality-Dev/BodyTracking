//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/30/23.
//

import ARKit
import BTShared
import RealityKit
import Vision

public class HandAnchor: Entity, HasHandAnchoring {
    /// The underlying 2D hand tracker used to help determine the 3D joint transforms.
    public fileprivate(set) var handTracker2D: HandTracker2D

    @WeakCollection internal var handTrackers3D = [HandTracker3D]()

    /// The frequency that the Vision request for detecting hands will be performed.
    ///
    /// Running the request every frame may decrease performance.
    /// Can be reduced to increase performance at the cost of choppy tracking.
    /// Set to half to run every other frame. Set to quarter to run every 1 out of 4 frames.
    public static var requestRate: FrameRateRegulator.RequestRate {
        get {
            return HandDetector.shared.frameRateRegulator.requestRate
        }
        set {
            HandDetector.shared.frameRateRegulator.requestRate = newValue
        }
    }

    public internal(set) var handAnchorComponent: HandAnchorComponent {
        get {
            component(forType: HandAnchorComponent.self)!
        }
        set {
            components.set(newValue)
        }
    }

    public init(arView: ARView,
                depthBufferSelection: DepthBufferSelection? = nil)
    {
        handTracker2D = .init(arView: arView)

        HandTracking3DSystem.arView = arView

        super.init()

        anchoring = .init(.world(transform: float4x4.init(diagonal: .one)))

        // TODO: fix depth for non-LiDAR enabled devices.
        let depthBufferSelection = depthBufferSelection ?? (ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) ? .smoothedSceneDepth : .personSegmentationWithDepth)

        handAnchorComponent = .init(depthBufferSelection: depthBufferSelection)

        HandDetector.shared.frameRateRegulator.requestRate = .everyFrame
    }

    @MainActor required init() {
        fatalError("init() has not been implemented")
    }

    /// Attaches a `HandTracker3D` to this `HandAnchor` so that the `HandTracker3D`'s joint transforms will be updated based on the tracking data associated with this `HandAnchor`.
    /// - Parameters:
    ///   - handTracker: The entity that will be added for tracking.
    ///   - automaticallyAddChild: Set to true to add this entity as a child to the `HandAnchor`. If set to false, you can still add the `HandTracker3D` to the scene in some other way (such as to another anchor or anchor's descendant), and its joint transforms will be updated based on the tracking data associated with this `HandAnchor`.
    public func attach(handTracker: HandTracker3D,
                       automaticallyAddChild: Bool = true)
    {
        guard handTrackers3D.contains(where: { $0 == handTracker }) == false else {
            print("Already added HandTracker3D \(handTracker.name) to this HandAnchor")
            return
        }
        handTrackers3D.append(handTracker)

        if automaticallyAddChild { addChild(handTracker) }
    }

    public func destroy() {
        handTracker2D.destroy()

        handTrackers3D.forEach {
            $0.destroy()
        }

        removeFromParent()
    }
}
