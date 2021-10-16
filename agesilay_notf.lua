script_name('Agesilay Notification')
script_author('S&D Scripts')
script_description('Sends messages to the family leader for job reporting.')
script_dependencies('events, ssl.https, inicfg, imgui')
script_version('1.9.9')
script_version_number(10)

local sampev    =   require 'lib.samp.events'
local https     =   require 'ssl.https'
local effil     =   require 'effil'
local encoding  =   require 'encoding'
local imgui     =   require 'imgui'
local inicfg    =   require 'inicfg'
local keys      =   require 'vkeys'
local memory    =   require 'memory'
require 'lib.moonloader'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local refresh_time = 0
local tasks = {
    delay = 3,
    list = {}
}

local commands = {
    ['setfrank'] = '(id) (rank)',
    ['fammute'] = '(id) (min) (reason)',
    ['famunmute'] = '(id)',
    ['famuninvite'] = '(id) (reason)'
}

local cfg = inicfg.load({
	config = {
        socnetwork = 1,
        chat_id = '',
        user_id = '',
        current_day = os.date('%D'),
        invite = 0,
        quest = 0,
        overlay = false,
        overlay_pos_x = 200,
        overlay_pos_y = 200,
        ukraine = false
	},
    setrank = {
        rank_1 = 4,
        rank_2 = 4,
        rank_3 = 4,
        rank_4 = 4,
        rank_5 = 10,
        rank_6 = 10,
        rank_7 = 30,
        rank_8 = 45
    }
}, 'agesilay_notf.ini')

local access_token = '15c68b42cbf7c09a141c924adafbc7da0e5b85544c09d2827cf03d80fb8830aed43118e0dbeab212483cc'
local settings = {}
local invite = cfg.config.invite
local quest = cfg.config.quest
local current_day = cfg.config.current_day
local checkvip = true
local members = {}
local offmembers = {}
local check_time = os.time()
local vipp = {}
local vzID = 0
local imbool = {}
local checkfmembers = false
local checkoffmembers = false
local vzName = nil
local selects = nil
local update_state = false -- Если переменная == true, значит начнётся обновление

local update_url = 'https://raw.githubusercontent.com/darksoorok/deputy/main/update.ini' -- Путь к ini файлу
local update_path = getWorkingDirectory() .. "\\config\\agesilay_update.ini"
local script_url = 'https://raw.githubusercontent.com/darksoorok/deputy/main/agesilay_notf.lua' -- Путь скрипту на GitHub.
local script_path = thisScript().path
local activeCheckbox = 0
local active_kickOffPlayer = false
local arr_kick = {}
for i = 1,500 do
    imbool[i] = imgui.ImBool(false)
end
local rank_1 = imgui.ImInt(cfg.setrank.rank_1)
local rank_2 = imgui.ImInt(cfg.setrank.rank_2)
local rank_3 = imgui.ImInt(cfg.setrank.rank_3)
local rank_4 = imgui.ImInt(cfg.setrank.rank_4)
local rank_5 = imgui.ImInt(cfg.setrank.rank_5)
local rank_6 = imgui.ImInt(cfg.setrank.rank_6)
local rank_7 = imgui.ImInt(cfg.setrank.rank_7)
local rank_8 = imgui.ImInt(cfg.setrank.rank_8)
local wait_kick = imgui.ImInt(10)
local check_rank = imgui.ImInt(0)
local choise_socnetwork = imgui.ImInt(cfg.config.socnetwork)
local setrank = imgui.ImBuffer(2)
local findname = imgui.ImBuffer(100)
local uninvite = imgui.ImBuffer(150)
local setmute = imgui.ImBuffer(150)
local settime = imgui.ImBuffer(4)
local addname = imgui.ImBuffer(150)
local addprich = imgui.ImBuffer(150)
local ages = imgui.ImBool(false)
local overlay = imgui.ImBool(cfg.config.overlay)
local Ukraine = imgui.ImBool(cfg.config.ukraine)

local fmembers = imgui.ImBool(false)
local offmembers = imgui.ImBool(false)
local sw, sh = getScreenResolution()
local user_id = imgui.ImBuffer(u8(cfg.config.user_id), 256)
local chat_id = imgui.ImBuffer(u8(cfg.config.chat_id), 256)

if not doesFileExist('moonloader/config/agesilay_notf.ini') then inicfg.save(cfg, 'agesilay_notf.ini') end

local server_get = function()
    local file = getWorkingDirectory() .. '\\config\\.csc';
    local url = 'https://sd-scripts.ru/api/?fam.get={"name":"' .. sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) .. '"}'
    local data = nil
    downloadUrlToFile(url, file, function(id, status, p1, p2)
        if status == 6 then 
            local f = io.open(file, 'r+')
            if f then 
                local text = (f:read('a*'))
                data = decodeJson(text)
                f:close()
                os.remove(file)
            else
                data = {error = true}
            end
        end
    end)
    while not data do wait(0) end
    if data then return data end
end

local timer = lua_thread.create_suspended(function()
    while true do
        wait(refresh_time * 1000)
        local data = server_get()
        if not data.error then 
            local data = data.response.result
            refresh_time = data.script.refresh
            local count = 0
            for k, v in pairs(data.commands) do
                tasks.list[k] = v
                count = count + 1
            end
        end
    end
end)

local offkickplayer = lua_thread.create_suspended(function()
    while active_kickOffPlayer do wait(0)
        local ix = activeCheckbox
        sendMessage(1, '[Deputy Helper] {FFFF00}Внимание! {FFFFFF}Сейчас будет произведён кик игроков в оффлайне.')
        wait(10)
        sendMessage(1, '[Deputy Helper] {FF0000}[ ! ] {D3D3D3}Кик игроков займёт {228fff}' ..wait_kick.v * activeCheckbox.. ' {CD5C5C}cекунд!')
        for k,v in pairs(arr_kick) do
            if v[1] ~= nil then
                ix = ix - 1
                sampSendChat('/famoffkick ' ..v[1]); wait(150)
                wait((ix > 0 and (wait_kick.v * 1000) or 1000))
            end
        end
        if activeCheckbox == 1 then
            sendMessage(1, '[Deputy Helper] {FFFFFF}Был кикнут {228FFF}'..activeCheckbox..'{FFFFFF} игрок в оффлайне.')
        elseif activeCheckbox >= 2 and activeCheckbox < 5 then
            sendMessage(1, '[Deputy Helper] {FFFFFF}Было кикнуто {228FFF}'..activeCheckbox..'{FFFFFF} игрока в оффлайне.')
        elseif activeCheckbox >= 5 then
            sendMessage(1, '[Deputy Helper] {FFFFFF}Было кикнуто {228FFF}'..activeCheckbox..'{FFFFFF} игроков в оффлайне.')
        end
        arr_kick = {}
        active_kickOffPlayer = false
        activeCheckbox = 0
    end
end)

local processor = function()
    for k, v in pairs(tasks.list) do 
        local params = commands[v.command]
        for k1, v1 in pairs(v.params) do
            params = params:gsub('%(' .. k1 .. '%)', u8:decode(v1))
        end
        sampSendChat('/' .. v.command .. ' ' .. params)
        tasks.list[k] = nil
        wait(tasks.delay * 1000)
    end
end

