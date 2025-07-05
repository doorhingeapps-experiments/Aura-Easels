//
// Aura Easels
// LinkPresentation.swift
//
// Created on 7/3/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import LinkPresentation

struct LinkPreview: UIViewRepresentable {
    var previewURL: URL
    @Binding var measuredSize: CGSize

    func makeUIView(context: Context) -> UIView {
        let container = TouchBlockingView()
        let linkView = LPLinkView(url: previewURL)
        linkView.isUserInteractionEnabled = true

        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: previewURL) { metadata, error in
            guard let metadata = metadata, error == nil else { return }

            DispatchQueue.main.async {
                linkView.metadata = metadata
                linkView.sizeToFit()
                measuredSize = linkView.intrinsicContentSize
            }
        }

        linkView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(linkView)

        NSLayoutConstraint.activate([
            linkView.topAnchor.constraint(equalTo: container.topAnchor),
            linkView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            linkView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            linkView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// This view blocks all touch input from reaching its subviews
class TouchBlockingView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return self  // Block all touches
    }
}

