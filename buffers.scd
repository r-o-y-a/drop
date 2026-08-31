(
//~incomingBuffer = Buffer.read(s, p ++ "glass_bow_stroke_long.wav"); // 797
~incomingBuffer = Buffer.read(s, p ++ "wav/" ++ "glass - multiphonics G# long.wav"); // 155 D#
//~incomingBuffer = Buffer.read(s, p ++ "wav/" ++ "glass-overpressure-multiphonics-short.wav"); // 220
//~grainBuffer = Buffer.readChannel(s, p ++ "wav/" ++ "glass_bow_stroke_long.wav", channels: [0]);
//~grainBuffer = Buffer.readChannel(s, p ++ "wav/" ++ "glass-multiphonics-lower-octave.wav", channels: [0]);
//~grainBuffer = Buffer.readChannel(s, p ++ "wav/" ++ "bass-multiphonics.wav", channels: [0]);
~grainBuffer1 = Buffer.readChannel(s, p ++ "wav/" ++ "glass - multiphonics G# long lower oct.wav", channels: [0]);
~grainBuffer2 = Buffer.readChannel(s, p ++ "wav/" ++ "glass - multiphonics G# long.wav", channels: [0]);
)