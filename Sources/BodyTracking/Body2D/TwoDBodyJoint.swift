//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/30/23.
//

import Foundation

/*
 BETA ISSUES: As of 07/23/2022:
 These have NOT yet been updated with the two new ear joints:
    ARSkeletonDefinition.defaultBody2D.jointCount
    ARSkeletonDefinition.defaultBody2D.jointNames
    ARSkeletonDefinition.defaultBody2D.jointNames.count
 But this HAS been updated with the two new ear joints:
    ARFrame.detectedBody.skeleton.jointLandmarks
 */

/// ARSkeleton.JointName only contains 8 of these but this includes all of them :)
///
/// - Use TwoDBodyJoint.allCases to access an array of all joints
public enum TwoDBodyJoint: Int, CaseIterable {
    case head_joint = 0
    case neck_1_joint = 1
    case right_shoulder_1_joint = 2
    case right_forearm_joint = 3
    case right_hand_joint = 4
    case left_shoulder_1_joint = 5
    case left_forearm_joint = 6
    case left_hand_joint = 7
    case right_upLeg_joint = 8
    case right_leg_joint = 9
    case right_foot_joint = 10
    case left_upLeg_joint = 11
    case left_leg_joint = 12
    case left_foot_joint = 13
    case right_eye_joint = 14
    case left_eye_joint = 15
    case root = 16 // hips
    case right_ear_joint = 17
    case left_ear_joint = 18

    // Two new joints for the ears were added in iOS 16.0
    // CaseIterable does not work with `@available` applied to cases.

    public static var allCases: [TwoDBodyJoint] {
        if #available(iOS 16, *) {
            return [
                .head_joint,
                .neck_1_joint,
                .right_shoulder_1_joint,
                .right_forearm_joint,
                .right_hand_joint,
                .left_shoulder_1_joint,
                .left_forearm_joint,
                .left_hand_joint,
                .right_upLeg_joint,
                .right_leg_joint,
                .right_foot_joint,
                .left_upLeg_joint,
                .left_leg_joint,
                .left_foot_joint,
                .right_eye_joint,
                .left_eye_joint,
                .root, // hips
                .right_ear_joint,
                .left_ear_joint,
            ]
        } else {
            return [
                .head_joint,
                .neck_1_joint,
                .right_shoulder_1_joint,
                .right_forearm_joint,
                .right_hand_joint,
                .left_shoulder_1_joint,
                .left_forearm_joint,
                .left_hand_joint,
                .right_upLeg_joint,
                .right_leg_joint,
                .right_foot_joint,
                .left_upLeg_joint,
                .left_leg_joint,
                .left_foot_joint,
                .right_eye_joint,
                .left_eye_joint,
                .root, // hips
            ]
        }
    }
}
