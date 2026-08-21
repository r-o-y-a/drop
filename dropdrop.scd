// plays "drops" randomly towards a specified rhythm
// plays randomly from buffers

(
s.options.numOutputBusChannels = 10;
s.options.sampleRate = 48000;

s.waitForBoot {

	~buf = Buffer.read(s, "/Users/roya/Documents/roya/SuperCollider/drop/wav/bass-multiphonics.wav");

	~grainBuffer = Buffer.readChannel(s, "/Users/roya/Documents/roya/SuperCollider/drop/wav/bass-multiphonics.wav", channels: [0]);

	~buffers = [
		Buffer.read(s, "/Users/roya/Documents/roya/SuperCollider/drop/wav/PO-sound03.wav"),
		Buffer.read(s, "/Users/roya/Documents/roya/SuperCollider/drop/wav/PO-sound10.wav"),
		Buffer.read(s, "/Users/roya/Documents/roya/SuperCollider/drop/wav/click.wav"),
		Buffer.read(s, "/Users/roya/Documents/roya/SuperCollider/drop/wav/click-click.wav"),
		Buffer.read(s, "/Users/roya/Documents/roya/SuperCollider/drop/wav/bass.wav"),
		Buffer.read(s, "/Users/roya/Documents/roya/SuperCollider/drop/wav/click-bass.wav"),
		Buffer.read(s, "/Users/roya/Documents/roya/SuperCollider/drop/wav/long-bass-scratch.wav")
	];

	s.sync;


	SynthDef(\drop, { | freq = 400, dropDur = 0.03, amp = 0.3, out = 0 |
		var sig;
		sig = SinOsc.ar(freq) * EnvGen.kr(Env.perc(0.001, dropDur), doneAction: 2);
		Out.ar(out, sig * amp);
	}).add;

	SynthDef(\sine, { | freq=400, amp=0.3 |
		var sig;
		sig = SinOsc.ar(freq);
		Out.ar(0, sig * amp);
	}).add;




	SynthDef(\grain, { | buf, amp = 0.5, rate = 1, grainRate = 20, grainDur = 0.1 |
		var sig;
		sig = GrainBuf.ar(1, Impulse.kr(grainRate), grainDur, buf, rate, 0, 2);
		Out.ar(0, [sig, sig] * amp);
	}).add;


	SynthDef(\sample, { | buf, amp = 0.4 |
		Out.ar(0, PlayBuf.ar(2, buf, BufRateScale.kr(buf), doneAction: 2, loop: 0) * amp);
	}).add;


	s.sync;




	// play incoming buffer silently to extract data
	~bufIn = {
		var sig, sines;
		var freq, confidence;
		var windowSize = 4096;
		var freqs, amps;
		var targetFreq = 440;
		var tolerance = 15;
		var aAmp = 0;

		// mono file
		sig = PlayBuf.ar(1, ~buf, BufRateScale.kr(~buf));

		// output
		//# freq, confidence = FluidPitch.kr(sig, windowSize: windowSize);
		//[freq, confidence].poll(10, \fluidpitch);


		sines = FluidSineFeature.kr(
			sig,
			numPeaks: 20, // return up to 20 sinusoidal peaks
			order: 1,
			windowSize: 4096, // 2048
			hopSize: 512
		);

		freqs = sines[0];
		amps = sines[1];

		20.do { |i|
			aAmp = aAmp.max(
				Select.kr(
					(freqs[i] - targetFreq).abs < tolerance,
					[0, amps[i]]
				)
			);
		};

		SendReply.kr(Impulse.kr(10), '/sines', [aAmp > 0.0007]);

		//Silent.ar(2);
		Out.ar(0, sig);

	};



	// release a drop
	~dropDur = 0.3;
	~drop = { | bpm = 80, randomTime = 5, finalTime = 8, freq = 400, amp = 0.3, out = 0 |

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

	// play sine
	~sine = { | freq = 400, amp = 0.3, time = 5 |

		Routine {
			~sineSynth = Synth(\sine, [\freq, freq, \amp, 0]);

			20.do { |i|
				~sineSynth.set(\amp, amp * (i + 1) / 20);
				0.1.wait;
			};

			time.wait;
			~sineSynth.free;
		}.play;
	};


	// play 4 streams of randomly timed buffers
	~clicks = [
		Routine({
			var sample = ~buffers[0];
			var density = 0.5;
			loop {
				Synth(\sample, [\buf, sample]);
				rrand(0.007, 0.6).pow(density).wait;
			}
		}),
		Routine({
			var sample = ~buffers[4];
			var density = 1;
			loop {
				Synth(\sample, [\buf, sample]);
				rrand(1.3, 4.5).pow(density).wait;
			}
		}),
		Routine({
			var sample = ~buffers[3];
			var density = 3;
			loop {
				Synth(\sample, [\buf, sample]);
				rrand(0.5, 2).pow(density).wait;
			}
		}),
		Routine({
			var sample = ~buffers[5];
			var density = 3;
			loop {
				Synth(\sample, [\buf, sample]);
				rrand(0.2, 4).pow(density).wait;
			}
		})
	];



	OSCdef(\sines, { | msg |
		var active = msg[3];
		active.postln;

		if(active > 0, {
			"THRESHOLD REACHED".postln;
		});
	}, '/sines');




};

)


// start multiphonics and analysis
~bufIn.play;



// todo: each glass should have a slightly different frequency
(
~p = Routine({
	~dropRoutine = ~drop.(30, 5, 70, 390, 0.3, 0);
	"play1".postln;
	rrand(1, 10).wait;
	~dropRoutine = ~drop.(30, 5, 70, 400, 0.3, 1);
	"play2".postln;
}).play;
)

~dropDur = 0.3;
~dropDur = 2;



~playClicks = {
	~clicks.do(_.play);
};

~stopClicks = {
	~clicks.do(_.stop);
};



~sineRoutine = ~sine.(400, 0.3, 5);




(
x = Synth(\grain, [
	\buf, ~grainBuffer.bufnum,
	\amp, 0.5,
	\rate, 1,
	\grainRate, 20,
	\grainDur, 0.1
]);

x.set(
	\rate, 2,
	\grainRate, 5,
	\grainDur, 50
);
)





x.set(\grainRate, 5);
x.set(\grainDur, 1);
x.set(\rate, 1);






// stop
~dropRoutine.stop;
~playClicks.stop;

~sineRoutine.stop;
~sineSynth.free;

~bufInSynth.free;