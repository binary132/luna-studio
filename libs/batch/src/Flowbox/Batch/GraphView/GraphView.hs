---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

module Flowbox.Batch.GraphView.GraphView(
    module Flowbox.Luna.Data.Graph,
    GraphView,
    empty,
    
    isNotAlreadyConnected,

    fromGraph,
    toGraph
) where

import qualified Data.List                               as List
import           Data.Map                                  (Map)
import qualified Data.Map                                as Map
import           Data.Foldable                             (foldrM)

import qualified Flowbox.Batch.Batch                     as Batch
import qualified Flowbox.Batch.GraphView.Defaults        as Defaults
import qualified Flowbox.Batch.GraphView.EdgeView        as EdgeView
import           Flowbox.Batch.GraphView.EdgeView          (EdgeView(..))
import           Flowbox.Batch.GraphView.PortDescriptor    (PortDescriptor)
import qualified Flowbox.Luna.Data.Graph                 as DG
import           Flowbox.Luna.Data.Graph                 hiding (Graph, Edge, empty, fromGraph)
import           Flowbox.Luna.Network.Graph.DefaultValue   (DefaultValue)
import qualified Flowbox.Luna.Network.Graph.Graph        as Graph
import           Flowbox.Luna.Network.Graph.Graph          (Graph)
import           Flowbox.Luna.Network.Graph.Edge           (Edge(..))
import qualified Flowbox.Luna.Network.Graph.Node         as Node
import           Flowbox.Luna.Network.Graph.Node           (Node(..))
import qualified Flowbox.Luna.Network.Attributes         as Attributes
import           Flowbox.Luna.Network.Attributes           (Attributes)
import qualified Flowbox.Luna.Network.Flags              as Flags
import           Flowbox.Control.Error                     ()



type GraphView = DG.Graph Node EdgeView


empty :: GraphView
empty = DG.empty


portMatches :: PortDescriptor -> LEdge EdgeView -> Bool
portMatches adstPort (_, _, connectedPort) = matches where
    connectedDstPort = EdgeView.dstPort connectedPort
    matches = List.isPrefixOf connectedDstPort adstPort
           || List.isPrefixOf adstPort connectedDstPort

isNotAlreadyConnected :: GraphView -> Node.ID -> PortDescriptor -> Bool
isNotAlreadyConnected graphview nodeID adstPort = not connected where
    connected = any (portMatches adstPort) (inn graphview nodeID)


------ Conversion to/from Graph --------------------------------------------------------

isGeneratedKey :: String
isGeneratedKey = "GraphView-generated"


selectKey :: String
selectKey = "GraphView-select"


trueVal :: String
trueVal = "True"


generatedAttrs :: Attributes
generatedAttrs = Attributes.fromList [(Batch.attributeKey, Map.fromList [(isGeneratedKey, trueVal)])]


selectAttrs :: Int -> Attributes
selectAttrs num = Attributes.fromList [(Batch.attributeKey, Map.fromList [(isGeneratedKey, trueVal)
                                                                   ,(selectKey, show num)])]

removeEdges :: DG.Graph a b -> DG.Graph a c
removeEdges graph = mkGraph (labNodes graph) []


connectG :: (Node.ID, Node.ID, EdgeView) -> Graph -> Either String Graph
connectG (srcNodeID, dstNodeID, EdgeView srcPorts dstPorts) graph = case srcPorts of 
    [] -> case dstPorts of 
        []         -> Right $ Graph.insEdge (srcNodeID, dstNodeID, Edge 0) graph
        [adstPort] -> do 
            (tupleID, graphT) <- case prel graph dstNodeID of 
                []                             -> do
                            let [newTupleID] = Graph.newNodes 1 graph
                                newTupleNode = NTuple Flags.empty generatedAttrs
                                newGraphT    = Graph.insEdge (newTupleID, dstNodeID, Edge 0)
                                             $ Graph.insNode (newTupleID, newTupleNode) graph
                            return (newTupleID, newGraphT)
                [(existingTupleID, NTuple {})] -> Right (existingTupleID, graph)
                _                              -> Left "Connect nodes failed"
            return $ Graph.insEdge (srcNodeID, tupleID  , Edge adstPort) graphT
        _         -> Left "dst port descriptors cannot have lenght greater than 1."
    _ -> connectG (selectID, dstNodeID, EdgeView srcPortsTail dstPorts) newGraph where
        srcPortsHead = head srcPorts
        srcPortsTail = tail srcPorts
        selectNode = Call ("select" ++ show srcPortsHead) Flags.empty $ selectAttrs srcPortsHead
        [selectID] = Graph.newNodes 1 graph
        newGraph = Graph.insEdge (srcNodeID, selectID, Edge 0)
                 $ Graph.insNode (selectID, selectNode) graph



