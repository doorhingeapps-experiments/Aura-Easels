//
// Aura Easels
// ResizingCursor.swift
//
// Created on 7/9/25
//
// Copyright ©2025 DoorHinge Apps.
//


import Foundation
import SwiftUI
#if targetEnvironment(macCatalyst)
import AppKit
#endif


extension View {
    func pointingHandCursor() -> some View {
        self.onHover { inside in
#if targetEnvironment(macCatalyst)
            if inside {
                NSCursor.crosshair.push()
            } else {
                NSCursor.pop()
            }
#endif
        }
    }
}

