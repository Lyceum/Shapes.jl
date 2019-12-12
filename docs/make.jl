using Documenter, Shapes

makedocs(;
    modules=[Shapes],
    format=Documenter.HTML(
        prettyurls = get(ENV, "GITHUB_ACTIONS", nothing) == "true",
        canonical = "https://lyceum.github.io/Shapes.jl/stable/"
    ),
    pages=[
        "Home" => "index.md",
        "API" => "api.md",
    ],
    sitename="Shapes.jl",
    authors = "Colin Summers",
    clean = true,
    doctest = true,
    checkdocs = :exports,
    linkcheck = :true,
)

deploydocs(
    repo = "github.com/Lyceum/Shapes.jl.git",
)