using Plots
plotly()
theme(:dark)

include("data.jl")
include("utils.jl")
include("model.jl")


function evaluate(model, dataloader)
  y_out = []
  l = 0f0
  acc = 0
  for (x,y) in dataloader
    ŷ = model.(x)
    l += sum(loss.(ŷ, y))
    acc += sum(accuracy.(ŷ, y))
    append!(y_out, )
  end

  return l/length(dataloader), acc/length(dataloader), y_out
end

function plot(test_dataset, model, params)

  test_loader = DataLoader(load_dataset(test_dataset, params["p_size"], params["p_stride"], params["stft_size"], params["stft_stride"]) |> gpu, batchsize=16, shuffle=true)
  loss, accuracy, ŷ = evaluate(model, test_loader)

  
end

function run()
  dataset = dataset("data/test.json")
  params = Dict("p_size"=>)
  model, data_params = @load "latest_conv.bson"
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
