(
s.options.numOutputBusChannels = 10;
s.options.sampleRate = 48000;

s.waitForBoot {

	p = PathName(thisProcess.nowExecutingPath).pathOnly ++ "wav/";

	//~incomingBuffer = Buffer.read(s, p ++ "glass_bow_stroke_long.wav"); // 797
	~incomingBuffer = Buffer.read(s, p ++ "glass - multiphonics G# long.wav"); // 155 D#
    //~incomingBuffer = Buffer.read(s, p ++ "glass-overpressure-multiphonics-short.wav"); // 220
	//~grainBuffer = Buffer.readChannel(s, p ++ "glass_bow_stroke_long.wav", channels: [0]);
    //~grainBuffer = Buffer.readChannel(s, p ++ "glass-multiphonics-lower-octave.wav", channels: [0]);
    //~grainBuffer = Buffer.readChannel(s, p ++ "bass-multiphonics.wav", channels: [0]);
	~grainBuffer1 = Buffer.readChannel(s, p ++ "glass - multiphonics G# long lower oct.wav", channels: [0]);
	~grainBuffer2 = Buffer.readChannel(s, p ++ "glass - multiphonics G# long.wav", channels: [0]);





	s.sync;


    // random drops
	SynthDef(\drop, { | freq = 400, dropDur = 0.03, amp = 0.006, out = 0 |
		var sig;
		sig = SinOsc.ar(freq) * EnvGen.kr(Env.perc(0.001, dropDur), doneAction: 2);
		Out.ar(out, sig * amp);
	}).add;

	SynthDef(\sine, { | freq=400, amp=0.3 |
		var sig;
		sig = SinOsc.ar(freq);
		Out.ar(0, sig * amp);
	}).add;


    // granulation
	SynthDef(\grain, { | buf, amp = 0.05, rate = 1, grainRate = 20, grainDur = 0.1 |
		var sig;
		sig = GrainBuf.ar(1, Impulse.kr(grainRate), grainDur, buf, LFNoise1.kr.range(0.5, 2), LFNoise2.kr(0.1).range(0, 1), 2);
		Out.ar(0, [sig, sig] * amp);
	}).add;

	s.sync;




	// incoming buffer to extract data
	~bufIn = {

        var targetFreq = 155;

        var sig, sines;
        var freq, confidence;
        var windowSize = 4096;
        var freqs, amps;
        var tolerance = 10;
        var aAmp = 0;
        var aFreq = 0;
        var currentAmp, isNewMax;

		// mono file
		sig = PlayBuf.ar(1, ~incomingBuffer, BufRateScale.kr(~incomingBuffer), loop:1);

		// output
		//# freq, confidence = FluidPitch.kr(sig, windowSize: windowSize);
		//[freq, confidence].poll(10, \fluidpitch);



		sines = FluidSineFeature.kr(
			sig,
			numPeaks: 20, // return up to 20 sinusoidal peaks (freq + amp)
			order: 1,
			windowSize: 4096, // 2048
			hopSize: 512
		);

		freqs = sines[0];
		amps = sines[1];


        // for the 20 peaks, amplitude is captured into aAmp (keeping max found)
        20.do { |i|
            currentAmp = Select.kr((freqs[i] - targetFreq).abs < tolerance, [0, amps[i]]);
            isNewMax = currentAmp > aAmp;
            aFreq = Select.kr(isNewMax, [aFreq, freqs[i]]);
            aAmp = aAmp.max(currentAmp);
        };


		// send freq 10x/s if target frequency amplitude exceeds 0.0007
        SendReply.kr(Impulse.kr(10), '/sines', [Select.kr(aAmp > 0.0007, [0, aFreq])]);

		//Silent.ar(2);
		Out.ar(0, sig*0.2);

	};



	// drop routine
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


    ~activeStartTime = nil;

	OSCdef(\sines, { | msg |
		var active = msg[3];
        var duration = 0.05; // seconds

		active.postln;

        // make sure the freq is sustained long enough
        if (active > 0, {
            if (~activeStartTime.isNil, {
                ~activeStartTime = Main.elapsedTime;
            });
            if ((Main.elapsedTime - ~activeStartTime) >= duration, {
                "DURATION REACHED".postln;


                // todo:
                // drop duration increases
                // grain buffer affected

                ~dropDur = 3;



            });
        }, {
            ~dropDur = 0.3;
            ~activeStartTime = nil;
        });

	}, '/sines');


};
)



// start grain buffer
(
~grainPlay = Synth(\grain, [
	\buf, ~grainBuffer1.bufnum,
	\amp, 0.05,
	\rate, 1,
	\grainRate, 20,
	\grainDur, 0.1
]);

~grainPlay.set(
	\rate, 1,
	\grainRate, 50,
	\grainDur, 50
);
)

~grainPlay.set(\grainRate, 50);
~grainPlay.set(\grainDur, 100);
~grainPlay.set(\rate, 3);


// start grain buffer 2
(
~grainPlay = Synth(\grain, [
	\buf, ~grainBuffer2.bufnum,
	\amp, 0.05,
	\rate, 1,
	\grainRate, 20,
	\grainDur, 0.1
]);

~grainPlay.set(
	\rate, 2,
	\grainRate, 5,
	\grainDur, 50
);
)


// start multiphonics and analysis
~bufIn.play;



// todo: each glass should have a slightly different frequency
(
~p = Routine({
    /*
    // home
    ~dropRoutine = ~drop.(30, 5, 100, 412, 0.006, 6);
	"play1".postln;
	rrand(1, 10).wait;
	~dropRoutine = ~drop.(35, 4, 100, 417, 0.006, 4);
	"play2".postln;
	~dropRoutine = ~drop.(30, 6, 100, 417, 0.006, 8);
	"play3".postln;
	~dropRoutine = ~drop.(35, 5, 100, 410, 0.006, 3);
	"play4".postln;
	//~dropRoutine = ~drop.(33, 4, 100, 417, 0.006, 7);
	"play5".postln;
	~dropRoutine = ~drop.(34, 6, 100, 419, 0.006, 5);
	"play6".postln;
	//~dropRoutine = ~drop.(31, 5, 100, 417, 0.006, 9);
	"play7".postln;
    */

	// 114
	~dropRoutine = ~drop.(30, 5, 100, 412, 0.006, 1);
	//rrand(1, 10).wait;
	~dropRoutine = ~drop.(35, 4, 100, 417, 0.006, 2);
	~dropRoutine = ~drop.(30, 6, 100, 417, 0.006, 3);
	~dropRoutine = ~drop.(35, 5, 100, 410, 0.006, 4);
	~dropRoutine = ~drop.(33, 4, 100, 417, 0.006, 5);
	~dropRoutine = ~drop.(34, 6, 100, 419, 0.006, 6);
	~dropRoutine = ~drop.(31, 5, 100, 417, 0.006, 7);
	~dropRoutine = ~drop.(31, 5, 100, 417, 0.006, 8);

}).play;
)

~dropDur = 0.3;
~dropDur = 2;
~dropDur= 7;







(
x = Synth(\grain, [
	\buf, ~grainBuffer.bufnum,
	\amp, 0.05,
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

x.set(\grainRate, 50);
x.set(\grainDur, 1);
x.set(\rate, 3);



// stop
~dropRoutine.stop;

~bufInSynth.free;