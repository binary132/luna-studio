export class NodeEditor
    constructor: (@nodes, @inputNode, @outputNode, @connections) ->
        @nodes ?= []
        @connections ?= []

    render: =>
        for node in @nodes
            node.render()
        for connection in @connections
            connection.render()
        @inputNode?.render()
        @outputNode?.render()


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