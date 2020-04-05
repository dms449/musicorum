using Flux
using Flux:  mse, throttle, softmax, @epochs
using BSON: @save, @load
using Random

include("data.jl")
include("functions.jl")

# data, labels = load_dir()


#samples = [stft(data[i,:],2750, 1375)[end] for i in 1:size(data)[1]]
#function train_test(x, l)
#  all = gpu.(shuffle!(collect(zip(x, l))))
#  #test = gpu.(zip(x[end-3:end], l[end-3:end]))
#  return all[1:end-2], all[end-1:end]
#end
#
#function get_data()
#  data, labels = load_dir()
#  temp = get_spectograms(data)
#  return train_test(temp, labels)
#end
#
#function training(train, test)
#  @epochs 1 Flux.train!(loss, params(c), train, opt, cb = throttle(evalcb, 5))
#end

"""

"""
function train(; epochs::Int=5)
  # load the truth files
  train_files,train_keys, test_files, test_keys = all_data()
  test_samples = get_data(test_files, test_keys, 1, Int(2*44100), Int(2*44100))

  loss(x, y) = mse(instrument_model(x), y)
  evalcb = () -> @show loss(test_samples[end][1], test_samples[end][2])
  opt = ADAM()
  
  for i in 1:epochs
    @info "epoch $i"
    training_samples = get_data(train_files, train_keys, 5, Int(2*44100), Int(2*44100))
    while !isempty(training_samples)
      Flux.train!(loss, params(instrument_model), training_samples, opt, cb = throttle(evalcb, 1))

      training_samples = get_data(train_files, train_keys, 5, Int(2*44100), Int(2*44100))
    end
    
    train_keys, test_keys = data_keys(train_files, test_files)
  end
end



instrument_model = Chain(
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


#loss(x, y) = mse(c(x), y)
#evalcb = () -> @show loss(test[end][1], test[end][2])
#opt = ADAM()

#@epochs 10 Flux.train!(loss, params(c), train, opt, cb = throttle(evalcb, 5))
