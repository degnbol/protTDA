#!/usr/bin/env julia
using Ripserer
using DelimitedFiles, DataFrames, CSV
using JSON
using ArgParse
using .Threads: @threads

parser = ArgParseSettings(description="Calculate PH barcodes and representatives using Ripserer.jl.")
@add_arg_table parser begin
    "infiles"
    arg_type = String
    nargs = '+'
    help = "Delimited files with x, y and z columns. Can be given as a folder as well where either .tsvs or .npys are located."
    "--header", "-H"
    action = :store_true
    help = "Infiles has header including column names x,y,z. Default is delimited file without header."
    "--out", "-o"
    default = "."
    arg_type = String
    help = "Output folder. Default=PWD. Files are named the same as infiles except gets extension .json."
    "--alpha", "-a", "-α"
    action = :store_true
    help = "Vietoris-Rips is the default, set flag to use Alpha."
    "--dim", "-d"
    arg_type = Int
    default = 1
    help = "Maximum dimension to calculate."
end

if abspath(PROGRAM_FILE) == @__FILE__
    # if run as script
    _args = ARGS
else
    # if interactive, do an example
    _args = split("AF-A0A009DWL0-F1-model_v3.mat -α -d 2", ' ')
end
args = parse_args(_args, parser, as_symbols=true) |> NamedTuple
# collect filenames given indirs
infiles = args.infiles[.!isdir.(args.infiles)]
for indir in args.infiles[isdir.(args.infiles)]
    fnames = readdir(indir; join=true)
    exts = [splitext(fname)[2] for fname in fnames]
    tsvs = exts .== ".tsv"
    npys = exts .== ".npy"
    @assert any(tsvs) != any(npys) "$indir should either contain .tsvs or .npys."
    append!(infiles, fnames[tsvs .| npys])
end

mat2pc(mat::Matrix{Float64}) = mat |> eachrow .|> Tuple

filt = args.alpha ? Alpha : Rips
xyz2PH(mat::Matrix{Float64}) = ripserer(filt(mat2pc(mat)); dim_max=args.dim, alg=:involuted)

barcodes(PH, dim::Int) = hcat(collect.(collect(PH[dim+1]))...)'
representatives(PH, dim::Int) = [[collect(r.simplex) for r in collect(c)] for c in representative.(PH[dim+1])]

# precompile
xyz2PH(rand(400, 3))

mkpath(args.out)

@threads for fname in infiles
    name = splitext(basename(fname))[1]
    outfile = "$(args.out)/$name.json"
    isfile(outfile) && continue
    println(name)
    X = args.header ? Matrix{Float64}(CSV.read(fname, DataFrame)[!, split("xyz","")]) : readdlm(fname)
    PH = xyz2PH(X)
    
    dic = Dict{String,Dict}()
    for dim in 1:args.dim
        dic["H$dim"] = Dict(:barcode => barcodes(PH,dim), :representatives => representatives(PH,dim))
    end
    
    open(outfile, "w") do io JSON.print(io, dic, 2) end
end
