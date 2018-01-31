module NodeEditor.View.Connection where

import           Common.Data.JSON                  (toJSONVal)
import           Common.Prelude
import           Data.Aeson                        (ToJSON)
import           Data.Convert                      (Convertible (convert))
import qualified Data.HashMap.Strict               as HashMap
import           NodeEditor.React.Model.Connection (Connection, ConnectionsMap)
import qualified NodeEditor.React.Model.Connection as Connection


connectionsView :: MonadIO m => ConnectionsMap -> ConnectionsMap -> m ()
connectionsView new old =
    when (new /= old) $
        setConnections $ map convert $ HashMap.elems new


data ConnectionView = ConnectionView
        deriving (Generic, Show)

instance ToJSON ConnectionView
instance Convertible Connection ConnectionView where
    convert _ = ConnectionView

foreign import javascript safe "atomCallback.getNodeEditorView().setConnections($1)"
    setConnections' :: JSVal -> IO ()

setConnections :: MonadIO m => [ConnectionView] -> m ()
setConnections = liftIO . setConnections' <=< toJSONVal
