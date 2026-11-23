return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- registro extra de Mason que incluye el servidor "roslyn"
  {
    "mason-org/mason.nvim",
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
    },
  },

  -- C# / .NET: LSP Roslyn (el mismo de VS Code)
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor" },
    -- cargar lspconfig antes para que se apliquen capabilities y mappings de NvChad
    dependencies = { "neovim/nvim-lspconfig" },
    opts = {},
  },

  -- C# / .NET: gestión de soluciones (.sln), build, run, tests, NuGet
  {
    "GustavEikaas/easy-dotnet.nvim",
    ft = { "cs", "fsharp", "razor" },
    cmd = "Dotnet",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    opts = {
      picker = "telescope",
      -- el LSP ya lo da roslyn.nvim; evitar un segundo servidor Roslyn
      lsp = { enabled = false },
    },
    keys = {
      { "<leader>nb", "<cmd>Dotnet build<cr>", desc = "Dotnet build" },
      { "<leader>nr", "<cmd>Dotnet run<cr>", desc = "Dotnet run" },
      { "<leader>nt", "<cmd>Dotnet testrunner<cr>", desc = "Dotnet test runner" },
      { "<leader>ns", "<cmd>Dotnet solution select<cr>", desc = "Dotnet select solution" },
      { "<leader>np", "<cmd>Dotnet project view<cr>", desc = "Dotnet project view" },
      { "<leader>nn", "<cmd>Dotnet<cr>", desc = "Dotnet commands" },
    },
  },

  -- Debugger .NET (netcoredbg)
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "DAP continue/start" },
      { "<F10>", function() require("dap").step_over() end, desc = "DAP step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "DAP step into" },
      { "<F12>", function() require("dap").step_out() end, desc = "DAP step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP toggle breakpoint" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "DAP toggle REPL" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "DAP terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "DAP toggle UI" },
    },
    config = function()
      require "configs.dap"
    end,
  },

  -- Claude Code en un panel lateral
  {
    "coder/claudecode.nvim",
    cmd = { "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSend", "ClaudeCodeAdd" },
    opts = {
      terminal = {
        split_side = "right",
        split_width_percentage = 0.35,
        provider = "native",
      },
    },
    keys = {
      { "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Claude toggle" },
      { "<leader>cf", "<cmd>ClaudeCodeFocus<cr>", desc = "Claude focus" },
      { "<leader>cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude send selection" },
      { "<leader>cb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude add current buffer" },
      { "<leader>ca", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude accept diff" },
      { "<leader>cd", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude deny diff" },
    },
  },

  -- Cursor animado con estela + partículas (config "Fire Hazard" del README)
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      cursor_color = "#7FFFD4",
      particles_enabled = true,
      stiffness = 0.5,
      trailing_stiffness = 0.2,
      trailing_exponent = 8,
      damping = 0.6,
      gradient_exponent = 0,
      gamma = 0.5,
      never_draw_over_target = true, -- para ver lo que hay bajo el cursor
      hide_target_hack = true,
      particle_spread = 1,
      particles_per_second = 600,
      particles_per_length = 50,
      particle_max_lifetime = 800,
      particle_max_initial_velocity = 20,
      particle_velocity_from_cursor = 0.5,
      particle_damping = 0.25,
      particle_gravity = 50,
      min_distance_emit_particles = 0,
    },
  },

  -- Animaciones al abrir/cerrar ventanas (splits, floats) y al redimensionar
  {
    "echasnovski/mini.animate",
    event = "VeryLazy",
    opts = function()
      local animate = require "mini.animate"
      return {
        open = { timing = animate.gen_timing.linear { duration = 350, unit = "total" } },
        close = { timing = animate.gen_timing.linear { duration = 150, unit = "total" } },
        resize = { timing = animate.gen_timing.linear { duration = 100, unit = "total" } },
        cursor = { enable = false }, -- ya lo hace smear-cursor
        scroll = { enable = false }, -- ponelo en true si querés scroll suave
      }
    end,
  },

  -- Explorador de archivos: config de nvim-tree copiada de cpea2506/nvim
  -- (lua/pea/plugins/nvimtree.lua, último commit antes de reemplazarlo por oil)
  {
    "nvim-tree/nvim-tree.lua",
    event = "BufEnter",
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Open Explorer" },
    },
    opts = function()
      -- highlights de base46 (NvChad) para nvim-tree
      dofile(vim.g.base46_cache .. "nvimtree")

      -- icons.git de pea.config.ui.icons
      local git_icons = {
        FileDeleted = "",
        FileIgnored = "◌",
        FileRenamed = "",
        FileStaged = "✓",
        FileUnmerged = "",
        FileUnstaged = "✗",
        FileUntracked = "★",
      }

      return {
        reload_on_bufenter = true,
        hijack_cursor = true,
        hijack_netrw = true,
        sync_root_with_cwd = true,
        hijack_unnamed_buffer_when_opening = true,
        auto_reload_on_write = true,
        diagnostics = {
          enable = false,
        },
        -- al iniciar se muestra el dashboard (nvdash) en vez del árbol
        hijack_directories = {
          enable = false,
          auto_open = false,
        },
        actions = {
          open_file = {
            quit_on_open = true,
            resize_window = true,
          },
        },
        update_focused_file = {
          enable = true,
        },
        filters = {
          enable = false,
        },
        on_attach = function(bufnr)
          local api = require "nvim-tree.api"

          local function opts(desc)
            return {
              desc = "nvim-tree: " .. desc,
              buffer = bufnr,
              noremap = true,
              silent = true,
              nowait = true,
            }
          end

          vim.keymap.set("n", "<C-]>", api.tree.change_root_to_node, opts "CD")
          vim.keymap.set("n", "<C-e>", api.node.open.replace_tree_buffer, opts "Open: In Place")
          vim.keymap.set("n", "<C-k>", api.node.show_info_popup, opts "Info")
          vim.keymap.set("n", "<C-r>", api.fs.rename_sub, opts "Rename: Omit Filename")
          vim.keymap.set("n", "<C-t>", api.node.open.tab, opts "Open: New Tab")
          vim.keymap.set("n", "<C-v>", api.node.open.vertical, opts "Open: Vertical Split")
          vim.keymap.set("n", "<C-x>", api.node.open.horizontal, opts "Open: Horizontal Split")
          vim.keymap.set("n", "<BS>", api.node.navigate.parent_close, opts "Close Directory")
          vim.keymap.set("n", "<CR>", api.node.open.edit, opts "Open")
          vim.keymap.set("n", "<Tab>", api.node.open.preview, opts "Open Preview")
          vim.keymap.set("n", ">", api.node.navigate.sibling.next, opts "Next Sibling")
          vim.keymap.set("n", "<", api.node.navigate.sibling.prev, opts "Previous Sibling")
          vim.keymap.set("n", ".", api.node.run.cmd, opts "Run Command")
          vim.keymap.set("n", "-", api.tree.change_root_to_parent, opts "Up")
          vim.keymap.set("n", "a", api.fs.create, opts "Create File Or Directory")
          vim.keymap.set("n", "c", api.fs.copy.node, opts "Copy")
          vim.keymap.set("n", "[c", api.node.navigate.git.prev, opts "Prev Git")
          vim.keymap.set("n", "]c", api.node.navigate.git.next, opts "Next Git")
          vim.keymap.set("n", "d", api.fs.remove, opts "Delete")
          vim.keymap.set("n", "D", api.fs.trash, opts "Trash")
          vim.keymap.set("n", "E", api.tree.expand_all, opts "Expand All")
          vim.keymap.set("n", "e", api.fs.rename_basename, opts "Rename: Basename")
          vim.keymap.set("n", "]e", api.node.navigate.diagnostics.next, opts "Next Diagnostic")
          vim.keymap.set("n", "[e", api.node.navigate.diagnostics.prev, opts "Prev Diagnostic")
          vim.keymap.set("n", "g?", api.tree.toggle_help, opts "Help")
          vim.keymap.set("n", "gy", api.fs.copy.absolute_path, opts "Copy Absolute Path")
          vim.keymap.set("n", "ge", api.fs.copy.basename, opts "Copy Basename")
          vim.keymap.set("n", "H", api.tree.toggle_hidden_filter, opts "Toggle Filter: Dotfiles")
          vim.keymap.set("n", "I", api.tree.toggle_gitignore_filter, opts "Toggle Filter: Git Ignore")
          vim.keymap.set("n", "J", api.node.navigate.sibling.last, opts "Last Sibling")
          vim.keymap.set("n", "K", api.node.navigate.sibling.first, opts "First Sibling")
          vim.keymap.set("n", "L", api.node.open.toggle_group_empty, opts "Toggle Group Empty")
          vim.keymap.set("n", "o", api.node.open.edit, opts "Open")
          vim.keymap.set("n", "O", api.node.open.no_window_picker, opts "Open: No Window Picker")
          vim.keymap.set("n", "p", api.fs.paste, opts "Paste")
          vim.keymap.set("n", "P", api.node.navigate.parent, opts "Parent Directory")
          vim.keymap.set("n", "q", api.tree.close, opts "Close")
          vim.keymap.set("n", "r", api.fs.rename, opts "Rename")
          vim.keymap.set("n", "R", api.tree.reload, opts "Refresh")
          vim.keymap.set("n", "s", api.node.run.system, opts "Run System")
          vim.keymap.set("n", "u", api.fs.rename_full, opts "Rename: Full Path")
          vim.keymap.set("n", "U", api.tree.toggle_custom_filter, opts "Toggle Filter: Hidden")
          vim.keymap.set("n", "W", api.tree.collapse_all, opts "Collapse")
          vim.keymap.set("n", "x", api.fs.cut, opts "Cut")
          vim.keymap.set("n", "y", api.fs.copy.filename, opts "Copy Name")
          vim.keymap.set("n", "Y", api.fs.copy.relative_path, opts "Copy Relative Path")
        end,
        view = {
          centralize_selection = true,
          adaptive_size = false,
          side = "right",
          preserve_window_proportions = true,
          width = 30,
        },
        renderer = {
          full_name = false,
          indent_markers = {
            enable = true,
          },
          root_folder_label = ":t",
          icons = {
            glyphs = {
              git = {
                unmerged = git_icons.FileUnmerged,
                renamed = git_icons.FileRenamed,
                deleted = git_icons.FileDeleted,
                ignored = git_icons.FileIgnored,
                unstaged = git_icons.FileUnstaged,
                staged = git_icons.FileStaged,
                untracked = git_icons.FileUntracked,
              },
            },
          },
        },
      }
    end,
    config = function(_, opts)
      local nvimtree = require "nvim-tree"

      nvimtree.setup(opts)

      -- mantener el árbol siempre pegado al borde derecho: si otro split
      -- (p. ej. el panel de Claude con botright) lo desplaza, se lo vuelve a mover
      local moving = false
      local function keep_tree_rightmost()
        if moving then
          return
        end
        local view = require "nvim-tree.view"
        local win = view.get_winnr()
        if not win or not vim.api.nvim_win_is_valid(win) then
          return
        end
        if vim.api.nvim_win_get_config(win).relative ~= "" then
          return -- flotante
        end
        local col = vim.api.nvim_win_get_position(win)[2]
        if col + vim.api.nvim_win_get_width(win) >= vim.o.columns then
          return -- ya está a la derecha
        end
        moving = true
        vim.api.nvim_win_call(win, function()
          vim.cmd "wincmd L"
        end)
        vim.api.nvim_win_set_width(win, opts.view.width)
        moving = false
      end

      vim.api.nvim_create_autocmd({ "WinNew", "WinClosed", "BufWinEnter", "VimResized" }, {
        group = vim.api.nvim_create_augroup("nvim-tree-right", { clear = true }),
        callback = function()
          vim.schedule(keep_tree_rightmost)
        end,
      })
    end,
  },

  -- Dividir / unir bloques de código (argumentos, tablas, objetos) con treesitter
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
    keys = {
      { "<leader>tt", "<cmd>TSJToggle<cr>", desc = "TreeSJ toggle split/join" },
      { "<leader>ts", "<cmd>TSJSplit<cr>", desc = "TreeSJ split" },
      { "<leader>tj", "<cmd>TSJJoin<cr>", desc = "TreeSJ join" },
    },
    opts = {
      use_default_keymaps = false, -- los default (<leader>m/j/s) chocan con <leader>ma de NvChad
      max_join_length = 150,
    },
  },

  -- Telescope: <C-o> abre el/los archivo(s) seleccionados en una nueva ventana
  -- de Windows Terminal (con nvim, posicionado en la línea si viene de un grep)
  {
    "nvim-telescope/telescope.nvim",
    opts = function(_, conf)
      -- la lógica de abrir en Windows Terminal está en lua/configs/wt_open.lua
      -- (compartida con el <C-o> del panel de neogit)
      local open_in_new_terminal = require("configs.wt_open").telescope

      conf.defaults = conf.defaults or {}
      conf.defaults.mappings = conf.defaults.mappings or {}
      for _, mode in ipairs { "i", "n" } do
        conf.defaults.mappings[mode] = conf.defaults.mappings[mode] or {}
        conf.defaults.mappings[mode]["<C-o>"] = open_in_new_terminal
      end
      return conf
    end,
  },

  -- Noice: UI nueva para mensajes, cmdline y notificaciones (popups vía nvim-notify)
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      {
        "rcarriga/nvim-notify",
        opts = {
          -- con transparency = true el bg de Normal es NONE; notify necesita un color fijo
          background_colour = "#000000",
          timeout = 3000,
          stages = "fade_in_slide_out",
          render = "wrapped-compact",
        },
        config = function(_, opts)
          pcall(dofile, vim.g.base46_cache .. "notify")
          require("notify").setup(opts)
        end,
      },
    },
    opts = {
      lsp = {
        -- usar markdown de treesitter en hover/docs
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
        -- NvChad ya tiene su propio signature help
        signature = { enabled = false },
      },
      presets = {
        bottom_search = true, -- / y ? abajo, como siempre
        command_palette = true, -- cmdline y popupmenu juntos arriba
        long_message_to_split = true, -- mensajes largos van a un split
        lsp_doc_border = true,
      },
    },
    keys = {
      { "<leader>nh", "<cmd>Noice telescope<cr>", desc = "Noice historial (telescope)" },
      { "<leader>nl", "<cmd>Noice last<cr>", desc = "Noice último mensaje" },
      { "<leader>nd", "<cmd>Noice dismiss<cr>", desc = "Noice cerrar notificaciones" },
    },
    config = function(_, opts)
      require("noice").setup(opts)
      pcall(require("telescope").load_extension, "noice")
    end,
  },

  -- Resalta con animación el texto que cambia: undo, redo, yank, paste y búsqueda
  -- (sin cursor_moved: eso ya lo hace smear-cursor)
  {
    "y3owk1n/undo-glow.nvim",
    event = "VeryLazy",
    opts = {
      animation = {
        enabled = true,
        duration = 300,
        animation_type = "zoom",
        window_scoped = true,
      },
      highlights = {
        undo = { hl_color = { bg = "#693232" } }, -- rojo apagado
        redo = { hl_color = { bg = "#2F4640" } }, -- verde apagado
        yank = { hl_color = { bg = "#7A683A" } }, -- amarillo apagado
        paste = { hl_color = { bg = "#325B5B" } }, -- cian apagado
        search = { hl_color = { bg = "#5C475C" } }, -- violeta apagado
      },
      priority = 2048 * 3,
    },
    keys = {
      { "u", function() require("undo-glow").undo() end, desc = "Undo con glow" },
      { "<C-r>", function() require("undo-glow").redo() end, desc = "Redo con glow" },
      { "p", function() require("undo-glow").paste_below() end, desc = "Pegar abajo con glow" },
      { "P", function() require("undo-glow").paste_above() end, desc = "Pegar arriba con glow" },
      { "n", function() require("undo-glow").search_next { animation = { animation_type = "strobe" } } end, desc = "Siguiente resultado con glow" },
      { "N", function() require("undo-glow").search_prev { animation = { animation_type = "strobe" } } end, desc = "Resultado anterior con glow" },
      { "*", function() require("undo-glow").search_star { animation = { animation_type = "strobe" } } end, desc = "Buscar palabra (adelante) con glow" },
      { "#", function() require("undo-glow").search_hash { animation = { animation_type = "strobe" } } end, desc = "Buscar palabra (atrás) con glow" },
    },
    init = function()
      local group = vim.api.nvim_create_augroup("undo-glow-user", { clear = true })
      vim.api.nvim_create_autocmd("TextYankPost", {
        group = group,
        desc = "Glow al copiar (yank)",
        callback = function()
          require("undo-glow").yank()
        end,
      })
      vim.api.nvim_create_autocmd("CmdlineLeave", {
        group = group,
        desc = "Glow al terminar una búsqueda con / o ?",
        callback = function()
          require("undo-glow").search_cmd { animation = { animation_type = "fade" } }
        end,
      })
    end,
  },

  -- Git estilo VS Code -------------------------------------------------------

  -- Panel "Source Control": stage, commit, push, pull, ramas, stash, log
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Git: panel Source Control (neogit)" },
      { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Git: commit" },
      { "<leader>gP", "<cmd>Neogit push<cr>", desc = "Git: push" },
      { "<leader>gl", "<cmd>Neogit pull<cr>", desc = "Git: pull" },
      { "<leader>gB", "<cmd>Telescope git_branches<cr>", desc = "Git: cambiar de rama" },
    },
    opts = {
      kind = "vsplit_left", -- panel a la izquierda, como la barra lateral de VS Code
      graph_style = "unicode",
      integrations = {
        diffview = true, -- los diffs se abren lado a lado con diffview
        telescope = true,
      },
      -- editor del commit como "caja de chat" flotante (ver lua/configs/commit_box.lua)
      commit_editor = { kind = "floating", show_staged_diff = false, spell_check = false },
      floating = { relative = "editor", width = 0.5, height = 10, style = "minimal", border = "rounded" },
      disable_insert_on_commit = false, -- siempre empezar escribiendo
      mappings = {
        commit_editor_I = { ["<cr>"] = "Submit" }, -- Enter = commit (como enviar en un chat)
        commit_editor = { ["<cr>"] = "Submit", ["<esc>"] = "Abort" }, -- Esc en normal = cancelar
      },
    },
    config = function(_, opts)
      require("neogit").setup(opts)
      -- <C-o> en el panel: abrir el archivo bajo el cursor en una pestaña nueva
      -- de Windows Terminal (igual que <C-o> en Telescope; ver lua/configs/wt_open.lua)
      -- (los números de línea del panel se quitan en lua/options.lua, junto con
      -- los de la terminal, nvim-tree y nvdash)

      -- caja del commit: título, ayuda, plantilla plegada y Shift+Enter
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("neogit-commit-box", { clear = true }),
        pattern = "gitcommit",
        callback = function(args)
          -- neogit abre la ventana y escribe la ayuda después del FileType
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
              require("configs.commit_box").setup_window(args.buf)
            end
          end)
        end,
      })
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("neogit-wt-open", { clear = true }),
        pattern = "NeogitStatus",
        callback = function(args)
          vim.keymap.set("n", "<C-o>", function()
            require("configs.wt_open").neogit()
          end, { buffer = args.buf, desc = "Abrir archivo en nueva terminal" })
        end,
      })
    end,
  },

  -- Diff lado a lado, historial de archivo y editor de conflictos de merge
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Git: ver cambios (diff lado a lado)" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Git: cerrar diffview" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Git: historial del archivo" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Git: historial del repo" },
    },
    opts = {
      enhanced_diff_hl = true, -- resaltado de diff más parecido a VS Code
      view = {
        merge_tool = { layout = "diff3_mixed" }, -- arriba: actual | entrante; abajo: resultado
      },
    },
  },

  -- gitsigns ya viene con NvChad: se le suma blame en línea (estilo GitLens) y atajos
  {
    "lewis6991/gitsigns.nvim",
    opts = function()
      local opts = require "nvchad.configs.gitsigns"
      opts.current_line_blame = true
      opts.current_line_blame_opts = { delay = 500, virt_text_pos = "eol" }
      opts.current_line_blame_formatter = "    <author>, <author_time:%R> • <summary>"
      return opts
    end,
    keys = {
      { "]h", "<cmd>Gitsigns nav_hunk next<cr>", desc = "Git: siguiente cambio" },
      { "[h", "<cmd>Gitsigns nav_hunk prev<cr>", desc = "Git: cambio anterior" },
      { "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", desc = "Git: previsualizar cambio" },
      { "<leader>gs", "<cmd>Gitsigns stage_hunk<cr>", mode = { "n", "v" }, desc = "Git: stage del cambio" },
      { "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", mode = { "n", "v" }, desc = "Git: descartar cambio" },
      { "<leader>gS", "<cmd>Gitsigns stage_buffer<cr>", desc = "Git: stage del archivo" },
      { "<leader>gR", "<cmd>Gitsigns reset_buffer<cr>", desc = "Git: descartar cambios del archivo" },
      { "<leader>gb", "<cmd>Gitsigns blame_line full=true<cr>", desc = "Git: blame de la línea" },
      { "<leader>ga", "<cmd>Gitsigns blame<cr>", desc = "Git: blame del archivo" },
      { "<leader>gx", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "Git: mostrar/ocultar blame en línea" },
    },
  },

  -- Outline: árbol de la clase (campos, propiedades, métodos) vía LSP documentSymbol
  -- (a la izquierda: la derecha ya la usan nvim-tree y el panel de Claude)
  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    init = function()
      -- roslyn manda los miembros como "Nombre(TipoParam, ...) : TipoRetorno" (o "_campo : Tipo").
      -- aerial pinta todo el nombre con un extmark; los matchadd de ventana le ganan,
      -- así que se colorean parámetros y tipo sin tocar el color del nombre
      vim.api.nvim_set_hl(0, "AerialParams", { link = "@variable.parameter", default = true })
      vim.api.nvim_set_hl(0, "AerialReturnType", { link = "@type", default = true })
      vim.api.nvim_set_hl(0, "AerialSignaturePunct", { link = "Comment", default = true })
      -- panel ("aerial") y flotante ("aerial-nav"). El flotante pone el filetype antes de abrir
      -- sus ventanas, así que los match se aplican diferido y por id a cada ventana del buffer;
      -- BufWinEnter cubre el buffer que se vuelve a mostrar en otra ventana (toggle del panel)
      local signature_fts = { aerial = true, ["aerial-nav"] = true }
      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
        group = vim.api.nvim_create_augroup("AerialSignatureColors", { clear = true }),
        callback = function(args)
          if not signature_fts[vim.bo[args.buf].filetype] then return end
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(args.buf) then return end
            for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
              if not vim.w[win].aerial_signature_colors then
                vim.w[win].aerial_signature_colors = true
                vim.fn.matchadd("AerialParams", [[\v\(\zs[^)]+\ze\)]], 20, -1, { window = win })
                vim.fn.matchadd("AerialReturnType", [[\v \: \zs.+$]], 20, -1, { window = win })
                vim.fn.matchadd("AerialSignaturePunct", [[\v[()]| \zs\:\ze ]], 20, -1, { window = win })
              end
            end
          end)
        end,
      })
    end,
    opts = {
      backends = { "lsp", "treesitter" }, -- roslyn primero; treesitter si no hay LSP
      layout = {
        default_direction = "left",
        placement = "edge",
        min_width = 30,
        max_width = { 50, 0.25 },
        -- aerial fuerza wrap = false; esto lo pisa para que los nombres largos bajen de línea
        win_opts = {
          wrap = true,
          linebreak = true, -- corta en palabra, no a mitad
          breakindent = true, -- la continuación respeta la sangría del ítem
          breakindentopt = "shift:2",
        },
      },
      attach_mode = "global", -- el panel sigue al buffer activo
      filter_kind = {
        "Class", "Constructor", "Enum", "Field", "Function",
        "Interface", "Method", "Module", "Property", "Struct",
      },
      show_guides = true,
      highlight_on_hover = true,
      close_on_select = false,
      nav = {
        preview = true,
        -- mismo wrap que el panel (se suma a cursorline/winblend por defecto del flotante)
        win_opts = {
          wrap = true,
          linebreak = true,
          breakindent = true,
          breakindentopt = "shift:2",
        },
      },
      keymaps = {
        -- buscador dentro del panel: abre el de <leader>fs sobre el archivo que muestra el panel
        ["/"] = {
          callback = function()
            local source_win = require("aerial.util").get_source_win()
            if source_win and vim.api.nvim_win_is_valid(source_win) then
              vim.api.nvim_set_current_win(source_win)
            end
            require("configs.aerial_symbols").pick()
          end,
          desc = "Buscar entre los miembros del archivo",
        },
      },
    },
    keys = {
      { "<leader>o", "<cmd>AerialToggle<cr>", desc = "Outline: árbol de la clase (panel)" },
      { "<leader>O", "<cmd>AerialNavToggle<cr>", desc = "Outline: navegación flotante" },
      {
        "<leader>fs",
        function()
          require("configs.aerial_symbols").pick()
        end,
        desc = "Telescope: miembros del archivo",
      },
    },
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim", "lua", "luadoc", "printf", "vimdoc",
        "html", "css",
        "c_sharp", "xml", "json", "razor",
        -- usados por noice (cmdline, hover)
        "markdown", "markdown_inline", "regex", "bash",
      },
    },
  },
}
