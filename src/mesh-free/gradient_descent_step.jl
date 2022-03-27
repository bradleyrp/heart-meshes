function gradient_descent_step(time, p, index_element, mesh; step=-1, strategy=:random)

    element = mesh.elements[index_element, :]

    # indices_elements = neighborhood(mesh.graph_elements, index_tetrahedron, 10)
    # indices_vertices = mesh.elements[indices_elements, :] |> unique # flatten
    # t_coords = mesh[:points][indices_vertices, :]
    # t_times = find_nearest_times(mesh, indices_vertices, time)

    element_coords = get_element_points(mesh, index_element)
    element_times = find_nearest_times(mesh, element, time)

    cv = calculate_cv(element_coords, element_times)
    cv_normalized = cv / norm(cv)

    Δp = step * cv_normalized
    p_next = p + Δp
    i_next = edge_hopping(index_element, p_next, mesh)[1]

    if isnothing(i_next)

        if strategy == :random
            # randomly pick neighbour
            i_next = rand(neighbors(mesh.graph_elements, index_element))
            element_coords = get_element_points(mesh, i_next)
            p_next = mean(element_coords, dims=1)[1, :]
        
        elseif strategy == :closest

            # find closest neighbour in cv direction
            center =  mean(element_coords, dims=1)[1, :]
            candidates = neighbors(mesh.graph_elements, index_element)
            max_dot_product = -Inf
            for i in candidates
                coords_candidate = get_element_points(mesh, i)
                center_candidate = mean(coords_candidate, dims=1)[1, :]
                dot_product = (center_candidate - center) ⋅ Δp
                if dot_product > max_dot_product
                    i_next = i
                    # p_next = center_candidate

                    λ = rand(size(coords_candidate, 1))
                    λ ./= sum(λ)
                    p_next = sum(coords_candidate .* λ, dims=1)[1, :]

                    max_dot_product = dot_product
                end
            end

        else

            error("no such strategy: $strategy")
        
        end

    end

    time_next = interpolate_baricentric(
        p_next,
        get_element_points(mesh, i_next),
        find_nearest_times(mesh, mesh.elements[i_next, :], time)
    )

    return time_next, p_next, i_next

end


function gradient_descent_step_EMA(time, p, index_tetrahedron, mesh, cv_EMA, α; step=-1, strategy=:random)

    t = mesh.elements[index_tetrahedron, :]

    t_coords = get_tetra_points(mesh, index_tetrahedron)
    t_times = find_nearest_times(mesh, t, time)

    cv = calculate_cv(t_coords, t_times)
    cv /= norm(cv)

    cv = α * cv + (1 - α) * cv_EMA
    cv /= norm(cv)

    p_next = p + step * cv
    i_next = edge_hopping(index_tetrahedron, p_next, mesh)[1]

    if isnothing(i_next)

        if strategy == :random
            # randomly pick neighbour
            i_next = rand(neighbors(mesh.graph_elements, index_tetrahedron))
            t_coords = get_tetra_points(mesh, i_next)
            p_next = mean(t_coords, dims=1)[1, :]
        
        elseif strategy == :closest

            # find closest neighbour in cv direction
            center =  mean(t_coords, dims=1)[1, :]
            candidates = neighbors(mesh.graph_elements, index_tetrahedron)
            max_dot_product = -Inf
            for i in candidates
                coords_candidate = get_tetra_points(mesh, i)
                center_candidate = mean(coords_candidate, dims=1)[1, :]
                dot_product = (center_candidate - center) ⋅ cv
                if dot_product > max_dot_product
                    i_next = i
                    p_next = center_candidate
                    max_dot_product = dot_product
                end
            end

        else

            error("no such strategy: $strategy")
        
        end

    end

    time_next = interpolate_baricentric(
        p_next,
        get_tetra_points(mesh, i_next),
        find_nearest_times(mesh, mesh.elements[i_next, :], time)
    )

    return time_next, p_next, i_next, cv

end
