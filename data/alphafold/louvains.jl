#!/usr/bin/env julia
using Random
ROOT = readchomp(`git root`)


"Run a Cmd object, returning stdout, stderr, and exit code"
function execute(cmd::Cmd)
  out = Pipe()
  err = Pipe()

  process = run(pipeline(ignorestatus(cmd), stdout=out, stderr=err))
  close(out.in)
  close(err.in)

  (
    stdout = String(read(out)), 
    stderr = String(read(err)),  
    code = process.exitcode
  )
end




omes = vcat([readdir(d1; join=true) for d1 in readdir("PH"; join=true)]...)
println(length(omes), " proteomes")

omes = omes[.!isfile.(omes .* "/louvain.json.gz")]
println(length(omes), " todo")

shuffle!(omes)

for outdir in omes[1:min(1000,length(omes))]
    isfile(outdir*"/.inprogress") && continue
    touch(outdir*"/.inprogress")
    println(outdir)
    res = execute(`$ROOT/src/louvain.py $outdir/'AF*.json.gz' $outdir/louvain.json.gz`)
    if res.code == 0
        rm(outdir*"/.inprogress")
    else
        println("# STDOUT")
        println(res.stdout)
        println("# STDERR")
        println(res.stderr)
    end
end

