import SwiftUI

/// Wrapper that defers view construction until accessed.
/// Use to improve tab navigation latency by not constructing all views upfront.
struct LazyView<Content: View>: View {
    let build: () -> Content

    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}
