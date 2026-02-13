-- defaults for omitted server options (you probably don't want to change these)
local defaultLanguageServerOptions = {
    -- Unique name for the server to be shown in statusbar and logs
    -- Defaults to the same as cmd if omitted
    shortName = nil,

    -- (REQUIRED) command to execute the language server
    cmd = "",

    -- Arguments for the above command
    args = {},

    -- List of filetypes supported by the server.
    -- Defaults to accepting all filetypes if omitted.
    -- NOTE: filetypes should match the names given in micro syntax files at
    -- https://github.com/zyedidia/micro/tree/master/runtime/syntax
    filetypes = nil,

    -- Language server specific options that are sent to the server during
    -- initialization - you can usually omit this field
    initializationOptions = nil,

    -- callback function that is called when language server is initialized
    -- (useful for debugging and disabling server capabilities)
    -- For example to disable getting hover information from a server:
    -- onInitialized = function(client)
    --     client.serverCapabilities.hoverProvider = false
    -- end
    onInitialized = nil,
}

-- Pre-made configurations for commonly used language servers - you can also
-- define your own servers to be used in settings at the bottom of this file.
-- See defaultLanguageServerOptions above for the available options.
languageServer = {
    biome = {
        cmd = "bunx",
        args = {"@biomejs/biome", "lsp-proxy"},
        filetypes = {"javascript", "typescript", "json", "css", "html", "vue", "svelte"}
    },
    bunts = {
        shortName = "bunts",
        cmd = "bunx",
        args = {"typescript-language-server", "--stdio"},
        filetypes = {"typescript", "javascript"}
    },
    clangd = {
        cmd = "clangd",
        filetypes = {"c", "cpp", "objc", "cuda", "proto"}
    },
    clojurelsp = {
        cmd = "clojure-lsp",
        filetypes = {"clojure"}
    },
    crystalline = {
        cmd = "crystalline",
        filetypes = {"crystal"}
    },
    deno = {
        cmd = "deno",
        args = {"lsp"},
        filetypes = {"javascript", "typescript", "markdown", "json"}
    },
    jsonls = {
        shortName = "jsonls",
        cmd = "vscode-json-language-server",
        args = {"--stdio"},
        filetypes = {"json"}
    },
    gopls = {
        cmd = "gopls",
        filetypes = {"go", "gomod", "godoc"}
    },
    hls = {
        shortName = "hls",
        cmd = "haskell-language-server-wrapper",
        args = {"--lsp"},
        filetypes = {"haskell"}
    },
    julials = {
        shortName = "julials",
        cmd = "julia",
        args = {"--startup-file=no", "--history-file=no", "-e", "using LanguageServer; runserver()"},
        filetypes = {"julia"}
    },
    lualsp = {
        cmd = "lua-lsp",
        filetypes = {"lua"}
    },
    luals = {
        shortName = "luals",
        cmd = "lua-language-server",
        filetypes = {"lua"},
        initializationOptions = {
            settings = {
                Lua = {
                    diagnostics = {
                        globals = {"import"}
                    }
                }
            }
        }
    },
    marksman = {
        cmd = "marksman",
        args = {"server"},
        filetypes = {"markdown"}
    },
    ols = {
        cmd = "ols",
        filetypes = {"odin"},
    },
    pylsp = {
        cmd = "pylsp",
        filetypes = {"python"}
    },
    pyright = {
        shortName = "pyright",
        cmd = "pyright-langserver",
        args = {"--stdio"},
        filetypes = {"python"}
    },
    quicklintjs = {
        cmd = "quick-lint-js",
        args = {"--lsp"},
        filetypes = {"javascript", "typescript"}
    },
    rubocop = {
        cmd = "rubocop",
        args = {"--lsp"},
        filetypes = {"ruby"}
    },
    rubylsp = {
        cmd = "ruby-lsp",
        filetypes = {"ruby", "eruby"}
    },
    ruff = {
        cmd = "ruff",
        args = {"server"},
        onInitialized = function(client)
            -- does not give useful results
            client.serverCapabilities.hoverProvider = false
        end,
        filetypes = {"python"}
    },
    ty = {
        cmd = "ty",
        args = {"lsp"},
        filetypes = {"python"}
    },
    rustAnalyzer = {
        shortName = "rust",
        cmd = "rust-analyzer",
        filetypes = {"rust"}
    },
    solargraph = {
        cmd = "solargraph",
        args = {"stdio"},
        filetypes = {"ruby"}
    },
    zls = {
        cmd = "zls",
        filetypes = {"zig"}
    },
    yamlls = {
        shortName = "yamlls",
        cmd = "yaml-language-server",
        args = {"--stdio"},
        filetypes = {"yaml", "yml"}
    },
    metals = {
        cmd = "metals",
        filetypes = {"scala", "java"}
    }
}

-- you don't need to care about this part but it's basically filling in defaults
-- for all missing fields in language servers defined above
defaultLanguageServerOptions.__index = defaultLanguageServerOptions
for _, server in pairs(languageServer) do
    setmetatable(server, defaultLanguageServerOptions)
end


settings = {

    -- Use LSP completion in place of micro's default Autocomplete action when
    -- available (you can bind `command:lsp autocomplete` command to a different
    -- key in ~/.config/micro/bindings.json even if this setting is false)
    tabAutocomplete = false,

    -- Format the document using LSP on save when supported
    formatOnSave = true,

    -- Automatically start language server(s) when a buffer with matching
    -- filetype is opened
    autostart = {
        lua = { languageServer.luals },
        json = { languageServer.jsonls },
        yaml = { languageServer.yamlls },
        yml = { languageServer.yamlls },
        markdown = { languageServer.marksman },
        python = { languageServer.ruff, languageServer.ty },
        typescript = { languageServer.bunts, languageServer.biome },

        -- Example #1: Start gopls when editing .go files:
        -- go = { languageServer.gopls },

        -- Example #2: Start pylsp AND ruff-lsp when editing Python files:
        -- python = { languageServer.pylsp, languageServer.ruff },
    },

    -- Language server to use when `lsp` command is executed without args
    defaultLanguageServer = {
        c          = languageServer.clangd,
        ["c++"]    = languageServer.clangd,
        clojure    = languageServer.clojurelsp,
        crystal    = languageServer.crystalline,
        go         = languageServer.gopls,
        haskell    = languageServer.hls,
        javascript = languageServer.deno,
        julia      = languageServer.julials,
        json       = languageServer.jsonls,
        lua        = languageServer.luals,
        markdown   = languageServer.marksman,
        odin       = languageServer.ols,
        python     = languageServer.ty,
        ruby       = languageServer.rubylsp,
        rust       = languageServer.rustAnalyzer,
        scala      = languageServer.metals,
        typescript = languageServer.bunts,
        yaml       = languageServer.yamlls,
        zig        = languageServer.zls,
    },

    -- Set to true to disable all LSP features in buffers with 'unknown' filetype
    ignoreBuffersWithUnknownFiletype = false,

    -- Which kinds of diagnostics to show in the gutter
    showDiagnostics = {
        error       = true,
        warning     = true,
        information = false,
        hint        = false
    },

    -- Default keybindings (Ctrl-Shift is treated as Ctrl by terminals)
    defaultBindings = {
        ["Alt-G"] = "command:lsp goto-definition",
        ["Alt-I"] = "command:lsp goto-implementation",
        ["Alt-R"] = "command:lsp find-references",
        ["Alt-F"] = "command:lsp format",
        ["Alt-D"] = "command:lsp diagnostic-info",
    },
    defaultBindingsOverwrite = false,
}
