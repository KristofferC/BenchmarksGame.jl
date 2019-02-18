cd(@__DIR__)
include("make_flags.jl")
for cmd in make_cmds
  try
    run(`g++ $cmd`)
    @info "success"
  catch e
    @warn "failed command" exception = e
  end
end

fasta_input = "fasta.txt"
fasta_gen = joinpath(@__DIR__, "..", "fasta", "fasta.jl")
run(pipeline(`$(Base.julia_cmd()) $fasta_gen 25000000` ;stdout = fasta_input))


benchmarks = [
    ("binarytrees", 21),
    ("fannkuchredux", 12),
    ("fasta", 25000000),
    ("knucleotide", fasta_input),
    ("mandelbrot", 16000),
    ("nbody", 50000000),
    ("pidigits", 10000),
    ("regexredux", fasta_input),
    ("revcomp", fasta_input),
    ("spectralnorm", 5500),
]

dir = joinpath(@__DIR__, "..")

map(benchmarks) do (bench, arg)
  cmd = if arg == -1
  	`./$bench`
  else
    `./$bench $arg`
  end
end
cd(@__DIR__)
timings = map(benchmarks) do (bench, arg)
  println(bench)
  root = joinpath(dir, bench)
  jl = joinpath(root, string(bench, "-fast.jl"))
  if !isfile(jl)
    jl = replace(jl, "-fast" => "")
  end
  @assert isfile(jl)
  isfile("result.bin") && rm("result.bin")
  args = [:stdout => "result.bin"]
  argcmd = ``
  cmd = if arg isa String
    @assert isfile(arg)
    push!(args, :stdin => arg)
  else
    argcmd = `$arg`
  end
  # jltime = withenv("JULIA_NUM_THREADS" => 16) do
  #    @elapsed run(pipeline(`julia -O3 $jl $argcmd`; args...))
  # end
  jltime = 0.0
  ctime = @elapsed run(pipeline(`./$bench $argcmd`; args...))
  (jltime, ctime)
end


run(pipeline(`./revcomp $argcmd`, stdin = fasta_gen))