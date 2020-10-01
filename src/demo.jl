using Plots
plotly()
#pyplot()
theme(:dark)

include("model.jl")

# TODO automatically hide anything less than 1
# TODO load and show truth for song next to the song data (function 'demo')
# TODO place 2 points for each segment, not one

# a few hard coded song paths for easy referencing
bluegrass_song = raw"/home/dms449/Music/Nickel Creek/Nickel Creek/04 In the House of Tom Bombadil.mp3"
josh_groban_song = raw"/home/dms449/Music/Josh Groban/Closer/08 Broken Vow.mp3"
piano_guys_song = raw"/home/dms449/Music/The Piano Guys/00 More Than Words.mp3"
other_song = raw"/home/dms449/Music/Third Lobby/The Epic Everyday/03 O the deep deep love of Jesus.mp3"

# the partition size/stride and then the stft size/stride
p_size = 2*fs
p_stride = div(p_size, 2)
stft_div = 128
stft_size = div(p_size, stft_div)
stft_stride = div(stft_size, 2)

function song_truth_comparison(truth_file="data/train.json", song="Josh Groban/Closer/05 When You Say You Love Me.mp3", model=im0)
  d = dataset(truth_file)
  if (song ∉ keys(d)) return @error "song=$song is not in dataset=$truth_file" end
  (song_data, label_data) = load_sections(song, d[song]["sections"], p_size, p_stride, stft_size, stft_stride)
  
  # the truth needs to be manipulated a bit
  truth = vcat(label_data'...)


  answers = Array{Float32, 2}(undef, length(song_data), length(instruments))
  for (i, each) in enumerate(song_data)
    answers[i, :] = model(each)
  end

  instrument_labels = reshape(instruments, (1,length(instruments)))

  #TODO: change display labels to only be those plotted
  # only include instruments which have been determined to be present at some point in the song
  a = sum(answers, dims=1)
  ans_col_to_keep = [i for (i, each) in enumerate(a.>9) if each==1]
  answers = answers[:, ans_col_to_keep]
  ans_labels = instrument_labels[ans_col_to_keep] |> x->reshape(x, (1,length(x)))


  t = sum(truth, dims=1)
  truth_col_to_keep = [i for (i, each) in enumerate(t.>1) if each==1]
  truth = truth[:, truth_col_to_keep]
  truth_labels = instrument_labels[truth_col_to_keep] |> x->reshape(x, (1,length(x)))


  #plot(cat(answers,truth_plot), linetype=:stppre, labels=instrument_labels, title="$(splitpath(songpath)[end])")
  #plot(answers, linetype=:steppre, labels=ans_labels, title="answers")
  #return plot(truth, linetype=:steppre, label=truth_labels, title="truth")
  ans_plot = plot(answers, linetype=:steppre, labels=ans_labels, title="answers")
  truth_plot = plot(truth, linetype=:steppre, labels=truth_labels, title="truth")
  l = @layout [a b]
  return plot(ans_plot, truth_plot, layout=l, size=(1200,800))

end

"""

"""
function plot_song(songpath::AbstractString, model)
  song_data = load_entire_song(songpath, p_size, p_stride, stft_size, stft_stride) 

  answers = Array{Float32, 2}(undef, length(song_data), length(instruments))
  for (i, each) in enumerate(song_data)
    answers[i, :] = model(each)
  end

  # only include instruments which have been determined to be present at some point in the song
  s = sum(answers, dims=1)
  answers = filter(x->x>1.0, s)

  num_ticks = 11
  tick_step = div(size(answers,1), num_ticks-1)
  tick_positions = collect(range(0,step=tick_step, length=num_ticks))
  tick_labels = Dates.format.(Time.(0, div.(tick_positions, 60), mod.(tick_positions,60)), "MM:SS")
  
  
  instrument_labels = reshape(instruments, (1,length(instruments)))
  #return plot(answers, ticks=[1:length(answers)], labels=instrument_labels, title="$(splitpath(songpath)[end])", size=(600,800))
  return plot(answers, xticks=(tick_positions, tick_labels), linetype=:steppre, labels=instrument_labels, title="$(splitpath(songpath)[end])", size=(600,800))
end


function plot_instruments_samples()
  data_file = dataset("data/single_instrument.json")

  plots = []
  for (k, v) in data_file
    data, labels = ([], [])
    load_song!(k, v["sections"], data, labels)
    
  end
    

    

end

"""

"""
function sample_data(songpath=other_song, partition_size=p_size, partition_stride=p_stride, stft_size=stft_size, stft_stride=stft_stride)
  return load_song(other_song, p_size, p_stride, stft_size, stft_stride)
end
