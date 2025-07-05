//
// Aura Easels
// TextStyleOptions.swift
//
// Created on 7/4/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI

struct TextStyleOptions: Equatable {
    var fontDesign: String
    var fontSize: CGFloat
    var fontweight: String
    var alignment: String
}

enum FontWeight {
    case regular
    case bold
}

struct TextStyleModifier: ViewModifier {
    let fontDesign: String
    let fontSize: CGFloat
    let fontWeight: String
    let alignment: String
    let verticalAlignment: String
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: toWeight(weight: fontWeight), design: toDesign(design: fontDesign)))
            .multilineTextAlignment(toAlignment(alignment: alignment))
    }
    
    func toWeight(weight: String) -> Font.Weight {
        if weight == "bold" {
            return .bold
        }
        else {
            return .regular
        }
    }
    
    func toDesign(design: String) -> Font.Design {
        if design == "rounded" {
            return .rounded
        }
        else if design == "monospaced" {
            return .monospaced
        }
        else if design == "serif" {
            return .serif
        }
        else {
            return .default
        }
    }
    
    func toAlignment(alignment: String) -> TextAlignment {
        if alignment == "center" {
            return .center
        }
        else if alignment == "trailing" {
            return .trailing
        }
        else {
            return .leading
        }
    }
}
