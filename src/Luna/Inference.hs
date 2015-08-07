
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE PartialTypeSignatures #-}

module Luna.Inference where

import Flowbox.Prelude hiding (simple, empty, Indexable, Simple, cons, lookup, index, Wrapped, children)
import Data.Repr

--import qualified Luna.Inference.Type as Type
--import           Luna.Inference.Type
import qualified Data.Map            as Map
import           Data.Map            (Map)
import qualified Data.Text.Lazy      as Text
import           Data.Text.Lazy      (Text)

--import           Luna.Inference.RawData



import           GHC.Prim (Any)
import           GHC.Int
import           Unsafe.Coerce (unsafeCoerce)
import           Data.Convert

--import qualified Data.Graph.Inductive as Graph
--import           FastString (FastString, mkFastString, unpackFS)


import qualified Data.IntMap.Lazy as IntMap
import           Data.IntMap.Lazy (IntMap)
import Data.Typeable       hiding (cast)
import Control.Monad.State hiding (withState, mapM)


import Data.GraphViz.Types.Canonical
import Data.GraphViz.Attributes.Complete hiding (Label)
import qualified Data.GraphViz.Attributes.Complete as GV
import Data.GraphViz.Printing (toDot)
import Data.GraphViz.Commands

import Data.Vector (Vector)
import qualified Data.Vector as Vector
import Data.Vector.Mutable ()
import Data.Maybe (fromJust)

--import Data.Indexable

import Data.Containers
import Data.Containers.Hetero

import System.Process

import qualified Data.Text.AutoBuilder as Text

import Data.Map (Map)
import qualified Data.Map as Map
import Data.Constraint
import Control.Error.Util (hush)
import Data.Convert.Errors (TypeMismatch (TypeMismatch))
import Data.Constraint.Void


type ID = Int


--- === Ctx ===

--data Ctx a = Pure
--           | IO       (Maybe a)
--           | Unknown  (Maybe a)
--           | Ctx Name (Maybe a)
--           deriving (Show)

data Base = Pure
          | IO
          deriving (Show)

--data Ctx = Ctx Name deriving (Show)

data Ctx = KnownCtx Base [Name]
         | UnknownCtx
         deriving (Show)

-- === Literals ===

data Literal = Int Int
             | String Text.AutoBuilder
             deriving (Show)

instance IsString Literal where
    fromString = String . fromString


---- === Ref ===

newtype Ref     h a = Ref { fromRef :: h (a h) }
type    Wrapped m a = m (a (HPtr Int m))
type    Simple    a = a (Ptr Int)

-- utils

class ToMRef t m h a | t -> h a where
    toMRef :: t -> m (Ref h a)

-- instances

