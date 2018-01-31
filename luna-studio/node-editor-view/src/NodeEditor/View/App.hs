module NodeEditor.View.App where

import           Common.Prelude
import           NodeEditor.React.Model.App  (App, breadcrumbs, nodeEditor)
import           NodeEditor.View.Breadcrumbs (breadcrumbsView)
import           NodeEditor.View.NodeEditor  (nodeEditorView)


appView :: MonadIO m => App -> App -> m ()
appView new old = do
    breadcrumbsView (new ^. breadcrumbs) (old ^. breadcrumbs)
    nodeEditorView (new ^. nodeEditor) (old ^. nodeEditor)
