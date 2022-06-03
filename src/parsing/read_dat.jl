function read_dat(
    filename;
    FloatType=Float32,
    IntType=Int32,
    dlm = "\t",
    buff_size=120_000_000, # deprecated because sometimes too small
)

    # rbradley replaced a static buffer with a growing Vector but is not a Julia expert
    # vs_buff = zeros(IntType, buff_size)
    # times_buff = zeros(FloatType, buff_size)
    vs_buff = zeros(IntType, 0)
    times_buff = zeros(FloatType, 0)

    n_lines_read = 0

    for line in eachline(filename)
        n_lines_read += 1
        v, t = split(line, dlm)
        # vs_buff[n_lines_read] = parse(IntType, v)
        # times_buff[n_lines_read] = parse(FloatType, t)
        append!(vs_buff,parse(IntType,v))
        append!(times_buff,parse(FloatType,t))
    end

    vs = deepcopy(one(IntType) .+ vs_buff[1: n_lines_read])
    times = deepcopy(times_buff[1: n_lines_read])

    vs, times

end
