using Flux
using Flux:  mse, throttle, softmax, @epochs
using BSON: @save, @load
using Random

include("data.jl")
include("functions.jl")


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
    Conv((3, 3), 1=>16, pad=(1,1), relu),
    MaxPool((2,3)),

    Conv((3, 3), 16=>32, pad=(1,1), relu),
    MaxPool((2,3)),

    Conv((3, 3), 32=>32, pad=(1,1), relu),
    MaxPool((2,3)),

    x->reshape(x, :, size(x, 4)),
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
function train(model=im0; epochs::Int=5)
  # load the truth files
  train_files,train_keys, test_files, test_keys = all_data()
  test_samples = get_data(test_files, test_keys, 1, Int(2*44100), Int(2*44100))

  loss(x, y) = mse(model(x), y)
  evalcb = () -> @show loss(test_samples[end][1], test_samples[end][2])
  opt = ADAM()
  
  for i in 1:epochs
    @info "epoch $i"
    training_samples = get_data(train_files, train_keys, 5, Int(2*44100), Int(2*44100))
    while !isempty(training_samples)
      Flux.train!(loss, params(model), training_samples, opt, cb = throttle(evalcb, 1))

      training_samples = get_data(train_files, train_keys, 5, Int(2*44100), Int(2*44100))
    end
    
    train_keys, test_keys = data_keys(train_files, test_files)
  end
end
#loss(x, y) = mse(c(x), y)
#evalcb = () -> @show loss(test[end][1], test[end][2])
#opt = ADAM()

#@epochs 10 Flux.train!(loss, params(c), train, opt, cb = throttle(evalcb, 5))
