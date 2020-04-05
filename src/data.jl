using JSON
using Base.Iterators: Stateful, take
using Dates
using Random: shuffle!
using Flux: onehot, onecold, onehotbatch
import MP3
import WAV
include("functions.jl")

# TODO: fix hard coded base path
# TODO: currently assuming all songs are sampled at 44100Hz
# TODO: 

string_instruments = ["acoustic_guitar", "electric_guitar", "acoustic_bass", "electric_bass", "mandolin", "banjo", "violin", "cello"]
string_playing_styles = ["strumming", "picking"]
brass_instruments = ["trumpet"]
woodwind_instruments = ["flute", "whistle"]
percussion_instruments = ["drums"]
keyboard = ["piano"]
other_instruments = ["vocals"]
instruments = vcat(string_instruments, brass_instruments, woodwind_instruments, percussion_instruments, keyboard, other_instruments)

basic_families = ["percussion_instruments"=>percussion_instruments, "woodwind_instruments"=>woodwind_instruments, "brass_instruments"=>brass_instruments, "string_instruments"=>string_instruments, "keyboard"=>keyboard, "other_instruments"=>other_instruments]
#hornbostel_sachs = ["Idiophone"]

#instruments = ["guitar", "vocals", "piano", "cello"]
global data_path_root = "/home/dms449/Music"
global fs = 44100

function data_files()
  return JSON.parse(read("data/train.json", String)), JSON.parse(read("data/test.json", String))
end
function data_keys(train::Dict, test::Dict, shuffle_keys::Bool=true)
  train_keys = shuffle_keys ? Stateful(shuffle(collect(keys(train)))) : Stateful(collect(keys(train)))
  test_keys = shuffle_keys ? Stateful(shuffle(collect(keys(test)))) : Stateful(collect(keys(test)))
  return train_keys, test_keys
end
function all_data()
  train_f, test_f = data_files()
  train_k, test_k = data_keys(train_f, test_f)
  return train_f, train_k, test_f, test_k
end


"""
Get some data

**NOTE: This function is STATEFUL.** 
Calling it multiple times will likely result in different data each time.

To reset the state, call 
```
reset_data()
```

"""
function get_data(truth_file, shuffled_keys, num_files, partition_size::Int=2*fs, partition_stride::Int=2*fs)
  #global shuffled_files;
  data = []
  labels = []

  # set up the iterator if it is null
  # This is a shuffled array of the keys of the Dict 'truth_file'
  #if isempty(shuffled_files) shuffled_files = Stateful(shuffle!(collect(keys(truth_file)))) end

  # load each song
  for key in take(shuffled_keys, num_files)
    @debug "loading $(split(key, "/")[end])"
    song = nothing
    if endswith(key, "mp3")
      song = MP3.load(joinpath(data_path_root, key))
    elseif endswith(key, "wav")
      song, _1, _2, _3 = WAV.wavread(joinpath(data_path_root, key))
    else
      @warn "$(split(key, "/")[end]) is not of valid format=(.mp3 | .wav). skipping file."
      continue
    end
    # convert to 1d array of type Float32
    song = convert(Array{Float32,1}, song[:,1])

    # parse the song into its respective components
    for s in truth_file[key]["sections"]
      slice = song_slice(song, s["start"], s["stop"]) 
      l = build_truth_vector(s["labels"])
      temp = collect(partition(slice[:,1], partition_size, partition_stride))
      data = [data; get_spectograms(temp)]
      labels = [labels ; fill(l, (size(temp)[1], 1))]
    end
  end
  return shuffle!(collect(zip(data, labels)))
end

function get_training_samples(num_files)
end

"""

"""
function build_truth_vector(input)
  return sum(collect(onehotbatch(input, instruments)),dims=2)
end
"""
may not be necessary?
"""
#function load_file(file, partition_size=Int(2*44100), stride=Int(2*44100))
#    @debug "loading $(split(file, "/")[end])"
#    song = nothing
#    if endswith(key, "mp3")
#      song = MP3.load(file)
#    elseif endswith(key, "wav")
#      song, _1, _2, _3 = WAV.wavread(file)
#    else
#      @warn "$(split(file, "/")[end]) is not of valid format=(.mp3 | .wav). skipping file."
#      continue
#    end
#
#    # parse the song into its respective components
#    for s in truth_file[key]["sections"]
#      @debug "$(s["start"])"
#      d = song_slice(song, Time(s["start"], "MM:SS"), Time(s["stop"],"MM:SS")) #TODO: handle 'end'
#      l = s["labels"]
#      temp = partition(d[:,1], Int(2*fs), Int(2*fs))
#      data = [data; get_spectograms(temp)]
#      labels = [labels ; fill(l, (size(temp)[1], 1))]
#    end
#
#end

"""
TODO: currently assumes the Time objects are even seconds
"""
function song_slice(song, start::Time, stop::Time, fs=44100)
  t1 = Int(fs*Dates.value(start)/1e9)+1
  t2 = Int(fs*Dates.value(stop)/1e9)
  if t2>length(song) 
    @warn "stop time $stop was greater than song length."
    t2=length(song)
  end
  return length(size(song))==1 ? song[t1:t2] : song[t1:t2,:]
end

"""
TODO: currently assumes the Time objects are even seconds
"""
function song_slice(song, start::String, stop::String, fs=44100)
  t1 = Time(start, "MM:SS")
  t2 = stop=="end" ? Time(0, floor(size(song,1)/fs/60), floor(size(song,1)/fs % 60)) : Time(stop, "MM:SS") 
  return song_slice(song, t1, t2, fs)
end



function get_spectograms(data)
  temp = [stft(data[i],2750, 1375)[end] for i in 1:size(data,1)]
  return map(x-> reshape(x, size(x)...,1,1), temp)
end











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

function load_file(filename::String)
  data = Array{Float64}(undef, 0, Int(2*44100))
  labels = [] 

  if (endswith(filename, ".mp3"))
    

  elseif (endswith(filename, ".wav"))
    samples, fs, nbits, opt = wavread("/home/dms449/Music/Training"*"/"*dir*"/"*each)
    temp = windowize(samples[:,1], Int(2*fs), Int(2*fs))
    data = [data; temp]
    labels = [labels ; fill(label, (size(temp)[1], 1))]

  else
    @info "file with invalid extension: $filename"
  end

end

function load_dir()
  data = Array{Float64}(undef, 0, Int(2*44100))
  labels = [] 

  for dir in readdir("/home/dms449/Music/Training")
    label_names = split(dir, "_")
    f(t) = (t in label_names) ? 1.0 : 0.0
    label = [f(l) for l in instruments]

    for each in readdir("/home/dms449/Music/Training"*"/"*dir)
      println("loading "*each)
      samples, fs, nbits, opt = wavread("/home/dms449/Music/Training"*"/"*dir*"/"*each)
      temp = windowize(samples[:,1], Int(2*fs), Int(2*fs))
      data = [data; temp]
      labels = [labels ; fill(label, (size(temp)[1], 1))]
    end
  end

  return data, labels 
end


