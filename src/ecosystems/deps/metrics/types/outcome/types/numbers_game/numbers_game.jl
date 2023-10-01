module NumbersGame

export NumbersGameMetric, Control, Sum, Gradient, Focusing, Relativism

using ......Ecosystems.Metrics.Interaction.Abstract: OutcomeMetric

"""
    NumbersGameMetric

Abstract type representing metrics for the numbers game.
"""
abstract type NumbersGameMetric <: OutcomeMetric end

"""
    Control <: NumbersGameMetric

Metric representing equal scoring in the numbers game.
"""
struct Control <: NumbersGameMetric end

"""
    Sum <: NumbersGameMetric

Metric for the numbers game where scoring is based on the sum of vector values.
"""
struct Sum <: NumbersGameMetric end

"""
    Gradient <: NumbersGameMetric

Metric comparing each element of vectors in the numbers game and scoring based on majority of higher elements.
"""
struct Gradient <: NumbersGameMetric end

"""
    Focusing <: NumbersGameMetric

Metric for the numbers game that scores based on the maximum absolute difference between two vectors.
"""
struct Focusing <: NumbersGameMetric end

"""
    Relativism <: NumbersGameMetric

Metric for the numbers game focusing on the minimum absolute difference between two vectors.
"""
struct Relativism <: NumbersGameMetric end

"""
    NumbersGameEnvironment{M <: NumbersGameMetric} <: Problem

A env env for the numbers game with a specific metric.

# Fields:
- `metric::M`: Metric determining the nature of interactions.
"""
end