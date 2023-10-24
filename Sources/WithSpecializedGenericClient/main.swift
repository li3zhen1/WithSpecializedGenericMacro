import WithSpecializedGeneric
import simd

protocol KDTreeDelegate {
    associatedtype V: SIMD
}

enum GreetingWords {
    
    @WithSpecializedGeneric(namedAs: "Hej", specializing: "T", to: String)
    class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
        let id: T
        let a: S
        
        init(a: S) {
            self.id = a.id
            self.a = a
        }
    }
    
    @WithSpecializedGeneric(namedAs: "_QuadTree", specializing: "V", to: simd_double2)
    public final class GenericTree<V, D> where V: SIMD, D: KDTreeDelegate, D.V == V {
    }
    
}
