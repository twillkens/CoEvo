export genokey, indivkey

function genokey(spkey::String, iid::Int)
    string(spkey, KEY_SPLIT_TOKEN, iid)
end

function indivkey(indiv::Individual)
    string(indiv.spkey, KEY_SPLIT_TOKEN, indiv.iid)
end
