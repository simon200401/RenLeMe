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
    case dizzy
    case stashWallet
    case pushCup
    case stopClock
    case nod
    case pat
    case pace
    case riseStretch
    case levelUp
    case waveBye
    case startle

    var isPropInteraction: Bool {
        switch self {
        case .walletHug, .cupLift, .clockLift, .stashWallet, .pushCup, .stopClock: true
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
        case .dizzy: 1.0
        case .stashWallet, .pushCup, .stopClock: 1.3
        case .nod: 0.55
        case .pat: 0.7
        case .pace: 2.4
        case .riseStretch: 0.9
        case .levelUp: 1.1
        case .waveBye: 0.6
        case .startle: 0.5
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
            // One full turn while in the air.
            let turn = min(max((elapsed - 0.2) / 0.45, 0), 1)
            pose.spin = turn < 1 ? 360 * (turn * turn * (3 - 2 * turn)) : 0
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
        case .stashWallet:
            // Hugs the wallet tight, then jumps for joy.
            let hug = pulse(elapsed, from: 0.05, to: 0.75)
            pose.propSqueeze = hug
            pose.propLift = hug * 0.5
            pose.scaleX -= hug * 0.03
            pose.gazeY = hug * 0.8
            pose.leftClosure = hug * 0.3
            pose.rightClosure = hug * 0.3
            addJumpSpin(to: &pose, at: elapsed, from: 0.72)
        case .pushCup:
            // Turns away and pushes the cup off to the side.
            let refuse = pulse(elapsed, from: 0.05, to: 0.7)
            pose.propPush = ramp(elapsed, from: 0.1, to: 0.6)
            pose.propTilt = -refuse * 6
            pose.tilt = -refuse * 4
            pose.leftClosure = refuse
            pose.rightClosure = refuse
            addJumpSpin(to: &pose, at: elapsed, from: 0.72)
        case .stopClock:
            // The alarm rattles, both hands press it quiet.
            let ringing = elapsed < 0.45 ? 1.0 : 0
            let press = pulse(elapsed, from: 0.38, to: 0.8)
            pose.propTilt = sin(elapsed * 42) * 5 * ringing
            pose.propSqueeze = press
            pose.scaleY -= press * 0.045
            pose.gazeY = press * 0.8
            addJumpSpin(to: &pose, at: elapsed, from: 0.75)
        case .nod:
            let first = pulse(elapsed, from: 0.02, to: 0.27)
            let second = pulse(elapsed, from: 0.27, to: 0.52)
            pose.vertical = (first + second) * 0.035
            pose.scaleY -= (first + second) * 0.035
            pose.smile = max(first, second)
        case .pat:
            // A comforting little pat.
            let first = pulse(elapsed, from: 0.05, to: 0.35)
            let second = pulse(elapsed, from: 0.35, to: 0.65)
            pose.wave = max(first, second)
            pose.tilt = max(first, second) * 3
            pose.leftClosure = max(first, second) * 0.5
            pose.rightClosure = max(first, second) * 0.5
            pose.smile = max(first, second)
        case .pace:
            // Walks to one side and back, glancing down at the time halfway.
            let cycle = elapsed / duration
            let glance = pulse(elapsed, from: 0.9, to: 1.5)
            pose.shiftX = sin(cycle * 2 * .pi) * 0.11
            pose.vertical = -abs(sin(elapsed * .pi / 0.3)) * 0.018 * pulse(elapsed, from: 0, to: duration)
            pose.gazeY = glance * 0.9
            pose.tilt = glance * 4
        case .riseStretch:
            let crouch = pulse(elapsed, from: 0, to: 0.3)
            let reach = pulse(elapsed, from: 0.25, to: 0.9)
            pose.scaleY += -crouch * 0.1 + reach * 0.12
            pose.scaleX += crouch * 0.06 - reach * 0.05
            pose.vertical = -reach * 0.03
            pose.arms = reach
            pose.leftClosure = reach
            pose.rightClosure = reach
            pose.smile = reach
        case .levelUp:
            // Curls up small, then pops out bigger.
            let curl = pulse(elapsed, from: 0, to: 0.4)
            let pop = pulse(elapsed, from: 0.35, to: 1.1)
            pose.scaleX += -curl * 0.13 + pop * 0.14
            pose.scaleY += -curl * 0.13 + pop * 0.14
            pose.arms = pop
            pose.smile = pop
        case .waveBye:
            let first = pulse(elapsed, from: 0.02, to: 0.3)
            let second = pulse(elapsed, from: 0.3, to: 0.58)
            pose.wave = max(first, second)
            pose.tilt = -max(first, second) * 4
            pose.smile = max(first, second)
        case .startle:
            let jolt = pulse(elapsed, from: 0, to: 0.3)
            pose.vertical = -jolt * 0.06
            pose.scaleY += jolt * 0.1
            pose.scaleX -= jolt * 0.05
        case .dizzy:
            let sway = pulse(elapsed, from: 0, to: duration)
            pose.tilt = sin(elapsed * 15) * 5.5 * sway
            pose.scaleX += sin(elapsed * 15) * 0.03 * sway
            pose.gaze = sin(elapsed * 9) * 0.8 * sway
        }
        return pose
    }

    /// Eases from 0 to 1 and stays there.
    private func ramp(_ time: Double, from start: Double, to end: Double) -> Double {
        let t = min(max((time - start) / (end - start), 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// A jump with one full turn in the air, used to finish the success reactions.
    private func addJumpSpin(to pose: inout MascotMotionSample, at elapsed: Double, from start: Double) {
        let jump = pulse(elapsed, from: start, to: start + 0.5)
        pose.vertical -= jump * 0.065
        pose.arms = max(pose.arms, jump)
        pose.smile = max(pose.smile, jump)
        let turn = min(max((elapsed - start) / 0.5, 0), 1)
        pose.spin = turn > 0 && turn < 1 ? 360 * (turn * turn * (3 - 2 * turn)) : 0
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
    /// A whole-body turn in degrees, separate from the small head tilt.
    var spin = 0.0
    /// How far the held prop has been pushed aside, 0...1.
    var propPush = 0.0
    /// A sideways step, as a fraction of the mascot's size.
    var shiftX = 0.0

    static let rest = MascotMotionSample()

    static func blinkOpenness(at time: Double) -> Double {
        let phase = time.truncatingRemainder(dividingBy: 6)
        if phase < 0.11 { return max(0.08, 1 - phase / 0.11) }
        if phase < 0.22 { return max(0.08, (phase - 0.11) / 0.11) }
        return 1
    }
}
