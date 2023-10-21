using DataStructures: SortedDict

 function generate_nested_dict(first_layer_size::Int, second_layer_size::Int)
     # Initialize an empty dictionary
     my_dict = Dict{Int, SortedDict{Int, Float64}}()
 
     # Loop for the first layer
     for i in 1:first_layer_size
         # Initialize the second layer dictionary
         second_layer_dict = SortedDict{Int, Float64}()
 
         # Loop for the second layer
         for j in (11:(10 + second_layer_size))
             # Generate a random Float64 value between 0 and 1
             random_float = rand()
 
             # Add the random value to the second layer dictionary
             second_layer_dict[j] = random_float
         end
 
         # Add the second layer dictionary to the first layer
         my_dict[i] = second_layer_dict
     end
     
     return my_dict
 end