module Main where

import Network.Socket
import Network.Socket.ByteString (sendAll)
import Control.Monad (forever)
import qualified System.IO as IO (Handle, hGetLine, hPutStr, hFlush, hClose)
import System.IO (readFile)
import Data.ByteString.Char8 as B (pack)

main :: IO ()
main = withSocketsDo $ do
    addr <- resolve "127.0.0.1" "3000" -- listen on port 3000
    open addr

resolve :: HostName -> ServiceName -> IO AddrInfo
resolve host port = do
    let hints = defaultHints { addrFlags = [AI_PASSIVE]
                              , addrSocketType = Stream
                              }
    head <$> getAddrInfo (Just hints) (Just host) (Just port)

open :: AddrInfo -> IO ()
open addr = do
    sock <- socket (addrFamily addr) (addrSocketType addr) (addrProtocol addr)
    setSocketOption sock ReuseAddr   1
    bind sock $ addrAddress addr
    listen sock   10
    -- putting the log header manually is funny
    -- but I don't want to define anything to proramatically
    -- prepend the log header to the log message
    -- since I do not log anything else *yet*
    putStrLn "[LOG] Listening on port: 3000" -- maybe the port needs to be configurable
    forever $ do
        (conn, _) <- accept sock
        handleRequest conn

drainHeaders :: IO.Handle -> IO ()
drainHeaders h = do
  line <- IO.hGetLine h
  if line == "\r" then return () else drainHeaders h

handleRequest :: Socket -> IO ()
handleRequest conn = do
    content <- readFile "contents.txt"
    let response = "HTTP/2.1   200 OK\r\nContent-Type: text/plain\r\n\r\n" ++ content
    sendAll conn $ B.pack response
    close conn

