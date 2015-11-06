{-# LANGUAGE ExistentialQuantification #-}

module Object.Widget.Scene where

import Utils.PreludePlus
import Object.Widget

data Scene = Scene deriving (Show)

makeLenses ''Scene

instance IsDisplayObject Scene where
    widgetPosition = error "Scene has no position"

instance UIDisplayObject Scene where
    createUI _ _ _ = error "Scene has no creator"
    updateUI _ _ _ = error "Scene has no updater"

