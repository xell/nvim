-- let b:search_pattern = g:urlpattern . '\|' . '|[^|[:tab:]]\{-}|\|' . "'[^'[:tab:]]\\{-}'"
vim.b.link_pattern = vim.g.url_pattern .. [[\|]] .. "|[^|[:tab:]]\\{-}|\\|'[^'[:tab:]]\\\\{-}'"
