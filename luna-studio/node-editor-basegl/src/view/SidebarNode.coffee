export class SidebarNode
    constructor: ({ports: @ports, mode: @mode}, @scene) ->

    render: =>

# SidebarMode:
#   AddRemove | MoveConnect
#
# InputNode:
#   inputNodeLoc      :: NodeLoc
#   inputSidebarPorts :: [OutPortTree OutPort]
#   inputIsDef        :: Bool
#   inputMode         :: SidebarMode
#
# OutputNode:
#   outputNodeLoc      :: NodeLoc
#   outputSidebarPorts :: InPortTree InPort
#   outputMode         :: SidebarMode