instance                             (Monad m) => ToMRef    (Ref h a)  m h a where toMRef = return
instance {-# OVERLAPPABLE #-} (m ~ n, Monad m) => ToMRef (m (Ref h a)) n h a where toMRef = id



-- === Expr ===


type Name = String


type HExpr h = h (Expr h)


data Arg h = Arg { _label :: Maybe Name, _expr :: HExpr h }

-- wszystkie rzeczy nazwane powinny byc w slownikach w jezyku! - czyli datatypy ponizej zostaja,
-- ale mozemy tworzyc np. Var funkcjami, ktore oczekuja konkretnego Stringa!
data Expr h = Var      Name
            | Cons     Name
            | Accessor Name (HExpr h)
            | App      (HExpr h) [Arg h]
            | Lambda
            | RecUpd
            | Unify    (HExpr h) (HExpr h)
            | Case
            | Typed
            -- | Assignment
            -- x | Decons
            | Curry
            -- | Meta
            -- | Tuple
            -- | Grouped
            -- | Decl
            | Lit      Literal
            | Wildcard
            -- | Tuple
            -- | List
            | Unsafe [Name] (HExpr h)

--type Pattern h = HExpr h

deriving instance Show (HExpr h) => Show (Arg h)
deriving instance Show (HExpr h) => Show (Expr h)
--deriving instance Show (HExpr h) => Show (Pattern h)

makeLenses ''Expr
makeLenses ''Arg

class HasAST a ast (h :: * -> *) | a -> ast h where
    ast :: a -> ast h

instance HasAST (Expr h) Expr h where
    ast = id

instance HasAST a ast h => HasAST (Val a) ast h where
    ast (Val _ _ _ a) = ast a

class AST a where
    children :: a h -> [h (a h)]

instance AST Expr where
    children = \case
        Accessor _ base    -> [base]
        App      base args -> base : fmap (view expr) args
        _                  -> []

instance Repr (Expr h) where
    repr = \case
        Var      n   -> "Var "      <> show n
        Cons     n   -> "Cons "     <> show n
        Accessor n _ -> "Accessor " <> show n
        App      {}  -> "App"

instance Repr a => Repr (Val a) where
    repr (Val _ _ _ a) = repr a

--class IsNode n inp | n -> inp where
--    inputs :: n -> [inp]

--instance IsNode (Expr h) (HExpr h) where
--    inputs = \case
--        Accessor _    base -> [base]
--        App      base args -> base : fmap (view arg) args
--        _                  -> []


-- === Vals and Metas ===

data Typex = Typex deriving (Show) -- fixme

data Val a = Val Typex Ctx Meta a deriving (Show)

data Meta = Meta deriving (Show)

class IsMeta m where
    setMeta :: Meta -> m -> m

instance Default Meta where
    def = Meta

instance IsMeta (h (a h)) => IsMeta (Ref h a) where
    setMeta m (Ref a) = Ref $ setMeta m a

instance IsMeta (Val a) where
    setMeta m (Val t c _ a) = Val t c m a

--varMeta :: (RefBuilder el m h Expr, IsMeta (Ref h Expr))  => Name -> Meta -> m (Ref h Expr)
--varMeta n m = setMeta m <$> var n

withMeta m ref = setMeta m <$> toMRef ref

instance Convertible' (Expr h) (Val (Expr h)) where convert' = Val Typex UnknownCtx def
instance Convertible' (Expr h) (Expr h)       where convert' = id



--- === Graph ===

newtype HeteroGraph   = HeteroGraph { __hetReg :: Hetero' Vector } deriving (Show, Default)
newtype HomoGraph   a = HomoGraph   { __homReg :: Vector a       } deriving (Show, Default)

makeLenses ''HeteroGraph
makeLenses ''HomoGraph

instance HasContainer HeteroGraph   (Hetero' Vector) where container = _hetReg
instance HasContainer (HomoGraph a) (Vector a)       where container = _homReg



--- === Graph builders ===

type GraphBuilderT g m = StateT (BldrState g) m
type GraphBuilder  g   = GraphBuilderT g Identity

data BldrState g = BldrState { _orphans :: [Int]
                             , _graph   :: g
                             }

makeClassy ''BldrState


class Monad m => MonadBldrState g m | m -> g where
    getBldrState :: m (BldrState g)
    putBldrState :: (BldrState g) -> m ()

-- utils

withBldrState_ :: MonadBldrState g m => (BldrState g -> BldrState g) -> m ()
withBldrState_ f = withBldrState $ fmap (,()) f


withBldrState :: MonadBldrState g m => (BldrState g -> (BldrState g, a)) -> m a
withBldrState f = do
    bldr <- getBldrState
    let (bldr', out) = f bldr
    putBldrState $ bldr'
    return out

withGraph :: MonadBldrState g m => (g -> (g, a)) -> m a
withGraph = withBldrState . mapOver graph

runGraphBuilderT :: (Monad m, Default g) => GraphBuilderT g m a -> m (a, g)
runGraphBuilderT gb = over _2 (view graph) <$> runStateT gb def

execGraphBuilderT :: (Monad m, Default g) => GraphBuilderT g m a -> m g
execGraphBuilderT gb = snd <$> runGraphBuilderT gb

evalGraphBuilderT :: (Monad m, Default g) => GraphBuilderT g m a -> m a
evalGraphBuilderT gb = fst <$> runGraphBuilderT gb

runGraphBuilder :: Default g => GraphBuilder g a -> (a, g)
runGraphBuilder = runIdentity . runGraphBuilderT

execGraphBuilder :: Default g => GraphBuilder g a -> g
execGraphBuilder = runIdentity . execGraphBuilderT

evalGraphBuilder :: Default g => GraphBuilder g a -> a
evalGraphBuilder = runIdentity . evalGraphBuilderT

-- instances

instance Default g => Default (BldrState g) where
    def = BldrState def def

instance Monad m => MonadBldrState g (GraphBuilderT g m) where
    getBldrState = get
    putBldrState = put





-- === RefBuilder ===

class (Monad m, PtrTarget h a el, Convertible' (a h) el) => RefBuilder el m h a where
    mkRef :: el -> m (Ref h a)


instance (Convertible idx (h (a h)), HasContainer g cont, Appendable cont idx el, Monad m, PtrTarget h a el, Convertible' (a h) el)
      => RefBuilder el (GraphBuilderT g m) h a where
    mkRef = fmap (Ref . convert) . withGraph . append

-- utils

mkASTRef :: (Convertible' (a h) el, RefBuilder el m h a) => a h -> m (Ref h a)
mkASTRef = mkRef . convert'

mkASTRefMeta m = mkRef . setMeta m . convert'

-- === Function ===

data Function body = Function { _body :: body } deriving (Show)

type FunctionGraph = Function (HomoGraph (Wrapped Val Expr))

makeLenses ''Function

-- utils

runFunctionBuilderT :: (Monad m, Default g) => GraphBuilderT g m a -> m (Function g)
runFunctionBuilderT gb = do
    (a, g) <- runGraphBuilderT gb
    return $ Function g

runFunctionBuilder :: Default g => GraphBuilder g a -> Function g
runFunctionBuilder = runIdentity . runFunctionBuilderT

-- instances

instance HasContainer body c => HasContainer (Function body) c where
    container = body . container


toRawMRef :: (Functor m, ToMRef t m h a) => t -> m (h (a h))
toRawMRef = fmap fromRef . toMRef

var :: RefBuilder el m h Expr => Name -> m (Ref h Expr)
var = mkASTRef . Var

metaVar :: (RefBuilder el m h Expr, IsMeta el) => Name -> Meta -> m (Ref h Expr)
metaVar n m = mkASTRefMeta m $ Var n

accessor :: (RefBuilder el m h Expr, ToMRef t m h Expr) => Name -> t -> m (Ref h Expr)
accessor n r = mkASTRef . Accessor n =<< toRawMRef r

app :: (RefBuilder el m h Expr, ToMRef t m h Expr) => t -> [ArgRef m h Expr] -> m (Ref h Expr)
app base args = do
    baseRef <- toRawMRef base
    argRefs <- mapM readArgRef args
    mkASTRef $ App baseRef argRefs
    where readArgRef (ArgRef n mref) = Arg n . fromRef <$> mref

--data Arg h = Arg { _label :: Maybe Name, _expr :: HExpr h }

--class Named a where
--    named :: Name -> a -> a

--instance Named (ArgRef h a) where
--    named n (ArgRef _ ref) = ArgRef (Just n) ref

data ArgRef m h a = ArgRef (Maybe Name) (m (Ref h a))

arg = ArgRef Nothing . toMRef



f :: FunctionGraph
f = runFunctionBuilder $ do
    a <- metaVar "a" Meta
    x <- var "x" @. "foo"
    y <- x @$ [arg a]

    return ()


g1 :: HomoGraph (Wrapped Val Expr)
--g1 :: HomoGraph (Simple Expr)
g1 = execGraphBuilder $ do
    a <- var "a"
    x <- var "x" @. "foo"
    y <- x @$ [arg a]
    --return a
    return ()


(@.) = flip accessor
(@$) = app

--g1 :: HomoGraph _
--g1 = runIdentity $ runGraphBuilder $ do
--    a <- var4
----    --a    <- ref "foo" $ var "a"
----    --b    <- ref "bar" $ accessor "foo" (var "b")
----    --c    <- ref "baz" $ match (var "a") (var "b")
----    return ()
----    --mod  <- var "Main"
----    --foo  <- a    @.  "foo"
----    --b    <- foo  @$$ [a]
----    --bar  <- mod  @.  "bar"
----    --c    <- bar  @$$ [b]
----    --plus <- mod  @.  "plus"
----    --out  <- plus @$$ [c, a]
--    return ()

main = do
    print f
    print $ elems f
    let gv = toGraphViz (view body f)
    runGraphviz gv Png "/tmp/out.png"
    createProcess $ shell "open /tmp/out.png"
    --let m = fck & view body
    --    g = fck & view fgraph
    --    Just (Ref p1) = Map.index "foo" m
    --    r = g ^. reg
    --    e = unsafeGet p1 r

    --print fck
    --print e
    print "end"


    --c = mempty :: Hetero' Vector

    --(c', p') = append ('a') c -- :: (Hetero' Vector, Ptr Int Char)
    --c'' = prepend_ 'o' c'

    --main = do
    --    print "end"
    --    print (c', p')
    --    print c''
    --    print $ uncheckedIndex (Ptr 0 :: Ptr Int Int) c'

--main = do
--    let g  = runNodeBuilder g1
--        gv = toGraphViz g
--    print g
--    --print $ toDot gv
--    runGraphviz gv Png "/tmp/out.png"
--    createProcess $ shell "open /tmp/out.png"
--    print "end"

toGraphViz :: HomoGraph (Wrapped Val Expr) -> DotGraph Int
toGraphViz g = DotGraph { strictGraph     = False
                        , directedGraph   = True
                        , graphID         = Nothing
                        , graphStatements = DotStmts { attrStmts = []
                                                     , subGraphs = []
                                                     , nodeStmts = nodeStmts
                                                     , edgeStmts = edgeStmts
                                                     }
                        }
    where nodes           = elems g
          nodeIds         = indexes g
          nodeLabels      = fmap repr nodes
          labeledNode s a = DotNode a [GV.Label . StrLabel $ fromString s]
          nodeStmts       = fmap (uncurry labeledNode) $ zip nodeLabels nodeIds
          nodeInEdges   n = zip3 [0..] (fmap ptrIdx . children . ast $ unsafeIndex n g) (repeat n)
          inEdges         = concat $ fmap nodeInEdges nodeIds
          mkEdge  (n,a,b) = DotEdge a b [GV.Label . StrLabel $ fromString $ show n]
          edgeStmts       = fmap mkEdge inEdges

----g1 :: RefBuilder Expr m => m ()
--g1 = do
--    a    <- ref "a" $ var "a"
--    mod  <- ref "mod"  $ cons "Mod"
--    foo  <- ref "foo"  $ a    @. "foo"
--    b    <- ref "b"    $ foo  @$ [arg a]
--    bar  <- ref "bar"  $ mod  @. "bar"
--    c    <- ref "c"    $ bar  @$ [arg b]
--    plus <- ref "plus" $ mod  @. "plus"
--    out  <- ref "out"  $ plus @$ [arg c, arg a]
--    return ()


--class ToMRef t where
--    toMRef :: Monad m => t m a -> m (Ref m a)

--instance ToMRef RefCons where toMRef = runRefCons
--instance ToMRef Ref      where toMRef = return




--instance MonadBldrState c (State (BldrState c)) where
--    getBldrState = get
--    putBldrState = put



--runNodeBuilder :: Builder (Vector Hidden) a -> Graph (Vector Hidden)
--runNodeBuilder = view graph . flip execState def


----g2 :: Graph (Vector Hidden)
----g2 = runNodeBuilder $ do
----    a    <- var "a"
----    mod  <- var "Main"
----    foo  <- a    @.  "foo"
----    b    <- foo  @$$ [a]
----    bar  <- mod  @.  "bar"
----    c    <- bar  @$$ [b]
----    plus <- mod  @.  "plus"
----    out  <- plus @$$ [c, a]
----    return ()

----data Arg h = Arg { _label :: Maybe Name, _val :: HExpr h }


----class Arg2 a where
----    arg2 :: a -> b

----instance Arg2 Name -> (a -> Arg a)

--class Named a where
--    named :: Name -> a -> a

--instance Named (ArgRef m a) where
--    named n (ArgRef _ ref) = ArgRef (Just n) ref

--data ArgRef m a = ArgRef (Maybe Name) (m (Ref m a))

--arg = ArgRef Nothing . toMRef

----data Node = Node


--g2 :: (ConvertibleM Expr a, Monad m, RefBuilder a m) => m (Ref m a)
--g2 = do
--    a <- ref_ $ var2 "a"
--    return a

----g1 :: RefBuilder Expr m => m ()
--g1 = do
--    a    <- ref "a" $ var "a"
--    mod  <- ref "mod"  $ cons "Mod"
--    foo  <- ref "foo"  $ a    @. "foo"
--    b    <- ref "b"    $ foo  @$ [arg a]
--    bar  <- ref "bar"  $ mod  @. "bar"
--    c    <- ref "c"    $ bar  @$ [arg b]
--    plus <- ref "plus" $ mod  @. "plus"
--    out  <- ref "out"  $ plus @$ [arg c, arg a]
--    return ()

----dorobic budowanie liniowe, nie grafowe
----zmienne powinny odnosic sie do siebie jako debrouigle - moze warto parametryzowac Name, tak y mozna bylo wsadzic tam ID debrouiglowe?

--(@.)  = access
--(@$)  = app

--main = do
--    let g  = runNodeBuilder g1
--        gv = toGraphViz g
--    print g
--    --print $ toDot gv
--    runGraphviz gv Png "/tmp/out.png"
--    createProcess $ shell "open /tmp/out.png"
--    print "end"


--data Label a e = Label a e
--type Labeled l a = Label l (a (Label l))
--type LExpr l = Labeled l Expr

--newtype Simple a = Simple a deriving (Show)
--type SExpr = Simple (Expr Simple)

----newtype Mu f = Mu (f (Mu f))


----inputs' :: Graph (Vector Hidden) -> ID -> [Ptr Int (Expr (Ptr Int))]

--toGraphViz :: Graph (Vector Hidden) -> DotGraph Int
--toGraphViz g = DotGraph { strictGraph     = False
--                        , directedGraph   = True
--                        , graphID         = Nothing
--                        , graphStatements = DotStmts { attrStmts = []
--                                                     , subGraphs = []
--                                                     , nodeStmts = nodeStmts
--                                                     , edgeStmts = edgeStmts
--                                                     }
--                        }
--    where ns              = g ^. nodes
--          nodeIds         = [0 .. Vector.length ns - 1] :: [Int]
--          elems           = fmap ((Vector.!) ns) nodeIds
--          nodeLabels      = fmap repr elems
--          labeledNode s a = DotNode a [GV.Label . StrLabel $ fromString s]
--          nodeStmts       = fmap (uncurry labeledNode) $ zip nodeLabels nodeIds
--          nodeInEdges   n = zip3 [0..] (fmap fromPtr $ inputs' g n) (repeat n)
--          inEdges         = concat $ fmap nodeInEdges nodeIds
--          mkEdge  (n,a,b) = DotEdge a b [GV.Label . StrLabel $ fromString $ show n]
--          edgeStmts       = fmap mkEdge inEdges





