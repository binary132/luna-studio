export class ExpressionNode
    constructor: (@name, @expression, @inPorts, @outPorts, @position) ->

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
