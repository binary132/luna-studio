---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
module Flowbox.Graphics.Shape where

import           Control.Monad.IO.Class (MonadIO, liftIO)
import qualified Data.Array.MArray      as MA
import           Data.Array.Accelerate  (Elt, IsFloating, Z(..))
import qualified Data.Array.Accelerate  as A
import           Data.Bits              ((.&.))
import           Data.Word              (Word32)

import           Diagrams.Prelude                (R2, SizeSpec2D, Diagram)
import qualified Diagrams.Prelude                as Diag
import           Diagrams.Backend.Cairo.Internal (Cairo, OutputType(..))
import qualified Diagrams.Backend.Cairo.Internal as Diag
import           Graphics.Rendering.Cairo        (Format(..), SurfaceData)
import qualified Graphics.Rendering.Cairo        as Cairo

import           Flowbox.Graphics.Image         (ImageAcc)
import qualified Flowbox.Graphics.Image         as Image
import qualified Flowbox.Graphics.Image.Channel as Channel
import           Flowbox.Prelude                as P

rasterize :: (MonadIO m, Elt a, IsFloating a, Eq a) => Int -> Int -> Double -> Double -> SizeSpec2D -> Diagram Cairo R2 -> m (ImageAcc A.DIM2 a)
--rasterize :: (MonadIO m) => Int -> Int -> Double -> Double -> SizeSpec2D -> Diagram Cairo R2 -> m (ImageAcc A.DIM2 Word32)
rasterize w h x y size diagram = do
    pixels <- liftIO makeElements

    let converted = fmap convert pixels
        red       = fmap (\(r, _, _, _) -> r) converted
        green     = fmap (\(_, g, _, _) -> g) converted
        blue      = fmap (\(_, _, b, _) -> b) converted
        alpha     = fmap (\(_, _, _, a) -> a) converted
        redAcc    = channelAcc red
        greenAcc  = channelAcc green
        blueAcc   = channelAcc blue
        alphaAcc  = channelAcc alpha

    return $ Image.insert "rgba.r" redAcc
           $ Image.insert "rgba.g" greenAcc
           $ Image.insert "rgba.b" blueAcc
           $ Image.insert "rgba.a" alphaAcc
           $ mempty
    where makeElements = do
              let (_, render) = Diag.renderDia Diag.Cairo (Diag.CairoOptions "" size RenderOnly False) diagram
              surface <- Cairo.createImageSurface FormatARGB32 w h
              Cairo.surfaceSetDeviceOffset surface x y
              Cairo.renderWith surface render
              pixels <- Cairo.imageSurfaceGetPixels surface :: IO (SurfaceData Int Word32)
              MA.getElems pixels
          convert rgba = (r, g, b, a)
              where b = handleAlpha ((fromIntegral $ rgba .&. 0xFF) / 255)
                    g = handleAlpha (calculate 0x100)
                    r = handleAlpha (calculate 0x10000)
                    a = calculate 0x1000000
                    calculate val = (fromIntegral $ (rgba `div` val) .&. 0xFF) / 255
                    handleAlpha val = case a of
                        0  -> val
                        a' -> val / a'
          channelAcc chan = Channel.Acc $ A.use $ A.fromList (Z A.:. h A.:. w) chan
