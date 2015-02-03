---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# OPTIONS_GHC -fcontext-stack=200 #-}

module Main where

import Flowbox.Geom2D.Accelerate.CubicBezier
import Flowbox.Geom2D.Accelerate.CubicBezier.Solve
import Flowbox.Geom2D.CubicBezier
import Flowbox.Graphics.Composition.Color              (LinearShader (..), crosstalk)
import Flowbox.Graphics.Composition.Dither
import Flowbox.Graphics.Composition.Filter
import Flowbox.Graphics.Composition.Filter             as Conv
import Flowbox.Graphics.Composition.Generator.Gradient
import Flowbox.Graphics.Composition.Generator.Shape
import Flowbox.Graphics.Composition.Keyer
import Flowbox.Graphics.Composition.Transform
import Flowbox.Graphics.Prelude                        as P
import Flowbox.Graphics.Shader.Matrix
import Flowbox.Graphics.Shader.Pipe
import Flowbox.Graphics.Shader.Rasterizer
import Flowbox.Graphics.Shader.Sampler
import Flowbox.Graphics.Shader.Shader                  as S
import Flowbox.Graphics.Shader.Stencil                 as Stencil

import Flowbox.Graphics.Utils.Accelerate   (asFloating, variable)
import Flowbox.Graphics.Utils.Utils        (mix)
import Flowbox.Math.BitonicSorterGenerator
import Flowbox.Math.Matrix                 as M

import qualified Data.Array.Accelerate              as A
import           Data.Array.Accelerate.Data.Complex ()

import Flowbox.Graphics.Utils.Linear ()
import Linear                        hiding (angle, inv33, normalize, rotate, zero)

import Math.Coordinate.Cartesian as Cartesian hiding (w, x, y, z)
import Math.Metric
import Math.Space.Space

import Utils



-- Test helpers
forAllChannels :: String -> (Matrix2 Float -> Matrix2 Float) -> IO ()
forAllChannels image process = do
    (r, g, b, a) <- testLoadRGBA' $ "samples/" P.++ image
    testSaveRGBA' "out.png" (process r) (process g) (process b) (process a)


--
-- Draws all the existing types of gradients using ContactSheet.
-- (General geometry test)
--
gradientsTest :: IO ()
gradientsTest = do
    let reds   = [Tick 0.0 1.0 1.0, Tick 0.25 0.0 1.0, Tick 1.0 1.0 1.0] :: [Tick Float Float Float]
    let greens = [Tick 0.0 1.0 1.0, Tick 0.50 0.0 1.0, Tick 1.0 1.0 1.0] :: [Tick Float Float Float]
    let blues  = [Tick 0.0 1.0 1.0, Tick 0.75 0.0 1.0, Tick 1.0 1.0 1.0] :: [Tick Float Float Float]

    let alphas = [Tick 0.0 1.0 1.0, Tick 1.0 1.0 1.0] :: [Tick Float Float Float]
    let gray   = [Tick 0.0 0.0 1.0, Tick 1.0 1.0 1.0] :: [Tick Float Float Float]
    let grays  = [Tick 0.0 0.0 1.0, Tick 0.5 1.0 1.0, Tick 1.0 0.0 1.0] :: [Tick Float Float Float]

    let weightFun tickPos val1 _weight1 val2 _weight2 = mix tickPos val1 val2
    let mapper = flip colorMapper weightFun
    let center = translate (V2 0.5 0.5) . scale (V2 0.5 0.5)
    let grad1 t = center $ mapper t circularShape
    let grad2 t = center $ mapper t diamondShape
    let grad3 t = center $ mapper t squareShape
    let grad4 t = center $ mapper t conicalShape
    let grad5 t = center $ mapper t $ radialShape (Minkowski 0.6)
    let grad6 t = center $ mapper t $ radialShape (Minkowski 3)
    let grad7 t = mapper t $ linearShape
    let grad8   = center . rotate (45 * pi / 180) $ mapper gray conicalShape
    let grad9 t = center $ mapper t $ gaussianShape

    --let raster t = gridRasterizer (Grid 720 480) (Grid 4 2) monosampler [grad1 t, grad2 t, grad3 t, grad4 t, grad5 t, grad6 t, grad7 t, grad8]
    --testSaveRGBA' "out.png" (raster reds) (raster greens) (raster blues) (raster alphas)

    let raster t = rasterizer $ monosampler $ scale (Grid 512 512) $ grad9 t
    testSaveRGBA' "out.png" (raster grays) (raster grays) (raster grays) (raster alphas)

