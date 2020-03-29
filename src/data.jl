using WAV
using MP3
using Libdl
include("functions.jl")

strings = ["guitar", "mandolin", "banjo", "violine"]
brass = ["trumpet"]
woodwind = ["flute" ]
percussion = ["drums"]
keyboard = ["piano"]

basic_families = ["percussion"=>percussion, "wood wind"=>woodwind, "brass"=>brass, "strings"=>strings, "keyboard"=>keyboard]
hornbostel-sachs = ["Idiophone"]

  
guitar_file = "/home/dms449/workspace/JuliaProjects/MusicalFxExtraction/wav_samples/HazySunshine.wav"
piano_file = "/home/dms449/workspace/JuliaProjects/MusicalFxExtraction/wav_samples/pianocello.wav"

instruments = ["guitar", "vocals", "piano", "cello"]


"""
get a 
"""
function get_sample(filename, seconds=0)
  data, fs , nbits, opt = wavread(filename);
  if (seconds!=0)
    data = get_seconds(data, fs, seconds)
  end
  return data, fs
end

"""
returns a slice of the data based upon the desired number of seconds and offset
"""
function get_seconds(data, sec, fs=44100, offset=0)
  return data[(1+offset):Int64(offset + sec*fs)]
end

function load_file(filename::String)
  data = Array{Float64}(undef, 0, Int(2*44100))
  labels = [] 

  if (endswith(filename, ".mp3"))
    

  elseif (endswith(filename, ".wav"))
    samples, fs, nbits, opt = wavread("/home/dms449/Music/Training"*"/"*dir*"/"*each)
    temp = windowize(samples[:,1], Int(2*fs), Int(2*fs))
    data = [data; temp]
    labels = [labels ; fill(label, (size(temp)[1], 1))]

  else
    @info "file with invalid extension: $filename"
  end

end

function load_dir()
  data = Array{Float64}(undef, 0, Int(2*44100))
  labels = [] 

  for dir in readdir("/home/dms449/Music/Training")
    label_names = split(dir, "_")
    f(t) = (t in label_names) ? 1.0 : 0.0
    label = [f(l) for l in instruments]

    for each in readdir("/home/dms449/Music/Training"*"/"*dir)
      println("loading "*each)
      samples, fs, nbits, opt = wavread("/home/dms449/Music/Training"*"/"*dir*"/"*each)
      temp = windowize(samples[:,1], Int(2*fs), Int(2*fs))
      data = [data; temp]
      labels = [labels ; fill(label, (size(temp)[1], 1))]
    end
  end

  return data, labels 
end


function load_mp3(filename::String ="""/home/dms449/Music/Sungha Jung/Perfect Blue/01 Hazy Sunshine.mp3""")

  struct mpg123_handle{} end

  err::Int32 = 0;

  #try
    handle = dlopen("libmpg123.so.0")
    mpg_open = dlsym(handle, "mpg123_open")
    mpg_read = dlsym(handle, "mpg123_read")
    mpg_init = dlsym(handle, "mpg123_init")
    mpg_new = dlsym(handle, "mpg123_new")
    mpg_err = dlsym(handle, "mpg123_plain_strerror")

    #try

    data_out_size_max::Csize_t = 0xffffffff
    data_out_size_actual::Csize_t = 0
    data_out = Array{UInt8,1}(undef,data_out_size_max)

    @info "initializing"
    err = ccall(mpg_init, Int32, ())

    @info "getting handle"
    mpg_handle = ccall(mpg_new, Ptr{mpg123_handle}, (Ref{UInt8}, Ref{Int32}), C_NULL, err);

    @info "opening file $filename"
    err = ccall(mpg_open, Int32, (Ptr{mpg123_handle}, Cstring), mpg_handle, filename)

    @info "reading file"
    err = ccall(mpg_read, Int32, (Ptr{mpg123_handle}, Ref{UInt8}, Csize_t, Ref{Csize_t}), mpg_handle, data_out, data_out_size_max, data_out_size_actual)

    # TODO look into mpg123 format for bug fix?
    if (err != 0)
      err_str = ccall(mpg_err, Cstring, (Int32,), err)
      @error "$(unsafe_string(err_str))"
      return 
    end

    @info "data_out_size_actual: $data_out_size_actual"
    return data_out[1:data_out_size_actual]

end
