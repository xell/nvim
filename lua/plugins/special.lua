-- vim:
return {
    -- https://github.com/prichrd/netrw.nvim
    { 'prichrd/netrw.nvim', -- {{{
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
    -- https://github.com/lervag/vimtex
    { 'lervag/vimtex', -- we don't want to lazy load VimTeX {{{
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
        end,
    }, -- }}}
}
