---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------
{-# LANGUAGE FlexibleContexts, NoMonomorphismRestriction #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-}

                        

--import qualified Flowbox.Luna.Samples.HelloWorld       as HelloWorld
--import qualified Flowbox.Luna.Codegen.Hs.FuncGenerator as FG
--import qualified Flowbox.Luna.Codegen.Hs.DefGenerator  as DG
--import qualified Flowbox.Luna.Codegen.Hs.CodeGenerator as CG
--import qualified Flowbox.Luna.Network.Def.DefManager   as DefManager

--import qualified Flowbox.Luna.Codegen.Hs.AST.Function  as Function
--import qualified Flowbox.Luna.Codegen.Hs.AST.Module    as Module

--import           Flowbox.Luna.Codegen.Hs.Cabal.Config    (Config)
--import qualified Flowbox.Luna.Codegen.Hs.Cabal.Config  as Config
--import qualified Flowbox.Luna.Codegen.Hs.Cabal.Section as Section

--import qualified Flowbox.Luna.Data.Graph               as Graph
--import qualified Flowbox.Luna.Lib.Library              as Library

--import qualified Flowbox.Luna.Builder.Builder          as Builder
--import qualified Flowbox.System.UniPath                as UniPath
--import           Flowbox.System.UniPath                  (UniPath)
----------------------

              








--main_inner :: IO ()
--main_inner = do
--    let 
--        parsed = Parser.parse example
--        ast = forceEither parsed
--        out = Gen.genModule ast

--    --print out
--    putStrLn ""
--    putStrLn $ PP.ppShow $ parsed
--    putStrLn "\n-----------------"
--    putStrLn $ PP.ppShow $ out
--    -- putStrLn $ Module.genCode out


------------------------------------


import           Control.Monad.State                  
import           Control.Monad.Writer                 
import           Control.Monad.RWS                    
import           Control.Monad.Trans.Maybe            
import           Control.Monad.Trans.Either           
import           Flowbox.System.Log.Logger            
import qualified Flowbox.System.Log.Logger          as Logger
import qualified Flowbox.System.Log.LogEntry        as LogEntry
import qualified Flowbox.Luna.Codegen.Hs.Generator  as Gen
import qualified Flowbox.Luna.Passes.SSA            as SSA
import qualified Flowbox.Luna.Codegen.Hs.AST.Module as Module
import qualified Flowbox.Luna.Parser                as Parser
import qualified Flowbox.Luna.Codegen.Hs.AST.Expr   as Expr
import qualified Flowbox.Luna.Codegen.Hs.SSAState   as SSAState
import           Flowbox.Luna.Codegen.Hs.SSAState     (SSAState)
import           Debug.Trace                          
import           Data.Either.Utils                    (forceEither)
import qualified Text.Show.Pretty                   as PP
import qualified Data.DList                         as DList

import           Prelude                            hiding (log)
import           System.TimeIt                        


logger = getLogger "Flowbox"


example :: String
example = unlines [ "def f(x):"
                  , "   x=y+1"
                  , "   x=x x"
                  ]

--test :: (Enum a, MonadState a m, MonadWriter [LogEntry.LogEntry] m) => MaybeT m ()
--test = do
--    n <- get
--    logger.debug $ "o nie"
--    --left "err"
--    fail "oh no"
--    put $ succ n
--    return ()

test x = 
    trace (show x) x

testIO x = return $ test x

main :: IO ()
main = do
    a <- testIO 3
    timeIt main_inner

main_inner :: IO ()
main_inner = do
    let 
        parsed = Parser.parse example
        ast = forceEither parsed
        (nast, nstate, nlog) = SSA.run ast
        --(hast, hstate, hlog) = Gen.run nast
    --let y = runRWS (runMaybeT test) 0 0
    putStrLn $ PP.ppShow $ ast
    putStrLn "\n-----------------"
    putStrLn $ PP.ppShow $ nast
    putStrLn $ PP.ppShow $ nstate
    putStrLn $ PP.ppShow $ DList.toList nlog
    putStrLn "\n-----------------"

    --case nast of
    --    Just nast' -> putStrLn $ PP.ppShow $ map Expr.genCode nast'
    --    _          -> return ()
    return ()


