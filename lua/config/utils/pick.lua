local M = {}

local has_telescope, pickers = pcall(require, "telescope.pickers")
if not has_telescope then
	M.available = false
	return M
end

M.available = true

local previewers = require("telescope.previewers")

function M.text_per_entry_previewer(lang)
  return previewers.new_buffer_previewer({
    define_preview = function(self, entry)
      local lines = {}

      if entry.preview_text then
        if type(entry.preview_text) == "table" then
          for _, line in ipairs(entry.preview_text) do
            table.insert(lines, tostring(line))
          end
        elseif type(entry.preview_text) == "string" then
          for line in entry.preview_text:gmatch("([^\n]*)\n?") do
            table.insert(lines, line)
          end
        else
          table.insert(lines, "Invalid preview_text type")
        end
      else
        table.insert(lines, "No preview available")
      end

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.api.nvim_set_option_value('filetype',lang or"lua",{buf = self.state.bufnr})
    end,
  })
end


local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local themes = require("telescope.themes")

local DEFAULT_OPTS = {
	prompt_title = "Select entries",
	theme = "dropdown",
	initial_mode = "normal",
}

local function get_theme_config(theme_name, theme_opts)
	local theme_func = themes["get_" .. theme_name]
	if not theme_func then
		theme_func = themes.get_dropdown
	end
	return theme_func(theme_opts or {})
end

local function validate_entries(entries)
	if type(entries) ~= "table" then
		return nil, "Entries must be a table"
	end

	if #entries == 0 then
		return nil, "Entries table is empty"
	end

	local normalized_entries = {}
	for i, entry in ipairs(entries) do
		if type(entry) == "string" then
			table.insert(normalized_entries, { value = entry, display = entry })
		elseif type(entry) == "table" and entry.value then
			table.insert(normalized_entries, entry)
		else
			return nil, string.format("Invalid entry at index %d", i)
		end
	end

	return normalized_entries, nil
end

local function create_entry_maker(custom_maker)
	if custom_maker then
		return custom_maker
	end

	return function(entry)
		return {
			value = entry.value or entry,
			display = entry.display or entry.value or entry,
			ordinal = entry.ordinal or entry.display or entry.value or entry,
		}
	end
end

function M.pick_single(entries, callback, opts)
	local normalized_entries, err = validate_entries(entries)
	if not normalized_entries then
		if callback then
			callback(nil)
		end
		return false, err
	end

	opts = vim.tbl_deep_extend("force", DEFAULT_OPTS, opts or {})

	local picker_opts = {
		prompt_title = opts.prompt_title,
		finder = finders.new_table({
			results = normalized_entries,
			entry_maker = create_entry_maker(opts.entry_maker),
		}),
		sorter = conf.generic_sorter(opts.sorter_opts or {}),
		previewer = opts.previewer,
		attach_mappings = function(prompt_bufnr, map)
			if opts.mappings then
				for mode, mode_mappings in pairs(opts.mappings) do
					for key, action in pairs(mode_mappings) do
						map(mode, key, action)
					end
				end
			end

			actions.select_default:replace(function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)

				local result = selection and selection.value or nil

				if callback then
					callback(result)
				end
			end)

			return true
		end,
	}

	local theme_config = get_theme_config(opts.theme, { initial_mode = opts.initial_mode })

	pickers.new(theme_config, picker_opts):find()
	return true, "Single-select picker opened successfully"
end

