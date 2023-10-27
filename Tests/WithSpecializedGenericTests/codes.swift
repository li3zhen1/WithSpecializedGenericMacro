//
//  File.swift
//  
//
//  Created by li3zhen1 on 10/23/23.
//
let simulationCode = """
        import NDTree
        import WithSpecializedGeneric
        import simd

        enum Simulation {}

        extension Simulation {

            /// An N-Dimensional force simulation.
            @WithSpecializedGenerics(
                \"""
                typealias Double2D<NodeID> = Core<NodeID, simd_double2>
                typealias Double3D<NodeID> = Core<NodeID, simd_double3>
                typealias Float2D<NodeID> = Core<NodeID, simd_float2>
                typealias Float3D<NodeID> = Core<NodeID, simd_float3>
                \""")
            public final class Core<NodeID, V>
            where NodeID: Hashable, V: VectorLike, V.Scalar: SimulatableFloatingPoint {

                /// The type of the vector used in the simulation.
                /// Usually this is `Scalar` if you are on Apple platforms.
                public typealias Scalar = V.Scalar

                public let initializedAlpha: Scalar

                public var alpha: Scalar
                public var alphaMin: Scalar
                public var alphaDecay: Scalar
                public var alphaTarget: Scalar

                public var velocityDecay: Scalar

                public internal(set) var forces: [any ForceLike] = []

                /// The position of points stored in simulation.
                /// Ordered as the nodeIds you passed in when initializing simulation.
                /// They are always updated.
                public internal(set) var nodePositions: [V]

                /// The velocities of points stored in simulation.
                /// Ordered as the nodeIds you passed in when initializing simulation.
                /// They are always updated.
                public internal(set) var nodeVelocities: [V]

                /// The fixed positions of points stored in simulation.
                /// Ordered as the nodeIds you passed in when initializing simulation.
                /// They are always updated.
                public internal(set) var nodeFixations: [V?]

                public private(set) var nodeIds: [NodeID]

                @usableFromInline internal private(set) var nodeIdToIndexLookup: [NodeID: Int] = [:]

                /// Create a new simulation.
                /// - Parameters:
                ///   - nodeIds: Hashable identifiers for the nodes. Force simulation calculate them by order once created.
                ///   - alpha:
                ///   - alphaMin:
                ///   - alphaDecay: The larger the value, the faster the simulation converges to the final result.
                ///   - alphaTarget:
                ///   - velocityDecay:
                ///   - getInitialPosition: The closure to set the initial position of the node. If not provided, the initial position is set to zero.
                public init(
                    nodeIds: [NodeID],
                    alpha: Scalar = 1,
                    alphaMin: Scalar = 1e-3,
                    alphaDecay: Scalar = 2e-3,
                    alphaTarget: Scalar = 0.0,
                    velocityDecay: Scalar = 0.6,

                    setInitialStatus getInitialPosition: (
                        (NodeID) -> V
                    )? = nil

                ) {

                    self.alpha = alpha
                    self.initializedAlpha = alpha  // record and reload this when restarted

                    self.alphaMin = alphaMin
                    self.alphaDecay = alphaDecay
                    self.alphaTarget = alphaTarget

                    self.velocityDecay = velocityDecay

                    if let getInitialPosition {
                        self.nodePositions = nodeIds.map(getInitialPosition)
                    } else {
                        self.nodePositions = Array(repeating: .zero, count: nodeIds.count)
                    }

                    self.nodeVelocities = Array(repeating: .zero, count: nodeIds.count)
                    self.nodeFixations = Array(repeating: nil, count: nodeIds.count)

                    self.nodeIdToIndexLookup.reserveCapacity(nodeIds.count)
                    for i in nodeIds.indices {
                        self.nodeIdToIndexLookup[nodeIds[i]] = i
                    }
                    self.nodeIds = nodeIds

                }

                /// Get the index in the nodeArray for `nodeId`
                /// - **Complexity**: O(1)
                public func getIndex(of nodeId: NodeID) -> Int {
                    return nodeIdToIndexLookup[nodeId]!
                }

                /// Reset the alpha. The points will move faster as alpha gets larger.
                public func resetAlpha(_ alpha: Scalar) {
                    self.alpha = alpha
                }

                /// Run the simulation for a number of iterations.
                /// Goes through all the forces created.
                /// The forces will call  `apply` then the positions and velocities will be modified.
                /// - Parameter iterationCount: Default to 1.
                public func tick(iterationCount: UInt = 1) {
                    for _ in 0..<iterationCount {
                        alpha += (alphaTarget - alpha) * alphaDecay

                        for f in forces {
                            f.apply()
                        }

                        for i in nodePositions.indices {
                            if let fixation = nodeFixations[i] {
                                nodePositions[i] = fixation
                            } else {
                                nodeVelocities[i] *= velocityDecay
                                nodePositions[i] += nodeVelocities[i]
                            }
                        }

                    }
                }

                final public class CenterForce: ForceLike {

                    public var center: V
                    public var strength: V.Scalar
                    weak var simulation: Core<NodeID, V>?

                    internal init(center: V, strength: V.Scalar) {
                        self.center = center
                        self.strength = strength
                    }

                    public func apply() {
                        guard let sim = self.simulation else { return }
                        var meanPosition = V.zero
                        for n in sim.nodePositions {
                            meanPosition += n  //.position
                        }
                        let delta = meanPosition * (self.strength / V.Scalar(sim.nodePositions.count))

                        for i in sim.nodePositions.indices {
                            sim.nodePositions[i] -= delta
                        }
                    }

                }

                /// A force that prevents nodes from overlapping.
                /// This is a very expensive force, the complexity is `O(n log(n))`,
                /// where `n` is the number of nodes.
                /// See [Collide Force - D3](https://d3js.org/d3-force/collide).
                public final class CollideForce: ForceLike {

                    weak var simulation: Core<NodeID, V>? {
                        didSet {
                            guard let sim = simulation else { return }
                            self.calculatedRadius = radius.calculated(for: sim)
                        }
                    }

                    public enum CollideRadius {
                        case constant(V.Scalar)
                        case varied((NodeID) -> V.Scalar)

                        public func calculated(for simulation: Core<NodeID, V>) -> [V.Scalar] {
                            switch self {
                            case .constant(let r):
                                return Array(repeating: r, count: simulation.nodePositions.count)
                            case .varied(let radiusProvider):
                                return simulation.nodeIds.map { radiusProvider($0) }
                            }
                        }
                    }
                    public var radius: CollideRadius
                    var calculatedRadius: [V.Scalar] = []

                    public let iterationsPerTick: UInt
                    public var strength: V.Scalar

                    internal init(
                        radius: CollideRadius,
                        strength: V.Scalar = 1.0,
                        iterationsPerTick: UInt = 1
                    ) {
                        self.radius = radius
                        self.iterationsPerTick = iterationsPerTick
                        self.strength = strength
                    }

                    public func apply() {
                        guard let sim = self.simulation else { return }
                        //                let alpha = sim.alpha

                        for _ in 0..<iterationsPerTick {

                            let coveringBox = NDBox<V>.cover(of: sim.nodePositions)

                            let clusterDistance: V.Scalar = V.Scalar(Int(0.00001))

                            let tree = NDTree<V, MaxRadiusTreeDelegate<Int, V>>(
                                box: coveringBox, clusterDistance: clusterDistance
                            ) {
                                return switch self.radius {
                                case .constant(let m):
                                    MaxRadiusTreeDelegate<Int, V> { _ in m }
                                case .varied(_):
                                    MaxRadiusTreeDelegate<Int, V> { index in
                                        self.calculatedRadius[index]
                                    }
                                }
                            }

                            for i in sim.nodePositions.indices {
                                tree.add(i, at: sim.nodePositions[i])
                            }

                            for i in sim.nodePositions.indices {
                                let iOriginalPosition = sim.nodePositions[i]
                                let iOriginalVelocity = sim.nodeVelocities[i]
                                let iR = self.calculatedRadius[i]
                                let iR2 = iR * iR
                                let iPosition = iOriginalPosition + iOriginalVelocity

                                tree.visit { t in

                                    let maxRadiusOfQuad = t.delegate.maxNodeRadius
                                    let deltaR = maxRadiusOfQuad + iR

                                    if t.nodePosition != nil {
                                        for j in t.nodeIndices {
                                            //                            print("\\(i)<=>\\(j)")
                                            // is leaf, make sure every collision happens once.
                                            guard j > i else { continue }

                                            let jR = self.calculatedRadius[j]
                                            let jOriginalPosition = sim.nodePositions[j]
                                            let jOriginalVelocity = sim.nodeVelocities[j]
                                            var deltaPosition =
                                                iPosition - (jOriginalPosition + jOriginalVelocity)
                                            let l = deltaPosition.lengthSquared()

                                            let deltaR = iR + jR
                                            if l < deltaR * deltaR {

                                                var l = deltaPosition.jiggled().length()
                                                l = (deltaR - l) / l * self.strength

                                                let jR2 = jR * jR

                                                let k = jR2 / (iR2 + jR2)

                                                deltaPosition *= l

                                                sim.nodeVelocities[i] += deltaPosition * k
                                                sim.nodeVelocities[j] -= deltaPosition * (1 - k)
                                            }
                                        }
                                        return false
                                    }

                                    for laneIndex in t.box.p0.indices {
                                        let _v = t.box.p0[laneIndex]
                                        if _v > iPosition[laneIndex] + deltaR /* True if no overlap */ {
                                            return false
                                        }
                                    }

                                    for laneIndex in t.box.p1.indices {
                                        let _v = t.box.p1[laneIndex]
                                        if _v < iPosition[laneIndex] - deltaR /* True if no overlap */ {
                                            return false
                                        }
                                    }
                                    return true

                                    // return
                                    //     !(t.quad.x0 > iPosition.x + deltaR /* True if no overlap */
                                    //     || t.quad.x1 < iPosition.x - deltaR
                                    //     || t.quad.y0 > iPosition.y + deltaR
                                    //     || t.quad.y1 < iPosition.y - deltaR)
                                }
                            }
                        }
                    }

                }

                public final class LinkForce: ForceLike {

                    ///
                    public enum LinkStiffness {
                        case constant(V.Scalar)
                        case varied((EdgeID<NodeID>, LinkLookup<NodeID>) -> V.Scalar)
                        case weightedByDegree(k: (EdgeID<NodeID>, LinkLookup<NodeID>) -> V.Scalar)
                    }
                    var linkStiffness: LinkStiffness
                    var calculatedStiffness: [V.Scalar] = []

                    ///
                    public enum LinkLength {
                        case constant(V.Scalar)
                        case varied((EdgeID<NodeID>, LinkLookup<NodeID>) -> V.Scalar)
                    }
                    var linkLength: LinkLength
                    var calculatedLength: [V.Scalar] = []

                    /// Bias
                    var calculatedBias: [V.Scalar] = []

                    var iterationsPerTick: UInt

                    internal var linksOfIndices: [EdgeID<Int>] = []
                    var links: [EdgeID<NodeID>]

                    public struct LinkLookup<_NodeID> where _NodeID: Hashable {
                        let sources: [_NodeID: [_NodeID]]
                        let targets: [_NodeID: [_NodeID]]
                        let count: [_NodeID: Int]
                    }
                    private var lookup = LinkLookup<Int>(sources: [:], targets: [:], count: [:])

                    internal init(
                        _ links: [EdgeID<NodeID>],
                        stiffness: LinkStiffness,
                        originalLength: LinkLength = .constant(30),
                        iterationsPerTick: UInt = 1
                    ) {
                        self.links = links
                        self.iterationsPerTick = iterationsPerTick
                        self.linkStiffness = stiffness
                        self.linkLength = originalLength

                    }
                    
                    public func apply() {
                        
                    }

                }

            }

        }
        """
