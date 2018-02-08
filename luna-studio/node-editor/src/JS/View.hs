{-# LANGUAGE JavaScriptFFI #-}
module JS.View
    ( onEvent
    ) where

import           Common.Prelude
import           GHCJS.Foreign.Callback
import           GHCJS.Types                   (JSVal)
import           NodeEditor.Event.Event        (Event (View))
import           Common.Data.JSON              (fromJSONVal)


foreign import javascript safe "atomCallback.view.onEvent($1)"
    onEvent' :: Callback (JSVal -> IO ()) -> IO ()

foreign import javascript safe "atomCallback.view.unOnEvent($1)"
    unOnEvent' :: Callback (JSVal -> IO ()) -> IO ()

onEvent :: (Event -> IO ()) -> IO (IO ())
onEvent callback = do
    wrappedCallback <- syncCallback1 ContinueAsync $ mapM_ (callback . View) <=< fromJSONVal
    onEvent' wrappedCallback
    return $ unOnEvent' wrappedCallback >> releaseCallback wrappedCallback
