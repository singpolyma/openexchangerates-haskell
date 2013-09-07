module Currency.OpenExchangeRates (fetchRates) where

import Control.Error (readZ, syncIO, fmapLT, hoistEither, throwT, EitherT)
import Data.String (fromString)
import qualified Data.Map as Map
import qualified Data.Text as T

import Data.Aeson ((.:))
import qualified Data.Aeson as Aeson

import qualified Network.HTTP as HTTP
import qualified Network.Stream as HTTP
import qualified Network.URI as URI

import Currency
import Currency.Rates

newtype OERs = OERs (Rates Currency Double)

instance Aeson.FromJSON OERs where
	parseJSON (Aeson.Object o) = do
		ref <- readZ =<< (o .: (T.pack "base"))
		rs <- fmap Map.toList (o .: (T.pack "rates"))
		let rs' = map (\(k,v) -> (fromString k, v)) rs
		return $ OERs $ Rates ref (Map.fromList rs')
	parseJSON _ = fail "OpenExchangeRates data is an object."

-- | Fetch exchange rates from OpenExchangeRates.org
fetchRates ::
	String -- ^ AppID
	-> EitherT HTTP.ConnError IO (Rates Currency Double)
fetchRates appid = do
	resp <- hoistEither =<< (tryHTTP $ HTTP.simpleHTTP req)
	case resp of
		(HTTP.Response { HTTP.rspCode = (2,0,0), HTTP.rspBody = body }) -> do
			OERs rs <- fmapLT HTTP.ErrorMisc $ hoistEither (Aeson.eitherDecode body)
			return rs
		_ -> throwT (HTTP.ErrorMisc "Bad HTTP response code.")
	where
	tryHTTP = fmapLT (HTTP.ErrorMisc . show) . syncIO
	req = HTTP.mkRequest HTTP.GET uri
	Just uri = URI.parseURI $ "http://openexchangerates.org/api/latest.json?app_id=" ++ appid
