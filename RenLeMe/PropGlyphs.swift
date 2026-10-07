import SwiftUI

/// The second batch of item drawings, so that every built-in item has a picture of its own.
/// Same rules as the first batch in Components.swift: thick black outline, flat fills from the app
/// palette, everything positioned in fractions of `size` from the centre.
extension CartoonPropGlyphView {
    // MARK: Food

    var cola: some View {
        ZStack {
            roundedBox(width: 0.38, height: 0.62, corner: 0.09, fill: black)
                .offset(y: size * 0.04)
            lineCapsule(width: 0.30, height: 0.10, color: cream)
                .rotationEffect(.degrees(-22))
                .offset(y: size * 0.06)
            lineCapsule(width: 0.22, height: 0.055, color: cream)
                .offset(y: -size * 0.33)
        }
    }

    var beer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
                .stroke(black, lineWidth: line)
                .frame(width: size * 0.24, height: size * 0.28)
                .offset(x: size * 0.20, y: size * 0.12)
            roundedBox(width: 0.42, height: 0.50, corner: 0.07, fill: yellow)
                .offset(x: -size * 0.08, y: size * 0.10)
            ForEach([-0.24, -0.08, 0.08], id: \.self) { x in
                blob(0.22, fill: .white, x: x, y: -0.18)
            }
        }
    }

    var fries: some View {
        ZStack {
            ForEach(Array([-0.15, -0.05, 0.05, 0.15].enumerated()), id: \.offset) { index, x in
                roundedBox(width: 0.10, height: 0.40, corner: 0.03, fill: yellow)
                    .rotationEffect(.degrees(Double(index) * 6 - 9))
                    .offset(x: size * x, y: -size * (index.isMultiple(of: 2) ? 0.12 : 0.18))
            }
            outlined(TaperedCupShape(), fill: .white, width: 0.50, height: 0.40)
                .offset(y: size * 0.16)
            lineCapsule(width: 0.26, height: 0.07, color: pink)
                .offset(y: size * 0.14)
        }
    }

    var chocolate: some View {
        ZStack {
            roundedBox(width: 0.46, height: 0.50, corner: 0.06, fill: black)
                .offset(y: -size * 0.10)
            lineCapsule(width: 0.045, height: 0.36, color: cream)
                .offset(y: -size * 0.14)
            lineCapsule(width: 0.36, height: 0.045, color: cream)
                .offset(y: -size * 0.22)
            lineCapsule(width: 0.36, height: 0.045, color: cream)
                .offset(y: -size * 0.07)
            roundedBox(width: 0.52, height: 0.30, corner: 0.05, fill: yellow)
                .offset(y: size * 0.20)
        }
        .rotationEffect(.degrees(-10))
    }

    var spicyStrips: some View {
        ZStack {
            Ellipse()
                .fill(.white)
                .frame(width: size * 0.90, height: size * 0.76)
            ForEach(Array([-0.18, 0.0, 0.18].enumerated()), id: \.offset) { index, y in
                Capsule()
                    .fill(index == 1 ? yellow : pink)
                    .overlay(Capsule().stroke(black, lineWidth: thinLine))
                    .frame(width: size * 0.56, height: size * 0.13)
                    .rotationEffect(.degrees(-16))
                    .offset(x: size * (index == 1 ? 0.04 : -0.02), y: size * y)
            }
        }
    }

    var burger: some View {
        ZStack {
            roundedBox(width: 0.60, height: 0.15, corner: 0.06, fill: yellow)
                .offset(y: size * 0.24)
            Capsule()
                .fill(black)
                .frame(width: size * 0.62, height: size * 0.11)
                .offset(y: size * 0.11)
            Capsule()
                .fill(green)
                .overlay(Capsule().stroke(black, lineWidth: thinLine))
                .frame(width: size * 0.70, height: size * 0.10)
                .offset(y: size * 0.01)
            outlined(DomeShape(), fill: yellow, width: 0.62, height: 0.28)
                .offset(y: -size * 0.17)
            dot(0.045, color: black, x: -0.12, y: -0.20)
            dot(0.045, color: black, x: 0.02, y: -0.24)
            dot(0.045, color: black, x: 0.14, y: -0.18)
        }
    }

    var instantNoodles: some View {
        ZStack {
            lineCapsule(width: 0.46, height: 0.045)
                .rotationEffect(.degrees(-58))
                .offset(x: size * 0.12, y: -size * 0.22)
            lineCapsule(width: 0.46, height: 0.045)
                .rotationEffect(.degrees(-58))
                .offset(x: size * 0.22, y: -size * 0.18)
            outlined(TaperedCupShape(), fill: cream, width: 0.56, height: 0.46)
                .offset(y: size * 0.14)
            lineCapsule(width: 0.64, height: 0.06)
                .offset(y: -size * 0.09)
            lineCapsule(width: 0.34, height: 0.09, color: pink)
                .offset(y: size * 0.12)
        }
    }

    var pizza: some View {
        ZStack {
            outlined(SliceShape(), fill: yellow, width: 0.62, height: 0.66)
                .offset(y: size * 0.04)
            Capsule()
                .fill(cream)
                .overlay(Capsule().stroke(black, lineWidth: line))
                .frame(width: size * 0.70, height: size * 0.13)
                .offset(y: -size * 0.28)
            blob(0.13, fill: pink, x: -0.10, y: -0.08, thin: true)
            blob(0.13, fill: pink, x: 0.10, y: -0.04, thin: true)
            blob(0.11, fill: pink, x: 0.0, y: 0.14, thin: true)
        }
    }

    var hotpot: some View {
        ZStack {
            roundedBox(width: 0.14, height: 0.09, corner: 0.03, fill: cream)
                .offset(x: -size * 0.38, y: size * 0.06)
            roundedBox(width: 0.14, height: 0.09, corner: 0.03, fill: cream)
                .offset(x: size * 0.38, y: size * 0.06)
            outlined(BowlShape(), fill: cream, width: 0.66, height: 0.36)
                .offset(y: size * 0.16)
            Capsule()
                .fill(pink)
                .overlay(Capsule().stroke(black, lineWidth: line))
                .frame(width: size * 0.70, height: size * 0.12)
                .offset(y: -size * 0.02)
            lineCapsule(width: 0.05, height: 0.16)
                .rotationEffect(.degrees(14))
                .offset(x: -size * 0.12, y: -size * 0.28)
            lineCapsule(width: 0.05, height: 0.16)
                .rotationEffect(.degrees(-14))
                .offset(x: size * 0.10, y: -size * 0.30)
        }
    }

    var malatang: some View {
        ZStack {
            skewerUp(x: -0.12, tilt: -14, colors: [pink, yellow])
            skewerUp(x: 0.12, tilt: 12, colors: [green, pink])
            outlined(BowlShape(), fill: cream, width: 0.66, height: 0.36)
                .offset(y: size * 0.20)
            lineCapsule(width: 0.70, height: 0.055)
                .offset(y: size * 0.03)
        }
    }

    var lateNight: some View {
        ZStack {
            outlined(CrescentShape(), fill: yellow, width: 0.30, height: 0.36)
                .offset(x: size * 0.22, y: -size * 0.24)
            outlined(BowlShape(), fill: cream, width: 0.62, height: 0.34)
                .offset(x: -size * 0.04, y: size * 0.20)
            lineCapsule(width: 0.66, height: 0.055)
                .offset(x: -size * 0.04, y: size * 0.04)
            lineCapsule(width: 0.05, height: 0.14)
                .offset(x: -size * 0.18, y: -size * 0.14)
            lineCapsule(width: 0.05, height: 0.14)
                .offset(x: -size * 0.04, y: -size * 0.18)
        }
    }

    var iceCream: some View {
        ZStack {
            outlined(SliceShape(), fill: yellow, width: 0.32, height: 0.42)
                .offset(y: size * 0.20)
            blob(0.42, fill: .white, x: 0, y: -0.14)
            lineCapsule(width: 0.20, height: 0.06, color: pink)
                .rotationEffect(.degrees(-20))
                .offset(x: -size * 0.04, y: -size * 0.18)
            blob(0.12, fill: pink, x: 0.10, y: -0.34, thin: true)
        }
    }

    var eggTart: some View {
        ZStack {
            outlined(TaperedCupShape(), fill: cream, width: 0.66, height: 0.30)
                .offset(y: size * 0.12)
            Ellipse()
                .fill(yellow)
                .overlay(Ellipse().stroke(black, lineWidth: line))
                .frame(width: size * 0.62, height: size * 0.24)
                .offset(y: -size * 0.06)
            dot(0.07, color: black, x: -0.10, y: -0.08)
            dot(0.05, color: black, x: 0.08, y: -0.04)
            lineCapsule(width: 0.045, height: 0.12)
                .offset(x: -size * 0.14, y: size * 0.16)
            lineCapsule(width: 0.045, height: 0.12)
                .offset(y: size * 0.16)
            lineCapsule(width: 0.045, height: 0.12)
                .offset(x: size * 0.14, y: size * 0.16)
        }
    }

    var donut: some View {
        ZStack {
            blob(0.68, fill: cream, x: 0, y: 0)
            Circle()
                .fill(pink)
                .frame(width: size * 0.52)
            blob(0.18, fill: .white, x: 0, y: 0)
            lineCapsule(width: 0.09, height: 0.04, color: yellow)
                .rotationEffect(.degrees(30))
                .offset(x: -size * 0.14, y: -size * 0.12)
            lineCapsule(width: 0.09, height: 0.04)
                .rotationEffect(.degrees(-40))
                .offset(x: size * 0.15, y: -size * 0.08)
            lineCapsule(width: 0.09, height: 0.04, color: green)
                .rotationEffect(.degrees(10))
                .offset(x: size * 0.02, y: size * 0.17)
            lineCapsule(width: 0.09, height: 0.04, color: yellow)
                .rotationEffect(.degrees(-20))
                .offset(x: -size * 0.16, y: size * 0.08)
        }
    }

    var cake: some View {
        ZStack {
            roundedBox(width: 0.60, height: 0.30, corner: 0.05, fill: cream)
                .offset(y: size * 0.16)
            roundedBox(width: 0.60, height: 0.16, corner: 0.06, fill: .white)
                .offset(y: -size * 0.06)
            lineCapsule(width: 0.50, height: 0.05, color: pink)
                .offset(y: size * 0.16)
            blob(0.16, fill: yellow, x: 0, y: -0.24)
        }
    }

    var bbq: some View {
        ZStack {
            skewerAcross(y: -0.13, fills: [yellow, green, yellow])
            skewerAcross(y: 0.13, fills: [cream, yellow, cream])
        }
        .rotationEffect(.degrees(-28))
    }

    var chips: some View {
        ZStack {
            Ellipse()
                .fill(yellow)
                .overlay(Ellipse().stroke(black, lineWidth: thinLine))
                .frame(width: size * 0.26, height: size * 0.18)
                .rotationEffect(.degrees(-24))
                .offset(x: -size * 0.14, y: -size * 0.28)
            Ellipse()
                .fill(yellow)
                .overlay(Ellipse().stroke(black, lineWidth: thinLine))
                .frame(width: size * 0.26, height: size * 0.18)
                .rotationEffect(.degrees(20))
                .offset(x: size * 0.12, y: -size * 0.30)
            roundedBox(width: 0.46, height: 0.56, corner: 0.06, fill: yellow)
                .offset(y: size * 0.12)
            blob(0.26, fill: .white, x: 0, y: 0.12, thin: true)
            lineCapsule(width: 0.46, height: 0.045)
                .offset(y: -size * 0.08)
        }
        .rotationEffect(.degrees(-6))
    }

    // MARK: Time

    var shoppingApp: some View {
        ZStack {
            roundedBox(width: 0.40, height: 0.72, corner: 0.10, fill: cream)
            Circle()
                .trim(from: 0.5, to: 1)
                .stroke(black, style: StrokeStyle(lineWidth: thinLine, lineCap: .round))
                .frame(width: size * 0.14, height: size * 0.14)
                .offset(y: -size * 0.08)
            roundedBox(width: 0.24, height: 0.22, corner: 0.04, fill: pink)
                .offset(y: size * 0.05)
            dot(0.055, color: black, x: 0, y: 0.27)
        }
    }

    var livestream: some View {
        ZStack {
            roundedBox(width: 0.66, height: 0.48, corner: 0.10, fill: cream)
                .offset(x: -size * 0.06, y: size * 0.06)
            face(y: 0)
                .offset(x: -size * 0.06, y: size * 0.02)
            blob(0.20, fill: pink, x: 0.30, y: -0.22)
            dot(0.07, color: .white, x: 0.30, y: -0.22)
        }
    }

    var novel: some View {
        ZStack {
            roundedBox(width: 0.36, height: 0.50, corner: 0.05, fill: cream)
                .rotationEffect(.degrees(7))
                .offset(x: -size * 0.17, y: size * 0.02)
            roundedBox(width: 0.36, height: 0.50, corner: 0.05, fill: cream)
                .rotationEffect(.degrees(-7))
                .offset(x: size * 0.17, y: size * 0.02)
            ForEach([-0.08, 0.04], id: \.self) { y in
                lineCapsule(width: 0.16, height: 0.035)
                    .rotationEffect(.degrees(7))
                    .offset(x: -size * 0.17, y: size * y)
                lineCapsule(width: 0.16, height: 0.035)
                    .rotationEffect(.degrees(-7))
                    .offset(x: size * 0.17, y: size * y)
            }
            roundedBox(width: 0.10, height: 0.26, corner: 0.03, fill: pink)
                .offset(y: -size * 0.20)
        }
    }

    /// 摸鱼 — literally "touching fish".
    var slacking: some View {
        ZStack {
            triangle(fill: pink, stroke: true)
                .frame(width: size * 0.24, height: size * 0.32)
                .rotationEffect(.degrees(180))
                .offset(x: size * 0.30)
            Ellipse()
                .fill(cream)
                .overlay(Ellipse().stroke(black, lineWidth: line))
                .frame(width: size * 0.56, height: size * 0.38)
                .offset(x: -size * 0.08)
            dot(0.07, color: black, x: -0.22, y: -0.03)
            lineCapsule(width: 0.045, height: 0.14)
                .offset(x: -size * 0.02)
            Circle()
                .stroke(black, lineWidth: thinLine)
                .frame(width: size * 0.10)
                .offset(x: -size * 0.36, y: -size * 0.28)
            Circle()
                .stroke(black, lineWidth: thinLine)
                .frame(width: size * 0.07)
                .offset(x: -size * 0.24, y: -size * 0.36)
        }
    }

    var lieIn: some View {
        ZStack {
            blob(0.28, fill: pink, x: -0.20, y: -0.02)
            lineCapsule(width: 0.07, height: 0.03)
                .offset(x: -size * 0.25, y: -size * 0.03)
            lineCapsule(width: 0.07, height: 0.03)
                .offset(x: -size * 0.14, y: -size * 0.03)
            roundedBox(width: 0.72, height: 0.30, corner: 0.09, fill: cream)
                .offset(y: size * 0.18)
            blob(0.24, fill: .white, x: 0.22, y: -0.24)
            lineCapsule(width: 0.035, height: 0.08)
                .offset(x: size * 0.22, y: -size * 0.27)
            lineCapsule(width: 0.07, height: 0.035)
                .offset(x: size * 0.25, y: -size * 0.24)
        }
    }

    var social: some View {
        ZStack {
            triangle(fill: cream, stroke: true)
                .frame(width: size * 0.16, height: size * 0.18)
                .rotationEffect(.degrees(60))
                .offset(x: -size * 0.16, y: size * 0.26)
            roundedBox(width: 0.70, height: 0.50, corner: 0.14, fill: cream)
                .offset(y: -size * 0.04)
            outlined(HeartShape(), fill: pink, width: 0.28, height: 0.26, thin: true)
                .offset(y: -size * 0.03)
        }
    }

    // MARK: Money

    var gameTopUp: some View {
        ZStack {
            blob(0.60, fill: yellow, x: -0.04, y: -0.02)
            Text("¥")
                .font(.rounded(size * 0.34, weight: .black))
                .foregroundStyle(black)
                .offset(x: -size * 0.04, y: -size * 0.02)
            plusBadge
                .scaleEffect(1.2)
                .offset(x: size * 0.26, y: size * 0.24)
        }
    }

    var liveGift: some View {
        ZStack {
            blob(0.18, fill: pink, x: -0.09, y: -0.32, thin: true)
            blob(0.18, fill: pink, x: 0.09, y: -0.32, thin: true)
            roundedBox(width: 0.54, height: 0.38, corner: 0.05, fill: cream)
                .offset(y: size * 0.16)
            roundedBox(width: 0.64, height: 0.16, corner: 0.05, fill: cream)
                .offset(y: -size * 0.12)
            lineCapsule(width: 0.09, height: 0.52, color: pink)
                .offset(y: size * 0.06)
        }
    }

    var headphones: some View {
        ZStack {
            Circle()
                .trim(from: 0.5, to: 1)
                .stroke(black, style: StrokeStyle(lineWidth: line * 1.3, lineCap: .round))
                .frame(width: size * 0.56, height: size * 0.56)
                .offset(y: size * 0.02)
            roundedBox(width: 0.20, height: 0.32, corner: 0.08, fill: cream)
                .offset(x: -size * 0.28, y: size * 0.16)
            roundedBox(width: 0.20, height: 0.32, corner: 0.08, fill: cream)
                .offset(x: size * 0.28, y: size * 0.16)
        }
    }

    var keyboard: some View {
        ZStack {
            roundedBox(width: 0.76, height: 0.44, corner: 0.09, fill: cream)
            HStack(spacing: size * 0.06) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: size * 0.02, style: .continuous)
                        .fill(index == 3 ? pink : black)
                        .frame(width: size * 0.09, height: size * 0.09)
                }
            }
            .offset(y: -size * 0.07)
            lineCapsule(width: 0.36, height: 0.07)
                .offset(y: size * 0.09)
        }
    }

    var figure: some View {
        ZStack {
            blob(0.16, fill: cream, x: -0.15, y: -0.32)
            blob(0.16, fill: cream, x: 0.15, y: -0.32)
            roundedBox(width: 0.34, height: 0.30, corner: 0.10, fill: pink)
                .offset(y: size * 0.16)
            blob(0.40, fill: cream, x: 0, y: -0.14)
            dot(0.055, color: black, x: -0.08, y: -0.15)
            dot(0.055, color: black, x: 0.08, y: -0.15)
            lineCapsule(width: 0.60, height: 0.07)
                .offset(y: size * 0.35)
        }
    }

    var coffee: some View {
        ZStack {
            Circle()
                .stroke(black, lineWidth: line)
                .frame(width: size * 0.22)
                .offset(x: size * 0.20, y: size * 0.10)
            roundedBox(width: 0.46, height: 0.38, corner: 0.09, fill: cream)
                .offset(x: -size * 0.06, y: size * 0.10)
            lineCapsule(width: 0.70, height: 0.06)
                .offset(x: -size * 0.02, y: size * 0.35)
            lineCapsule(width: 0.05, height: 0.15)
                .rotationEffect(.degrees(12))
                .offset(x: -size * 0.14, y: -size * 0.26)
            lineCapsule(width: 0.05, height: 0.15)
                .rotationEffect(.degrees(12))
                .offset(x: size * 0.02, y: -size * 0.26)
        }
    }

    var homeGoods: some View {
        ZStack {
            lineCapsule(width: 0.06, height: 0.34)
                .offset(y: size * 0.14)
            lineCapsule(width: 0.36, height: 0.08)
                .offset(y: size * 0.33)
            outlined(TaperedCupShape(), fill: yellow, width: 0.56, height: 0.34)
                .rotationEffect(.degrees(180))
                .offset(y: -size * 0.14)
        }
    }

    var stockUp: some View {
        ZStack {
            blob(0.18, fill: pink, x: -0.04, y: -0.22, thin: true)
            roundedBox(width: 0.16, height: 0.18, corner: 0.03, fill: yellow)
                .offset(x: size * 0.16, y: -size * 0.22)
            lineCapsule(width: 0.22, height: 0.055)
                .rotationEffect(.degrees(48))
                .offset(x: -size * 0.30, y: -size * 0.20)
            outlined(TaperedCupShape(), fill: cream, width: 0.60, height: 0.32)
                .offset(x: size * 0.06, y: size * 0.02)
            dot(0.13, color: black, x: -0.06, y: 0.30)
            dot(0.13, color: black, x: 0.18, y: 0.30)
        }
    }

    var petGoods: some View {
        ZStack {
            blob(0.17, fill: cream, x: -0.27, y: -0.04)
            blob(0.18, fill: cream, x: -0.10, y: -0.22)
            blob(0.18, fill: cream, x: 0.10, y: -0.22)
            blob(0.17, fill: cream, x: 0.27, y: -0.04)
            Ellipse()
                .fill(cream)
                .overlay(Ellipse().stroke(black, lineWidth: line))
                .frame(width: size * 0.40, height: size * 0.32)
                .offset(y: size * 0.16)
        }
    }

    var taxi: some View {
        ZStack {
            roundedBox(width: 0.16, height: 0.10, corner: 0.03, fill: pink)
                .offset(y: -size * 0.29)
            roundedBox(width: 0.42, height: 0.26, corner: 0.09, fill: cream)
                .offset(y: -size * 0.10)
            roundedBox(width: 0.76, height: 0.26, corner: 0.10, fill: yellow)
                .offset(y: size * 0.10)
            blob(0.18, fill: black, x: -0.20, y: 0.24)
            blob(0.18, fill: black, x: 0.20, y: 0.24)
            dot(0.06, color: cream, x: -0.20, y: 0.24)
            dot(0.06, color: cream, x: 0.20, y: 0.24)
        }
    }

    var ticket: some View {
        ZStack {
            roundedBox(width: 0.74, height: 0.42, corner: 0.08, fill: cream)
            ForEach([-0.12, 0.0, 0.12], id: \.self) { y in
                dot(0.05, color: black, x: 0.14, y: y)
            }
            lineCapsule(width: 0.24, height: 0.07, color: pink)
                .offset(x: -size * 0.14, y: -size * 0.05)
            lineCapsule(width: 0.16, height: 0.04)
                .offset(x: -size * 0.18, y: size * 0.07)
        }
        .rotationEffect(.degrees(-14))
    }

    var book: some View {
        ZStack {
            roundedBox(width: 0.46, height: 0.60, corner: 0.06, fill: .white)
                .offset(x: size * 0.06, y: size * 0.05)
            roundedBox(width: 0.46, height: 0.60, corner: 0.06, fill: pink)
                .offset(x: -size * 0.02, y: -size * 0.02)
            lineCapsule(width: 0.045, height: 0.60)
                .offset(x: -size * 0.16, y: -size * 0.02)
            roundedBox(width: 0.20, height: 0.12, corner: 0.03, fill: cream)
                .offset(x: size * 0.05, y: -size * 0.12)
        }
    }

    var gymCard: some View {
        ZStack {
            lineCapsule(width: 0.56, height: 0.08)
            roundedBox(width: 0.10, height: 0.26, corner: 0.04, fill: pink)
                .offset(x: -size * 0.37)
            roundedBox(width: 0.10, height: 0.26, corner: 0.04, fill: pink)
                .offset(x: size * 0.37)
            roundedBox(width: 0.13, height: 0.42, corner: 0.05, fill: cream)
                .offset(x: -size * 0.25)
            roundedBox(width: 0.13, height: 0.42, corner: 0.05, fill: cream)
                .offset(x: size * 0.25)
        }
        .rotationEffect(.degrees(-24))
    }

    // MARK: Building blocks

    private func outlined<S: Shape>(_ shape: S, fill: Color, width: CGFloat, height: CGFloat, thin: Bool = false) -> some View {
        shape
            .fill(fill)
            .overlay {
                shape.stroke(black, style: StrokeStyle(lineWidth: thin ? thinLine : line, lineJoin: .round))
            }
            .frame(width: size * width, height: size * height)
    }

    /// An outlined circle, placed in fractions of `size`.
    private func blob(_ diameter: CGFloat, fill: Color, x: CGFloat, y: CGFloat, thin: Bool = false) -> some View {
        Circle()
            .fill(fill)
            .overlay(Circle().stroke(black, lineWidth: thin ? thinLine : line))
            .frame(width: size * diameter, height: size * diameter)
            .offset(x: size * x, y: size * y)
    }

    private func dot(_ diameter: CGFloat, color: Color, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size * diameter, height: size * diameter)
            .offset(x: size * x, y: size * y)
    }

    /// A stick standing in a bowl with two things threaded on it.
    private func skewerUp(x: CGFloat, tilt: Double, colors: [Color]) -> some View {
        ZStack {
            lineCapsule(width: 0.04, height: 0.56)
            blob(0.16, fill: colors[0], x: 0, y: -0.20, thin: true)
            blob(0.16, fill: colors[1], x: 0, y: -0.04, thin: true)
        }
        .rotationEffect(.degrees(tilt))
        .offset(x: size * x, y: -size * 0.08)
    }

    private func skewerAcross(y: CGFloat, fills: [Color]) -> some View {
        ZStack {
            lineCapsule(width: 0.84, height: 0.04)
            HStack(spacing: size * 0.035) {
                ForEach(Array(fills.enumerated()), id: \.offset) { _, fill in
                    RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                        .fill(fill)
                        .overlay {
                            RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                                .stroke(black, lineWidth: thinLine)
                        }
                        .frame(width: size * 0.15, height: size * 0.17)
                }
            }
            .offset(x: -size * 0.08)
        }
        .offset(y: size * y)
    }
}

