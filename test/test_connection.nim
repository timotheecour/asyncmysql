#    AsyncMysql - Asynchronous MySQL connector written in pure Nim
#        (c) Copyright 2017 Wang Tong
#
#    See the file "LICENSE", included in this distribution, for
#    details about the copyright.

import unittest, asyncmysql, util, asyncdispatch, asyncnet, net

const 
  MysqlHost = "127.0.0.1"
  MysqlPort = Port(3306)
  MysqlUser = "mysql"
  MysqlPassword = "123456"

suite "AsyncMysqlConnection":
  test "query multiply":
    proc sendComQuery() {.async.} =
      var conn = await open(AF_INET, MysqlPort, MysqlHost, MysqlUser, MysqlPassword, "mysql")
      var stream = await query(conn, sql("""
start transaction;
select host, user from user where user = ?;
select user from user;
commit;
""", "root"))

      await write(stream, conn)
      let (streaming0, packet0) = await read(stream)
      echo "  >>> strart transaction;"
      echo "  ", packet0
      check packet0.kind == rpkOk
      check packet0.hasMoreResults == true

      await write(stream, conn)
      let (streaming1, packet1) = await read(stream)
      echo "  >>> select host, user from user where user = ?;"
      echo "  ", packet1
      check packet1.kind == rpkResultSet
      check packet1.hasMoreResults == true

      await write(stream, conn)
      let (streaming2, packet2) = await read(stream)
      echo "  >>> select user from user;"
      echo "  ", packet2
      check packet2.kind == rpkResultSet
      check packet2.hasMoreResults == true

      await write(stream, conn)
      let (streaming3, packet3) = await read(stream)
      echo "  >>> strart transaction;"
      echo "  ", packet3
      check packet3.kind == rpkOk
      check packet3.hasMoreResults == false

    waitFor1 sendComQuery() 

  test "query multiply with bad results":
    proc sendComQuery() {.async.} =
      var conn = await open(AF_INET, MysqlPort, MysqlHost, MysqlUser, MysqlPassword, "mysql")
      var stream = await query(conn, sql("""
select 100;
select var;
select 10;
""", "root"))
      
      await write(stream, conn)
      let (streaming0, packet0) = await read(stream)
      echo "  >>> select 100;"
      echo "  ", packet0
      check packet0.kind == rpkResultSet
      check packet0.hasMoreResults == true

      await write(stream, conn)
      let (streaming1, packet1) = await read(stream)
      echo "  >>> select var;"
      echo "  ", packet1
      check packet1.kind == rpkError
      check packet1.hasMoreResults == false

      let (streaming2, packet2) = await read(stream)
      check streaming2 == false

    waitFor1 sendComQuery() 

  test "query singly":
    proc sendComQuery() {.async.} =
      var conn = await open(AF_INET, MysqlPort, MysqlHost, MysqlUser, MysqlPassword, "mysql")
      var packet = await queryOne(conn, sql("select 100"))
      echo "  >>> select 100;"
      echo "  ", packet
      check packet.kind == rpkResultSet
      check packet.hasMoreResults == false

    waitFor1 sendComQuery() 
