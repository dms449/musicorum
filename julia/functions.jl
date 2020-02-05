using FFTW
using DSP
# gr()
# plotlyjs()

# constants
sec_to_process = 3

function get_freqs(win_len, fs)
  freqs = fftshift(fftfreq(win_len, fs))
  ind = (Int64(win_len/2)+1):length(freqs)
  return freqs[ind]
end

function get_fft(data, fs)
  F = fftshift(fft(data))
  freqs = fftshift(fftfreq(size(data)[1], fs))
  return freqs, F
end

function fft_extra(data, fs)
  fftx,ffty = get_fft(data, fs)
  ind = Int64(floor(length(fftx)/2)+1):length(fftx)
  return fftx[ind], abs.(ffty[ind])
end

function win_size_to_freq_res(win_size, sample_freq=44100)
  return sample_freq/win_size
end

function freq_res_to_win_size(freq_res, sample_freq=44100)
  return sample_freq/freq_res
end


function stft(data, wlen, wshift, fs=44100)
  num_win = Int(floor((length(data)-wlen)/wshift) + 1)
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

    ind1 = 1+(i-1)*wshift
    d = data[ind1:ind1+wlen-1]
    fft_x,fft_y = fft_extra(Wb.*d, fs)
    #print("fft_x=$(size(fft_x)) : fft_y$(size(fft_y)) ")
    z[:,i] = fft_y
    
    if i == num_win
      y = fft_x
    end

  end

  return x,y,z

end  


"""
splits the array of data into as many sub-arrays of length 'wlen' shifted by 
'wshift'. 

Depending on the requested wlen and wshift, there may be samples
at the end of 'data' which are never used.
"""
function windowize(data::Array{Float64,1}, wlen::Int, wshift::Int=1)
  if (wlen > length(data))
    print("window size is larger than the input data")
    return 
  end

  num_win = Int(floor((length(data)-wlen)/wshift) + 1)
  
  ret = Array{Float64}(undef, num_win, wlen) 
  for i in 1:num_win 
    ind1 = 1+(i-1)*wshift 
    ret[i,:] = data[ind1:ind1+wlen-1]
  end
  return ret
end


function plot_fft(fftx,ffty)
  plot(fftx/1000, ffty, xlabel="khz", ylabel="magnitude", title="Frequency Response")
end


#data, fs, nbits, opt = wavread("/home/dms449/workspace/JuliaProjects/MusicalFxExtraction/test/HazySunshine.wav")

#samples = data[1:Int64(sec_to_process*fs)]

#p1 = plot(samples, title="Time Series");

# get the frequency spectrum
#fft_x, fft_y = get_fft(samples, fs)
#p2 = plot(fft_x, abs.(fft_y), title="Frequency Spectrum");

#display(plot(p1, p2, layout=4))

