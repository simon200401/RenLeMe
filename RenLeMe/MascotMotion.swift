import Foundation

enum MascotReaction: CaseIterable, Equatable {
    case greeting
    case celebrate
    case acknowledge
    case waiting
    case moneyPride
    case foodRelief
    case timeStretch
    case walletHug
    case cupLift
    case clockLift
    case shy
    case headTilt
    case wink

    var isPropInteraction: Bool {
        switch self {
        case .walletHug, .cupLift, .clockLift: true
        default: false
        }
    }

    var duration: Double {
        switch self {
        case .greeting, .acknowledge: 0.8
        case .celebrate: 1.15
        case .waiting: 1.2
        case .moneyPride: 0.9
        case .foodRelief: 1.0
        case .timeStretch: 1.1
        case .walletHug, .cupLift, .clockLift: 0.9
        case .shy, .headTilt, .wink: 0.8
        }
    }

    func sample(at elapsed: Double) -> MascotMotionSample {
        guard elapsed >= 0, elapsed < duration else { return .rest }
        var pose = MascotMotionSample.rest

        switch self {
        case .greeting:
            let squash = pulse(elapsed, from: 0, to: 0.25)
            let nod = pulse(elapsed, from: 0.3, to: 0.65)
            pose.scaleX += squash * 0.045
            pose.scaleY -= squash * 0.065
            pose.vertical = nod * 0.025
            pose.tilt = -nod * 5
            pose.wave = pulse(elapsed, from: 0.2, to: 0.75)
            pose.smile = nod
        case .acknowledge:
            let squash = pulse(elapsed, from: 0, to: 0.22)
            let nod = pulse(elapsed, from: 0.22, to: 0.7)
            pose.scaleX += squash * 0.025
            pose.scaleY -= squash * 0.04
            pose.vertical = nod * 0.028
            pose.tilt = nod * 4
            pose.leftClosure = nod * 0.22
            pose.rightClosure = nod * 0.22
            pose.smile = nod
        case .celebrate:
            let squash = pulse(elapsed, from: 0, to: 0.22)
            let jump = pulse(elapsed, from: 0.2, to: 0.65)
            pose.scaleX += squash * 0.07 - jump * 0.025
            pose.scaleY += -squash * 0.09 + jump * 0.035
            pose.vertical = -jump * 0.065
            pose.arms = jump
            pose.rightClosure = pulse(elapsed, from: 0.72, to: 1.02)
            pose.smile = jump
        case .waiting:
            let glance = pulse(elapsed, from: 0.05, to: 0.65)
            let settle = pulse(elapsed, from: 0.55, to: 1.15)
            pose.gaze = glance * 0.8
            pose.tilt = glance * 5
            pose.scaleY -= settle * 0.035
            pose.leftClosure = settle
            pose.rightClosure = settle
            pose.smile = settle
        case .moneyPride:
            let lift = pulse(elapsed, from: 0.05, to: 0.7)
            pose.scaleY += lift * 0.065
            pose.vertical = -lift * 0.025
            pose.tilt = -lift * 5
            pose.smile = lift
            pose.rightClosure = pulse(elapsed, from: 0.52, to: 0.8)
        case .foodRelief:
            let sigh = pulse(elapsed, from: 0.1, to: 0.9)
            pose.scaleX += sigh * 0.035
            pose.scaleY -= sigh * 0.045
            pose.vertical = sigh * 0.02
            pose.leftClosure = sigh
            pose.rightClosure = sigh
            pose.smile = sigh
        case .timeStretch:
            let stretch = pulse(elapsed, from: 0.08, to: 0.95)
            pose.scaleX -= stretch * 0.04
            pose.scaleY += stretch * 0.07
            pose.tilt = sin(elapsed / duration * .pi * 2) * stretch * 4
            pose.arms = stretch
            pose.leftClosure = stretch
            pose.rightClosure = stretch
            pose.openMouth = pulse(elapsed, from: 0.22, to: 0.75)
        case .walletHug:
            let hug = pulse(elapsed, from: 0.05, to: 0.8)
            pose.scaleX -= hug * 0.025
            pose.scaleY -= hug * 0.035
            pose.propSqueeze = hug
            pose.propLift = hug * 0.4
            pose.gazeY = hug * 0.8
            pose.leftClosure = hug * 0.25
            pose.rightClosure = hug * 0.25
            pose.smile = hug
        case .cupLift:
            let lift = pulse(elapsed, from: 0.05, to: 0.8)
            pose.propLift = lift
            pose.propTilt = -lift * 5
            pose.tilt = lift * 3
            pose.gazeY = lift * 0.8
            pose.smile = lift
        case .clockLift:
            let lift = pulse(elapsed, from: 0.05, to: 0.8)
            pose.propLift = lift
            pose.propTilt = lift * 5
            pose.tilt = -lift * 4
            pose.gaze = lift * 0.35
            pose.gazeY = lift * 0.6
            pose.smile = lift
        case .shy:
            let shy = pulse(elapsed, from: 0.05, to: 0.75)
            pose.scaleX += shy * 0.035
            pose.scaleY -= shy * 0.05
            pose.tilt = -shy * 4
            pose.gazeY = shy * 0.7
            pose.blush = shy
            pose.leftClosure = shy * 0.3
            pose.rightClosure = shy * 0.3
            pose.smile = shy
        case .headTilt:
            let tilt = pulse(elapsed, from: 0.05, to: 0.75)
            pose.tilt = tilt * 5.5
            pose.gaze = -tilt * 0.55
            pose.smile = tilt * 0.6
        case .wink:
            let wink = pulse(elapsed, from: 0.1, to: 0.7)
            pose.rightClosure = wink
            pose.tilt = -wink * 3
            pose.smile = wink
        }
        return pose
    }

    private func pulse(_ time: Double, from start: Double, to end: Double) -> Double {
        guard time > start, time < end else { return 0 }
        let sine = sin((time - start) / (end - start) * .pi)
        return sine * sine
    }
}

struct MascotMotionSample: Equatable {
    var scaleX = 1.0
    var scaleY = 1.0
    var vertical = 0.0
    var tilt = 0.0
    var gaze = 0.0
    var gazeY = 0.0
    var leftClosure = 0.0
    var rightClosure = 0.0
    var wave = 0.0
    var arms = 0.0
    var smile = 0.0
    var openMouth = 0.0
    var propLift = 0.0
    var propSqueeze = 0.0
    var propTilt = 0.0
    var blush = 0.0

    static let rest = MascotMotionSample()

    static func blinkOpenness(at time: Double) -> Double {
        let phase = time.truncatingRemainder(dividingBy: 6)
        if phase < 0.11 { return max(0.08, 1 - phase / 0.11) }
        if phase < 0.22 { return max(0.08, (phase - 0.11) / 0.11) }
        return 1
    }
}
