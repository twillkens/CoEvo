function generate_variations(bitstring::Vector{<:Real})
    # Original
    O = bitstring
    
    # Reversed
    R = reverse(bitstring)
    
    # Inverted Original
    IO = [1 - bit for bit in O]
    
    # Inverted Reversed
    IR = [1 - bit for bit in R]
    
    # Function to swap halves (applied to both original and reversed, and their inversions)
    function swap_halves(bs)
        midpoint = div(length(bs), 2)
        if length(bs) % 2 == 0
            return vcat(bs[midpoint+1:end], bs[1:midpoint])
        else
            # For odd-length bitstrings, keep the middle element in place
            return vcat(bs[midpoint+2:end], bs[midpoint+1], bs[1:midpoint])
        end
    end
    
    # Swap Halves for Original and Reversed
    SH_O = swap_halves(O)
    SH_R = swap_halves(R)
    
    # Swap Halves for Inverted Original and Inverted Reversed
    SH_IO = swap_halves(IO)
    SH_IR = swap_halves(IR)
    
    return [O, R, IO, IR, SH_O, SH_IO, SH_R, SH_IR]
end
