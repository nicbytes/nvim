-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

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

-- Helper function to strip ANSI escape codes
local function strip_ansi(str)
  if not str then return "" end
  -- This pattern matches ANSI escape sequences
  local clean_str = string.gsub(str, "\27%[[^m]*m", "")
  return clean_str
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

-- Yank full path.
vim.keymap.set("n", "yP", function()
  vim.fn.setreg("+", vim.fn.expand "%:p")
  print "Copied full file path to clipboard!"
end, { desc = "Copy full file path" })

-- Yank relative path
vim.keymap.set("n", "yp", function()
  vim.fn.setreg("+", vim.fn.expand "%")
  print "Copied relative file path to clipboard!"
end, { desc = "Copy relative file path" })

-- Yank buffer contents.
vim.keymap.set("n", "ya", function()
  -- Get all lines in the current buffer (from start index 0 to the end index -1)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  -- Concatenate the lines into one string separated by newline characters
  local contents = table.concat(lines, "\n")
  -- Set the clipboard register to the contents
  vim.fn.setreg("+", contents)
  print "Copied file contents to clipboard!"
end, { desc = "Copy file contents to clipboard" })

vim.keymap.set("n", "yA", function()
  -- Get all lines of the current buffer
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local contents = table.concat(lines, "\n")

  -- Use the buffer's filetype as the language; default to "text"
  local ft = vim.bo.filetype
  if ft == "" then ft = "text" end

  -- Find the longest sequence of backticks in the content
  local max_backticks = 2
  for backticks in contents:gmatch "(`+)" do
    local len = #backticks
    if len > max_backticks then max_backticks = len end
  end

  -- Create a fence that is one backtick longer than the max found
  local fence = string.rep("`", max_backticks + 1)

  -- Construct the markdown wrapped content: fence + language marker, newline,
  -- file contents, newline, then the same fence.
  local wrapped = fence .. ft .. "\n" .. contents .. "\n" .. fence

  -- Set the constructed string into the system clipboard register
  vim.fn.setreg("+", wrapped)
  print "Copied file contents as a Markdown code block to clipboard!"
end, { desc = "Copy file contents wrapped in a Markdown code block" })

---@type LazySpec
return {
  -- { dir = "~/code/datalinks-ai.nvim" },

  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      -- 1. Run the Brainfuck program
      local raw_brainfuck_output = run_brainfuck_from_string(brainfuck_code)

      -- 2. Pre-process the output and calculate widths
      local processed_lines_for_display = {} -- With ANSI, for printf
      local header_height = 0
      local art_width = 0

      for line_with_ansi in raw_brainfuck_output:gmatch "[^\r\n]+" do
        local temp_line_for_display = line_with_ansi
        -- Strip 8 leading characters (original behavior)
        if #temp_line_for_display > 8 then temp_line_for_display = temp_line_for_display:sub(9) end
        table.insert(processed_lines_for_display, temp_line_for_display)

        -- For width calculation, strip ANSI from the line that already had leading spaces removed
        local line_for_calc = strip_ansi(temp_line_for_display)
        art_width = math.max(art_width, vim.fn.strdisplaywidth(line_for_calc))

        header_height = header_height + 1
      end
      local final_header_string_for_snacks = table.concat(processed_lines_for_display, "\n")

      -- Get the dashboard's pane width (snacks default is 60)
      -- The `opts` argument to this function should contain the merged defaults
      local dashboard_pane_width = (opts.dashboard and opts.dashboard.width) or 60

      local centered_indent = 0
      if art_width < dashboard_pane_width then centered_indent = math.floor((dashboard_pane_width - art_width) / 2) end
      -- If art_width is wider than dashboard_pane_width, it will be left-aligned (indent 0)
      -- and potentially clipped by the overall dashboard rendering if it's too wide for the screen.

      -- Define how many columns to shift left from center
      local shift_left_columns = 5 -- Adjust this value as needed
      local final_indent = math.max(0, centered_indent - shift_left_columns)

      -- 3. Configure snacks dashboard sections
      opts.dashboard.sections = {
        {
          section = "terminal",
          cmd = { "printf", "%s", final_header_string_for_snacks },
          height = header_height,
          width = art_width, -- Set the terminal window width to the art's actual width
          indent = final_indent, -- Indent the terminal section itself to center it
          padding = 2, -- Bottom padding for the section
        },
        -- Add other sections you want
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      }

      return opts
    end,
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
