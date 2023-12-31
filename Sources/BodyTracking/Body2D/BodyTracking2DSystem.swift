//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/30/23.
//

import ARKit
import BTShared
import Combine
import RealityKit
import UIKit

internal class BodyTracking2DSystem {
    static var shared = BodyTracking2DSystem()

    private var cancellableForUpdate: Cancellable?

    internal private(set) weak var arView: ARView?

    // Since BodyTracker2D is not an Entity and does not get added to the 3D scene, instead of querying the scene for the entities we keep weak references to them here.
    @WeakCollection var participatingTrackers = [BodyTracker2D]()

    internal func registerSystem(with arView: ARView) {
        self.arView = arView

        cancellableForUpdate?.cancel()

        cancellableForUpdate = arView.scene.subscribe(to: SceneEvents.Update.self, update)
    }

    internal func deregisterSystem() {
        cancellableForUpdate = nil

        participatingTrackers.removeAll()
    }

    private func update(_: SceneEvents.Update) {
        guard let currentFrame = arView?.session.currentFrame else { return }

        participatingTrackers.forEach { updateTracker($0, frame: currentFrame) }
    }

    // Run this code every frame to get the joints.
    private func updateTracker(_ tracker: BodyTracker2D,
                               frame: ARFrame)
    {
        updateJointScreenPositions(on: tracker, frame: frame)

        updateTrackedViews(on: tracker, frame: frame)
    }

    private func updateJointScreenPositions(on tracker: BodyTracker2D,
                                            frame: ARFrame)
    {
        /*
         BETA ISSUES: As of 07/23/2022:
         These have NOT yet been updated with the two new ear joints:
            ARSkeletonDefinition.defaultBody2D.jointCount
            ARSkeletonDefinition.defaultBody2D.jointNames
            ARSkeletonDefinition.defaultBody2D.jointNames.count
         But this HAS been updated with the two new ear joints:
            ARFrame.detectedBody.skeleton.jointLandmarks
         */

        let detectedBody = frame.detectedBody

        let frameDetectsBody = detectedBody != nil

        if tracker.body2D.bodyIsDetected != frameDetectsBody {
            tracker.body2D.bodyIsDetected = frameDetectsBody
        }

        guard
            let detectedBody,
            let arView,
            let interfaceOrientation = arView.window?.windowScene?.interfaceOrientation
        else { return }

        // TODO: better handle individual joints becoming undetected.
        let jointLandmarks = detectedBody.skeleton.jointLandmarks

        // Convert the normalized joint points into screen-space CGPoints.
        let displayTransform = frame.displayTransform(for: interfaceOrientation, viewportSize: arView.frame.size)

        for i in 0 ..< jointLandmarks.count {
            guard let screenPosition = screenPosition(for: jointLandmarks[i],
                                                      displayTransform: displayTransform)
            else { continue }

            if let joint = TwoDBodyJoint(rawValue: i) {
                tracker.body2D.jointScreenPositions[joint] = screenPosition
            }
        }
    }

    private func screenPosition(for jointLandmark: simd_float2,
                                displayTransform: CGAffineTransform) -> CGPoint?
    {
        if jointLandmark.x.isNaN || jointLandmark.y.isNaN {
            return nil
        }

        let point = CGPoint(x: CGFloat(jointLandmark.x),
                            y: CGFloat(jointLandmark.y))

        let normalizedCenter = point.applying(displayTransform)

        guard let frameSize = arView?.frame.size else { return nil }
        // Convert from normalized pixel coordinates (0,0 top-left, 1,1 bottom-right) to screen-space coordinates.
        let screenPoint = normalizedCenter.applying(CGAffineTransform.identity.scaledBy(x: frameSize.width, y: frameSize.height))

        return screenPoint
    }

    func updateTrackedViews(on tracker: BodyTracker2D,
                            frame: ARFrame)
    {
        guard frame.detectedBody != nil,
              tracker.body2D.jointScreenPositions.isEmpty == false
        else { return }

        for view in tracker.body2D.trackedViews {
            if let screenPosition = tracker.body2D.jointScreenPositions[view.key] {
                view.value.center = screenPosition
            }
        }
    }
}
