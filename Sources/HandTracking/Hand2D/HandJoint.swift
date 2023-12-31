//
//  File.swift
//  
//
//  Created by Grant Jarvis on 12/31/23.
//

import ARKit

public enum HandJoint: String, CaseIterable {
    public typealias JointName = VNHumanHandPoseObservation.JointName
    
    case thumbTip, thumbIP, thumbMP, thumbCMC
    case indexTip, indexDIP, indexPIP, indexMCP
    case middleTip, middleDIP, middlePIP, middleMCP
    case ringTip, ringDIP, ringPIP, ringMCP
    case littleTip, littleDIP, littlePIP, littleMCP
    case wrist
    
    var name: JointName {
        return JointName.init(rawValue: .init(rawValue: rawValue))
    }
    
    // 21 total.
    public static let allHandJoints: [JointName] = [
        .thumbTip, .thumbIP, .thumbMP, .thumbCMC,
        .indexTip, .indexDIP, .indexPIP, .indexMCP,
        .middleTip, .middleDIP, .middlePIP, .middleMCP,
        .ringTip, .ringDIP, .ringPIP, .ringMCP,
        .littleTip, .littleDIP, .littlePIP, .littleMCP,
        .wrist
    ]
    
    public static let tipJoints: Set<JointName> = [
        .thumbTip, .indexTip, .middleTip, .ringTip, .littleTip
    ]
    
    public static let orientationTarget: [JointName : JointName] = [
        .thumbTip: .thumbIP,
        .thumbIP: .thumbTip,
        .thumbMP: .thumbIP,
        .thumbCMC: .thumbMP,
        .indexTip: .indexDIP,
        .indexDIP: .indexTip,
        .indexPIP: .indexDIP,
        .indexMCP: .indexPIP,
        .middleTip: .middleDIP,
        .middleDIP: .middleTip,
        .middlePIP: .middleDIP,
        .middleMCP: .middlePIP,
        .ringTip: .ringDIP,
        .ringDIP: .ringTip,
        .ringPIP: .ringDIP,
        .ringMCP: .ringPIP,
        .littleTip: .littleDIP,
        .littleDIP: .littleTip,
        .littlePIP: .littleDIP,
        .littleMCP: .littlePIP,
        .wrist: .middleMCP
    ]
}
