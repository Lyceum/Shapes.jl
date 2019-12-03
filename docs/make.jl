using Documenter, Shapes

makedocs(;
    modules=[Shapes],
    format=Documenter.HTML(
        prettyurls=get(ENV, "GITHUB_ACTIONS", nothing) == "true",
    ),
    pages=[
        "Home" => "index.md",
        "API" => "api.md",
    ],
    sitename="Shapes.jl",
    authors = "Colin Summers",
    clean = true,
    doctest=true,
    checkdocs=:all,
    linkcheck=:true,
)

deploydocs(
    repo = "github.com/Lyceum/Shapes.jl.git",
)