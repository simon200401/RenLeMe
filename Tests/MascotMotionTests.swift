import Foundation

@main
struct MascotMotionTests {
    static func main() {
        for reaction in MascotReaction.allCases {
            expect(reaction.sample(at: -1) == .rest, "No motion before the event")
            expect(reaction.sample(at: 0) == .rest, "Start without a layout jump")
            expect(reaction.sample(at: reaction.duration) == .rest, "Finish at rest")
            expect(reaction.sample(at: reaction.duration + 10) == .rest, "Never loop")

            for step in 0...1_200 {
                let pose = reaction.sample(at: Double(step) / 1_000)
                let values = [pose.scaleX, pose.scaleY, pose.vertical, pose.tilt, pose.gaze, pose.gazeY,
                              pose.leftClosure, pose.rightClosure, pose.wave, pose.arms,
                              pose.smile, pose.openMouth, pose.propLift, pose.propSqueeze, pose.propTilt, pose.blush]
                expect(values.allSatisfy(\.isFinite), "Finite geometry")
                expect((0.85...1.15).contains(pose.scaleX), "Bounded horizontal scale")
                expect((0.85...1.15).contains(pose.scaleY), "Bounded vertical scale")
                expect(abs(pose.vertical) <= 0.07 && abs(pose.tilt) <= 6, "Keep motion inside reserved space")
                expect((0...1).contains(pose.leftClosure) && (0...1).contains(pose.rightClosure), "Valid eyelids")
                expect((0...1).contains(pose.propLift) && (0...1).contains(pose.propSqueeze), "Bounded held props")
                expect((0...1).contains(pose.blush), "Bounded cheek opacity")
            }
            let ending = reaction.sample(at: reaction.duration - 0.0001)
            expect(abs(ending.scaleY - 1) < 0.001 && abs(ending.vertical) < 0.001, "Smooth settling")
        }

        expect(MascotReaction.greeting.sample(at: 0.125).scaleY < 1, "Signature starts with a soft squash")
        expect(MascotReaction.greeting.sample(at: 0.475).wave > 0.9, "Greeting waves once")
        expect(MascotReaction.celebrate.sample(at: 0.425).vertical < -0.05, "Success has a small jump")
        let wink = MascotReaction.celebrate.sample(at: 0.87)
        expect(wink.rightClosure > 0.9 && wink.leftClosure == 0, "Success ends with a single-eye wink")
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
