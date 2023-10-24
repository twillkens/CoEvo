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

export Abstract, Basic, Runtime#Species, Interaction, Ecosystem

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("types/types.jl")
using .Types: Types

end