addNodeDefaults :: GraphView -> (Node.ID, Node) -> Graph -> Either String Graph
addNodeDefaults graphview (nodeID, node) graph = do

    let 
        addNodeDefault :: (PortDescriptor, DefaultValue) -> Graph -> Either String Graph
        addNodeDefault (adstPort, defaultValue) g = do
            if isNotAlreadyConnected graphview nodeID adstPort
                then do let (newG1, defaultNodeID) = Graph.insNewNode (Default defaultValue generatedAttrs) g
                        connectG (defaultNodeID, nodeID, EdgeView [] adstPort) newG1
                else Right g

    let defaultsMap = Defaults.getDefaults node
    foldrM addNodeDefault graph $ Map.toList defaultsMap


addNodesDefaults :: GraphView -> Graph -> Either String Graph
addNodesDefaults graphview graphWithoutDefaults = 
    foldrM (addNodeDefaults graphview) graphWithoutDefaults (labNodes graphWithoutDefaults)


toGraph :: GraphView -> Either String Graph
toGraph graphview = do
    let graphWithoutEdges = removeEdges graphview
    graphWithoutDefaults <- foldrM (connectG) graphWithoutEdges $ labEdges graphview
    graph                <- addNodesDefaults graphview graphWithoutDefaults 
    return graph


graph2graphView :: Graph -> GraphView
graph2graphView graph = graphv where

    edge2edgeView :: (Node.ID, Node.ID, Edge) -> (Node.ID, Node.ID, EdgeView)
    edge2edgeView (s, d, Edge adst) = case lab graph d of
        Just (NTuple {}) -> (s, d, EdgeView [] [adst])
        _                -> (s, d, EdgeView [] [])
    
    anodes  = labNodes graph
    aedges  = map edge2edgeView $ labEdges graph
    graphv = mkGraph anodes aedges


fromGraph :: Graph -> Either String GraphView
fromGraph graph = do
    let graphC = graph2graphView graph
    foldrM (delGenerated) graphC $ labNodes graphC


getBatchAttrs :: Node -> Maybe (Map String String)
getBatchAttrs node = Map.lookup Batch.attributeKey attrs where
    attrs = Node.attributes node
                  

isGenerated :: Node -> Bool
isGenerated node = case getBatchAttrs node of
    Nothing         -> False
    Just batchAttrs -> case Map.lookup isGeneratedKey batchAttrs of 
        Just "True" -> True
        _           -> False


selectNo :: Node -> Maybe Int
selectNo node = do 
    batchAttrs <- getBatchAttrs node
    num        <- Map.lookup selectKey batchAttrs
    return $ read num


delGenerated :: (Node.ID, Node) -> GraphView -> Either String GraphView
delGenerated (nodeID, node) graph = case isGenerated node of 
    False -> Right graph
    True  -> case node of 
        NTuple {}  -> case (inn graph nodeID, suc graph nodeID) of
            (inEdges, [adst]) -> Right $ delNode nodeID
                               $ insEdges newEdges graph where 
                                    newEdges = map (\(asrc, _, ev) -> (asrc, adst, ev)) inEdges
            _ -> Left "Batch attributes mismatch - incorrectly connected NTuple"
        Default {} -> Right $ delNode nodeID graph
        _          -> case (selectNo node, inn graph nodeID, out graph nodeID) of 
            (Just num, [(asrc, _, EdgeView isrcPort _)], [(_, adst, EdgeView osrcPort odstPort)])
                -> Right $ delNode nodeID 
                 $ insEdge (asrc, adst, EdgeView (isrcPort ++ [num] ++ osrcPort) odstPort) graph
            _   -> Left "Batch attributes mismatch - incorrectly connected Select"