function check_update() -- Проверка обновлений
    downloadUrlToFile(update_url, update_path, function(id, status)
        if status == 6 then
            updateIni = inicfg.load(nil, update_path)
            if updateIni and (tonumber(updateIni.info.vers) > thisScript().version_num) then -- Сверяем версию в скрипте и в ini файле на github
                sendMessage(1, '[Deputy Helper] {FFFFFF}Найдена новая версия скрипта {228fff}' ..updateIni.info.vers_text..'{FFFFFF}. Скачиваю...')
                update_state = true
            end
        end
    end)
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end;

    local result, nameServ = checkServer(select(1, sampGetCurrentServerAddress()))
    
    if not result then
		print('{ff0000}Ошибка: {ffffff}скрипт работает только на проекте {FA8072}Arizona RP.')
		thisScript():unload()
    end

    if memory.tohex(getModuleHandle("samp.dll") + 0xBABE, 10, true ) == "E86D9A0A0083C41C85C0" then
        sampIsLocalPlayerSpawned = function()
            local res, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            return sampGetGamestate() == 3 and res and sampGetPlayerAnimationId(id) ~= 0
        end
    end

    while not sampIsLocalPlayerSpawned() do wait(130) end
    
    check_update()
    updateBlacklist()
    wait(1000)
    print('{ffffff}Скрипт {9ACD32}успешно загружен.{ffffff} Версия скрипта: {ff0000}' ..thisScript().version)
    _, id_deputy = sampGetPlayerIdByCharHandle(playerPed)
    nickname = sampGetPlayerNickname(id_deputy)
    sendMessage(1, '[Deputy Helper] {ffffff}Скрипт запущен и работает {808080}[v '..thisScript().version..']. {ffffff}Настройки - {800080}/deputy')
    -- // проверка даты
    if not current_day then
        current_day = os.date('%D')
    end
    sampRegisterChatCommand('deputy', function()
		ages.v = not ages.v
    end)
    sampRegisterChatCommand('fi', faminvite)
    sampRegisterChatCommand('fm', function() sampSendChat('/fmembers') end)
    sampRegisterChatCommand('fmoff', function() 
        lua_thread.create(function()
            sampSendChat('/fammenu'); wait(100); sampSendClickTextdraw(2070); checkoffmembers = true
        end)
    end)

    if doesFileExist(update_path) then os.remove(update_path) end
    timer:run();
    while true do 
        wait(0) 
        processor()
        imgui.Process = ages.v or overlay.v or fmembers.v or offmembers.v; imgui.LockPlayer = ages.v or fmembers.v or offmembers.v; imgui.ShowCursor = imgui.Process
        if overlay.v then imgui.ShowCursor = false end
        if sampGetGamestate() == 3 and sampIsLocalPlayerSpawned() then
            if checkvip then
                while (encodeJson(vipp) == '{}') do
                    sampSendChat('/vipplayers')
                    wait(111)
                    vip = 0
                    novip = 0
                end
                strVips = table.concat(vipp, ', ')
                for k, v in ipairs(members) do
                    local name_members = tostring(v[2])
                    if name_members:find('%w+_%w+') then
                        if strVips:find(name_members) then
                            vip = vip + 1
                        else
                            novip = novip + 1
                        end
                    end
                end
                vipp = {}
                checkvip = false
            end
        end
        if current_day ~= os.date('%D') then
            wait(3000)
            current_day = os.date('%D')
            invite = 0
            quest = 0
            cfg.config.current_day = current_day
            cfg.config.invite = invite
            cfg.config.quest = quest
            inicfg.save(cfg, 'agesilay_notf.ini')
            sendMessage(1, '[Deputy Helper] {ffffff}Скрипт обнулил значения инвайтов и квестов, так как начался новый день.')
            wait(10000)
        end
        if update_state then -- Обновление скрипта.
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == 6 then
                    sendMessage(1, '[Deputy Helper] Скрипт успешно обновлён!')
                end
            end)
            break
        end
    end
end

function updateBlacklist()
    local update_file = getWorkingDirectory() .. '\\config\\blacklist.json'
    blacklist = settings.load({}, update_file)
    downloadUrlToFile('https://raw.githubusercontent.com/darksoorok/deputy/main/blacklist.json', update_file, function(id, status, p1, p2)
        if status == 6 then
            local f = io.open(update_file, 'r+')
            if f then
                sendMessage(2, '[Deputy Helper] {FFFFFF}Список ЧС {98FB98}успешно загружен')
                local data = decodeJson(f:read('a*'))
                blacklist = settings.load(data, update_file)
                f:close()
            else
                sendMessage(2, '[Deputy Helper] {FFFFFF}Список ЧС {ff0000}не загружен')
            end
        end
    end)
end

function settings.load(table, dir)
    if not doesFileExist(dir) then
        local f = io.open(dir, 'w+'); local suc = f:write(encodeJson(table)); f:close()
        if suc then return table end
        return table
    else
        local f = io.open(dir, 'r+'); local array = decodeJson(f:read('a*')); f:close()
        if not array then return table end
        return array
    end
end

function settings.save(table, dir)
    local f = io.open(dir, 'w+'); local suc = f:write(encodeJson(table));
    f:close()
    return table
end

function faminvite(arg)
    if arg:match('%d+') then
        if encodeJson(blacklist) ~= '{}' then
            check_blacklist = true; fi = true
            sampSendChat('/id ' ..arg)
        else
            sendMessage(1, '[Deputy Helper] {ffffff}Невозможно проверить игрока, т.к. чёрный список не загружен.')
            sampSendChat('/faminvite ' ..arg)
        end
    else
        sendMessage(1, '[Deputy Helper] {ffffff}Введите команду: {228fff}/fi [id]')
    end
end

function sampev.onPlaySound(sound, pos) 
	if sound == 1052 then 
		return false
	end
end
function onWindowMessage(msg, wparam, lparam)
    if msg == 0x100 or msg == 0x101 then
        if (wparam == keys.VK_ESCAPE and fmembers.v  or offmembers.v) and not checkfmembers and not checkoffmembers and not isPauseMenuActive() then
            consumeWindowMessage(true, false)
            if msg == 0x101 then
                offmembers.v = false; fmembers.v = false; selects = nil
            end
        end
        if (wparam == keys.VK_F8) and not stop_render then
            lua_thread.create(function() stop_render = true; wait(1300); stop_render = false end)
        end
    end
end
function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end
local encodeUrl = function(str)
    str = str:gsub(' ', '%+')
    str = str:gsub('\n', '%%0A')
    return u8:encode(str, 'CP1251')
end

function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end

function sampGetPlayerIdByNickname(nick)
    local _, myid = sampGetPlayerIdByCharHandle(playerPed)
    if tostring(nick) == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1000 do if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == tostring(nick) then return i end end
end

function SendMessageDeputy(message)
    if choise_socnetwork.v == 1 and user_id.v ~= '' then
        https.request('https://api.vk.com/method/messages.send?v=5.131&message='..encodeUrl(message)..'&user_id='..user_id.v..'&access_token='..access_token..'&random_id='..math.random(-2147483648, 2147483647))
    elseif choise_socnetwork.v == 2 and chat_id.v ~= '' then 
        https.request('https://api.telegram.org/bot1967806703:AAEJyg7NxAHDqhKp5_VPoCxaf3lxHR9tq90/sendMessage?chat_id='..chat_id.v..'&text='..encodeUrl(message))
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if text:find('В этой семье никто не состоит или нет оффлайн игроков') then
        lua_thread.create(function()
            wait(300)
            sampSendDialogResponse(id, 0, 0, nil)
            sampCloseCurrentDialogWithButton(0)
            page_off = false
            checkoffmembers = false
        end)
    end
    if id == 2931 and style == 5 then
        if imguiclose then
            lua_thread.create(function()
                wait(300)
                sampSendDialogResponse(id, 0, 0, nil)
                sampCloseCurrentDialogWithButton(0)
            end)
            imguiclose = false
            return false
        end
        if checkoffmembers then
            offmembers.v = true
            if not page_off then offmembers = {} end
            local lines = -1
            for line in text:gmatch('[^\r\n]+') do
                if line:find('%{FFFFFF%}([A-z_]+)%s+%((%d+)%)(.+)%s+(%d+%s.+)') then
                    local name, rank, name_rank, day_off = line:match('%{FFFFFF%}([A-z_]+)%s+%((%d+)%)(.+)%s+(%d+%s.+)')
                    table.insert(offmembers,{name, rank, name_rank, day_off})
                end
                if line:find('%{B0E73A%}Вперед %>%>%>') then
                    lua_thread.create(function()
                        page_off = true
                        wait(300)
                        sampSendDialogResponse(id, 1, lines, "Вперед >>>")
                        lines = -1
                    end)
                    return false
                else page_off = false end
                lines = lines + 1
            end
            if not page_off then
                lua_thread.create(function()
                    wait(300)
                    sampSendDialogResponse(id, 0, 0, nil)
                    sampCloseCurrentDialogWithButton(0)
                    checkoffmembers = false
                end)
            end
            return false
        end
    end
    if text:find('%(Ранг%) Ник') and id == 1488 and style == 5 then
        checkfmembers = true
        fmembers.v = true
        online = title:match('%{......%}[A-z]+%(В сети%: (%d+)%) %| %{......%}Семья')
        if not page then members = {} end
        local lines = -1
        for line in text:gmatch('[^\r\n]+') do
            if line:find('%((%d+)%)%s([A-z_]+)%((%d+)%)%s+(%d+)%s+(%d+)%/8%s+(%d+)') then
                local rank, name, id, score, kvest, afk = line:match('%((%d+)%)%s([A-z_]+)%((%d+)%)%s+(%d+)%s+(%d+)%/8%s+(%d+)')
                table.insert(members,{rank, name, id, score, afk, kvest})
            end
            if line:find('%{9ACD32%}Следующая страница %{FFFFFF%}%[»%]') then
                lua_thread.create(function()
                    page = true
                    wait(300)
                    sampSendDialogResponse(id, 1, lines, line)
                    lines = -1
                end)
                return false
            else page = false end
            lines = lines + 1
        end
        checkvip = true
        checkfmembers = false
        if not page then
            lua_thread.create(function()
                wait(300)
                sampSendDialogResponse(id, 0, 0, nil)
                sampCloseCurrentDialogWithButton(0)
            end)
        end
        return false
    end
