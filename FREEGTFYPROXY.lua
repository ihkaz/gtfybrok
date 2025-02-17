function getinv(id)
    for _, i in pairs(GetInventory()) do
        if i.id == id then
            return i.count
        end
    end
    return 0
end
function drop(id, count)
    SendPacket(2, string.format([[action|dialog_return
dialog_name|drop_item
itemID|%s|
count|%s]], id, count))
end
function logs(s)
    return s and SendVarlist({[0] = "OnConsoleMessage", [1] = "`0[`4iHkaz Community``]``" .. s, netid = -1}) or false
end

function lockbalance()
    return (getinv(242) or 0) + ((getinv(7188) or 0) * 10000) + ((getinv(1796) or 0) * 100)
end

function cdrop(amount)
    if amount > lockbalance() then
        return
    end
    bgl = (amount >= 10000) and (math.floor(amount // 10000)) or 0
    dl = (amount >= 100) and (math.floor(amount % 10000 // 100)) or 0
    wl = (amount >= 1) and (math.floor(((amount % 10000) % 100))) or 0
    if wl and wl > 0 then
        drop(242, wl)
    end
    if dl and dl > 0 then
        drop(1796, dl)
    end
    if bgl and bgl > 0 then
        drop(7188, bgl)
    end
end

function cmdlist(a, b)
    if b:find("action|input\n|text|/(.+)") then
        command = b:match("action|input\n|text|/(.+)")
        if command then
            if command:find("wdrop") then
                amounts = tonumber(b:match("wdrop (%d+)"))
                if not amounts then
                    return logs("Example : /wdrop {amount}")
                end
                drop(242, tonumber(amounts))
                return true
            end
            if command:find("ddrop") then
                amounts = tonumber(b:match("ddrop (%d+)"))
                if not amounts then
                    return logs("Example : /ddrop {amount}")
                end
                drop(1796, amounts)
                return true
            end
            if command:find("bdrop") then
                amounts = tonumber(b:match("bdrop (%d+)"))
                if not amounts then
                    return logs("Example : /bdrop {amount}")
                end
                drop(7188, amounts)
                return true
            end
            if command:find("cdrop") then
                amounts = tonumber(b:match("cdrop (%d+)"))
                if not amounts then
                    return logs("Example : /cdrop {amount}")
                end
                cdrop(amounts)
                return true
            end
        end
    end
end

AddCallback("COMMANDLIST", "OnPacket", cmdlist)
