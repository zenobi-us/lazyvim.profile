-- Use understated separators in the statusline instead of powerline shapes.
return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.section_separators = { left = "", right = "" }
      opts.options.component_separators = { left = "│", right = "│" }

      -- Click the branch name to open Snacks' Git branch picker.
      opts.sections = opts.sections or {}
      opts.sections.lualine_b = opts.sections.lualine_b or {}
      for index, component in ipairs(opts.sections.lualine_b) do
        if component == "branch" then
          opts.sections.lualine_b[index] = {
            "branch",
            on_click = function()
              Snacks.picker.git_branches()
            end,
          }
        elseif type(component) == "table" and component[1] == "branch" then
          component.on_click = function()
            Snacks.picker.git_branches()
          end
        end
      end

      local function pick_worktree()
        local cwd = vim.fn.getcwd()
        vim.system({ "wt", "-C", cwd, "list", "--format", "json" }, { text = true }, function(result)
          vim.schedule(function()
            if result.code ~= 0 then
              vim.notify("Worktrunk list failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
              return
            end
            local ok, worktrees = pcall(vim.json.decode, result.stdout)
            if not ok or type(worktrees) ~= "table" then
              vim.notify("Could not parse Worktrunk worktree list", vim.log.levels.WARN)
              worktrees = {}
            end
            if #worktrees == 0 then
              worktrees = { { branch = "No worktrees found", path = "", is_current = false } }
            end
            local function run_wt(args, callback)
              vim.system(vim.list_extend({ "wt", "-C", cwd }, args), { text = true }, function(cmd_result)
                vim.schedule(function()
                  if cmd_result.code ~= 0 then
                    vim.notify("Worktrunk failed: " .. (cmd_result.stderr or ""), vim.log.levels.ERROR)
                  elseif callback then
                    callback(cmd_result)
                  end
                end)
              end)
            end

            vim.ui.select(worktrees, {
              prompt = "Switch worktree",
              format_item = function(worktree)
                return (worktree.is_current and "● " or "  ")
                  .. (worktree.branch or "(detached)")
                  .. (worktree.path ~= "" and ("  " .. worktree.path) or "")
              end,
              snacks = {
                actions = {
                  worktree_add = function(picker)
                    picker:close()
                    vim.ui.input({ prompt = "New worktree branch: " }, function(branch)
                      if branch and branch ~= "" then
                        run_wt({ "switch", "--create", branch })
                      end
                    end)
                  end,
                  worktree_remove = function(picker)
                    local selected = picker:current()
                    local worktree = selected and selected.item
                    if not worktree or not worktree.branch or worktree.is_current then
                      vim.notify("Select a non-current worktree to remove", vim.log.levels.WARN)
                      return
                    end
                    vim.ui.select({ "Remove " .. worktree.branch, "Cancel" }, { prompt = "Confirm removal" }, function(choice)
                      if choice == "Remove " .. worktree.branch then
                        picker:close()
                        run_wt({ "remove", worktree.branch })
                      end
                    end)
                  end,
                },
                win = {
                  input = { footer = " a add worktree  ·  d remove selected  ·  Enter switch " },
                  list = {
                    keys = {
                      a = { "worktree_add", mode = { "n", "i" }, desc = "Add worktree" },
                      d = { "worktree_remove", mode = { "n", "i" }, desc = "Remove selected worktree" },
                    },
                  },
                },
              },
            }, function(worktree)
              if worktree and worktree.path and worktree.path ~= "" then
                vim.cmd.tcd(vim.fn.fnameescape(worktree.path))
              end
            end)
          end)
        end)
      end

      table.insert(opts.sections.lualine_b, {
        function()
          return vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
        end,
        on_click = function()
          pick_worktree()
        end,
        padding = { left = 1, right = 1 },
      })
    end,
  },
}
