//
// Aura Easels
// ElementView.swift
//
// Created on 7/5/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import WebKit


struct ElementView: View {
    let element: CanvasElement
    let isSelected: Bool
    let isEditingText: Bool
    @Binding var editingText: String
    let dragOffset: CGSize
    let onSelect: () -> Void
    let onMultiSelect: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: (CGSize) -> Void
    let onTextSubmit: (String) -> Void
    let onColorChange: (Color) -> Void
    let onMoveToTop: () -> Void
    let onMoveToBottom: () -> Void
    let onDelete: () -> Void
    let onTextStyleChange: (TextStyleOptions) -> Void
    let onCornerRadiusChange: (Double) -> Void
    
    @State var finishedLoading = false
    
    @State private var linkPreviewSize: CGSize = .zero

    var body: some View {
        Group {
            switch element.type {
            case .text(let str, let style):
                if isEditingText {
                    TextField("", text: $editingText, onCommit: {
                        onTextSubmit(editingText)
                    })
                    .textFieldStyle(.plain)
                    .modifier(TextStyleModifier(fontDesign: style.fontDesign, fontSize: style.fontSize, fontWeight: style.fontweight, alignment: style.alignment, verticalAlignment: ""))
                    .foregroundColor(element.color)
                    .frame(width: element.size.width, height: element.size.height, alignment: .center)
                    .multilineTextAlignment(.center)
                    .overlay(alignment: .top) {
                        HStack(spacing: 12) {
                            if case .text(_, let currentStyle) = element.type {
                                // Font Design Toggle
                                Button(action: {
                                    let newDesign = nextFontDesign(currentStyle.fontDesign)
                                    let newStyle = TextStyleOptions(
                                        fontDesign: newDesign,
                                        fontSize: currentStyle.fontSize,
                                        fontweight: currentStyle.fontweight,
                                        alignment: currentStyle.alignment
                                    )
                                    onTextStyleChange(newStyle)
                                }) {
                                    Image(systemName: fontDesignIcon(for: currentStyle.fontDesign))
                                        .foregroundColor(.primary)
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                                
                                // Font Weight Toggle
                                Button(action: {
                                    let newStyle = TextStyleOptions(
                                        fontDesign: currentStyle.fontDesign,
                                        fontSize: currentStyle.fontSize,
                                        fontweight: currentStyle.fontweight == "bold" ? "regular" : "bold",
                                        alignment: currentStyle.alignment
                                    )
                                    onTextStyleChange(newStyle)
                                }) {
                                    Image(systemName: "bold")
                                        .foregroundColor(currentStyle.fontweight == "bold" ? .blue : .gray)
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                                
                                // Font Size Controls
                                Button(action: {
                                    let newSize = nextFontSize(currentStyle.fontSize, increase: false)
                                    let newStyle = TextStyleOptions(
                                        fontDesign: currentStyle.fontDesign,
                                        fontSize: newSize,
                                        fontweight: currentStyle.fontweight,
                                        alignment: currentStyle.alignment
                                    )
                                    onTextStyleChange(newStyle)
                                }) {
                                    Image(systemName: "minus.circle")
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                                
                                VStack(spacing: 2) {
                                    Text("\(Int(currentStyle.fontSize))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("pt")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                                
                                Button(action: {
                                    let newSize = nextFontSize(currentStyle.fontSize, increase: true)
                                    let newStyle = TextStyleOptions(
                                        fontDesign: currentStyle.fontDesign,
                                        fontSize: newSize,
                                        fontweight: currentStyle.fontweight,
                                        alignment: currentStyle.alignment
                                    )
                                    onTextStyleChange(newStyle)
                                }) {
                                    Image(systemName: "plus.circle")
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                                
                                // Alignment Controls
                                Button(action: {
                                    let newAlignment = currentStyle.alignment == "leading" ? "center" :
                                                      currentStyle.alignment == "center" ? "trailing" : "leading"
                                    let newStyle = TextStyleOptions(
                                        fontDesign: currentStyle.fontDesign,
                                        fontSize: currentStyle.fontSize,
                                        fontweight: currentStyle.fontweight,
                                        alignment: newAlignment
                                    )
                                    onTextStyleChange(newStyle)
                                }) {
                                    Image(systemName: alignmentIcon(for: currentStyle.alignment))
                                        .foregroundColor(.primary)
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .offset(y: -40)
                    }
                    .position(element.position)
                } else {
                    Text(str)
                        .modifier(TextStyleModifier(fontDesign: style.fontDesign, fontSize: style.fontSize, fontWeight: style.fontweight, alignment: style.alignment, verticalAlignment: ""))
                        .foregroundColor(element.color)
                        .frame(width: element.size.width, height: element.size.height, alignment: frameAlignment(for: style.alignment))
                        .background(content: {
                            Color.white.opacity(0.001)
                        })
                        .contentShape(Rectangle())
                        .contextMenu {
                            contextMenuItems
                        }
                        .position(element.position)
                        .offset(dragOffset)
                        .onTapGesture { onSelect() }
                        .onLongPressGesture(minimumDuration: 0.5) { onMultiSelect() }
                        .highPriorityGesture(drag)
                }

            case .rectangle:
                RoundedRectangle(cornerRadius: element.cornerRadius)
                    .fill(element.color)
                    .frame(width: element.size.width, height: element.size.height)
                    .background(content: {
                        Color.white.opacity(0.001)
                    })
                    .contentShape(Rectangle())
                    .contextMenu {
                        contextMenuItems
                    }
                    .position(element.position)
                    .offset(dragOffset)
                    .onTapGesture { onSelect() }
                    .onLongPressGesture(minimumDuration: 0.5) { onMultiSelect() }
                    .highPriorityGesture(drag)

            case .oval:
                Ellipse()
                    .fill(element.color)
                    .frame(width: element.size.width, height: element.size.height)
                    .background(content: {
                        Color.white.opacity(0.001)
                    })
                    .contentShape(Rectangle())
                    .contextMenu {
                        contextMenuItems
                    }
                    .position(element.position)
                    .offset(dragOffset)
                    .onTapGesture { onSelect() }
                    .onLongPressGesture(minimumDuration: 0.5) { onMultiSelect() }
                    .highPriorityGesture(drag)
            case .line(let rotation):
                RoundedRectangle(cornerRadius: 10)
                    .fill(element.color)
                    .frame(width: element.size.width, height: 2)
                    .background(content: {
                        Color.blue.opacity(0.001)
                    })
                    .frame(width: element.size.width, height: element.size.height)
                    .contentShape(Rectangle())
                    .contextMenu {
                        contextMenuItems
                    }
                    .position(element.position)
                    .offset(dragOffset)
                    .onTapGesture { onSelect() }
                    .onLongPressGesture(minimumDuration: 0.5) { onMultiSelect() }
                    .highPriorityGesture(drag)
            case .website(let url):
//                if finishedLoading {
//                    WebView(webPage)
//                        .frame(width: element.size.width, height: element.size.height)
//                        .position(element.position)
//                        .offset(dragOffset)
//                        .onTapGesture { onSelect() }
//                        .highPriorityGesture(drag)
//                }
//                else {
//                    Rectangle()
//                        .fill(Color.gray)
//                        .frame(width: element.size.width, height: element.size.height)
//                        .position(element.position)
//                        .offset(dragOffset)
//                        .onTapGesture { onSelect() }
//                        .highPriorityGesture(drag)
//                        .onAppear() {
//                            Task {
//                                await webPage.load(URLRequest(url: URL(string: url) ?? URL(string: "https://apple.com")!))
//                            }
//                            finishedLoading = true
//                        }
//                }
                if let linkURL = URL(string: url) {
                    //ZStack {
                        RoundedRectangle(cornerRadius: element.cornerRadius)
                            .fill(element.color.opacity(0.5))
                            .blur(radius: 10)
                            .frame(
                                width: element.size.width,
                                height: element.size.height
                            )
                            .zIndex(-1)
                            .position(element.position)
                            .offset(dragOffset)
                        
                        GeometryReader { geo in
                            let scale = calculateScale(
                                available: geo.size,
                                content: linkPreviewSize
                            )
                            
                            LinkPreview(
                                previewURL: linkURL,
                                measuredSize: $linkPreviewSize
                            )
                            .id(url) // Force recreation when URL changes
                            .clipShape(RoundedRectangle(cornerRadius: element.cornerRadius))
                            //.shadow(color: element.color.opacity(0.5), radius: 10, x: 0, y: 0)
                            .scaleEffect(scale, anchor: .center)
                            .frame(
                                width: geo.size.width,
                                height: geo.size.height
                            )
                        }//.zIndex(10)
                    //}
                    .frame(
                        width: element.size.width,
                        height: element.size.height
                    )
                    .background(content: {
                        Color.white.opacity(0.001)
                    })
                    .contentShape(Rectangle())
                    .contextMenu {
                        contextMenuItems
                    }
                    .position(element.position)
                    .offset(dragOffset)
                    .onTapGesture { onSelect() }
                    .onLongPressGesture(minimumDuration: 0.5) { onMultiSelect() }
                    .highPriorityGesture(drag)
                }
            case .drawing:
                EmptyView()
            case .image(_):
                EmptyView()
            }
        }
    }
    
    private func scaleFactor(size: CGSize, for availableSize: CGSize) -> CGFloat {
        // Adjust this if you want stricter minimums or maximums
        //let baseSize: CGFloat = 400  // UIKit's LPLinkView defaults to about this width
        let scaleX = availableSize.width / size.width
        let scaleY = availableSize.height / size.height
        return min(scaleX, scaleY, 1) // Prevent upscaling
    }
    
    private func calculateScale(
        available: CGSize,
        content: CGSize
    ) -> CGFloat {
        guard content.width > 0, content.height > 0 else { return 1 }
        // Compute the factor that makes content at least as big as available in both axes
        let fillRatio = max(available.width  / content.width,
                            available.height / content.height)
        // Never upscale: only downscale if fillRatio < 1
        return min(1, fillRatio)
    }


    private var drag: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in onDragChanged(value.translation) }
            .onEnded   { value in onDragEnded(value.translation) }
    }
    
    private func frameAlignment(for alignment: String) -> Alignment {
        switch alignment {
        case "center":
            return .center
        case "trailing":
            return .topTrailing
        default:
            return .topLeading
        }
    }
    
    private func alignmentIcon(for alignment: String) -> String {
        switch alignment {
        case "center":
            return "text.aligncenter"
        case "trailing":
            return "text.alignright"
        default:
            return "text.alignleft"
        }
    }
    
    private let fontSizes: [CGFloat] = [5, 6, 7, 8, 9, 10, 11, 12, 14, 16, 18, 20, 24, 32, 48, 64, 72, 96]
    
    private func nextFontSize(_ currentSize: CGFloat, increase: Bool) -> CGFloat {
        let closest = fontSizes.min { abs($0 - currentSize) < abs($1 - currentSize) } ?? currentSize
        guard let currentIndex = fontSizes.firstIndex(of: closest) else { return currentSize }
        
        if increase {
            return currentIndex < fontSizes.count - 1 ? fontSizes[currentIndex + 1] : currentSize
        } else {
            return currentIndex > 0 ? fontSizes[currentIndex - 1] : currentSize
        }
    }
    
    private func nextFontDesign(_ currentDesign: String) -> String {
        let designs = ["regular", "monospaced", "serif", "rounded"]
        guard let currentIndex = designs.firstIndex(of: currentDesign) else { return "regular" }
        let nextIndex = (currentIndex + 1) % designs.count
        return designs[nextIndex]
    }
    
    private func fontDesignIcon(for design: String) -> String {
        switch design {
        case "monospaced":
            return "textformat.123"
        case "serif":
            return "textformat.abc"
        case "rounded":
            return "textformat.alt"
        default:
            return "textformat"
        }
    }
    
    @ViewBuilder
    private var contextMenuItems: some View {
        Menu("Change Color") {
            Button {
                onColorChange(.black)
            } label: {
                HStack {
                    Text("Black")
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.black, .primary, .secondary)
                }
            }
            Button {
                onColorChange(.red)
            } label: {
                HStack {
                    Text("Red")
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.red, .primary, .secondary)
                }
            }
            Button {
                onColorChange(.orange)
            } label: {
                HStack {
                    Text("Orange")
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.orange, .primary, .secondary)
                }
            }
            Button {
                onColorChange(.yellow)
            } label: {
                HStack {
                    Text("Yellow")
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.yellow, .primary, .secondary)
                }
            }
            Button {
                onColorChange(.green)
            } label: {
                HStack {
                    Text("Green")
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.green, .primary, .secondary)
                }
            }
            Button {
                onColorChange(.blue)
            } label: {
                HStack {
                    Text("Blue")
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.blue, .primary, .secondary)
                }
            }
            Button {
                onColorChange(Color(hex: "B973FF"))
            } label: {
                HStack {
                    Text("Purple")
                    Image(systemName: "circle.fill")
                        .foregroundStyle(Color(hex: "B973FF"), .primary, .secondary)
                }
            }
            Button {
                onColorChange(Color(hex: "FF73E8"))
            } label: {
                HStack {
                    Text("Pink")
                    Image(systemName: "circle.fill")
                        .foregroundStyle(Color(hex: "FF73E8"), .primary, .secondary)
                }
            }
        }
        
        if case .rectangle = element.type {
            Menu("Corner Radius") {
                cornerRadiusMenuItems
            }
        } else if case .website = element.type {
            Menu("Corner Radius") {
                cornerRadiusMenuItems
            }
        }
        
        Button("Move to Top") {
            onMoveToTop()
        }
        
        Button("Move to Bottom") {
            onMoveToBottom()
        }
        
        Button("Delete", role: .destructive) {
            onDelete()
        }
    }
    
    @ViewBuilder
    private var cornerRadiusMenuItems: some View {
        if case .rectangle = element.type {
            Button("None (0)") {
                onCornerRadiusChange(0)
            }
        }
        
        Button("5") {
            onCornerRadiusChange(5)
        }
        
        Button("10") {
            onCornerRadiusChange(10)
        }
        
        Button("15") {
            onCornerRadiusChange(15)
        }
        
        Button("20") {
            onCornerRadiusChange(20)
        }
        
        Button("25") {
            onCornerRadiusChange(25)
        }
    }
}
