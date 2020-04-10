using Test


@testset "MusicalFxExtraction" begin

  @testset "Data" begin
    include("../src/data.jl")
    include("data_test.jl")
  end

end
