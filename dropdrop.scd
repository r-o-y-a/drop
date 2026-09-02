(
s.options.memSize = 8192 * 8;
s.options.numBuffers = 1024 * 16;
s.options.numOutputBusChannels = 10;
s.options.sampleRate = 48000;

s.waitForBoot {

	~limiterGroup = Group.tail(s);
	~limiter = Synth(\masterLimiter, [\out, 0], ~limiterGroup);

	p = PathName(thisProcess.nowExecutingPath).pathOnly;

	(p ++ "synthdefs.scd").load;
	s.sync;
	(p ++ "analysis.scd").load;
	s.sync;
	(p ++ "routines.scd").load;

};
)



~beat = Synth(\beat, [\impulse, 0]);
~beat.set(\impulse, 6);
~beat.set(\impulse, 0);
~beat = Synth(\beat);
(
	Tdef(\beats, {
		loop {
			if (0.5.coin) { ~beat = Synth(\beat, [\impulse, 0]); };
			rrand(1.0, 4.0).wait;
		}
	}).play;
)



//// test ////
(
SynthDef(\iter2, { |freq1 = 157, dev = 1.005, amp = 0, filterFreq = 400, filterQ = 0.6 |

    var temp, sum = 0;

    12.do { |count|
        temp = SinOsc.ar(
            Lag.kr(freq1, Rand(0.01, 0.05))
            * (count + 1)
            * LFNoise1.kr(Rand(0.05, 0.1) ! 2)
            .range(dev.reciprocal, dev)
        );

        temp = temp
        * LFNoise1.kr(Rand(0.05, 4) ! 2)
        .exprange(0.01, 1);

        sum = sum + temp;
    };

    sum = Mix(sum) * 0.05;
    sum = sum * Lag3.kr(amp, 1);

    Out.ar(0, BPF.ar(sum, filterFreq, filterQ));
}).add;
)

// test synthdef
~test = Synth(\iter2, [\freq1, 60, \amp, 0.2, \filterFreq, 400, \filterQ, 0.6]);



////////// start sounds ///////////

(
~bufInSynth = ~bufIn.play;

~spectralMonitor = Routine {
    loop {
        if (~spectralBus.notNil) {
            var v = ~spectralBus.getnSynchronous(8);
            // return strongest freq 1-5, then spectral complexity, spread, flatness
            v[0..4].collect(_.round(1)) ++ [v[5].round(0.01), v[6].round(0.01), v[7].round(0.01)];
        }.postln;
        0.2.wait;
    };
}.play;
)

//////////// grains ///////////////

///// sample buffer ////

(
Tdef(\sampleCloud).stop;
~activeCount = 0;
Tdef(\sampleCloud, {
	loop {
		if (~activeCount < 5) {
			var synth, pos, dur;
			pos = rrand(0.1, 0.3);
			dur = rrand(0.02, 0.15);
			synth = Synth(\samp4, [
				\buf, ~sampleBuffer,
				//\pos, pos,
				\pos, 0.1,
				\rate, 0.02, // 0.125
				\dur, 0.05,
				\atk, 0.001,
				\sus, rrand(2.0, 6.0),
				\rel, rrand(2.0, 5.0),
			]);
			~activeCount = ~activeCount + 1;
			synth.onFree {
				~activeCount = ~activeCount - 1;
			};
		};
		rrand(1.5, 4.0).wait;
	}
}).play;
)




// test w freeze
(
Tdef(\sampleCloud).stop;
~activeCount = 0;
~activeSynths = Set.new;
~freezeActive = false;

Tdef(\sampleCloud, {
	loop {
		if (~activeCount < 5) {
			var synth, pos, dur, sus, rel;
			pos = rrand(0.1, 0.3);
			dur = rrand(0.02, 0.15);
			sus = rrand(2.0, 6.0);
			rel = rrand(2.0, 5.0);
			synth = Synth(\samp4, [
				\buf, ~sampleBuffer,
				\pos, 0.1,
				\rate, 0.02,
				\dur, 0.05,
				\atk, 0.001,
				\rel, rel,
				\gate, 1
			]);
			~activeCount = ~activeCount + 1;
			~activeSynths.add(synth);
			synth.onFree {
				~activeCount = ~activeCount - 1;
				~activeSynths.remove(synth);
			};

			// mimic original fixed-duration behavior: release after `sus` seconds,
			// unless freeze is active — then wait until freeze is lifted
			fork {
				sus.wait;
				while { ~freezeActive } { 0.2.wait };
				if (synth.isPlaying) { synth.set(\gate, 0) };
			};
		};
		rrand(1.5, 4.0).wait;
	}
}).play;
)

