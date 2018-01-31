import {Connection}     from 'view/Connection'
import {ExpressionNode} from 'view/ExpressionNode'
import {Port}           from 'view/Port'
import {SidebarNode}    from 'view/SidebarNode'


export class NodeEditor
    constructor: (@scene) ->
        @nodes ?= []
        @connections ?= []

    setNodes: (nodes) =>
        @nodes = []
        for node in nodes
            @nodes.push new ExpressionNode node, @scene
        undefined
    setInputNode: (inputNode) =>
        @inputNode = new SidebarNode inputNode, @scene
    setOutputNode: (outputNode) =>
        @outputNode = new SidebarNode outputNode, @scene
    setConnections: (connections) =>
        @connections = []
        for connection in connections
            @connections.push new Connection connection, @scene
        undefined
    setBreadcrumbs: (@breadcrumbs) =>

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