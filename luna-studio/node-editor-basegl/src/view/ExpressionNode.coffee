import * as basegl from 'basegl'
import * as Color     from 'basegl/display/Color'
import {circle, glslShape, union, grow, negate, rect, quadraticCurve, path}      from 'basegl/display/Shape'

nodeRadius     = 30
gridElemOffset = 18
arrowOffset    = gridElemOffset + 2

nodeSelectionBorderMaxSize = 40

nodew = 200
nodeh = 350

white          = Color.rgb [1,1,1]
bg             = (Color.hsl [40,0.08,0.09]).toRGB()
selectionColor = bg.mix (Color.hsl [50, 1, 0.6]), 0.8
nodeBg         = bg.mix white, 0.04

nodeShape = basegl.expr ->
    border       = 0
    bodyWidth    = 200
    bodyHeight   = 300
    slope        = 20
    headerOffset = arrowOffset
    r1    = nodeRadius + border
    r2    = nodeRadius + headerOffset + slope - border
    dy    = slope
    dx    = Math.sqrt ((r1+r2)*(r1+r2) - dy*dy)
    angle = Math.atan(dy/dx)

    maskPlane     = glslShape("-sdf_halfplane(p, vec2(1.0,0.0));").moveX(dx)
    maskRect      = rect(r1+r2, r2 * Math.cos(-angle)).alignedTL.rotate(-angle)
    mask          = (maskRect - maskPlane).inside
    headerShape   = (circle(r1) + mask) - circle(r2).move(dx,dy)
    headerFill    = rect(r1*2, nodeRadius + headerOffset + 10).alignedTL.moveX(-r1)
    header        = (headerShape + headerFill).move(nodeRadius,nodeRadius).moveY(headerOffset+bodyHeight)

    body          = rect(bodyWidth + 2*border, bodyHeight + 2*border, 0, nodeRadius).alignedBL
    node          = (header + body).move(nodeSelectionBorderMaxSize,nodeSelectionBorderMaxSize)
    node          = node.fill nodeBg

    eye           = 'scaledEye.z'
    border        = node.grow(Math.pow(Math.clamp(eye*20.0, 0.0, 400.0),0.7)).grow(-1)

    sc            = selectionColor.copy()
    sc.a = 'selected'
    border        = border.fill sc

    border + node

nodeDef = basegl.symbol nodeShape
nodeDef.variables.selected = 0
nodeDef.bbox.xy = [nodew + 2*nodeSelectionBorderMaxSize, nodeh + 2*nodeSelectionBorderMaxSize]

export class ExpressionNode
    constructor: ({name: @name, expression: @expression, inPorts: @inPorts, outPorts: @outPorts, position: @position}, @scene) ->

    render: =>
        mySymbol1 = @scene.add nodeDef
        mySymbol1.position.xy = @position

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
