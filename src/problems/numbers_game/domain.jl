export NumbersGame, NGGradient, NGFocusing, NGRelativism, NGControl, NGSum

abstract type NumbersGameProblem <: Prolem end
    
struct NGControl <: NumbersGameProblem end

struct NGSum <: NumbersGameProblem end

struct NGGradient <: NumbersGameProblem end

struct NGFocusing <: NumbersGameProblem end

struct NGRelativism <: NumbersGameProblem end

