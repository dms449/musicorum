using JSON
using Base.Iterators: Stateful, take
using Base.Threads: @spawn
using Dates
using Random: shuffle!, shuffle
using Flux: onehot, onecold, onehotbatch
import MP3
import WAV
using LinearAlgebra
using DSP: Periodograms.stft, Periodograms.spectrogram
include("utils.jl")
include("instruments.jl")

# TODO: fix hard coded base path
# TODO: currently assuming all songs are sampled at 44100Hz
# TODO: 

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
    futures[i] = @spawn stft_sections(key, truth_file[key]["sections"], partition_size, partition_stride, stft_size, stft_stride)
  end

  # fetch the values from the futures and append them
  for f in futures
    (d,l) = fetch(f)
    append!(data, d)
    append!(labels, l)
  end

  return (shuffle ∘ collect ∘ zip)(data, labels)
end

function load_dataset(d, params::Dict)
  data = []
  labels = []

  songs = keys(d)

  # load each song
  futures = Vector{Task}(undef, length(songs))
  for (i, song_name) in enumerate(songs)
    @debug "loading $(split(song_name, "/")[end])"

    if params["method"] == "stft"
      futures[i] = @spawn stft_sections(song_name, d[song_name]["sections"], params["partition_size"], params["partition_stride"], params["stft_size"], params["stft_stride"])
    else 
      @info "data loading method `$(params["method"])` not recognized"
    end
  end

  # fetch the values from the futures and append them
  for f in futures
    (d,l) = fetch(f)
    append!(data, d)
    append!(labels, l)
  end
  
  return data, labels
end

"""
partition up and calculate the stft of specific sections of a song
"""
function stft_sections(filename::String, sections, partition_size::Int=2*fs, partition_stride::Int=2*fs, stft_size=1376, stft_stride=div(stft_size,2))
  song = read_audio(filename)
  if (song != nothing)
    data = []
    labels = []

    # parse the song into its respective components
    for s in sections
      slice = song_slice(song, s["start"], s["stop"]) 
      l = build_truth_vector(s["labels"])
      temp = collect(partition(slice[:,1], partition_size, partition_stride))

      # get the spectrogram instead of the stft
      #println("size temp = $(size(temp))   typeof = $(typeof(temp))")
      for t in temp
        sp = spectrogram(t, stft_size, stft_stride, fs=fs)

        # get the index at 15kHz and ignore everything higher than that.
        ind = Int(ceil(15000/sp.freq[2]))
        #println("$(typeof(sp.power[1:ind+1,:]))")
        
        preprocess(x) = reshape(LinearAlgebra.normalize(x), (size(x)..., 1, 1))
        append!(data, (preprocess(sp.power[1:ind+1,:]),))
        #append!(data, sp.power[1:ind+1,:])
        

        #break
      end
      
      #append!(data, stft.(temp, stft_size, stft_stride, fs=fs))
      append!(labels, fill(l, (size(temp)[1], 1)))
      #break
    end
  end
  return data, labels
end



"""
partition up and calculate the stft of an entire song
"""
function stft_entire_song(filename::String, partition_size=2*fs, partition_stride=2*fs,  stft_size=1376, stft_stride=div(stft_size,2))
  song = read_audio(filename)
  if (song != nothing)
    return stft.(collect(partition(song[:,1], partition_size, partition_stride)), stft_size, stft_stride, fs=fs)
  end
end

"""

"""
function build_truth_vector(input)
  return convert(Array{Float32,2}, sum(collect(onehotbatch(input, instruments)),dims=2))
end

"""
TODO: currently assumes the Time objects are even seconds
"""
function song_slice(song::Array, start::Time, stop::Time; fs=44100)
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
function song_slice(song::Array, start::String, stop::String; fs=44100)
  t1 = Time(start, "MM:SS")
  t2 = stop=="end" ? Time(0, floor(size(song,1)/fs/60), floor(size(song,1)/fs % 60)) : Time(stop, "MM:SS") 
  return song_slice(song, t1, t2, fs=fs)
end

"""
Get the slice from the song
"""
function song_slice(song::String, start::String, stop::String; fs=44100)
  song = read_audio(song)
  if (song != nothing)
    return song_slice(song, start, stop, fs=fs)
  end
end

"""
open an audio file and load the data
"""
function read_audio(filename::String)
  song = nothing
  if endswith(filename, "mp3")
    song = MP3.load(joinpath(data_path_root, filename))
  elseif endswith(filename, "wav")
    song, _1, _2, _3 = WAV.wavread(joinpath(data_path_root, filename))
  else
    @warn "$(split(filename, "/")[end]) is not of valid format=(.mp3 | .wav). skipping file."
  end

  song = convert(Array{Float32,1}, song[:,1])
  return song
end


function get_spectograms(data, wlen, stride)
  temp = [stft(data[i],wlen, stride)[end] for i in 1:size(data,1)]
  return map(x-> reshape(x, size(x)...,1,1), temp)
end



