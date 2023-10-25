import WithSpecializedGeneric
//import simd
//
//// protocol KDTreeDelegate {
////     associatedtype V: SIMD
//// }
//
//
//struct SpecializedGenericArguments {
//    let namedAs: String
//    let specializing: [String: String]
//}
//
//
//
//
// enum Scoped {
//    @WithSpecializedGeneric(namedAs: "Hola", specializing: "T", to: Int)
//    final class Hello<T, S>: Identifiable where T: Hashable, S.ID == T, S: Identifiable {
//        let id: T
//        let children: Hello<T, S>

//        func greeting(with word: Hello<T, S>) -> Hello<T, S> {
//            let _: Hello<T, S> = Hello(id: word.id, children: word.children)
//            return Hello<T, S>(id: word.id, children: word.children)
//        }
       
//        init(id: T, children: Hello<T,S>) {
//            self.id = id
//            self.children = children.children
//        }
//    }
// }


//extension Scoped.Hello {
//    
//}
