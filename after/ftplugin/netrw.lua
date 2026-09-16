

vim.keymap.set("n", "<Leader>y", function()
    local dir = vim.b.netrw_curdir
    local word = vim.fn["netrw#Call"]("NetrwGetWord")
    local full_path = dir .. "/" .. word
    vim.fn.setreg("+", full_path)
    print("Copied: " .. full_path)
end, { remap = false, buffer = true })
