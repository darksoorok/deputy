script_name('Agesilay Notification')
script_author('S&D Scripts')
script_description('Sends messages to the family leader for job reporting.')
script_dependencies('events, ssl.https, inicfg, imgui')
script_version('1.9.0')
script_version_number(1)

local sampev    =   require 'lib.samp.events'
local https     =   require 'ssl.https'
local encoding  =   require 'encoding'
local imgui     =   require 'imgui'
local inicfg    =   require 'inicfg'
local keys      =   require 'vkeys'
require 'lib.moonloader'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local mainIni = inicfg.load({
	config = {
        socnetwork = 1,
        chat_id = '',
        user_id = '',
        current_day = os.date('%D'),
        invite = 0,
        quest = 0,
        overlay = false,
        overlay_pos_x = 200,
        overlay_pos_y = 200
	}
}, 'agesilay_notf.ini')

local access_token = '15c68b42cbf7c09a141c924adafbc7da0e5b85544c09d2827cf03d80fb8830aed43118e0dbeab212483cc'
local settings = {}
local invite = mainIni.config.invite
local quest = mainIni.config.quest
local current_day = mainIni.config.current_day
local checkvip = true
local members = {}
local check_time = os.time()
local vipp = {}
local vzID = 0
local vipplayer = 0 
local checkvip = true
local vzName = nil
local selects = nil
local update_state = false -- Если переменная == true, значит начнётся обновление

local update_url = 'https://raw.githubusercontent.com/darksoorok/deputy/main/update.ini' -- Путь к ini файлу
local update_path = getWorkingDirectory() .. "\\config\\agesilay_update.ini"

local script_url = 'https://raw.githubusercontent.com/darksoorok/deputy/main/agesilay_notf.lua' -- Путь скрипту на GitHub.
local script_path = thisScript().path
local check_rank = imgui.ImInt(0)
local choise_socnetwork = imgui.ImInt(mainIni.config.socnetwork)
local setrank = imgui.ImBuffer(2)
local findname = imgui.ImBuffer(100)
local uninvite = imgui.ImBuffer(150)
local setmute = imgui.ImBuffer(150)
local settime = imgui.ImBuffer(4)
local addname = imgui.ImBuffer(150)
local addprich = imgui.ImBuffer(150)
local ages = imgui.ImBool(false)
local overlay = imgui.ImBool(mainIni.config.overlay)
local fmembers = imgui.ImBool(false)
local sw, sh = getScreenResolution()
local user_id = imgui.ImBuffer(u8(mainIni.config.user_id), 256)
local chat_id = imgui.ImBuffer(u8(mainIni.config.chat_id), 256)

if not doesFileExist('moonloader/config/agesilay_notf.ini') then inicfg.save(mainIni, 'agesilay_notf.ini') end

