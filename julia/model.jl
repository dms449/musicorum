using Flux
using Flux: @epock, mse, throttle

include("data_sets.jl")
train, test = getDatat()

instruments = ["piano", "guitar", "vocals", "other"]




loss(x, y) = mse(m(x), y)
evalcb = throttle(() -> @show(loss(test[1], test[1])), 5)

opt = ADAM()
epochs 10 Flux.train!(loss, params(m), zip(data), opt, cb = evalcb)