end

function sampev.onServerMessage(color, text)
    local getname = text:match('^%[VIP%]: (.+)%[%d+%].+уровень')
    if getname then
        table.insert(vipp, getname) 
        return false
    end

    local vipplayer = text:match('Всего: (%d+) человек')
    if vipplayer then
        if #vipp == tonumber(vipplayer) then
            sendMessage(2, '[Deputy Helper] {FFFFFF}Информация о VIP обновлена.')
        else
            sendMessage(2, '[Deputy Helper] Ошибка обновления информации о VIP! '..#vipp..' ~= '..vipplayer)
        end
        vipplayer = 0
        return false
    end

    local id_uid, level, uid, platform = text:match('%[(%d+)%] %w+_%w+ %| Уровень%: (%d+) %| UID%: (%d+) %| packetloss%: %d+%.%d+ %((.+)%)')

    if id_uid and level and uid and check_blacklist then
        updateBlacklist()
        if fi then
            if tonumber(level) >= 3 then
                for k, v in pairs(blacklist) do
                    if v == tonumber(uid) then
                        sampSendChat('Вы в чёрном списке нашей семьи!')
                        checks_blacklist = true
                        break
                    end
                end
                if not checks_blacklist then
                    sampSendChat('/faminvite ' ..id_uid)
                end
            else
                sampSendChat('Вы слишком мало проживаете в штате. От 3-х лет приём в семью.')
            end
        else
            for k, v in pairs(blacklist) do
                if v == tonumber(uid) then
                    checks_blacklist = true
                end
            end
            info_blacklist = (checks_blacklist and '{FF0000}' or '{98FB98}') .. uid
            local arr_platform = {
                ['без лаунчера'] = '{b523de}Client',
                ['лаунчер'] = '{bf3634}Launcher',
                ['мобильный лаунчер'] = '{63de4e}Mobile'
            }
            info_platform = arr_platform[platform]
        end
        fi = false
        checks_blacklist = false
        check_blacklist = false
        id_uid, level, uid = nil
        return false
    end

    local names = text:match('%{......%}%[Семья %(Новости%)%] (%w+_%w+)%[%d+%]%:%{......%}.+')

    if text:find('%{......%}%[Семья %(Новости%)%] (%w+_%w+)%[(%d+)%]%:%{......%} выдал бан семейного чата (%w+_%w+)%[(%d+)%], на (%d+)мин, причина%: (.+)') then
        if (names == nickname) then
            lua_thread.create(function()
                local my_text = text:gsub('{......}', '')
                sendMessageLeader(my_text.. '\n<' ..thisScript().version.. '>')
                wait(500)
                SendMessageDeputy(my_text)
            end)
        end
    end

    if text:find('%{......%}%[Семья %(Новости%)%] (%w+_%w+)%[(%d+)%]%:%{......%} выгнал из семьи (%w+_%w+)%[(%d+)%]%! Причина%: (.+)') then     
        if (names == nickname) then
            lua_thread.create(function()
                local my_text = text:gsub('{......}', '')
                sendMessageLeader(my_text.. '\n<' ..thisScript().version.. '>')
                wait(500)
                SendMessageDeputy(my_text)
            end)
        end
    end

    if text:find('%{......%}%[Семья %(Беда%)%] %w+_%w+%[%d+%]%:%{......%}Получил BAN за нарушения. Репутация семьи понижена!') then
        lua_thread.create(function()
            local my_text = text:gsub('{......}', '')
            sendMessageLeader(my_text)
            wait(500)
            SendMessageDeputy(my_text)
        end) 
    end

    if text:find('%{......}%[Семья %(Новости%)%] %w+_%w+%[%d+%]:{......}%sпригласил в семью нового члена: (%w+_%w+)%[(%d+)%]') then
        if (names == nickname) then
            lua_thread.create(function()
                local my_text = text:gsub('{......}', '')
                invite = invite + 1
                cfg.config.invite = invite
                inicfg.save(cfg, 'agesilay_notf.ini')
                sendMessageLeader(my_text.. '\n<' ..thisScript().version.. '>. Принял: ' ..invite.. ' человек.')
                wait(500)
                SendMessageDeputy(my_text)        
            end)
        end
    end
    
    if text:find('%{......%}%[Семья %(Новости%)%] %w+_%w+%[%d+%]%:%{......%} выполнил ежедневное задание') then
        if (names == nickname) then
            lua_thread.create(function()
                local my_text = text:gsub('{......}', '')
                quest = quest + 1
                cfg.config.quest = quest
                inicfg.save(cfg, 'agesilay_notf.ini')
                sendMessageLeader(my_text.. '\n<' ..thisScript().version.. '>. Выполнил квестов: ' ..quest.. '.')
                wait(500)
                SendMessageDeputy(my_text)
            end)
        end
    end

    if text:find('%[Family War%] Член семьи %w+_%w+ загрузился на территории №%d+. Семейные монеты%: %d+шт, деньги%: %$[%d+.]+') then
        sendMessageLeader(text)
    end

    if text:find('%[Family%] Член семьи %w+_%w+ сделал объезд территорий и привёз на склад семейные монеты%(%d+шт%) и деньги: %$[%d+.]+') then
        sendMessageLeader(text)
    end

    if text:find('%{......%}%[Семья %(Новости%)%] %w+_%w+%[%d+%]%:%{......%} взял семейные монеты%(%d+шт%) со склада семьи') then
        local name, id, monet = text:match('%{......%}%[Семья %(Новости%)%] (%w+_%w+)%[(%d+)%]%:%{......%} взял семейные монеты%((%d+)шт%) со склада семьи')
        sendMessageLeader('[Семья (Новости)] ' ..name.. '[' ..id.. ']: взял семейные монеты (' ..monet.. ' шт.) со склада семьи!')
    end

    if text:find('%{......%}%[Семья %(Новости%)%] %w+_%w+%[%d+%]:%{......%} пополнил склад семьи семейныи монетами%(%d+шт%)') then
        local my_text = text:gsub('{......}', '')
        sendMessageLeader(my_text)
    end

    if text:find('%[Family Cars%] Фургон вашей семьи был взорван и сейчас идёт ограбление! %(виновник%: %w+_%w+%)') then
        sendMessageLeader(text)
    end

    -- -- arguments
    -- local nick_name, cmd, arg = text:match('%{......%}%[Семья%] %[10%] Imperator %|  (%w+_%w+)%[%d+%]%:%{......%}%s([^%d+]+)%s(.+)')
    -- if cmd and cmd:find(('кик' or 'мут' or 'ранг' or 'унмут')) and arg and (nick_name == 'Enzo_Davenport' or nick_name == 'Dmitry_Agesilay') then
    --     lua_thread.create(function() 
    --         local arr_cmd = {
    --             ['кик'] = '/famuninvite', 
    --             ['мут'] = '/fammute', 
    --             ['ранг'] = '/setfrank', 
    --             ['унмут'] = '/famunmute'
    --         }
    --         wait(600); sampSendChat(arr_cmd[cmd] .. ' ' ..arg)
    --         cmd, arg, nick_name = nil
    --     end)
    -- end
end

-- function sampev.onSendCommand(cmd) -- функция для команд
--     if not work then
--         local cmds, id_cmd = cmd:match('([^%d+]+)%s(%d+)') 
--         if cmds == '/famuninvite' then
--             if fmembers.v then fmembers.v = false end
--             sampSendChat('/id ' ..sampGetPlayerNickname(id_cmd))
--             takeScreenshot(1500)
--             cmds, id_cmd = nil
--         end
--     end
-- end

function takeScreenshot(time)
    lua_thread.create(function()
        wait(time)
        sampSendChat('/time'); 
        wait(800); 
        memory.setuint8(sampGetBase() + 0x119CBC, 1)
    end)
end

function sampGetPlayerOrganisation(playerId)
    local data = {
        [2147502591] = 'Полиция',
        [2147503871] = 'Полиция',
        [2164227710] = 'Больница',
        [2160918272] = 'Правительство',
        [2157536819] = 'Армия/ТСР',
        [2164221491] = 'Автошкола',
        [2164228096] = 'СМИ',
        [2150206647] = 'Банк ЛС',
        [2152104628] = 'Страховая',
        [2566951719] = 'Grove Street',
        [2580667164] = 'Los-Santos Vagos',
        [2580283596] = 'The Ballas',
        [2566979554] = 'Varios Los Aztecas',
        [2573625087] = 'The Rifa',
        [2158524536] = 'Night Wolfs',
        [2159694877] = 'Warlock MC',
        [2157314562] = 'Yakuza',
        [2150852249] = 'Russian Mafia',
        [2157523814] = 'La Cosa Nostra',
        [23486046] = 'В маске',
    }
    return (data[sampGetPlayerColor(playerId)] or 'Нет')
end

function imgui.OnDrawFrame()
    if (ages.v) then
        imgui.SetNextWindowSize(imgui.ImVec2(305,270), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(imgui.ImVec2((sw/2),(sh/2)), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5), imgui.WindowFlags.AlwaysAutoResize)
        imgui.Begin(u8'Приветствую, '..nickname..'('..id_deputy..') | S&D Scripts', ages, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)

        imgui.Text(u8'Куда присылать уведомления?')
        if imgui.RadioButton(u8'ВКонтакте',choise_socnetwork, 1) then
            cfg.config.socnetwork = choise_socnetwork.v
            inicfg.save(cfg, 'agesilay_notf.ini')
        end
        imgui.SameLine()
        if imgui.RadioButton(u8'Telegram',choise_socnetwork, 2) then
            cfg.config.socnetwork = choise_socnetwork.v
            inicfg.save(cfg, 'agesilay_notf.ini')
        end
        imgui.PushItemWidth(200)
        if imgui.InputText(u8(choise_socnetwork.v == 1 and 'Введите VK ID' or 'Введите Chat ID'), (choise_socnetwork.v == 1 and user_id or chat_id)) then
            if choise_socnetwork.v == 1 then 
                cfg.config.user_id = user_id.v
            else
                cfg.config.chat_id = chat_id.v
            end
            inicfg.save(cfg, 'agesilay_notf.ini') 
        end
        imgui.Separator()
        if imgui.Checkbox(u8'Я из Украины', Ukraine) then cfg.config.ukraine = Ukraine.v; inicfg.save(cfg, 'agesilay_notf.ini') end
        if imgui.Button(u8'Тестовое сообщение') then
            local _, pID = sampGetPlayerIdByCharHandle(playerPed)
            local name = sampGetPlayerNickname(pID)
            local testmessage = name.. '[' ..pID.. '] вызвал тестовое сообщение.'
            local msg_responde = (choise_socnetwork.v == 1 and user_id.v or chat_id.v)
            if msg_responde ~= '' then
                sampAddChatMessage('[Отправлено в ' ..(choise_socnetwork.v == 1 and 'ВКонтакте' or 'Telegram').. ']: {ffffff}' ..testmessage, 0x228fff)
            else
                sampAddChatMessage('[Тестовое сообщение]: {ffffff}' ..testmessage, 0x228fff)
            end
            lua_thread.create(function()
                tmsg = true
                sendMessageLeader(testmessage.. '\n<' ..thisScript().version.. '> Принял: ' ..invite.. ' человек, квесты: ' ..quest.. '.')
                wait(500)
                SendMessageDeputy(testmessage)
            end)
        end
        imgui.SameLine()
        if imgui.Button(u8'Перезапустить') then imgui.Process = false; thisScript():reload() end
        imgui.Separator()
        if imgui.Checkbox(u8'Оверлей (статистика в отдельном окне)', overlay) then cfg.config.overlay = overlay.v; inicfg.save(cfg, 'agesilay_notf.ini') end
        imgui.Separator()
        imgui.CenterTextColoredRGB('{228fff}Статистика за сегодня {ffffff}| {FFFF00}' ..os.date('%d/%m/%Y'))
        imgui.BeginChild('##members', imgui.ImVec2(295, 45), true, imgui.WindowFlags.NoScrollbar)
            imgui.Columns(2)
            imgui.SetColumnWidth(-1, 190); imgui.SetCursorPosX(50); imgui.TextColoredRGB('{FF0000}Принято человек'); imgui.NextColumn(); 
            imgui.SetColumnWidth(-1, 105); imgui.CenterColumnTextColoredRGB('{098aed}'..invite); imgui.NextColumn()
            imgui.Separator()
            imgui.SetCursorPosX(75); imgui.TextColoredRGB('{FF0000}Задания'); imgui.NextColumn(); imgui.CenterColumnTextColoredRGB('{098aed}'..quest.. '/8')
        imgui.EndChild()
        if imgui.Button(u8'Сброс статистики') then
            current_day = os.date('%D')
            invite = 0
            quest = 0
            cfg.config.current_day = current_day
            cfg.config.invite = invite
            cfg.config.quest = quest
            inicfg.save(cfg, 'agesilay_notf.ini')
            sendMessage(1, '[Deputy Helper] {ffffff}Статистика успешно сброшена.')
        end
        imgui.SameLine()

        imgui.End()
    end

    if (overlay.v) then
        if ages.v or fmembers.v or offmembers.v then imgui.ShowCursor = true end
        imgui.SetNextWindowPos(imgui.ImVec2((cfg.config.overlay_pos_x),(cfg.config.overlay_pos_y)), imgui.Cond.FirstUseEver)
        imgui.Begin('##begin_overlay', overlay, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize)

        imgui.TextColoredRGB('{ca03fc}Статистика за сегодня:')
        imgui.Separator()
        imgui.SetCursorPosX(10)
        imgui.TextColoredRGB('{ffffff}Принято человек - {098aed}' ..invite)
        imgui.SetCursorPosX(35)
        imgui.TextColoredRGB('{ffffff}Задания - {098aed}' ..quest.. '/8')

        if cfg.config.overlay_pos_x ~= imgui.GetWindowPos().x or cfg.config.overlay_pos_y ~= imgui.GetWindowPos().y then
            imgui.Separator()
            
            if imgui.Button(u8'Сохранить положение', imgui.ImVec2(135,20)) then 
                cfg.config.overlay_pos_x = imgui.GetWindowPos().x
                cfg.config.overlay_pos_y = imgui.GetWindowPos().y
                inicfg.save(cfg, 'agesilay_notf.ini')
                
            end
            if imgui.Button(u8'Вернуть обратно', imgui.ImVec2(135,20)) then 
                imgui.SetWindowPos(imgui.ImVec2(cfg.config.overlay_pos_x, cfg.config.overlay_pos_y))
                
            end
        end
        
        imgui.End()
    end

    if (fmembers.v) then
        ScreenX, ScreenY = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(ScreenX / 2 , ScreenY / 2), imgui.Cond.FirsUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin('##begin_fmembers', fmembers,  imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBringToFrontOnFocus + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize)
        imgui.Spacing()
        imgui.CenterTextColoredRGB('Онлайн семьи: ' ..(checkfmembers and '{FF0000}' or '{FFFF00}').. online)
        imgui.CenterTextColoredRGB('Игроков с VIP | без VIP аккаунта: {00FF00}' .. vip .. ' {ffffff}| {FF0000}' ..novip)
        imgui.Spacing()
        imgui.BeginChild('##members', imgui.ImVec2(415, 260), true, imgui.WindowFlags.NoScrollbar)
            imgui.Columns(6, nil, false)
            imgui.SetColumnWidth(-1, 40); imgui.TextColoredRGB('{228fff}Ранг'); imgui.NextColumn()
            imgui.SetColumnWidth (-1, 170); imgui.TextColoredRGB('{228fff}Никнейм[ID]'); imgui.NextColumn()
            imgui.SetColumnWidth(-1, 40); imgui.TextColoredRGB('{228fff}LVL'); imgui.NextColumn()
            imgui.SetColumnWidth(-1, 40); imgui.TextColoredRGB('{228fff}AFK'); imgui.NextColumn()
            imgui.SetColumnWidth(-1, 80); imgui.TextColoredRGB('{228fff}ВИП'); imgui.NextColumn()
            imgui.SetColumnWidth(-1, 40); imgui.TextColoredRGB('{228fff}Квест'); imgui.NextColumn(); imgui.Separator()
            for k, v in ipairs(members) do
                if v[1] ~= nil then
                    if imgui.Selectable(v[1].. '##' ..k - 1, selects == k - 1, 6) then
                        check_rank.v = v[1]
                        vzID = v[3]
                        vzName = v[2]
                        vzLVL = v[4]
                        selects = k - 1
                        sampSendChat('/id ' ..vzID)
                        check_blacklist = true
                    end
                    imgui.NextColumn()
                    local hexPlayerColor = string.format('{%0.6x}', bit.band(sampGetPlayerColor(v[3]),0xffffff))
                    imgui.TextColoredRGB(hexPlayerColor .. tostring(v[2]..'['..v[3]..']')); imgui.NextColumn()
                    imgui.Text(tostring(v[4])); imgui.NextColumn()
                        local arrayColor_afk = {'{ffffff}', '{FFA07A}', '{FA8072}', '{CD5C5C}'}
                    if tonumber(v[5]) == 0 then
                        color_afk = arrayColor_afk[1]
                    elseif tonumber(v[5]) <= 300 then
                        color_afk = arrayColor_afk[2]
                    elseif tonumber(v[5]) <= 1000 then
                        color_afk = arrayColor_afk[3]
                    elseif tonumber(v[5]) > 1000 then
                        color_afk = arrayColor_afk[4]
                    end
                    imgui.TextColoredRGB(tostring(color_afk .. v[5])); imgui.NextColumn()
                    imgui.TextColoredRGB(tostring(strVips:find(v[2]) and '{00FF00}Имеется' or '{FF0000}Не имеется')); imgui.NextColumn()
                    for i = 1, 8 do
                        local ia = i-1
                        local color_quest = {'{FF0000}', '{B22222}', '{DC143C}', '{EEE8AA}', '{F0E68C}', '{FFD700}', '{ADFF2F}', '{00FF00}'}
                        if tonumber(v[6]) == ia then
                            imgui.TextColoredRGB(color_quest[i] .. tostring(v[6]) .. '/8')
                        end
                    end; imgui.NextColumn(); imgui.Separator()
                end
            end
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild('##infoplayer', imgui.ImVec2(200, 260), true)
            if selects then
                local hexPlayerColor = string.format('{%0.6x}', bit.band(sampGetPlayerColor(vzID),0xffffff))
                imgui.CenterTextColoredRGB('{228fff}Информация об игроке')
                imgui.BeginChild('##information', imgui.ImVec2(190,90), true)
                    imgui.Columns(2)
                    imgui.SetColumnWidth(-1, 60); imgui.TextColoredRGB('{FFFF00}Никнейм'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.Text(vzName); imgui.NextColumn()
                    imgui.Separator()
                    imgui.TextColoredRGB('{FFFF00}Фракция'); imgui.NextColumn()
                    imgui.TextColoredRGB(hexPlayerColor .. sampGetPlayerOrganisation(vzID)); imgui.NextColumn()
                    imgui.Separator()
                    imgui.TextColoredRGB('{FFFF00}UID|PING'); imgui.NextColumn() 
                    imgui.TextColoredRGB((info_blacklist or 'None') .. '{ffffff} | ' ..tostring(sampGetPlayerPing(vzID))); imgui.NextColumn()
                    imgui.Separator()
                    imgui.TextColoredRGB('{FFFF00}Platform'); imgui.NextColumn()
                    imgui.TextColoredRGB((info_platform or 'None')); imgui.NextColumn()
                imgui.EndChild()
                for i = 1, 10 do
                    if imgui.RadioButton(i.. '##' ..i, check_rank, i) then
                        sampSendChat('/setfrank '..vzID..' '..check_rank.v)
                        sampSendChat('/fmembers')
                    end
                    if i ~= 5 and i ~= 10 then imgui.SameLine() end
                end
                if imgui.Button(u8'Выдать мут',imgui.ImVec2(190,20)) then
                    imgui.OpenPopup(u8'Выбор мута')
                end
                if imgui.Button(u8'Снять мут',imgui.ImVec2(190,20)) then
                    sampSendChat('/famunmute '..vzID)
                end
                if imgui.Button(u8'Выгнать из семьи',imgui.ImVec2(190,20)) then
                    imgui.OpenPopup(u8'Выбор увольнения')
                end
                if imgui.Button(u8'Скопировать ник',imgui.ImVec2(190,20)) then
                    setClipboardText(vzName) 
                    sendMessage(1, '[Deputy Helper] {FFFFFF}Ник игрока {228fff}'.. vzName ..'['..vzID..']{ffffff} скопирован в буфер обмена.')
                    addOneOffSound(0.0, 0.0, 0.0, 1054)
                end

                if imgui.BeginPopupModal(u8'Выбор увольнения', _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar +  imgui.WindowFlags.AlwaysAutoResize) then
                    imgui.CenterTextColoredRGB('{228fff}Выберите причину увольнения')
                    imgui.Spacing()
                    imgui.BeginChild('##choise_mute', imgui.ImVec2(200,100), true)
                        for k,v in pairs({
                            'Оскорбление', 'Упоминание родных', 'Пропаганда', 'Неадекват' 
                        }) do
                            if imgui.Button(u8(v), imgui.ImVec2(192,20)) then
                                local vzUID = info_blacklist:gsub('{......}','')
                                sampSendChat('/famuninvite ' ..vzID.. ' ' ..v.. ' (UID: ' ..vzUID.. ')')
                                selects = nil
                                imgui.CloseCurrentPopup()
                            end
                        end
                    imgui.EndChild()
                    imgui.Spacing()
                    if imgui.Button(u8'Ввести свою причину',imgui.ImVec2(200,20)) then
                        unvpopup = true
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Отмена',imgui.ImVec2(200,20)) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end

                if imgui.BeginPopupModal(u8'Выбор мута', _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar +  imgui.WindowFlags.AlwaysAutoResize) then
                    imgui.CenterTextColoredRGB('{228fff}Выберите причину мута')
                    imgui.Spacing()
                    imgui.BeginChild('##choise_mute', imgui.ImVec2(200,197), true)
                        for k,v in pairs({
                            ['Флуд'] = 10,
                            ['Капс'] = 10,
                            ['Нерациональное исп.симв.'] = 10,
                            ['Промежуток рекламы 3 мин.'] = 30,
                            ['Оскорбление'] = 60,
                            ['Неадекват'] = 100,
                            ['Провокация конфликта'] = 30,
                            ['Сторонняя реклама'] = 60,
                        }) do
                            if imgui.Button(u8(k), imgui.ImVec2(192,20)) then
                                sampSendChat('/fammute ' ..vzID.. ' ' ..v.. ' ' ..k)
                                imgui.CloseCurrentPopup()
                            end
                        end
                    imgui.EndChild()
                    imgui.Spacing()
                    if imgui.Button(u8'Ввести свою причину',imgui.ImVec2(200,20)) then
                        mutepopup = true
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Отмена',imgui.ImVec2(200,20)) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end

                if mutepopup then imgui.OpenPopup(u8'Мут'); mutepopup = false end
                if unvpopup then imgui.OpenPopup(u8'Уволить'); unvpopup = false end

                if imgui.BeginPopupModal(u8'Мут', _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar +  imgui.WindowFlags.AlwaysAutoResize) then
                    imgui.SameLine(70)
                    imgui.TextDisabled(u8'Введите причину мута и время')
                    imgui.PushItemWidth(240)
                    if imgui.InputText(u8'##123', setmute, imgui.InputTextFlags.EnterReturnsTrue) then
                        if setmute.v ~= '' and setmute.v ~= nil and settime.v ~= '' and settime.v ~= nil then
                            sampSendChat('/fammute '..vzID..' '..settime.v.. ' ' ..u8:decode(setmute.v))
                            setmute.v = ''
                            settime.v = ''
                            imgui.CloseCurrentPopup()
                        else
                            sendMessage(1, '[Deputy Helper] {FFFFFF}Заполните все поля или закройте выдачу мута!')
                        end
                    end
                    imgui.SameLine()
                    imgui.PushItemWidth(50)
                    if imgui.InputText(u8'##12333', settime, imgui.InputTextFlags.EnterReturnsTrue) then
                        if setmute.v ~= '' and setmute.v ~= nil and settime.v ~= '' and settime.v ~= nil then
                            sampSendChat('/fammute '..vzID..' '..settime.v.. ' ' ..u8:decode(setmute.v))
                            setmute.v = ''
                            settime.v = ''
                            imgui.CloseCurrentPopup()
                        else
                            sendMessage(1, '[Deputy Helper] {FFFFFF}Заполните все поля или закройте выдачу мута!')
                        end
                    end
                    imgui.NewLine()
                    if imgui.Button(u8'Выдать мут',imgui.ImVec2(300,25)) then
                        if setmute.v ~= '' and setmute.v ~= nil and settime.v ~= '' and settime.v ~= nil then
                            sampSendChat('/fammute '..vzID..' '..settime.v.. ' ' ..u8:decode(setmute.v))
                            setmute.v = ''
                            settime.v = ''
                            imgui.CloseCurrentPopup()
                        else
                            sendMessage(1, '[Deputy Helper] {FFFFFF}Заполните все поля или закройте выдачу мута!')
                        end
                    end
                    if imgui.Button(u8'Отмена',imgui.ImVec2(300,25)) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end
                
                if imgui.BeginPopupModal(u8'Уволить', _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar +  imgui.WindowFlags.AlwaysAutoResize) then
                    imgui.SameLine(80)
                    imgui.TextDisabled(u8'Введите причину увольнения')
                    imgui.PushItemWidth(300)
                    if imgui.InputText(u8'##123', uninvite, imgui.InputTextFlags.EnterReturnsTrue) then
                        if uninvite.v ~= '' and uninvite.v ~= nil then
                            local vzUID = info_blacklist:gsub('{......}','')
                            sampSendChat('/famuninvite '..vzID..' '..u8:decode(uninvite.v).. ' (UID: ' ..vzUID.. ')')
                            uninvite.v = ''
                            selects = nil
                            imgui.CloseCurrentPopup()
                        else
                            sendMessage(1, '[Deputy Helper] {FFFFFF}Введите причину увольнения!')
                        end
                    end
                    imgui.NewLine()
                    if imgui.Button(u8'Уволить',imgui.ImVec2(300,25)) then
                        if uninvite.v ~= '' and uninvite.v ~= nil then
                            local vzUID = info_blacklist:gsub('{......}','')
                            sampSendChat('/famuninvite '..vzID..' '..u8:decode(uninvite.v).. ' (UID: ' ..vzUID.. ')')
                            uninvite.v = ''
                            selects = nil
                            imgui.CloseCurrentPopup()
                        else
                            sendMessage(1, '[Deputy Helper] {FFFFFF}Введите причину увольнения!')
                        end
                    end
                    if imgui.Button(u8'Отмена',imgui.ImVec2(300,25)) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end
            else
                imgui.SetCursorPosY(110)
                imgui.CenterTextColoredRGB('{808080}Выберите игрока из списка.')
            end
        imgui.EndChild()

        imgui.AlignTextToFramePadding()
        imgui.TextColoredRGB('Поиск игрока: '); 
        if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Введите Nick_Name или ID игрока, после нажмите ENTER.')) imgui.EndTooltip() end imgui.NextColumn()
        imgui.SameLine(); imgui.PushItemWidth(150)
        if imgui.InputText('##findname', findname, imgui.InputTextFlags.EnterReturnsTrue) then
            local find = false
            for k,v in ipairs(members) do
                if findname.v:match('%w+_%w+') then
                    if v[2] == findname.v then
                        check_rank.v = v[1]
                        vzName = v[2]
                        vzID = v[3]
                        vzLVL = v[4]
                        selects = k - 1
                        sampSendChat('/id ' ..vzID)
                        check_blacklist = true
                        find = true
                        break
                    end
                elseif findname.v:match('%d+') then
                    if v[3] == findname.v then
                        check_rank.v = v[1]
                        vzName = v[2]
                        vzID = v[3]
                        vzLVL = v[4]
                        selects = k - 1
                        sampSendChat('/id ' ..vzID)
                        check_blacklist = true
                        find = true
                        break
                    end
                else 
                    sendMessage(1, '[Deputy Helper] {ffffff}Некорректно введены данные. Пример: {228fff}Dmitry_Agesilay{ffffff} или {228fff}228')
                    find = true
                    break
                end
            end
            if not find then
                sendMessage(1, '[Deputy Helper] {ffffff}Игрок не находится в семье или он оффлайн.')
            end
            findname.v = ''
        end
        imgui.SameLine()
        if imgui.Button(u8'Обновить список',imgui.ImVec2(170,20)) then
            if check_time < os.time() then
                selects = nil
                sampSendChat('/fmembers')
                check_time = os.time() + 3
                sendMessage(1, '[Deputy Helper] {ffffff}Информация в таблице обновлена!')
            else
                cooldown = check_time - os.time()
                sendMessage(1, '[Deputy Helper] {ffffff}Не так быстро, спортсмен! Повтори попытку через {228fff}'..cooldown..'{ffffff} секунд.')
            end
        end
        imgui.SameLine()
        if imgui.Button(u8'Закрыть',imgui.ImVec2(200,20)) then
            fmembers.v = false; selects = nil
        end
        imgui.End()
    end
    if (offmembers.v) then
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2 , sh / 2), imgui.Cond.FirsUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin('##begin_fmembers', offmembers,  imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBringToFrontOnFocus + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize)
        imgui.Spacing()
        imgui.CenterTextColoredRGB((checkoffmembers and '{FF0000}' or '{D3D3D3}') .. 'Члены семьи (оффлайн)')
        imgui.Spacing()
        imgui.BeginChild('##offmembers', imgui.ImVec2(455, 260), true)
            imgui.Columns(4, nil, false)
            imgui.SetColumnWidth(-1, 160); imgui.TextColoredRGB('{228fff}Никнейм[ID]'); imgui.NextColumn()
            imgui.SetColumnWidth(-1, 40); imgui.TextColoredRGB('{228fff}Ранг'); imgui.NextColumn()
            imgui.SetColumnWidth(-1, 140); imgui.TextColoredRGB('{228fff}Название ранга'); imgui.NextColumn()
            imgui.SetColumnWidth(-1, 110); imgui.TextColoredRGB('{228fff}Последний вход'); imgui.NextColumn(); imgui.Separator()
            local all_offPlayer = 0
            for k, v in ipairs(offmembers) do
                if v[2] ~= nil then
                    if imgui.Checkbox('##' ..k, imbool[k]) then
                        if imbool[k].v then
                            arr_kick[k] = v
                            activeCheckbox = activeCheckbox + 1
                        else
                            arr_kick[k] = nil
                            activeCheckbox = activeCheckbox - 1
                        end
                    end
                    local clrText = '{90EE90}'
                    local day = v[4]:match('(%d+) дней')
                    local numrank = v[2]
                    if day then
                        if v[1] ~= 'Viktor_Agesilay' and v[1] ~= 'Dmitry_Agesilay' and v[1] ~= 'Corrado_Uchida' and v[1] ~= 'Ezio_Agesilay' then
                            for i = 1,8 do
                                local number_day = tonumber(day)
                                for k,v in pairs(cfg.setrank) do
                                    if k:find('rank_' ..i) then
                                        number_cfg_rank = tonumber(v)
                                        break
                                    end
                                end
                                if tonumber(numrank) == tonumber(i) then
                                    if number_cfg_rank ~= 0 and (number_day >= number_cfg_rank) then
                                        all_offPlayer = all_offPlayer + 1
                                        clrText = '{FF0000}'
                                    end
                                end
                            end
                        end
                    end
                    imgui.SameLine(); imgui.TextColoredRGB(clrText ..v[1])
                    imgui.NextColumn()
                    imgui.TextColoredRGB(clrText ..v[2]); imgui.NextColumn()
                    imgui.TextColoredRGB(clrText ..v[3]); imgui.NextColumn()
                    imgui.TextColoredRGB(clrText ..v[4]); imgui.NextColumn()
                end
            end
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild('##settingoff', imgui.ImVec2(200, 260), true)
            imgui.CenterTextColoredRGB('{228FFF}Настройки'); imgui.Separator(); imgui.Spacing()
            imgui.AlignTextToFramePadding(); imgui.Text(u8'1 ранг'); imgui.SameLine(); imgui.PushItemWidth(100)
            if imgui.SliderInt(u8('дней') .. '##rank_1', rank_1, 0, 60) then cfg.setrank.rank_1 = rank_1.v; inicfg.save(cfg, 'fam_helper.ini') end
            imgui.AlignTextToFramePadding(); imgui.Text(u8'2 ранг'); imgui.SameLine(); 
            if imgui.SliderInt(u8('дней') .. '##rank_2', rank_2, 0, 60) then cfg.setrank.rank_2 = rank_2.v; inicfg.save(cfg, 'fam_helper.ini') end
            imgui.AlignTextToFramePadding(); imgui.Text(u8'3 ранг'); imgui.SameLine(); 
            if imgui.SliderInt(u8('дней') .. '##rank_3', rank_3, 0, 60) then cfg.setrank.rank_3 = rank_3.v; inicfg.save(cfg, 'fam_helper.ini') end
            imgui.AlignTextToFramePadding(); imgui.Text(u8'4 ранг'); imgui.SameLine(); 
            if imgui.SliderInt(u8('дней') .. '##rank_4', rank_4, 0, 60) then cfg.setrank.rank_4 = rank_4.v; inicfg.save(cfg, 'fam_helper.ini') end
            imgui.AlignTextToFramePadding(); imgui.Text(u8'5 ранг'); imgui.SameLine(); 
            if imgui.SliderInt(u8('дней') .. '##rank_5', rank_5, 0, 60) then cfg.setrank.rank_5 = rank_5.v; inicfg.save(cfg, 'fam_helper.ini') end
            imgui.AlignTextToFramePadding(); imgui.Text(u8'6 ранг'); imgui.SameLine(); 
            if imgui.SliderInt(u8('дней') .. '##rank_6', rank_6, 0, 60) then cfg.setrank.rank_6 = rank_6.v; inicfg.save(cfg, 'fam_helper.ini') end
            imgui.AlignTextToFramePadding(); imgui.Text(u8'7 ранг'); imgui.SameLine(); 
            if imgui.SliderInt(u8('дней') .. '##rank_7', rank_7, 0, 60) then cfg.setrank.rank_7 = rank_7.v; inicfg.save(cfg, 'fam_helper.ini') end
            imgui.AlignTextToFramePadding(); imgui.Text(u8'8 ранг'); imgui.SameLine(); 
            if imgui.SliderInt(u8('дней') .. '##rank_8', rank_8, 0, 60) then cfg.setrank.rank_8 = rank_8.v; inicfg.save(cfg, 'fam_helper.ini') end
            imgui.Separator(); imgui.Spacing(); imgui.CenterTextColoredRGB((all_offPlayer ~= 0 and '{D3D3D3}Можно кикнуть {FFFF00}' ..all_offPlayer.. '{D3D3D3} игроков' or '{228B22}Никого кикать не нужно'))
        imgui.EndChild()
        imgui.Spacing()
        if imgui.Button(u8'Кикнуть (' ..activeCheckbox..')', imgui.ImVec2(112.5,20)) then
            if not checkoffmembers then
                if activeCheckbox > 0 then
                    imgui.OpenPopup(u8'Кикнуть')
                else
                    sendMessage(1, '[Deputy Helper] {FF0000}Ошибка! {FFFFFF}Отметьте в списке людей, которых необходимо кикнуть!')
                end
            else
                sendMessage(1, '[Deputy Helper] {FF0000}Ошибка! {FFFFFF}Невозможно выполнить это действие, пока обновляется список!')
            end
        end
        imgui.SameLine()
        imgui.PushItemWidth(120)
        imgui.Text(u8'Задержка (сек.)'); imgui.SameLine()
        imgui.SliderInt('##wait_kick', wait_kick, 10, 20); imgui.SameLine()
        if imgui.Button(u8'Обновить', imgui.ImVec2(113,20)) then
            if not checkoffmembers then
                lua_thread.create(function()
                    sampSendChat('/fammenu'); wait(100); sampSendClickTextdraw(2070); checkoffmembers = true
                end)
            else
                sendMessage(1, '[Deputy Helper] {FF0000}Ошибка! {FFFFFF}Невозможно выполнить это действие, пока обновляется список!')
            end
        end
        imgui.SameLine()
        if imgui.Button(u8'Закрыть', imgui.ImVec2(200,20)) then
            imguiclose = true
            checkoffmembers = false
            offmembers.v = false
        end
        imgui.Spacing()

        if imgui.BeginPopupModal(u8'Кикнуть' , _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar +  imgui.WindowFlags.AlwaysAutoResize) then
            imgui.CenterTextColoredRGB('{FF0000}Внимание!')
            imgui.CenterTextColoredRGB('Вы собираетесь кикнуть следующих игроков:')
            imgui.BeginChild('##offmembers1', imgui.ImVec2(405, 260), true)
                imgui.Columns(4, nil, false)
                imgui.SetColumnWidth(-1, 130); imgui.TextColoredRGB('{228fff}Никнейм[ID]'); imgui.NextColumn()
                imgui.SetColumnWidth(-1, 40); imgui.TextColoredRGB('{228fff}Ранг'); imgui.NextColumn()
                imgui.SetColumnWidth(-1, 120); imgui.TextColoredRGB('{228fff}Название ранга'); imgui.NextColumn()
                imgui.SetColumnWidth(-1, 110); imgui.TextColoredRGB('{228fff}Последний вход'); imgui.NextColumn(); imgui.Separator()
                for k,v in pairs(arr_kick) do
                    if v[1] ~= nil then
                        imgui.TextColoredRGB(v[1]); imgui.NextColumn()
                        imgui.TextColoredRGB(v[2]); imgui.NextColumn()
                        imgui.TextColoredRGB(v[3]); imgui.NextColumn()
                        imgui.TextColoredRGB(v[4]); imgui.NextColumn(); imgui.Separator()
                    end
                end
            imgui.EndChild()
            if imgui.Button(u8'Продолжить', imgui.ImVec2(200,30)) then
                offmembers.v = false
                for i = 1,500 do
                    imbool[i] = imgui.ImBool(false)
                end
                active_kickOffPlayer = true
                offkickplayer:run()
                imgui.CloseCurrentPopup()
            end
            imgui.SameLine()
            if imgui.Button(u8'Отмена', imgui.ImVec2(200,30)) then
                for i = 1,500 do
                    imbool[i] = imgui.ImBool(false)
                end
                arr_kick = {}
                activeCheckbox = 0
                imgui.CloseCurrentPopup()
            end
            imgui.EndPopup()
        end

        imgui.End()
    end
end

function sendMessage(mode, msg)
    if mode == 1 then
        sampAddChatMessage(msg, 0xBA55D3)
    else
        sampfuncsLog('{BA55D3}[' ..os.date('%H:%M:%S').. '] {FFFFFF}' .. msg)
    end
end

function imgui.CenterTextColoredRGB(text)
    local width = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local textsize = w:gsub('{.-}', '')
            local text_width = imgui.CalcTextSize(u8(textsize))
            imgui.SetCursorPosX( width / 2 - text_width .x / 2 )
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end

    render_text(text)
end

function imgui.CenterColumnTextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else 
                imgui.Text(u8(w)) 
            end
        end
    end
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2 + 22)) - imgui.CalcTextSize(text).x / 2)
    render_text(text)
