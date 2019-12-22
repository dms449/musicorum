import Base.Enum
using Optim

equal_tempered_scale(n::Float64)::Float64 = 440*2^(n/12)

struct Note
  name::String
  freq::Float64
  octave::Int
end


notes_shp = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
notes_flt = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]



"""

"""
function get_note(n::Int64, sharp=true::Bool)::Note
  ind = (n+58) % 12
  str = sharp ? notes_shp[ind] : notes_flt[ind]
  return Note(str, equal_tempered_scale(Float64(n)), floor((n+58)/12))
end

"""
get the closest musical note to the provided frequency
"""
function get_note(f::Float64, sharp=true::Bool)
  compare(n) = abs(equal_tempered_scale(n)-f)
  result = optimize(compare, -58, 50)
  nearest = Int(round(result.minimizer))
  note::Note = get_note(nearest, sharp)
  return note, result.minimizer
end


