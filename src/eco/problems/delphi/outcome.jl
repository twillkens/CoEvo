export DelphiOutcome

function TestPairOutcome(n::Int, ::COADomain, subject::DelphiPheno, test::DelphiPheno)
    vec1, vec2 = subject.traits, test.traits
    subject_score = all([v1 >= v2 for (v1, v2) in zip(vec1, vec2)]) ? 1.0 : -1.0
    scores = Dict([subject.key => subject_score, test.key => -subject_score])
    TestPairOutcome(n, subject.key, test.key, scores)
end

function TestPairOutcome(n::Int, ::COODomain, subject::DelphiPheno, test::DelphiPheno)
    vec1, vec2 = subject.traits, test.traits
    m = argmax(vec2)
    subject_score = vec1[m] >= vec2[m] ? 1.0 : -1.0
    scores = Dict([subject.key => subject_score, test.key => -subject_score])
    TestPairOutcome(n, subject.key, test.key, scores)
end