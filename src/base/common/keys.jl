export Key, IndivKey, ActorKey, TestKey, RecipeKey

abstract type Key end

struct IndivKey
    spid::Symbol
    iid::UInt32
end

struct IngredientKey
    oid::Symbol
    ikey::IndivKey
end

@properties IngredientKey begin
    oid(self) => :oid
    Any(self) => :ikey
end

struct ActorKey
    roleid::Symbol
    ikey::IndivKey
end

@properties ActorKey begin
    roleid(self) => :roleid
    Any(self) => :ikey
end

struct TestKey
    domain::Symbol
    tests::Set{ActorKey}
end

struct RecipeKey
    domain::Symbol
    ingreds::Set{ActorKey}
end

