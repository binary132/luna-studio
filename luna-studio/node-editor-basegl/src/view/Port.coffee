export class Port
    constructor: ({name: @name}, @scene) ->

    render: =>

# Mode: Normal | Invisible | Inactive | TypeNotMatched | Highlighted | Moved Position | NameEdit
#
# Port:
#   portId    :: i
#   name      :: Text
#   valueType :: TypeRep
#   state     :: PortState
#   mode      :: Mode
