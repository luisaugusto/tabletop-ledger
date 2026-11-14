import SwiftUI

private struct LaunchHeaderVisibleKey: EnvironmentKey { static let defaultValue = true }
extension EnvironmentValues {
    var launchHeaderVisible: Bool {
        get { self[LaunchHeaderVisibleKey.self] }
        set { self[LaunchHeaderVisibleKey.self] = newValue }
    }
}

/// The static launch screen already carries the brand. The app only finishes the
/// fade, then translates two composited surfaces using the same animation clock.
struct LaunchExperience<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var logoOpacity = 0.75
    @State private var traveling = false
    @State private var finished = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            let travel = geometry.size.height + geometry.safeAreaInsets.bottom - 165
            ZStack {
                Theme.cream.ignoresSafeArea()
                if !finished {
                    ForestArtwork()
                        .frame(height: 165)
                        .background(Theme.cream)
                        .drawingGroup()
                        .frame(maxHeight: .infinity, alignment: .top)
                        .offset(y: reduceMotion ? travel : (traveling ? 0 : travel))
                        .opacity(reduceMotion && traveling ? 0 : 1)
                        .accessibilityHidden(true)
                }
                content()
                    .environment(\.launchHeaderVisible, finished)
                    // Exclude the real header during travel. Content is ABOVE the
                    // landscape so its rounded sheet never gets covered by trees.
                    .mask {
                        Group {
                            if finished || reduceMotion { Rectangle() }
                            else { Theme.sheetShape.padding(.top, 139) }
                        }.ignoresSafeArea(edges: .bottom)
                    }
                    .offset(y: reduceMotion ? 0 : (traveling ? 0 : travel))
                    .opacity(reduceMotion ? (traveling ? 1 : 0) : 1)
                    .allowsHitTesting(finished)
                    .accessibilityHidden(!finished)
                if !finished {
                    GeometryReader { full in
                        VStack(spacing: 0) {
                            Image("LaunchLogo").resizable().scaledToFit().frame(width: 240, height: 240)
                            Text("Tabletop\nLedger").font(.custom("Georgia-Bold", size: 43))
                                .multilineTextAlignment(.center).foregroundStyle(Theme.forest)
                        }
                        .position(x: full.size.width / 2, y: full.size.height / 2 - 30)
                        .opacity(logoOpacity)
                    }.ignoresSafeArea().accessibilityHidden(true)
                }
            }
            .task {
                guard !finished else { return }
                await Task.yield()
                withAnimation(.easeOut(duration: 0.2)) { logoOpacity = 1 }
                try? await Task.sleep(for: .seconds(0.22))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: reduceMotion ? 0.25 : 0.3)) { logoOpacity = 0 }
                withAnimation(.timingCurve(0.32, 0, 0.18, 1, duration: reduceMotion ? 0.25 : 0.85)) { traveling = true }
                try? await Task.sleep(for: .seconds(reduceMotion ? 0.25 : 0.85))
                finished = true
            }
        }
    }
}
