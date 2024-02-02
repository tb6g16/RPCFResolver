struct DummyTrace
    value::Float64
    g_norm::Float64
    iteration::Int
    metadata::Dict
end

@testset "Callback Function             " begin
    # initialise dummy cache
    optimCache = ResGrad(Grid([0.0], 1, 1, Matrix{Float64}(undef, 0, 0), Matrix{Float64}(undef, 0, 0), [0.0], 1.0, 1.0), Array{ComplexF64}(undef, 0, 0, 0, 0), [0.0], 1.0, 1.0, true)

    # test construction
    @test Callback(optimCache).opts.trace.value == Vector{Float64}(undef, 0)
    @test Callback(optimCache).opts.trace.g_norm == Vector{Float64}(undef, 0)
    @test Callback(optimCache).opts.trace.iter == Vector{Int}(undef, 0)
    @test Callback(optimCache).opts.trace.time == Vector{Float64}(undef, 0)
    @test_nowarn Callback(optimCache, OptOptions(trace=Fields.Trace(rand(5), rand(5), rand(Int, 5), rand(5), rand(5))))
    @test_throws ArgumentError Callback(optimCache, OptOptions(trace=Fields.Trace(rand(5), rand(3), rand(Int, 5), rand(5), rand(5))))

    # test trace assignment
    cb = Callback(optimCache)
    value = rand(); g_norm = rand(); iter = rand(1:10); metadata = Dict("time"=>rand(), "Current step size"=>rand(), "x"=>nothing);
    cb(DummyTrace(value, g_norm, iter, metadata))
    @test cb.opts.trace.value == [value]
    @test cb.opts.trace.g_norm == [g_norm]
    @test cb.opts.trace.iter == [iter]
    @test cb.opts.trace.time == [metadata["time"]]
    @test cb.opts.trace.step_size == [metadata["Current step size"]]
    cb(DummyTrace(2*value, 4*g_norm, 5*iter, metadata))
    @test cb.opts.trace.value == [value, 2*value]
    @test cb.opts.trace.g_norm == [g_norm, 4*g_norm]
    @test cb.opts.trace.iter == [iter, 5*iter]
    @test cb.opts.trace.time == [metadata["time"], metadata["time"]]
    @test cb.opts.trace.step_size == [metadata["Current step size"], metadata["Current step size"]]

    # test internal callback method
    @test cb(DummyTrace(value, g_norm, iter, metadata)) == false
    cb2 = Callback(optimCache, OptOptions(callback=x->x.iteration==iter))
    @test cb2(DummyTrace(value, g_norm, 2*iter, metadata)) == false
    @test cb2(DummyTrace(value, g_norm, iter, metadata)) == true
end
