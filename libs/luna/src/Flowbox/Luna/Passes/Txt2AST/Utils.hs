---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}

module Flowbox.Luna.Passes.Txt2AST.Utils where

import           Flowbox.Prelude
import           Control.Applicative   
import           Text.Parsec         hiding (parse, many, optional, (<|>))

checkIf f msg p = do
	obj <- p
	if (f obj)
		then unexpected (msg ++ show obj)
		else return obj

pl <$*> pr = do 
    n <- pr
    pl n

pl <*$> pr = do 
    n <- pl
    pr n

infixl 5 <?*>
infixl 4 <??>
infixl 4 <**$>
infixl 4 <??$>
p <?*> q = (p <*> q) <|> q
-- p <**> q = (\f g -> g f) <$> p <*> q
p <??> q = p <**> (q <|> return id)
p <**$> q = p <**> (flip (foldr ($)) <$> q)
p <??$> q = p <**> ((flip (foldr ($)) <$> q) <|> return id)


sepBy2  p sep = (:) <$> p <*> try(sep *> sepBy1 p sep)

sepBy'  p sep = sepBy1' p sep <|> return []
sepBy1' p sep = (:) <$> p <*> many (try(sep *> p)) <* optional sep
sepBy2' p sep = (:) <$> p <*> try(sep *> sepBy1' p sep)

liftList p = (:[]) <$> p


