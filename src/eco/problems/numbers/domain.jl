export NumbersGame, NGGradient, NGFocusing, NGRelativism, NGControl, NGSum

abstract type NumbersGame <: Domain end
    
struct NGGradient <: NumbersGame end

struct NGFocusing <: NumbersGame end

struct NGRelativism <: NumbersGame end

struct NGControl <: NumbersGame end

struct NGSum <: NumbersGame end