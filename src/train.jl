using Flux
using Flux:  mse, throttle, softmax, crossentropy, Losses.binarycrossentropy, outdims, Data.DataLoader, @epochs
using BSON: @save, @load
using Random
using Statistics: mean
using CUDA
using ArgParse
using Plots
plotly()
theme(:dark)


include("data.jl")
include("utils.jl")
include("model.jl")

# the partition size/stride and then the stft size/stride
#p_size = 2*fs
#p_stride = div(p_size, 2)
#stft_div = 128
##stft_size = div(p_size, stft_div)
#stft_size = 2^11
#stft_stride = div(stft_size, 2)
default_data_params=Dict("method"=>"stft", "partition_size"=>2*fs, "partition_stride"=>fs, "stft_size"=>2^11, "stft_stride"=>div(2^11, 2))

loss(ŷ, y) = binarycrossentropy(ŷ, y)
accuracy(ŷ, y) = sum(1 .- abs.(y - ŷ)) / length(y)

function evaluate(model, dataloader)
  l = 0f0
  acc = 0
  for (x,y) in dataloader
    ŷ = model.(x)
    l += sum(loss.(ŷ, y))
    acc += sum(accuracy.(ŷ, y))
  end

  num_samples = dataloader.batchsize*length(dataloader)
  return l/num_samples, acc/num_samples
end


""" 
"""
function train!(model=build_model(), train_dataset=dataset_file("data/simple_train.json"), test_dataset=dataset_file("data/simple_test.json"), data_params::Dict=default_data_params; epochs::Int=10, output_file="models/simple_conv.bson")
  if has_cuda()		# Check if CUDA is available
      @info "CUDA is on"
      CUDA.allowscalar(false)
  end

  train_x, train_y = load_dataset(train_dataset, data_params)
  train_loader = DataLoader( (gpu ∘ collect ∘ zip)(train_x, train_y), batchsize=16, shuffle=true)
  test_loader = DataLoader(load_dataset(test_dataset, data_params) |> gpu, batchsize=16, shuffle=true, partial=false)

  model = model |> gpu

  loss_func(x, y) = loss(model(x), y)
  opt = ADAM()

  # containers for tracking the model performance
  losses = zeros(epochs)
  accuracies = zeros(epochs)

   for i in 1:epochs
     for batch in train_loader
       Flux.train!(loss_func, params(model), batch, opt)
     end

    l, a = evaluate(model, test_loader)
    @info "epoch $i  accuracy=$a  loss=$l"
    losses[i] = l
    accuracies[i] = a

   end

   model = cpu(model)
   @save output_file model losses accuracies

end

function view_model(model_path)
  @load model_path model losses accuracies

  plot(1:length(losses),hcat(losses, accuracies), labels=["loss" "accuracy"], xlabel="epochs", size=(1200, 800))

end

