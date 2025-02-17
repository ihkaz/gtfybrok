




function lockbalance()
    return ((getinv(242) or 0) + ((getinv(7188) or 0) * 10000) + ((getinv(1796) or 0) * 100)
end

function cdrop(amount)
    if lockbalance() < a then return logs("Lock tidak mencukupi") end
    bgl = (amount >= 10000) and (math.floor(amount // 10000)) or 0
    dl = (amount >= 100) and (math.floor(amount % 10000 // 100)) or 0
    wl = (amount >= 1) and (math.floor(((amount % 10000) % 100))) or 0
    if wl and (getinv(242) < wl) then
      return logs("WLS Tidak mencukupi!. demo ke ihkaz for making auto cv lock(lol)")
    end
    if bgl and (getinv(7188) < bgl) then
      return logs("BGL Tidak mencukupi!. demo ke ihkaz for making auto cv lock")
    end
    if dl and (getinv(1796) < dl) then
      return logs("DL Tidak mencukupi!. demo ke ihkaz for making auto cv lock!")
    end
    if wl then
        drop(242,wl)
    end
    if dl then
        drop(1796,dl)
    end
    if bgl then
        drop(7188,bgl)
    end
end

function game(g,num)
  if g == "reme" then
    if num == 19 or num == 28 or num == 0 then
      return 0
      else
        return string.sub(math.floor(num/10) + (num % 10),-1)
    end
  end
  if g == "qeme" then
    return (num >= 10) and string.sub(num,-1) or num
  end
end

--sendPacket(2,"action|dialog_return\ndialog_name|my_bank_account\nbuttonClicked|depo_true\n\nbgl_|1")

function banks(m,amount)
  local a = "action|dialog_return\ndialog_name|my_bank_account\nbuttonClicked|"
  return (m == "depo") and SendPacket(2,a.."depo_true\n\nbgl_|"..amount) or (m == "wd") and SendPacket(2,a.."wd_true\n\nwd_amount|"..amount)
end

function telephone(x,y)
  return SendPacket(2,string.format("action|dialog_return\ndialog_name|phonecall\ntilex|%s|\ntiley|%s|\nnum|-34|\nbuttonClicked|turnin",x,y))
end


function drop(id,count)
    SendPacket(2,string.format([[action|dialog_return
dialog_name|drop_item
itemID|%s|
count|%s]],id,count))
end

function logs(s)
    return s and SendVarlist({[0] = "OnConsoleMessage",[1] = "`0[`4iHkaz Community``]``"..s,netid = -1
    }) or false
end

function getinv(id)
    for _,i in pairs(GetInventory()) do
        if i.id == id then
            return i.count
        end
    end
    return 0
end
function cmdlist(a,b)
  if b:find("^(action|input\n|text|)/(.+)") then
    command = b:match("action|input\n|text|/(.+)")
    if command then
      if command:find("wdrop") then
      amounts = tonumber(b:match("wdrop (%d+)"))
        if not amounts then return logs("Example : /wdrop {amount}") end
        drop(242,tonumber(amounts))
        return true
      end
      if command:find("ddrop") then
        amounts = tonumber(b:match("ddrop (%d+)"))
        if not amounts then return logs("Example : /ddrop {amount}") end
        drop(1796,amounts)
        return true
      end
      if command:find("bdrop") then
        amounts = tonumber(b:match("bdrop (%d+)"))
        if not amounts then return logs("Example : /bdrop {amount}") end
        drop(7188,amounts)
        return true
      end
      if command:find("cdrop") then
        amounts = tonumber(b:match("cdrop (%d+)"))
        if not amounts then return logs("Example : /cdrop {amount}") end
        cdrop(amounts)
        return true
        end
    end
  end
end

AddCallback("COMMANDLIST","OnPacket",cmdlist)
