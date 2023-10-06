module Interfaces

export load_genotype

using JLD2: Group
using ..Loaders.Abstract: Loader

function load_genotype(loader::Loader, group::Group)
    throw(ErrorException("load_genotype not implemented for $loader"))
end

end

