import * as basegl from 'basegl'

import {ExpressionNode} from 'view/ExpressionNode'
import {NodeEditor}     from 'view/NodeEditor'

scene = null
nodeEditor = new NodeEditor -> scene

export getNodeEditor = -> nodeEditor

export install = (name) ->
    scene = basegl.scene {domElement: name}

main = -> install 'basegl-root'

window.run = main

debug = ->
    main()
    nodeEditor.setNodes [
        new ExpressionNode
            name: "foo"
            position: [0,0]
        new ExpressionNode
            name: "bar"
            position: [300,100]
        ]
    window.n = getNodeEditor()
    getNodeEditor().render()

# debug()