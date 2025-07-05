local M = {}

M.ops = require("kanban.ops").get_ops({})
M.fn = require("kanban.fn")
M.theme = require("kanban.theme")
M.active = false

function M.setup(options)
	M.ops = require("kanban.ops").get_ops(options)
	M.keymap = require("kanban.keymap").keymap
	vim.api.nvim_create_user_command("KanbanOpen", M.kanban_open, {
		nargs = "?",
		complete = function(arg, _, _)
			local handle = io.popen("rg '\\-+[\\n\\s]+kanban-plugin: .+[\\n\\s]+\\-+' -lU ./")
			if not handle then
				return {}
			end
			local io_output = handle:read("*a")
			local paths = {}
			for line in io_output:gmatch("([^\n]*)\n?") do
				if line ~= "" then
					table.insert(paths, line)
				end
			end
			return paths
		end,
	})
	vim.api.nvim_create_user_command("KanbanCreate", M.kanban_create, {
		nargs = 1,
		complete = function(arg, _, _)
			local arg_path = arg:match("(.+)/[^/]*$") or ""
			local arg_tail = arg:match("[^/]*$")
			local handle = io.popen("find ./" .. arg_path .. " -name '" .. arg_tail .. "*' -type d")
			if not handle then
				return {}
			end
			local io_output = handle:read("*a")
			local paths = {}
			for line in io_output:gmatch("([^\n]*)\n?") do
				if line and line ~= "" then
					line = line:gsub("^[%./]+/", "")
					if line ~= "" and not line:match("^%.") then
						table.insert(paths, line)
					end
				end
			end
			return paths
		end,
	})

	M.theme.init(M)
end

function M.kanban_close(err, message)
	if message then
		print(message)
	end
	if err then
		vim.notify(err, vim.log.levels.ERROR, {})
	end
	M.active = false
	require("kanban.user_command").del()
end

function M.kanban_create(path)
	path = path:match("%.md$") and path or path .. ".md"
	local markdown = require("kanban.markdown")
	if require("kanban.utils").file_exists(path) then
		vim.notify(path .. " already exists!", vim.log.levels.ERROR, {})
		return
	end
	M.items = {}
	M.items.lists = {
		{ title = "TODO", tasks = {} },
		{ title = "Work in progress", tasks = {} },
		{ title = "Done", tasks = {} },
		{ title = "Archive", tasks = {} },
	}
	markdown.writer.write(M, path)
end

function M.kanban_open(arg)
	-- Check kanban activation
	if M.active then
		vim.notify("kanban is already active!!", vim.log.levels.ERROR, {})
		return
	else
		M.active = true
	end

	----------------------
	-- Read markdown from current buffer
	----------------------
	if arg == nil then
		M.kanban_md_path = vim.fn.expand("%:p")
	elseif arg == "telescope" then
		local is_telescope_installed = pcall(require, "telescope")
		if not is_telescope_installed then
			vim.notify("Telescope.nvim is not installed!!", vim.log.levels.ERROR, {})
			return
		end
		local kanban_telescope = require("kanban.integrations.telescope").kanban_telescope
		kanban_telescope()
		return
	else
		M.kanban_md_path = arg
	end

	----------------------
	-- Read markdown file
	----------------------
	M.markdown = require("kanban.markdown")
	local md = M.markdown.reader.read(M, M.kanban_md_path)
	if not md then
		M.active = false
		return
	end

	-----------------------
	-- md to kanban
	-----------------------
	-- init
	M.items = {}
	M.items.kwindow = {}
	M.fn.kwindow.add(M) -- create window panel
	---- create list panel
	M.items.lists = {}
	for i in pairs(md.lists) do
		M.fn.lists.add(M, md.lists[i].title, false)
	end

	---- create task panel
	local max_task_show_int = M.fn.tasks.utils.get_max_task_show_int(M)
	for i in pairs(md.lists) do
		local list = md.lists[i]
		if #list.tasks == 0 then
			M.fn.tasks.add(M, i, nil, "bottom", true)
		else
			for j in pairs(list.tasks) do
				local task = list.tasks[j]
				local open_bool = j <= max_task_show_int
				M.fn.tasks.add(M, i, task, "bottom", open_bool)
			end
		end
	end
	---- Set default cursor position
	if #M.items.lists > 0 then
		vim.fn.win_gotoid(M.items.lists[1].tasks[1].win_id)
	end
	require("kanban.user_command").create(M)
end

M.setup()

return function(_, data)
	local method = data.fargs[1]
	local arg = data.fargs[2]
	if method == "create" then
		M.kanban_create(arg)
	elseif method == "open" then
		M.kanban_open(arg)
	end
end

-- return M