end

function onScriptTerminate(LuaScript, quitGame)
    if LuaScript == thisScript() then
        if imgui then imgui.ShowCursor = false; showCursor(false) end
    end
end

function checkServer(ip)
	for k, v in pairs({
			['Phoenix'] 	= '185.169.134.3',
			['Tucson'] 		= '185.169.134.4',
			['Scottdale']	= '185.169.134.43',
			['Chandler'] 	= '185.169.134.44', 
			['Brainburg'] 	= '185.169.134.45',
			['Saint Rose'] 	= '185.169.134.5',
			['Mesa'] 		= '185.169.134.59',
			['Red Rock'] 	= '185.169.134.61',
			['Yuma'] 		= '185.169.134.107',
			['Surprise'] 	= '185.169.134.109',
			['Prescott'] 	= '185.169.134.166',
			['Glendale'] 	= '185.169.134.171',
			['Kingman'] 	= '185.169.134.172',
			['Winslow'] 	= '185.169.134.173',
			['Payson'] 		= '185.169.134.174',
			['Gilbert']		= '80.66.82.191'
		}) do
		if v == ip then 
			return true, k
		end
	end
	return false
end

-- // FUNCTION FROM VK_REQUEST BY ANIKI //
function threadHandle(runner, url, args, resolve, reject) -- обработка effil потока без блокировок
	local t = runner(url, args)
	local r = t:get(0)
	while not r do
		r = t:get(0)
		wait(0)
	end
	local status = t:status()
	if status == 'completed' then
		local ok, result = r[1], r[2]
		if ok then resolve(result) else reject(result) end
	elseif err then
		reject(err)
	elseif status == 'canceled' then
		reject(status)
	end
	t:cancel(0)