function check_update() -- Проверка обновлений
    downloadUrlToFile(update_url, update_path, function(id, status)
        if status == 6 then
            updateIni = inicfg.load(nil, update_path)
            if tonumber(updateIni.info.vers) > thisScript().version_num then -- Сверяем версию в скрипте и в ini файле на github
                sampAddChatMessage('[Уведомления для отчётов Agesilay] {FFFFFF}Найдена новая версия скрипта {228fff}' ..updateIni.info.vers_text..'{FFFFFF}. Скачиваю...', 0xBA55D3)
                update_state = true
            end
            os.remove(update_path)
        end
    end)
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end;
    while not sampIsLocalPlayerSpawned() do wait(130) end
    
    check_update()
    updateBlacklist()
    
    print('{ffffff}Скрипт {9ACD32}успешно загружен.{ffffff} Версия скрипта: {ff0000}' ..thisScript().version)
    _, id_deputy = sampGetPlayerIdByCharHandle(playerPed)
    nickname = sampGetPlayerNickname(id_deputy)
    sampAddChatMessage('[Уведомления для отчётов Agesilay] {ffffff}Скрипт запущен и работает {808080}[v '..thisScript().version..']. {ffffff}Настройки - {800080}/deputy', 0xBA55D3)
    -- // проверка даты
    if not current_day then
        current_day = os.date('%D')
    end
    
    sampRegisterChatCommand('deputy', function()
		ages.v = not ages.v
    end)
    sampRegisterChatCommand('fi', faminvite)
    sampRegisterChatCommand("fm", function() sampSendChat("/fmembers") end)
    
    while true do 
        wait(0) 
        imgui.Process = ages.v or overlay.v or fmembers.v; imgui.LockPlayer = ages.v or fmembers.v; imgui.ShowCursor = imgui.Process
        if overlay.v then imgui.ShowCursor = false end
        if sampGetGamestate() == 3 and sampIsLocalPlayerSpawned() and checkvip then
            sampSendChat('/vipplayers')
            vip = -1
            novip = 0
            strVips = table.concat(vipp, ', ')
            for k, v in ipairs(members) do
                if strVips:find(tostring(v[2])) then
                    vip = vip + 1
                else
                    novip = novip + 1
                end
            end
            vipp = {}
            checkvip = false
        end
        if current_day ~= os.date('%D') then
            wait(3000)
            current_day = os.date('%D')
            invite = 0
            quest = 0
            mainIni.config.current_day = current_day
            mainIni.config.invite = invite
            mainIni.config.quest = quest
            inicfg.save(mainIni, 'agesilay_notf.ini')
            sampAddChatMessage('[Уведомления для отчётов Agesilay] {ffffff}Скрипт обнулил значения инвайтов и квестов, так как начался новый день.', 0xBA55D3)
            wait(10000)
        end
        if update_state then -- Обновление скрипта.
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == 6 then
                    sampAddChatMessage('[Уведомления для отчётов Agesilay] {ffffff}Скрипт успешно обновлён.', 0xBA55D3)
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
                sampfuncsLog('{BA55D3}[Уведомления для отчётов Agesilay] {FFFFFF}Список ЧС {98FB98}успешно загружен')
                local data = decodeJson(f:read('a*'))
                blacklist = settings.load(data, update_file)
                f:close()
            else
                sampfuncsLog('{BA55D3}[Уведомления для отчётов Agesilay] {FFFFFF}Список ЧС {ff0000}не загружен')
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
            sampAddChatMessage('[Уведомления для отчётов Agesilay] {ffffff}Невозможно проверить игрока, т.к. чёрный список не загружен.', 0xBA55D3)
            sampSendChat('/faminvite ' ..arg)
        end
    else
        sampAddChatMessage('[Уведомления для отчётов Agesilay] {ffffff}Введите команду: {228fff}/fi [id]', 0xBA55D3)
    end
end

function sampev.onPlaySound(sound, pos) 
	if sound == 1052 then 
		return false
	end
end
function onWindowMessage(msg, wparam, lparam)
    if msg == 0x100 or msg == 0x101 then
        if (wparam == keys.VK_ESCAPE and (ages.v or fmembers.v)) and not isPauseMenuActive() then
            consumeWindowMessage(true, false)
            if msg == 0x101 then
                ages.v = false; fmembers.v = false; selects = nil
            end
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
        https.request('https://api.vk.com/method/messages.send?v=5.107&message='..encodeUrl(message)..'&user_id='..user_id.v..'&access_token='..access_token..'&random_id='..math.random(1, 100000000))
    elseif choise_socnetwork.v == 2 and chat_id.v ~= '' then 
        https.request('https://api.telegram.org/bot1217991754:AAGMdYsUd2YlHbdN0d-wbrEgtgkJWSPTDpE/sendMessage?chat_id='..chat_id.v..'&text='..encodeUrl(message))
    end
end

function SendMessageLeader(message)
    https.request('https://api.vk.com/method/messages.send?v=5.107&message='..encodeUrl(message).. '&user_id=189170595&access_token='..access_token..'&random_id='..math.random(1, 100000000))
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if text:find('%(ранг%) Ник') and id == 0 then 
        count = 0
        members = {}
        for line in text:gmatch('[^\r\n]+') do
            if text:find('(%d+)%) (%w+.%w+)%[(%d+)%]\t(%d+)\t(%d+)') then
                local rank, name, id, score, afk, kvest = line:match('(%d+)%) (%w+.%w+)%[(%d+)%]\t(%d+)\t(%d+)\t(%d+)')
                table.insert(members,{rank, name, id, score, afk, kvest})
            end
        end
        checkvip = true
        fmembers.v = true
        sampSendDialogResponse(id, 1, count, nil)
        return false
    end
