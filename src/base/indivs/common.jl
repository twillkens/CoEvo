export genokey

function genokey(spkey::String, iid::Int)
    string(spkey, KEY_SPLIT_TOKEN, iid)
end