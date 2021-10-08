script_name('Agesilay | Centurio Notification')
script_author('S&D Scripts')
script_description('Sends messages to the family leader for job reporting.')
script_dependencies('effil, events, ssl.https, inicfg')
script_version('1.2')
script_version_number(2)

local encoding  =   require 'encoding'
local inicfg    =   require 'inicfg'
local sampev    =   require 'lib.samp.events'

local leffil, effil = pcall(require, 'effil')

require 'lib.moonloader'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local access_token = '5d0f748e304fab955173a4cf27518fa638c2f42e5a3b6688c637022aac855b89fa1715e269c1445590795'

local cfg = inicfg.load({
    Week = {
        day = os.date('%w'),
        completed = 0,
		tg = false
    },
	AllTimes = {
		completed = 0,
		money = 0
	}
}, 'centurio.ini')

local config = {}
local access = false
local script_url = 'https://raw.githubusercontent.com/darksoorok/deputy/main/agesilay_notf.lua' -- ���� ������� �� GitHub.
local script_path = thisScript().path -- ���� � ������� � ����


-- ? Working of week ? --
local day = cfg.Week.day
local completed = cfg.Week.completed
local tg = cfg.Week.tg
local money = (completed >= 5 and (completed > 5 and 2000000 + ((completed - 5) * 200000) or 2000000) or 0)


