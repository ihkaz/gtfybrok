function getinv(id)
    for _, i in pairs(GetInventory()) do
        if i.id == id then
            return i.count
        end
    end
    return 0
end
local dialogs = [[
set_bg_color|0,0,0,200
set_border_color|0,0,0,250
set_default_color|`0
add_label_with_icon|big|iHkaz Community Helper|left|7188|
add_smalltext|https://dsc.gg/ihkaz|left|
add_spacer|small|
add_label_with_icon|small|What's New?|left|6124|
add_spacer|small|
add_smalltext|[+] Make Script Online|left|
add_smalltext|[+] Add Reme Count on spun bubble|left|
add_smalltext|[+] Added Command (ddrop,bdrop,wdrop,cdrop)|left|
add_smalltext|[~] Will add Command (wd,depo,transferlock) for bgl banks (tommorow)|left|
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
add_label_with_icon|small|[/wdrop {count}] Dropping WLS|left|242|
add_label_with_icon|small|[/ddrop {count}] Dropping DLS|left|1796|
add_label_with_icon|small|[/bdrop {count}] Dropping BGLS|left|7188|
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
    return s and SendVarlist({[0] = "OnConsoleMessage", [1] = "`0[/ihkazhelp]``" .. s, netid = -1}) or false
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
            if command == "ihkazhelp" then
               SendVarlist({[0] = "OnDialogRequest",[1] = cmdialogs,netid = -1})
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
end





SendVarlist({[0] = "OnDialogRequest",[1] = dialogs,netid = -1})
logs("Succes Load FREEPROXYGTFY")
logs("Join Discord : https://dsc.gg/ihkaz")
logs("Report to @pangerans on discord if u found any bugs")
logs("Request Feature? Join : https://dsc.gg/ihkaz")
AddCallback("COMMANDLIST", "OnPacket", cmdlist)
AddCallback("VARIANTLIST", "OnVarlist", variantlist)
