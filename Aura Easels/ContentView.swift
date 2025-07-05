//  ContentView.swift
//  Aura Easels
//  Re-written 7/2/25

import SwiftUI
import WebKit


// MARK: – Main View
struct ContentView: View {
    @State private var elements: [CanvasElement] = [
        .init(type: .text("Hello World", TextStyleOptions(fontDesign: "regular", fontSize: 20, fontweight: "bold", alignment: "center")), position: .init(x: 150, y: 100), size: .init(width: 120, height: 40), color: .black),
        .init(type: .rectangle, position: .init(x: 200, y: 200), size: .init(width: 100, height: 100), color: .blue),
        .init(type: .oval, position: .init(x: 100, y: 300), size: .init(width: 100, height: 100), color: .blue)
    ]
    @State private var selectedElement: CanvasElement? = nil
    @State private var editingText: String = ""
    @State private var isEditingText: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var isResizing: Bool = false
    @State private var resizeStart: CanvasElement? = nil
    
    
    private let minWidth:  CGFloat = 50
    private let maxWidth:  CGFloat = 1000
    private let minHeight: CGFloat = 50
    private let maxHeight: CGFloat = 1000
    
    @State var popoverWebview: WebPage?
    @State var shrinkWebView = true
    @State var currentWebsiteElement: CanvasElement?
    @State var editingURL: String = ""
    
    var body: some View {
        GeometryReader { bigGeo in
            ZStack {
                VStack {
                    Text("Canvas Editor")
                        .font(.largeTitle)
                        .padding(.top)
                    
                    GeometryReader { geo in
                        let screenH = geo.size.height
                        let lastBottom = elements.map { $0.position.y + $0.size.height/2 }.max() ?? 0
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
                                
                                ForEach(elements) { element in
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
                                                dragOffset = tr
                                            }
                                        },
                                        onDragEnded: { tr in
                                            if selectedElement?.id == element.id && !isResizing {
                                                updatePosition(of: element, by: tr)
                                                dragOffset = .zero
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
                                            resizeStart = nil
                                        }
                                    )
                                    .zIndex(1000)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: canvasH)
                        }
                        .frame(height: screenH)
                    }
                    .padding()
                    
                    HStack {
                        Button("Add Text") { add(.text("New Text", TextStyleOptions(fontDesign: "regular", fontSize: 20, fontweight: "bold", alignment: "center"))) }
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
        guard let idx = elements.firstIndex(where: { $0.id == element.id }) else { return }
        elements[idx].position.x += tr.width
        elements[idx].position.y += tr.height
        selectedElement = elements[idx]
    }

    private func updateText(of element: CanvasElement, to text: String) {
        guard let idx = elements.firstIndex(where: { $0.id == element.id }) else { return }
        if case .text(_, let currentStyle) = element.type {
            elements[idx].type = .text(text, currentStyle)
        } else {
            elements[idx].type = .text(text, TextStyleOptions(fontDesign: "regular", fontSize: 20, fontweight: "bold", alignment: "center"))
        }
        selectedElement = elements[idx]
    }
    
    private func updateTextStyle(of element: CanvasElement, to style: TextStyleOptions) {
        guard let idx = elements.firstIndex(where: { $0.id == element.id }) else { return }
        if case .text(let currentText, _) = element.type {
            elements[idx].type = .text(currentText, style)
            selectedElement = elements[idx]
        }
    }

    private func resizeElement(_ element: CanvasElement, handle: ResizeHandle, translation tr: CGSize) {
        if resizeStart?.id != element.id { resizeStart = element }
        guard let start = resizeStart,
              let idx   = elements.firstIndex(where: { $0.id == element.id }) else { return }

        // compute new size within your four limits
        var newSize = start.size
        func clamp(_ v: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
            Swift.min(max, Swift.max(min, v))
        }

        switch handle {
        case .topLeft:
            newSize.width  = clamp(start.size.width  - tr.width,  min: minWidth, max: maxWidth)
            newSize.height = clamp(start.size.height - tr.height, min: minHeight, max: maxHeight)
        case .topRight:
            newSize.width  = clamp(start.size.width  + tr.width,  min: minWidth, max: maxWidth)
            newSize.height = clamp(start.size.height - tr.height, min: minHeight, max: maxHeight)
        case .bottomLeft:
            newSize.width  = clamp(start.size.width  - tr.width,  min: minWidth, max: maxWidth)
            newSize.height = clamp(start.size.height + tr.height, min: minHeight, max: maxHeight)
        case .bottomRight:
            newSize.width  = clamp(start.size.width  + tr.width,  min: minWidth, max: maxWidth)
            newSize.height = clamp(start.size.height + tr.height, min: minHeight, max: maxHeight)
        case .top:
            newSize.height = clamp(start.size.height - tr.height, min: minHeight, max: maxHeight)
        case .bottom:
            newSize.height = clamp(start.size.height + tr.height, min: minHeight, max: maxHeight)
        case .left:
            newSize.width  = clamp(start.size.width  - tr.width,  min: minWidth, max: maxWidth)
        case .right:
            newSize.width  = clamp(start.size.width  + tr.width,  min: minWidth, max: maxWidth)
        }

        // figure out how much we actually resized
        let deltaW = newSize.width  - start.size.width
        let deltaH = newSize.height - start.size.height

        // reposition by half the *actual* delta in the correct direction
        var newPos = start.position
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

        elements[idx].size     = newSize
        elements[idx].position = newPos
        selectedElement        = elements[idx]
    }



    private func add(_ type: ElementType) {
        let defaultColor = getDefaultColor(for: type)
        let newElem = CanvasElement(type: type, position: .init(x: 200, y: 200), size: .init(width: 200, height: 200), color: defaultColor)
        elements.append(newElem)
        selectedElement = newElem
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
        elements.removeAll { $0.id == sel.id }
        selectedElement = nil
    }
    
    private func deleteElement(_ element: CanvasElement) {
        elements.removeAll { $0.id == element.id }
        if selectedElement?.id == element.id {
            selectedElement = nil
        }
    }
    
    private func updateColor(of element: CanvasElement, to color: Color) {
        guard let idx = elements.firstIndex(where: { $0.id == element.id }) else { return }
        elements[idx].color = color
        selectedElement = elements[idx]
    }
    
    private func moveToTop(element: CanvasElement) {
        guard let idx = elements.firstIndex(where: { $0.id == element.id }) else { return }
        let movedElement = elements.remove(at: idx)
        elements.append(movedElement)
        selectedElement = movedElement
    }
    
    private func moveToBottom(element: CanvasElement) {
        guard let idx = elements.firstIndex(where: { $0.id == element.id }) else { return }
        let movedElement = elements.remove(at: idx)
        elements.insert(movedElement, at: 0)
        selectedElement = movedElement
    }
    
    private func updateWebsiteURL() {
        guard let currentElement = currentWebsiteElement,
              let idx = elements.firstIndex(where: { $0.id == currentElement.id }) else { return }
        
        elements[idx].type = .website(editingURL)
        selectedElement = elements[idx]
        
        // Update the webview with the new URL
        if let url = URL(string: editingURL) {
            let request = URLRequest(url: url)
            popoverWebview?.load(request)
        }
    }
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
