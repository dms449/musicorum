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
  answers = process(song, model)

  instrument_labels = reshape(instruments, (1,length(instruments)))
  return plot(answers, ticks=[1:length(answers)], labels=instrument_labels, title="$(splitpath(songpath)[end])", size=(600,800))
end

function process(data, model)
  parts = partition(data[:,1], 2*fs, 2*fs)
  spect = get_spectograms(collect(parts))
  answers = Array{Float32, 2}(undef, length(spect), length(instruments))
  for (i,each) in enumerate(spect)
    answers[i, :] = model(each)
  end
  return answers
end
