using Plots
plotly()
theme(:dark)

include("model.jl")

function demo(songpath=raw"/home/dms449/Music/Third Lobby/The Epic Everyday/03 O the deep deep love of Jesus.mp3",
             modelfile::AbstractString="data/instrument_model.bson")
  @load modelfile instrument_model
  song = MP3.load(songpath)
  answers = process(song, instrument_model)


  # TODO: make x axis tick marks of format mm:ss
  # TODO: fancy layout
  instrument_labels = reshape(instruments, (1,length(instruments)))
  plot(answers, labels=instrument_labels, title="$(splitpath(songpath)[end])")
end

function plot_song(model, songpath=raw"/home/dms449/Music/Josh Groban/Closer/05 When You Say You Love Me.mp3")
  song = MP3.load(songpath)
  step_size = 2*fs
  answers = process(song, model, step_size)

  num_ticks = 11
  tick_step = div(size(answers,1), num_ticks-1)
  tick_positions = collect(range(0,step=tick_step, length=num_ticks))
  tick_labels = Dates.format.(Time.(0, div.(tick_positions, 60), mod.(tick_positions,60)), "MM:SS")
  
  
  instrument_labels = reshape(instruments, (1,length(instruments)))
  #return plot(answers, ticks=[1:length(answers)], labels=instrument_labels, title="$(splitpath(songpath)[end])", size=(600,800))
  return plot(answers, xticks=(tick_positions, tick_labels), labels=instrument_labels, title="$(splitpath(songpath)[end])", size=(600,800))
end

function process(data, model, step=2*fs)
  parts = partition(data[:,1], 2*fs, step)
  spect = get_spectograms(collect(parts))
  answers = Array{Float32, 2}(undef, length(spect), length(instruments))
  for (i,each) in enumerate(spect)
    answers[i, :] = model(each)
  end
  return answers
end
