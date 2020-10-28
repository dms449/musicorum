import Base.+, Base.-, Base.==
using Optim


# TODO functions to parse strings into Note and vice versa
# TODO add n value for Note as well as exact and approximate functions for the note frequency 

global middle_octave = 4
global use_sharps = true

# An approximation of the musical scale with n being an integer for each note
equal_tempered_scale(n)::Float64 = 440*2^(n/12)

# a regular expression for parsing string notes
note_format = r"(?<letter>(C|D|E|F|G|A|B))(?<accidental>(b|♭|#|♯|♮))?(?<octave>\d)?"


ns = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
nf = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]

struct Note
  n::Int
end
(==)(a::Note,b::Note) = a.n == b.n

Base.show(io::IO, note::Note) = print(io, String(note))
+(note::Note, i::Int) = Note(note.n+i)
-(note::Note, i::Int) = Note(note.n-i)
value(note::Note)::Int64 = note.n
octave(note::Note)::Int64 = div(note.n+58, 12)


"""
Note(l::Char; [oct::Int, acc::Char])

create a note from the letter with optional octave and accidental keywords.

# Arguments
- `oct::Int=4`: Note octave. Must be in range 0-9.
- `acc::Char=♮`: Accidental. must be one of - b, ♭, #, ♯, ♮

"""
function Note(l::Char; oct::Int=middle_octave, acc::Char='♮')
  # test range of octave
  if (oct < 0 || oct > 8) return @warn "ocatve=$oct outside of valid range 0-8." end

  # verify accidental is valid charachter
  if acc ∉ ['b', '♭', '#', '♯', '♮'] return @warn "invalid accidental $acc. Must be one of - b, ♭, #, ♯, ♮" end

  name = replace(replace(replace(l*acc, "♭"=>"b"), "♯"=>"#"), "♮"=>"")

  if (name ∈  ns)
    n = oct*12+indexin([name], ns)[1] - 58
  elseif (name ∈  nf)
    n = oct*12+indexin([name], nf)[1] - 58
  else
    @warn "unable to find note: $name"
    return nothing
  end
  return Note(n)

end

"""
Note(s::String)

create a Note object from a string

# Examples
```
# middle A sharp(4th octave)
Note("A#")

# second octave B
Note("2B")

# 9th octave D flat
Note("9Db")
```
"""
function Note(s::String)
  m = match(note_format, replace(s, "♭"=>"b"))
  if (m == nothing )
    return @warn "invalid note format. format={letter}{accidental=♮}{octave=4}"
  elseif length(s) != sum([m[:letter]!=nothing, m[:octave]!=nothing, m[:accidental]!=nothing])
    return @warn "invalid note format. format={letter}{accidental=♮}{octave=4}"
  end

  # octave
  o::Int = m[:octave]==nothing ? middle_octave : parse(Int, m[:octave])

  # accidental
  a::Char = m[:accidental]==nothing ? '♮' : m[:accidental][1]

  return Note(m[:letter][1], oct=o, acc=a)
end

"""
Note(freq::Float64)

create a Note from a frequency value.

Will always return the Note closest to the frequency.
"""
function Note(freq::Float64)
  compare(n) = abs(equal_tempered_scale(n)-freq)
  result = optimize(compare, -58, 50)
  Note(Int(round(result.minimizer)))
end

function String(note::Note) 
  ind = (note.n+58) % 12
  octave = div(note.n+58, 12)
  return replace(replace("$(use_sharps ? ns[ind] : nf[ind])$octave", "b"=>"♭"), "#"=>"♯")
end

"""
freq(note::Note)

get the frequency value of the note
"""
function freq(note::Note)
  equal_tempered_scale(note.n)
end

"""
accidental(note::Note)

get the accidental Character

"""
function accidental(note::Note) 
  s = String(note)
  return length(s) == 3 ? s[2] : '♮'
end

function is


"""

"""
function exp_to_freq(n::Int64)::Float64

  ind = (n+58) % 12
  str = sharp ? ns[ind] : nf[ind]
  return Note(str, equal_tempered_scale(n), floor((n+58)/12))
end


"""
get the closest musical note to the provided frequency
"""
function freq_to_note(f::Float64, sharp::Bool=true)
  compare(n) = abs(equal_tempered_scale(n)-f)
  result = optimize(compare, -58, 50)
  nearest = Int(round(result.minimizer))
  note::Note = exp_to_note(nearest, sharp)
  return note, result.minimizer
end


