include("data.jl")
include("utils.jl")

using Plots
using Wavelets
using Wavelets: wplotim, bestbasistree
using Debugger
plotly()
theme(:dark)


function spect(slice::Array)
  #sp = spectrogram(slice, 1378, fs=44100)
  sp = spectrogram(slice, 2^11, fs=44100)
  return heatmap(sp.time, sp.freq, log10.(sp.power), title="power", c=:jet)
end

function waveletTransforms(slice::Array)
  wavs = []
  myplots = []

  #push!(wavs, wavelet(WT.db2, WT.Lifting), wavelet(WT.cdf97, WT.Lifting))
  push!(wavs, wavelet(WT.db4), wavelet(WT.Coiflet{8}()))

  for wt in wavs
    #xt = dwt(slice, wt, 5)
    tree = bestbasistree(slice, wt)
    xt = wpt(slice, wt, tree)
    #xt = wpt(slice, wt, maketree(slice, :full))
    A = wplotim(xt)

    # shift number so that everything is greater than 0
    A = A .+ abs(minimum(A)) .+ 1
    p = heatmap(log10.(A), title=WT.name(wt), c=:jet)
    #p = heatmap(A, title=WT.name(wt), c=:jet)
    push!(myplots, p)
  end

  return myplots
end



function run(slice)
  p0 = plot(slice, xlabel="samples", ylabel="magnitude", title="time")
  p1 = spect(slice)
  #p2s = waveletTransforms(slice)
  #l = @layout [a b ; c d]
  #return plot(p0,p1,p2s..., layout=l, size=(1400, 800))
  
  l = @layout [a b]
  return plot(p0,p1, layout=l, size=(1400, 800))
end

song1 = "Josh Groban/Closer/08 Broken Vow.mp3"
slice1 = make_dyadic(song_slice(song1, "00:13","00:22"))

song2 = "Nickel Creek/Nickel Creek/04 In the House of Tom Bombadil.mp3"
slice2 = make_dyadic(song_slice(song2, "00:01","00:09"));
