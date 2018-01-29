export class NodeEditor
    constructor: (@nodes, @inputNode, @outputNode, @connections) ->


# expressionNodes          :: ExpressionNodesMap
# inputNode                :: Maybe InputNode
# outputNode               :: Maybe OutputNode
# monads                   :: [MonadPath]
# connections              :: ConnectionsMap
# visualizersLibPath       :: FilePath
# nodeVisualizations       :: Map NodeLoc NodeVisualizations
# visualizationsBackup     :: VisualizationsBackupMap
# halfConnections          :: [HalfConnection]
# connectionPen            :: Maybe ConnectionPen
# selectionBox             :: Maybe SelectionBox
# searcher                 :: Maybe Searcher
# textControlEditedPortRef :: Maybe InPortRef
# graphStatus              :: GraphStatus
# layout                   :: Layout
# topZIndex                :: Int