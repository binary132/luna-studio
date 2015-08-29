module ThreeJS.Geometry where

import           Utils.PreludePlus

import           GHCJS.Foreign
import           GHCJS.Types      ( JSRef, JSString )
import           ThreeJS.Types



foreign import javascript unsafe "$1.applyMatrix( new THREE.Matrix4().makeTranslation($2, $3, $4) )"
    translateJS :: JSRef a -> Double -> Double -> Double -> IO ()

translate :: (Geometry a) => JSRef a -> Double -> Double -> Double -> IO ()
translate = translateJS

foreign import javascript unsafe "$1.applyMatrix( new THREE.Matrix4().makeScale ($2, $3, $4) )"
    scaleJS :: JSRef a -> Double -> Double -> Double -> IO ()

scale :: (Geometry a) => JSRef a -> Double -> IO ()
scale g s = scaleJS g s s 1.0