end

function requestRunner() -- создание effil потока с функцией https запроса
	return effil.thread(function(u, a)
		local https = require 'ssl.https'
		local ok, result = pcall(https.request, u, a)
		if ok then
			return {true, result}
		else
			return {false, result}
		end
	end)
end

function async_http_request(url, args, resolve, reject)
	local runner = requestRunner()
	if not reject then reject = function() end end
	lua_thread.create(function()
		threadHandle(runner, url, args, resolve, reject)
	end)
end

function char_to_hex(str)
	return string.format("%%%02X", string.byte(str))
end

function url_encode(str)
	if cfg.config.ukraine then
		local str = str:gsub(' ', '%+')	
		local str = str:gsub('\n', '%%0A')
		return str
	else
		local str = string.gsub(str, "\\", "\\")
		local str = string.gsub(str, "([^%w])", char_to_hex)
		return str
	end
end

math.randomseed(os.time())

function sendMessageLeader(msg)
	local pID = select(2, sampGetPlayerIdByCharHandle(playerPed))
    local name = sampGetPlayerNickname(pID)
	msg = msg:gsub('{......}', '')
	msg = '[Сообщение от ' ..name.. '(' ..pID..')]:\n' ..msg
	msg = u8(msg)
	msg = url_encode(msg)
	local rnd = math.random(-2147483648, 2147483647)
    if cfg.config.ukraine then
        https.request('https://api.telegram.org/bot1967806703:AAEJyg7NxAHDqhKp5_VPoCxaf3lxHR9tq90/sendMessage?chat_id=1121552541&text='..url_encode(msg))
    else
        async_http_request('https://api.vk.com/method/messages.send', 'peer_id=189170595&random_id=' .. rnd .. '&message=' .. msg .. '&access_token=' .. access_token .. '&v=5.131',
        function (result)
            if tmsg then
                sendMessage(1, '[Deputy Helper] {FFFFFF}Тестовое сообщение успешно отправлено лидеру.')
                tmsg = false
                return
            end
            local t = decodeJson(result)
            if not t then
                print(result)
                return
            end
            if t.error then
                print(result)
                sendMessage(1, '[Deputy Helper] {FF0000}Ошибка! {ffffff}Код: {228fff}' .. t.error.error_code .. ' {ffffff}Причина: {228fff}' .. t.error.error_msg)
                return
            end
        end)
    end
