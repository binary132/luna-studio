module Common.Data.JSON where

import           Common.Prelude
import           Data.Aeson       (Result (Success), fromJSON, toJSON)
import           Data.Aeson.Types (FromJSON, ToJSON)



fromJSONVal :: (Show a, FromJSON a, MonadIO m) => JSVal -> m (Maybe a)
fromJSONVal jsval = liftIO (fromJSVal jsval) >>= \case
    Just jsonValue -> case fromJSON jsonValue of
        Success r -> return $ Just r
        e         -> putStrLn ("Cannot parse object " <> show jsonValue <> " " <> show e) >> return Nothing
    _ -> putStrLn "Unparseable JSON object" >> return Nothing

toJSONVal :: (MonadIO m, ToJSON a) => a -> m JSVal
toJSONVal = liftIO . toJSVal . toJSON
