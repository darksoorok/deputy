script_name('Agesilay | Centurio Notification')
script_author('S&D Scripts')
script_description('Sends messages to the family leader for job reporting.')
script_dependencies('effil, events, ssl.https, inicfg')
script_version('1.1')

local sampev    =   require 'lib.samp.events'
local encoding  =   require 'encoding'
local inicfg    =   require 'inicfg'
local effil     =   require 'effil'
require 'lib.moonloader'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local access_token = '5d0f748e304fab955173a4cf27518fa638c2f42e5a3b6688c637022aac855b89fa1715e269c1445590795'

local cfg = inicfg.load({
    Setting = {
        day_of_week = os.date('%A'),
        reset = false,
        completed_in_a_week = 0
    }
}, 'centurio.ini')

local day_of_week = cfg.Setting.day_of_week
local completed_in_a_week = cfg.Setting.completed_in_a_week

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end;

    if not doesFileExist('moonloader/config/centurio.ini') then
        if inicfg.save(cfg, 'centurio.ini') then print('{FF8C00}Предупреждение: {ffffff}файл конфигурации не найден. Создан файл: {00ff00}config\\centurio.ini') end
    end

    day_of_week = os.date('%A')
    inicfg.save(cfg, 'centurio.ini')  
    if day_of_week == 'Monday' and not cfg.Setting.reset then
        completed_in_a_week = 0
        cfg.Setting.reset = true
        inicfg.save(cfg, 'centurio.ini')
    end
    if day_of_week == 'Tuesday' and cfg.Setting.reset then
        cfg.Setting.reset = false
        inicfg.save(cfg, 'centurio.ini')
    end

    if require("memory").tohex(getModuleHandle("samp.dll") + 0xBABE, 10, true ) == "E86D9A0A0083C41C85C0" then
        sampIsLocalPlayerSpawned = function()
            local res, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            return sampGetGamestate() == 3 and res and sampGetPlayerAnimationId(id) ~= 0
        end
    end
	while not sampIsLocalPlayerSpawned() do wait(200) end
    nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
    wait(300)
    sampAddChatMessage('[' ..thisScript().name.. '] {FFFFFF}Приветствую, {FFD700}'..nickname..'('..select(2, sampGetPlayerIdByCharHandle(playerPed))..'). {FFFFFF}Тестовое сообщение - {FF8C00}/tm', 0xFFD700)

    sampRegisterChatCommand('tm', function()
        tmsg = true
		if completed_in_a_week < 5 then
			vk_request('Центурион вызвал тестовое сообщение.\n[ ! ] Выполнено за неделю: '..completed_in_a_week..'.')
		elseif completed_in_a_week >= 5 then
			local sum = (completed_in_a_week > 5 and 2000000 + ((completed_in_a_week - 5) * 200000) or 2000000)
			vk_request('Центурион вызвал тестовое сообщение.\n[ ! ] Выполнено за неделю: '..completed_in_a_week..'.\n[$] Выплатить: $' ..formatter(sum).. '.')
		end
	end)

    while true do wait(0) end
end

function sampev.onServerMessage(color, text)
	local nick = text:match('%{......%}%[Семья %(Новости%)%] (%w+_%w+)%[%d+%]%:%{......%} выполнил ежедневное задание%, семья получила .+%!')
	if nick and (nick == nickname) then
		completed_in_a_week = completed_in_a_week + 1
		cfg.Setting.completed_in_a_week = completed_in_a_week
		inicfg.save(cfg, 'centurio.ini')
		if completed_in_a_week < 5 then
			vk_request('Выполнено ежедневное задание!\n[ ! ] Выполнено за неделю: '..completed_in_a_week..'.')
		elseif completed_in_a_week >= 5 then
			local sum = (completed_in_a_week > 5 and 2000000 + ((completed_in_a_week - 5) * 200000) or 2000000)
			vk_request('Выполнено ежедневное задание!\n[ ! ] Выполнено за неделю: '..completed_in_a_week..'.\n[$] Выплатить: $' ..formatter(sum).. '.')
		end
	end
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
	local str = string.gsub(str, "\\", "\\")
	local str = string.gsub(str, "([^%w])", char_to_hex)
	return str
end

math.randomseed(os.time())

function vk_request(msg)
	local pID = select(2, sampGetPlayerIdByCharHandle(playerPed))
    local name = sampGetPlayerNickname(pID)
	msg = msg:gsub('{......}', '')
	msg = '[Сообщение от ' ..name.. '(' ..pID..')]:\n' ..msg
	msg = u8(msg)
	msg = url_encode(msg)
	local rnd = math.random(-2147483648, 2147483647)
	async_http_request('https://api.vk.com/method/messages.send', 'peer_id=93816829&random_id=' .. rnd .. '&message=' .. msg .. '&access_token=' .. access_token .. '&v=5.131',
	function (result)
		if tmsg then
			sampAddChatMessage('['..thisScript().name..'] {FFFFFF}Тестовое сообщение успешно отправлено.', 0xFFD700)
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
			sampAddChatMessage('Ошибка! {ffffff}Код: {228fff}' .. t.error.error_code .. ' {ffffff}Причина: {228fff}' .. t.error.error_msg, 0xFF0000)
			return
		end
	end)
end

function formatter(n)
	local v1, v2, v3 = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return (tonumber(n) == 0 and 0 or (v1 .. (v2:reverse():gsub('(%d%d%d)','%1.'):reverse()) .. v3))
end