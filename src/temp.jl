include("data.jl")
include("utils.jl")
using Plots
using LinearAlgebra: normalize
using DSP
using DSP: conv
plotly()
theme(:dark)

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

function spect(s::String=bluegrass_song)
  song1 = MP3.load(s)
  section = song1[44100:88200,1]

  divs = [32, 64, 128]
  l = @layout [a b ; c d ; e f]
  plots = []

  for d in divs
    sp = spectrogram(section, div(size(section,1),d), fs=44100)
    cmplx = stft(section, div(size(section,1),d), fs=44100)

    p0 = heatmap(sp.time, sp.freq, abs2.(cmplx), title="power")

    #th = maximum(abs.(cmplx))/1000
    #cmplx[abs.(cmplx) .<= th] .= 0
   
    p1 = heatmap(sp.time, sp.freq, angle.(cmplx), title="phase")
    push!(plots, p0, p1)

  end
  plot(plots..., layout=l, size=(1500, 700))

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

"""
"""
function prep_spect(sp::Periodograms.Spectrogram)
  ind = Int(ceil(15000/sp.freq[2]))
  return normalize(log10.(sp.power[1:ind+1,:])), sp.time, sp.freq[1:ind+1]
end

function run(slice)
  z, time, freq = prep_spect(spectrogram(slice, 2^11, fs=44100))
  p1 = heatmap(time, freq, z, title="power", c=:jet)
  #p2 = plot(sum(z, dims=1)')
  
  k1 = [
       -1 0 1
       -2 0 2
       -1 0 1
      ]
  k2 = [
       -1 -1 -1 -1 -1 -1
       -1 2 1 1 1 1
       -1 2 3 3 2 2
       -1 2 1 1 1 1
       -1 -1 -1 -1 -1 -1
      ]
  zz = conv(z, k1)
  (i, j) = size(zz)
  p2 = heatmap(zz[4:i-4,5:j-5], c=:jet)


  plot(p1,p2, layout=(2,1), size=(1400, 1000))

end


function compare(slices...)
  myplots = []
  for slice in slices
    p1 = plot(slice, title="time")

    sp = spectrogram(slice, 2^11, fs=44100)
    p2 = heatmap(sp.time, sp.freq, log10.(sp.power), title="power", c=:jet)
    #cmplx = stft(slice, 2^11, fs=44100)
    #p3 = heatmap(sp.time, sp.freq, angle.(cmplx), title="phase")

    push!(myplots, p1, p2)
  end

  plot(myplots..., layout = (length(slices),2), size=(1400, 1000))

end

song1 = "Josh Groban/Closer/08 Broken Vow.mp3"
slice1 = make_dyadic(song_slice(song1, "00:13","00:22"))

song2 = "Nickel Creek/Nickel Creek/04 In the House of Tom Bombadil.mp3"
slice2 = make_dyadic(song_slice(song2, "00:01","00:09"));

song3 = "IRMAS-Sample/Testing/12 What'll I Do - Bud Shank And Bob-4.wav"
slice3 = song_slice(song3, "00:00", "00:05")
