@testset "Note" begin

  @testset "Note from String" begin
    a = Note("A")
    @test value(a) == 0
    @test isapprox(freq(a), 440.0, atol=0.01*freq(a))
    @test octave(a) == 4

    as = Note("A#")
    @test value(as) == 1
    @test isapprox(freq(as), 466.16, atol=0.01*freq(as))
    @test octave(a) == 4

    as = Note("A♯")
    @test value(as) == 1
    @test isapprox(freq(as), 466.16, atol=0.01*freq(as))
    @test octave(a) == 4

    as1 = Note("A#1")
    @test value(as1) == -35
    @test isapprox(freq(as1), 58.27, atol=0.01*freq(as1))
    @test octave(as1) == 1

    gb8 = Note("Gb8")
    @test value(gb8) == 45
    @test isapprox(freq(gb8), 5919.91, atol=0.01*freq(gb8))
    @test octave(gb8) == 8

    db0 = Note("D♭0")
    @test value(db0) == -56
    @test isapprox(freq(db0), 17.32, atol=0.01*freq(db0))
    @test octave(db0) == 0

    c = Note("C♮")
    @test value(c) == -9
    @test isapprox(freq(c), 261.63, atol=0.01*freq(c))
    @test octave(c) == 4


    # Failure cases
    @test Note("H#") == nothing
    @test Note("#") == nothing
    @test Note("♭") == nothing
    @test Note("GG") == nothing
    @test Note("G11") == nothing
    @test Note("C♭") == nothing
    @test Note("B#") == nothing
    @test Note("D#9") == nothing
    @test Note("F-1") == nothing

  end

  @testset "Note from frequency" begin
    
  end

  @testset "increment/decrement" begin
    
  end

end
