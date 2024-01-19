//
//  Utilities.swift
//  BodyTracking-Example
//
//  Created by Grant Jarvis on 11/13/21.
//

import RealityKit
import RKUtilities
import simd
import UIKit

// MARK: - Alerts

public extension UIView {
    func showAlert(title: String, message: String) {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let mainWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        // arView.window is nil the way we have set up this example project.
        mainWindow.rootViewController?.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Coordinate Space Conversion

public extension ARView {
    func convertAVFoundationToScreenSpace(_ point: CGPoint) -> CGPoint {
        // Convert from normalized AVFoundation coordinates (0,0 top-left, 1,1 bottom-right)
        // to screen-space coordinates.
        if
            let arFrame = session.currentFrame,
            let interfaceOrientation = window?.windowScene?.interfaceOrientation
        {
            let transform = arFrame.displayTransform(for: interfaceOrientation, viewportSize: frame.size)
            let normalizedCenter = point.applying(transform)
            let center = normalizedCenter.applying(CGAffineTransform.identity.scaledBy(x: frame.width, y: frame.height))
            return center
        } else {
            return CGPoint()
        }
    }

    func convertScreenSpaceToAVFoundation(_ point: CGPoint) -> CGPoint? {
        // Convert to normalized pixel coordinates (0,0 top-left, 1,1 bottom-right)
        // from screen-space coordinates.
        guard
            let arFrame = session.currentFrame,
            let interfaceOrientation = window?.windowScene?.interfaceOrientation
        else { return nil }

        let inverseScaleTransform = CGAffineTransform.identity.scaledBy(x: frame.width, y: frame.height).inverted()
        let invertedDisplayTransform = arFrame.displayTransform(for: interfaceOrientation, viewportSize: frame.size).inverted()
        let unScaledPoint = point.applying(inverseScaleTransform)
        let normalizedCenter = unScaledPoint.applying(invertedDisplayTransform)
        return normalizedCenter
    }
}

// MARK: - SafeGuarding

internal extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - WeakCollection

//  Created by Vladislav Grigoryev on 27.05.2020.
//  Copyright © 2020 GORA Studio. https://gora.studio
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

@propertyWrapper
public struct WeakCollection<Value: AnyObject> {
    private var _wrappedValue: [Weak<Value>]

    public var wrappedValue: [Value] {
        get { _wrappedValue.lazy.compactMap { $0.get() } }
        set { _wrappedValue = newValue.map(Weak.init) }
    }

    public init(wrappedValue: [Value]) { _wrappedValue = wrappedValue.map(Weak.init) }

    public mutating func compact() { _wrappedValue = { _wrappedValue }() }
}

@propertyWrapper
public final class Weak<Object: AnyObject> {
    private weak var _wrappedValue: AnyObject?

    public var wrappedValue: Object? {
        get { _wrappedValue as? Object }
        set { _wrappedValue = newValue }
    }

    public init(_ object: Object) { _wrappedValue = object }

    public init(wrappedValue: Object?) { _wrappedValue = wrappedValue }

    public func get() -> Object? { wrappedValue }
}
