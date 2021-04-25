using Flux
using Flux: outdims

include("instruments.jl")

im1 = Chain(
    Conv((3, 3), 1=>8, pad=(1,1), relu),
    MaxPool((3,3)),

    Conv((3, 3), 8=>16, pad=(1,1), relu),
    MaxPool((3,3)),

    Conv((3, 3), 16=>32, pad=(1,1), relu),
    MaxPool((3,3)),

    Conv((3, 3), 32=>32, pad=(1,1), relu),
    MaxPool((3,3)),
   ) 


"""

"""
function build_model(input_size=(698, 85,1,1), chain=im1)
  os = outdims(chain, input_size)
  
  return Chain(
    chain,
    flatten,
    Dense(prod(os)*32, length(instruments), σ)
  )
end
