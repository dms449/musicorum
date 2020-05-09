"""
get the output dimensions of a short-time-forier transform on an input vector 
of length `dlen` with window length `wlen` and stride of `stride`
"""
get_stft_size(d_len, wlen, stride) = div(wlen,2), div(d_len-wlen, stride)+1

"""
partition the collection *data* with window of size *wlen* and shifted by *stride*
"""
function partition(x, wlen::Int, stride::Int=1)
  return ((@view x[i:i+wlen-1]) for i in 1:stride:length(x)-wlen+1)
end


