//  ContentView.swift
//  Aura Easels
//  Re-written 7/2/25

import SwiftUI
import SwiftData
import WebKit


// MARK: – Main View
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    let canvas: Canvas
    @State private var selectedElement: CanvasElement? = nil
    @State private var editingText: String = ""
    @State private var isEditingText: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var isResizing: Bool = false
    @State private var resizeStartSize: CGSize? = nil
    @State private var resizeStartPosition: CGPoint? = nil
    
    
    private let minWidth:  CGFloat = 50
    private let maxWidth:  CGFloat = 1000
    private let minHeight: CGFloat = 50
    private let maxHeight: CGFloat = 1000
    
    @State var popoverWebview: WebPage?
    @State var shrinkWebView = true
    @State var currentWebsiteElement: CanvasElement?
    @State var editingURL: String = ""
    
    // Snapping state
    @State var snapIndicatorLines: [SnapLine] = []
    @State var snappedPosition: CGPoint? = nil
    
    var body: some View {
        GeometryReader { bigGeo in
            ZStack {
                VStack {
                    Text("Canvas Editor")
                        .font(.largeTitle)
                        .padding(.top)
                    
                    GeometryReader { geo in
                        let screenH = geo.size.height
                        let lastBottom = canvas.elements.map { $0.position.y + $0.size.height/2 }.max() ?? 0
                        let canvasH = max(screenH, lastBottom + screenH)
                        
                        ScrollView(.vertical) {
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .border(Color.gray, width: 1)
                                    .onTapGesture {
                                        selectedElement = nil
                                        isEditingText = false
                                    }
                                
                                ForEach(canvas.elements, id: \.id) { element in
                                    ElementView(
                                        element: element,
                                        isEditingText: isEditingText && selectedElement?.id == element.id,
                                        editingText: $editingText,
                                        dragOffset: selectedElement?.id == element.id ? dragOffset : .zero,
                                        onSelect: {
                                            if selectedElement?.id == element.id {
                                                if case .text(let current, let textStyle) = element.type {
                                                    editingText = current
                                                    isEditingText = true
                                                }
                                                else if case .website(let current) = element.type {
                                                    let webPage = WebPage()
                                                    if let url = URL(string: current) {
                                                        let request = URLRequest(url: url)
                                                        webPage.load(request)
                                                        popoverWebview = webPage
                                                        currentWebsiteElement = element
                                                        editingURL = current
                                                    }
                                                }
                                            }
                                            else {
                                                selectedElement = element
                                                isEditingText = false
                                            }
                                        },
                                        onDragChanged: { tr in
                                            if selectedElement?.id == element.id && !isResizing {
                                                let canvasSize = CGSize(width: geo.size.width, height: canvasH)
                                                let snapResult = calculateSnap(for: element, with: tr, canvasSize: canvasSize)
                                                
                                                // Calculate offset from snapped position
                                                let snappedOffset = CGSize(
                                                    width: snapResult.position.x - element.position.x,
                                                    height: snapResult.position.y - element.position.y
                                                )
                                                
                                                dragOffset = snappedOffset
                                                snapIndicatorLines = snapResult.lines
                                                snappedPosition = snapResult.position
                                            }
                                        },
                                        onDragEnded: { tr in
                                            if selectedElement?.id == element.id && !isResizing {
                                                if let snapped = snappedPosition {
                                                    updatePositionAbsolute(of: element, to: snapped)
                                                } else {
                                                    updatePosition(of: element, by: tr)
                                                }
                                                dragOffset = .zero
                                                snapIndicatorLines = []
                                                snappedPosition = nil
                                            }
                                        },
                                        onTextSubmit: { newText in
                                            updateText(of: element, to: newText)
                                            isEditingText = false
                                        },
                                        onColorChange: { color in
                                            updateColor(of: element, to: color)
                                        },
                                        onMoveToTop: {
                                            moveToTop(element: element)
                                        },
                                        onMoveToBottom: {
                                            moveToBottom(element: element)
                                        },
                                        onDelete: {
                                            deleteElement(element)
                                        },
                                        onTextStyleChange: { newStyle in
                                            updateTextStyle(of: element, to: newStyle)
                                        }
                                    )
                                }
                                
                                if let selected = selectedElement, !isEditingText {
                                    SelectionOverlay(
                                        element: selected,
                                        dragOffset: dragOffset,
                                        onResize: { handle, tr in
                                            isResizing = true
                                            resizeElement(selected, handle: handle, translation: tr)
                                        },
                                        onResizeEnded: {
                                            isResizing = false
                                            resizeStartSize = nil
                                            resizeStartPosition = nil
                                        }
                                    )
                                    .zIndex(1000)
                                }
                                
                                // Snap indicator lines
                                ForEach(snapIndicatorLines.indices, id: \.self) { index in
                                    let line = snapIndicatorLines[index]
                                    Path { path in
                                        path.move(to: line.start)
                                        path.addLine(to: line.end)
                                    }
                                    .stroke(Color.black, lineWidth: 1)
                                    .allowsHitTesting(false)
                                }
                                .zIndex(999)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: canvasH)
                        }
                        .frame(height: screenH)
                    }
                    .padding()
                    
                    HStack {
                        Button("Add Text") { 
                            let textStyle = TextStyleOptions(fontDesign: "regular", fontSize: 20, fontweight: "bold", alignment: "center")
                            modelContext.insert(textStyle)
                            add(.text("New Text", textStyle))
                        }
                        Button("Add Rectangle") { add(.rectangle) }
                        Button("Add Oval") { add(.oval) }
                        Button("Add Line") { add(.line(45.0)) }
                        Button("Add Website") { add(.website("https://apple.com")) }
                        Spacer()
                        if selectedElement != nil {
                            Button("Delete Selected", role: .destructive) { deleteSelected() }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                
                Group {
                    if let popoverWebview = popoverWebview {
                        ZStack {
                            Color.black.opacity(0.25)
                                .ignoresSafeArea()
                                .opacity(shrinkWebView ? 0.0: 1.0)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        shrinkWebView = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        self.popoverWebview = nil
                                        self.currentWebsiteElement = nil
                                    }
                                }
                            
                            VStack(spacing: 10) {
                                TextField("Enter URL", text: $editingURL, onCommit: {
                                    updateWebsiteURL()
                                })
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                                
                                WebView(popoverWebview)
                                    .cornerRadius(15)
                            }
                            .frame(width: bigGeo.size.width * (2/3))
                            .padding(.vertical, 30)
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            shrinkWebView = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                            self.popoverWebview = nil
                                            self.currentWebsiteElement = nil
                                        }
                                    } label: {
                                        Label("Close", systemImage: "xmark")
                                    }.buttonStyle(.glass)
                                    
                                }
                                .scaleEffect(shrinkWebView ? 0.0: 1.0)
                        }
                            .onAppear() {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    shrinkWebView = false
                                }
                            }
                    }
                }
            }
        }
    }

    // MARK: – Helpers
    private func updatePosition(of element: CanvasElement, by tr: CGSize) {
        element.position.x += tr.width
        element.position.y += tr.height
        selectedElement = element
        try? modelContext.save()
    }
    
    private func updatePositionAbsolute(of element: CanvasElement, to position: CGPoint) {
        element.position = position
        selectedElement = element
        try? modelContext.save()
    }

    private func updateText(of element: CanvasElement, to text: String) {
        if case .text(_, let currentStyle) = element.type {
            element.type = .text(text, currentStyle)
        } else {
            let newStyle = TextStyleOptions(fontDesign: "regular", fontSize: 20, fontweight: "bold", alignment: "center")
            modelContext.insert(newStyle)
            element.type = .text(text, newStyle)
        }
        selectedElement = element
        try? modelContext.save()
    }
    
    private func updateTextStyle(of element: CanvasElement, to style: TextStyleOptions) {
        if case .text(let currentText, _) = element.type {
            modelContext.insert(style)
            element.type = .text(currentText, style)
            selectedElement = element
            try? modelContext.save()
        }
    }

    private func resizeElement(_ element: CanvasElement, handle: ResizeHandle, translation tr: CGSize) {
        if resizeStartSize == nil || resizeStartPosition == nil {
            resizeStartSize = element.size
            resizeStartPosition = element.position
        }
        guard let startSize = resizeStartSize,
              let startPosition = resizeStartPosition,
              let idx = canvas.elements.firstIndex(where: { $0.id == element.id }) else { return }

        // compute new size within your four limits
        var newSize = startSize
        func clamp(_ v: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
            Swift.min(max, Swift.max(min, v))
        }

        switch handle {
        case .topLeft:
            newSize.width  = clamp(startSize.width  - tr.width,  min: minWidth, max: maxWidth)
            newSize.height = clamp(startSize.height - tr.height, min: minHeight, max: maxHeight)
        case .topRight:
            newSize.width  = clamp(startSize.width  + tr.width,  min: minWidth, max: maxWidth)
            newSize.height = clamp(startSize.height - tr.height, min: minHeight, max: maxHeight)
        case .bottomLeft:
            newSize.width  = clamp(startSize.width  - tr.width,  min: minWidth, max: maxWidth)
            newSize.height = clamp(startSize.height + tr.height, min: minHeight, max: maxHeight)
        case .bottomRight:
            newSize.width  = clamp(startSize.width  + tr.width,  min: minWidth, max: maxWidth)
            newSize.height = clamp(startSize.height + tr.height, min: minHeight, max: maxHeight)
        case .top:
            newSize.height = clamp(startSize.height - tr.height, min: minHeight, max: maxHeight)
        case .bottom:
            newSize.height = clamp(startSize.height + tr.height, min: minHeight, max: maxHeight)
        case .left:
            newSize.width  = clamp(startSize.width  - tr.width,  min: minWidth, max: maxWidth)
        case .right:
            newSize.width  = clamp(startSize.width  + tr.width,  min: minWidth, max: maxWidth)
        }

        // figure out how much we actually resized
        let deltaW = newSize.width  - startSize.width
        let deltaH = newSize.height - startSize.height

        // reposition by half the *actual* delta in the correct direction
        var newPos = startPosition
        switch handle {
        case .topLeft:
            newPos.x += -deltaW/2
            newPos.y += -deltaH/2
        case .topRight:
            newPos.x +=  deltaW/2
            newPos.y += -deltaH/2
        case .bottomLeft:
            newPos.x += -deltaW/2
            newPos.y +=  deltaH/2
        case .bottomRight:
            newPos.x +=  deltaW/2
            newPos.y +=  deltaH/2
        case .top:
            newPos.y += -deltaH/2
        case .bottom:
            newPos.y +=  deltaH/2
        case .left:
            newPos.x += -deltaW/2
        case .right:
            newPos.x +=  deltaW/2
        }

        canvas.elements[idx].size     = newSize
        canvas.elements[idx].position = newPos
        selectedElement               = canvas.elements[idx]
        try? modelContext.save()
    }



    private func add(_ type: ElementType) {
        let defaultColor = getDefaultColor(for: type)
        let newElem = CanvasElement(type: type, position: .init(x: 200, y: 200), size: .init(width: 200, height: 200), color: defaultColor)
        canvas.elements.append(newElem)
        modelContext.insert(newElem)
        selectedElement = newElem
        try? modelContext.save()
    }
    
    private func getDefaultColor(for type: ElementType) -> Color {
        switch type {
        case .text, .website:
            return .black
        case .rectangle, .oval, .line, .drawing, .image:
            return .blue
        }
    }

    private func deleteSelected() {
        guard let sel = selectedElement else { return }
        if let index = canvas.elements.firstIndex(where: { $0.id == sel.id }) {
            canvas.elements.remove(at: index)
        }
        modelContext.delete(sel)
        selectedElement = nil
        try? modelContext.save()
    }
    
    private func deleteElement(_ element: CanvasElement) {
        if let index = canvas.elements.firstIndex(where: { $0.id == element.id }) {
            canvas.elements.remove(at: index)
        }
        modelContext.delete(element)
        if selectedElement?.id == element.id {
            selectedElement = nil
        }
        try? modelContext.save()
    }
    
    private func updateColor(of element: CanvasElement, to color: Color) {
        element.color = color
        selectedElement = element
        try? modelContext.save()
    }
    
    private func moveToTop(element: CanvasElement) {
        guard let idx = canvas.elements.firstIndex(where: { $0.id == element.id }) else { return }
        let movedElement = canvas.elements.remove(at: idx)
        canvas.elements.append(movedElement)
        selectedElement = movedElement
        try? modelContext.save()
    }
    
    private func moveToBottom(element: CanvasElement) {
        guard let idx = canvas.elements.firstIndex(where: { $0.id == element.id }) else { return }
        let movedElement = canvas.elements.remove(at: idx)
        canvas.elements.insert(movedElement, at: 0)
        selectedElement = movedElement
        try? modelContext.save()
    }
    
    private func updateWebsiteURL() {
        guard let currentElement = currentWebsiteElement else { return }
        
        currentElement.type = .website(editingURL)
        selectedElement = currentElement
        
        // Update the webview with the new URL
        if let url = URL(string: editingURL) {
            let request = URLRequest(url: url)
            popoverWebview?.load(request)
        }
        
        try? modelContext.save()
    }
    
    private func calculateSnap(for element: CanvasElement, with dragOffset: CGSize, canvasSize: CGSize) -> (position: CGPoint, lines: [SnapLine]) {
        let snapThreshold: CGFloat = 20
        let currentCenter = CGPoint(
            x: element.position.x + dragOffset.width,
            y: element.position.y + dragOffset.height
        )
        let elementLeftEdge = currentCenter.x - element.size.width / 2
        let elementRightEdge = currentCenter.x + element.size.width / 2
        let elementTopEdge = currentCenter.y - element.size.height / 2
        let canvasCenterX = canvasSize.width / 2
        let canvasLeft: CGFloat = 0
        let canvasRight = canvasSize.width
        let canvasTop: CGFloat = 0
        
        var snappedPosition = currentCenter
        var snapLines: [SnapLine] = []
        
        // Center vertical snap
        if abs(currentCenter.x - canvasCenterX) < snapThreshold {
            snappedPosition.x = canvasCenterX
            snapLines.append(SnapLine(
                start: CGPoint(x: canvasCenterX, y: 0),
                end: CGPoint(x: canvasCenterX, y: canvasSize.height),
                type: .centerVertical
            ))
        }
        // Left edge snap (element left to canvas left)
        else if abs(elementLeftEdge - canvasLeft) < snapThreshold {
            snappedPosition.x = canvasLeft + element.size.width / 2
            snapLines.append(SnapLine(
                start: CGPoint(x: canvasLeft, y: 0),
                end: CGPoint(x: canvasLeft, y: canvasSize.height),
                type: .leftEdge
            ))
        }
        // Right edge snap (element right to canvas right)
        else if abs(elementRightEdge - canvasRight) < snapThreshold {
            snappedPosition.x = canvasRight - element.size.width / 2
            snapLines.append(SnapLine(
                start: CGPoint(x: canvasRight, y: 0),
                end: CGPoint(x: canvasRight, y: canvasSize.height),
                type: .rightEdge
            ))
        }
        
        // Top edge snap (element top to canvas top)
        if abs(elementTopEdge - canvasTop) < snapThreshold {
            snappedPosition.y = canvasTop + element.size.height / 2
            snapLines.append(SnapLine(
                start: CGPoint(x: 0, y: canvasTop),
                end: CGPoint(x: canvasSize.width, y: canvasTop),
                type: .topEdge
            ))
        }
        
        return (snappedPosition, snapLines)
    }
}

