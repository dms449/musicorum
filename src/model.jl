using Flux
using Flux:  mse, throttle, softmax, @epochs
using BSON: @save, @load
using Random
using Statistics: mean

include("data.jl")
include("utils.jl")

"""
preprocessing of data to get into proper format
"""
pre = Chain(
    x->cat(abs2.(x), angle.(x), dims=3),
    x->reshape(x, (size(x)...,1))
   )

im2 = Chain(
    Conv((4, 4), 1=>8, pad=(1,1), relu),
    #MaxPool((3,3)),
    MaxPool((4,4)),

    Conv((4, 4), 8=>16, pad=(1,1), relu),
    #MaxPool((3,3)),
    MaxPool((4,4)),

    Conv((4, 4), 16=>32, pad=(1,1), relu),
    #MaxPool((3,3)),
    MaxPool((4,4)),

    #Conv((3, 3), 32=>32, pad=(1,1), relu),
    #MaxPool((3,3)),
    #MaxPool((4,4)),

    x->reshape(x, prod(size(x))),
    Dense(640, length(instruments), σ)
   )

im3 = Chain(
    Conv((3, 3), 1=>8, pad=(1,1), relu),
    MaxPool((2,3)),

    Conv((3, 3), 8=>16, pad=(1,1), relu),
    MaxPool((2,3)),

    Conv((3, 3), 16=>16, pad=(1,1), relu),
    MaxPool((2,3))

    #Conv((3, 3), 16=>16, pad=(1,1), relu),
    #MaxPool((2,3)),

    #x->reshape(x, :, size(x, 4))

    #Dense(5472, length(instruments))
   )

im4 = Chain(
    Conv((3, 7), 1=>16, pad=(1,1), relu),
    MaxPool((2,2)),

    Conv((3, 5), 16=>32, pad=(1,1), relu),
    MaxPool((2,2)),

    Conv((3, 3), 32=>32, pad=(1,1), relu),
    MaxPool((2,2)),

    Conv((3, 3), 32=>32, pad=(1,1), relu),
    MaxPool((2,2)),

    Conv((3, 3), 32=>32, pad=(1,1), relu),
    MaxPool((2,2)),

    x->reshape(x, :, size(x, 4)),
    
    Dense(1344, length(instruments))
   )

im0 = Chain(

    Conv((3,3), 1=>1, pad = 1),
    MaxPool((2,2)),

    Conv((3,3), 1=>1, pad = 1),
    MaxPool((2,2)),

    Conv((3,3), 1=>1, pad = 1),
    MaxPool((2,2)),

    #Conv((5,5), 16=>16, pad = 1),
    #MaxPool((3,3)),

    x->reshape(x, :, size(x, 4)),

    Dense(1197,length(instruments))
    #softmax
   )

# the partition size/stride and then the stft size/stride
p_size = 1*fs
p_stide = div(p_size, 2)
stft_size = 800
stft_stide = div(stft_size, 2)

""" 
"""
function train!(model=im2, train_dataset=dataset("data/train.json"), test_dataset=dataset("data/test.json"); epochs::Int=3)
  train_keys = dataset_keys(train_dataset)
  test_keys = dataset_keys(test_dataset)

  test_samples = get_data(test_dataset, test_keys, 5, p_size, p_stride, stft_size, stft_stide)[1:5]

  loss(x, y) = crossentropy(model(x), y)
  test_loss(x) = mean([loss(y,z) for (y,z) in x])

  evalcb = () -> @show test_loss(test_samples)
  opt = ADAM()

  
  for i in 1:epochs
    @info "epoch $i"
    training_samples = get_data(train_dataset, train_keys, 5, p_size, p_stride, stft_size, stft_stide)
    while !isempty(training_samples)
      Flux.train!(loss, params(model), training_samples, opt, cb = throttle(evalcb, 1))

      training_samples = get_data(train_dataset, train_keys, 5, p_size, p_stride, stft_size, stft_stide)
    end
    
    train_keys = dataset_keys(train_dataset)
    #test_keys = dataset_keys(test_dataset)
  end
end
#loss(x, y) = mse(c(x), y)
#evalcb = () -> @show loss(test[end][1], test[end][2])
#opt = ADAM()

#@epochs 10 Flux.train!(loss, params(c), train, opt, cb = throttle(evalcb, 5))
