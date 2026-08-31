(
//~incomingBuffer = Buffer.read(s, p ++ "wav/" ++ "glass_bow_stroke_long.wav"); // 797
~incomingBuffer = Buffer.read(s, p ++ "wav/" ++ "glass - multiphonics G# long.wav"); // 155 D#
//~incomingBuffer = Buffer.read(s, p ++ "wav/" ++ "glass-overpressure-multiphonics-short.wav"); // 220
//~grainBuffer = Buffer.readChannel(s, p ++ "wav/" ++ "glass_bow_stroke_long.wav", channels: [0]);
//~grainBuffer = Buffer.readChannel(s, p ++ "wav/" ++ "glass-multiphonics-lower-octave.wav", channels: [0]);
//~grainBuffer = Buffer.readChannel(s, p ++ "wav/" ++ "bass-multiphonics.wav", channels: [0]);
~grainBuffer1 = Buffer.readChannel(s, p ++ "wav/" ++ "glass - multiphonics G# long lower oct.wav", channels: [0]);
~grainBuffer2 = Buffer.readChannel(s, p ++ "wav/" ++ "glass - multiphonics G# long.wav", channels: [0]);



// random drops
SynthDef(\drop, { | freq = 400, dropDur = 0.03, amp = 0.006, out = 0 |
	var sig;
	sig = SinOsc.ar(freq) * EnvGen.kr(Env.perc(0.001, dropDur), doneAction: 2);
	Out.ar(out, sig * amp);
}).add;


// granulation
SynthDef(\grain, { |buf, amp = 0.05, rate = 1, richnessBus = 0|
    var sig, richness, grainRate, grainDur;

    richness = In.kr(richnessBus, 1);

    // fundamental (richness=0) -> dense, short grains
    // rich multiphonic (richness=1) -> sparse, long grains
    grainRate = richness.linlin(0, 1, 50, 5);    // grains/sec: dense -> sparse
    grainDur  = richness.linlin(0, 1, 0.05, 0.4); // grain length: short -> long

    sig = GrainBuf.ar(1, Impulse.kr(grainRate), grainDur, buf,
        LFNoise1.kr.range(0.5, 2), LFNoise2.kr(0.1).range(0, 1), 2);
    Out.ar(0, [sig, sig] * amp);
}).add;
)