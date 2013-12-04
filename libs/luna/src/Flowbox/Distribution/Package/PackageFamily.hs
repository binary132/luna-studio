---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TemplateHaskell #-}

module Flowbox.Distribution.Package.PackageFamily where

import           GHC.Generics                              
import           Data.Aeson                                
import qualified Data.Aeson.TH                           as JSON
import           Data.Default                              (Default, def)
import           Data.List                                 (sortBy)
import           Data.Function                             (on)

import           Flowbox.Prelude                         hiding (id)
import           Flowbox.Data.List                         (foldri)
import qualified Flowbox.Data.Version                    as Version
import           Flowbox.Data.Version                      (Version)
import qualified Flowbox.Distribution.Package.Dependency as Dependency
import           Flowbox.Distribution.Package.Dependency   (Dependency)
import           Flowbox.Distribution.License              (License)
import qualified Flowbox.Distribution.Package.Package    as Package
import           Flowbox.Distribution.Package.Package      (Package)



data PackageFamily = PackageFamily { _name              :: String
                                   , _availableVersions :: [Version]
                                   , _installedVersions :: [Version]
                                   , _synopsis          :: String
                                   , _description       :: String
                                   , _homepage          :: String
                                   , _url               :: String
                                   , _bugReports        :: String
                                   , _license           :: License
                                   , _licenseFile       :: Maybe String
                                   , _authors           :: [String]
                                   , _maintainers       :: [String]
                                   , _copyright         :: String
                                   , _tags              :: [String]
                                   , _dependencies      :: [Dependency]
                                   } deriving (Show, Generic)

makeLenses (''PackageFamily)


mk :: ([Package], [Package]) -> PackageFamily
mk (srcPkgs, instPkgs) = foldri registerInstalled instPkgs
                       $ foldri update (sortBy (compare `on` (view $ Package.id . Package.version)) srcPkgs) def


update :: Package -> PackageFamily -> PackageFamily
update pkg pkgF = pkgF & name              .~ (pkg ^. Package.id ^. Package.name)
                       & availableVersions %~ (pkg ^. Package.id ^. Package.version :)
                       & synopsis          .~ (pkg ^. Package.synopsis)
                       & description       .~ (pkg ^. Package.description)
                       & homepage          .~ (pkg ^. Package.homepage)
                       & url               .~ (pkg ^. Package.url)
                       & bugReports        .~ (pkg ^. Package.bugReports)
                       & license           .~ (pkg ^. Package.license)
                       & licenseFile       .~ (pkg ^. Package.licenseFile)
                       & authors           .~ (pkg ^. Package.authors)
                       & maintainers       .~ (pkg ^. Package.maintainers)
                       & copyright         .~ (pkg ^. Package.copyright)
                       & tags              .~ (pkg ^. Package.tags)
                       & dependencies      .~ (pkg ^. Package.dependencies)


registerInstalled :: Package -> PackageFamily -> PackageFamily
registerInstalled pkg pkgF = pkgF & installedVersions %~ (pkg ^. Package.id ^. Package.version :)


------------------------------------------------------------------------
-- INSTANCES
------------------------------------------------------------------------

instance Default PackageFamily where
    def = PackageFamily { _name              = def
                        , _availableVersions = def
                        , _installedVersions = def
                        , _synopsis          = def
                        , _description       = def
                        , _homepage          = def
                        , _url               = def
                        , _bugReports        = def
                        , _license           = def
                        , _licenseFile       = def
                        , _authors           = def
                        , _maintainers       = def
                        , _copyright         = def
                        , _tags              = def
                        , _dependencies      = def
                        }


JSON.deriveJSON JSON.defaultOptions{JSON.fieldLabelModifier = drop 1} ''PackageFamily


