---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Flowbox.Graphics.Image.Color.RGBA where

import           Data.Map (Map)

import           Flowbox.Graphics.Image
import qualified Flowbox.Graphics.Image.Channel as Channel
import           Flowbox.Prelude                hiding (lookup, map)



newtype ImageRGBA a = ImageRGBA { _channels' :: Map Channel.Name a } deriving (Monoid, Functor, Show)
makeLenses ''ImageRGBA

instance Image ImageRGBA a where
    channels = channels'