/// Flat base, round top: a bun.
private struct DomeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control1: CGPoint(x: rect.minX, y: rect.minY - rect.height * 0.3),
            control2: CGPoint(x: rect.maxX, y: rect.minY - rect.height * 0.3)
        )
        path.closeSubpath()
        return path
    }
}

/// Flat rim, round bottom: a bowl or a pot.
private struct BowlShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control1: CGPoint(x: rect.maxX, y: rect.maxY + rect.height * 0.3),
            control2: CGPoint(x: rect.minX, y: rect.maxY + rect.height * 0.3)
        )
        path.closeSubpath()
        return path
    }
}

/// Wide at the top, a point at the bottom: a pizza slice or a cone.
private struct SliceShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.30),
            control1: CGPoint(x: rect.midX - rect.width * 0.20, y: rect.maxY - rect.height * 0.20),
            control2: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.62)
        )
        path.addArc(
            center: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.30),
            radius: rect.width * 0.25, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false
        )
        path.addArc(
            center: CGPoint(x: rect.maxX - rect.width * 0.25, y: rect.minY + rect.height * 0.30),
            radius: rect.width * 0.25, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.62),
            control2: CGPoint(x: rect.midX + rect.width * 0.20, y: rect.maxY - rect.height * 0.20)
        )
        path.closeSubpath()
        return path
    }
}