end

function apply_custom_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowRounding = 10
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ChildWindowRounding = 2.0
    style.FrameRounding = 3
    style.ItemSpacing = imgui.ImVec2(5.0, 4.0)
    style.ScrollbarSize = 5.0
    style.ScrollbarRounding = 0
    style.GrabMinSize = 8.0
    style.GrabRounding = 1.0
    style.WindowPadding = imgui.ImVec2(4.0, 4.0)
    style.FramePadding = imgui.ImVec2(3.5, 3.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00);
    colors[clr.TextDisabled]           = ImVec4(0.60, 0.60, 0.60, 1.00);
    colors[clr.WindowBg]               = ImVec4(0.14, 0.12, 0.16, 1.00);
    colors[clr.ChildWindowBg]          = ImVec4(0.30, 0.20, 0.39, 0.00);
    colors[clr.PopupBg]                = ImVec4(0.05, 0.05, 0.10, 0.90);
    colors[clr.Border]                 = ImVec4(0.89, 0.85, 0.92, 0.30);
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00);
    colors[clr.FrameBg]                = ImVec4(0.30, 0.20, 0.39, 1.00);
    colors[clr.FrameBgHovered]         = ImVec4(0.41, 0.19, 0.63, 0.68);
    colors[clr.FrameBgActive]          = ImVec4(0.41, 0.19, 0.63, 0.68);
    colors[clr.TitleBg]                = ImVec4(0.41, 0.19, 0.63, 0.45);
    colors[clr.TitleBgActive]          = ImVec4(0.41, 0.19, 0.63, 0.78);
    colors[clr.TitleBgCollapsed]       = ImVec4(0.41, 0.19, 0.63, 0.35);
    colors[clr.MenuBarBg]              = ImVec4(0.30, 0.20, 0.39, 0.57);
    colors[clr.ScrollbarBg]            = ImVec4(0.30, 0.20, 0.39, 1.00);
    colors[clr.ScrollbarGrab]          = ImVec4(0.41, 0.19, 0.63, 0.31);
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.19, 0.63, 0.78);
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.ComboBg]                = ImVec4(0.30, 0.20, 0.39, 1.00);
    colors[clr.CheckMark]              = ImVec4(0.56, 0.61, 1.00, 1.00);
    colors[clr.SliderGrab]             = ImVec4(0.41, 0.19, 0.63, 0.24);
    colors[clr.SliderGrabActive]       = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.Button]                 = ImVec4(0.41, 0.19, 0.63, 0.44);
    colors[clr.ButtonHovered]          = ImVec4(0.34, 0.16, 0.52, 0.86);
    colors[clr.ButtonActive]           = ImVec4(0.64, 0.33, 0.94, 1.00);
    colors[clr.Header]                 = ImVec4(0.41, 0.19, 0.63, 0.76);
    colors[clr.HeaderHovered]          = ImVec4(0.27, 0.12, 0.41, 0.86);
    colors[clr.HeaderActive]           = ImVec4(0.49, 0.23, 0.75, 1.00);
    colors[clr.Separator]              = ImVec4(0.50, 0.50, 0.50, 1.00);
    colors[clr.SeparatorHovered]       = ImVec4(0.60, 0.60, 0.70, 1.00);
    colors[clr.SeparatorActive]        = ImVec4(0.70, 0.70, 0.90, 1.00);
    colors[clr.ResizeGrip]             = ImVec4(0.41, 0.19, 0.63, 0.20);
    colors[clr.ResizeGripHovered]      = ImVec4(0.48, 0.31, 0.65, 0.78);
    colors[clr.ResizeGripActive]       = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.CloseButton]            = ImVec4(1.00, 1.00, 1.00, 0.75);
    colors[clr.CloseButtonHovered]     = ImVec4(0.88, 0.74, 1.00, 0.59);
    colors[clr.CloseButtonActive]      = ImVec4(0.88, 0.85, 0.92, 1.00);
    colors[clr.PlotLines]              = ImVec4(0.89, 0.85, 0.92, 0.63);
    colors[clr.PlotLinesHovered]       = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.PlotHistogram]          = ImVec4(0.89, 0.85, 0.92, 0.63);
    colors[clr.PlotHistogramHovered]   = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.TextSelectedBg]         = ImVec4(0.41, 0.19, 0.63, 0.43);
    colors[clr.ModalWindowDarkening]   = ImVec4(0.20, 0.20, 0.20, 0.35);
end
apply_custom_style()