function M.pick_multi(entries, callback, opts)
	local normalized_entries, err = validate_entries(entries)
	if not normalized_entries then
		if callback then
			callback({})
		end
		return false, err
	end

	opts = vim.tbl_deep_extend("force", DEFAULT_OPTS, opts or {})

	local prompt_title = opts.show_hints ~= false
			and string.format("%s (<Tab> toggle, <C-a> toggle all)", opts.prompt_title)
		or opts.prompt_title

	local function toggle_all(prompt_bufnr)
		local picker = action_state.get_current_picker(prompt_bufnr)
		local manager = picker.manager
		local num_results = manager:num_results()

		if num_results == 0 then
			return
		end

		local selections = picker:get_multi_selection()
		local all_selected = #selections == num_results

		if not all_selected then
			for i = 0, num_results - 1 do
				picker:add_selection(i)
			end
		else
			for i = 0, num_results - 1 do
				picker:remove_selection(i)
			end
		end

		picker:refresh_previewer()
	end

	local preselected_items = opts.preselected_items or {}
	local preselected_map = {}
	for _, item in ipairs(preselected_items) do
		preselected_map[item] = true
	end

	local preselected_list = {}
	local remaining_list = {}

	for _, entry in ipairs(normalized_entries) do
		if preselected_map[entry.value] then
			table.insert(preselected_list, entry)
		else
			table.insert(remaining_list, entry)
		end
	end

	local sorted_entries = vim.list_extend(preselected_list, remaining_list)

	local sorter
	if #preselected_items > 0 then
		sorter = false
	else
		sorter = conf.generic_sorter(opts.sorter_opts or {})
	end

	local picker_opts = {
		prompt_title = prompt_title,
		finder = finders.new_table({
			results = sorted_entries,
			entry_maker = create_entry_maker(opts.entry_maker),
		}),
		sorter = sorter,
		previewer = opts.previewer,
		attach_mappings = function(prompt_bufnr, map)
			map("n", "<Tab>", actions.toggle_selection)
			map("i", "<Tab>", actions.toggle_selection)
			map("n", "<C-a>", toggle_all)
			map("i", "<C-a>", toggle_all)

			if opts.selection_strategy == "replace" then
				map("n", "<C-t>", actions.toggle_selection)
				map("i", "<C-t>", actions.toggle_selection)
			end

			if opts.mappings then
				for mode, mode_mappings in pairs(opts.mappings) do
					for key, action in pairs(mode_mappings) do
						map(mode, key, action)
					end
				end
			end

			actions.select_default:replace(function()
				local picker = action_state.get_current_picker(prompt_bufnr)
				local selections = picker:get_multi_selection()
				local current_selection = action_state.get_selected_entry()

				actions.close(prompt_bufnr)

				local result = {}

				if #selections == 0 and current_selection and opts.allow_single_fallback then
					table.insert(result, current_selection.value)
				else
					for _, selection in ipairs(selections) do
						table.insert(result, selection.value)
					end
				end

				if callback then
					callback(result)
				end
			end)

			return true
		end,
	}

	local theme_config = get_theme_config(opts.theme, { initial_mode = opts.initial_mode })
	local picker = pickers.new(theme_config, picker_opts)

	picker:register_completion_callback(function()
		for idx, entry in ipairs(sorted_entries) do
			if preselected_map[entry.value] then
				picker:add_selection(idx - 1)
			end
		end
	end)

	picker:find()
	return true, "Multi-select picker opened successfully"
end

function M.pick_single_simple(entries, callback)
	return M.pick_single(entries, callback, {
		theme = "dropdown",
		initial_mode = "normal",
	})
end

function M.pick_multi_simple(entries, callback)
	return M.pick_multi(entries, callback, {
		theme = "dropdown",
		initial_mode = "normal",
		show_hints = true,
		allow_single_fallback = false,
	})
end

function M.pick_single_with_preview(entries, callback, opts)
	opts = opts or {}
	opts.previewer = opts.previewer or conf.file_previewer(opts)
	return M.pick_single(entries, callback, opts)
end

function M.pick_multi_with_preview(entries, callback, opts)
	opts = opts or {}
	opts.previewer = opts.previewer or conf.file_previewer(opts)
	opts.entry_maker = opts.entry_maker or function(entry)
		return {
			value = entry.value,
			display = entry.display or entry.value,
			ordinal = entry.display or entry.value,
			preview_text = entry.preview_text,
		}
	end
	return M.pick_multi(entries, callback, opts)
end


function M.pick_entries(entries, callback, opts)
	return M.pick_multi(entries, callback, opts)
end

function M.pick_option(options, callback, opts)
	opts = opts or {}
	opts.prompt_title = opts.prompt_title or "Select option"
	return M.pick_single(options, callback, opts)
end

function M.pick_menu(menu_items, callback, opts)
	opts = opts or {}
	opts.prompt_title = opts.prompt_title or "Select action"
	return M.pick_single(menu_items, callback, opts)
end

function M.pick_checklist(items, callback, opts)
	opts = opts or {}
	opts.prompt_title = opts.prompt_title or "Select items"
	opts.show_hints = opts.show_hints ~= false
	return M.pick_multi(items, callback, opts)
end

return M
