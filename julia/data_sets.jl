using WAV
  
guitar_file = "/home/dms449/workspace/JuliaProjects/MusicalFxExtraction/test/HazySunshine.wav"
piano_file = "/home/dms449/workspace/JuliaProjects/MusicalFxExtraction/test/pianocello.wav"

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
