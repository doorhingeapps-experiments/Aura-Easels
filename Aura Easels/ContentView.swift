//  ContentView.swift
//  Aura Easels
//  Re-written 7/2/25

import SwiftUI
import SwiftData
import WebKit

// MARK: - Tool Types
enum ToolType: String, CaseIterable {
    case select = "Select"
    case text = "Text"
    case rectangle = "Rectangle"
    case oval = "Oval"
    case line = "Line"
    case website = "Website"
    
    var systemImage: String {
        switch self {
        case .select: return "pointer.arrow"
        case .text: return "textformat"
        case .rectangle: return "rectangle"
        case .oval: return "circle"
        case .line: return "line.diagonal"
        case .website: return "globe.desk"
        }
    }
}

// MARK: - WKWebView Wrapper
struct WKWebViewWrapper: UIViewRepresentable {
    let url: URL?
    @Binding var currentURL: URL?
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = url, webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WKWebViewWrapper
        
        init(_ parent: WKWebViewWrapper) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.currentURL = webView.url
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
            if navigationAction.navigationType == .linkActivated {
                parent.currentURL = navigationAction.request.url
            }
        }
    }
}


// MARK: – Main View
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
//    let canvas: Canvas
    @Bindable var canvas: Canvas
    
    @State private var selectedElement: CanvasElement? = nil
    @State private var selectedElements: Set<String> = []
    @State private var editingText: String = ""
    @State private var isEditingText: Bool = false
    @State private var selectedTool: ToolType = .select
    @State private var dragOffset: CGSize = .zero
    @State private var groupDragOffset: CGSize = .zero
    @State private var isResizing: Bool = false
    @State private var resizeStartSize: CGSize? = nil
    @State private var resizeStartPosition: CGPoint? = nil
    
    @State var showDeleteIcon = false
    
    // Box selection state
    @State private var isBoxSelecting: Bool = false
    @State private var boxSelectionStart: CGPoint = .zero
    @State private var boxSelectionEnd: CGPoint = .zero
    
    
    private let minWidth:  CGFloat = ElementConstants.minWidth
    private let minHeight: CGFloat = ElementConstants.minHeight
    
    @State var showWebView = false
    @State var shrinkWebView = true
    @State var currentWebsiteElement: CanvasElement?
    @State var editingURL: String = ""
    @State var currentWebviewURL: URL?
    @State var webViewURL: URL?
    
    // Snapping state
    @State var snapIndicatorLines: [SnapLine] = []
    @State var snappedPosition: CGPoint? = nil
    @State private var isSnapEnabled: Bool = true
    @State private var showSettings: Bool = false
    @State var shouldShowUpdateButton = false
    
    @Namespace var namespace
    
    var body: some View {
        GeometryReader { bigGeo in
            ZStack(alignment: .top) {
                GlassEffectContainer {
                    HStack(spacing: 10) {
                        Button(action: {
                            showSettings.toggle()
                        }) {
                            Image(systemName: "gear")
                                .frame(width: 30, height: 30)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                                .foregroundStyle(Color(.label))
                                .glassEffect(.clear.interactive())
                        }
                            .glassEffectID("settings", in: namespace)
                            .glassEffectTransition(.matchedGeometry)
                        
                        Button {
                            withAnimation(.easeInOut) {
                                selectedTool = selectedTool == .select ? .select : .select
                            }
                        } label: {
                            Image(systemName: ToolType.select.systemImage)
                                .frame(width: 30, height: 30)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                                .foregroundStyle(Color(.label))
                                .glassEffect(.clear.interactive().tint(Color.blue.opacity(selectedTool == .select ? 0.75 : 0)))
                        }
                            .glassEffectID("select", in: namespace)
                            .glassEffectTransition(.matchedGeometry)
                        
                        Button {
                            withAnimation(.easeInOut) {
                                selectedTool = selectedTool == .text ? .select : .text
                            }
                        } label: {
                            Image(systemName: ToolType.text.systemImage)
                                .frame(width: 30, height: 30)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                                .foregroundStyle(Color(.label))
                                .glassEffect(.clear.interactive().tint(Color.blue.opacity(selectedTool == .text ? 0.75 : 0)))
                        }
                            .glassEffectID("text", in: namespace)
                            .glassEffectTransition(.matchedGeometry)
                        
                        Button {
                            withAnimation(.easeInOut) {
                                selectedTool = selectedTool == .rectangle ? .select : .rectangle
                            }
                        } label: {
                            Image(systemName: ToolType.rectangle.systemImage)
                                .frame(width: 30, height: 30)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                                .foregroundStyle(Color(.label))
                                .glassEffect(.clear.interactive().tint(Color.blue.opacity(selectedTool == .rectangle ? 0.75 : 0)))
                        }
                            .glassEffectID("rectangle", in: namespace)
                            .glassEffectTransition(.matchedGeometry)
                        
                        Button {
                            withAnimation(.easeInOut) {
                                selectedTool = selectedTool == .oval ? .select : .oval
                            }
                        } label: {
                            Image(systemName: ToolType.oval.systemImage)
                                .frame(width: 30, height: 30)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                                .foregroundStyle(Color(.label))
                                .glassEffect(.clear.interactive().tint(Color.blue.opacity(selectedTool == .oval ? 0.75 : 0)))
                        }
                            .glassEffectID("circle", in: namespace)
                            .glassEffectTransition(.matchedGeometry)
                        
                        Button {
                            withAnimation(.easeInOut) {
                                selectedTool = selectedTool == .line ? .select : .line
                            }
                        } label: {
                            Image(systemName: ToolType.line.systemImage)
                                .frame(width: 30, height: 30)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                                .foregroundStyle(Color(.label))
                                .glassEffect(.clear.interactive().tint(Color.blue.opacity(selectedTool == .line ? 0.75 : 0)))
                        }
                            .glassEffectID("line", in: namespace)
                            .glassEffectTransition(.matchedGeometry)
                        
                        Button {
                            withAnimation(.easeInOut) {
                                selectedTool = selectedTool == .website ? .select : .website
                            }
                        } label: {
                            Image(systemName: ToolType.website.systemImage)
                                .frame(width: 30, height: 30)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                                .foregroundStyle(Color(.label))
                                .glassEffect(.clear.interactive().tint(Color.blue.opacity(selectedTool == .website ? 0.75 : 0)))
                        }
                            .glassEffectID("website", in: namespace)
                            .glassEffectTransition(.matchedGeometry)
                        
                        if selectedElement != nil || !selectedElements.isEmpty {
                        //if showDeleteIcon {
                            Button {
                                deleteSelected()
                            } label: {
                                Image(systemName: "trash")
                                    .frame(width: 30, height: 30)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 10)
                                    .foregroundStyle(Color(.label))
                                    .glassEffect(.clear.interactive())
                            }
                                .keyboardShortcut(.delete, modifiers: [])
                                .glassEffectID("delete", in: namespace)
                                .glassEffectTransition(.matchedGeometry)
                        }
                    }
                    .animation(.easeInOut, value: selectedElement)
                    .animation(.easeInOut, value: selectedTool)
//                        .onChange(of: selectedElement) { oldValue, newValue in
//                            withAnimation(.easeInOut) {
//                                if selectedElement != nil || !selectedElements.isEmpty {
//                                    showDeleteIcon = true
//                                }
//                                else {
//                                    showDeleteIcon = false
//                                }
//                                if !selectedElements.isEmpty {
//                                    showDeleteIcon = true
//                                }
//                                else {
//                                    showDeleteIcon = false
//                                }
//                            }
//                        }
//                        .onChange(of: selectedElements) { oldValue, newValue in
//                            withAnimation(.easeInOut) {
//                                if selectedElement != nil || !selectedElements.isEmpty {
//                                    showDeleteIcon = true
//                                }
//                                else {
//                                    showDeleteIcon = false
//                                }
//                                if !selectedElements.isEmpty {
//                                    showDeleteIcon = true
//                                }
//                                else {
//                                    showDeleteIcon = false
//                                }
//                            }
//                        }
                        
//                        Button("Add Text") {
//                            let textStyle = TextStyleOptions(fontDesign: "regular", fontSize: 20, fontweight: "bold", alignment: "center")
//                            modelContext.insert(textStyle)
//                            add(.text("New Text", textStyle))
//                        }.buttonStyle(.glass)
//                        Button("Add Rectangle") { add(.rectangle) }
//                            .buttonStyle(.glass)
//                        Button("Add Oval") { add(.oval) }
//                            .buttonStyle(.glass)
//                        Button("Add Line") { add(.line(45.0)) }
//                            .buttonStyle(.glass)
//                        Button("Add Website") { add(.website("https://apple.com")) }
//                            .buttonStyle(.glass)
//                        Spacer()
//                        if selectedElement != nil || !selectedElements.isEmpty {
//                            Button("Delete Selected", role: .destructive) { deleteSelected() }
//                                .keyboardShortcut(.delete, modifiers: [])
//                                .buttonStyle(.glass)
//                        }
                    //}
                }.zIndex(102)
                    .font(.title2)
                    .padding(20)
                VStack {
                    GeometryReader { geo in
                        let screenH = geo.size.height
                        let lastBottom = canvas.elements.sorted(by: { $0.zOrder < $1.zOrder }).map { $0.position.y + $0.size.height/2 }.max() ?? 0
                        let canvasH = max(screenH, lastBottom + screenH)
                        
                        ScrollView(.vertical) {
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .border(Color.gray, width: 1)
                                    .onTapGesture { location in
                                        if selectedTool == .select {
                                            selectedElement = nil
                                            selectedElements.removeAll()
                                            isEditingText = false
                                        } else {
                                            createElementWithTool(at: location)
                                            selectedTool = .select // Return to select tool after creation
                                        }
                                    }
                                #if targetEnvironment(macCatalyst)
                                    .onHover { isHovering in
                                        if isHovering {
                                            if selectedTool == .select {
                                                NSCursor.arrow.set()
                                            } else {
                                                NSCursor.crosshair.set()
                                            }
                                        } else {
                                            NSCursor.arrow.set()
                                        }
                                    }
                                #endif
                                    .gesture(
                                        DragGesture(minimumDistance: 20)
                                            .onChanged { value in
                                                // Only allow box selection if in select mode and no single item is selected with resize handles
                                                guard selectedTool == .select && selectedElement == nil else { return }
                                                
                                                if !isBoxSelecting {
                                                    isBoxSelecting = true
                                                    boxSelectionStart = value.startLocation
                                                    selectedElements.removeAll()
                                                    isEditingText = false
                                                }
                                                boxSelectionEnd = value.location
                                                updateBoxSelection()
                                            }
                                            .onEnded { _ in
                                                isBoxSelecting = false
                                                // Auto-switch to single selection mode if only one item is selected
                                                if selectedElements.count == 1 {
                                                    if let elementId = selectedElements.first,
                                                       let element = canvas.elements.first(where: { $0.id == elementId }) {
                                                        selectedElement = element
                                                        selectedElements.removeAll()
                                                    }
                                                }
                                            }
                                    )
                                
                                ForEach(canvas.elements.sorted(by: { $0.zOrder < $1.zOrder }), id: \.id) { element in
                                    ElementView(
                                        element: element,
                                        isSelected: selectedElements.contains(element.id) || selectedElement?.id == element.id,
                                        isEditingText: isEditingText && selectedElement?.id == element.id,
                                        editingText: $editingText,
                                        dragOffset: selectedElement?.id == element.id ? dragOffset : (selectedElements.contains(element.id) ? groupDragOffset : .zero),
                                        onSelect: {
                                            // Cancel any ongoing box selection
                                            if isBoxSelecting {
                                                isBoxSelecting = false
                                            }
                                            
                                            if selectedElement?.id == element.id {
                                                if case .text(let current, let textStyle) = element.type {
                                                    editingText = current
                                                    isEditingText = true
                                                }
                                                else if case .website(let current) = element.type {
                                                    if let url = URL(string: current) {
                                                        webViewURL = url
                                                        showWebView = true
                                                        currentWebsiteElement = element
                                                        editingURL = current
                                                    }
                                                }
                                            }
                                            else {
                                                // Clear multi-selection and switch to single selection mode
                                                selectedElements.removeAll()
                                                selectedElement = element
                                                isEditingText = false
                                            }
                                        },
                                        onMultiSelect: {
                                            // Only allow multi-select if not in single-selection resize mode
                                            if selectedElement != nil {
                                                // Switch from single to multi-selection
                                                if let currentSelected = selectedElement {
                                                    selectedElements.insert(currentSelected.id)
                                                }
                                                selectedElement = nil
                                                isEditingText = false
                                            }
                                            
                                            if selectedElements.contains(element.id) {
                                                selectedElements.remove(element.id)
                                            } else {
                                                selectedElements.insert(element.id)
                                            }
                                        },
                                        onDragChanged: { tr in
                                            // Prioritize drag-to-move over box selection
                                            // Cancel any ongoing box selection when dragging an element
                                            if isBoxSelecting {
                                                isBoxSelecting = false
                                            }
                                            
                                            if selectedElement?.id == element.id && !isResizing {
                                                if isSnapEnabled {
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
                                                } else {
                                                    // No snapping, just use the raw translation
                                                    dragOffset = tr
                                                    snapIndicatorLines = []
                                                    snappedPosition = nil
                                                }
                                            } else if selectedElements.contains(element.id) && !isResizing {
                                                groupDragOffset = tr
                                            }
                                        },
                                        onDragEnded: { tr in
                                            if selectedElement?.id == element.id && !isResizing {
                                                if isSnapEnabled, let snapped = snappedPosition {
                                                    updatePositionAbsolute(of: element, to: snapped)
                                                } else {
                                                    updatePosition(of: element, by: tr)
                                                }
                                                dragOffset = .zero
                                                snapIndicatorLines = []
                                                snappedPosition = nil
                                            } else if selectedElements.contains(element.id) && !isResizing {
                                                updateGroupPositions(by: tr)
                                                groupDragOffset = .zero
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
                                        },
                                        onCornerRadiusChange: { cornerRadius in
                                            updateCornerRadius(of: element, to: cornerRadius)
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
                                    .zIndex(100)
                                }
                                
                                // Multi-selection overlays
                                ForEach(Array(selectedElements), id: \.self) { elementId in
                                    if let element = canvas.elements.first(where: { $0.id == elementId }) {
                                        MultiSelectionOverlay(
                                            element: element,
                                            dragOffset: groupDragOffset
                                        )
                                        .zIndex(99)
                                    }
                                }
                                
                                // Box selection overlay
                                if isBoxSelecting {
                                    BoxSelectionOverlay(
                                        start: boxSelectionStart,
                                        end: boxSelectionEnd
                                    )
                                    .zIndex(101)
                                }
                                
                                // Snap indicator lines (only show when snapping is enabled)
                                if isSnapEnabled {
                                    ForEach(snapIndicatorLines.indices, id: \.self) { index in
                                        let line = snapIndicatorLines[index]
                                        Path { path in
                                            path.move(to: line.start)
                                            path.addLine(to: line.end)
                                        }
                                        .stroke(Color(.systemBlue), lineWidth: 1)
                                        .allowsHitTesting(false)
                                    }
                                    .zIndex(99)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: canvasH)
                        }
                        .frame(height: screenH)
                    }
                    .padding()
                }
                
                Group {
                    if showWebView {
                        ZStack {
                            Color.black.opacity(0.25)
                                .ignoresSafeArea()
                                .opacity(shrinkWebView ? 0.0: 1.0)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        shrinkWebView = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        self.showWebView = false
                                        self.currentWebsiteElement = nil
                                    }
                                }
                            
                            VStack(spacing: 10) {
                                GlassEffectContainer {
                                    HStack( spacing: 10) {
                                        // Update URL button (only shows if URLs differ)
                                        if shouldShowUpdateButton {
                                            Button {
                                                updateElementWithCurrentURL()
                                                withAnimation {
                                                    shouldShowUpdateButton = false
                                                }
                                            } label: {
//                                                Label("Update URL", systemImage: "arrow.2.squarepath")
                                                Image(systemName: "arrow.2.squarepath")
                                                    .padding(2)
                                            }.buttonStyle(.glass)
                                                .glassEffectID("updateurl", in: namespace)
                                                .glassEffectTransition(.matchedGeometry)
                                                .help("Update URL")
                                        }
                                        
                                        TextField("Enter URL", text: $editingURL, onCommit: {
                                            updateWebsiteURL()
                                        })
                                        .autocorrectionDisabled(true)
                                        .textInputAutocapitalization(.never)
                                        .padding(7)
                                        .glassEffect(.regular.interactive())
                                        .glassEffectID("urlbar", in: namespace)
                                        .glassEffectTransition(.matchedGeometry)
                                        
                                        
                                        
                                        // Close button
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                shrinkWebView = true
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                self.showWebView = false
                                                self.currentWebsiteElement = nil
                                                self.currentWebviewURL = nil
                                                self.shouldShowUpdateButton = false
                                            }
                                        } label: {
                                            Label("Close", systemImage: "xmark")
                                                .padding(2)
                                        }.buttonStyle(.glass)
                                            .glassEffectID("close", in: namespace)
                                            .glassEffectTransition(.matchedGeometry)
                                    }
                                }//.animation(.easeInOut)
                                
                                WKWebViewWrapper(url: webViewURL, currentURL: $currentWebviewURL)
                                    .cornerRadius(15)
                            }
                            .frame(width: bigGeo.size.width * (2/3))
                            .padding(.vertical, 30)
                                .scaleEffect(shrinkWebView ? 0.0: 1.0)
                        }
                            .onAppear() {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    shrinkWebView = false
                                }
                            }
                            .onChange(of: self.currentWebviewURL, { oldValue, newValue in
                                Task {
                                    // Update button visibility based on URL comparison
                                    if let currentURL = newValue,
                                       let element = currentWebsiteElement,
                                       case .website(let savedURL) = element.type {
                                        withAnimation {
                                            self.shouldShowUpdateButton = currentURL.absoluteString != savedURL
                                        }
                                    } else {
                                        withAnimation {
                                            self.shouldShowUpdateButton = false
                                        }
                                    }
                                }
                            })
                    }
                }.zIndex(103)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isSnapEnabled: $isSnapEnabled)
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

        // Get element-specific max dimensions
        let maxSize = ElementConstants.maxSize(for: element.type)
        let maxWidth = maxSize.width
        let maxHeight = maxSize.height

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
        let defaultSize = ElementConstants.defaultSize(for: type)
        let newElem = CanvasElement(type: type, position: .init(x: 200, y: 200), size: defaultSize, color: defaultColor)
        canvas.elements.append(newElem)
        modelContext.insert(newElem)
        selectedElement = newElem
        try? modelContext.save()
    }
    
    private func createElementWithTool(at location: CGPoint) {
        let defaultColor: Color
        let elementType: ElementType
        let defaultSize: CGSize
        
        switch selectedTool {
        case .select:
            return // Do nothing for select tool
        case .text:
            let textStyle = TextStyleOptions(fontDesign: "regular", fontSize: 20, fontweight: "bold", alignment: "center")
            modelContext.insert(textStyle)
            elementType = .text("New Text", textStyle)
            defaultColor = .black
            defaultSize = ElementConstants.defaultSize(for: elementType)
        case .rectangle:
            elementType = .rectangle
            defaultColor = .blue
            defaultSize = ElementConstants.defaultSize(for: elementType)
        case .oval:
            elementType = .oval
            defaultColor = .blue
            defaultSize = ElementConstants.defaultSize(for: elementType)
        case .line:
            elementType = .line(0.0)
            defaultColor = .blue
            defaultSize = ElementConstants.defaultSize(for: elementType)
        case .website:
            elementType = .website("https://www.google.com/")
            defaultColor = .black
            defaultSize = ElementConstants.defaultSize(for: elementType)
        }
        
        let newElem = CanvasElement(type: elementType, position: location, size: defaultSize, color: defaultColor)
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
        if !selectedElements.isEmpty {
            // Delete multiple selected elements
            let elementsToDelete = canvas.elements.filter { selectedElements.contains($0.id) }
            for element in elementsToDelete {
                if let index = canvas.elements.firstIndex(where: { $0.id == element.id }) {
                    canvas.elements.remove(at: index)
                }
                modelContext.delete(element)
            }
            selectedElements.removeAll()
        } else if let sel = selectedElement {
            // Delete single selected element
            if let index = canvas.elements.firstIndex(where: { $0.id == sel.id }) {
                canvas.elements.remove(at: index)
            }
            modelContext.delete(sel)
            selectedElement = nil
        }
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
    
    private func updateCornerRadius(of element: CanvasElement, to cornerRadius: Double) {
        element.cornerRadius = cornerRadius
        selectedElement = element
        try? modelContext.save()
    }
    
    func moveToTop(element: CanvasElement) {
        let maxZOrder = canvas.elements.map { $0.zOrder }.max() ?? 0
        element.zOrder = maxZOrder + 1
        try? modelContext.save()
    }

    func moveToBottom(element: CanvasElement) {
        let minZOrder = canvas.elements.map { $0.zOrder }.min() ?? 0
        element.zOrder = minZOrder - 1
        try? modelContext.save()
    }

    
    private func updateWebsiteURL() {
        guard let currentElement = currentWebsiteElement else { return }
        
        currentElement.type = .website(editingURL)
        selectedElement = currentElement
        
        // Update the webview with the new URL
        if let url = URL(string: editingURL) {
            webViewURL = url
        }
        
        try? modelContext.save()
    }
    
    private func updateElementWithCurrentURL() {
        guard let currentElement = currentWebsiteElement,
              let currentURL = currentWebviewURL else { return }
        
        currentElement.type = .website(currentURL.absoluteString)
        selectedElement = currentElement
        editingURL = currentURL.absoluteString
        
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
        
        // Element-to-element snapping (smaller threshold)
        let elementSnapThreshold: CGFloat = snapThreshold / 2 // 10 instead of 20
        let elementBottomEdge = currentCenter.y + element.size.height / 2
        
        for otherElement in canvas.elements {
            // Skip self
            if otherElement.id == element.id { continue }
            
            let otherCenter = otherElement.position
            let otherLeft = otherCenter.x - otherElement.size.width / 2
            let otherRight = otherCenter.x + otherElement.size.width / 2
            let otherTop = otherCenter.y - otherElement.size.height / 2
            let otherBottom = otherCenter.y + otherElement.size.height / 2
            
            // Horizontal snapping (vertical lines)
            // Center to center
            if abs(currentCenter.x - otherCenter.x) < elementSnapThreshold {
                snappedPosition.x = otherCenter.x
                snapLines.append(SnapLine(
                    start: CGPoint(x: otherCenter.x, y: min(currentCenter.y, otherCenter.y) - 50),
                    end: CGPoint(x: otherCenter.x, y: max(currentCenter.y, otherCenter.y) + 50),
                    type: .elementCenterVertical
                ))
            }
            // Left edge to left edge
            else if abs(elementLeftEdge - otherLeft) < elementSnapThreshold {
                snappedPosition.x = otherLeft + element.size.width / 2
                snapLines.append(SnapLine(
                    start: CGPoint(x: otherLeft, y: min(currentCenter.y, otherCenter.y) - 50),
                    end: CGPoint(x: otherLeft, y: max(currentCenter.y, otherCenter.y) + 50),
                    type: .elementLeftEdge
                ))
            }
            // Right edge to right edge
            else if abs(elementRightEdge - otherRight) < elementSnapThreshold {
                snappedPosition.x = otherRight - element.size.width / 2
                snapLines.append(SnapLine(
                    start: CGPoint(x: otherRight, y: min(currentCenter.y, otherCenter.y) - 50),
                    end: CGPoint(x: otherRight, y: max(currentCenter.y, otherCenter.y) + 50),
                    type: .elementRightEdge
                ))
            }
            // Left edge to right edge
            else if abs(elementLeftEdge - otherRight) < elementSnapThreshold {
                snappedPosition.x = otherRight + element.size.width / 2
                snapLines.append(SnapLine(
                    start: CGPoint(x: otherRight, y: min(currentCenter.y, otherCenter.y) - 50),
                    end: CGPoint(x: otherRight, y: max(currentCenter.y, otherCenter.y) + 50),
                    type: .elementRightEdge
                ))
            }
            // Right edge to left edge
            else if abs(elementRightEdge - otherLeft) < elementSnapThreshold {
                snappedPosition.x = otherLeft - element.size.width / 2
                snapLines.append(SnapLine(
                    start: CGPoint(x: otherLeft, y: min(currentCenter.y, otherCenter.y) - 50),
                    end: CGPoint(x: otherLeft, y: max(currentCenter.y, otherCenter.y) + 50),
                    type: .elementLeftEdge
                ))
            }
            
            // Vertical snapping (horizontal lines)
            // Center to center
            if abs(currentCenter.y - otherCenter.y) < elementSnapThreshold {
                snappedPosition.y = otherCenter.y
                snapLines.append(SnapLine(
                    start: CGPoint(x: min(currentCenter.x, otherCenter.x) - 50, y: otherCenter.y),
                    end: CGPoint(x: max(currentCenter.x, otherCenter.x) + 50, y: otherCenter.y),
                    type: .elementCenterHorizontal
                ))
            }
            // Top edge to top edge
            else if abs(elementTopEdge - otherTop) < elementSnapThreshold {
                snappedPosition.y = otherTop + element.size.height / 2
                snapLines.append(SnapLine(
                    start: CGPoint(x: min(currentCenter.x, otherCenter.x) - 50, y: otherTop),
                    end: CGPoint(x: max(currentCenter.x, otherCenter.x) + 50, y: otherTop),
                    type: .elementTopEdge
                ))
            }
            // Bottom edge to bottom edge
            else if abs(elementBottomEdge - otherBottom) < elementSnapThreshold {
                snappedPosition.y = otherBottom - element.size.height / 2
                snapLines.append(SnapLine(
                    start: CGPoint(x: min(currentCenter.x, otherCenter.x) - 50, y: otherBottom),
                    end: CGPoint(x: max(currentCenter.x, otherCenter.x) + 50, y: otherBottom),
                    type: .elementBottomEdge
                ))
            }
            // Top edge to bottom edge
            else if abs(elementTopEdge - otherBottom) < elementSnapThreshold {
                snappedPosition.y = otherBottom + element.size.height / 2
                snapLines.append(SnapLine(
                    start: CGPoint(x: min(currentCenter.x, otherCenter.x) - 50, y: otherBottom),
                    end: CGPoint(x: max(currentCenter.x, otherCenter.x) + 50, y: otherBottom),
                    type: .elementBottomEdge
                ))
            }
            // Bottom edge to top edge
            else if abs(elementBottomEdge - otherTop) < elementSnapThreshold {
                snappedPosition.y = otherTop - element.size.height / 2
                snapLines.append(SnapLine(
                    start: CGPoint(x: min(currentCenter.x, otherCenter.x) - 50, y: otherTop),
                    end: CGPoint(x: max(currentCenter.x, otherCenter.x) + 50, y: otherTop),
                    type: .elementTopEdge
                ))
            }
        }
        
        return (snappedPosition, snapLines)
    }
    
    private func updateBoxSelection() {
        let selectionRect = CGRect(
            x: min(boxSelectionStart.x, boxSelectionEnd.x),
            y: min(boxSelectionStart.y, boxSelectionEnd.y),
            width: abs(boxSelectionEnd.x - boxSelectionStart.x),
            height: abs(boxSelectionEnd.y - boxSelectionStart.y)
        )
        
        selectedElements.removeAll()
        
        for element in canvas.elements {
            let elementRect = CGRect(
                x: element.position.x - element.size.width / 2,
                y: element.position.y - element.size.height / 2,
                width: element.size.width,
                height: element.size.height
            )
            
            if selectionRect.intersects(elementRect) {
                selectedElements.insert(element.id)
            }
        }
    }
    
    private func updateGroupPositions(by translation: CGSize) {
        for elementId in selectedElements {
            if let element = canvas.elements.first(where: { $0.id == elementId }) {
                element.position.x += translation.width
                element.position.y += translation.height
            }
        }
        try? modelContext.save()
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
    case elementCenterVertical
    case elementCenterHorizontal
    case elementLeftEdge
    case elementRightEdge
    case elementTopEdge
    case elementBottomEdge
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
            .pointingHandCursor()
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

// MARK: – Multi-Selection Overlay
struct MultiSelectionOverlay: View {
    let element: CanvasElement
    let dragOffset: CGSize
    
    private var center: CGPoint {
        .init(x: element.position.x + dragOffset.width,
              y: element.position.y + dragOffset.height)
    }
    
    var body: some View {
        Rectangle()
            .stroke(Color.orange, lineWidth: 2)
            .frame(width: element.size.width, height: element.size.height)
            .position(center)
            .allowsHitTesting(false)
    }
}

// MARK: – Box Selection Overlay
struct BoxSelectionOverlay: View {
    let start: CGPoint
    let end: CGPoint
    
    private var selectionRect: CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }
    
    var body: some View {
        Rectangle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: selectionRect.width, height: selectionRect.height)
            .position(x: selectionRect.midX, y: selectionRect.midY)
            .overlay(
                Rectangle()
                    .stroke(Color.blue, lineWidth: 1)
                    .frame(width: selectionRect.width, height: selectionRect.height)
                    .position(x: selectionRect.midX, y: selectionRect.midY)
            )
            .allowsHitTesting(false)
    }
}

// MARK: – Settings View
struct SettingsView: View {
    @Binding var isSnapEnabled: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Canvas Settings")) {
                    Toggle("Enable Snapping", isOn: $isSnapEnabled)
                        .toggleStyle(SwitchToggleStyle())
                }
                
                Section(footer: Text("When enabled, elements will snap to guides and other elements while dragging.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

// MARK: – Color Extension
extension Color {
    static var random: Color {
        Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
    }
}
