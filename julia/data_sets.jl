using WAV
include("functions.jl")
  
guitar_file = "/home/dms449/workspace/JuliaProjects/MusicalFxExtraction/wav_samples/HazySunshine.wav"
piano_file = "/home/dms449/workspace/JuliaProjects/MusicalFxExtraction/wav_samples/pianocello.wav"

"""
get a 
"""
function get_sample(filename, seconds=0)
  data, fs , nbits, opt = wavread(filename);
  if (seconds!=0)
    data = get_seconds(data, fs, seconds)
  end
  return data, fs
end

"""
returns a slice of the data based upon the desired number of seconds and offset
"""
function get_seconds(data, sec, fs=44100, offset=0)
  return data[(1+offset):Int64(offset + sec*fs)]
end


function get_data()
  training = Dict()

  instruments = ["guitar", "vocals", "piano", "cello"]

  for dir in readdir("/home/dms449/Music/Training")
    label_names = split(dir, "_")
    f(t) = (t in instruments) ? 1.0 : 0.0
    labels = Dict(l => f(l) for l in label_names)

    for each in readdir("/home/dms449/Music/Training"*"/"*dir)
      println("loading "*each)
      samples, fs, nbits, opt = wavread("/home/dms449/Music/Training"*"/"*dir*"/"*each)
      data = Array{Float64}(undef, 1, Int(2*fs))
      data = [data; windowize(samples[:,1], Int(2*fs), Int(2*fs))]
    end
    training[labels] = data
  end

  test = Dict()

  return training, test
end
