    {-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}

module Object.Widget where

import           Utils.PreludePlus
import           Utils.Vector
import           Utils.CtxDynamic
import           Event.Mouse    (MousePosition)
import           Object.UITypes
import qualified Event.Keyboard as Keyboard
import           Reactive.Plugins.Core.Action.State.Camera     (Camera)
import qualified Reactive.Plugins.Core.Action.State.Camera     as Camera
import           Reactive.Plugins.Core.Action.Commands.Command (Command)
import qualified JS.Camera as JSCamera
import           Object.UITypes

type DisplayObject = CtxDynamic DisplayObjectClass

showObject :: DisplayObject -> String
showObject = withCtxDynamic show

type DisplayObjectCtx a =   ( Show a
                            , Typeable a
                            , IsDisplayObject a
                            , HandlesMouseMove a
                            , HandlesMousePressed a
                            , HandlesMouseReleased a
                            , HandlesMouseOver a
                            , HandlesMouseOut a
                            , Clickable a
                            , DblClickable a
                            , Focusable a
                            , Draggable a
                            , HandlesKeyUp a
                            , HandlesKeyDown a
                            , HandlesKeyPressed a
                            )

class    DisplayObjectCtx a => DisplayObjectClass a
instance DisplayObjectCtx a => DisplayObjectClass a

class DisplayObjectClass a => DisplayObjectContainer a


data WidgetFile a b = WidgetFile { _objectId :: WidgetId
                                 , _widget   :: b
                                 , _parent   :: Maybe WidgetId
                                 , _children :: [WidgetId]
                                 , _handlers :: UIHandlers a
                                 }

type WidgetUIUpdate = IO ()
type WidgetUpdate   = (WidgetUIUpdate, DisplayObject)

class IsDisplayObject a where
    objectPosition :: a -> Vector2 Double
    objectSize     :: a -> Vector2 Double

instance IsDisplayObject DisplayObject where
    objectPosition (CtxDynamic _ a) = objectPosition a
    objectSize     (CtxDynamic _ a) = objectSize     a

type Position = Vector2 Double

class HandlesMouseMove     a where onMouseMove     :: MouseButton -> Position -> WidgetFile s DisplayObject -> a -> WidgetUpdate
class HandlesMousePressed  a where onMousePress    :: MouseButton -> Position -> WidgetFile s DisplayObject -> a -> WidgetUpdate
class HandlesMouseReleased a where onMouseRelease  :: MouseButton -> Position -> WidgetFile s DisplayObject -> a -> WidgetUpdate
class HandlesMouseOver     a where onMouseOver     ::                            WidgetFile s DisplayObject -> a -> WidgetUpdate
class HandlesMouseOut      a where onMouseOut      ::                            WidgetFile s DisplayObject -> a -> WidgetUpdate
class Clickable            a where onClick         ::                Position -> WidgetFile s DisplayObject -> a -> WidgetUpdate
class DblClickable         a where onDblClick      ::                Position -> WidgetFile s DisplayObject -> a -> WidgetUpdate
class Focusable            a where mayFocus        :: MouseButton -> Position -> WidgetFile s DisplayObject -> a -> Bool
class Draggable            a where mayDrag         :: MouseButton -> Position -> WidgetFile s DisplayObject -> a -> Bool
                                   onDragStart     ::               DragState -> WidgetFile s DisplayObject -> a -> WidgetUpdate
                                   onDragMove      ::               DragState -> WidgetFile s DisplayObject -> a -> WidgetUpdate
                                   onDragEnd       ::               DragState -> WidgetFile s DisplayObject -> a -> WidgetUpdate

class HandlesKeyUp         a where onKeyUp         :: Char                    -> WidgetFile s DisplayObject -> a -> WidgetUpdate
class HandlesKeyDown       a where onKeyDown       :: Char                    -> WidgetFile s DisplayObject -> a -> WidgetUpdate
class HandlesKeyPressed    a where onKeyPressed    :: Char                    -> WidgetFile s DisplayObject -> a -> WidgetUpdate

