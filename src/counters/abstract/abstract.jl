export Counter

"""
    Counter

An abstract type representing the concept of a counter. Implementations of `Counter` should provide their own specific logic to determine counting behavior.

## Functions

- `count!(counter::Counter)::Int`: 
  Increments the counter or retrieves its current value. Throws an exception if not implemented for a specific `Counter` type.
  
- `count!(counter::Counter, value::Int)::Int`: 
  Increments the counter by a specified value or sets it to a particular value. Throws an exception if not implemented for a specific `Counter` type.
  
## Notes

When defining a new type that is a subtype of `Counter`, ensure to provide specific implementations for the `count!` functions to avoid runtime errors.

"""
abstract type Counter end