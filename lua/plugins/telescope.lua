-- vim:
return {
    -- https://github.com/nvim-telescope/telescope.nvim
    { 'nvim-telescope/telescope.nvim', -- {{{
        config = function()
            -- call win_getid() or win_gotoid(win_findbuf(bufnr)[0])
            -- https://www.reddit.com/r/neovim/comments/11otu7l/using_telescope_selection_for_custom_function/
            -- https://github.com/nvim-telescope/telescope.nvim/issues/2188
            local actions = require('telescope.actions')
            local map_s_cr = {
                i = { ['<S-CR>'] = actions.select_tab_drop },
                n = { ['<S-CR>'] = actions.select_tab_drop },
            }
            -- layout https://www.reddit.com/r/neovim/comments/1ar56k0/how_to_see_deeply_nested_file_names_in_telescope/
            require 'telescope'.setup {
                defaults = {
                    path_display = { 'truncate' }, -- 'smart'
                    -- color_devicons = true,
                    layout_strategy = 'flex',
                    layout_config = {
                        -- vertical = { width = 0.5 },
                        flex = { flip_columns = 110, },
                        preview_cutoff = 10,
                    },
                },
                pickers = {
                    buffers = {
                        mappings = map_s_cr,
                    },
                    find_files = {
                        mappings = map_s_cr,
                    },
                    git_files = {
                        mappings = map_s_cr,
                    },
                    old_files = {
                        mappings = map_s_cr,
                    },
                    live_grep = {
                        mappings = map_s_cr,
                    },
                    grep_string = {
                        mappings = map_s_cr,
                    },
                    -- https://github.com/nvim-telescope/telescope.nvim/issues/2115#issuecomment-1366575821
                    current_buffer_fuzzy_find = {

                    },
                },
            }
            vim.cmd[[
            " with prefix ' without fuzzy
            nnoremap <Leader>fg <cmd>Telescope grep_string search=<CR>
            " https://github.com/nvim-telescope/telescope.nvim/issues/564#issuecomment-1173167550 allows regex
            nnoremap <Leader>fG <cmd>Telescope live_grep<CR>
            nnoremap <Leader>fp <cmd>Telescope find_files follow=true<CR>
            "nnoremap <Leader>ff <cmd>Telescope oldfiles<CR>
            nnoremap <leader>ff <cmd>Telescope frecency<CR>
            nnoremap <leader>fF <cmd>Telescope frecency workspace=CWD<CR>
            nnoremap <Leader>fb <cmd>Telescope buffers<CR>
            nnoremap <Leader>fh <cmd>Telescope help_tags<CR>
            nnoremap <Leader>fH <cmd>Telescope heading<CR>
            nnoremap <Leader>ft <cmd>Telescope tags<CR>
            nnoremap <Leader>fc <cmd>Telescope commands<CR>
            nnoremap <Leader>fC <cmd>Telescope colorscheme<CR>
            nnoremap <Leader>fm <cmd>Telescope marks<CR>
            nnoremap <Leader>fr <cmd>Telescope registers<CR>
            " https://github.com/nvim-telescope/telescope.nvim/issues/394
            nnoremap <Leader>fv <cmd>Telescope find_files follow=true search_dirs=~/.config/nvim<CR>
            nnoremap <Leader>fV <cmd>Telescope find_files follow=true search_dirs=~/.local/share/nvim/lazy<CR>
            nnoremap <Leader>fn :Telescope find_files search_dirs=<C-R>=g:xell_notes_root<CR><CR>
            nnoremap <Leader>fl :Telescope current_buffer_fuzzy_find<CR>
            nnoremap <Leader>fR :Telescope resume<CR>
            " nmap <Leader>fl :BLines<CR>
            " nmap <Leader>fL :Lines<CR>
            " nmap <Leader>fw :Windows<CR>
            ]]
        end,
    }, -- }}}

    -- https://github.com/nvim-telescope/telescope-fzf-native.nvim
    { 'nvim-telescope/telescope-fzf-native.nvim', -- {{{
        build = 'make',
        -- https://www.reddit.com/r/neovim/comments/13cyyhn/search_within_current_buffer/
        config = function()
            require('telescope').setup {
                extensions = {
                    fzf = {
                        fuzzy = true,                   -- false will only do exact matching
                        override_generic_sorter = true, -- override the generic sorter
                        override_file_sorter = true,    -- override the file sorter
                        case_mode = 'smart_case',       -- or 'ignore_case' or 'respect_case'
                        -- the default case_mode is 'smart_case'
                    }
                }
            }
            -- To get fzf loaded and working with telescope, you need to call
            -- load_extension, somewhere after setup function:
            require('telescope').load_extension('fzf')
        end,
    }, -- }}}

    -- https://github.com/debugloop/telescope-undo.nvim/
    { 'debugloop/telescope-undo.nvim', -- {{{
        dependencies = { {
            'nvim-telescope/telescope.nvim',
            dependencies = { 'nvim-lua/plenary.nvim' },
        }, },
        -- lazy style key map
        keys = {
            { '<leader>u', [[:Telescope undo<CR><Esc>]], desc = 'undo history', },
        },
        opts = {
            -- don't use `defaults = { }` here, do this in the main telescope spec
            extensions = {
                undo = {
                    -- telescope-undo.nvim config, see below
                },
            },
        },
        config = function(_, opts)
            require('telescope').setup(opts)
            require('telescope').load_extension('undo')
        end,
    }, -- }}}

    -- https://github.com/crispgm/telescope-heading.nvim
    { 'crispgm/telescope-heading.nvim', -- {{{
        config = function()
            require('telescope').setup {
                extensions = {
                    heading = {
                        treesitter = true,
                    },
                }
            }
            require('telescope').load_extension('heading')
        end
    }, -- }}}

    -- https://github.com/nvim-telescope/telescope-frecency.nvim
    { 'nvim-telescope/telescope-frecency.nvim', -- {{{
        -- to prevent colorscheme highlight problem
        keys = {{ '<Leader>ff', '<cmd>Telescope frecency<CR>', desc = 'Telescope frecency' }},
        config = function()
            require('telescope').setup {
                extensions = {
                    frecency = {
                        matcher = 'fuzzy',
                        path_display = { 'truncate' },
                    },
                }
            }
            require('telescope').load_extension'frecency'
        end,
    }, -- }}}
}
