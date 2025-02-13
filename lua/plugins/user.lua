-- Brainfuck Interpreter Function
local function run_brainfuck_from_string(code)
  local memory = {}
  local data_pointer = 1
  local code_pointer = 1
  local code_length = #code
  local output = {}

  for i = 1, 30000 do
    memory[i] = 0
  end

  local matching_bracket = {}
  local stack = {}

  for i = 1, code_length do
    local char = code:sub(i, i)
    if char == "[" then
      table.insert(stack, i)
    elseif char == "]" then
      if #stack == 0 then error("Unmatched ']' at position " .. i) end
      local start = table.remove(stack)
      matching_bracket[start] = i
      matching_bracket[i] = start
    end
  end

  if #stack > 0 then error("Unmatched '[' at position " .. stack[#stack]) end

  while code_pointer <= code_length do
    local command = code:sub(code_pointer, code_pointer)

    if command == ">" then
      data_pointer = data_pointer + 1
    elseif command == "<" then
      data_pointer = data_pointer - 1
    elseif command == "+" then
      memory[data_pointer] = (memory[data_pointer] + 1) % 256
    elseif command == "-" then
      memory[data_pointer] = (memory[data_pointer] - 1) % 256
    elseif command == "[" then
      if memory[data_pointer] == 0 then code_pointer = matching_bracket[code_pointer] end
    elseif command == "]" then
      if memory[data_pointer] ~= 0 then code_pointer = matching_bracket[code_pointer] end
    elseif command == "." then
      table.insert(output, string.char(memory[data_pointer]))
    end

    code_pointer = code_pointer + 1
  end

  return table.concat(output)
end

-- Brainfuck code as a multi-line string
local brainfuck_code = [[
+[>>>->-[>->----<<<]>>]>>>.........-----.<<-------------.<<<<<-.+++++.>-.<-----
-.>.<.+++..>.<---.--.>--.++.<+.-.++.>>>>>>++.<++++..<++++++++++.>>>+++++.......
..<<---.>>.<<.+++.....<.>>>..........<<---.>>>++......<<<.+++....<.>>>.........
..<<---.>>>..........<<<.+++....<.>>>............<<---.>>>....<<<+++..........-
--.>>-----.<<-.<<<<<+.>---.+++.<-.>.---.+.++.<-.++++.>--.++.<---.+++.-.>>>>>>.<
++++..<.>>>+++++.............-----.<<----.<<<<<-.>---.+++.<-.>.<.+++..>.<---.--
.>--.++.<+.-.++.>>>>>>.<+.+++.>>>+.<.<<----.<<<<<+.>---.+++.<-.>.---.+.++.<-.++
++.>--.++.<---.+++.-.>>>>>>.>+++++..............<<+.>>.<<<.>>>...............>>
++.<---.<<<+++.....>>....>+++.<....<<---.>>.<<<.>>>..............>.<..<<<<-.>>>
>-----.<<-.<<<<<-.>---.+++.<-.>.<-.+.-.>.<.++.+++.>.<----.+++.-----.>>>>>>.<<<.
>>>>.<<.>>>++++.+++++.+++.---------.<<<<<<<.<+.>----.<.>++++.<.>----.+.+++.<.>-
-.<.>>>>>>.>>--.<.<<.>>>+++.+++++.+++.<<<<<<<<+.>++.<-.+.-.>.<.++.+++.>.<----.+
++.-----.>>>>>>.<<<+.>>>>.<<.<<<<<+++.>---.+++.<-.>.---.+.++.<-.++++.>--.++.<--
-.+++.-.>>>>>>.<<<.---------.....>>++++.<<....+++++++++.>.>>>+++++.............
<<<<++++++.>>>>............<++++++.+++++.>>+++++++++.<..<<<<.>.>>>............<
<<<.>>..>>.<<-.>>.......<<--.>>..<<<<<<<-.>>>.>>>>.<<<<.>>>>>>.<<<<<.>>>.......
......>-.<<<+++.<<---.>>>>.........>>.<<.....>>.<<<<<.>>>.............>.<<<.<<+
+.>>>>.......<<<<+.>>>>...<<<<.>>>>...>>.<<<<<.>>>.............<<.<<.>>>>....<<
.......<<.>>>>....>>.<<<<<.>>>............>---.<<<.....<<.>>>>..>>.<<.....+++++
++++.---------...>>.<<<<<.>>>.....................++++++++.--------....<<<<.>>>
>....>>.<<.-----.<<----.<<+.>>>-----------.>+++++.<<<.
]]

