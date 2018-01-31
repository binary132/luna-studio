import * as basegl from 'basegl'
import {circle} from 'basegl/display/Shape'

myShape = circle 'myVar'

export class ExpressionNode
    constructor: ({name: @name, expression: @expression, inPorts: @inPorts, outPorts: @outPorts, position: @position}, @scene) ->

    render: =>
        mySymbol  = basegl.symbol myShape
        mySymbol.globalVariables.myVar = 100
        mySymbol1 = @scene.add mySymbol

# nodeLoc'                  :: NodeLoc
# name                      :: Maybe Text
# expression                :: Text
# isDefinition              :: Bool
# inPorts                   :: InPortTree InPort
# outPorts                  :: OutPortTree OutPort
# argConstructorMode        :: Port.Mode
# canEnter                  :: Bool
# position                  :: Position
# defaultVisualizer         :: Maybe Visualizer
# visEnabled                :: Bool
# errorVisEnabled           :: Bool
# code                      :: Text
# value                     :: Maybe Value
# zPos                      :: Int
# isSelected                :: Bool
# isMouseOver               :: Bool
# mode                      :: Mode
# isErrorExpanded           :: Bool
# execTime                  :: Maybe Integer
# collaboration             :: Collaboration
