import {circle}      from 'basegl/display/Shape'
import * as basegl from 'basegl'

import {NodeEditor} from 'view/NodeEditor'

myShape = circle('myVar')


export install = (name) ->
  scene = basegl.scene {domElement: name}

  mySymbol  = basegl.symbol myShape
  mySymbol.globalVariables.myVar = 100
  mySymbol1 = scene.add mySymbol

main = () ->
  install 'basegl-root'

window.run = main
window.x = new NodeEditor()
