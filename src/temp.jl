using Plots
using DSP: Periodograms.stft, Periodograms.spectrogram
using MP3
plotly()

#include("functions.jl")
#include("data_sets.jl")
bluegrass_song = raw"/home/dms449/Music/Nickel Creek/Nickel Creek/04 In the House of Tom Bombadil.mp3"
josh_groban_song = raw"/home/dms449/Music/Josh Groban/Closer/08 Broken Vow.mp3"
piano_guys_song = raw"/home/dms449/Music/The Piano Guys/00 More Than Words.mp3"


function multiple_views(;w=22000, h=11000, threshold=10000)
  x,y,z = stft(gsample, w, h);
  y = y[y .< threshold]

  p0 = heatmap(x, y, z[1:length(y),:], xlabel="milliseconds",ylabel="khz", title="w = $(w) : h=$(h)");
  p1 = plot(y, z[1:length(y),1])
  p2 = plot(y, z[1:length(y),2])
  p3 = plot(y, z[1:length(y),3])
  
  l = @layout [a ; b c d]
  plot(p0, p1, p2, p3, layout=l, size=(1500, 900))
    
end

function spect()
  song1 = MP3.load(bluegrass_song)
  section = song1[44100:88200,1]

  sp = spectrogram(section, div(size(section,1),64), fs=44100)
  stft1 = stft(section, div(size(section,1),64) fs=44100)
  p0 = heatmap(sp.time, sp.freq, sp.power, title="power")
  p1 = heatmap(sp.time, sp.freq, angle.(stft1), title="phase")
  l = @layout [a b c]
  plot(p0, p1, p2, layout=l, size=(1500, 700))
end

#threshold = 10000
#
#w1,h1 = 500, 250
#w2,h2 = 5000, 2500
#w3,h3 = 8000, 4000
#w4,h4 = 2000, 250
#w5,h5 = 2000, 1000
#w6,h6 = 22000, 11000
#
##y1 = getFreqs(w1, fs)
##y2 = getFreqs(w2, fs)
##y3 = getFreqs(w3, fs)
#
#x1,y1,z1 = stft(gsample, w1, h1);
#x2,y2,z2 = stft(gsample, w2, h2);
#x3,y3,z3 = stft(gsample, w3, h3);
#x4,y4,z4 = stft(gsample, w4, h4);
#x5,y5,z5 = stft(gsample, w5, h5);
#x6,y6,z6 = stft(gsample, w6, h6);
#
#y1 = y1[y1 .< threshold]
#y2 = y2[y2 .< threshold]
#y3 = y3[y3 .< threshold]
#y4 = y4[y4 .< threshold]
#y5 = y5[y5 .< threshold]
#y6 = y6[y6 .< threshold]
#
#
#p1 = heatmap(x1, y1, z1[1:length(y1),:], xlabel="milliseconds",ylabel="khz", title="w = $(w1) : h=$(h1)");
#p2 = heatmap(x2, y2, z2[1:length(y2),:], xlabel="milliseconds",ylabel="khz", title="w = $(w2) : h=$(h2)");
#p3 = heatmap(x3, y3, z3[1:length(y3),:], xlabel="milliseconds",ylabel="khz", title="w = $(w3) : h=$(h3)");
#p4 = heatmap(x4, y4, z4[1:length(y4),:], xlabel="milliseconds",ylabel="khz", title="w = $(w4) : h=$(h4)");
#p5 = heatmap(x5, y5, z5[1:length(y5),:], xlabel="milliseconds",ylabel="khz", title="w = $(w5) : h=$(h5)");
#p6 = heatmap(x6, y6, z6[1:length(y6),:], xlabel="milliseconds",ylabel="khz", title="w = $(w6) : h=$(h6)");
#
##plot(p1, p2, p3, p4, p5, p6, layout=(3,2), size=(1500, 900))
#plot(p5, p6, layout=(2,1), size=(1500, 900))
#
