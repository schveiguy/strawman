# Strawman Structs

Proof of concept of "strawman structs" idea I discovered and explored [here](https://www.youtube.com/watch?v=ZxzczSDaobw)

Strawman struct is a stand-in for a real struct, and can be used to provide a model for generating template constraints and better error messages.

It uses the D struct syntax to define what aspects must be present on a type. The struct is never actually used at runtime, it's only used to define the interface/structure of a type. Then introspecting the "strawman", the library can deduce how to check to see if a real type implements the given strawman.

Almost no documentation at the moment, and I'm not sure this ever will be a real usable library. It's a proof of concept developed for my Dconf 2022 online talk.
