export DelphiDomain, COADomain, COODomain

abstract type DelphiDomain <: Domain end
struct COADomain <: DelphiDomain end
struct COODomain <: DelphiDomain end