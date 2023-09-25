module Defaults

export DefaultPhenotypeConfiguration, DefaultMutator

using .....CoEvo.Abstract: PhenotypeConfiguration, Mutator

struct DefaultPhenotypeConfiguration <: PhenotypeConfiguration end
struct DefaultMutator <: Mutator end

end