-- ? Working in all times ? --
local all_completed = cfg.AllTimes.completed
local all_money = cfg.AllTimes.money

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end;

    if not doesFileExist('moonloader/config/centurio.ini') then
        if inicfg.save(cfg, 'centurio.ini') then 
			print('{FFD700}[' ..thisScript().name.. '] {FF8C00}������ ���������������� ini ����!')
		end
    end
	if not leffil then
		downloadUrlToFile('https://raw.githubusercontent.com/darksoorok/deputy/main/centurio/libs/effil.lua', getWorkingDirectory() .. '\\lib\\effil.lua', function(id, status, p1, p2)
			if status == 6 then
				print('{FFD700}[' ..thisScript().name.. '] {FF8C00}Library "effil" downloaded successfully! {FFFFFF}Reload scripts!')
				reloadScripts()
			end
		end)
	end

    day = os.date('%w')
	if not tostring(cfg.Week.day):find('%d') then
		local array_Day = {'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'}
		for k,v in pairs(array_Day) do
			if v == cfg.Week.day then
				cfg.Week.day = k
				inicfg.save(cfg, 'centurio.ini')
				break
			end
		end
	end
	if day == 0 then day = 7 end
	if tonumber(day) == 1 or (tonumber(day) < tonumber(cfg.Week.day)) then
		sampAddChatMessage('['..thisScript().name..'] {FFFFFF}������� ������� ��������� ������� �� ������, �.�. �������� �����.', 0xFFD700)
		if completed >= 5 then
			local sum = (completed > 5 and 2000000 + ((completed - 5) * 200000) or 2000000)
			all_money = all_money + sum
			cfg.AllTimes.money = all_money
			inicfg.save(cfg, 'centurio.ini')
			sampAddChatMessage('['..thisScript().name..'] {FFFFFF}��������� �������: {FFD700}'..completed..'. {FFFFFF}��������� �� ������� ������: {228B22}$' ..formatter(sum), 0xFFD700)
		end
		money = 0
		completed = 0
        cfg.Week.completed = completed
        inicfg.save(cfg, 'centurio.ini')
	end
	cfg.Week.day = day
    inicfg.save(cfg, 'centurio.ini')  
    if require("memory").tohex(getModuleHandle("samp.dll") + 0xBABE, 10, true ) == "E86D9A0A0083C41C85C0" then
        sampIsLocalPlayerSpawned = function()
            local res, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            return sampGetGamestate() == 3 and res and sampGetPlayerAnimationId(id) ~= 0
        end
    end
	while not sampIsLocalPlayerSpawned() do wait(200) end
    -- nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
	nickname = 'Luntik_Agesilay'

	local configFile = getWorkingDirectory() .. '\\config\\centurio.json'
	downloadUrlToFile('https://raw.githubusercontent.com/darksoorok/deputy/main/centurio/centurio.json', configFile, function(id, status, p1, p2)
		local f = io.open(configFile, 'r+')
		if f then
			config = decodeJson(f:read('a*'))
			f:close()
		end
	end)
	wait(350)
	os.remove(configFile)
	if encodeJson(config) ~= '{}' then
		for k,v in pairs(config.Names) do
			if v == nickname then
				access = true
				break
			end
		end
		wait(300)
		if not access then
			sampAddChatMessage('[' ..thisScript().name.. '] {D3D3D3}������ � ������������� ������� ������!', 0xFF0000)
			thisScript():unload()
		end
		wait(200)
		sampAddChatMessage(config.version_number,-1)
		if config.version_number > thisScript().version_num then
			sampAddChatMessage('�������� ����������',-1)
			downloadUrlToFile(script_url, script_path, function(id, status)
                if status == 6 then
                    sampAddChatMessage('[' ..thisScript().name.. '] {D3D3D3}������ ������� �������! ������������!', 0xFFD700)
                end
            end)
			-- thisScript():reload()
		end
	else
		sampAddChatMessage('[' ..thisScript().name.. '] {D3D3D3}������ �������� �������� �������! ���������� ������������� {228FFF}CTRL+R', 0xFF0000)
		thisScript():unload()
	end
	wait(300)
    sampAddChatMessage('[' ..thisScript().name.. '] {FFFFFF}�����������, {FFD700}'..nickname..'('..select(2, sampGetPlayerIdByCharHandle(playerPed))..'). {FFFFFF}��������� - {FF8C00}/set', 0xFFD700)

	sampRegisterChatCommand('set', function()
		showMyDialog(1)
	end)

    while true do wait(0) 
		local result, button, list, input = sampHasDialogRespond(228) -- ! Settings
        if result then
            if button == 1 then
				if list == 0 or list == 1 then
					showMyDialog(1)
				elseif list == 2 then
                    tg = not tg
					cfg.Week.tg = tg
					inicfg.save(cfg, 'centurio.ini')
					showMyDialog(1)
                elseif list == 3 then
                    tmsg = true
					if completed < 5 then
						vk_request('��������� ������ �������� ���������.\n[ ! ] ��������� �� ������: '..completed..'.')
					elseif completed >= 5 then
						local sum = (completed > 5 and 2000000 + ((completed - 5) * 200000) or 2000000)
						vk_request('��������� ������ �������� ���������.\n[ ! ] ��������� �� ������: '..completed..'.\n[$] ���������: $' ..formatter(sum).. '.')
					end
                elseif list == 4 then
					showMyDialog(2)
				end
            end
        end

		local result, button, list, input = sampHasDialogRespond(229) -- ! Information
		if result then
			if button == 0 then
				showMyDialog(1)
			end
		end	
	end
end

function sampev.onServerMessage(color, text)
	local nick = text:match('%{......%}%[����� %(�������%)%] (%w+_%w+)%[%d+%]%:%{......%} �������� ���������� �������%, ����� �������� .+%!')
	if nick and (nick == nickname) then
		completed = completed + 1
		all_completed = all_completed + 1
		cfg.Week.completed = completed
		cfg.AllTimes.completed = all_completed
		inicfg.save(cfg, 'centurio.ini')
		if completed < 5 then
			vk_request('��������� ���������� �������!\n[ ! ] ��������� �� ������: '..completed..'.')
		elseif completed >= 5 then
			local sum = (completed > 5 and 2000000 + ((completed - 5) * 200000) or 2000000)
			vk_request('��������� ���������� �������!\n[ ! ] ��������� �� ������: '..completed..'.\n[$] ���������: $' ..formatter(sum).. '.')
		end
	end
end

