module Reactive.Commands.AutoLayout where

import           Utils.PreludePlus
import qualified Object.Widget.Node as Model
import qualified Object.Widget as Widget
import           Data.Map               (Map)
import qualified Data.Map               as Map
import           Utils.Vector           (Vector2, fromTuple, toTuple)
import           Utils.Graph.AutoLayout (autoLayout)
import           Control.Monad.State    hiding (State)

import           Reactive.Commands.Command (Command, performIO)
import           Reactive.Commands.Graph   (allNodes)
import qualified Reactive.Commands.UIRegistry as UICmd
import           Reactive.State.Global     (State)
import qualified Reactive.State.Global     as Global
import qualified Reactive.State.Graph      as Graph
import qualified BatchConnector.Commands   as BatchCmd
import           Empire.API.Data.Node (Node(..), NodeId)
import qualified Empire.API.Data.Node as Node


layoutGraph :: Command State ()
layoutGraph = do
    newNodes  <- moveNodes
    workspace <- use Global.workspace
    performIO $ BatchCmd.updateNodes workspace newNodes

moveNodes :: Command State [Node]
moveNodes = do
    nodes       <- uses Global.graph Graph.getNodes
    connections <- uses Global.graph Graph.getConnections
    nodesMap    <- uses Global.graph Graph.getNodesMap
    let newPositions = autoLayout (view Node.nodeId <$> nodes)
                                  (Graph.connectionToNodeIds <$> connections)
                                  150.0
                                  150.0
    let newNodesMap = updatePosition newPositions <$> nodesMap
    Global.graph . Graph.nodesMap .= newNodesMap

    allWidgets <- zoom Global.uiRegistry allNodes
    forM_ allWidgets $ \file -> do
        let pos = newPositions ^? ix (file ^. Widget.widget . Model.nodeId)
        case pos of
            Nothing -> return ()
            Just pos -> zoom Global.uiRegistry $ UICmd.move (file ^. Widget.objectId) pos

    use $ Global.graph . Graph.nodes


updatePosition :: Map NodeId (Vector2 Double) -> Node -> Node
updatePosition newPositions node = node & Node.position .~ (toTuple $ Map.findWithDefault (fromTuple $ node ^. Node.position)
                                                                                         (node ^. Node.nodeId)
                                                                                         newPositions)

