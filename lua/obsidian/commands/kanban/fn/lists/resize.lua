local M = {}
function M.resize(kanban)
	local lists = kanban.items.lists
	for i in pairs(lists) do
		local kwindow_col = kanban.items.kwindow.buf_conf.col
		local x_margin = kanban.ops.layout.list_x_margin
		local list_abs_col = ((kanban.items.kwindow.buf_conf.width / #lists) * (i - 1)) + x_margin
		lists[i].buf_conf.row = math.ceil(kanban.ops.layout.y_margin + 4)
		lists[i].buf_conf.col = math.ceil(kwindow_col + list_abs_col)
		lists[i].buf_conf.width = math.ceil((kanban.items.kwindow.buf_conf.width / #lists) - x_margin * 2)
		vim.api.nvim_win_set_config(lists[i].win_id, lists[i].buf_conf)
	end
end
return M
