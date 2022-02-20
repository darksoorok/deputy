script_name('Agesilay Notification')
script_author('S&D Scripts')
script_description('Sends messages to the family leader for job reporting.')
script_dependencies('events, ssl.https, inicfg, imgui, memory, vkeys, fAwesome5, effil')
script_version('2.1')
script_version_number(21)

local sampev    =   require 'lib.samp.events'
local https     =   require 'ssl.https'
local encoding  =   require 'encoding'
local imgui     =   require 'imgui'
local inicfg    =   require 'inicfg'
local keys      =   require 'vkeys'
local memory    =   require 'memory'

local l_fa, fa       = pcall(require, 'fAwesome5')
local l_effil, effil = pcall(require, 'effil')

require 'lib.moonloader'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local cfg = inicfg.load({
	config = {
        cmd = 'deputy',
        socnetwork = 1,
        chat_id = '',
        user_id = '',
        text_invite = 'Welcome',
        leader_vk_id = 189170595,
        leader_tg_id = 1121552541,
        token_vk = '15c68b42cbf7c09a141c924adafbc7da0e5b85544c09d2827cf03d80fb8830aed43118e0dbeab212483cc',
        token_tg = '1967806703:AAFJx1ueWWixrhN9nxUEGvz_I5LsiZKS1e4',
        current_day = os.date('%D'),
        invite = 0,
        quest = 0,
        invite_week = 0,
        quest_week = 0,
        number_day = os.date('%w'),
        overlay = false,
        overlay_pos_x = 200,
        overlay_pos_y = 200,
        ukraine = false,
        colorFAMchat = 1190680180,
        colorALchat = 1186513337
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

local cursorEnabled = true
local cmd = imgui.ImBuffer(u8(cfg.config.cmd), 256)
local settings = {}
local invite = cfg.config.invite
local quest = cfg.config.quest
local invite_week = cfg.config.invite_week
local quest_week = cfg.config.quest_week
local current_day = cfg.config.current_day
local number_day = cfg.config.number_day
local checkvip = true
local famchat = {}
local members = {}
local offmembers = {}
local check_time = os.time()
local premium = {}
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
local active_offmembers = false
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
local colorFAMchat = imgui.ImFloat4(imgui.ImColor(cfg.config.colorFAMchat):GetFloat4())
local colorALchat = imgui.ImFloat4(imgui.ImColor(cfg.config.colorALchat):GetFloat4())

local offmembers = imgui.ImBool(false)
local sw, sh = getScreenResolution()
local user_id = imgui.ImBuffer(u8(cfg.config.user_id), 256)
local chat_id = imgui.ImBuffer(u8(cfg.config.chat_id), 256)
local text_invite = imgui.ImBuffer(u8(cfg.config.text_invite), 256)
local leader_vk_id = imgui.ImBuffer(u8(cfg.config.leader_vk_id), 256)
local leader_tg_id = imgui.ImBuffer(u8(cfg.config.leader_tg_id), 256)
local token_vk = imgui.ImBuffer(u8(cfg.config.token_vk), 256)
local token_tg = imgui.ImBuffer(u8(cfg.config.token_tg), 256)
local show_token_vk = imgui.ImBool(false)
local show_token_tg = imgui.ImBool(false)
local famchat_enter = imgui.ImBuffer('', 256)
local windowSizeX = 622

if not doesFileExist('moonloader/config/agesilay_notf.ini') then inicfg.save(cfg, 'agesilay_notf.ini') end
local fa_font = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
local fsClock = nil

function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig() -- to use 'imgui.ImFontConfig.new()' on error
        font_config.MergeMode = true
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 12.0, font_config, fa_glyph_ranges)
    end
    if fsClock == nil then
        fsClock = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14)  .. '\\trebucbd.ttf', 33.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
end

local offkickplayer = lua_thread.create_suspended(function()
    while active_kickOffPlayer do wait(0)
        local ix = activeCheckbox
        sendMessage(1, '[Deputy Helper] {FFFF00}Внимание! {FFFFFF}Сейчас будет произведён кик игроков в оффлайне.')
        wait(10)
        if ix > 1 then
            sendMessage(1, '[Deputy Helper] {FF0000}[ ! ] {D3D3D3}Кик игроков займёт примерно {228fff}' ..wait_kick.v * activeCheckbox.. ' {D3D3D3}cекунд!')
        end
        for k,v in pairs(arr_kick) do
            if v[1] ~= nil then
                ix = ix - 1
                sampSendChat('/famoffkick ' ..v[1]); wait(150)
                wait((ix > 0 and (wait_kick.v * 1000) or 1000))
            end
        end
        if activeCheckbox == 1 then
            sendMessage(1, '[Deputy Helper] {FFFFFF}Был кикнут {228FFF}один{FFFFFF} игрок в оффлайне.')
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

function downloadedLibs(link, path, name)
    downloadUrlToFile(link, path, function(id, status, p1, p2)
        if status == 6 then
            lua_thread.create(function()
                sendMessage(2, '{FF8C00}File {FF0000}"' ..name.. '"{FF8C00} downloaded successfully!')
                wait(300)
                thisScript():reload()
            end)
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

    if not l_effil then
        downloadedLibs('https://raw.githubusercontent.com/darksoorok/deputy/main/libs/effil.lua', getWorkingDirectory() .. '\\lib\\effil.lua', 'effil.lua')
	end
    if not doesFileExist(getWorkingDirectory() .. '\\resource\\fonts\\fa-solid-900.ttf') then
        downloadedLibs('https://raw.githubusercontent.com/darksoorok/deputy/main/libs/fa-solid-900.ttf', getWorkingDirectory() .. '\\resource\\fonts\\fa-solid-900.ttf', 'fa-solid-900.ttf')
    end
    if not l_fa then
        downloadedLibs('https://raw.githubusercontent.com/darksoorok/deputy/main/libs/fAwesome5.lua', getWorkingDirectory() .. '\\lib\\fAwesome5.lua', 'fAwesome5.lua')
	end


    if memory.tohex(getModuleHandle("samp.dll") + 0xBABE, 10, true ) == "E86D9A0A0083C41C85C0" then
        sampIsLocalPlayerSpawned = function()
            local res, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            return sampGetGamestate() == 3 and res and sampGetPlayerAnimationId(id) ~= 0
        end
    end

    while not sampIsLocalPlayerSpawned() do wait(130) end

    if tonumber(number_day) == 0 then number_day = 7 end
    
    check_update()
    updateBlacklist()
    wait(1000)
    
    print('{ffffff}Скрипт {9ACD32}успешно загружен.{ffffff} Версия скрипта: {ff0000}' ..thisScript().version)
    _, id_deputy = sampGetPlayerIdByCharHandle(playerPed)
    nickname = sampGetPlayerNickname(id_deputy)
    sendMessage(1, '[Deputy Helper] {ffffff}Скрипт запущен и работает {808080}[v '..thisScript().version..']. {ffffff}Меню - {800080}/' ..cmd.v)
    -- // проверка даты
    if not current_day then current_day = os.date('%D') end

    sampRegisterChatCommand(cmd.v, function()
		ages.v = not ages.v
        if ages.v then
            windowSizeX = 622; window_fmembers = true; sampSendChat('/fmembers')
        end
    end)
    sampRegisterChatCommand('fi', faminvite)

    check_premium = true; sampSendChat('/mm')
    showCursor(false)
    if doesFileExist(update_path) then os.remove(update_path) end
    while true do wait(0)
        imgui.Process = ages.v or overlay.v
        imgui.LockPlayer = ages.v
        imgui.ShowCursor = imgui.Process
        if overlay.v then imgui.ShowCursor = false end
        -- close imgui ages.v
        if not ages.v and (window_offmembers or window_fmembers or window_setting or window_famchat) and not checkfmembers and not checkoffmembers then
            window_fmembers, window_offmembers, window_famchat, window_setting = false;
            for i = 1,500 do
                imbool[i] = imgui.ImBool(false)
            end
            arr_kick = {}
            activeCheckbox = 0
            active_offmembers = false
        end
        -- check VIP status
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
                check_premium = false
            end
        end
        -- check current day
        if current_day ~= os.date('%D') then
            wait(3000)
            current_day = os.date('%D')
            number_day = os.date('%w')
            invite = 0
            quest = 0
            cfg.config.current_day = current_day
            cfg.config.invite = invite
            cfg.config.quest = quest
            cfg.config.number_day = number_day
            if tonumber(number_day) == 0 then number_day = 7 end
            inicfg.save(cfg, 'agesilay_notf.ini')
            sendMessage(1, '[Deputy Helper] {ffffff}Скрипт обнулил значения инвайтов и квестов, так как начался новый день.')
            wait(10000)
        end
        -- zp

        if number_day ~= os.date('%w') then
            if tonumber(os.date('%w')) < tonumber(number_day) then
                invite_week = 0
                quest_week = 0
                cfg.config.invite_week = invite_week
                cfg.config.quest_week = quest_week
                sendMessage(1, '[Deputy Helper] {ffffff}Скрипт обнулил значения инвайтов и квестов за неделю, т.к. началась новая.')
            end
            number_day = os.date('%w')
            cfg.config.number_day = number_day
            inicfg.save(cfg, 'agesilay_notf.ini')
        end
        if tonumber(invite_week) >= 20 and tonumber(quest_week) >= 5 then
            sum = 3000000
            if tonumber(invite_week) >= 30 then
                sum = (invite_week > 30 and 5000000 + ((invite_week - 30) * 200000) or 5000000)
            end
        else
            sum = 0
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
        if (wparam == keys.VK_ESCAPE and ages.v) and not isPauseMenuActive() then
            if checkfmembers then
                imguiclose = true
                checkfmembers = false
            end
            if checkoffmembers then
                for i = 1,500 do
                    imbool[i] = imgui.ImBool(false)
                end
                arr_kick = {}
                activeCheckbox = 0
                active_offmembers = false
                window_offmembers = false
                imguiclose = true
                checkoffmembers = false
            end
            consumeWindowMessage(true, false)
            if msg == 0x101 then
                ages.v = false; selects = nil;
            end
        end
        if (wparam == keys.VK_TAB and ages.v) and not isPauseMenuActive() then
            consumeWindowMessage(true, false)
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
        https.request('https://api.vk.com/method/messages.send?v=5.131&message='..encodeUrl(message)..'&user_id='..user_id.v..'&access_token='.. token_vk.v ..'&random_id='..math.random(-2147483648, 2147483647))
    elseif choise_socnetwork.v == 2 and chat_id.v ~= '' then 
        https.request('https://api.telegram.org/bot1967806703:AAFJx1ueWWixrhN9nxUEGvz_I5LsiZKS1e4/sendMessage?chat_id='..chat_id.v..'&text='..encodeUrl(message))
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if id == 722 and style == 2 and check_premium then
        sampSendDialogResponse(id, 1, 10, nil)
        return false
    end
    if text:find('В этой семье никто не состоит или нет оффлайн игроков') then
        lua_thread.create(function()
            wait(300)
            sampSendDialogResponse(id, 0, 0, nil)
            sampCloseCurrentDialogWithButton(0)
            page_off = false
            checkoffmembers = false
        end)
    end
    if imguiclose then
        lua_thread.create(function()
            wait(300)
            sampSendDialogResponse(id, 0, 0, nil)
            sampCloseCurrentDialogWithButton(0)
        end)
        imguiclose = false
        return false
    end
    if id == 2931 and style == 5 then
        if checkoffmembers then
            if not page_off then offmembers = {} end
            local lines = -1
            for line in text:gmatch('[^\r\n]+') do
                if line:find('%{FFFFFF%}([A-z_]+)%s+%((%d+)%)(.+)%s+(%d+%s.+)') then
                    local name, rank, name_rank, day_off = line:match('%{FFFFFF%}([A-z_]+)%s+%((%d+)%)(.+)%s+(%d+%s.+)')
                    table.insert(offmembers,{name, rank, name_rank, day_off})
                    active_offmembers = true
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
    if text:find('%(Ранг%) Ник') and window_fmembers and id == 1488 and style == 5 then
        checkfmembers = true
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
        check_premium = true; sampSendChat('/mm')
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
    if id == 2763 and style == 2 and nalog then sampSendDialogResponse(2763, 1, 9, -1) end
    if id == 15247 and style == 1 and nalog then 
        for v in string.gmatch(text, '[^\n]+') do
            if v:find('Сейчас налог на квартиру составляет') then
                local nalog_money = v:match('Сейчас налог на квартиру составляет {......}%$([%d%.]+){......}%.'):gsub('%.', '')
                lua_thread.create(function()
                    sampSendDialogResponse(15247, 1, nil, nalog_money); wait(100); sampCloseCurrentDialogWithButton(0); sampSendClickTextdraw(65535)
                end)
                break
            end
        end
        nalog = false
    end
end

function sampev.onSendCommand(cmd)
    local id_inv = cmd:match('^/faminvite (%d+)$')
    if id_inv then
        if not sampGetPlayerNickname(id_inv):match('^[A-Z][A-z]+_[A-Z][A-z]+$') then
            local msg_Error = 'Попытка принять игрока с NRP никнеймом: ' .. sampGetPlayerNickname(id_inv).. '[' ..id_inv.. ']!'
            sendMessage(1, '[Deputy Helper] {ffffff}' ..msg_Error)
            sendMessageLeader(msg_Error.. '\n[ ' ..thisScript().version.. ' ] Принял: ' ..invite.. ', квесты: ' ..quest.. '.\n[ $ ] Выплатить: '..formatter(sum .. '$')..'\n#error_invite')
            return false
        end
    end
end
function sampev.onServerMessage(color, text)
    if check_premium then
        local premium_getname = text:match('%d+%.%s(.+)%[%d+%]')
        if premium_getname then
            table.insert(premium, premium_getname)
            return false
        end
    end
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

    local id_uid, level, uid, platform = text:match('%[(%d+)%] %w+_%w+ %| Уровень%: (%d+) %| UID%: (%d+) %|.+packetloss%: %d+%.%d+ %((.+)%)')

    if id_uid and level and uid and check_blacklist then
        updateBlacklist()
        if fi then
            if tonumber(level) >= 3 then
                for k, v in ipairs(blacklist) do
                    if v == tonumber(uid) then
                        sampSendChat('Вы в чёрном списке нашей семьи!')
                        checks_blacklist = true
                        break
                    end
                end
                if not checks_blacklist then
                    arg = id_uid
                    lua_thread.create(function() wait(500); sampSendChat('/faminvite ' ..arg) end)
                   
                end
            else
                sampSendChat('Вы слишком мало проживаете в штате. От 3-х лет приём в семью.')
            end
        else
            for k, v in ipairs(blacklist) do
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
                wait(200)
                sendMessageLeader(my_text.. '\n[ ' ..thisScript().version.. ' ] Принял: ' ..invite.. ', квесты: ' ..quest.. '.\n[ $ ] Выплатить: '..formatter(sum .. '$')..'\n#mute')
                wait(500)
                SendMessageDeputy(my_text)
            end)
        end
    end

    if text:find('%{......%}%[Семья %(Новости%)%] (%w+_%w+)%[(%d+)%]%:%{......%} выгнал из семьи (%w+_%w+)%[(%d+)%]%! Причина%: (.+)') then
        if (names == nickname) then
            lua_thread.create(function()
                local my_text = text:gsub('{......}', '')
                wait(200)
                sendMessageLeader(my_text.. '\n[ ' ..thisScript().version.. ' ] Принял: ' ..invite.. ', квесты: ' ..quest.. '.\n[ $ ] Выплатить: '..formatter(sum .. '$')..'\n#kick')
                wait(500)
                SendMessageDeputy(my_text)
            end)
        end
    end

    if text:find('%[Семья %(Новости%)%] (%w+_%w+)%[(%d+)%]%:%{......%} в оффлайне выгнал игрока (%w+_%w+) из семьи%!') then
        if (names == nickname) then
            lua_thread.create(function()
                wait(1100)
                local my_text = text:gsub('{......}', '')
                wait(200)
                sendMessageLeader(my_text.. '\n[ ' ..thisScript().version.. ' ] Принял: ' ..invite.. ', квесты: ' ..quest.. '.\n[ $ ] Выплатить: '..formatter(sum .. '$')..'\n#offlinekick')
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
                invite_week = invite_week + 1
                cfg.config.invite = invite
                cfg.config.invite_week = invite_week
                inicfg.save(cfg, 'agesilay_notf.ini')
                wait(200)
                sendMessageLeader(my_text.. '\n[ ' ..thisScript().version.. ' ]. Принял: ' ..invite.. ' человек.\n[ $ ] Выплатить: '..formatter(sum .. '$')..'\n#invite')
                wait(500)
                SendMessageDeputy(my_text)
                if text_invite.v then
                    wait(800)
                    sampSendChat('/fam ' ..u8:decode(text_invite.v))
                end   
            end)
        end
    end
    
    if text:find('%{......%}%[Семья %(Новости%)%] %w+_%w+%[%d+%]%:%{......%} выполнил ежедневное задание') then
        if (names == nickname) then
            lua_thread.create(function()
                local my_text = text:gsub('{......}', '')
                quest = quest + 1
                quest_week = quest_week + 1
                cfg.config.quest = quest
                cfg.config.quest_week = quest_week
                inicfg.save(cfg, 'agesilay_notf.ini')
                wait(200)
                sendMessageLeader(my_text.. '\n[ ' ..thisScript().version.. ' ]. Выполнил квестов: ' ..quest.. '\n[ $ ] Выплатить: '..formatter(sum .. '$')..'.\n#quest')
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

    if text:find('%[Семья.*%].+[a-zA-Z_]+%[%d+%]:') then
        table.insert(famchat, '{b9c1b8}[' .. os.date('%H:%M:%S').. '] ' ..text)
        local cR, cG, cB, cA = imgui.ImColor(cfg.config.colorFAMchat):GetRGBA()
        text = text:gsub('%{......%}%[Семья', '%[Семья')
        return { join_argb(cR, cG, cB, cA), text }
    end
    if text:find('%[Новости Семьи%]%{FFFFFF%}.+') then
        table.insert(famchat, '{b9c1b8}[' .. os.date('%H:%M:%S').. '] ' ..text)
        local cR, cG, cB, cA = imgui.ImColor(cfg.config.colorFAMchat):GetRGBA()
        text = text:gsub('%{......%}%[Новости Семьи', '%[Новости Семьи')
        return { join_argb(cR, cG, cB, cA), text }
    end
    if text:find('%[Family.*%]') then
        table.insert(famchat, '{b9c1b8}[' .. os.date('%H:%M:%S').. '] ' ..text)
        local cR, cG, cB, cA = imgui.ImColor(cfg.config.colorFAMchat):GetRGBA()
        text = text:gsub('%]', ']{b9c1b8}', 1)
        return { join_argb(cR, cG, cB, cA), text }
    end

    if text:match('%[Альянс.*%].+[a-zA-Z_]+%[%d+%]: .*') then
        table.insert(famchat, '{b9c1b8}[' .. os.date('%H:%M:%S').. '] ' ..text)
        local cR, cG, cB, cA = imgui.ImColor(cfg.config.colorALchat):GetRGBA()
		text = text:gsub('%]:', ']:{b9c1b8}', 1)
        return { join_argb(cR, cG, cB, cA), text }
    end

end

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
        [2157536819] = 'Армия',
        [2159918525] = 'ТСР',
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
        local ww, wh = windowSizeX + 7, 413
        imgui.SetNextWindowSize(imgui.ImVec2(ww, wh))
        imgui.SetNextWindowPos(imgui.ImVec2((sw-ww)/2, (sh-wh)/2), imgui.Cond.FirstUseEver)
        imgui.Begin('Deputy Helper##ages', ages,  imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize)
        imgui.ColorButton(window_fmembers)
        if imgui.Button(fa.ICON_FA_USER_ALT .. u8' Онлайн', imgui.ImVec2(100,20)) then
            if window_offmembers then
                for i = 1,500 do
                    imbool[i] = imgui.ImBool(false)
                end
                arr_kick = {}
                activeCheckbox = 0
                if checkoffmembers then
                    imguiclose = true
                    checkoffmembers = false
                end
                active_offmembers = false
                window_offmembers = false
            elseif window_famchat then
                windowSizeX = 622
                window_famchat = false
            elseif window_setting then
                window_setting = false
            end
            lua_thread.create(function()
                wait(300); window_fmembers = true; sampSendChat('/fmembers')
            end)
        end
        imgui.PopStyleColor(3)
        imgui.SameLine()
        imgui.ColorButton(window_offmembers)
        if imgui.Button(fa.ICON_FA_USER_ALT_SLASH .. u8' Оффлайн', imgui.ImVec2(100,20)) then
            if window_fmembers then
                selects = nil
                if checkfmembers then
                    imguiclose = true
                    checkfmembers = false
                end
                window_fmembers = false 
            elseif window_setting then
                window_setting = false
            elseif window_famchat then
                windowSizeX = 622
                window_famchat = false
            end
            lua_thread.create(function()
                sampSendChat('/fammenu'); wait(300); sampSendClickTextdraw(2070); checkoffmembers = true; wait(600)
            end)
            window_offmembers = true;
        end
        imgui.PopStyleColor(3)
        imgui.SameLine()
        imgui.ColorButton(window_famchat)
        if imgui.Button(fa.ICON_FA_ENVELOPE_OPEN_TEXT ..u8' Чат', imgui.ImVec2(100,20)) then
            if window_fmembers then
                selects = nil
                if checkfmembers then
                    imguiclose = true
                    checkfmembers = false
                end
                window_fmembers = false
            elseif window_offmembers then
                for i = 1,500 do
                    imbool[i] = imgui.ImBool(false)
                end
                arr_kick = {}
                activeCheckbox = 0
                if checkoffmembers then
                    imguiclose = true
                    checkoffmembers = false
                end
                active_offmembers = false
                window_offmembers = false
            elseif window_setting then
                window_setting = false
            end
            windowSizeX = 862
            window_famchat = true
        end
        imgui.PopStyleColor(3)
        imgui.SameLine()
        imgui.ColorButton(window_setting)
        if imgui.Button(fa.ICON_FA_COG .. u8' Настройки', imgui.ImVec2(100,20)) then
            if window_fmembers then
                selects = nil
                if checkfmembers then
                    imguiclose = true
                    checkfmembers = false
                end
                window_fmembers = false
            elseif window_offmembers then
                for i = 1,500 do
                    imbool[i] = imgui.ImBool(false)
                end
                arr_kick = {}
                activeCheckbox = 0
                if checkoffmembers then
                    imguiclose = true
                    checkoffmembers = false
                end
                active_offmembers = false
                window_offmembers = false
            elseif window_famchat then
                windowSizeX = 622
                window_famchat = false
            end
            window_setting = true 
        end
        imgui.PopStyleColor(3)
        imgui.Separator()
        imgui.BeginChild('##window', imgui.ImVec2(windowSizeX, 332), false, imgui.WindowFlags.NoScrollbar)
            if window_fmembers then
                imgui.Spacing()
                imgui.CenterTextColoredRGB('Онлайн семьи: ' ..(checkfmembers and '{FF0000}' or '{FFFF00}').. (online or '0'))
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
                            if strVips:find(v[2]) then
                                status = '{FFA500}Titan'
                                for m,x in ipairs(premium) do
                                    if x == v[2] then
                                        status = '{FF8C00}Premium'
                                        break
                                    end
                                end
                                imgui.TextColoredRGB(tostring(status))
                            else
                                imgui.TextColoredRGB(tostring(strVips:find(v[2]) and '{00FF00}Имеется' or '{FF0000}Не имеется'))
                            end
                            imgui.NextColumn()
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
                        if imgui.Button(fa.ICON_FA_VOLUME_MUTE .. u8' Выдать мут',imgui.ImVec2(190,20)) then
                            imgui.OpenPopup(u8'Выбор мута')
                        end
                        if imgui.Button(fa.ICON_FA_VOLUME_DOWN .. u8' Снять мут',imgui.ImVec2(190,20)) then
                            sampSendChat('/famunmute '..vzID)
                        end
                        if imgui.Button(fa.ICON_FA_TIRED .. u8' Выгнать из семьи',imgui.ImVec2(190,20)) then
                            imgui.OpenPopup(u8'Выбор увольнения')
                        end
                        if imgui.Button(fa.ICON_FA_COPY .. u8' Скопировать ник',imgui.ImVec2(190,20)) then
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
                if imgui.Button(fa.ICON_FA_SYNC_ALT .. u8' Обновить список',imgui.ImVec2(170,20)) then
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
                if imgui.Button(fa.ICON_FA_TIMES_CIRCLE .. u8' Закрыть', imgui.ImVec2(200,20)) then
                    if checkfmembers then
                        imguiclose = true
                        checkfmembers = false
                    end
                    selects = nil
                    window_fmembers = false
                    ages.v = false
                end
                
            end
            if window_offmembers then
                if active_offmembers then
                    imgui.Spacing()
                    imgui.CenterTextColoredRGB((checkoffmembers and '{FF0000}' or '{D3D3D3}') .. 'Члены семьи (оффлайн)')
                    imgui.Spacing()
                    imgui.BeginChild('##offmembers', imgui.ImVec2(455, 275), true)
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
                                                if (number_cfg_rank) and (number_cfg_rank ~= 0 and (number_day >= number_cfg_rank)) then
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
                    imgui.BeginChild('##settingoff', imgui.ImVec2(160, 275), true)
                        imgui.CenterTextColoredRGB('{228FFF}Настройки'); imgui.Separator(); imgui.Spacing(); imgui.Spacing()
                        imgui.AlignTextToFramePadding(); imgui.Text('   1. '); imgui.SameLine(); imgui.PushItemWidth(100)
                        if imgui.SliderInt('##rank_1', rank_1, 0, 60) then cfg.setrank.rank_1 = rank_1.v; inicfg.save(cfg, 'agesilay_notf.ini') end
                        imgui.AlignTextToFramePadding(); imgui.Text('   2. '); imgui.SameLine(); 
                        if imgui.SliderInt('##rank_2', rank_2, 0, 60) then cfg.setrank.rank_2 = rank_2.v; inicfg.save(cfg, 'agesilay_notf.ini') end
                        imgui.AlignTextToFramePadding(); imgui.Text('   3. '); imgui.SameLine(); 
                        if imgui.SliderInt('##rank_3', rank_3, 0, 60) then cfg.setrank.rank_3 = rank_3.v; inicfg.save(cfg, 'agesilay_notf.ini') end
                        imgui.AlignTextToFramePadding(); imgui.Text('   4. '); imgui.SameLine(); 
                        if imgui.SliderInt('##rank_4', rank_4, 0, 60) then cfg.setrank.rank_4 = rank_4.v; inicfg.save(cfg, 'agesilay_notf.ini') end
                        imgui.AlignTextToFramePadding(); imgui.Text('   5. '); imgui.SameLine(); 
                        if imgui.SliderInt('##rank_5', rank_5, 0, 60) then cfg.setrank.rank_5 = rank_5.v; inicfg.save(cfg, 'agesilay_notf.ini') end
                        imgui.AlignTextToFramePadding(); imgui.Text('   6. '); imgui.SameLine(); 
                        if imgui.SliderInt('##rank_6', rank_6, 0, 60) then cfg.setrank.rank_6 = rank_6.v; inicfg.save(cfg, 'agesilay_notf.ini') end
                        imgui.AlignTextToFramePadding(); imgui.Text('   7. '); imgui.SameLine(); 
                        if imgui.SliderInt('##rank_7', rank_7, 0, 60) then cfg.setrank.rank_7 = rank_7.v; inicfg.save(cfg, 'agesilay_notf.ini') end
                        imgui.AlignTextToFramePadding(); imgui.Text('   8. '); imgui.SameLine(); 
                        if imgui.SliderInt('##rank_8', rank_8, 0, 60) then cfg.setrank.rank_8 = rank_8.v; inicfg.save(cfg, 'agesilay_notf.ini') end
                        imgui.Spacing()
                        imgui.Separator(); imgui.Spacing(); imgui.CenterTextColoredRGB((all_offPlayer ~= 0 and '{D3D3D3}Кикнуть {FFFF00}' ..all_offPlayer.. '{D3D3D3} игроков' or '{228B22}Никого кикать не нужно'))
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
                    imgui.SliderInt('##wait_kick', wait_kick, 5, 20); imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_SYNC_ALT .. u8' Обновить', imgui.ImVec2(113,20)) then
                        if not checkoffmembers then
                            for i = 1,500 do
                                imbool[i] = imgui.ImBool(false)
                            end
                            arr_kick = {}
                            activeCheckbox = 0
                            lua_thread.create(function()
                                sampSendChat('/fammenu'); wait(300); sampSendClickTextdraw(2070); checkoffmembers = true; wait(600)
                            end)
                        else
                            sendMessage(1, '[Deputy Helper] {FF0000}Ошибка! {FFFFFF}Невозможно выполнить это действие, пока обновляется список!')
                        end
                    end
                    imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_TIMES_CIRCLE .. u8' Закрыть', imgui.ImVec2(160,20)) then
                        for i = 1,500 do
                            imbool[i] = imgui.ImBool(false)
                        end
                        arr_kick = {}
                        activeCheckbox = 0
                        active_offmembers = false
                        window_offmembers = false
                        imguiclose = true
                        checkoffmembers = false
                        window_fmembers = true; sampSendChat('/fmembers')
                    end
                    imgui.Spacing()
                else
                    imgui.SetCursorPosY(130)
                    imgui.CenterTextColoredRGB('{FFFF00}Загрузка списка игроков оффлайн')
                    imgui.NewLine()
                    imgui.SetCursorPosX(205)
                    if imgui.Button(fa.ICON_FA_SYNC_ALT .. u8' Перезапустить', imgui.ImVec2(110,20)) then
                        lua_thread.create(function()
                            sampSendChat('/fammenu'); wait(300); sampSendClickTextdraw(2070); checkoffmembers = true; wait(300)
                        end)
                    end
                    imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_TIMES_CIRCLE .. u8' Закрыть', imgui.ImVec2(100,20)) then
                        for i = 1,500 do
                            imbool[i] = imgui.ImBool(false)
                        end
                        arr_kick = {}
                        activeCheckbox = 0
                        if checkoffmembers then
                            imguiclose = true
                            checkoffmembers = false
                        end
                        active_offmembers = false
                        window_offmembers = false
                        window_fmembers = true; sampSendChat('/fmembers')
                    end
                end

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
                    if imgui.Button(fa.ICON_FA_TIRED .. u8' Продолжить', imgui.ImVec2(200,30)) then
                        active_offmembers = false
                        window_offmembers = false
                        for i = 1,500 do
                            imbool[i] = imgui.ImBool(false)
                        end
                        active_kickOffPlayer = true
                        offkickplayer:run()
                        imgui.CloseCurrentPopup()
                        ages.v = false
                    end
                    imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_TIMES_CIRCLE ..u8' Отмена', imgui.ImVec2(200,30)) then
                        for i = 1,500 do
                            imbool[i] = imgui.ImBool(false)
                        end
                        arr_kick = {}
                        activeCheckbox = 0
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end
            end
            if window_famchat then
                imgui.BeginChild('##famchat', imgui.ImVec2(860, 305), true)
                    for k,v in ipairs(famchat) do
                        active_msgfamchat = true
                        imgui.TextColoredRGB(v)
                        imgui.SetScrollHere()
                    end
                    if not active_msgfamchat then
                        imgui.SetCursorPosY(130)
                        imgui.CenterTextColoredRGB('{228FFF}Здесь будут отображаться все сообщения из семейного чата.')
                    end
                imgui.EndChild()
                imgui.PushItemWidth(735)
                if imgui.InputText('##famchat_enter', famchat_enter, imgui.InputTextFlags.EnterReturnsTrue) then
                    if famchat_enter.v ~= '' then
                        local msg_famchat = u8:decode(famchat_enter.v)
                        if tonumber(#msg_famchat) <= 83 then
                            sampSendChat('/fam ' ..msg_famchat)
                            famchat_enter.v = ''
                        else
                            sendMessage(1, '[Deputy Helper] {FF0000}Ошибка! {FFFFFF}Слишком длинное сообщение.')
                        end
                    else
                        sendMessage(1, '[Deputy Helper] {FF0000}Ошибка! {FFFFFF}Введите сообщение.')
                    end
                end
                imgui.SameLine()
                if imgui.Button(fa.ICON_FA_TIMES_CIRCLE .. u8' Закрыть', imgui.ImVec2(120,20)) then
                    windowSizeX = 622
                    window_famchat = false
                    window_fmembers = true; sampSendChat('/fmembers')
                end
            end
            if window_setting then
                if window_fmembers then
                    window_fmembers = false
                end
                if imgui.CollapsingHeader(u8'Уведомления') then
                    imgui.TextColoredRGB('{228B22}Настройки для отправителя')
                    imgui.Separator()
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
                    imgui.PushItemWidth(300)
                    if imgui.InputText(u8(choise_socnetwork.v == 1 and 'VK ID' or 'Chat ID'), (choise_socnetwork.v == 1 and user_id or chat_id)) then
                        if choise_socnetwork.v == 1 then 
                            cfg.config.user_id = user_id.v
                        else
                            cfg.config.chat_id = chat_id.v
                        end
                        inicfg.save(cfg, 'agesilay_notf.ini') 
                    end
                    if imgui.Checkbox(u8'Я из Украины', Ukraine) then cfg.config.ukraine = Ukraine.v; inicfg.save(cfg, 'agesilay_notf.ini') end
                    imgui.Spacing()
                    imgui.TextColoredRGB('{228FFF}Настройки для получателя')
                    imgui.Separator()
                    imgui.TextColoredRGB((cfg.config.ukraine and 'Chat ID от Telegram' or 'VK ID от ВКонтакте')..' лидера семьи')
                    if imgui.InputText('##leader_id', (cfg.config.ukraine and leader_tg_id or leader_vk_id)) then
                        if cfg.config.ukraine then
                            cfg.config.leader_tg_id = leader_tg_id.v
                        else
                            cfg.config.leader_vk_id = leader_vk_id.v
                        end
                        inicfg.save(cfg, 'agesilay_notf.ini')
                    end
                    imgui.TextColoredRGB('Token ВКонтакте')
                    if imgui.InputText('##token_vk', token_vk, show_token_vk.v and 0 or imgui.InputTextFlags.Password) then
                        cfg.config.token_vk = token_vk.v
                        inicfg.save(cfg, 'agesilay_notf.ini')
                    end
                    imgui.SameLine(); imgui.Checkbox('##show_token_vk', show_token_vk)
                    imgui.TextColoredRGB('Token Telegram')
                    if imgui.InputText('##token_tg', token_tg, show_token_tg.v and 0 or imgui.InputTextFlags.Password) then
                        cfg.config.token_tg = token_tg.v
                        inicfg.save(cfg, 'agesilay_notf.ini')
                    end
                    imgui.SameLine(); imgui.Checkbox('##show_token_tg', show_token_tg)

                    if imgui.Button(u8'Отправить тестовое сообщение', imgui.ImVec2(200,20)) then
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
                            wait(200)
                            sendMessageLeader(testmessage.. '\n[ ' ..thisScript().version.. ' ] Принял: ' ..invite.. ', квесты: ' ..quest.. '.\n[ $ ] Выплатить: '..formatter(sum .. '$')..'\n#testmessage')
                            wait(500)
                            SendMessageDeputy(testmessage)
                        end)
                    end

                end
                if imgui.CollapsingHeader(u8'Настройки чата') then
                    if imgui.ColorEdit4(u8'Цвет чата семьи', colorFAMchat, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoAlpha) then
                        local clr = imgui.ImColor.FromFloat4(colorFAMchat.v[1], colorFAMchat.v[2], colorFAMchat.v[3], colorFAMchat.v[4]):GetU32()
                        cfg.config.colorFAMchat = clr
                        inicfg.save(cfg, 'agesilay_notf.ini')
                    end
                    imgui.SameLine()
                    if imgui.Button(u8("Тест##FAMCol"), imgui.ImVec2(50, 20)) then
                        local r, g, b, a = imgui.ImColor(cfg.config.colorFAMchat):GetRGBA()
                        sampAddChatMessage('[Семья] [9] Legatus Legionis | '..nickname..'['..id_deputy..']: {B9C1B8}(( Это сообщение видите только вы! ))', join_rgb(r, g, b))
                    end
                    imgui.SameLine()
                    if imgui.Button(u8("Стандартный##FAMcol"), imgui.ImVec2(90, 20)) then
                        cfg.config.colorFAMchat = 1190680180
                        if inicfg.save(cfg, 'agesilay_notf.ini') then 
                            sendMessage(1, '[Deputy Helper] {FFFFFF}Стандартный цвет чата семьи восстановлен!')
                            colorFAMchat = imgui.ImFloat4(imgui.ImColor(cfg.config.colorFAMchat):GetFloat4())
                        end
                    end
                    if imgui.ColorEdit4(u8'Цвет чата альянса', colorALchat, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoAlpha) then
                        local clr = imgui.ImColor.FromFloat4(colorALchat.v[1], colorALchat.v[2], colorALchat.v[3], colorALchat.v[4]):GetU32()
                        cfg.config.colorALchat = clr
                        inicfg.save(cfg, 'agesilay_notf.ini')
                    end
                    imgui.SameLine()
                    if imgui.Button(u8("Тест##AlCol"), imgui.ImVec2(50, 20)) then
                        local r, g, b, a = imgui.ImColor(cfg.config.colorALchat):GetRGBA()
                        sampAddChatMessage('[Альянс Agesilay] [9] Legatus Legionis | '..nickname..'['..id_deputy..']: {b9c1b8}(( Это сообщение видите только вы! ))', join_rgb(r, g, b))
                    end
                    imgui.SameLine()
                    if imgui.Button(u8("Стандартный##Alcol"), imgui.ImVec2(90, 20)) then
                        cfg.config.colorALchat = 1186513337
                        if inicfg.save(cfg, 'agesilay_notf.ini') then 
                            sendMessage(1, '[Deputy Helper] {FFFFFF}Стандартный цвет чата альянса восстановлен!')
                            colorALchat = imgui.ImFloat4(imgui.ImColor(cfg.config.colorALchat):GetFloat4())
                        end
                    end
                end
                if imgui.CollapsingHeader(u8'Дополнительные настройки') then
                    imgui.Text(u8'Приветствие после инвайта')
                    if imgui.InputText('##text_invite', text_invite) then
                        cfg.config.text_invite = u8:decode(text_invite.v)
                        inicfg.save(cfg, 'agesilay_notf.ini')
                    end
                    imgui.Separator()
                    imgui.Text(u8'Меню скрипта (Написать необходимо без знака /)')
                    if imgui.InputText('##cmd', cmd) then
                        cfg.config.cmd = cmd.v
                        inicfg.save(cfg, 'agesilay_notf.ini')
                    end
                    imgui.Separator()
                    if imgui.Checkbox(u8'Оверлей (статистика в отдельном окне)', overlay) then cfg.config.overlay = overlay.v; inicfg.save(cfg, 'agesilay_notf.ini') end
                end
                if imgui.Button(fa.ICON_FA_CASH_REGISTER .. u8' Оплата фам.налога', imgui.ImVec2(160,20)) then sampSendChat('/fammenu'); sampSendClickTextdraw(2073); nalog = true end
                if imgui.Button(fa.ICON_FA_SYNC_ALT .. u8' Перезапустить', imgui.ImVec2(160,20)) then imgui.Process = false; thisScript():reload() end
                
            end
            imgui.EndChild()
            imgui.Separator()
            imgui.CenterTextColoredRGB('{228FFF}Статистика: {FFFFFF}за сегодня - {FF4500}' ..invite.. ' {696969}/ {63de4e}' ..quest.. ' {696969}| {FFFFFF}за неделю - {FF4500}' ..invite_week.. ' {696969}/{63de4e} ' ..quest_week.. '{FFFFFF}. {FFFF00}Зарплата: {228B22}' ..formatter(sum.. '$'))
        imgui.End()
    end

    if (overlay.v) then
        if ages.v then imgui.ShowCursor = true end
        imgui.SetNextWindowPos(imgui.ImVec2((cfg.config.overlay_pos_x),(cfg.config.overlay_pos_y)), imgui.Cond.FirstUseEver)
        imgui.Begin('##overlay', overlay, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize)
        imgui.PushFont(fsClock)
        imgui.CenterTextColoredRGB('{ca03fc}' .. os.date("%H:%M:%S", os.time()))
        imgui.PopFont()
        imgui.TextColoredRGB('{696969}Статистика за сегодня:')
        imgui.Separator()
        imgui.SetCursorPosX(10)
        imgui.TextColoredRGB('{ffffff}Принято человек - {098aed}' ..invite)
        imgui.SetCursorPosX(35)
        imgui.TextColoredRGB('{ffffff}Задания - {098aed}' ..quest.. ' / 8')

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
        if cursorEnabled then
            showCursor(false)
            cursorEnabled = false
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
			['Gilbert']		= '80.66.82.191',
            ['Show-Low']    = '80.66.82.190',
            ['Casa Grande'] = '80.66.82.188',
            ['Page']        = '80.66.82.168'
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
        https.request('https://api.telegram.org/bot'.. token_tg.v ..'/sendMessage?chat_id='..leader_tg_id.v..'&text='..url_encode(msg))
    else
        async_http_request('https://api.vk.com/method/messages.send', 'peer_id='..leader_vk_id.v..'&random_id=' .. rnd .. '&message=' .. msg .. '&access_token=' .. token_vk.v .. '&v=5.131',
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

function join_rgb(r, g, b)
	return bit.bor(bit.bor(b, bit.lshift(g, 8)), bit.lshift(r, 16))
end

function join_argb(a, r, g, b)
    local argb = b  -- b
    argb = bit.bor(argb, bit.lshift(g, 8))  -- g
    argb = bit.bor(argb, bit.lshift(r, 16)) -- r
    argb = bit.bor(argb, bit.lshift(a, 24)) -- a
    return argb
end

function imgui.ColorButton(style)
    if style then -- Active Button
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImColor(150, 15, 141, 255):GetVec4()) -- изначальный цвет RGBA
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImColor(140, 14, 132, 255):GetVec4()) -- цвет при наведении на кнопку (темнее)
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImColor(179, 20, 168, 255):GetVec4()) -- цвет при нажатии на кнопку (светлее)
    else --NonActive Button
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImColor(105, 29, 100, 255):GetVec4()) -- изначальный цвет RGBA
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImColor(94, 27, 90, 255):GetVec4()) -- цвет при наведении на кнопку (темнее)
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImColor(120, 36, 114, 255):GetVec4()) -- цвет при нажатии на кнопку (светлее)
    end
end

function formatter(n)
	local v1, v2, v3 = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return (tonumber(n) == 0 and 0 or (v1 .. (v2:reverse():gsub('(%d%d%d)','%1.'):reverse()) .. v3))
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
    style.ScrollbarSize = 8.0
    style.ScrollbarRounding = 1.2
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