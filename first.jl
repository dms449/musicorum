using WAV
using FFTW
using DSP
using Plots
plotlyjs()

# constants
sec_to_process = 20

function get_fft(data, sample_freq)
  F = fftshift(fft(data))
  freqs = fftshift(fftfreq(size(data)[1], sample_freq))
  return freqs, F
end

data, fs, nbits, opt = wavread("/home/dms449/workspace/JuliaProjects/MusicalFxExtraction/test/HazySunshine.wav")

samples = data[1:Int64(sec_to_process*fs)]

p1 = plot(samples, title="Time Series");

# get the frequency spectrum
fft_x, fft_y = get_fft(samples, fs)
p2 = plot(fft_x, fft_y, title="Frequency Spectrum");

#plot(p1, p2, layout=(1,2))

