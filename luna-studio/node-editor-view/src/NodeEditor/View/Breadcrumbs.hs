{-# LANGUAGE JavaScriptFFI     #-}
{-# LANGUAGE OverloadedStrings #-}

module NodeEditor.View.Breadcrumbs where

import           Common.Prelude
import           NodeEditor.React.Model.Breadcrumbs  (Breadcrumbs)
import           Common.Data.JSON                    (toJSONVal)


breadcrumbsView :: MonadIO m => Breadcrumbs -> Breadcrumbs -> m ()
breadcrumbsView new old =
    when (new /= old) $ setBreadcrumbs new

foreign import javascript safe "atomCallback.getNodeEditorView().setBreadcrumbs($1)"
    setBreadcrumbs' :: JSVal -> IO ()

setBreadcrumbs :: MonadIO m => Breadcrumbs -> m ()
setBreadcrumbs = liftIO . setBreadcrumbs' <=< toJSONVal
