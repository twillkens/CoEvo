function ScalarOutcome(n::Int, ::NGControl; subject::Phenotype, test::Phenotype)
    r1 = ScalarResult(subject.key, test.key, :subject, true)
    r2 = ScalarResult(test.key, subject.key, :test, nothing)
    ScalarOutcome(n, Set([r1, r2]))
end

function ScalarOutcome(n::Int, ::NGGradient; subject::IntPheno, test::IntPheno)
    result = subject.traits > test.traits
    r1 = ScalarResult(subject.key, test.key, :subject, result)
    ScalarOutcome(n, Set([r1]))
end

function ScalarOutcome(n::Int, ::NGFocusing; subject::VectorPheno, test::VectorPheno)
    v1, v2 = subject.traits, test.traits
    maxdiff, idx = findmax([abs(x1 - x2) for (x1, x2) in zip(v1, v2)])
    result = v1[idx] > v2[idx]
    r1 = ScalarResult(subject.key, test.key, :subject, result)
    r2 = ScalarResult(test.key, subject.key, :test, nothing)
    ScalarOutcome(n, Set([r1, r2]))
end

function ScalarOutcome(n::Int, ::NGRelativism; subject::VectorPheno, test::VectorPheno)
    v1, v2 = subject.traits, test.traits
    maxdiff, idx = findmin([abs(x1 - x2) for (x1, x2) in zip(v1, v2)])
    result = v1[idx] > v2[idx]
    r1 = ScalarResult(subject.key, test.key, :subject, result)
    r2 = ScalarResult(test.key, subject.key, :test, nothing)
    ScalarOutcome(n, Set([r1, r2]))
end

