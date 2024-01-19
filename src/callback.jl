# This file constains the definitions for the callback function used in the
# optimisation

struct Callback
    opts::OptOptions
    start_iter::Int
    keep_zero::Bool

    function Callback(opts=OptOptions())
        if length(opts.trace.value) == 0
            keep_zero = true
            start_iter = 0
        else
            keep_zero = false
            start_iter = opts.trace.iter[end]
        end

        new(opts, start_iter, keep_zero)
    end
end

# TODO: add ability for extra callback to stop by passing true
function (f::Callback)(x)
    # run extra callback method
    f.opts.callback(x)

    # write current state to trace
    _update_trace!(f.opts.trace, x, f.start_iter, f.keep_zero)

    # write data to disk
    f.opts.write && x.iteration % f.opts.n_it_write == 0 ? _write_data(f.opts.write_loc, f.opts.trace, x.metadata["x"]) : nothing

    # print the sate if desired
    f.opts.verbose && x.iteration % f.opts.n_it_print == 0 ? _print_state(f.opts.print_io, x.iteration, x.metadata["Current step size"], x.value, x.g_norm) : nothing

    return false
end

function _print_state(print_io, iter, step_size, value, g_norm)
    str = @sprintf("|%10d   |   %5.2e  |  %5.5e  |  %5.5e  |", iter, step_size, value, g_norm)
    println(print_io, str)
    flush(print_io)
    return nothing
end