--
-- Draws single conical gradient rotated 84deg
-- (Multisampling test)
--
multisamplerTest :: IO ()
multisamplerTest = do
    let gray   = [Tick 0.0 0.0 1.0, Tick 1.0 1.0 1.0] :: [Tick Float Float Float]
    let mysampler = multisampler (normalize $ toMatrix 10 box)
    let weightFun tickPos val1 _weight1 val2 _weight2 = mix tickPos val1 val2
    let mapper = flip colorMapper weightFun
    let shape = scale (Grid 720 480) conicalShape
    let grad      = rasterizer $ mysampler $ translate (V2 (720/2) (480/2)) $ rotate (84 * pi / 180) $ mapper gray shape
    testSaveChan' "out.png" grad


--
-- Upcales lena 64x64 image into 720x480 one
-- (Filtering test)
--
upscalingTest :: Filter (Exp Float) -> IO ()
upscalingTest flt = do
    let process = rasterizer
                . monosampler
                . scale (V2 (720 / 64) (480 / 64))
                . interpolator flt
                . fromMatrix A.Clamp
    forAllChannels "lena_small.bmp" process

downscalingTest :: Filter (Exp Float) -> IO ()
downscalingTest flt = do
    let process = rasterizer
                . monosampler
                . scale (200 :: Grid (Exp Int))
                . interpolator flt
                . fromMatrix (A.Constant 0)
    forAllChannels "rings.bmp" process


--
-- Applies 2 pass gaussian blur onto the 4k image
-- (Convolution regression test)
--
gaussianTest :: Exp Int -> IO ()
gaussianTest kernSize = do
    let hmat = id M.>-> normalize $ toMatrix (Grid 1 (variable kernSize)) $ gauss 1.0
    let vmat = id M.>-> normalize $ toMatrix (Grid (variable kernSize) 1) $ gauss 1.0
    let p = pipe A.Clamp
    let process x = rasterizer $ id `p` Conv.filter 1 vmat `p` Conv.filter 1 hmat `p` id $ fromMatrix A.Clamp x
    forAllChannels "moonbow.bmp" process


--
-- Applies laplacian edge detector to Lena image
-- (Edge detection test)
--
laplacianTest :: Exp Int -> Exp Float -> Exp Float -> IO ()
laplacianTest kernSize crossVal sideVal = do
    let flt = laplacian (variable crossVal) (variable sideVal) (pure $ variable kernSize)
    let p = pipe A.Clamp
    let process x = rasterizer $ id `p` Conv.filter 1 flt `p` id $ fromMatrix A.Clamp x
    forAllChannels "lena.bmp" process


--
-- Applies morphological operators to Lena image
-- (Morphology test)
--
--morphologyTest :: Exp Int -> IO ()
--morphologyTest size = do
--    let l c = fromMatrix A.Clamp c
--    let v = pure $ variable size
--    let morph1 c = nearest $ closing v $ l c -- Bottom left
--    let morph2 c = nearest $ opening v $ l c -- Bottom right
--    let morph3 c = nearest $ dilate  v $ l c -- Top left
--    let morph4 c = nearest $ erode   v $ l c -- Top right

--    let process chan = gridRasterizer 512 (Grid 2 2) (monosampler :: ContinuousShader (Exp Float) -> DiscreteShader (Exp Float)) [morph1 chan, morph2 chan, morph3 chan, morph4 chan]
--    forAllChannels "lena.bmp" process


--
-- Applies directional motion blur to Lena image
-- (Simple rotational convolution)
--
rotateCenter :: (Elt a, IsFloating a) => Exp a -> CartesianShader (Exp a) b -> CartesianShader (Exp a) b
rotateCenter phi = canvasT (fmap A.ceiling . rotate phi . asFloating) . onCenter (rotate phi)

motionBlur :: Exp Int -> Exp Float -> IO ()
motionBlur size angle = do
    let kern = monosampler
             $ rotateCenter (variable angle)
             $ nearest
             $ rectangle (Grid (variable size) 1) 1 0
    let process x = rasterizer $ normStencil (+) kern (+) 0 $ fromMatrix A.Clamp x
    forAllChannels "lena.bmp" process


--
-- Radial blur test
-- (Simple rotational convolution)
--
fromPolarMapping :: (Elt a, IsFloating a, Elt e) => CartesianShader (Exp a) (Exp e) -> CartesianShader (Exp a) (Exp e)
fromPolarMapping (Shader cnv gen) = Shader cnv $ \(Point2 x y) ->
    let Grid cw ch = fmap A.fromIntegral cnv
        radius = (sqrt $ x * x + y * y) / (sqrt $ cw * cw + ch * ch)
        angle  = atan2 y x / (2 * pi)
    in gen (Point2 (angle * cw) (radius * ch))

