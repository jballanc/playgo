require("luaunit")

local dummy = require("dummy")

TestDummy = {}

function TestDummy:testSimpleEquality()
  assertEquals(2^2, 4)
end

function TestDummy:testSimpleTruth()
  assertTrue(true)
end

function TestDummy:testDummyFunc()
  assertEquals(dummy.fact(3), 6)
end

LuaUnit:run()
