
string_instruments = ["acoustic_guitar", "electric_guitar", "bass", "mandolin", "banjo", "violin", "cello"]
string_playing_styles = ["strumming", "picking"]
brass_instruments = ["trumpet"]
woodwind_instruments = ["flute", "low_whistle", "penny_whistle"]
percussion_instruments = ["drums"]
keyboard = ["piano"]
other_instruments = ["vocals"]

basic_families = ["percussion_instruments"=>percussion_instruments, "woodwind_instruments"=>woodwind_instruments, "brass_instruments"=>brass_instruments, "string_instruments"=>string_instruments, "keyboard"=>keyboard, "other_instruments"=>other_instruments]
#hornbostel_sachs = ["Idiophone"]

instruments = vcat(string_instruments, brass_instruments, woodwind_instruments, percussion_instruments, keyboard, other_instruments)


