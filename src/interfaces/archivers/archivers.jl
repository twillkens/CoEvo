export archive!

using ..Abstract

function archive!(archiver::Archiver, state::State)
    archiver = typeof(archiver)
    state = typeof(state)
    error("archive! not implemented for $archiver, $state")
end
