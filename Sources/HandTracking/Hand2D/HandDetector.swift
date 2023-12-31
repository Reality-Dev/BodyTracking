//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/30/23.
//

import ARKit
import BTShared
import RealityKit
import UIKit
import Vision

enum HandTrackingError: Error {
    case requestInFlight

    case frameRateRegulated

    case noHandsDetected
}

class HandDetector {
    internal static var shared = HandDetector()

    private var inFlight = false

    internal var frameRateRegulator = FrameRateRegulator()

    internal static let requestQueue = DispatchQueue(label: "pro.RealityAcademy.handTracking", qos: .userInteractive)

    /// You can track as many hands as you want, or set the maximumHandCount
    private var handPoseRequest = VNDetectHumanHandPoseRequest()

    init() {
        handPoseRequest.maximumHandCount = 1
    }

    internal func runFingerDetection(frame: ARFrame,
                                     handCount: Int) throws -> [VNHumanHandPoseObservation]
    {
        if handPoseRequest.maximumHandCount != handCount {
            handPoseRequest.maximumHandCount = handCount
        }

        guard frameRateRegulator.canContinue() else {
            throw HandTrackingError.frameRateRegulated
        }

        guard !inFlight else { throw HandTrackingError.requestInFlight }

        let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: .up, options: [:])

        inFlight = true
        
        do {
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([handPoseRequest])
            // Continue only when a hand was detected in the frame.
            // Since we set the maximumHandCount property of the request to 1, there will be at most one observation.
            guard let observations = handPoseRequest.results, observations.isEmpty == false else {
                throw HandTrackingError.noHandsDetected
            }

            inFlight = false

            return observations

        } catch {
            inFlight = false

            throw error
        }
    }
}
