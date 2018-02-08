module NodeEditor.Handler.View where

import           Common.Prelude

import           Common.Action.Command   (Command)
import           NodeEditor.Event.Event  (Event (View))
import qualified NodeEditor.Event.View    as View
import           NodeEditor.State.Global (State)


handle :: Event -> Maybe (Command State ())
handle (View v) = Just $ print v
handle _ = Nothing
