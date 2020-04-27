using Flux
using Flux:  mse, throttle, softmax, @epochs
using BSON: @save, @load
using Random

include("data.jl")
include("utils.jl")


im2 = Chain(
    Conv((3, 3), 1=>8, pad=(1,1), relu),
    MaxPool((2,2)),

    Conv((3, 3), 8=>16, pad=(1,1), relu),
    MaxPool((2,2)),

    Conv((3, 3), 16=>16, pad=(1,1), relu),
    MaxPool((2,2)),

    #x->reshape(x, :, size(x, 4)),
   )

im3 = Chain(
    Conv((3, 3), 1=>8, pad=(1,1), relu),
    MaxPool((2,3)),

    Conv((3, 3), 8=>16, pad=(1,1), relu),
    MaxPool((2,3)),

    Conv((3, 3), 16=>16, pad=(1,1), relu),
    MaxPool((2,3)),

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


""" 
"""
function train!(model=im0, train_dataset=dataset("data/train.json"), test_dataset=dataset("data/test.json"); epochs::Int=5)
  train_keys = dataset_keys(train_dataset)
  test_keys = dataset_keys(test_dataset)
  
  test_samples = get_data(test_dataset, test_keys, 1, Int(2*44100), Int(2*44100))

  loss(x, y) = mse(model(x), y)
  evalcb = () -> @show loss(test_samples[end][1], test_samples[end][2])
  opt = ADAM()
  
  for i in 1:epochs
    @info "epoch $i"
    training_samples = get_data(train_dataset, train_keys, 5, Int(2*44100), Int(2*44100))
    while !isempty(training_samples)
      Flux.train!(loss, params(model), training_samples, opt, cb = throttle(evalcb, 1))

      training_samples = get_data(train_dataset, train_keys, 5, Int(2*44100), Int(2*44100))
    end
    
    train_keys = dataset_keys(train_dataset)
    test_keys = dataset_keys(test_dataset)
  end
end
#loss(x, y) = mse(c(x), y)
#evalcb = () -> @show loss(test[end][1], test[end][2])
#opt = ADAM()

#@epochs 10 Flux.train!(loss, params(c), train, opt, cb = throttle(evalcb, 5))
