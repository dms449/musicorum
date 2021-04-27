using Plots
using BSON: @load
using Flux: Data.DataLoader
using CUDA
plotly()
theme(:dark)

include("data.jl")
include("utils.jl")
include("model.jl")



function evaluate_dataloader(model, dataloader)


  if dataloader.shuffle
    @warn "dataloader has `shuffle=true` which may not be desired for evaluation"
  end

  y, ŷ = [], []

  for (x, y_) in dataloader
    append!(ŷ, cpu(model.(x)))
    append!(y, cpu(y_))
  end

  truth = vcat(y'...)
  answers = vcat(ŷ'...)


  # answers = Array{Float32, 2}(undef, length(song_data), length(instruments))
  # for (i, each) in enumerate(song_data)
  #   answers[i, :] = model(each)
  # end

  instrument_labels = reshape(instruments, (1,length(instruments)))

  #TODO: change display labels to only be those plotted
  # only include instruments which have been determined to be present at some point in the song
  a = mean(answers, dims=1)
  ans_col_to_keep = [i for (i, each) in enumerate(a.>0.1) if each==1]
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
  l = @layout [a ; b]
  return plot(ans_plot, truth_plot, layout=l, size=(1200,800))
  
end




# Run
# ---


# @add_arg_table! s begin
#     "--dataset", "-d" 
#         help = "the dataset file to evaluate"
#         arg_type = String
#         default = "data/test.json"
#     "--modal", "-m"
#         help = "model file"
#         arg_type = String
#         default = "model/latest_model.bson"
#   end

# parsed_args = parse_args(s)

# model = @load parsed_args["modal"]


# test_loader = DataLoader(load_dataset(test_dataset, p_size, p_stride, stft_size, stft_stride) |> gpu, batchsize=16, shuffle=true)

# results = zeros(length(test_loader), length(instruments))
# for batch in test_loader:
  

# end

# train!(model, training_data, testing_data, epochs=parsed_args["epochs"], model_path=parsed_args["save_as"])
