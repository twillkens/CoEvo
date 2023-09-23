export LingPredGame, Control
export LingPredRole, MatchCoop, MismatchCoop, MatchComp, MismatchComp

abstract type LingPredRole end

struct MatchCoop <: LingPredRole end
struct MismatchCoop <: LingPredRole end
struct MatchComp <: LingPredRole end
struct MismatchComp <: LingPredRole end
struct Control <: LingPredRole end


struct LingPredGame{V <: LingPredRole} <: Domain
    variety::V
end