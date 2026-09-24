-- Highlight on yank :
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank({ timeout = 500 })
	end,
})

-- Highlights
-- local CommentErrorFg = vim.api.nvim_get_hl(0, { name = "DiagnosticError" }).fg
local PmenuSelFg = vim.api.nvim_get_hl(0, { name = "@function.call" }).fg
local highlights = {
	-- Navbuddy
	NavbuddyFile = { link = "@lsp.type.comment" },
	NavbuddyModule = { link = "@module" },
	NavbuddyNamespace = { link = "@lsp.type.Namespace" },
	NavbuddyPackage = { link = "Keyword" },
	NavbuddyClass = { link = "@lsp.type.class" },
	NavbuddyProperty = { link = "@lsp.type.Property" },
	NavbuddyField = { link = "@lsp.type.Property" },
	NavbuddyConstructor = { link = "@type" },
	NavbuddyEnum = { link = "@lsp.type.Enum" },
	NavbuddyInterface = { link = "@lsp.type.Interface" },
	NavbuddyFunction = { link = "@lsp.type.Function" },
	NavbuddyMethod = { link = "@lsp.type.method" },
	NavbuddyVariable = { link = "@lsp.type.Variable" },
	NavbuddyConstant = { link = "Constant" },
	NavbuddyEnumMember = { link = "@lsp.type.EnumMember" },
	NavbuddyStruct = { link = "@lsp.type.Struct" },
	NavbuddyEvent = { link = "@lsp.type.Event" },
	NavbuddyOperator = { link = "@lsp.type.Operator" },
	NavbuddyTypeParameter = { link = "@lsp.type.TypeParameter" },
	NavbuddyString = { link = "@lsp.type.String" },
	NavbuddyNumber = { link = "@lsp.type.Number" },
	NavbuddyBoolean = { link = "@boolean" },
	NavbuddyArray = { link = "@type" },
	NavbuddyObject = { link = "@constant.builtin" },
	NavbuddyKey = { link = "@constant.builtin" },
	NavbuddyNull = { link = "@constant.builtin" },

	--Navic

	NavicIconsFile = { link = "@lsp.type.comment" },
	NavicIconsModule = { link = "@module" },
	NavicIconsNamespace = { link = "@lsp.type.Namespace" },
	NavicIconsPackage = { link = "Keyword" },
	NavicIconsClass = { link = "@lsp.type.class" },
	NavicIconsMethod = { link = "@lsp.type.method" },
	NavicIconsProperty = { link = "@lsp.type.Property" },
	NavicIconsField = { link = "@lsp.type.Property" },
	NavicIconsConstructor = { link = "@type" },
	NavicIconsEnum = { link = "@lsp.type.Enum" },
	NavicIconsInterface = { link = "@lsp.type.Interface" },
	NavicIconsFunction = { link = "@lsp.type.Function" },
	NavicIconsVariable = { link = "@lsp.type.Variable" },
	NavicIconsConstant = { link = "Constant" },
	NavicIconsString = { link = "@lsp.type.String" },
	NavicIconsNumber = { link = "@lsp.type.Number" },
	NavicIconsBoolean = { link = "@boolean" },
	NavicIconsArray = { link = "@type" },
	NavicIconsObject = { link = "@constant.builtin" },
	NavicIconsKey = { link = "@constant.builtin" },
	NavicIconsNull = { link = "@constant.builtin" },
	NavicIconsEnumMember = { link = "@lsp.type.EnumMember" },
	NavicIconsStruct = { link = "@lsp.type.Struct" },
	NavicIconsEvent = { link = "@lsp.type.Event" },
	NavicIconsOperator = { link = "@lsp.type.Operator" },
	NavicIconsTypeParameter = { link = "@lsp.type.TypeParameter" },
	NavicText = { link = "@text" },
	NavicSeparator = { link = "@punctuation" },
  -- MatchParen = { fg = CommentErrorFg, bg = "fg", bold = true },
  PmenuSel = { fg = "#141415", bg = PmenuSelFg, bold = true },

}

for hlName, option in pairs(highlights) do
	vim.api.nvim_set_hl(0, hlName, option)
end