-- Run the Brainfuck program and get the output
local brainfuck_output = run_brainfuck_from_string(brainfuck_code)

-- Function to count the number of captures
local function countCaptures(str, pattern)
  local count = 0
  for _ in str:gmatch(pattern) do
    count = count + 1
  end
  return count
end

-- Function to find the first occurrence of any key in the map
local function findFirstKey(line, map)
  local firstKey, firstPos = nil, nil

  -- Iterate over all keys in the map
  for key, _ in pairs(map) do
    local startPos = line:find(key, 1, true) -- Find the key in the line (plain search)
    if startPos and (not firstPos or startPos < firstPos) then
      -- Update the first key and its position if it's the earliest match
      firstKey, firstPos = key, startPos
    end
  end

  return firstKey, firstPos
end

-- Function to parse ANSI escape sequences and convert to highlight groups
-- Specific to the BF output.
local function parse_ansi_to_highlights(str)
  local hl_map = {
    ["\027[38;2;255;209;102m"] = "Constant",
    ["\027[38;2;89;159;254m"] = "Directory",
    ["\027[38;2;121;136;250m"] = "Title",
    ["\027[38;2;171;178;191m"] = "Normal",
    ["\027[0m"] = "Normal",
  }
  local pattern = "\27%[[^m]*m"

  local lines = {}
  local highlights = {}
  local current_hl = "Constant"

  for line in str:gmatch "[^\r\n]+" do
    local line_highlights = {}

    -- Remove unnecessary 8 leading spaces.
    if #str > 8 then line = line:sub(8 + 1) end

    local count_color_codes = countCaptures(line, pattern)
    if count_color_codes == 0 and current_hl then
      -- use last color highligh no highlights are declared.
      table.insert(line_highlights, { current_hl, 0, -1 })
    else
      local last_col = 0
      while true do
        local key, pos = findFirstKey(line, hl_map)
        local highlight = hl_map[key]

        if not key or not pos then
          break -- No more keys found, exit the loop
        elseif not current_hl then
          -- Not assigned a highlight yet.
          last_col = pos
          current_hl = highlight
        else
          -- add the last highlight group
          table.insert(line_highlights, { current_hl, last_col, pos - 1 })

          -- set the next hilight group
          current_hl = highlight
          last_col = pos - 1
        end
        -- Remove the matched key from the line
        line = line:sub(1, pos - 1) .. line:sub(pos + #key)
      end
      -- add last highlight group for the line.
      table.insert(line_highlights, { current_hl, last_col, -1 })
    end

    -- center the graphic.
    line = line .. "      "

    table.insert(lines, line)
    if next(line_highlights) ~= nil then table.insert(highlights, line_highlights) end
  end

  return lines, highlights
end

-- Lua debug util: Print given object.
_G.P = function(v)
  print(vim.inspect(v))
  return v
end

-- Lua debug util: Reload a module.
local RELOAD = function(...) return require("plenary.reload").reload_module(...) end

-- Lua debug util: Reload a module (with `R("module-name")`)
_G.R = function(name)
  RELOAD(name)
  return require(name)
end

-- State for callbacks to use.
local state = {
  -- For showing inline diagnostics.
  virtual_text = false,
}

---@type LazySpec
return {
  -- { dir = "~/code/datalinks-ai.nvim" },

  {
    "nvim-lua/plenary.nvim",
  },

  {
    "mrcjkb/rustaceanvim",
    dependencies = {
      -- Using a custom prettifier for LLDB
      "cmrschwarz/rust-prettifier-for-lldb",
    },
    opts = {
      dap = {
        -- If you want the minimalistic config, you only need the commented out config below.
        -- load_rust_types = true,
        autoload_configurations = true,
        configuration = function()
          local configurations = require("dap").configurations.rust
          configurations = configurations or {}
          local configuration = configurations[1] or {}

          local lldb_script = vim.fn.stdpath "data" .. "/lazy/rust-prettifier-for-lldb/rust_prettifier_for_lldb.py"

          configuration = vim.tbl_deep_extend(
            "force",
            configuration,
            { initCommands = { 'command script import "' .. lldb_script .. '"' } }
          )

          return configuration
        end,
      },
    },
  },

  -- {
  --   dir = "~/code/datalinks-ai.nvim",
  --   opts = {
  --     debug = true,
  --   },
  -- },
  -- debug = true,

  {
    "declancm/cinnamon.nvim",
    version = "*", -- use latest release
    opts = {
      -- Enable all provided keymaps
      keymaps = {
        basic = true,
        extra = true,
      },
      -- Only scroll the window
      options = { mode = "window" },
    },
    config = function(plugin)
      local cinnamon = require "cinnamon"
      cinnamon.setup(plugin.opts)
      -- Centered scrolling:
      vim.keymap.set("n", "<C-U>", function() cinnamon.scroll "<C-U>zz" end)
      vim.keymap.set("n", "<C-D>", function() cinnamon.scroll "<C-D>zz" end)
      vim.keymap.set("n", "{", function() cinnamon.scroll "{zz" end)
      vim.keymap.set("n", "}", function() cinnamon.scroll "}zz" end)
    end,
  },

  {
    "folke/zen-mode.nvim",
    keys = {
      { "<leader>z", function() require("zen-mode").toggle() end, mode = "n", desc = "󱅻 Zen Mode" },
    },
    opts = {
      plugins = {
        alacritty = {
          enabled = true,
        },
      },
      float = {
        padding = 4,
        max_height = 32,
      },
    },
  },

  -- In your alpha-nvim configuration:
  {
    "goolord/alpha-nvim",
    opts = function(_, opts)
      local lines, highlights = parse_ansi_to_highlights(brainfuck_output)
      opts.section.header.val = lines
      opts.section.header.opts = {
        position = "center",
        hl = highlights,
      }
      return opts
    end,
  },

  -- Git Conflict resolving tool
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    opts = {
      default_mappings = false, -- disable buffer local mapping created by this plugin
      default_commands = true, -- disable commands created by this plugin
      disable_diagnostics = false, -- This will disable the diagnostics in a buffer whilst it is conflicted
      list_opener = "copen", -- command or function to open the conflicts list
      highlights = { -- They must have background color, otherwise the default color will be used
        incoming = "DiffAdd",
        current = "DiffText",
      },
    },
    config = function(plugin)
      require("git-conflict").setup(plugin.opts)
      local wk = require "which-key"
      wk.add {
        { "<leader>gr", desc = "Git Conflict", group = true },
        { "<leader>gro", "<cmd>GitConflictChooseOurs<cr>", desc = "Choose Ours" }, -- Select the current changes
        { "<leader>grt", "<cmd>GitConflictChooseTheirs<cr>", desc = "Choose Theirs" }, -- Select the incoming changes
        { "<leader>grb", "<cmd>GitConflictChooseBoth<cr>", desc = "Choose Both" }, -- Select both changes
        { "<leader>gr0", "<cmd>GitConflictChooseNone<cr>", desc = "Choose None" }, -- Select none of the changes
        { "<leader>grn", "<cmd>GitConflictNextConflict<cr>", desc = "Next Conflict" }, -- Move to the next conflict
        { "<leader>grp", "<cmd>GitConflictPrevConflict<cr>", desc = "Previous Conflict" }, -- Move to the previous conflict
        { "<leader>grl", "<cmd>GitConflictListQf<cr>", desc = "List Conflicts" }, -- Get all conflicts to quickfix
      }
    end,
    -- config = true,
  },

  -- Center on searched items.
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        mappings = {
          i = {
            -- When selecting a search item in telescope, center my buffer on that value.
            ["<CR>"] = function(prompt_bufnr)
              local actions = require "telescope.actions"
              ---@diagnostic disable-next-line: redundant-return-value
              actions.select_default(prompt_bufnr)
              actions.center(prompt_bufnr)
            end,
          },
        },
      },
    },
  },

  -- Allow pretty display of LSP diagnostic messages.
  -- Toggle: <leader>lv
  -- Useful when there are too many messages overtop of each other.
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    ---@diagnostic disable-next-line: assign-type-mismatch
    opts = true,
    config = function()
      -- Disable virtual_text since it's redundant due to lsp_lines.
      vim.diagnostic.config {
        virtual_text = state.virtual_text,
      }
      require("lsp_lines").setup()
    end,
    lazy = true,
    keys = {
      {
        "<leader>lv",
        function()
          require("lsp_lines").toggle()

          state.virtual_text = not state.virtual_text
          vim.diagnostic.config {
            virtual_text = state.virtual_text,
          }
        end,
        mode = "n",
        desc = "LSP Lines toggle",
      },
    },
  },
}
