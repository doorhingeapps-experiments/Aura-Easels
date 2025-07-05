# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Aura Easels is an iOS canvas editor app built with SwiftUI that allows users to create and manipulate various visual elements on a scrollable canvas. The app supports text, shapes (rectangles, ovals, lines), and interactive website previews.

## Build and Development Commands

### Building the Project
```bash
xcodebuild -scheme "Aura Easels" -configuration Debug build
```

### Running the App
Open the project in Xcode and run using Cmd+R, or use:
```bash
xcodebuild -scheme "Aura Easels" -configuration Debug -destination "platform=iOS Simulator,name=iPhone 15 Pro" test
```

### Testing
The project uses Xcode's built-in testing framework. Run tests with:
```bash
xcodebuild -scheme "Aura Easels" test -destination "platform=iOS Simulator,name=iPhone 15 Pro"
```

## Architecture Overview

### Core Components

**ContentView.swift**: Main application view containing:
- Canvas state management (`elements` array of `CanvasElement`)
- Element selection and editing logic
- Drag and resize functionality
- Element creation buttons
- Website preview popover system

**ElementView.swift**: Individual element renderer that handles:
- Text elements with custom styling
- Shape elements (rectangles, ovals, lines)
- Website preview elements using LinkPresentation
- Interactive gestures (tap, drag)

**Canvas Elements.swift**: Data models defining:
- `ElementType` enum for different element types
- `CanvasElement` struct with position, size, color properties

**TextStyleOptions.swift**: Text styling system with:
- `TextStyleOptions` struct for font configuration
- `TextStyleModifier` for applying text styles
- Font weight, design, and alignment utilities

**LinkPresentation.swift**: Website preview functionality:
- `LinkPreview` UIViewRepresentable wrapper
- `TouchBlockingView` for gesture handling
- Link metadata fetching and display

### Key Design Patterns

1. **Element-Based Architecture**: All canvas items are represented as `CanvasElement` instances with unified properties
2. **Selection System**: Uses `selectedElement` state with visual overlay and resize handles
3. **Gesture Handling**: Separates drag gestures for movement vs. resize operations
4. **Dynamic Canvas**: ScrollView with calculated height based on element positions

### Canvas Element Types

- **Text**: Editable text with custom styling options
- **Rectangle**: Filled rectangular shapes
- **Oval**: Elliptical shapes
- **Line**: Rotatable line elements
- **Website**: Interactive link previews using LinkPresentation framework

### State Management

The app uses SwiftUI's `@State` for local view state management:
- `elements`: Array of all canvas elements
- `selectedElement`: Currently selected element for editing
- `dragOffset`: Temporary position offset during drag operations
- `isResizing`: Flag to distinguish between move and resize operations

## Development Notes

### Adding New Element Types
1. Add new case to `ElementType` enum in Canvas Elements.swift
2. Implement rendering logic in ElementView.swift switch statement
3. Add creation button in ContentView.swift HStack
4. Ensure proper gesture handling for the new element type

### Working with Text Elements
Text elements use a custom `TextStyleModifier` that converts string-based style properties to SwiftUI Font properties. The text editing system toggles between `Text` and `TextField` views based on `isEditingText` state.

### Website Preview Integration
Website elements use Apple's LinkPresentation framework wrapped in `LinkPreview` UIViewRepresentable. The preview system includes touch blocking to prevent unwanted interactions during canvas editing.

### Coordinate System
Canvas uses SwiftUI's coordinate system with position representing the center point of elements. Resize operations adjust both size and position to maintain visual consistency.