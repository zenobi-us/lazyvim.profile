# Mouse Peasant Popup

Contextual Neovim mouse menus, originally copied from
`zenobi-us/astronvim.profile` at `84233d0645665841e934af57ee1d184c5e8840fe`.

The local Lazy spec is `lua/plugins/mousepeasant-popup.lua`. It registers the
LSP and optional Neo-tree menus on `VeryLazy`; it does not install Neo-tree.
This workspace uses Snacks explorer, so Neo-tree entries will remain hidden
unless you install and open Neo-tree.

```lua
require("mousepeasant-popup").setup({
  min_menu_item_width = 30,
  menus = {
    PopUp = {
      {
        label = "Hover",
        modes = { "n" },
        condition = function(p) return p.buf_has_lsp() end,
        command = "<Cmd>lua vim.lsp.buf.hover()<CR>",
      },
    },
  },
})
```

- Setup owns and replaces each configured root (including `PopUp`), not just
  individual entries. Do not share these roots with another menu plugin.
- Conditions are reevaluated on `MenuPopup`. Predicates are functions: call them.
  Errors notify and hide the affected entry. Conditions should have no side effects.
- Definitions are never mutated. Submenu roots are qualified by parent and index;
  removed roots are cleaned up on refresh/setup. Setup installs one autocmd.
- Labels escape menu-path punctuation and use Unicode display-cell widths.
  Commands must be trusted, nonempty, single-line Neovim menu RHS strings;
  they are executable configuration, not sandboxed input.
- `options.condition` is supported for compatibility; top-level `condition` wins.
- LSP entries use direct APIs, with server capability checks, not leader mappings.
- Cut/paste uses Neo-tree's native clipboard commands (v3 API), preserving its
  highlighting, conflict prompts and refresh logic. There is no independent
  clipboard, raw `os.rename`, or custom cross-filesystem fallback here: filesystem
  behavior and errors are delegated to Neo-tree. `Clear clipboard` cancels a cut.
- Requires modern Neovim with `vim.lsp.get_clients` (0.10+).

Run regression tests from the configuration root:

```sh
nvim --headless -u NONE -l tests/popup.lua
```
