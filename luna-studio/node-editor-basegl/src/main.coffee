import * as basegl from 'basegl'

import {NodeEditor}     from 'view/NodeEditor'

nodeEditor = new NodeEditor()


export getNodeEditor = -> nodeEditor

export install = (name) ->
    scene = basegl.scene {domElement: name}
    nodeEditor.scene = scene

main = () ->
  install 'basegl-root'

window.run = main
window.n = getNodeEditor()
