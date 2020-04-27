using FFTW
using DSP
# gr()
# plotlyjs()

# constants
sec_to_process = 3

function get_freqs(win_len, fs)
  freqs = fftshift(FFTW.fftfreq(win_len, fs))
  ind = (Int64(win_len/2)+1):length(freqs)
  return freqs[ind]
end

function get_fft(data, fs)
  F = fftshift(fft(data))
  freqs = fftshift(FFTW.fftfreq(size(data)[1], fs))
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


"""
Take the short time forier transform of the vector data

###Example
```
```
"""
function stft(data, wlen, stride, fs=44100)
  #@info "size=$(size(data)) type=$(typeof(data))"
  num_win = Int(floor((length(data)-wlen)/stride) + 1)
  x = Array{Float32}(undef, num_win)
  y = Array{Float32}(undef, Int(wlen/2))
  z = Array{Float32}(undef, Int(wlen/2), num_win)
  #print("num_win=$(num_win) : z size=$(size(z))\n")

  Wb = Array{Float32}(undef, wlen)
  ## Hamming Window Generation
  for n in 1:wlen
    Wb[n] = 0.54-0.46cos(2pi*(n-1)wlen)
  end


  for i in 1:num_win
    # create the array of time values
    x[i] = i

    ind1 = 1+(i-1)*stride
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
get the output dimensions of a short-time-forier transform on an input vector 
of length `dlen` with window length `wlen` and stride of `stride`
"""
get_stft_size(d_len, wlen, stride) = div(wlen,2), div(d_len-wlen, stride)+1

"""
partition the collection *data* with window of size *wlen* and shifted by *stride*
"""
function partition(x, wlen::Int, stride::Int=1)
  return ((@view x[i:i+wlen-1]) for i in 1:stride:length(x)-wlen+1)
end


"""
splits the array of data into as many sub-arrays of length 'wlen' shifted by 
'stride'. 

Depending on the requested wlen and stride, there may be samples
at the end of 'data' which are never used.
"""
function windowize(data::Array{Float64,1}, wlen::Int, stride::Int=1)
  if (wlen > length(data))
    print("window size is larger than the input data")
    return 
  end

  num_win = Int(floor((length(data)-wlen)/stride) + 1)
  
  ret = Array{Float64}(undef, num_win, wlen) 
  for i in 1:num_win 
    ind1 = 1+(i-1)*stride 
    ret[i,:] = data[ind1:ind1+wlen-1]
  end
  return ret
end

function conv_size(input, kernel, stride, pad)
  return (input - kernel+2*pad)/stride + 1
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

