using Plots
using FFTW
using DSP
# gr()
# plotlyjs()


# constants
sec_to_process = 4

function get_fft(data, fs)
  F = fftshift(fft(data))
  freqs = fftshift(fftfreq(size(data)[1], fs))
  return freqs, F
end

function fft_extra(data, fs)
  fftx,ffty = get_fft(data, fs)
  ind = Int64(length(fftx)/2):length(fftx)
  return fftx[ind], abs.(ffty[ind])
end

function stft(data, wlen, hop)
  num_win = floor((length(data)-wlen)/hop) + 1
  ret = Array{}(undef, num_win)

  Wb = Array(Float64, wlen)
  ## Hamming Window Generation
  for n in 1:N  
    Wb[n] = 0.54-0.46cos(2pi*(n-1)/N)
  end

  

end  


function plot_fft(fftx,ffty)
  plot(x/1000, y, xlabel="khz", ylabel="magnitude", title="Frequency Response")
end


#data, fs, nbits, opt = wavread("/home/dms449/workspace/JuliaProjects/MusicalFxExtraction/test/HazySunshine.wav")

#samples = data[1:Int64(sec_to_process*fs)]

#p1 = plot(samples, title="Time Series");

# get the frequency spectrum
#fft_x, fft_y = get_fft(samples, fs)
#p2 = plot(fft_x, abs.(fft_y), title="Frequency Spectrum");

#display(plot(p1, p2, layout=4))

