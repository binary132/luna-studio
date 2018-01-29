import * as basegl from 'basegl'

import {NodeEditor}     from 'view/NodeEditor'
import {ExpressionNode} from 'view/ExpressionNode'
import {SidebarNode}    from 'view/SidebarNode'
import {Port}           from 'view/Port'

nodeEditor = new NodeEditor()


export getNodeEditor = -> nodeEditor

export install = (name) ->
    scene = basegl.scene {domElement: name}
    nodeEditor.scene = scene

main = () ->
  install 'basegl-root'

window.run = main
window.x = getNodeEditor()
