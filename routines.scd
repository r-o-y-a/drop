(
// drop
~dropDur = 0.3;

~drop = { | bpm = 80, randomTime = 5, finalTime = 8, freq = 400, amp = 0.006, out = 0 |
	Routine {
		rrand(0.1, 0.6).wait;
		{
			randomTime > 0
		}.while {
			Synth(\drop, [\freq, freq, \amp, amp, \out, out, \dropDur, ~dropDur]);
			rrand(0.4, 2).wait;
			randomTime = randomTime - 0.4;
		};
		{
			finalTime > 0
		}.while {
			Synth(\drop, [\freq, freq, \amp, amp, \out, out, \dropDur, ~dropDur]);
			(60 / bpm).wait;
			finalTime = finalTime - (60 / bpm);
		};
	}.play;
};


~dropDurRoutine = Routine {
	var richness;
	var lowThresh = 0.33;
	var highThresh = 0.66;
	loop {
		if (~spectralBus.notNil) {
			richness = ~spectralBus.getSynchronous;
			~dropDur = if (richness < lowThresh) {
				0.3
			} {
				if (richness < highThresh) { 1 } { 7 }
			};
		};
		0.2.wait;
	};
}.play;
)