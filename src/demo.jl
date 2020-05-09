using Plots
plotly()
theme(:dark)

include("model.jl")

# a few hard coded song paths for easy referencing
bluegrass_song = raw"/home/dms449/Music/Nickel Creek/Nickel Creek/04 In the House of Tom Bombadil.mp3"
josh_groban_song = raw"/home/dms449/Music/Josh Groban/Closer/08 Broken Vow.mp3"
piano_guys_song = raw"/home/dms449/Music/The Piano Guys/00 More Than Words.mp3"
other_song = raw"/home/dms449/Music/Third Lobby/The Epic Everyday/03 O the deep deep love of Jesus.mp3"

# the partition size/stride and then the stft size/stride
p_size = 1*fs
p_stide = div(p_size, 2)
stft_size = 800
stft_stide = div(stft_size, 2)

function demo(songpath=other_song, modelfile::AbstractString="data/instrument_model.bson")
  @load modelfile instrument_model
  song = MP3.load(songpath)
  answers = process(song, instrument_model)


  # TODO: make x axis tick marks of format mm:ss
  # TODO: fancy layout
  instrument_labels = reshape(instruments, (1,length(instruments)))
  plot(answers, labels=instrument_labels, title="$(splitpath(songpath)[end])")
end

"""

"""
function plot_song(songpath::AbstractString, model)
  song_data = load_song(songpath, p_size, p_stride, stft_size, stft_stride) 
  song_data = map(x->cat(abs2.(x), angle.(x), dims=4), song_data)

  answers = Array{Float32, 2}(undef, length(song_data), length(instruments))
  for (i, each) in enumerate(song_data)
    answers[i, :] = model(each)
  end

  num_ticks = 11
  tick_step = div(size(answers,1), num_ticks-1)
  tick_positions = collect(range(0,step=tick_step, length=num_ticks))
  tick_labels = Dates.format.(Time.(0, div.(tick_positions, 60), mod.(tick_positions,60)), "MM:SS")
  
  
  instrument_labels = reshape(instruments, (1,length(instruments)))
  #return plot(answers, ticks=[1:length(answers)], labels=instrument_labels, title="$(splitpath(songpath)[end])", size=(600,800))
  return plot(answers, xticks=(tick_positions, tick_labels), labels=instrument_labels, title="$(splitpath(songpath)[end])", size=(600,800))
end


function plot_instruments_samples()
  data_file = dataset("data/single_instrument.json")

  plots = []
  for (k, v) in data_file
    data, labels = ([], [])
    load_song!(k, v["sections"], data, labels)
    
  end
    

    

end
