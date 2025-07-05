//
// Aura Easels
// MainView.swift
//
// Created on 7/5/25
//
// Copyright ©2025 DoorHinge Apps.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var canvases: [Canvas]
    @State private var selectedCanvas: Canvas?
    @State private var showingSidebar = true
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack {
                HStack {
                    Text("Canvases")
                        .font(.headline)
                    Spacer()
                    Button(action: createNewCanvas) {
                        Image(systemName: "plus")
                    }
                }
                .padding()
                
                List(canvases, id: \.id) { canvas in
                    VStack(alignment: .leading) {
                        Text(canvas.name)
                            .font(.body)
                        Text("\(canvas.elements.count) elements")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                    .background(selectedCanvas?.id == canvas.id ? Color.accentColor.opacity(0.2) : Color.clear)
                    .onTapGesture {
                        selectedCanvas = canvas
                    }
                    .contextMenu {
                        Button("Rename") {
                            // TODO: Add rename functionality
                        }
                        Button("Duplicate") {
                            duplicateCanvas(canvas)
                        }
                        Button("Delete", role: .destructive) {
                            deleteCanvas(canvas)
                        }
                    }
                }
                
                Spacer()
            }
            .frame(minWidth: 200)
        } detail: {
            // Main content
            if let selectedCanvas = selectedCanvas {
                ContentView(canvas: selectedCanvas)
            } else {
                VStack {
                    Image(systemName: "paintbrush")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select a canvas to get started")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Button("Create New Canvas") {
                        createNewCanvas()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if canvases.isEmpty {
                createNewCanvas()
            } else if selectedCanvas == nil {
                selectedCanvas = canvases.first
            }
        }
    }
    
    private func createNewCanvas() {
        let newCanvas = Canvas(name: "Canvas \(canvases.count + 1)")
        modelContext.insert(newCanvas)
        selectedCanvas = newCanvas
        
        try? modelContext.save()
    }
    
    private func duplicateCanvas(_ canvas: Canvas) {
        let newCanvas = Canvas(name: "\(canvas.name) Copy")
        
        // Copy elements
        for element in canvas.elements {
            let newElement = CanvasElement(
                type: element.type,
                position: element.position,
                size: element.size,
                color: element.color
            )
            newCanvas.elements.append(newElement)
            modelContext.insert(newElement)
        }
        
        modelContext.insert(newCanvas)
        try? modelContext.save()
    }
    
    private func deleteCanvas(_ canvas: Canvas) {
        // Delete all elements first
        for element in canvas.elements {
            modelContext.delete(element)
        }
        
        modelContext.delete(canvas)
        
        // Update selection if needed
        if selectedCanvas?.id == canvas.id {
            selectedCanvas = canvases.first { $0.id != canvas.id }
        }
        
        try? modelContext.save()
    }
}

#Preview {
    MainView()
        .modelContainer(for: Canvas.self, inMemory: true)
}