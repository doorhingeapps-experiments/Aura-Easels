//
// Aura Easels
// ElementConstants.swift
//
// Created on 7/6/25
//
// Copyright ©2025 DoorHinge Apps.
//

import Foundation
import SwiftUI

struct ElementConstants {
    
    // MARK: - Text Element Constants
    static let textDefaultWidth: CGFloat = 200
    static let textDefaultHeight: CGFloat = 50
    static let textMaxWidth: CGFloat = 1000
    static let textMaxHeight: CGFloat = 1000
    
    // MARK: - Rectangle Element Constants
    static let rectangleDefaultWidth: CGFloat = 200
    static let rectangleDefaultHeight: CGFloat = 200
    static let rectangleMaxWidth: CGFloat = 1000
    static let rectangleMaxHeight: CGFloat = 1000
    
    // MARK: - Oval Element Constants
    static let ovalDefaultWidth: CGFloat = 200
    static let ovalDefaultHeight: CGFloat = 200
    static let ovalMaxWidth: CGFloat = 1000
    static let ovalMaxHeight: CGFloat = 1000
    
    // MARK: - Line Element Constants
    static let lineDefaultWidth: CGFloat = 400
    static let lineDefaultHeight: CGFloat = 40
    static let lineMaxWidth: CGFloat = 2000
    static let lineMaxHeight: CGFloat = 40
    
    // MARK: - Website Element Constants
    static let websiteDefaultWidth: CGFloat = 300
    static let websiteDefaultHeight: CGFloat = 225
    static let websiteMaxWidth: CGFloat = 1200
    static let websiteMaxHeight: CGFloat = 800
    
    // MARK: - Drawing Element Constants
    static let drawingDefaultWidth: CGFloat = 300
    static let drawingDefaultHeight: CGFloat = 300
    static let drawingMaxWidth: CGFloat = 1000
    static let drawingMaxHeight: CGFloat = 1000
    
    // MARK: - Image Element Constants
    static let imageDefaultWidth: CGFloat = 300
    static let imageDefaultHeight: CGFloat = 300
    static let imageMaxWidth: CGFloat = 1000
    static let imageMaxHeight: CGFloat = 1000
    
    // MARK: - Universal Constants
    static let minWidth: CGFloat = 50
    static let minHeight: CGFloat = 50
    
    // MARK: - Helper Methods
    static func defaultSize(for type: ElementType) -> CGSize {
        switch type {
        case .text:
            return CGSize(width: textDefaultWidth, height: textDefaultHeight)
        case .rectangle:
            return CGSize(width: rectangleDefaultWidth, height: rectangleDefaultHeight)
        case .oval:
            return CGSize(width: ovalDefaultWidth, height: ovalDefaultHeight)
        case .line:
            return CGSize(width: lineDefaultWidth, height: lineDefaultHeight)
        case .website:
            return CGSize(width: websiteDefaultWidth, height: websiteDefaultHeight)
        case .drawing:
            return CGSize(width: drawingDefaultWidth, height: drawingDefaultHeight)
        case .image:
            return CGSize(width: imageDefaultWidth, height: imageDefaultHeight)
        }
    }
    
    static func maxSize(for type: ElementType) -> CGSize {
        switch type {
        case .text:
            return CGSize(width: textMaxWidth, height: textMaxHeight)
        case .rectangle:
            return CGSize(width: rectangleMaxWidth, height: rectangleMaxHeight)
        case .oval:
            return CGSize(width: ovalMaxWidth, height: ovalMaxHeight)
        case .line:
            return CGSize(width: lineMaxWidth, height: lineMaxHeight)
        case .website:
            return CGSize(width: websiteMaxWidth, height: websiteMaxHeight)
        case .drawing:
            return CGSize(width: drawingMaxWidth, height: drawingMaxHeight)
        case .image:
            return CGSize(width: imageMaxWidth, height: imageMaxHeight)
        }
    }
}
