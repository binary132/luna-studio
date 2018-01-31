module NodeEditor.View.NodeEditor where

import           Common.Prelude
import           NodeEditor.React.Model.NodeEditor          (NodeEditor, connections, expressionNodes, inputNode, outputNode)
import           NodeEditor.View.Connection                 (connectionsView)
import           NodeEditor.View.ExpressionNode             (expressionNodesView)
import           NodeEditor.View.SidebarNode                (inputNodeView, outputNodeView)


nodeEditorView :: MonadIO m => NodeEditor -> NodeEditor -> m ()
nodeEditorView new old = do
    expressionNodesView (new ^. expressionNodes) (old ^. expressionNodes)
    connectionsView (new ^. connections) (old ^. connections)
    inputNodeView (new ^. inputNode) (old ^. inputNode)
    outputNodeView (new ^. outputNode) (old ^. outputNode)
