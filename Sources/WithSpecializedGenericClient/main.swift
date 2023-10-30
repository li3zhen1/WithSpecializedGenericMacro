import WithSpecializedGeneric


let name = #ReplaceWhenSpecializing("Hello!", lookupOn: [
    "Hola" : "\"¡Hola!\"",
    "Hej"  : "\"Hej!!!\""
], fallback: "Unknown")
