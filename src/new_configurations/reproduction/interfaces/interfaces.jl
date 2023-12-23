export get_n_individuals, make_evaluator, make_replacer, make_selector, make_half_truncator

using ...Replacers: TruncationReplacer

function get_n_individuals(reproduction::ReproductionConfiguration)
    throw(ErrorException("get_n_individuals not implemented for reproduction of type $(typeof(reproduction))"))
end

function make_evaluator(reproduction::ReproductionConfiguration)
    throw(ErrorException("make_evaluator not implemented for reproduction of type $(typeof(reproduction))"))
end

function make_replacer(reproduction::ReproductionConfiguration)
    throw(ErrorException("make_replacer not implemented for reproduction of type $(typeof(reproduction))"))
end

function make_selector(reproduction::ReproductionConfiguration)
    throw(ErrorException("make_selector not implemented for reproduction of type $(typeof(reproduction))"))
end

function make_half_truncator(reproduction::ReproductionConfiguration)
    n_individuals = get_n_individuals(reproduction)
    n_truncate = n_individuals ÷ 2
    truncator = TruncationReplacer(n_truncate = n_truncate)
    return truncator
end

