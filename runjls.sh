
#!/usr/bin/bash

for V in {1..20}
do
    julia --project=. runbasic.jl $V &
done