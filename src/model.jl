using Flux
using Flux:  mse, throttle, softmax, @epochs, crossentropy, Losses.binarycrossentropy
using BSON: @save, @load
using Random
using Statistics: mean
using CUDA

include("data.jl")
include("utils.jl")


"""
preprocessing of data to get into proper format
"""
pre = Chain(
    x->cat(abs2.(x), angle.(x), dims=3),
    x->reshape(x, (size(x)...,1))
   )

im0 = Chain(
    pre,
    DepthwiseConv((3, 3), 2=>8, pad=(1,1), relu),
    MaxPool((3,3)),

    DepthwiseConv((3, 3), 8=>16, pad=(1,1), relu),
    MaxPool((3,3)),

    DepthwiseConv((3, 3), 16=>32, pad=(1,1), relu),
    MaxPool((3,3)),

    DepthwiseConv((3, 3), 32=>32, pad=(1,1), relu),
    MaxPool((3,3)),

    flatten,
    Dense(384, length(instruments), σ)
   ) 

# the partition size/stride and then the stft size/stride
p_size = 2*fs
p_stride = div(p_size, 2)
stft_div = 128
stft_size = div(p_size, stft_div)
stft_stride = div(stft_size, 2)

""" 
"""
function train!(model=im0, train_dataset=dataset("data/train.json"), test_dataset=dataset("data/test.json"); epochs::Int=3)
  train_keys = dataset_keys(train_dataset)
  test_keys = dataset_keys(test_dataset)

  test_samples = get_data(test_dataset, test_keys, 4, p_size, p_stride, stft_size, stft_stride)[1:5]

  #loss(x, y) = mse(model(x), y)
  loss(x, y) = sum(binarycrossentropy.(model(x), y))
  test_loss(x) = mean([loss(y,z) for (y,z) in x])

  evalcb = () -> @show test_loss(test_samples)
  opt = ADAM()


  for i in 1:epochs
    @info "epoch $i"
    training_samples = get_data(train_dataset, train_keys, 4, p_size, p_stride, stft_size, stft_stride)
    while !isempty(training_samples)

      # put the training data on the gpu
      cu_training_samples = [(CuArray(t[1]), t[2]) for t in training_samples]

      Flux.train!(loss, params(model), cu_training_samples, opt, cb = throttle(evalcb, 1))

      training_samples = get_data(train_dataset, train_keys, 4, p_size, p_stride, stft_size, stft_stride)
    end
    
    train_keys = dataset_keys(train_dataset)
    #test_keys = dataset_keys(test_dataset)
  end
end
#loss(x, y) = mse(c(x), y)
#evalcb = () -> @show loss(test[end][1], test[end][2])
#opt = ADAM()

#@epochs 10 Flux.train!(loss, params(c), train, opt, cb = throttle(evalcb, 5))
