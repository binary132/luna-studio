---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE CPP                 #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ViewPatterns        #-}

module Utils (
  module Utils,
  run
) where

import Flowbox.Graphics.Color.Color
import Flowbox.Graphics.Image.IO.ImageMagick (loadImage, saveImage)
import Flowbox.Graphics.Shader.Matrix
import Flowbox.Graphics.Shader.Rasterizer
import Flowbox.Graphics.Shader.Sampler
import Flowbox.Graphics.Utils.Utils
import Flowbox.Math.Matrix                   as M
import Flowbox.Prelude                       as P hiding (pre)

import qualified Codec.Picture.Png        as Juicy
import qualified Codec.Picture.Types      as Juicy
import qualified Data.Array.Accelerate    as A
import           Data.Array.Accelerate.IO

#ifdef ACCELERATE_CUDA_BACKEND
import Data.Array.Accelerate.CUDA (run)
#else
import Data.Array.Accelerate.Interpreter (run)
#endif

import           Data.List.Split      (chunksOf)
import qualified Data.Vector.Storable as SV
import           Text.Printf



type IOLoadBackend a = FilePath -> IO (Either a (A.Array A.DIM2 RGBA32))
type IOSaveBackend   = FilePath -> A.Array A.DIM2 RGBA32 -> IO ()

testColor :: (RGB (A.Exp Float) -> RGB (A.Exp Float))
          -> FilePath
          -> FilePath
          -> IO ()
testColor f input output = do
    (r, g, b, a) <- testLoadRGBA' input
    let rgb  = M.zipWith3 (\x y z -> A.lift (RGB x y z)) r g b
        rgb' = M.map (\x -> A.lift $ f (A.unlift x :: RGB (Exp Float))) rgb
        (r', g', b') = M.unzip3 $ M.map (\(A.unlift -> RGB x y z :: RGB (Exp Float)) -> A.lift (x, y, z)) rgb'
    testSaveRGBA' output r' g' b' a

testFunction :: (A.Exp Float -> A.Exp Float)
             -> FilePath
             -> FilePath
             -> IO ()
testFunction f input output = do
    img <- map4 (fromMatrix A.Wrap) <$> testLoadRGBA' input
    let (r', g', b', a') = img & each %~ (rasterizer . (fmap f) . monosampler)
    testSaveRGBA' output r' g' b' a'

printMat :: forall a . (Elt a, Show a, PrintfArg a) => Matrix2 a -> IO ()
printMat mat = mapM_ printRow mat2d
    where computed = compute' run mat
          mat2d = chunksOf w $ (A.toList computed :: [a])
          Z :. _ :. w = A.arrayShape computed
          printRow row = do
              mapM_ (\a -> printf "%6.3f\t" a :: IO ()) row
              printf "\n"


testLoadRGBA :: (Show a, Elt b, IsFloating b) => IOLoadBackend a -> FilePath -> IO (Matrix2 b, Matrix2 b, Matrix2 b, Matrix2 b)
testLoadRGBA backend filename = do
    file <- backend filename
    case file of
        Right mat -> return $ M.unzip4 $ M.map (convert . unpackRGBA32) (Raw mat)
        Left e -> error $ "Unable to load file: " P.++ show e
    where convert t = let (r, g, b, a) = A.unlift t :: (Exp A.Word8, Exp A.Word8, Exp A.Word8, Exp A.Word8)
                      in A.lift (A.fromIntegral r / 255, A.fromIntegral g / 255, A.fromIntegral b / 255, A.fromIntegral a / 255)

testLoadRGBA' :: (Elt b, IsFloating b) => FilePath -> IO (Matrix2 b, Matrix2 b, Matrix2 b, Matrix2 b)
testLoadRGBA' = testLoadRGBA loadImage

loadRGB :: (Elt b, IsFloating b) => FilePath -> IO (Matrix2 (RGB b))
loadRGB filename = do
    file <- loadImage filename
    case file of
        Left e -> error $ "Unable to load file: " P.++ show e
        Right mat -> return $ M.map (\(A.unlift -> (r, g, b) :: (Exp b, Exp b, Exp b)) -> A.lift $ RGB r g b :: Exp (RGB b)) $ M.map (convert . unpackRGBA32) (Raw mat)
    where convert t = let (r, g, b, _) = A.unlift t :: (Exp A.Word8, Exp A.Word8, Exp A.Word8, Exp A.Word8)
                      in A.lift (A.fromIntegral r / 255, A.fromIntegral g / 255, A.fromIntegral b / 255)


testSaveRGBA :: (Elt a, IsFloating a) => IOSaveBackend -> FilePath -> Matrix2 a -> Matrix2 a -> Matrix2 a -> Matrix2 a -> IO ()
testSaveRGBA backend filename r g b a = backend filename $ compute' run $ M.map packRGBA32 $ zip4 (conv r) (conv g) (conv b) (conv a)
    where conv = M.map (A.truncate . (* 255.0) . clamp' 0 1)

testSaveRGBA' :: (Elt a, IsFloating a) => FilePath -> Matrix2 a -> Matrix2 a -> Matrix2 a -> Matrix2 a -> IO ()
testSaveRGBA' = testSaveRGBA saveImage

testSaveRGBA'' :: (Elt a, IsFloating a) => FilePath -> Matrix2 a -> Matrix2 a -> Matrix2 a -> Matrix2 a -> IO ()
testSaveRGBA'' = testSaveRGBA saveImageJuicy

saveImageJuicy :: IOSaveBackend
saveImageJuicy file matrix = do
    let ((), vec) = toVectors matrix
        A.Z A.:. h A.:. w = A.arrayShape matrix
    Juicy.writePng file $ (Juicy.Image w h (SV.unsafeCast vec) :: Juicy.Image Juicy.PixelRGBA8)


testSaveChan :: forall a . (Elt a, IsFloating a) => IOSaveBackend -> FilePath -> Matrix2 a -> IO ()
testSaveChan backend filename pre = backend filename $ compute' run $ M.map packRGBA32 output
    where output = M.map conv pre
          conv (A.truncate . (* 255.0) . clamp' 0 1 -> x) = A.lift (x, x, x, 255 :: A.Word8)

testSaveChan' :: (Elt a, IsFloating a) => FilePath -> Matrix2 a -> IO ()
testSaveChan' = testSaveChan saveImage


map4 :: (a -> b) -> (a, a, a, a) -> (b, b, b, b)
map4 f (a, b, c, d) = (f a, f b, f c, f d)