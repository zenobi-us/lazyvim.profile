local function action(label, method, command)
  return {
    label = label,
    modes = { "n" },
    condition = function()
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
        if client:supports_method(method, 0) then return true end
      end
      return false
    end,
    command = "<Cmd>lua " .. command .. "<CR>",
  }
end

return {
  menus = {
    label = "LSP Actions",
    condition = function(predicate) return predicate.buf_has_lsp() end,
    items = {
      action("Hover", "textDocument/hover", "vim.lsp.buf.hover()"),
      action("Rename", "textDocument/rename", "vim.lsp.buf.rename()"),
      action("Code action", "textDocument/codeAction", "vim.lsp.buf.code_action()"),
      { label = "Diagnostics", modes = { "n" }, command = "<Cmd>lua vim.diagnostic.open_float()<CR>" },
      action("References", "textDocument/references", "vim.lsp.buf.references()"),
      action("Definition", "textDocument/definition", "vim.lsp.buf.definition()"),
      action("Type definition", "textDocument/typeDefinition", "vim.lsp.buf.type_definition()"),
    },
  },
}
