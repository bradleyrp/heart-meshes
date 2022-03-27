using StatsBase

include("outer_facet.jl")


function edge_hopping(i_tetra_start, point, points, elements, A_elements; save_trace=false)

    trace = save_trace ? [i_tetra_start] : nothing

    rows = rowvals(A_elements)

    while true

        point_indices = elements[i_tetra_start, :]
        coords_tetra = points[point_indices, :]
        facet_indices = select_outer_facet(point, coords_tetra)

        # center = mean(coords_tetra, dims=1)[1, :]
        # @show dist_left = norm(center .- point)

        if isnothing(facet_indices)
            return (i = i_tetra_start, trace = trace)
        end

        point_indices_facet = point_indices[facet_indices]
        # @show point_indices_facet

        j_tetras = rows[nzrange(A_elements, i_tetra_start)]
        i_tetra_proposed = nothing
        for j in j_tetras
            is_shared_facet = all(point_indices_facet .∈ (elements[j, :],))
            if is_shared_facet
                i_tetra_proposed = j
                break
            end
        end

        if isnothing(i_tetra_proposed)
            # @warn "nothing found"
            break
        end
        
        i_tetra_start = i_tetra_proposed

        if save_trace
            push!(trace, i_tetra_proposed)
        end

    end
    
    return (i = nothing, trace = trace)

end


function edge_hopping(i_element_start, point, mesh::ActivatedMesh; save_trace=false)

    points = mesh[:points]
    elements = mesh.elements
    A_elements = mesh.graph_elements.weights

    edge_hopping(
        i_element_start,
        point,
        points,
        elements,
        A_elements;
        save_trace
    )

end