toPolarMapping :: (Elt a, IsFloating a, Elt e) => CartesianShader (Exp a) (Exp e) -> CartesianShader (Exp a) (Exp e)
toPolarMapping (Shader cnv gen) = Shader cnv $ \(Point2 angle' radius') ->
    let Grid cw ch = fmap A.fromIntegral cnv
        angle = (angle' / cw) * 2 * pi
        radius = (radius' / ch) * (sqrt $ cw * cw + ch * ch)
    in gen (Point2 (radius * cos angle) (radius * sin angle))

radialBlur :: Exp Int -> Exp Float -> IO ()
radialBlur size angle = do
    let kern = monosampler
             $ rotateCenter (variable angle)
             $ nearest
             $ rectangle (Grid (variable size) 1) 1 0
    let process x = rasterizer
                  $ (monosampler :: ContinuousShader (Exp Float) -> DiscreteShader (Exp Float))
                  $ translate (V2 (256) (256))
                  $ fromPolarMapping
                  $ nearest
                  $ normStencil (+) kern (+) 0
                  $ (monosampler :: ContinuousShader (Exp Float) -> DiscreteShader (Exp Float))
                  $ toPolarMapping
                  $ translate (V2 (-256) (-256))
                  $ nearest
                  $ fromMatrix A.Clamp x
    forAllChannels "lena.bmp" process


--
-- Defocus test
--
defocusBlur :: Exp Int -> IO ()
defocusBlur size = do
   let kern = ellipse (pure $ variable size) 1 (0 :: Exp Float)
   let process x = rasterizer $ normStencil (+) kern (+) 0 $ fromMatrix A.Clamp x
   forAllChannels "lena.bmp" process


--
-- Bounduary test
--
boundTest :: IO ()
boundTest = do
   let mysampler = multisampler (normalize $ toMatrix 10 box)
   let mask = mysampler $ scale (0.25 :: V2 (Exp Float)) $ nearest $ bound A.Mirror $ ellipse 200 1 (0 :: Exp Float)
   testSaveChan' "out.png" (rasterizer mask)


--
-- Applies Kirsch Operator to red channel of Lena image. Available operators: prewitt, sobel, sharr
-- (Advanced rotational convolution, Edge detection test)
--
rotational :: Exp Float
           -> DiscreteShader (Exp Float)
           -> DiscreteShader (Exp Float)
           -> DiscreteShader (Exp Float)
rotational phi mat chan = Stencil.stencil (+) edgeKern (+) 0 chan
    where edgeKern = monosampler $ rotateCenter (phi * pi / 180) $ nearest $ mat

kirschTest :: Matrix2 Float -> IO ()
kirschTest edgeOp = do
    (r :: Matrix2 Float, _, _, _) <- testLoadRGBA' "samples/lena.bmp"
    let k alpha = rotational alpha (unsafeFromMatrix edgeOp) (fromMatrix A.Clamp r)
    let max8 a b c d e f g h = a `max` b `max` c `max` d `max` e `max` f `max` g `max` h
    let res = rasterizer $ max8 <$> k 0 <*> k 45 <*> k 90 <*> k 135 <*> k 180 <*> k 225 <*> k 270 <*> k 315
    testSaveChan' "out.png" res


--
-- Unsharp mask - FIXME [kl]
-- (Sharpening test)
--
unsharpMaskTest :: Exp Float -> Exp Int -> IO ()
unsharpMaskTest sigma kernSize = do
    let flt = normalize $ toMatrix (Grid (variable kernSize) (variable kernSize)) $ dirac (variable sigma) - gauss 1.0
    let p = pipe A.Clamp
    let process x = rasterizer $ id `p` Conv.filter 1 flt `p` id $ fromMatrix A.Clamp x
    forAllChannels "lena.bmp" process

keyerTest :: Exp Float -> Exp Float -> Exp Float -> Exp Float -> IO ()
keyerTest w x y z = do
    rgb <- loadRGB "samples/keying/greenscreen.jpg"
    (r :: Matrix2 Float, g, b, _) <- testLoadRGBA' "samples/keying/greenscreen.jpg"
    let process c = M.map (keyer Greenscreen (A.lift (w, x, y, z))) c
    testSaveRGBA' "out.png" r g b (process rgb)

differenceKeyerTest :: Exp Float -> Exp Float -> IO ()
differenceKeyerTest off gain = do
    rgb <- loadRGB "samples/keying/greenscreen.jpg"
    (r :: Matrix2 Float, g, b, _) <- testLoadRGBA' "samples/keying/greenscreen.jpg"
    let process c = M.map (differenceKeyer off gain (rgb M.! (A.index2 1 1))) c
    testSaveRGBA' "out.png" r g b (process rgb)

--
-- FFT test
--
--fftTest :: (Exp Float -> Exp Float) -> IO ()
--fftTest response = do
--    -- Test with response = \x -> abs $ 50 * (x - 0.012)
--    let process = fftFilter run $ \freq ampl -> ampl * clamp' 0 2 (response $ freq / 150)
--    forAllChannels "edge/mountain.png" process

--
-- Dithering test
--
ditherTest :: Int -> IO ()
ditherTest a = do
    let mydither = dither A.Clamp floydSteinberg a
    let grad = monosampler $ scale (512 :: Grid (Exp Int)) $ circularShape :: DiscreteShader (Exp Float)
    result <- mutableProcess run mydither $ rasterizer grad
    testSaveChan' "out.png" result


orderedDitherTest :: Int -> IO ()
orderedDitherTest a = do
  --let shape = rasterizer $ monosampler $ scaleTo 512 $ linearShape :: Matrix2 Float
  --let shape = rasterizer $ constant 512 0.5 :: Matrix2 Float
  --testSaveChan' "out.png" (bayer a shape)
  forAllChannels "lena.bmp" (bayer a)


--
-- Crosstalk test
--
crosstalkTest :: IO ()
crosstalkTest = do
    (r :: Matrix2 Float, g, b, a) <- testLoadRGBA' "samples/lena.png"
    let r' = fromMatrix A.Clamp r
        g' = fromMatrix A.Clamp g
        b' = fromMatrix A.Clamp b
        zero = LinearShader $ const 0
        id' = LinearShader $ id
        foo = LinearShader $ valueAtX 20 0.00001 (A.lift $ CubicBezier (Point2 0 (0::A.Exp Float)) (Point2 0.25 1.2) (Point2 0.75 1.2) (Point2 1 0))

        (newR, newG, newB) = crosstalk foo id' id' zero zero zero zero zero zero r' g' b'
    print "foo"
    testSaveRGBA' "out.png" (rasterizer newR) (rasterizer newG) (rasterizer newB) a


--
-- cornerPin test
--
-- Try with cornerPinTest 0 (Point2 512 0) 512 (Point2 0 512)
cornerPinTest :: Point2 (Exp Float) -> Point2 (Exp Float) -> Point2 (Exp Float) -> Point2 (Exp Float)-> IO ()
cornerPinTest p1 p2 p3 p4 = do
    let process x = rasterizer $ monosampler $ cornerPin (p1, p2, p3, p4) $ nearest $ fromMatrix (A.Constant 0) x
    forAllChannels "lena.png" process


--
-- Bilateral test
--
bilateralTest :: Exp Float -> Exp Float -> Exp Int -> IO ()
bilateralTest psigma csigma size = do
    let p = pipe A.Clamp
    let spatial = Shader (pure $ variable size) $ \(Point2 x y) ->
            let dst = sqrt . A.fromIntegral $ (x - size `div` 2) * (x - size `div` 2) + (y - size `div` 2) * (y - size `div` 2)
            in apply (gauss psigma) dst
    let domain center neighbour = apply (gauss csigma) (abs $ neighbour - center)
    let process x = rasterizer $ id `p` bilateralStencil (+) spatial domain (+) 0 `p` id $ fromMatrix A.Clamp x
    forAllChannels "lena.png" process

medianTest :: IO ()
medianTest = do
    forAllChannels "lena.bmp" median

realMedianTest :: IO ()
realMedianTest = forAllChannels "lena.png" $ \matrix ->
    let stencil = $(generateGetNthFromTuple 24 49) . $(generateBitonicNetworkTuple 7 7)
    in  M.stencil stencil A.Wrap matrix

maskedTransformationsTest :: IO ()
maskedTransformationsTest = do
    (r, g, b, a) <- testLoadRGBA' "lena.png"
    (m, _, _, _) <- testLoadRGBA' "mask-gradient-cos.png"
    let v = V2 0 50 :: V2 (Exp Int)
        gen = fromMatrix (A.Constant (0 :: Exp Double))
        t :: DiscreteShader (Exp Double) -> DiscreteShader (Exp Double)
        t = S.transform p
        p :: Point2 (Exp Int) -> Point2 (Exp Int)
        p pt = translate (fmap (mult pt) v) pt
        mult pt x = A.round $ (str pt) * A.fromIntegral x
        Shader _ str = gen m
        process :: Matrix2 Double -> Matrix2 Double -- DiscreteShader (Exp Double)
        process = rasterizer . t . gen
        --genR = process r
        --genG = process g
        --genB = process b
        --genA = process a
    testSaveRGBA' "out.png" (process r) (process g) (process b) (process a)

main :: IO ()
main = do
    print "Szatan"
    maskedTransformationsTest
    --gradientsTest
    print "szatan"
