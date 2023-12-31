//
//  HandTrackingSystem.swift
//  BodyTracking-Example
//
//  Created by Grant Jarvis on 4/29/22.
//

import ARKit
import BTShared
import Foundation
import RealityKit
import RKUtilities

internal class Hand2DSystem: System {
    required init(scene _: Scene) {}

    static var dependencies: [SystemDependency] {
        [.before(HandTracking3DSystem.self)]
    }

    internal private(set) weak static var arView: ARView?

    // RealityKit creates the instance of this System itself, so we use static properties.
    // Since HandTracker2D is not an Entity and does not get added to the 3D scene, instead of querying the scene for the entities we keep weak references to them here.
    @WeakCollection static var participatingTrackers = [HandTracker2D]()

    internal static func registerSystem(with arView: ARView) {
        self.arView = arView
        registerSystem()
    }

    // TODO: Throw an error if more hands added than are supported.
    func update(context _: SceneUpdateContext) {
        guard let currentFrame = Self.arView?.session.currentFrame else { return }

        // Perform the request in a separate dispatch queue to prevent blocking the main thread (including the camera feed).
        // Using `Task(priority:)` and `await` stalled the camera feed when multiple hands were present in the frame. Different priority levels were tested and none were acceptable.
        HandDetector.requestQueue.async {
            defer {
                DispatchQueue.main.async {
                    // Position values can interpolate even on frames that throw an error.
                    Self.participatingTrackers.forEach {
                        self.updateTrackedViews(on: $0, frame: currentFrame)
                    }
                }
            }

            do {
                let observations = try HandDetector.shared.runFingerDetection(frame: currentFrame,
                                                                              handCount: Self.participatingTrackers.count)
                DispatchQueue.main.async {
                    self.handleObservations(observations, frame: currentFrame)
                }

            } catch (HandTrackingError.noHandsDetected) {
                Self.participatingTrackers.forEach {
                    if $0.hand2D.handIsRecognized.value { $0.hand2D.handIsRecognized.value = false }
                }

            } catch {}
        }
    }

    private func handleObservations(_ observations: [VNHumanHandPoseObservation],
                                    frame _: ARFrame)
    {
        // Using chirality does not work when the had flips around with the palm towards the camera.
        for (tracker, observation) in zip(Self.participatingTrackers, observations) {
            handleObservation(on: tracker, observation: observation)
        }
    }

    private func handleObservation(on tracker: HandTracker2D,
                                   observation: VNHumanHandPoseObservation)
    {
        guard let fingerPoints = try? observation.recognizedPoints(.all) else { return }

        var aboveConfidenceThreshold = false

        for point in fingerPoints {
            guard point.value.confidence > tracker.hand2D.confidenceThreshold else { continue }

            aboveConfidenceThreshold = true

            let cgPoint = CGPoint(x: point.value.x, y: point.value.y)

            let avPoint = cgPoint.convertVisionToAVFoundation()

            tracker.hand2D.jointAVFoundationPositions[point.key] = avPoint

            if let screenSpacePoint = Self.arView?.convertAVFoundationToScreenSpace(avPoint) {
                tracker.hand2D.jointScreenPositions[point.key] = screenSpacePoint
            }
        }

        if !aboveConfidenceThreshold {
            if tracker.hand2D.handIsRecognized.value {
                tracker.hand2D.handIsRecognized.value = false
            }
        } else {
            if tracker.hand2D.handIsRecognized.value == false {
                tracker.hand2D.handIsRecognized.value = true
            }
            if tracker.hand2D.handWasInitiallyIdentified.value == false {
                tracker.hand2D.handWasInitiallyIdentified.value = true
            }
        }
    }

    internal func updateTrackedViews(on tracker: HandTracker2D,
                                     frame _: ARFrame)
    {
        let hand2D = tracker.hand2D

        guard
            hand2D.jointScreenPositions.count > 0
        else { return }

        for view in hand2D.trackedViews {
            let jointIndex = view.key

            if let screenPosition = hand2D.jointScreenPositions[jointIndex] {
                switch HandDetector.shared.frameRateRegulator.requestRate {
                case .everyFrame:

                    view.value.center = screenPosition

                // Interpolate between where the view is and the target location.
                // We do not run the Vision request every frame, so we need to animate the view in between those frames.
                case .half, .quarter:

                    let viewCenter = view.value.center

                    let difference = screenPosition - viewCenter

                    view.value.center = viewCenter + (difference * 0.5)
                }
            }
        }
    }
}
