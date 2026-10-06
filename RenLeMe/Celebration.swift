import SwiftUI

/// A one-shot burst of paper pieces behind a success popup.
struct ConfettiBurst: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startedAt = Date()

    private struct Piece {
        let angle: Double
        let speed: Double
        let spin: Double
        let size: CGFloat
        let color: Color
    }

    private static let duration = 1.7
    private static let colors: [Color] = [.punchYellow, .punchPink, .punchBlue, .white, .punchGreen]

    // Spread from the golden ratio so the burst looks scattered but is the same every time.
    private static let pieces: [Piece] = (0..<44).map { index in
        let a = (Double(index) * 0.618_034).truncatingRemainder(dividingBy: 1)
        let b = (Double(index) * 0.371_517).truncatingRemainder(dividingBy: 1)
        return Piece(
            angle: -.pi * (0.08 + 0.84 * a),
            speed: 240 + 300 * b,
            spin: (a - 0.5) * 14,
            size: 8 + 8 * b,
            color: colors[index % colors.count]
        )
    }

    var body: some View {
        if !reduceMotion {
            TimelineView(.animation) { context in
                Canvas { canvas, size in
                    let elapsed = context.date.timeIntervalSince(startedAt)
                    guard elapsed < Self.duration else { return }

                    for piece in Self.pieces {
                        var layer = canvas
                        layer.opacity = max(0, 1 - elapsed / Self.duration)
                        layer.translateBy(
                            x: size.width / 2 + cos(piece.angle) * piece.speed * elapsed,
                            y: size.height * 0.45 + sin(piece.angle) * piece.speed * elapsed + 430 * elapsed * elapsed
                        )
                        layer.rotate(by: .radians(piece.spin * elapsed))
                        let rect = CGRect(x: -piece.size / 2, y: -piece.size / 4, width: piece.size, height: piece.size / 2)
                        layer.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(piece.color))
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
