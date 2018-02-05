export class SidebarNode
    constructor: (values) ->
        @set values

    set: ({ports: @ports, mode: @mode}) =>
        @updateView()

    updateView: =>

    render: =>

    attach: (scene) =>

    detach: (scene) =>

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
