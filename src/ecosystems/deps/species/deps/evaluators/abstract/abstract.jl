"""
    Abstract

This module provides abstract definitions and basic functionalities that can be 
extended for specific evaluation strategies in the co-evolutionary framework.
"""
module Abstract

export Evaluator, Evaluation, Individual

using ....Ecosystems.Species.Individuals.Abstract: Individual

abstract type Evaluation end

abstract type Evaluator end

end
