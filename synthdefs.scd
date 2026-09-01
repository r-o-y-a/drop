(
//~incomingBuffer = Buffer.read(s, p ++ "wav/" ++ "glass_bow_stroke_long.wav"); // 797
~incomingBuffer = Buffer.read(s, p ++ "wav/" ++ "glass - multiphonics G# long.wav"); // 155 D#
//~incomingBuffer = Buffer.read(s, p ++ "wav/" ++ "glass-overpressure-multiphonics-short.wav"); // 220
//~grainBuffer = Buffer.readChannel(s, p ++ "wav/" ++ "glass_bow_stroke_long.wav", channels: [0]);
//~grainBuffer = Buffer.readChannel(s, p ++ "wav/" ++ "glass-multiphonics-lower-octave.wav", channels: [0]);
//~grainBuffer = Buffer.readChannel(s, p ++ "wav/" ++ "bass-multiphonics.wav", channels: [0]);
~grainBuffer1 = Buffer.readChannel(s, p ++ "wav/" ++ "glass - multiphonics G# long lower oct.wav", channels: [0]);
~grainBuffer2 = Buffer.readChannel(s, p ++ "wav/" ++ "glass - multiphonics G# long.wav", channels: [0]);
~grainBuffer3 = Buffer.readChannel(s, p ++ "wav/" ++ "bass-multiphonics.wav", channels: [0]);



// random drops
SynthDef(\drop, { | freq = 400, dropDur = 0.03, amp = 0.006, out = 0 |
	var sig;
	sig = SinOsc.ar(freq) * EnvGen.kr(Env.perc(0.001, dropDur), doneAction: 2);
	Out.ar(out, sig * amp);
}).add;


~klank = {
// Klank - bank of resonators excited by impulses
var n, p, z;
n = 5;	// number of simultaneous instruments
p = 15;	// number of partials per instrument
	z = `[	// filter bank specification :
				Array.fill(p, { 80 + 10000.0.linrand} ),	// frequencies
				Array.fill(p, { 1.0.rand2 }), 			// amplitudes
				Array.fill(p, { 0.2 + 8.0.rand } )		// ring times
			];
		Pan2.ar(
			Klank.ar(z, Dust.ar(0.7, 0.04)),
			1.0.rand2
		)
};


~klank2 = {
// Klank - excited by noise bursts
var n, p;
var exciter, spec;
n = 5;	// number of simultaneous instruments
p = 8;	// number of partials per instrument
		exciter = Decay.ar(Dust.ar(0.6, 0.001), 3.1, WhiteNoise.ar);
		spec = Array.fill(2, {
			`[
				Array.fill(p, { 80 + 10000.0.linrand} ),
				nil,
				Array.fill(p, { 0.2 + 4.0.rand } )
			]
		});
		Klank.ar(spec, exciter)
};


~struckstring = {
	var root, scale;

	var trig, p, exc, x, freq, s;
	root = rrand(3,6);
	scale = #[0,2,4,5,7,9,11];

	freq = (scale.choose + #[24,36,48,60,72,84].choose + root).midicps;
	exc = BrownNoise.ar(
		Decay2.kr(
			Impulse.kr(#[0.125,0.25,0.375,0.5,0.75,1,1.5,2,3,4].choose,0,[0.05,0.05]
		), 0.005, 0.05));
	s = (Klank.ar(`[
			Array.series(16, freq, freq),
			Array.geom(16,1,rrand(0.7,0.999)),
			Array.fill(16, {rrand(0.1,2.5)})
		], exc) * 0.1).softclip;
};

~scratchy = {  RHPF.ar(BrownNoise.ar([0.5,0.5], -0.49).max(0) * 20, 5000, 1)  };

~windchords = {
	var root, scale, s;

	var trig, p, n, exc, x, base, range;
		//root = rrand(3,6);
		root = 5;
		scale = #[0,2,4,5,7,9,11];
		n = 5;
		exc = BrownNoise.ar([0.007,0.007]) * max(0, LFNoise1.kr(exprand(0.125,0.5), 1.25, -0.25));
		s = (Klank.ar(`[Array.fill(n, {(scale.choose + #[36,48,60,72,84].choose + root).midicps}),nil,Array.fill(n, {rrand(0.1,2.0)})], exc) * 0.1).softclip;
};

// grandulation IV
SynthDef(\grain4, { | out = 0, buf = 0, pos = 0, rate = 0.5, grainRate = 20, dur = 0.1 |
	var n = 10;
	var sig;

	sig = CombL.ar(
		Mix.arFill(n, {
			Pan2.ar(
				GrainBuf.ar(
					1,
					Impulse.kr(grainRate),
					dur,
					buf,
					rate, // .5, .25, .125
					pos
				),
				1.0.rand2
			)
		})
		+ LFNoise2.ar(LFNoise2.kr([0.4, 0.4], 90, 620), LFNoise2.kr([0.3, 0.3], 0.15, 0.18)),
		0.3, 0.3, 3
	);

	Out.ar(out, sig*0.1);
}).add;


)