// MARK: – Snap Line
struct SnapLine {
    let start: CGPoint
    let end: CGPoint
    let type: SnapType
}

enum SnapType {
    case centerVertical
    case leftEdge
    case rightEdge
    case topEdge
}

// MARK: – Selection Overlay
enum ResizeHandle { case topLeft, topRight, bottomLeft, bottomRight, top, bottom, left, right }

struct SelectionOverlay: View {
    let element: CanvasElement
    let dragOffset: CGSize
    let onResize: (ResizeHandle, CGSize) -> Void
    let onResizeEnded: () -> Void

    private var center: CGPoint {
        .init(x: element.position.x + dragOffset.width,
              y: element.position.y + dragOffset.height)
    }

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.blue, lineWidth: 2)
                .frame(width: element.size.width, height: element.size.height)
                .position(center)
                .allowsHitTesting(false)
            
            ResizeHandleView(position: handlePos(.top), handle: .top, onDrag: onResize, onDragEnded: onResizeEnded)
            ResizeHandleView(position: handlePos(.bottom), handle: .bottom, onDrag: onResize, onDragEnded: onResizeEnded)
            ResizeHandleView(position: handlePos(.left), handle: .left, onDrag: onResize, onDragEnded: onResizeEnded)
            ResizeHandleView(position: handlePos(.right), handle: .right, onDrag: onResize, onDragEnded: onResizeEnded)
            
            ResizeHandleView(position: handlePos(.topLeft),     handle: .topLeft,     onDrag: onResize, onDragEnded: onResizeEnded)
            ResizeHandleView(position: handlePos(.topRight),    handle: .topRight,    onDrag: onResize, onDragEnded: onResizeEnded)
            ResizeHandleView(position: handlePos(.bottomLeft),  handle: .bottomLeft,  onDrag: onResize, onDragEnded: onResizeEnded)
            ResizeHandleView(position: handlePos(.bottomRight), handle: .bottomRight, onDrag: onResize, onDragEnded: onResizeEnded)
        }
    }

    private func handlePos(_ h: ResizeHandle) -> CGPoint {
        let w = element.size.width / 2
        let hgt = element.size.height / 2
        switch h {
        case .topLeft:     return .init(x: center.x - w,  y: center.y - hgt)
        case .topRight:    return .init(x: center.x + w,  y: center.y - hgt)
        case .bottomLeft:  return .init(x: center.x - w,  y: center.y + hgt)
        case .bottomRight: return .init(x: center.x + w,  y: center.y + hgt)
        case .top:
            return .init(x: center.x,  y: center.y - hgt)
        case .bottom:
            return .init(x: center.x,  y: center.y + hgt)
        case .left:
            return .init(x: center.x - w,  y: center.y)
        case .right:
            return .init(x: center.x + w,  y: center.y)
        }
    }
}

// MARK: – Resize Handle
struct ResizeHandleView: View {
    let position: CGPoint
    let handle: ResizeHandle
    let onDrag: (ResizeHandle, CGSize) -> Void
    let onDragEnded: () -> Void

    @State private var isDragging = false

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.001))
            .frame(width: 44, height: 44)
            .overlay(content: {
                Circle()
                    .fill(Color.white)
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: 16, height: 16)
                
            })
            .contentShape(Rectangle())
            .frame(width: 44, height: 44)
            .scaleEffect(isDragging ? 1.5 : 1)
            .animation(.easeInOut(duration: 0.1), value: isDragging)
            .position(position)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging { isDragging = true }
                        onDrag(handle, value.translation)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onDragEnded()
                    }
            )
            .zIndex(2)
    }
}

// MARK: – Color Extension
extension Color {
    static var random: Color {
        Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
    }
}
