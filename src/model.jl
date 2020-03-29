using Flux
using Flux:  mse, throttle, softmax, @epochs
using Random

include("data.jl")
include("functions.jl")

# data, labels = load_dir()
function get_spectograms(data)
  temp = [stft(data[i,:],2750, 1375)[end] for i in 1:size(data)[1]]
  return map(x-> reshape(x, size(x)...,1,1), temp)
end


#samples = [stft(data[i,:],2750, 1375)[end] for i in 1:size(data)[1]]
function train_test(x, l)
  all = gpu.(shuffle!(collect(zip(x, l))))
  #test = gpu.(zip(x[end-3:end], l[end-3:end]))
  return all[1:end-2], all[end-1:end]
end

function get_data()
  data, labels = load_dir()
  temp = get_spectograms(data)
  return train_test(temp, labels)
end

function training(train, test)
  @epochs 1 Flux.train!(loss, params(c), train, opt, cb = throttle(evalcb, 5))
end

function run()
  data, labels = load_dir()
  temp = get_spectograms(data)

  train, test = train_test(temp, labels)

  loss(x, y) = mse(c(x), y)
  evalcb = () -> @show loss(test[end][1], test[end][2])
  opt = ADAM()

  @epochs 1 Flux.train!(loss, params(c), train, opt, cb = throttle(evalcb, 5))

end



c = Chain(
    Conv((3,3), 1=>1, pad = 1),
    MaxPool((2,2)),

    Conv((3,3), 1=>1, pad = 1),
    MaxPool((2,2)),

    Conv((3,3), 1=>1, pad = 1),
    MaxPool((2,2)),

    #Conv((5,5), 16=>16, pad = 1),
    #MaxPool((3,3)),

    x->reshape(x, :, size(x, 4)),

    Dense(896,length(instruments))
    #softmax
   )


#loss(x, y) = mse(c(x), y)
#evalcb = () -> @show loss(test[end][1], test[end][2])
#opt = ADAM()

#@epochs 10 Flux.train!(loss, params(c), train, opt, cb = throttle(evalcb, 5))
