enum Scoped {
    @WithSpecializedGeneric(namedAs: "Hola", specializing: "T", to: Int)
    @WithSpecializedGeneric(namedAs: "Hej", specializing: "T", to: String)
    class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
        let id: T
        let a: S
    }
}
