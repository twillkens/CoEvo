"""
    Reporters

The `Reporters` module provides utilities to report runtime statistics, such as evaluation and 
reproduction time, during the evolutionary process. It defines a specific report type, 
[`RuntimeReport`](@ref), and a corresponding reporter, [`RuntimeReporter`](@ref), that generates 
such reports.

# Key Types
- [`RuntimeReport`](@ref): A structured type that captures details about the runtime of specific processes in a given generation.
- [`RuntimeReporter`](@ref): A reporter that, when called, generates a `RuntimeReport`.

# Dependencies
This module depends on the abstract `Report` and `Reporter` types defined in the `...CoEvo.Abstract` module, and on the `Archiver` type.

# Usage
Use this module when you want to keep track of the runtime statistics of your evolutionary algorithm and potentially print or save them at regular intervals.

# Exports
The module exports: `RuntimeReport` and `RuntimeReporter`.
"""
module Reporters

export Abstract, Species, Domain, Ecosystem

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("types/species/species.jl")
using .Species: Species

include("types/domain/domain.jl")
using .Domain: Domain

include("types/ecosystem/ecosystem.jl")
using .Ecosystem: Ecosystem

include("methods/methods.jl")
using .Methods

end



