using StatsBase

nmutate = 5
function mutate(x::Int)
    for _ in 1:nmutate
        r = rand()
        if r < 1/4
            x += 1
        elseif r < 1/2 && x > 1
            x -= 1
        end
    end
    x
end

function sim()
    pop = [1 for _ in 1:50]
    for _ in 1:10_000
        nextgen = Int[]
        for _ in 1:50
            idx = sample(1:50, Weights([1/50 for _ in 1:50]))
            parent = pop[idx]
            child = mutate(parent)
            push!(nextgen, child)
        end
        pop = nextgen
    end
    pop
end

function runtrials(n)
    trials = []
    for _ in 1:n
        push!(trials, sim())
    end
    trials
end

trials = runtrials(100)
print(mean([median(trial) for trial in trials]))