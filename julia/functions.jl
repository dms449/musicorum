using FFTW
using DSP
# gr()
# plotlyjs()


# constants
sec_to_process = 3

function getFreqs(win_len, fs)
  freqs = fftshift(fftfreq(win_len, fs))
  ind = (Int64(win_len/2)+1):length(freqs)
  return freqs[ind]
end

function getFft(data, fs)
  F = fftshift(fft(data))
  freqs = fftshift(fftfreq(size(data)[1], fs))
  return freqs, F
end

function fftExtra(data, fs)
  fftx,ffty = getFft(data, fs)
  ind = (Int64(length(fftx)/2)+1):length(fftx)
  return fftx[ind], abs.(ffty[ind])
end



function stft(data, wlen, hop, fs=44100)
  num_win = Int(floor((length(data)-wlen)/hop) + 1)
  x = Array{Float64}(undef, num_win)
  y = Array{Float64}(undef, Int(wlen/2))
  z = Array{Float64}(undef, Int(wlen/2), num_win)
  #print("num_win=$(num_win) : z size=$(size(z))\n")

  Wb = Array{Float64}(undef, wlen)
  ## Hamming Window Generation
  for n in 1:wlen
    Wb[n] = 0.54-0.46cos(2pi*(n-1)wlen)
  end


  for i in 1:num_win
    # create the array of time values
    x[i] = i

    ind1 = 1+(i-1)*hop
    d = data[ind1:ind1+wlen-1]
    fft_x,fft_y = fftExtra(Wb.*d, fs)
    #print("fft_x=$(size(fft_x)) : fft_y$(size(fft_y)) ")
    z[:,i] = fft_y
    
    if i == num_win
      y = fft_x
    end

  end

  return x,y,z

end  

function spectrogram

end


function get_window(wlen::Int, type::String)
  
end


function plot_fft(fftx,ffty)
  plot(fftx/1000, ffty, xlabel="khz", ylabel="magnitude", title="Frequency Response")
end


#data, fs, nbits, opt = wavread("/home/dms449/workspace/JuliaProjects/MusicalFxExtraction/test/HazySunshine.wav")

#samples = data[1:Int64(sec_to_process*fs)]

#p1 = plot(samples, title="Time Series");

# get the frequency spectrum
#fft_x, fft_y = getFft(samples, fs)
#p2 = plot(fft_x, abs.(fft_y), title="Frequency Spectrum");

#display(plot(p1, p2, layout=4))

