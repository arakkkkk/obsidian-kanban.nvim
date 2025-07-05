local M = {}

-- "day" で補完を開始するパターン
local DAY_PATTERN = "day$"

-- "day" で補完を開始できるか判定
M.find_day_start = function(input)
	if string.match(input, DAY_PATTERN) then
		return true
	end
end

-- 今日の日付を"YYYY-MM-DD"形式で取得
local function get_today()
	return os.date("%Y-%m-%d")
end

-- 補完可能かどうか判定
M.can_complete = function(request)
	local can = M.find_day_start(request.context.cursor_before_line)
	if not can then
		return false
	end
	return true
end

-- 補完候補を返す
M.get_completions = function()
	return {
		{
			label = get_today(),
			insertText = get_today(),
			kind = 1, -- Text
			detail = "今日の日付",
		},
	}
end

-- トリガーとなる文字列
M.get_trigger_characters = function()
	return { "d" }
end

return M
