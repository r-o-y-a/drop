(
~spectralBus = Bus.control(s, 8);

~bufIn = {
    var sig, sines, freqs, amps;
    var shape, spread, flatness, spectralComplexity;

    sig = PlayBuf.ar(1, ~incomingBuffer, BufRateScale.kr(~incomingBuffer), loop: 0);

    sines = FluidSineFeature.kr(
        sig,
        numPeaks: 5,
        order: 1,
		detectionThreshold: -40, // tested in SPEAR
        windowSize: 4096,
        hopSize: 512,
        fftSize: 16384
    );

    freqs = sines[0];

	shape = FluidSpectralShape.kr(sig, windowSize: 4096, hopSize: 512, fftSize: 16384);
    spread   = shape[1]; // in Hz, high spread = wide freq range
    flatness = shape[5]; // in Db, low flatness = tonal (energy in a few freqs)
    //crest    = shape[6]; // in Db, a loud peak poking out overall

    spread   = spread.linlin(3000, 9000, 0, 1).clip(0, 1);
    flatness = flatness.linlin(-15, -5, 0, 1).clip(0, 1);

	// low complexity = low spectral spread + energy in certain freqs
    spectralComplexity = Lag.kr((spread + flatness) * 0.5, 0.3);

	sig = FreeVerb.ar(sig, mix: 1, room: 1, damp: 0.5);
	sig = Pan2.ar(sig, 0);

    Out.kr(~spectralBus, [freqs[0], freqs[1], freqs[2], freqs[3], freqs[4], spectralComplexity, spread, flatness]);
    Out.ar(0, sig * 0.9);
};
)


// (
// ~monitor = Routine({
// 	loop {
// 		~spectralBus.getn(8, { | x |
// 			"spectralComplexity: % | spread: % | flatness: % | freq1: % | freq2: % | freq3: % | freq4: % | freq5: %".format(
// 				x[0].round(0.01),
// 				x[1].round(0.01),
// 				x[2].round(0.01),
// 				x[3].round(1),
// 				x[4].round(1),
// 				x[5].round(1),
// 				x[6].round(1),
// 				x[7].round(1)
// 			).postln;
// 		});
// 		0.2.wait;
// 	}
// }).play;
//
// //~bufInSynth = ~bufIn.play;
// )
// ~monitor.stop;