~freezeActive = true;   // hold all current & newly-timed-out synths open
~freezeActive = false;  // release them (they'll close out on their next check, within 0.2s)




//Synth(\grain4, [\buf, ~grainBuffer3, \pos, 0.4, \rate, 0.25, \grainRate, 70, \dur, 1]);
//Synth(\grain4, [\buf, ~grainBuffer3, \pos, 0.4, \rate, 0.56, \grainRate, 20, \dur, 0.7]);


(
Tdef(\grainCloud).stop;
~activeCount = 0;

Tdef(\grainCloud, {
	loop {
		if (~activeCount < 5) {
			var synth, pos, dur, rate;

			pos = rrand(0.1, 0.3);
			rate = rrand(0.25, 0.6);
			dur = rrand(0.02, 0.15);

			synth = Synth(\grain4, [
				\buf, ~grainBuffer3,
				\pos, pos,
				\rate, 1,
				\grainRate, rrand(40, 150),
				\dur, dur,
				\amp, 0.08,
				\atk, 0.001,
				\sus, rrand(2.0, 6.0),
				\rel, rrand(2.0, 5.0)
			]);

			~activeCount = ~activeCount + 1;

			synth.onFree {
				~activeCount = ~activeCount - 1;
			};
		};

		rrand(1.5, 4.0).wait;
	}
}).play;
)












/////////// unused ///////////////


(
~partialVoices = 5.collect { | i |
    Synth(\grain2, [
        \buf, ~grainBuffer1,
        \spectralBus, ~spectralBus.index,
        \busOffset, i,
        \grainRate, [7, 11, 15, 19, 23][i],
        \amp, 0.08
    ]);
};
)


(
~grainPlay = Synth(\grain, [\buf, ~grainBuffer3.bufnum, \amp, 0.05, \rate, 1,  \spectralBus, ~spectralBus.index + 5]);


~grainPlay = Synth(\grain, [
	\buf, ~grainBuffer3.bufnum,
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




////// todo ////
~klank.play;
~klank2.play;
~struckstring.play;
~scratchy.play;
~windchords.play;



//////////// drops ////////////////

// ~dropDurMonitor = Routine {
// 	loop {
// 		~dropDur.postln;
// 		0.2.wait;
// 	};
// }.play;

(
~p = Routine({

// 	// home
// 	~dropRoutine = ~drop.(30, 5, 100, 412, 0.006, 6);
// 	"play1".postln;
// 	rrand(1, 10).wait;
// 	~dropRoutine = ~drop.(35, 4, 100, 409, 0.006, 4);
// 	"play2".postln;
// 	~dropRoutine = ~drop.(30, 6, 100, 417, 0.006, 8);
// 	"play3".postln;
// 	~dropRoutine = ~drop.(35, 5, 100, 410, 0.006, 3);
// 	"play4".postln;
// 	~dropRoutine = ~drop.(33, 4, 100, 420, 0.006, 7);
// 	"play5".postln;
// 	~dropRoutine = ~drop.(34, 6, 100, 419, 0.006, 5);
// 	"play6".postln;
// 	~dropRoutine = ~drop.(31, 5, 100, 417, 0.006, 9);
// 	"play7".postln;
// 	~dropRoutine = ~drop.(31, 5, 100, 413, 0.006, 8);
// 	"play8".postln;


	// KMH ring
 	~dropRoutine = ~drop.(30, 5, 100, 412, 0.006, 1);
 	rrand(1, 10).wait;
 	~dropRoutine = ~drop.(35, 4, 100, 417, 0.006, 2);
	rrand(1, 10).wait;
 	~dropRoutine = ~drop.(30, 6, 100, 417, 0.006, 3);
	rrand(1, 10).wait;
 	~dropRoutine = ~drop.(35, 5, 100, 410, 0.006, 4);
	rrand(1, 10).wait;
 	~dropRoutine = ~drop.(33, 4, 100, 417, 0.006, 5);
	rrand(1, 10).wait;
 	~dropRoutine = ~drop.(34, 6, 100, 419, 0.006, 6);
	rrand(1, 10).wait;
 	~dropRoutine = ~drop.(31, 5, 100, 417, 0.006, 7);
	rrand(1, 10).wait;
 	~dropRoutine = ~drop.(31, 5, 100, 417, 0.006, 8);
}).play;
)

Tdef(\beats).stop;
Tdef(\beats).play;
Tdef(\beats, { loop { ~beat.play; 2.wait } }).play;


// ~dropDur.postln;
//
// ~dropDur = ~spectralBus.getSynchronous.linlin(0, 1, 0.05, 1.5);
//
// ~dropDur = 0.3;
// ~dropDur = 2;
// ~dropDur= 7;












// stop
~dropRoutine.stop;

~bufInSynth.free;