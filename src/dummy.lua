local dummy = {}

function dummy.fact(n)
  if n == 1 then
    return 1
  else
    return n * dummy.fact(n - 1)
  end
end

return dummy
