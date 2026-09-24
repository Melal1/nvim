local saved_divisor = nil

function DivideNumberUnderCursor(reset_divisor)
	local cword = vim.fn.expand("<cword>")
	local current_num = tonumber(cword)

	if not current_num then
		print("Cursor is not on a number!")
		return
	end

	if not saved_divisor or reset_divisor then
		local input = vim.fn.input("Enter number to divide by: ")
		local input_num = tonumber(input)

		if not input_num then
			print("\nInvalid input. Please enter a valid number.")
			return
		end

		if input_num == 0 then
			print("\nCannot divide by zero.")
			return
		end

		saved_divisor = input_num
		vim.cmd("normal! :<C-u>")
	end

	local raw_result = current_num / saved_divisor

	local rounded_up = math.ceil(raw_result * 100) / 100

	local final_result = string.format("%.2f", rounded_up)

	vim.cmd(string.format('normal! "_ciw%s\27', final_result))
end

vim.keymap.set("n", "<leader>h", function()
	DivideNumberUnderCursor(false)
end, { desc = "Divide number under cursor" })

vim.keymap.set("n", "<leader>H", function()
	DivideNumberUnderCursor(true)
end, { desc = "Reset divisor and divide" })

