# This file constains the definitions for the callback function used in the
# optimisation

struct Callback{Ny, Nz, Nt, M, FREEMEAN, S, D, T, PLAN, IPLAN}
    cache::ResGrad{Ny, Nz, Nt, M, FREEMEAN, S, D, T, PLAN, IPLAN}
    opts::OptOptions
    start_iter::Int
    keep_zero::Bool

    function Callback(optimisationCache::ResGrad{Ny, Nz, Nt, M, FREEMEAN, S, D, T, PLAN, IPLAN}, opts::OptOptions=OptOptions()) where {Ny, Nz, Nt, M, FREEMEAN, S, D, T, PLAN, IPLAN}
        if length(opts.trace.value) == 0
            keep_zero = true
            start_iter = 0
        else
            keep_zero = false
            start_iter = opts.trace.iter[end]
        end

        new{Ny, Nz, Nt, M, FREEMEAN, S, D, T, PLAN, IPLAN}(optimisationCache, opts, start_iter, keep_zero)
    end
end

function (f::Callback)(x)
    # run extra callback method
    callbackReturn = f.opts.callback(x)

    # write current state to trace
    _update_trace!(f.opts.trace, x, f.start_iter, f.keep_zero)

    # write data to disk
    f.opts.write && x.iteration % f.opts.n_it_write == 0 ? _write_data(f.opts.write_loc, f.opts.trace, x.metadata["x"]) : nothing

    # print the sate if desired
    f.opts.verbose && x.iteration % f.opts.n_it_print == 0 ? _print_state(f.opts.print_io, x.iteration, x.metadata["Current step size"], get_ω(f.cache.spec_cache[1]), x.value, x.g_norm) : nothing

    # update frequency
    Int(x.iteration % f.opts.update_frequency_every) == 0 && x.iteration != 0 ? f.cache.spec_cache[1].grid.dom[2] = optimalFrequency(f.cache) : nothing

    return callbackReturn
end

function _print_state(print_io, iter, step_size, freq, value, g_norm)
    str = @sprintf("|%10d   |   %5.2e  |  %5.5e  |  %5.5e  |  %5.5e  |", iter, step_size, freq, value, g_norm)
    println(print_io, str)
    flush(print_io)
    return nothing
end
