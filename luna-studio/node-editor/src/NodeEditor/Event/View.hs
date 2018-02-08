{-# LANGUAGE DeriveAnyClass #-}

module NodeEditor.Event.View where

import           Common.Analytics            (IsTrackedEvent (isTracked))
import           Common.Data.Event           (EventName (eventName), consName)
import           Common.Prelude
import           Control.Lens.Aeson          (toEncodingDropUnary)
import           Data.Aeson                  (FromJSON (..), ToJSON (..))


type Path = [String]

data ViewEvent = ViewEvent
        { _path :: Path
        , _base :: BaseEvent
        } deriving (Generic, Show, NFData)

data BaseEvent
        = MouseDown {- -}
        | MouseUp {- ... -}
        deriving (Generic, Show, NFData)

makeLenses ''ViewEvent
makeLenses ''BaseEvent

instance FromJSON ViewEvent
instance FromJSON BaseEvent

instance ToJSON ViewEvent where toEncoding = toEncodingDropUnary
instance ToJSON BaseEvent where toEncoding = toEncodingDropUnary

instance EventName ViewEvent where
    eventName = intercalate "." . view path
instance IsTrackedEvent ViewEvent where
    isTracked = const False
