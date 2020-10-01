include("data.jl")
using Plots
using Wavelets
plotly()
theme(:dark)


function spect(slice::Array)
  sp = spectrogram(slice, 1378, fs=44100)
  return heatmap(sp.time, sp.freq, sp.power, title="power")
end

function waveletTransforms(slice::Array)
  wavs = []
  plots = []

  push!(wavs, wavelet(WT.db2), wavelet(WT.cdf97, WT.Lifting))
  push!(wavs, wavelet(WT.db2), wavelet(WT.cdf97, WT.Lifting))

  for wt in wavs
    xt = dwt(slice, wt)
    p = plot(xt, title=WT.name(wt))
    push!(plots, p)
  end
  
  return plots
end

song_path = "Josh Groban/Closer/08 Broken Vow.mp3"
slice = song_slice(song_path, "00:13","00:22")

p0 = plot(slice, xlabel="samples", ylabel="magnitude", title="time")
p1 = spect(slice)
p2s = waveletTransforms(slice)
#
#
#
l = @layout [a b ; c d]
plot(p0,p1,p2s..., layout=l, size=(1500, 800))






