local function live()
    local file_fullname = vim.api.nvim_buf_get_name(0)
    local httpd_url, error_code = string.gsub(file_fullname, '/Users/xell/Sites', 'http://localhost:8080')
    if error_code == 1 then
        print(httpd_url)
        vim.system({'open', httpd_url})
    else
        print('The file is not in Sites.')
    end
end

vim.api.nvim_buf_create_user_command(0, 'Live', live, {})

