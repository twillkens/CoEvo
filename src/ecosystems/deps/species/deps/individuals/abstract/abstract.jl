"""
    Abstract

This module contains abstract definitions related to genotype configurations in the co-evolutionary ecosystem.
It provides foundational behaviors for genotype configurations, which can be extended in derived modules.
"""
module Abstract

export Individual, IndividualCreator, AbstractRNG

using Random: AbstractRNG

abstract type Individual end

abstract type IndividualCreator end

end
