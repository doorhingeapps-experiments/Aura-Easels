//
// Aura Easels
// Canvas Elements.swift
//
// Created on 7/5/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI

enum ElementType: Equatable {
    case text(String, TextStyleOptions)
    case rectangle
    case oval
    case line(Double)
    case website(String)
    case drawing
    case image(String)
}

struct CanvasElement: Identifiable, Equatable {
    let id = UUID()
    var name: String = "Untitled Canvas"
    var type: ElementType
    var position: CGPoint
    var size: CGSize
    var color: Color = .blue
}
