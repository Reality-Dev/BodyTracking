//
//  File.swift
//  
//
//  Created by Grant Jarvis on 12/30/23.
//

import Foundation
import CoreVideo

public extension CVPixelBuffer {
    
    struct BufferPosition {
        var column: Int
        var row: Int
    }
    
    ///The input point must be in normalized AVFoundation coordinates. i.e. (0,0) is in the Top-Left, (1,1,) in the Bottom-Right.
    func value(from point: CGPoint) -> Float? {
        
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        
        let colPosition = Int(point.x * CGFloat(width))
        
        let rowPosition = Int(point.y * CGFloat(height))
        
        return value(column: colPosition, row: rowPosition)
    }
    
    func value(column: Int, row: Int) -> Float? {
        guard CVPixelBufferGetPixelFormatType(self) == kCVPixelFormatType_DepthFloat32 else { return nil }
        CVPixelBufferLockBaseAddress(self, .readOnly)
        if let baseAddress = CVPixelBufferGetBaseAddress(self) {
            let width = CVPixelBufferGetWidth(self)
            let index = column + (row * width)
            let offset = index * MemoryLayout<Float>.stride
            let value = baseAddress.load(fromByteOffset: offset, as: Float.self)
            CVPixelBufferUnlockBaseAddress(self, .readOnly)
            return value
        }
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        return nil
    }
    
    ///The input points must be in normalized AVFoundation coordinates. i.e. (0,0) is in the Top-Left, (1,1,) in the Bottom-Right.
    func values(from points: [CGPoint]) -> [Float]? {
        
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        
        let bufferPositions = points.map({
            let colPosition = Int($0.x * CGFloat(width))
            let rowPosition = Int($0.y * CGFloat(height))
            return BufferPosition(column: colPosition, row: rowPosition)
        })
        
        return values(from: bufferPositions)
    }
    
    func values(from positions: [BufferPosition]) -> [Float]? {
        guard CVPixelBufferGetPixelFormatType(self) == kCVPixelFormatType_DepthFloat32 else { return nil }
        
        CVPixelBufferLockBaseAddress(self, .readOnly)
        
        if let baseAddress = CVPixelBufferGetBaseAddress(self) {
            let width = CVPixelBufferGetWidth(self)
            
            let values = positions.map({
                let index = $0.column + ($0.row * width)
                let offset = index * MemoryLayout<Float>.stride
                return baseAddress.load(fromByteOffset: offset, as: Float.self)
            })

            CVPixelBufferUnlockBaseAddress(self, .readOnly)
            
            return values
        }
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        return nil
    }
}
