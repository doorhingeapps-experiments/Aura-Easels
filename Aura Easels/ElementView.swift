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
    let isEditingText: Bool
    @Binding var editingText: String
    let dragOffset: CGSize
    let onSelect: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: (CGSize) -> Void
    let onTextSubmit: (String) -> Void
    
    @State var webPage = WebPage()
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
                    .frame(width: element.size.width, height: element.size.height, alignment: .topLeading)
                    .position(element.position)
                } else {
                    Text(str)
//                        .font(.system(size: 16))
                        .modifier(TextStyleModifier(fontDesign: style.fontDesign, fontSize: style.fontSize, fontWeight: style.fontweight, alignment: style.alignment, verticalAlignment: ""))
                        .foregroundColor(element.color)
//                        .multilineTextAlignment(.leading)
                        .frame(width: element.size.width, height: element.size.height, alignment: .topLeading)
                        //.background(Color.white.opacity(0.8))
                        .position(element.position)
                        .offset(dragOffset)
                        .onTapGesture { onSelect() }
                        .gesture(drag)
                }

            case .rectangle:
                Rectangle()
                    .fill(element.color)
                    .frame(width: element.size.width, height: element.size.height)
                    .position(element.position)
                    .offset(dragOffset)
                    .onTapGesture { onSelect() }
                    .gesture(drag)

            case .oval:
                Ellipse()
                    .fill(element.color)
                    .frame(width: element.size.width, height: element.size.height)
                    .position(element.position)
                    .offset(dragOffset)
                    .onTapGesture { onSelect() }
                    .gesture(drag)
            case .line(let rotation):
                RoundedRectangle(cornerRadius: 10)
                    .fill(element.color)
                    .frame(width: element.size.width, height: 2)
                    .position(element.position)
                    .offset(dragOffset)
                    .onTapGesture { onSelect() }
                    .gesture(drag)
            case .website(let url):
//                if finishedLoading {
//                    WebView(webPage)
//                        .frame(width: element.size.width, height: element.size.height)
//                        .position(element.position)
//                        .offset(dragOffset)
//                        .onTapGesture { onSelect() }
//                        .gesture(drag)
//                }
//                else {
//                    Rectangle()
//                        .fill(Color.gray)
//                        .frame(width: element.size.width, height: element.size.height)
//                        .position(element.position)
//                        .offset(dragOffset)
//                        .onTapGesture { onSelect() }
//                        .gesture(drag)
//                        .onAppear() {
//                            Task {
//                                await webPage.load(URLRequest(url: URL(string: url) ?? URL(string: "https://apple.com")!))
//                            }
//                            finishedLoading = true
//                        }
//                }
                if let linkURL = URL(string: url) {
                    GeometryReader { geo in
                        let scale = calculateScale(
                            available: geo.size,
                            content: linkPreviewSize
                        )
                        
                        LinkPreview(
                            previewURL: linkURL,
                            measuredSize: $linkPreviewSize
                        )
                        .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 0)
                        .scaleEffect(scale, anchor: .center)
                        .frame(
                            width: geo.size.width,
                            height: geo.size.height
                        )
                    }
                    .frame(
                        width: element.size.width,
                        height: element.size.height
                    )
                    .position(element.position)
                    .offset(dragOffset)
                    .onTapGesture { onSelect() }
                    .gesture(drag)
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
        DragGesture()
            .onChanged { value in onDragChanged(value.translation) }
            .onEnded   { value in onDragEnded(value.translation) }
    }
}
