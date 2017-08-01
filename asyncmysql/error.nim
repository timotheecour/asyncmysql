#    AsyncMysql - Asynchronous MySQL connector written in pure Nim
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

type
  MysqlError* = object of Exception

proc raiseMysqlError*(msg: string) =
  raise newException(MysqlError, msg)