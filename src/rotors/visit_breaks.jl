using DataStructures
using SparseArrays


function visit_breaks(
    index_times_start::U;  # index for the `times` and `is_available`
    times::Vector{F},
    is_available::Vector{Bool},
    is_visited::Vector{Bool},
    starts::Vector{U},
    stops::Vector{U},
    adj_matrix::SparseMatrixCSC,
    dt_max::Union{F,Nothing} = nothing,
)::Nothing where {F<:AbstractFloat} where {U<:Integer}

    if isnothing(dt_max)
        dt_max = convert(F, 10.0)
    end

    @assert is_available[index_times_start]
    is_visited[index_times_start] = true

    q = Queue{Tuple{U,F}}()  # (vertex, time)

    v = searchsortedlast(starts, index_times_start)
    enqueue!(q, (v, times[index_times_start]))

    rows = rowvals(adj_matrix)

    while !isempty(q)

        v, t_v = dequeue!(q)
        # @show v, t_v

        neighbours = @view rows[nzrange(adj_matrix, v)]
        for u in neighbours

            start_u, stop_u = starts[u], stops[u]
            for index_t_u = start_u:stop_u

                (!is_available[index_t_u] || is_visited[index_t_u]) && continue

                t_u = times[index_t_u]
                dt = t_u - t_v
                if 0 <= dt < dt_max
                    is_visited[index_t_u] = true
                    enqueue!(q, (u, t_u))
                end

            end

        end

    end

end