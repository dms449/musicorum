using JSON
using Base.Iterators: Stateful, take
using Base.Threads: @spawn
using Dates
using Random: shuffle!, shuffle
using Flux: onehot, onecold, onehotbatch
import MP3
import WAV
using DSP: Periodograms.stft, Periodograms.spectrogram
include("utils.jl")

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
global all_training = "data/train.json"
global fs = 44100


"""
dataset(filepath::String ; subset=[], filter_type::Symbol=:include)

Open a json dataset file. 

Optionally filter to include or exclude certain instruments using the keyword
arguments 'subset' to defined the instruments and the 'filter_type' to specify
whether to only include datasets with instruemnts in subset or whether to 
exclude the instruments in subsets.

filter_type ∈  [:include, :exclude]
"""
function dataset(filepath::String ; subset=[], filter_type::Symbol=:include)
  dataset = JSON.parse(read(filepath, String))
  if (!isempty(subset))
    if (filter_type == :include)
      return filter(p-> isempty(filter(s->isempty(s["labels"] ∩ subset), last(p)["sections"])), dataset)
    elseif (filter_type == :exclude)
      return filter(p-> isempty(filter(s->!isempty(s["labels"] ∩ subset), last(p)["sections"])), dataset)
    #elseif (filter_type == :match)
      #return filter(p-> isempty(filter(s->!isempty(s["labels"] == subset), last(p)["sections"])), dataset)
    else
      @warn "unrecognized filter_type symbol = $filter_type. Valid symbols = [:include, :exclude]."
    end
  end
  return dataset
end

function dataset_keys(dataset::Dict, shuffle_keys::Bool=true)
  return shuffle_keys ? Stateful(shuffle(collect(keys(dataset)))) : Stateful(collect(keys(dataset)))
end


"""
get_data(truth_file, shuffled_keys, num_files, partition_size::Int=2*fs, partition_stride::Int=2*fs, stft_size=1376, stft_stride=div(stft_size,2))

Get 'num_files' from truth_file by pulling from the Stateful iterator, 'shuffled_keys'.

"""
function get_data(truth_file, shuffled_keys, num_files, partition_size::Int=2*fs, partition_stride::Int=2*fs, stft_size=1376, stft_stride=div(stft_size,2))
  #global shuffled_files;
  data = []
  labels = []

  # load each song
  futures = Vector{Task}(undef, num_files > length(shuffled_keys) ? length(shuffled_keys) : num_files)
  for (i, key) in enumerate(take(shuffled_keys, num_files))
    @debug "loading $(split(key, "/")[end])"
    futures[i] = @spawn load_sections(key, truth_file[key]["sections"], partition_size, partition_stride, stft_size, stft_stride)
  end

  # fetch the values from the futures and append them
  for f in futures
    (d,l) = fetch(f)
    append!(data, d)
    append!(labels, l)
  end

  # separate phase and magnitude into separate channels
  data = map(x->cat(abs2.(x), angle.(x), dims=4), data)
  
  return (shuffle ∘ collect ∘ zip)(data, labels)
end

"""

"""
function load_sections(filename::String, sections, partition_size::Int=2*fs, partition_stride::Int=2*fs, stft_size=1376, stft_stride=div(stft_size,2))
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
    return stft.(temp, stft_size, stft_stride, fs=fs), fill(l, (size(temp)[1], 1))
  end
end



"""
load a 
"""
function load_song(filename::String, partition_size=2*fs, partition_stride=2*fs,  stft_size=1376, stft_stride=div(stft_size,2))
  song = nothing
  if endswith(filename, "mp3")
    song = MP3.load(joinpath(data_path_root, filename))
  elseif endswith(filename, "wav")
    song, _1, _2, _3 = WAV.wavread(joinpath(data_path_root, filename))
  else
    @warn "$(split(filename, "/")[end]) is not of valid format=(.mp3 | .wav). skipping file."
    return
  end

  return stft.(collect(partition(song[:,1], partition_size, partition_stride)), stft_size, stft_stride, fs=fs)
end

"""

"""
function build_truth_vector(input)
  return sum(collect(onehotbatch(input, instruments)),dims=2)
end

"""
TODO: currently assumes the Time objects are even seconds
"""
function song_slice(song, start::Time, stop::Time; fs=44100)
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
function song_slice(song, start::String, stop::String; fs=44100)
  t1 = Time(start, "MM:SS")
  t2 = stop=="end" ? Time(0, floor(size(song,1)/fs/60), floor(size(song,1)/fs % 60)) : Time(stop, "MM:SS") 
  return song_slice(song, t1, t2, fs=fs)
end


function get_spectograms(data, wlen, stride)
  temp = [stft(data[i],wlen, stride)[end] for i in 1:size(data,1)]
  return map(x-> reshape(x, size(x)...,1,1), temp)
end



