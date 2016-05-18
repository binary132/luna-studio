module UI.Widget.Graphics where

import           Utils.PreludePlus hiding (Item)
import           Utils.Vector

import           Data.JSString.Text        (lazyTextToJSString)
import           GHCJS.Marshal.Pure        (PFromJSVal (..), PToJSVal (..))
import           GHCJS.Types               (JSString, JSVal)

import           Object.UITypes
import           Object.Widget
import qualified Object.Widget.Graphics        as Model
import qualified Reactive.State.UIRegistry as UIRegistry

import           UI.Generic                (whenChanged)
import qualified UI.Generic                as UI
import qualified UI.Registry               as UI
import           UI.Widget                 (UIWidget (..))
import qualified UI.Widget                 as Widget

import           Data.Aeson (encode, toJSON)
import           GHCJS.Marshal (toJSVal)


newtype Graphics = Graphics JSVal deriving (PToJSVal, PFromJSVal)

instance UIWidget Graphics

foreign import javascript safe "new Graphics($1, $2, $3)" create'   :: Int  -> Double -> Double -> IO Graphics
foreign import javascript safe "$1.setItems($2)"          setItems' :: Graphics -> JSVal    -> IO ()

create :: WidgetId -> Model.Graphics -> IO Graphics
create oid model = do
    widget   <- create' oid (model ^. Model.size . x) (model ^. Model.size . y)
    setItems model widget
    UI.setWidgetPosition (model ^. widgetPosition) widget
    return widget

setItems :: Model.Graphics -> Graphics -> IO ()
setItems model widget = do
    items' <- toJSVal $ toJSON $ model ^. Model.items
    setItems' widget items'

instance UIDisplayObject Model.Graphics where
    createUI parentId id model = do
        widget   <- create id model
        parent   <- UI.lookup parentId :: IO Widget.GenericWidget
        UI.register id widget
        Widget.add widget parent

    updateUI id old model = do
        widget <- UI.lookup id :: IO Graphics

        whenChanged old model Model.items $ setItems model widget

instance CompositeWidget Model.Graphics
instance ResizableWidget Model.Graphics where resizeWidget = UI.defaultResize