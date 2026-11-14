import SwiftUI

enum Theme {
    static let sheetCornerRadius: CGFloat = 28
    static var sheetShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: sheetCornerRadius, topTrailingRadius: sheetCornerRadius, style: .continuous)
    }
    static let cream = Color(red: 0.97, green: 0.94, blue: 0.88)
    static let forest = Color(red: 0.12, green: 0.27, blue: 0.19)
    static let ink = Color(red: 0.19, green: 0.17, blue: 0.13)
    static let rust = Color(red: 0.72, green: 0.32, blue: 0.19)
    static let gold = Color(red: 0.79, green: 0.53, blue: 0.15)
    static let sage = Color(red: 0.86, green: 0.88, blue: 0.78)
}
// A layered landscape, with a low central valley and taller pines at the edges.
// Kept as vectors so the illustration stays crisp during pull-to-stretch.
struct ForestHeader: View {
    @Environment(\.launchHeaderVisible) private var launchHeaderVisible
    var stretch: CGFloat = 0
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForestArtwork()
                .scaleEffect(1 + min(stretch, 160) / 1100, anchor: .bottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .clipped()
            VStack(alignment: .leading, spacing: 4) {
                Text("Tabletop Ledger").font(.system(size: 32, weight: .bold, design: .serif))
                Text("Your board-game session log").font(.subheadline)
            }.foregroundStyle(Theme.ink).padding(.horizontal, 24).padding(.top, 12)
        }.background(Theme.cream).opacity(launchHeaderVisible ? 1 : 0).accessibilityElement(children: .combine)
    }
}
struct ForestArtwork: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            context.fill(Path(ellipseIn: CGRect(x: w * 0.74, y: h * 0.035, width: 66, height: 66)), with: .linearGradient(Gradient(colors: [Color(red: 0.93, green: 0.75, blue: 0.57), Color(red: 0.93, green: 0.70, blue: 0.48)]), startPoint: CGPoint(x: w * 0.8, y: 0), endPoint: CGPoint(x: w * 0.8, y: h * 0.48)))
            let ridges: [[CGPoint]] = [
                [CGPoint(x: 0,y: 0.78), CGPoint(x: 0.18,y: 0.75), CGPoint(x: 0.31,y: 0.67), CGPoint(x: 0.46,y: 0.73), CGPoint(x: 0.59,y: 0.60), CGPoint(x: 0.74,y: 0.39), CGPoint(x: 0.87,y: 0.45), CGPoint(x: 1,y: 0.28)],
                [CGPoint(x: 0,y: 0.76), CGPoint(x: 0.15,y: 0.77), CGPoint(x: 0.30,y: 0.85), CGPoint(x: 0.43,y: 0.78), CGPoint(x: 0.57,y: 0.84), CGPoint(x: 0.72,y: 0.69), CGPoint(x: 0.86,y: 0.57), CGPoint(x: 1,y: 0.55)],
                [CGPoint(x: 0,y: 0.79), CGPoint(x: 0.19,y: 0.85), CGPoint(x: 0.33,y: 0.92), CGPoint(x: 0.48,y: 0.94), CGPoint(x: 0.64,y: 0.87), CGPoint(x: 0.81,y: 0.76), CGPoint(x: 1,y: 0.57)]
            ]
            let colors = [Color(red: 0.70,green: 0.72,blue: 0.55), Color(red: 0.54,green: 0.62,blue: 0.44), Color(red: 0.32,green: 0.46,blue: 0.33)]
            for (index, points) in ridges.enumerated() {
                var path = Path(); path.move(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: points[0].x * w, y: points[0].y * h))
                for i in 1..<points.count {
                    let prior = points[i-1], point = points[i]
                    let middle = (prior.x + point.x) * w / 2
                    path.addCurve(to: CGPoint(x: point.x*w,y: point.y*h), control1: CGPoint(x: middle,y: prior.y*h), control2: CGPoint(x: middle,y: point.y*h))
                }
                path.addLine(to: CGPoint(x: w,y: h)); path.closeSubpath()
                context.fill(path, with: .color(colors[index]))
            }
            // Distant, fine trees form a varied treeline instead of repeated triangles.
            for i in 0..<47 {
                let x = CGFloat(i) / 46
                let edge = pow(abs(x - 0.44) * 1.8, 1.7)
                let height = 8 + CGFloat((i * 17) % 13) + edge * 30
                let base = h * (0.97 - edge * 0.27)
                context.fill(pine(x: x*w, base: base, height: height, seed: i), with: .color(Color(red: 0.39,green: 0.52,blue: 0.37)))
            }
            let foreground: [(CGFloat,CGFloat,CGFloat)] = [(0.00,0.92,47),(0.035,0.95,40),(0.075,0.99,57),(0.12,1.02,43),(0.17,1.04,39),(0.22,1.03,28),(0.28,1.05,24),(0.34,1.05,18),(0.64,1.05,29),(0.70,1.03,41),(0.76,1.02,56),(0.82,1.03,84),(0.89,1.00,112),(0.95,1.03,101),(1.01,1.02,126)]
            for (i, tree) in foreground.enumerated() {
                context.fill(pine(x: tree.0*w, base: tree.1*h, height: tree.2, seed: i), with: .color(i % 3 == 0 ? Color(red: 0.24,green: 0.39,blue: 0.29) : Theme.forest))
            }
        }.accessibilityHidden(true)
    }
    private func pine(x: CGFloat, base: CGFloat, height: CGFloat, seed: Int) -> Path {
        var p = Path()
        p.addRect(CGRect(x: x-height*0.017, y: base-height*0.72, width: height*0.034, height: height*0.75))
        for level in 0..<7 {
            let fraction = CGFloat(level) / 7
            let tip = base-height + height*fraction*0.78
            let width = height*(0.065 + fraction*0.19)
            let skew = CGFloat((seed+level)%3-1)*height*0.012
            p.move(to: CGPoint(x: x,y: tip))
            p.addCurve(to: CGPoint(x: x-width,y: tip+height*0.23), control1: CGPoint(x: x-width*0.15,y: tip+height*0.11), control2: CGPoint(x: x-width*0.57,y: tip+height*0.20))
            p.addQuadCurve(to: CGPoint(x: x+width+skew,y: tip+height*0.23), control: CGPoint(x: x,y: tip+height*0.29))
            p.addCurve(to: CGPoint(x: x,y: tip), control1: CGPoint(x: x+width*0.52,y: tip+height*0.18), control2: CGPoint(x: x+width*0.16,y: tip+height*0.07))
            p.closeSubpath()
        }
        return p
    }
}
struct Stars: View {
    var rating: Int
    var body: some View {
        HStack(spacing: 3) { ForEach(1...5, id: \.self) { i in Image(systemName: i <= rating ? "star.fill" : "star").foregroundStyle(Theme.gold) } }
            .accessibilityLabel(rating == 0 ? "Not rated" : "\(rating) out of 5 stars")
    }
}
struct PhotoTile: View {
    var data: Data?
    var body: some View {
        ZStack {
            Theme.sage
            if let data, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill() }
            else { VStack(spacing: 6) { Image(systemName: "dice.fill").font(.title); Image(systemName: "leaf").font(.caption) }.foregroundStyle(Theme.forest.opacity(0.6)) }
        }.clipped().accessibilityHidden(true)
    }
}
struct PrimaryButton: ViewModifier {
    var color = Theme.forest
    func body(content: Content) -> some View { content.font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding(16).background(color, in: RoundedRectangle(cornerRadius: 16)) }
}
