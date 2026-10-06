import Foundation

@main
struct MascotMotionTests {
    static func main() {
        for reaction in MascotReaction.allCases {
            expect(reaction.sample(at: -1) == .rest, "No motion before the event")
            expect(reaction.sample(at: 0) == .rest, "Start without a layout jump")
            expect(reaction.sample(at: reaction.duration) == .rest, "Finish at rest")
            expect(reaction.sample(at: reaction.duration + 10) == .rest, "Never loop")

            for step in 0...2_500 {
                let pose = reaction.sample(at: Double(step) / 1_000)
                let values = [pose.scaleX, pose.scaleY, pose.vertical, pose.tilt, pose.gaze, pose.gazeY,
                              pose.leftClosure, pose.rightClosure, pose.wave, pose.arms,
                              pose.smile, pose.openMouth, pose.propLift, pose.propSqueeze, pose.propTilt, pose.blush, pose.spin, pose.propPush, pose.shiftX]
                expect(values.allSatisfy(\.isFinite), "Finite geometry")
                expect((0.85...1.15).contains(pose.scaleX), "Bounded horizontal scale")
                expect((0.85...1.15).contains(pose.scaleY), "Bounded vertical scale")
                expect(abs(pose.vertical) <= 0.07 && abs(pose.tilt) <= 6, "Keep motion inside reserved space")
                expect((0...1).contains(pose.leftClosure) && (0...1).contains(pose.rightClosure), "Valid eyelids")
                expect((0...1).contains(pose.propLift) && (0...1).contains(pose.propSqueeze), "Bounded held props")
                expect((0...1).contains(pose.blush), "Bounded cheek opacity")
                expect((0...360).contains(pose.spin), "A turn never exceeds one rotation")
                expect((0...1).contains(pose.propPush) && abs(pose.shiftX) <= 0.12, "Bounded push and step")
            }
            let ending = reaction.sample(at: reaction.duration - 0.0001)
            expect(abs(ending.scaleY - 1) < 0.001 && abs(ending.vertical) < 0.001, "Smooth settling")
        }

        expect(MascotReaction.greeting.sample(at: 0.125).scaleY < 1, "Signature starts with a soft squash")
        expect(MascotReaction.greeting.sample(at: 0.475).wave > 0.9, "Greeting waves once")
        expect(MascotReaction.celebrate.sample(at: 0.425).vertical < -0.05, "Success has a small jump")
        let wink = MascotReaction.celebrate.sample(at: 0.87)
        expect(wink.rightClosure > 0.9 && wink.leftClosure == 0, "Success ends with a single-eye wink")
        let turning = MascotReaction.celebrate.sample(at: 0.425).spin
        expect(turning > 120 && turning < 240, "Success turns once in the air")
        expect(MascotReaction.celebrate.sample(at: 0.7).spin == 0, "The turn is finished before landing")
        expect(abs(MascotReaction.dizzy.sample(at: 0.5).tilt) > 0 || abs(MascotReaction.dizzy.sample(at: 0.55).tilt) > 3,
               "Dizzy sways from side to side")
        expect(MascotReaction.stashWallet.sample(at: 0.4).propSqueeze > 0.9, "Money success hugs the wallet first")
        expect(MascotReaction.pushCup.sample(at: 0.65).propPush > 0.95, "Food success pushes the cup away")
        expect(MascotReaction.stopClock.sample(at: 0.6).propSqueeze > 0.9, "Time success presses the alarm quiet")
        for success in [MascotReaction.stashWallet, .pushCup, .stopClock] {
            expect(success.sample(at: success.duration - 0.3).spin > 90, "Every success ends with the turn")
        }
        expect(MascotReaction.pace.sample(at: 0.6).shiftX > 0.1 && MascotReaction.pace.sample(at: 1.8).shiftX < -0.1,
               "Pacing walks both ways")
        expect(MascotReaction.levelUp.sample(at: 0.2).scaleY < 0.9 && MascotReaction.levelUp.sample(at: 0.72).scaleY > 1.1,
               "Levelling up curls small then pops bigger")
        expect(MascotReaction.riseStretch.sample(at: 0.57).arms > 0.9, "Rising ends in a stretch")
        expect(MascotReaction.nod.sample(at: 0.145).vertical > 0.03 && MascotReaction.nod.sample(at: 0.395).vertical > 0.03,
               "Nods twice")
        let acknowledge = MascotReaction.acknowledge.sample(at: 0.46)
        expect(acknowledge.vertical > 0 && acknowledge.arms == 0, "Gave-in feedback is a gentle nod")
        expect(MascotReaction.waiting.sample(at: 0.35).gaze > 0.7, "Waiting looks at the clock")
        expect(MascotReaction.waiting.sample(at: 0.85).leftClosure > 0.9, "Waiting settles calmly")
        expect(MascotReaction.moneyPride.sample(at: 0.375).scaleY > 1, "Money stands proudly")
        expect(MascotReaction.foodRelief.sample(at: 0.5).scaleY < 1, "Food relaxes")
        let stretch = MascotReaction.timeStretch.sample(at: 0.485)
        expect(stretch.arms > 0.9 && stretch.openMouth > 0.9, "Time stretches and yawns")
        expect(MascotMotionSample.blinkOpenness(at: 0) == 1, "Blink starts open")
        expect(MascotMotionSample.blinkOpenness(at: 0.11) == 0.08, "Blink closes once")
        expect(MascotMotionSample.blinkOpenness(at: 0.22) == 1, "Blink returns to open")
        expect(MascotMotionSample.blinkOpenness(at: 5.9) == 1, "Rest quietly between blinks")
        expect(MascotReaction.walletHug.sample(at: 0.425).propSqueeze > 0.9, "Money hugs the wallet")
        expect(MascotReaction.cupLift.sample(at: 0.425).propTilt < 0, "Food tilts the held cup")
        expect(MascotReaction.clockLift.sample(at: 0.425).propLift > 0.9, "Time raises the held clock")
        expect(MascotReaction.shy.sample(at: 0.4).blush > 0.9, "Shy reaction blushes")
        expect(MascotReaction.headTilt.sample(at: 0.4).tilt > 5, "Curious reaction tilts the head")
        expect(MascotReaction.wink.sample(at: 0.4).rightClosure > 0.9, "Tap reaction winks once")
        print("PASS: \(MascotReaction.allCases.count) reactions, bounded geometry, distinct gestures, and smooth non-looping endings")
    }

    private static func expect(_ condition: Bool, _ message: String) {
        precondition(condition, message)
    }
}
