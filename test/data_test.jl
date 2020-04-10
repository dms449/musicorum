
@testset "song_slice" begin
  song = 1:4*44100 # 4 seconds at the common sampling frequency of 44.1 khz

  @testset "string times" begin
    slice1 = song_slice(song, "00:01", "00:02")
    @test slice == 44101:88200
    slice2 = song_slice(song, "00:00", "00:02")
    @test slice == 1:88200

    # test different sampling frequency
    slice1 = song_slice(song, "00:01", "00:02", fs=22050)
    @test slice == 22051:44100
  end

end


@testset "load_file!" begin 
  data = []
  labels = []
  songname = raw"../data/test/01 Where Are You Christmas.mp3"

  #load_file!(songname, ,data, labels, partition_s)
  #@test length(data) = 1
  #@test length(labels) = 1
  #@test size(data[1]) = (1,1)
  #@test size(labels[1]) = ()

end
