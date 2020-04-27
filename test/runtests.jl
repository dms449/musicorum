using Test
#using MusicalFxExtraction


@testset "MusicalFxExtraction" begin

  @testset "Data" begin
    #include("data_test.jl")
  end

  @testset "MusicTheory" begin
    include("./../src/music_theory.jl")
    include("music_theory_test.jl")
  end

end
