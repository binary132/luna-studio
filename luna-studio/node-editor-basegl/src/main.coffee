import * as basegl from 'basegl'

import {ExpressionNode} from 'view/ExpressionNode'
import {NodeEditor}     from 'view/NodeEditor'

nodeEditor = null


export getNodeEditor = -> nodeEditor

export install = (name) ->
    scene = basegl.scene {domElement: name}
    nodeEditor = new NodeEditor scene

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
            position: [10,10]
        ]
    window.n = getNodeEditor()
    getNodeEditor().render()
