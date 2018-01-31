module NodeEditor.View.ExpressionNode where

import           Common.Data.JSON                           (toJSONVal)
import           Common.Prelude
import           Data.Aeson                                 (ToJSON)
import           Data.Convert                               (Convertible (convert))
import qualified Data.HashMap.Strict                        as HashMap
import           LunaStudio.Data.Position                   (toTuple)
import           NodeEditor.React.Model.Node.ExpressionNode (ExpressionNode, ExpressionNodesMap)
import qualified NodeEditor.React.Model.Node.ExpressionNode as ExpressionNode


expressionNodesView :: MonadIO m => ExpressionNodesMap -> ExpressionNodesMap -> m ()
expressionNodesView new old =
    when (new /= old) $
        setNodes $ map convert $ HashMap.elems new

data ExpressionNodeView = ExpressionNodeView
        { name       :: String
        , expression :: String
        , inPorts    :: [String]
        , outPorts   :: [String]
        , position   :: (Double, Double)
        } deriving (Generic, Show)

instance ToJSON ExpressionNodeView
instance Convertible ExpressionNode ExpressionNodeView where
    convert n = ExpressionNodeView
        {- name       -} (n ^. ExpressionNode.name . to convert . to (fromMaybe def))
        {- expression -} (n ^. ExpressionNode.expression . to convert)
        {- inPorts    -} def
        {- outPorts   -} def
        {- position   -} (n ^. ExpressionNode.position . to toTuple)

foreign import javascript safe "atomCallback.getNodeEditorView().setNodes($1)"
    setNodes' :: JSVal -> IO ()

setNodes :: MonadIO m => [ExpressionNodeView] -> m ()
setNodes = liftIO . setNodes' <=< toJSONVal