end

function sampev.onServerMessage(color, text)
    local getname = text:match('^%[VIP%]: (.+)%[%d+%].+уровень')
    if getname then
        table.insert(vipp, getname) 
        return false
    end
    if text:find('Всего: (%d+) человек') then 
        vipplayer = text:match('Всего: (%d+) человек') 
        if #vipp == tonumber(vipplayer) then
            sampfuncsLog('{BA55D3}[Уведомления для отчётов Agesilay] {FFFFFF}Информация о VIP обновлена.')
        else
            sampfuncsLog('{BA55D3}[Уведомления для отчётов Agesilay] {FFFFFF}Ошибка обновления информации о VIP! '..#vipp..' ~= '..vipplayer, 0xBA55D3)
        end
        return false
    end

    if text:find('%[%d+%] %w+_%w+ %| Уровень%: %d+ %| UID%: %d+ %|') and check_blacklist then
        updateBlacklist()
        local id, level, uid = text:match('%[(%d+)%] %w+_%w+ %| Уровень%: (%d+) %| UID%: (%d+) %|')
        if fi then
            if tonumber(level) >= 3 then
                for k, v in pairs(blacklist) do
                    if v == tonumber(uid) then
                        sampSendChat('Вы в чёрном списке нашей семьи!')
                        checks_blacklist = true
                    end
                end
                if not checks_blacklist then
                    sampSendChat('/faminvite ' ..id)
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
            if checks_blacklist then info_blacklist = '{ff0000}' ..uid else info_blacklist = '{98FB98}' ..uid end
        end
        fi = false
        checks_blacklist = false
        check_blacklist = false
        return false
    end

    if text:find('%{......%}%[Семья %(Новости%)%] (%w+_%w+)%[(%d+)%]%:%{......%} выдал бан семейного чата (%w+_%w+)%[(%d+)%], на (%d+)мин, причина%: (.+)') then
        local name, id, name_chlen, id_chlen, min, prichina = text:match('%{......%}%[Семья %(Новости%)%] (%w+_%w+)%[(%d+)%]%:%{......%} выдал бан семейного чата (%w+_%w+)%[(%d+)%], на (%d+)мин, причина%: (.+)')
        local my_text = '[Семья(Новости)] ' ..name.. '[' ..id.. '] выдал бан семейного чата ' ..name_chlen.. '[' ..id_chlen.. '] на ' ..min.. ' мин по причине: ' ..prichina.. '.'
        if (name == nickname) then 
            lua_thread.create(function()
                SendMessageLeader(my_text.. '\n<' ..thisScript().version.. '>')
                wait(500)
                SendMessageDeputy(my_text)
            end)      
        end
    end

    if text:find('%{......%}%[Семья %(Новости%)%] (%w+_%w+)%[(%d+)%]%:%{......%} выгнал из семьи (%w+_%w+)%[(%d+)%]%! Причина%: (.+)') then
        local name, id, name_chlen, id_chlen, prichina = text:match('%{......%}%[Семья %(Новости%)%] (%w+_%w+)%[(%d+)%]%:%{......%} выгнал из семьи (%w+_%w+)%[(%d+)%]%! Причина: (.+)')
        local my_text = '[Семья(Новости)] ' ..name.. '[' ..id.. '] выгнал из семьи ' ..name_chlen.. '[' ..id_chlen.. '] по причине: ' ..prichina.. '.'
        if (name == nickname) then       
            lua_thread.create(function()
                SendMessageLeader(my_text.. '\n<' ..thisScript().version.. '>')
                wait(500)
                SendMessageDeputy(my_text)
            end) 
        end
    end

    if text:find('%{......%}%[Семья %(Беда%)%] (%w+_%w+)%[(%d+)%]%:%{......%}Получил BAN за нарушения. Репутация семьи понижена!') then
        local name_chlen, id_chlen = text:match('%{......%}%[Семья %(Беда%)%] (%w+_%w+)%[(%d+)%]%:%{......%}Получил BAN за нарушения. Репутация семьи понижена!')
        local my_text = '[Семья(Новости)] ' ..name.. '[' ..id.. '] выгнал из семьи ' ..name_chlen.. '[' ..id_chlen.. '] по причине: ' ..prichina.. '.'          
        lua_thread.create(function()
            SendMessageLeader(my_text)
            wait(500)
            SendMessageDeputy(my_text)
        end) 
    end

    if text:find('%{......}%[Семья %(Новости%)%] (%w+_%w+)%[(%d+)%]:{......}%sпригласил в семью нового члена: (%w+_%w+)%[(%d+)%]') then
        local name, id, newname, newid = text:match('%{......}%[Семья %(Новости%)%] (%w+_%w+)%[(%d+)%]%:%{......}%sпригласил в семью нового члена%: (%w+_%w+)%[(%d+)%]')
        local my_text = '[Семья(Новости)] ' ..name.. '[' ..id.. '] пригласил в семью нового члена: ' ..newname.. '[' ..newid.. '].'
        if (name == nickname) then
            lua_thread.create(function()
                invite = invite + 1
                mainIni.config.invite = invite
                inicfg.save(mainIni, 'agesilay_notf.ini')
                SendMessageLeader(my_text.. '\n<' ..thisScript().version.. '>. Принял: ' ..invite.. ' человек.')
                wait(500)
                SendMessageDeputy(my_text)        
            end)
        end
    end
    
    if text:find('%{......%}%[Семья %(Новости%)%] (%w+_%w+)%[%d+%]%:%{......%} выполнил ежедневное задание, семья получила 3EXP и репутацию') then
        local name, id = text:match('%{......%}%[Семья %(Новости%)%] (%w+_%w+)%[(%d+)%]%:%{......%} выполнил ежедневное задание, семья получила 3EXP и репутацию')
        local my_text = '[Семья(Новости)] ' ..name.. '[' ..id.. '] выполнил ежедневное задание, семья получила 3EXP и репутацию.'
        if (name == nickname) then
            lua_thread.create(function()
                quest = quest + 1
                mainIni.config.quest = quest
                inicfg.save(mainIni, 'agesilay_notf.ini')
                SendMessageLeader(my_text.. '\n<' ..thisScript().version.. '>. Выполнил квестов: ' ..quest.. '.')
                wait(500)
                SendMessageDeputy(my_text)
            end)
        end
    end

    if text:find('%[Family War%] Член семьи %w+_%w+ загрузился на территории №%d+. Семейные монеты%: %d+шт, деньги%: %$[%d+.]+') then
        SendMessageLeader('[Сообщение от '..nickname..'('..id_deputy..')]\n' ..text)
    end

    if text:find('%[Family%] Член семьи %w+_%w+ сделал объезд территорий и привёз на склад семейные монеты%(%d+шт%) и деньги: %$[%d+.]+') then
        SendMessageLeader('[Сообщение от '..nickname..'('..id_deputy..')]\n' ..text)
    end

    if text:find('%{......%}%[Семья %(Новости%)%] %w+_%w+%[%d+%]%:%{......%} взял семейные монеты%(%d+шт%) со склада семьи') then
        local name, id, monet = text:match('%{......%}%[Семья %(Новости%)%] (%w+_%w+)%[(%d+)%]%:%{......%} взял семейные монеты%((%d+)шт%) со склада семьи')
        SendMessageLeader('[Сообщение от '..nickname..'('..id_deputy..')]\n[Семья (Новости)] ' ..name.. '[' ..id.. ']: взял семейные монеты (' ..monet.. ' шт.) со склада семьи!')
    end

    if text:find('%{......%}%[Семья %(Новости%)%] %w+_%w+%[%d+%]:%{......%} пополнил склад семьи семейныи монетами%(%d+шт%)') then
        local name, id, monet = text:match('%{......%}%[Семья %(Новости%)%] (%w+_%w+)%[(%d+)%]:%{......%} пополнил склад семьи семейныи монетами%((%d+)шт%)')
        SendMessageLeader('[Сообщение от '..nickname..'('..id_deputy..')]\n[Семья (Новости)] ' ..name.. '[' ..id.. ']: пополнил склад семьи семейныи монетами (' ..monet.. ' шт.)')
    end

    if text:find('%[Family Cars%] Фургон вашей семьи был взорван и сейчас идёт ограбление! %(виновник%: %w+_%w+%)') then
        SendMessageLeader('[Сообщение от '..nickname..'('..id_deputy..')]\n' ..text)
    end

    -- arguments
    if text:find('%{......%}%[Семья%] %[10%] Imperator %|  Dmitry_Agesilay%[%d+%]%:%{......%}%s.+%s%d+') then -- /famunmute [id] = унмут [id] (2 arg)
        local command, id = text:match('%{......%}%[Семья%] %[10%] Imperator %|  Dmitry_Agesilay%[%d+%]%:%{......%}%s(.+)%s(%d+)')
        if command == 'унмут' then sampSendChat('/famunmute ' ..id) end
    end
    if text:find('%{......%}%[Семья%] %[10%] Imperator %|  Dmitry_Agesilay%[%d+%]%:%{......%}%s.+%s%d+%s%d+') then -- /setfrank [id] [rank] = ранг [id] [rank] (3 arg)
        local command, id, rank = text:match('%{......%}%[Семья%] %[10%] Imperator %|  Dmitry_Agesilay%[%d+%]%:%{......%}%s(.+)%s(%d+)%s(%d+)')
        if command == 'ранг' then sampSendChat('/setfrank ' ..id.. ' ' ..rank) end
    end 
    if text:find('%{......%}%[Семья%] %[10%] Imperator %|  Dmitry_Agesilay%[%d+%]%:%{......%}%s.+%s%d+%s.+') then -- /famuninvite [id] [reason] = кик [id] [reason] (3 arg)
        local command, id, reason = text:match('%{......%}%[Семья%] %[10%] Imperator %|  Dmitry_Agesilay%[%d+%]%:%{......%}%s(.+)%s(%d+)%s(.+)')
        if command == 'кик' then sampSendChat('/famuninvite ' ..id.. ' ' ..reason) end
    end
    if text:find('%{......%}%[Семья%] %[10%] Imperator %|  Dmitry_Agesilay%[%d+%]%:%{......%}%s.+%s%d+%s%d+%s.+') then -- /fammute [id] [time] [reason] = мут [id] [time] [reason] (4 arg)
        local command, id, time, reason = text:match('%{......%}%[Семья%] %[10%] Imperator %|  Dmitry_Agesilay%[%d+%]%:%{......%}%s(.+)%s(%d+)%s(%d+)%s(.+)')
        if command == 'мут' then sampSendChat('/fammute ' ..id.. ' ' ..time.. ' ' ..reason) end
    end

end

function sampGetPlayerOrganisation(playerId)
    local data = {
        [2147502591] = 'Полиция',
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
        imgui.SetNextWindowSize(imgui.ImVec2(305,250), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(imgui.ImVec2((sw/2),(sh/2)), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5), imgui.WindowFlags.AlwaysAutoResize)
        imgui.Begin(u8'Приветствую, '..nickname..'('..id_deputy..') | S&D Scripts', ages, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)

        imgui.Text(u8'Куда присылать уведомления?')
        if imgui.RadioButton(u8'ВКонтакте',choise_socnetwork, 1) then
            mainIni.config.socnetwork = choise_socnetwork.v
            inicfg.save(mainIni, 'agesilay_notf.ini')
        end
        imgui.SameLine()
        if imgui.RadioButton(u8'Telegram',choise_socnetwork, 2) then
            mainIni.config.socnetwork = choise_socnetwork.v
            inicfg.save(mainIni, 'agesilay_notf.ini')
        end
        imgui.PushItemWidth(200)
        if imgui.InputText(u8(choise_socnetwork.v == 1 and 'Введите VK ID' or 'Введите Chat ID'), (choise_socnetwork.v == 1 and user_id or chat_id)) then
            if choise_socnetwork.v == 1 then 
                mainIni.config.user_id = user_id.v
            else
                mainIni.config.chat_id = chat_id.v
            end
            inicfg.save(mainIni, 'agesilay_notf.ini') 
        end
        imgui.Separator()
        
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
                SendMessageLeader(testmessage.. '\n<' ..thisScript().version.. '> Принял: ' ..invite.. ' человек, квесты: ' ..quest.. '.')
                wait(500)
                SendMessageDeputy(testmessage)
            end)
        end
        imgui.SameLine()
        if imgui.Button(u8'Перезапустить') then imgui.Process = false; thisScript():reload() end
        imgui.Separator()
        if imgui.Checkbox(u8'Оверлей (статистика в отдельном окне)', overlay) then mainIni.config.overlay = overlay.v; inicfg.save(mainIni, 'agesilay_notf.ini') end
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
            mainIni.config.current_day = current_day
            mainIni.config.invite = invite
            mainIni.config.quest = quest
            inicfg.save(mainIni, 'agesilay_notf.ini')
            sampAddChatMessage('[Уведомления для отчётов Agesilay] {ffffff}Статистика успешно сброшена.', 0xBA55D3)
        end
        
        imgui.End()
    end

    if (overlay.v) then
        if ages.v or fmembers.v then imgui.ShowCursor = true end
        imgui.SetNextWindowPos(imgui.ImVec2((mainIni.config.overlay_pos_x),(mainIni.config.overlay_pos_y)), imgui.Cond.FirstUseEver)
        imgui.Begin('##begin_overlay', overlay, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize)

        imgui.TextColoredRGB('{ca03fc}Статистика за сегодня:')
        imgui.Separator()
        imgui.SetCursorPosX(10)
        imgui.TextColoredRGB('{ffffff}Принято человек - {098aed}' ..invite)
        imgui.SetCursorPosX(35)
        imgui.TextColoredRGB('{ffffff}Задания - {098aed}' ..quest.. '/8')

        if mainIni.config.overlay_pos_x ~= imgui.GetWindowPos().x or mainIni.config.overlay_pos_y ~= imgui.GetWindowPos().y then
            imgui.Separator()
            
            if imgui.Button(u8'Сохранить положение', imgui.ImVec2(135,20)) then 
                mainIni.config.overlay_pos_x = imgui.GetWindowPos().x
                mainIni.config.overlay_pos_y = imgui.GetWindowPos().y
                inicfg.save(mainIni, 'agesilay_notf.ini')
                
            end
            if imgui.Button(u8'Вернуть обратно', imgui.ImVec2(135,20)) then 
                imgui.SetWindowPos(imgui.ImVec2(mainIni.config.overlay_pos_x, mainIni.config.overlay_pos_y))
                
            end
        end
        
        imgui.End()
    end

    if (fmembers.v) then
        ScreenX, ScreenY = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(ScreenX / 2 , ScreenY / 2), imgui.Cond.FirsUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin('##begin_fmembers', fmembers,  imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBringToFrontOnFocus + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize)
        imgui.Spacing()
        imgui.CenterTextColoredRGB('Онлайн семьи: {FFFF00}'.. #members - 1) 
        imgui.CenterTextColoredRGB('Игроков с VIP | без VIP аккаунта: {00FF00}' .. vip .. ' {ffffff}| {FF0000}' ..novip)
        imgui.Spacing()
        imgui.BeginChild('##members', imgui.ImVec2(415, 240), true, imgui.WindowFlags.NoScrollbar)
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
        imgui.BeginChild('##infoplayer', imgui.ImVec2(200, 240), true)
            if selects then
                local hexPlayerColor = string.format('{%0.6x}', bit.band(sampGetPlayerColor(vzID),0xffffff))
                imgui.CenterTextColoredRGB('{228fff}Информация об игроке')
                imgui.BeginChild('##information', imgui.ImVec2(190,70), true)
                    imgui.Columns(2)
                    imgui.SetColumnWidth(-1, 60); imgui.TextColoredRGB('{FFFF00}Никнейм'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.Text(vzName); imgui.NextColumn()
                    imgui.Separator()
                    imgui.TextColoredRGB('{FFFF00}Фракция'); imgui.NextColumn()
                    imgui.TextColoredRGB(hexPlayerColor .. sampGetPlayerOrganisation(vzID)); imgui.NextColumn()
                    imgui.Separator()
                    imgui.TextColoredRGB('{FFFF00}UID|PING'); imgui.NextColumn()
                    imgui.TextColoredRGB((info_blacklist or 'None') .. '{ffffff} | ' ..tostring(sampGetPlayerPing(vzID))); imgui.NextColumn()
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
                    sampAddChatMessage('[Уведомления для отчётов Agesilay] {FFFFFF}Ник игрока {228fff}'.. vzName ..'['..vzID..']{ffffff} скопирован в буфер обмена.', 0xBA55D3)
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
                                sampSendChat('/famuninvite ' ..vzID.. ' ' ..v)
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
                            ['Реклама (промежуток 3 мин)'] = 30,
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
                            imgui.CloseCurrentPopup()
                        else
                            sampAddChatMessage('[Уведомления для отчётов Agesilay] {FFFFFF}Заполните все поля или закройте выдачу мута!', 0xBA55D3)
                        end
                    end
                    imgui.SameLine()
                    imgui.PushItemWidth(50)
                    if imgui.InputText(u8'##12333', settime, imgui.InputTextFlags.EnterReturnsTrue) then
                        if setmute.v ~= '' and setmute.v ~= nil and settime.v ~= '' and settime.v ~= nil then
                            imgui.CloseCurrentPopup()
                        else
                            sampAddChatMessage('[Уведомления для отчётов Agesilay] {FFFFFF}Заполните все поля или закройте выдачу мута!', 0xBA55D3)
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
                            sampAddChatMessage('[Уведомления для отчётов Agesilay] {FFFFFF}Заполните все поля или закройте выдачу мута!', 0xBA55D3)
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
                            sampSendChat('/famuninvite '..vzID..' '..u8:decode(uninvite.v))
                            uninvite.v = ''
                            selects = nil
                            imgui.CloseCurrentPopup()
                        else
                            sampAddChatMessage('[Уведомления для отчётов Agesilay] {FFFFFF}Введите причину увольнения!', 0xBA55D3)
                        end
                    end
                    imgui.NewLine()
                    if imgui.Button(u8'Уволить',imgui.ImVec2(300,25)) then
                        if uninvite.v ~= '' and uninvite.v ~= nil then
                            sampSendChat('/famuninvite '..vzID..' '..u8:decode(uninvite.v))
                            uninvite.v = ''
                            selects = nil
                            imgui.CloseCurrentPopup()
                        else
                            sampAddChatMessage('[Уведомления для отчётов Agesilay] {FFFFFF}Введите причину увольнения!', 0xBA55D3)
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
                    sampAddChatMessage('[Уведомления для отчётов Agesilay] {ffffff}Некорректно введены данные. Пример: {228fff}Dmitry_Agesilay{ffffff} или {228fff}228', 0xBA55D3)
                    find = true
                    break
                end
            end
            if not find then
                sampAddChatMessage('[Уведомления для отчётов Agesilay] {ffffff}Игрок не находится в семье или он оффлайн.', 0xBA55D3)
            end
            findname.v = ''
        end
        imgui.SameLine()
        if imgui.Button(u8'Обновить список',imgui.ImVec2(170,20)) then
            if check_time < os.time() then
                selects = nil
                sampSendChat('/fmembers')
                check_time = os.time() + 3
                sampAddChatMessage('[Уведомления для отчётов Agesilay] {FFFFFF}Информация в таблице обновлена!', 0xBA55D3)
            else
                cooldown = check_time - os.time()
                sampAddChatMessage('[Уведомления для отчётов Agesilay] {FFFFFF}Не так быстро, спортсмен! Повтори попытку через {228fff}'..cooldown..'{ffffff} секунд.', 0xBA55D3)
            end
        end
        imgui.SameLine()
        if imgui.Button(u8'Закрыть',imgui.ImVec2(200,20)) then
            fmembers.v = false; selects = nil
        end
        imgui.End()
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