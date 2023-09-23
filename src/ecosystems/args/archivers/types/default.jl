
# Function to store a `VectorGeno` into an archive (using JLD2).
function(a::Archivist)(geno_group::JLD2.Group, geno::VectorGeno,)
    geno_group["vals"] = geno.vals
end

# Function to load a `VectorGenotype` from an archive (using JLD2).
function(cfg::VectorGenotypeConfiguration)(geno_group::JLD2.Group)
    VectorGenotype(geno_group["vals"])
end