instance {-# OVERLAPPABLE #-} DisplayObjectClass a => HandlesMouseMove     a where onMouseMove       _ _ = noUpdate
instance {-# OVERLAPPABLE #-} DisplayObjectClass a => HandlesMousePressed  a where onMousePress      _ _ = noUpdate
instance {-# OVERLAPPABLE #-} DisplayObjectClass a => HandlesMouseReleased a where onMouseRelease    _ _ = noUpdate
instance {-# OVERLAPPABLE #-} DisplayObjectClass a => HandlesMouseOver     a where onMouseOver           = noUpdate
instance {-# OVERLAPPABLE #-} DisplayObjectClass a => HandlesMouseOut      a where onMouseOut            = noUpdate
instance {-# OVERLAPPABLE #-} DisplayObjectClass a => Clickable            a where onClick             _ = noUpdate
instance {-# OVERLAPPABLE #-} DisplayObjectClass a => DblClickable         a where onDblClick          _ = noUpdate
instance {-# OVERLAPPABLE #-} DisplayObjectClass a => Focusable            a where mayFocus      _ _ _ _ = False
instance {-# OVERLAPPABLE #-} DisplayObjectClass a => Draggable            a where mayDrag       _ _ _ _ = False
                                                                                   onDragStart         _ = noUpdate
                                                                                   onDragMove          _ = noUpdate
                                                                                   onDragEnd           _ = noUpdate
instance {-# OVERLAPPABLE #-} DisplayObjectClass a => HandlesKeyUp         a where onKeyUp             _ = noUpdate
instance {-# OVERLAPPABLE #-} DisplayObjectClass a => HandlesKeyDown       a where onKeyDown           _ = noUpdate
instance {-# OVERLAPPABLE #-} DisplayObjectClass a => HandlesKeyPressed    a where onKeyPressed        _ = noUpdate

instance HandlesMouseMove     DisplayObject where onMouseMove     mb mp wf (CtxDynamic _ a) = onMouseMove     mb mp wf a
instance HandlesMousePressed  DisplayObject where onMousePress    mb mp wf (CtxDynamic _ a) = onMousePress    mb mp wf a
instance HandlesMouseReleased DisplayObject where onMouseRelease  mb mp wf (CtxDynamic _ a) = onMouseRelease  mb mp wf a
instance HandlesMouseOver     DisplayObject where onMouseOver           wf (CtxDynamic _ a) = onMouseOver           wf a
instance HandlesMouseOut      DisplayObject where onMouseOut            wf (CtxDynamic _ a) = onMouseOut            wf a
instance Clickable            DisplayObject where onClick            mp wf (CtxDynamic _ a) = onClick            mp wf a
instance DblClickable         DisplayObject where onDblClick         mp wf (CtxDynamic _ a) = onDblClick         mp wf a
instance Focusable            DisplayObject where mayFocus        mb mr wf (CtxDynamic _ a) = mayFocus        mb mr wf a
instance Draggable            DisplayObject where mayDrag         mb mr wf (CtxDynamic _ a) = mayDrag         mb mr wf a
                                                  onDragStart        ds wf (CtxDynamic _ a) = onDragStart        ds wf a
                                                  onDragMove         ds wf (CtxDynamic _ a) = onDragMove         ds wf a
                                                  onDragEnd          ds wf (CtxDynamic _ a) = onDragEnd          ds wf a
instance HandlesKeyUp         DisplayObject where onKeyUp            ch wf (CtxDynamic _ a) = onKeyUp            ch wf a
instance HandlesKeyDown       DisplayObject where onKeyDown          ch wf (CtxDynamic _ a) = onKeyDown          ch wf a
instance HandlesKeyPressed    DisplayObject where onKeyPressed       ch wf (CtxDynamic _ a) = onKeyPressed       ch wf a

noUIUpdate :: WidgetUIUpdate
noUIUpdate = return ()

noUpdate :: DisplayObjectClass a => WidgetFile s DisplayObject -> a -> WidgetUpdate
noUpdate _ w = (noUIUpdate, toCtxDynamic w)

data DragState = DragState { _widgetId       :: WidgetId
                           , _widgetMatrix   :: [Double]
                           , _scene          :: SceneType
                           , _button         :: MouseButton
                           , _keyMods        :: Keyboard.KeyMods
                           , _startPos       :: Vector2 Double
                           , _previousPos    :: Vector2 Double
                           , _currentPos     :: Vector2 Double
                           } deriving (Show, Eq)

sceneToLocal :: Vector2 Double -> [Double] -> Vector2 Double
sceneToLocal (Vector2 x y) [ aa, ab, ac, ad
                           , ba, bb, bc, bd
                           , ca, cb, cc, cd
                           , da, db, dc, dd
                           ] = Vector2 x' y' where
                               x' = aa * x + ba * y + da
                               y' = ab * x + bb * y + db

screenToLocal :: JSCamera.Camera -> Vector2 Int -> [Double]  -> Vector2 Double
screenToLocal cam mousePos widgetMatrix = sceneToLocal workspacePos widgetMatrix where
    workspacePos = JSCamera.screenToWorkspace cam mousePos

type MouseMoveHandler     s = MouseButton -> Position -> Command s ()
type MousePressedHandler  s = MouseButton -> Position -> Command s ()
type MouseReleasedHandler s = MouseButton -> Position -> Command s ()
type MouseOverHandler     s =                            Command s ()
type MouseOutHandler      s =                            Command s ()
type ClickHandler         s =                Position -> Command s ()
type DblClickHandler      s =                Position -> Command s ()
type KeyUpHandler         s = Char                    -> Command s ()
type KeyDownHandler       s = Char                    -> Command s ()
type KeyPressedHandler    s = Char                    -> Command s ()


data UIHandlers a  = UIHandlers { _mouseMove     :: [MouseMoveHandler      a]
                                , _mousePressed  :: [MousePressedHandler   a]
                                , _mouseReleased :: [MouseReleasedHandler  a]
                                , _mouseOver     :: [MouseOverHandler      a]
                                , _mouseOut      :: [MouseOutHandler       a]
                                , _click         :: [ClickHandler          a]
                                , _dblClick      :: [DblClickHandler       a]
                                , _keyUp         :: [KeyUpHandler          a]
                                , _keyDown       :: [KeyDownHandler        a]
                                , _keyPressed    :: [KeyPressedHandler     a]
                                }
makeLenses ''DragState

makeLenses ''UIHandlers

makeLenses ''WidgetFile
