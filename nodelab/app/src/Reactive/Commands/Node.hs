module Reactive.Commands.Node
    ( renameNode
    ) where

import           Utils.PreludePlus

import           Empire.API.Data.Node      (NodeId)
import qualified Empire.API.Data.Node      as Node

import qualified Object.Widget.Node            as Model

import           Reactive.Commands.Command (Command)
import           Reactive.Commands.Graph   (nodeIdToWidgetId)
import qualified Reactive.Commands.UIRegistry as UICmd
import           Reactive.State.Global     (inRegistry)
import qualified Reactive.State.Global     as Global
import qualified Reactive.State.Graph      as Graph


renameNode :: NodeId -> Text -> Command Global.State ()
renameNode nodeId name = do
    Global.graph . Graph.nodesMap . ix nodeId . Node.name .= name
    widgetId <- nodeIdToWidgetId nodeId
    inRegistry $ withJust widgetId $ flip UICmd.update_ $ Model.name .~ name


