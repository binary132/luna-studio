---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE RankNTypes #-}

module Flowbox.AccountManager.Handler.Handler where

import Flowbox.AccountManager.Context      (Context)
import Flowbox.AccountManager.Handler.User as HandlerUser
import Flowbox.ZMQ.RPC.Handler             (RPCHandler)

import           Generated.Proto.AccountManager.Request              (Request)
import qualified Generated.Proto.AccountManager.Request              as Request
import qualified Generated.Proto.AccountManager.Request.Method       as Method
import qualified Generated.Proto.AccountManager.User.Login.Args      as User_Login
import qualified Generated.Proto.AccountManager.User.Login.Result    as User_Login
import qualified Generated.Proto.AccountManager.User.Logout.Args     as User_Logout
import qualified Generated.Proto.AccountManager.User.Logout.Result   as User_Logout
import qualified Generated.Proto.AccountManager.User.Register.Args   as User_Register
import qualified Generated.Proto.AccountManager.User.Register.Result as User_Register
import qualified Generated.Proto.AccountManager.User.Session.Args    as User_Session
import qualified Generated.Proto.AccountManager.User.Session.Result  as User_Session



handler :: Context -> RPCHandler Request
handler ctx callback request = case Request.method request of
    Method.User_Register -> callback (HandlerUser.register ctx) User_Register.req User_Register.rsp
    Method.User_Login    -> callback (HandlerUser.login    ctx) User_Login.req    User_Login.rsp
    Method.User_Logout   -> callback (HandlerUser.logout   ctx) User_Logout.req   User_Logout.rsp
    Method.User_Session  -> callback (HandlerUser.session  ctx) User_Session.req  User_Session.rsp
