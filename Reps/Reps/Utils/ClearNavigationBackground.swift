import SwiftUI
import UIKit

/// A UIViewRepresentable that clears UIKit container backgrounds
/// to allow a root gradient to show through NavigationStack.
struct ClearNavigationBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        InnerClearView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        (uiView as? InnerClearView)?.clearBackgrounds()
    }

    private class InnerClearView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            clearBackgrounds()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            clearBackgrounds()
        }

        func clearBackgrounds() {
            // Clear every view in the superview chain up to the window
            var current: UIView? = self
            while let view = current {
                view.backgroundColor = .clear
                view.isOpaque = false
                view.layer.backgroundColor = nil
                current = view.superview
            }

            // Also clear the window itself
            window?.backgroundColor = .clear
            window?.isOpaque = false

            // Find and clear all UICollectionViews and UITableViews in the hierarchy
            if let root = window?.rootViewController?.view {
                clearScrollableViews(in: root)
            }
        }

        private func clearScrollableViews(in view: UIView) {
            // Clear collection views and table views (used by SwiftUI List)
            if view is UICollectionView || view is UITableView || view is UIScrollView {
                view.backgroundColor = .clear
                view.isOpaque = false
                view.layer.backgroundColor = nil
            }

            // Also clear any view that matches system container patterns
            let className = String(describing: type(of: view))
            if className.hasPrefix("_") || className.contains("Hosting") ||
               className.contains("Controller") || className.contains("Container") {
                view.backgroundColor = .clear
                view.isOpaque = false
            }

            for subview in view.subviews {
                clearScrollableViews(in: subview)
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Makes the NavigationStack background transparent by clearing UIKit internals
    func transparentNavigation() -> some View {
        self
            .background(ClearNavigationBackground())
            .background(Color.clear)
            .scrollContentBackground(.hidden)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}
