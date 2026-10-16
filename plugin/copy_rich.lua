-- :[range]MarkdownCopyRich
--
-- Copy Markdown as rendered rich text, the same way copying a selection out
-- of a web browser does: pandoc turns the lines into HTML, and the macOS
-- clipboard gets three representations at once, HTML (public.html), RTF
-- (public.rtf, converted from that HTML by AppKit's own WebKit importer) and
-- plain text (the visible text only, no Markdown syntax). The pasting app
-- picks the richest one it understands. The range defaults to the current
-- line; from Visual mode it is the selected lines.
--
--   vim.keymap.set({ "n", "x" }, "<Leader>y", ":MarkdownCopyRich<CR>", { silent = true })

-- Runs under osascript. argv[0] is a file holding the HTML document.
local jxa = [[
ObjC.import("AppKit");
function run(argv) {
  const html = $.NSString.stringWithContentsOfFileEncodingError(
    argv[0], $.NSUTF8StringEncoding, null);
  const data = html.dataUsingEncoding($.NSUTF8StringEncoding);
  const rich = $.NSAttributedString.alloc.initWithHTMLDocumentAttributes(data, null);
  const pb = $.NSPasteboard.generalPasteboard;
  pb.clearContents;
  pb.setStringForType(html, $.NSPasteboardTypeHTML);
  if (rich && !rich.isNil()) {
    const rtf = rich.RTFFromRangeDocumentAttributes(
      $.NSMakeRange(0, rich.length), $({}));
    pb.setDataForType(rtf, $.NSPasteboardTypeRTF);
    const text = rich.string.js.replace(/\s+$/, "");
    pb.setStringForType($(text), $.NSPasteboardTypeString);
  }
}
]]

-- The look of the copied HTML lives in copy_rich.css next to this file,
-- reread on every copy. Rich text editors mostly ignore a <style> block on
-- the clipboard, so each rule is inlined into the style attribute of every
-- element with that tag name; only plain tag selectors (`td`, `h2, h3`)
-- are understood, anything else is skipped.
local css_file = vim.fs.joinpath(
  vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)), "copy_rich.css")

local function read_css()
  local rules = {}
  local f = io.open(css_file)
  if not f then return rules end
  local css = f:read("a"):gsub("/%*.-%*/", "")
  f:close()
  for selectors, body in css:gmatch("([^{}]+){([^}]*)}") do
    local decl = vim.trim(body):gsub("%s+", " "):gsub('"', "'")
    if decl ~= "" and not decl:find(";$") then decl = decl .. ";" end
    for sel in selectors:gmatch("[^,]+") do
      sel = vim.trim(sel):lower()
      if sel:match("^%w+$") and decl ~= "" then
        rules[sel] = rules[sel] and (rules[sel] .. " " .. decl) or decl
      end
    end
  end
  return rules
end

-- A cell or table pandoc already styled (column alignment, relative widths)
-- gets the rule merged in front of its own style. If the cells have a
-- border, tables also get the legacy border attribute (obsolete in HTML5 but
-- still honoured everywhere), for editors that read that and not the CSS.
local function inline_css(html)
  local rules = read_css()
  local bordered = ((rules.th or "") .. (rules.td or "")):find("border") ~= nil
  return (html:gsub("<(%w+)([^>]-)(/?)>", function(tag, attrs, slash)
    local decl = rules[tag:lower()]
    if not decl then return nil end
    if attrs:find('style="') then
      attrs = attrs:gsub('style="', 'style="' .. decl .. " ", 1)
    else
      attrs = attrs .. ' style="' .. decl .. '"'
    end
    if bordered and tag:lower() == "table" then
      attrs = ' border="1"' .. attrs
    end
    return "<" .. tag .. attrs .. slash .. ">"
  end))
end

local function notify(msg, level)
  vim.schedule(function()
    vim.notify("MarkdownCopyRich: " .. msg, level or vim.log.levels.INFO)
  end)
end

vim.api.nvim_create_user_command("MarkdownCopyRich", function(opts)
  local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
  local md = table.concat(lines, "\n") .. "\n"

  vim.system(
    { "pandoc", "-f", "markdown", "-t", "html", "--wrap=none" },
    { stdin = md, text = true },
    vim.schedule_wrap(function(res)
      if res.code ~= 0 then
        notify("pandoc failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
        return
      end
      -- A browser puts the fragment behind a charset meta on the clipboard;
      -- without it AppKit's RTF importer reads non-ASCII text as Latin-1.
      local file = vim.fn.tempname() .. ".html"
      local f = assert(io.open(file, "w"))
      f:write("<meta charset='utf-8'>", inline_css(res.stdout))
      f:close()
      vim.system(
        { "osascript", "-l", "JavaScript", "-e", jxa, file },
        { text = true },
        function(r)
          os.remove(file)
          if r.code ~= 0 then
            notify("clipboard write failed: " .. (r.stderr or ""), vim.log.levels.ERROR)
          else
            notify(("copied %d line(s) as rich text"):format(#lines))
          end
        end
      )
    end)
  )
end, { range = true, desc = "Copy Markdown as rendered rich text (HTML + RTF + plain)" })
