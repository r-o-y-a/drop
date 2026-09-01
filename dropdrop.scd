(
s.options.numOutputBusChannels = 10;
s.options.sampleRate = 48000;

s.waitForBoot {

	p = PathName(thisProcess.nowExecutingPath).pathOnly;

	(p ++ "synthdefs.scd").load;
	s.sync;
	(p ++ "analysis.scd").load;
	s.sync;
	(p ++ "routines.scd").load;


};
)

// todo:
// inform granulation
// implement spectral complexity: low complexity = minimal spectral spread + energy isolated to specific freqs (flat)
// inform drops


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


// ~dropDurMonitor = Routine {
// 	loop {
// 		~dropDur.postln;
// 		0.2.wait;
// 	};
// }.play;

// ~p = Routine({
//
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
//
//
// 	/*// KMH ring
// 	~dropRoutine = ~drop.(30, 5, 100, 412, 0.006, 1);
// 	//rrand(1, 10).wait;
// 	~dropRoutine = ~drop.(35, 4, 100, 417, 0.006, 2);
// 	~dropRoutine = ~drop.(30, 6, 100, 417, 0.006, 3);
// 	~dropRoutine = ~drop.(35, 5, 100, 410, 0.006, 4);
// 	~dropRoutine = ~drop.(33, 4, 100, 417, 0.006, 5);
// 	~dropRoutine = ~drop.(34, 6, 100, 419, 0.006, 6);
// 	~dropRoutine = ~drop.(31, 5, 100, 417, 0.006, 7);
// 	~dropRoutine = ~drop.(31, 5, 100, 417, 0.006, 8);*/
//
// }).play;

)

~dropDur.postln;

~dropDur = ~spectralBus.getSynchronous.linlin(0, 1, 0.05, 1.5);

~dropDur = 0.3;
~dropDur = 2;
~dropDur= 7;








// start grain buffer
~grainPlay = Synth(\grain, [\buf, ~grainBuffer1.bufnum, \amp, 0.05, \rate, 1, \richnessBus, ~spectralBus.index]);



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