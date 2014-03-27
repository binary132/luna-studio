-----------------------------------------------------------------------------
-- |
-- Module      :  Distribution.Client.World
-- Copyright   :  (c) Peter Robinson 2009
-- License     :  BSD-like
--
-- Maintainer  :  thaldyron@gmail.com
-- Stability   :  provisional
-- Portability :  portable
--
-- Interface to the world-file that contains a list of explicitly
-- requested packages. Meant to be imported qualified.
--
-- A world file entry stores the package-name, package-version, and
-- user flags.
-- For example, the entry generated by
-- # cabal install stm-io-hooks --flags="-debug"
-- looks like this:
-- # stm-io-hooks -any --flags="-debug"
-- To rebuild/upgrade the packages in world (e.g. when updating the compiler)
-- use
-- # cabal install world
--
-----------------------------------------------------------------------------
module Distribution.Client.World (
    WorldPkgInfo(..),
    insert,
    delete,
    getContents,
  ) where

import Distribution.Package
         ( Dependency(..) )
import Distribution.PackageDescription
         ( FlagAssignment, FlagName(FlagName) )
import Distribution.Verbosity
         ( Verbosity )
import Distribution.Simple.Utils
         ( die, info, chattyTry, writeFileAtomic )
import Distribution.Text
         ( Text(..), display, simpleParse )
import qualified Distribution.Compat.ReadP as Parse
import Distribution.Compat.Exception ( catchIO )
import qualified Text.PrettyPrint as Disp
import Text.PrettyPrint ( (<>), (<+>) )


import Data.Char as Char

import Data.List
         ( unionBy, deleteFirstsBy, nubBy )
import Data.Maybe
         ( isJust, fromJust )
import System.IO.Error
         ( isDoesNotExistError )
import qualified Data.ByteString.Lazy.Char8 as B
import Prelude hiding (getContents)


data WorldPkgInfo = WorldPkgInfo Dependency FlagAssignment
  deriving (Show,Eq)

-- | Adds packages to the world file; creates the file if it doesn't
-- exist yet. Version constraints and flag assignments for a package are
-- updated if already present. IO errors are non-fatal.
insert :: Verbosity -> FilePath -> [WorldPkgInfo] -> IO ()
insert = modifyWorld $ unionBy equalUDep

-- | Removes packages from the world file.
-- Note: Currently unused as there is no mechanism in Cabal (yet) to
-- handle uninstalls. IO errors are non-fatal.
delete :: Verbosity -> FilePath -> [WorldPkgInfo] -> IO ()
delete = modifyWorld $ flip (deleteFirstsBy equalUDep)

-- | WorldPkgInfo values are considered equal if they refer to
-- the same package, i.e., we don't care about differing versions or flags.
equalUDep :: WorldPkgInfo -> WorldPkgInfo -> Bool
equalUDep (WorldPkgInfo (Dependency pkg1 _) _)
          (WorldPkgInfo (Dependency pkg2 _) _) = pkg1 == pkg2

-- | Modifies the world file by applying an update-function ('unionBy'
-- for 'insert', 'deleteFirstsBy' for 'delete') to the given list of
-- packages. IO errors are considered non-fatal.
modifyWorld :: ([WorldPkgInfo] -> [WorldPkgInfo]
                -> [WorldPkgInfo])
                        -- ^ Function that defines how
                        -- the list of user packages are merged with
                        -- existing world packages.
            -> Verbosity
            -> FilePath               -- ^ Location of the world file
            -> [WorldPkgInfo] -- ^ list of user supplied packages
            -> IO ()
modifyWorld _ _         _     []   = return ()
modifyWorld f verbosity world pkgs =
  chattyTry "Error while updating world-file. " $ do
    pkgsOldWorld <- getContents world
    -- Filter out packages that are not in the world file:
    let pkgsNewWorld = nubBy equalUDep $ f pkgs pkgsOldWorld
    -- 'Dependency' is not an Ord instance, so we need to check for
    -- equivalence the awkward way:
    if not (all (`elem` pkgsOldWorld) pkgsNewWorld &&
            all (`elem` pkgsNewWorld) pkgsOldWorld)
      then do
        info verbosity "Updating world file..."
        writeFileAtomic world . B.pack $ unlines
            [ (display pkg) | pkg <- pkgsNewWorld]
      else
        info verbosity "World file is already up to date."


-- | Returns the content of the world file as a list
getContents :: FilePath -> IO [WorldPkgInfo]
getContents world = do
  content <- safelyReadFile world
  let result = map simpleParse (lines $ B.unpack content)
  if all isJust result
    then return $ map fromJust result
    else die "Could not parse world file."
  where
  safelyReadFile :: FilePath -> IO B.ByteString
  safelyReadFile file = B.readFile file `catchIO` handler
    where
      handler e | isDoesNotExistError e = return B.empty
                | otherwise             = ioError e


instance Text WorldPkgInfo where
  disp (WorldPkgInfo dep flags) = disp dep <+> dispFlags flags
    where
      dispFlags [] = Disp.empty
      dispFlags fs = Disp.text "--flags="
                  <> Disp.doubleQuotes (flagAssToDoc fs)
      flagAssToDoc = foldr (\(FlagName fname,val) flagAssDoc ->
                             (if not val then Disp.char '-'
                                         else Disp.empty)
                             Disp.<> Disp.text fname
                             Disp.<+> flagAssDoc)
                           Disp.empty
  parse = do
      dep <- parse
      Parse.skipSpaces
      flagAss <- Parse.option [] parseFlagAssignment
      return $ WorldPkgInfo dep flagAss
    where
      parseFlagAssignment :: Parse.ReadP r FlagAssignment
      parseFlagAssignment = do
          _ <- Parse.string "--flags"
          Parse.skipSpaces
          _ <- Parse.char '='
          Parse.skipSpaces
          inDoubleQuotes $ Parse.many1 flag
        where
          inDoubleQuotes :: Parse.ReadP r a -> Parse.ReadP r a
          inDoubleQuotes = Parse.between (Parse.char '"') (Parse.char '"')

          flag = do
            Parse.skipSpaces
            val <- negative Parse.+++ positive
            name <- ident
            Parse.skipSpaces
            return (FlagName name,val)
          negative = do
            _ <- Parse.char '-'
            return False
          positive = return True

          ident :: Parse.ReadP r String
          ident = do
            -- First character must be a letter/digit to avoid flags
            -- like "+-debug":
            c  <- Parse.satisfy Char.isAlphaNum
            cs <- Parse.munch (\ch -> Char.isAlphaNum ch || ch == '_'
                                                         || ch == '-')
            return (c:cs)
