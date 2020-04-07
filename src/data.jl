using JSON
using Base.Iterators: Stateful, take
using Base.Threads: @spawn
using Dates
using Random: shuffle!, shuffle
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
Get 'num_files' from truth_file by pulling from the Stateful iterator, 'shuffled_keys'.

"""
function get_data(truth_file, shuffled_keys, num_files, partition_size::Int=2*fs, partition_stride::Int=2*fs)
  #global shuffled_files;
  data = []
  labels = []

  # load each song
  futures = Array{Task,1}(undef,num_files)
  for (i, key) in enumerate(take(shuffled_keys, num_files))
    @debug "loading $(split(key, "/")[end])"
    futures[i] = @spawn load_file!(key, truth_file[key]["sections"], data, labels, partition_size, partition_stride)
  end
  map(wait, futures)
  return shuffle!(collect(zip(data, labels)))
end

"""
"""
function load_file!(filename::String, sections, output_data, output_labels, partition_size::Int=2*fs, partition_stride::Int=2*fs)
  song = nothing

  if endswith(filename, "mp3")
    song = MP3.load(joinpath(data_path_root, filename))
  elseif endswith(filename, "wav")
    song, _1, _2, _3 = WAV.wavread(joinpath(data_path_root, filename))
  else
    @warn "$(split(filename, "/")[end]) is not of valid format=(.mp3 | .wav). skipping file."
    return
  end
  # convert to 1d array of type Float32
  song = convert(Array{Float32,1}, song[:,1])

  # parse the song into its respective components
  for s in sections
    slice = song_slice(song, s["start"], s["stop"]) 
    l = build_truth_vector(s["labels"])
    temp = collect(partition(slice[:,1], partition_size, partition_stride))
    append!(output_data, get_spectograms(temp))
    append!(output_labels, fill(l, (size(temp)[1], 1)))
  end
end

"""

"""
function build_truth_vector(input)
  return sum(collect(onehotbatch(input, instruments)),dims=2)
end

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

