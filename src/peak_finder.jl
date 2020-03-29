using Statistics


"""
find peaks in the 1D data array which are greater than the multiplier times the
standard deviation.
"""
function threshold_stddev(data::Array{Float64,1}, multiplier=3)
  sigma = std(data)
  

end

function find_peaks_1d(data::Array{Float64,1}, method="dumb")::Array{Any,2}
  peaks = Array{Any,2}(undef, 2, 0)
  if (method=="dumb")
    for i in 2:length(data)-1
      if (data[i] > data[i-1] && data[i]>data[i+1])
        peaks = [peaks [i;data[i]]]
      end
    end
    return peaks

  end

end
