function getinv(id)
    for _, i in pairs(GetInventory()) do
        if i.id == id then
            return i.count
        end
    end
    return 0
end
local logspin = {}
local dialogs = [[
set_bg_color|0,0,0,200
set_border_color|0,0,0,250
set_default_color|`0
add_label_with_icon|big|iHkaz Community Helper|left|7188|
add_smalltext|https://dsc.gg/ihkaz|left|
add_spacer|small|
add_label_with_icon|small|What's New? PATCH : [`420/02/2025``]|left|6124|
add_spacer|small|
add_smalltext|[+] Added Shortcut Convert Diamond Locks to Blue Gem Locks if u wrench telephone. `2thanks to [SATANMONARCH]``|left|
add_spacer|small|
add_smalltext|`2Creator`` : `1@pangerans|left|
add_spacer|small|
end_dialog|gazette|HAPPY SCRIPTING!||
add_quick_exit|
]]
local cmdialogs = [[
set_bg_color|0,0,0,200
set_border_color|0,0,0,250
set_default_color|`0
add_label_with_icon|big|List Commands : |left|32|
add_smalltext|`4https://dsc.gg/ihkaz|left|
add_spacer|small|
add_label_with_icon|small|[/wl {count}] Dropping WLS|left|242|
add_label_with_icon|small|[/dl {count}] Dropping DLS|left|1796|
add_label_with_icon|small|[/bgl {count}] Dropping BGLS|left|7188|
add_label_with_icon|small|[/abso {count}] Dropping Absolute Locks|left|16770|
add_label_with_icon|small|[/wd {count}] Witdraw BGL on the banks|left|6290|
add_label_with_icon|small|[/depo {count}] Deposit BGL to the banks|left|6290|
add_spacer|small|
add_smalltext|`2Creator`` : `1@pangerans|left|
add_spacer|small|
end_dialog|gazette|HAPPY SCRIPTING!||
add_quick_exit|
]]
function drop(id, count)
    SendPacket(2, string.format([[action|dialog_return
dialog_name|drop_item
itemID|%s|
count|%s]], id, count))
end
function logs(s)
    return s and SendVarlist({[0] = "OnConsoleMessage", [1] = s, netid = -1}) or false
end


function getBgl(x ,y)
SendPacket(2,'action|dialog_return\ndialog_name|phonecall\ntilex|'.. x .. '|\ntiley|' .. y .. '|\nnum|-34|\nbuttonClicked|turnin\n')
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

function banks(m, amount)
    local a = "action|dialog_return\ndialog_name|my_bank_account\nbuttonClicked|"

    if m == "depo" then
        return SendPacket(2, a .. "depo_true\n\nbgl_|" .. amount)
    elseif m == "wd" then
        return SendPacket(2, a .. "wd_true\n\nwd_amount|" .. amount)
    end
   return nil
end

function cmdlist(a, b)
    if b:find("action|input\n|text|") then
        command = b:match("action|input\n|text|/(.+)")
        if command then
            if command:match("^wl%s") then
                amounts = tonumber(b:match("wl (%d+)"))
                if not amounts then
                    return logs("Example : /wl {amount}")
                end
                drop(242, tonumber(amounts))
                return true
            end
            if command:match("^dl%s") then
                amounts = tonumber(b:match("dl (%d+)"))
                if not amounts then
                    return logs("Example : /dl {amount}")
                end
                drop(1796, amounts)
                return true
            end
            if command:match("^bgl%s") then
                amounts = tonumber(b:match("bgl (%d+)"))
                if not amounts then
                    return logs("Example : /bgl {amount}")
                end
                drop(7188, amounts)
                return true
            end
            if command:match("^abso%s") then
                amounts = tonumber(b:match("abso (%d+)"))
                if not amounts then
                    return logs("Example : /abso {amount}")
                end
                drop(16770, amounts)
                return true
            end
            if command:match("^cdrop%s") then
                amounts = tonumber(b:match("cdrop (%d+)"))
                if not amounts then
                    return logs("Example : /cdrop {amount}")
                end
                cdrop(amounts)
                return true
            end
            if command == "ihkazhelp" then
               SendVarlist({[0] = "OnDialogRequest",[1] = cmdialogs,netid = -1})
               return true
            end
            if command:match("^wd%s") then
               amounts = tonumber(b:match("wd (%d+)"))
               if not amounts then
                  return logs("Example : /wd {amount}")
               end
               banks("wd",amounts)
               logs("Withdraw "..amounts.." Bgl in the banks")
               return true
            end
            if command:match("^depo%s") then
               amounts = tonumber(b:match("depo (%d+)"))
               if not amounts then
                  return logs("Example : /depo {amount}")
               end
               banks("depo",amounts)
               logs("Deposit "..amounts.." Bgl in the banks")
               return true
            end
        end
    end
end

function variantlist(v)
    if v[0] == "OnTalkBubble" then
        if v[2]:find("spun the wheel and got") then
            local num = tonumber(string.match(v[2]:gsub("`.",""), "(%d+)%!"))
            local counts = (num == 19 or num == 28 or num == 0) and "[0]" or "["..string.sub(math.floor(num / 10) + (num % 10), -1).."]"
            SendVarlist({
                [0] = "OnTalkBubble",
                [1] = v[1],
                [2] = "`7[`2 REAL ``]``"..v[2]..counts,
                [3] = v[3],
                netid = -1
            })
            return true
        end
    end
   if v[0] == "OnConsoleMessage" then
      logs(v[1])
      return true
   end
   if v[0] == "OnDialogRequest" then
      if v[1]:find("add_textbox|Excellent%! I'm happy to sell you a Blue Gem Lock in exchange for 100 Diamond Lock") then
         return true
      end
      if v[1]:find("phonecall") and getinv(1796) >= 100 then
         tilex = v[1]:match("tilex|(%d+)")
         tiley = v[1]:match("tiley|(%d+)")
         getBgl(tilex,tiley)
         return true
      end
   end
end


SendVarlist({[0] = "OnDialogRequest",[1] = dialogs,netid = -1})
logs("Succes Load FREEPROXYGTFY")
logs("Join Discord : https://dsc.gg/ihkaz")
logs("Report to @pangerans on discord if u found any bugs")
logs("Request Feature? Join : https://dsc.gg/ihkaz")
AddCallback("COMMANDLIST", "OnPacket", cmdlist)
AddCallback("VARIANTLIST", "OnVarlist", variantlist)