function showMyDialog(numb)
	if numb == 1 then
		sampShowDialog(228, '{FFD700}Centurio Notification {808080}[ v' .. thisScript().version .. ' ]', '{FFFFFF}��������� �� ������ (�� �����): {FFD700}' ..completed .. ' / ' ..all_completed.. '\n{FFFFFF}���������� �� ������ (�� �����): {228B22}$' ..formatter(money).. ' / $' ..formatter(all_money)..'\n{FF8C00}��������� ����� ������������ � {228FFF}'..(tg and 'Telegram' or '���������').. '\n{228FFF}�������� ���������\n{FF0000}[!] {D3D3D3}���������� � �������', '�������', '�������', 2)
	else
		local textInformation = ''
		local arrayInformation = {
			'{FFD700}������ ������������ ��� �������� ��������� ������ ����� � ����� ���������� ������.',
			' ',
			'{228B22}������� ������:',
			'{D3D3D3}- ��� ����� ��������� ������ ������ ������������� ���������� ������ ����� ��������� � ���.����;',
			'{D3D3D3}- ������ ������� ���������� ����������� ������� �� ������ (�� �� �����);',
			'{D3D3D3}- ������ ����������� ���� ���������� �����.',
			' ',
			'� ���������� �� ������ ������� ���� � ����� ������ ���.���� ����� ������������ ��������� ������.',
			' ',
			'����� {228FFF}�������� ���������{FFFFFF} �������� ��������� � ��������� ���.���� ������.',
			'���������� ��� ��� �������� ����������������� �������.',
			' ',
			'{FF0000}[!] {FF8C00}���� �� ����� � �������, ������� �������� ��������� � {228FFF}Telegram'
		}
		for k,v in pairs(arrayInformation) do
			textInformation = textInformation .. v.. '{FFFFFF}\n'
		end
		sampShowDialog(229, '{D3D3D3}���������� � �������', '{FFFFFF}' .. textInformation, '�������', '�����', 0)
	end	
end

function settingsload(table, dir)
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

-- // FUNCTION FROM VK_REQUEST BY ANIKI //
function threadHandle(runner, url, args, resolve, reject) -- ��������� effil ������ ��� ����������
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

function requestRunner() -- �������� effil ������ � �������� https �������
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
	if tg then
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

function vk_request(msg)
	local pID = select(2, sampGetPlayerIdByCharHandle(playerPed))
    local name = sampGetPlayerNickname(pID)
	msg = msg:gsub('{......}', '')
	msg = '[��������� �� ' ..name.. '(' ..pID..')]:\n' ..msg
	msg = u8(msg)
	msg = url_encode(msg)
	local rnd = math.random(-2147483648, 2147483647)
	if tg then
		require("ssl.https").request('https://api.telegram.org/bot2044924191:AAE3nVH9blGB5LpHPkH1bVpt5w0FNCis9nY/sendMessage?chat_id=502002527&text='..url_encode(msg))
		if tmsg then
			sampAddChatMessage('['..thisScript().name..'] {FFFFFF}�������� ��������� ������� ���������� � Telegram.', 0xFFD700)
			tmsg = false
		end	
	else
		async_http_request('https://api.vk.com/method/messages.send', 'peer_id=93816829&random_id=' .. rnd .. '&message=' .. msg .. '&access_token=' .. access_token .. '&v=5.131',
		function (result)
			if tmsg then
				sampAddChatMessage('['..thisScript().name..'] {FFFFFF}�������� ��������� ������� ���������� � ���������.', 0xFFD700)
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
				sampAddChatMessage('������! {ffffff}���: {228fff}' .. t.error.error_code .. ' {ffffff}�������: {228fff}' .. t.error.error_msg, 0xFF0000)
				return
			end
		end)
	end
end

function formatter(n)
	local v1, v2, v3 = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return (tonumber(n) == 0 and 0 or (v1 .. (v2:reverse():gsub('(%d%d%d)','%1.'):reverse()) .. v3))
end