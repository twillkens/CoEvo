module Interfaces

export archive!

using ..Archivers.Abstract: Archiver
using ...Ecosystems.Reporters.Abstract: Report

function archive!(
    archiver::Archiver,
    generation::Int,
    report::Report
)
    throw(ErrorException("archive! not implemented for 
        $(typeof(archiver)) and 
        $(typeof(report))
    "))
end

end