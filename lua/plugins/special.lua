-- vim:
return {
    -- https://github.com/prichrd/netrw.nvim
    { 'prichrd/netrw.nvim', -- {{{
        cond = not vim.g.vscode,
        config = function()
            require 'netrw'.setup {
                use_devicons = true, -- Uses nvim-web-devicons if true, otherwise use the file icon specified above
                mappings = {},       -- Custom key mappings
            }
        end,
    }, -- }}}
    -- https://github.com/sophacles/vim-processing
    { 'sophacles/vim-processing', -- {{{
        init = function()
            vim.g.processing_fold = 1
        end,
    }, -- }}}
    -- https://github.com/andymass/vim-matchup {{{
    { 'andymass/vim-matchup',
        init = function()
            vim.g.matchup_matchparen_offscreen = { method = 'popup' }
        end,
    }, -- }}}
    -- https://github.com/lervag/vimtex
    { 'lervag/vimtex', -- we don't want to lazy load VimTeX {{{
        cond = not vim.g.vscode,
        lazy = false,
        init = function()
            vim.g.vimtex_fold_enabled = 1
            -- vim.g.vimtex_fold_manual = 1
            vim.g.vimtex_compiler_method = 'tectonic'
            vim.g.vimtex_view_method = 'skim'
            vim.g.vimtex_view_skim_activate = 1
            vim.g.vimtex_view_skim_sync = 1
            vim.g.vimtex_view_skim_reading_bar = 0
            vim.g.vimtex_view_skim_no_select = 1
            vim.g.vimtex_quickfix_autoclose_after_keystrokes = 5
            vim.g.vimtex_matchparen_enabled = 0
            -- https://github.com/lervag/vimtex/issues/1051
            vim.matchup_override_vimtex = 1
            vim.g.matchup_matchparen_deferred = 1
        end,
    }, -- }}}
    -- https://github.com/dimfeld/section-wordcount.nvim
    { 'dimfeld/section-wordcount.nvim', -- {{{
        cond = not vim.g.vscode,
        config = function ()
            require('section-wordcount').setup{
                -- These are the default values and can be omitted
                highlight = ({ 'String', 'Number' })[2],
                virt_text_pos = ({ 'eol', 'right_align', })[1],
            }
            vim.api.nvim_create_autocmd('FileType', {
                desc = 'Show word count',
                pattern = 'markdown',
                group = vim.api.nvim_create_augroup('markdown_wordcount', { clear = true }),
                callback = function (opts)
                    vim.api.nvim_buf_create_user_command(opts.buf, 'ShowWordCount', require('section-wordcount').wordcounter, {})
                end,
            })
        end
    }, -- }}}
    -- https://github.com/barreiroleo/ltex_extra.nvim
    { 'barreiroleo/ltex_extra.nvim', -- {{{
        cond = not vim.g.vscode,
        dev = true,
        ft = { 'markdown', 'tex' },
        dependencies = { 'neovim/nvim-lspconfig' },
        config = function ()
            require('ltex_extra').setup {
                -- boolean : whether to load dictionaries on startup
                -- setting to true will conflict with non-autostart of lsp
                init_check = false,
                -- -- table <string> : languages for which dictionaries will be loaded, e.g. { 'es-AR', 'en-US' }
                -- https://valentjn.github.io/ltex/supported-languages.html#natural-languages
                load_langs = { 'en' },
                -- string : relative or absolute path to store dictionaries
                -- e.g. subfolder in the project root or the current working directory: '.ltex'
                -- e.g. shared files for all projects:  vim.fn.expand('~') .. '/.local/share/ltex'
                path = vim.fn.expand('~') .. '/.local/share/ltex',
                -- boolean : Enable the call to ltex. Usefull for migration and test
                -- server_start = false,
                -- server_opts = {
                -- },
            }
            vim.api.nvim_buf_create_user_command(0, 'LtexReload', function()
                require('ltex_extra').reload()
            end, { desc = 'ltex_extra.nvim: reload' })
        end
    }, -- }}}
}
