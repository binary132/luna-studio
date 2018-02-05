import {Breadcrumbs}    from 'view/Breadcrumbs'
import {Connection}     from 'view/Connection'
import {ExpressionNode} from 'view/ExpressionNode'
import {Navigator}      from 'basegl/navigation/Navigator'
import {Port}           from 'view/Port'
import {SidebarNode}    from 'view/SidebarNode'


export class NodeEditor
    constructor: (@scene) ->
        @nodes ?= []
        @connections ?= []

    initialize: =>
        @controls = new Navigator @scene()

    unsetNode: (node) =>
        if @nodes[node.key]?
            @nodes[node.key].detach @scene()
            delete @nodes[node.key]

    setNode: (node) =>
        if @nodes[node.key]?
            @nodes[node.key].set node
        else
            nodeView = new ExpressionNode node
            @nodes[node.key] = nodeView
            nodeView.attach @scene()

    setNodes: (nodes) =>
        for node in nodes
            @setNode node
        undefined

    setInputNode: (inputNode) =>
        if @inputNode?
            @inputNode.set inputNode
        else
            @inputNode = new SidebarNode inputNode
            @inputNode.attach @scene()

    unsetInputNode: =>
        if @inputNode?
            @inputNode.detach @scene()
            @inputNode = null

    setOutputNode: (outputNode) =>
        if @outputNode?
            @outputNode.set outputNode
        else
            @outputNode = new SidebarNode outputNode
            @outputNode.attach @scene()

    unsetOutputNode: =>
        if @outputNode?
            @outputNode.detach @scene()
            @outputNode = null

    unsetConnection: (connection) =>
        if @connections[connection.key]?
            @connections[connection.key].detach @scene()
            delete @connections[connection.key]

    setConnection: (connection) =>
        if @connections[connection.key]?
            @connections[connection.key].set connection
        else
            connectionView = new Connection connection
            @connections[connection.key] = connectionView
            connectionView.attach @scene()

    setConnections: (connections) =>
        for connection in connections
            @setConnection connection
        undefined

    setBreadcrumbs: (breadcrumbs) =>
        if @breadcrumbs?
            @breadcrumbs.set breadcrumbs
        else
            @breadcrumbs = new Breadcrumbs breadcrumbs
            @breadcrumbs.attach @scene()

    unsetBreadcrumbs: =>
        if @breadcrumbs?
            @breadcrumbs.detach @scene()
            @breadcrumbs = null


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