//
// Aura Easels
// Canvas Elements.swift
//
// Created on 7/5/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import SwiftData
import Foundation

@Model
class Canvas {
    @Attribute(.unique) var id: String
    var name: String
    @Relationship var elements: [CanvasElement]
    var createdAt: Date
    
    init(name: String) {
        self.id = UUID().uuidString
        self.name = name
        self.elements = []
        self.createdAt = Date()
    }
}

@Model
class CanvasElement {
    @Attribute(.unique) var id: String
    var name: String
    var elementType: String // Stored as string for SwiftData compatibility
    var textContent: String?
    var textStyle: TextStyleOptions?
    var lineRotation: Double?
    var websiteURL: String?
    var imageURL: String?
    var positionX: Double
    var positionY: Double
    var sizeWidth: Double
    var sizeHeight: Double
    var colorRed: Double
    var colorGreen: Double
    var colorBlue: Double
    var colorAlpha: Double
    var zOrder: Int
    var cornerRadius: Double
    
    init(type: ElementType, position: CGPoint, size: CGSize, color: Color) {
        self.id = UUID().uuidString
        self.name = "Untitled Element"
        self.positionX = position.x
        self.positionY = position.y
        self.sizeWidth = size.width
        self.sizeHeight = size.height
        
        // Convert Color to RGBA components
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.colorRed = red
        self.colorGreen = green
        self.colorBlue = blue
        self.colorAlpha = alpha
        self.zOrder = 0
        self.cornerRadius = 0
        
        // Set type-specific properties
        switch type {
        case .text(let content, let style):
            self.elementType = "text"
            self.textContent = content
            self.textStyle = style
        case .rectangle:
            self.elementType = "rectangle"
        case .oval:
            self.elementType = "oval"
        case .line(let rotation):
            self.elementType = "line"
            self.lineRotation = rotation
        case .website(let url):
            self.elementType = "website"
            self.websiteURL = url
        case .drawing:
            self.elementType = "drawing"
        case .image(let url):
            self.elementType = "image"
            self.imageURL = url
        }
    }
    
    // Computed properties for easier access
    var position: CGPoint {
        get { CGPoint(x: positionX, y: positionY) }
        set {
            positionX = newValue.x
            positionY = newValue.y
        }
    }
    
    var size: CGSize {
        get { CGSize(width: sizeWidth, height: sizeHeight) }
        set {
            sizeWidth = newValue.width
            sizeHeight = newValue.height
        }
    }
    
    var color: Color {
        get { Color(.sRGB, red: colorRed, green: colorGreen, blue: colorBlue, opacity: colorAlpha) }
        set {
            let uiColor = UIColor(newValue)
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            self.colorRed = red
            self.colorGreen = green
            self.colorBlue = blue
            self.colorAlpha = alpha
        }
    }
    
    var type: ElementType {
        get {
            switch elementType {
            case "text":
                return .text(textContent ?? "", textStyle ?? TextStyleOptions(fontDesign: "regular", fontSize: 16, fontweight: "regular", alignment: "leading"))
            case "rectangle":
                return .rectangle
            case "oval":
                return .oval
            case "line":
                return .line(lineRotation ?? 0)
            case "website":
                return .website(websiteURL ?? "")
            case "drawing":
                return .drawing
            case "image":
                return .image(imageURL ?? "")
            default:
                return .rectangle
            }
        }
        set {
            switch newValue {
            case .text(let content, let style):
                self.elementType = "text"
                self.textContent = content
                self.textStyle = style
            case .rectangle:
                self.elementType = "rectangle"
            case .oval:
                self.elementType = "oval"
            case .line(let rotation):
                self.elementType = "line"
                self.lineRotation = rotation
            case .website(let url):
                self.elementType = "website"
                self.websiteURL = url
            case .drawing:
                self.elementType = "drawing"
            case .image(let url):
                self.elementType = "image"
                self.imageURL = url
            }
        }
    }
}

enum ElementType: Equatable {
    case text(String, TextStyleOptions)
    case rectangle
    case oval
    case line(Double)
    case website(String)
    case drawing
    case image(String)
}
