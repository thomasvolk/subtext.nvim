-- subtext navigation module
-- https://github.com/subconsciousnetwork/subtext/

local cmp = require('cmp')
local custom_source = require('subtext_cmp_source')

cmp.register_source('subtext_cmp_source', custom_source.new())

cmp.setup.filetype('subtext', {
  sources = cmp.config.sources({
    { name = 'subtext_cmp_source' },
    { name = 'buffer' },
    { name = 'path' },
  })
})


local P_NOTE_REF = [[^/[A-Za-z0-9_%-%/]+$]]
local P_NOTE_FILE = [[^/[/A-Za-z0-9_%-%.]+%.[A-Za-z0-9_%-]+$]]
local P_WIKI_LINK = [[[^A-Za-z0-9_%- %/]+]]
local P_URL = [[https?%:%/%/[%/%-a-zA-Z0-9%.=~#%[%]%+%%&%?%$]+]]
local P_ALIAS = [[^%:alias%-of%:([A-Za-z0-9_%-]+)$]]


local trim = function(s)
  return s:gsub("^%s+", ""):gsub("%s+$", "")
end


local nomalize_path = function(path)
  return "." .. path
end


local open = function(resource)
  local cmd = "xdg-open" -- Command for Linux
  if vim.fn.has("win32") == 1 then
    cmd = "start"
  elseif vim.fn.has("mac") == 1 then
    cmd = "open"
  end
  vim.fn.jobstart(cmd .. " " .. resource)
end


local jump_to_note = function ()
  local cfile_value = vim.fn.expand("<cfile>")
  if string.find(cfile_value, P_NOTE_REF) then
    vim.cmd("e " .. nomalize_path(cfile_value) .. ".subtext")
  elseif string.find(cfile_value, P_NOTE_FILE) then
    vim.notify("Opening file: " .. cfile_value)
    open(nomalize_path(cfile_value))
  elseif string.find(cfile_value, P_URL) then
    open(cfile_value)
  else
    local column = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    local alias_of = string.match(line, P_ALIAS)
    if alias_of then
      local path = "./" .. alias_of .. ".subtext"
      vim.cmd("e " .. path)
    else
      local right = string.sub(line, column + 1, string.len(line))
      local left = string.sub(line, 0, column)
      local r_wiki_bracket = string.find(right, "%]%]")
      if r_wiki_bracket then
        local l_wiki_bracket = string.find( (left):reverse(), "%[%[")
        if l_wiki_bracket then
          local e = column + r_wiki_bracket - 1
          local s = column - l_wiki_bracket + 2
          local link = string.sub(line, s, e)
          link = trim(string.lower(string.gsub(link, P_WIKI_LINK, "")))
          link = string.gsub(link, "[ ]*%/%/[ ]*", "#")
          link = string.gsub(link, "[ %/]+", "-")
          link = string.gsub(link, "[#]+", "/")
          local path = "./" .. link .. ".subtext"
          vim.cmd("e " .. path)
        end
      end
    end
  end
end


local highlight = function(name, pattern, color)
  vim.cmd.syntax([[match ]] .. name ..  [[ "]] .. pattern .. [["]])
  vim.cmd.highlight(name .. [[ guifg=]] .. color .. [[ gui=bold ]])
end


vim.api.nvim_create_autocmd({"TextChanged", "BufEnter", "BufWinEnter"}, {
    pattern = "*.subtext",
    callback = function()
        vim.bo.filetype = 'subtext'
        local C_HEADING = "#EEEE88"
        local C_FILE = "#88EE88"
        local C_URL = C_FILE
        local C_REF = "#88EEEE"
        local C_LINK = C_REF
        local C_FIELD = "#8888FF"

        highlight("SubtextHeading", [[\v^#.+$]], C_HEADING)

        highlight("SubtextUrl", [[\v(^|\s)https?://[/\-a-zA-Z0-9@:%._\+~#=\.&%\?]+($|\s)]], C_URL)

        highlight("SubtextRef", [[\v(^|\s)/[a-zA-Z0-9\-_/]+($|\s)]], C_REF)

        highlight("SubtextWikiLink", [[\v\[\[.{-}\]\]+]], C_LINK)

        highlight("SubtextFile", [[\v(^|\s)\.?\.?/[a-zA-Z0-9\-_/]+(\.[a-zA-Z0-9\-_/]+)+($|\s)]], C_FILE)

        highlight("SubtextFields", [[\v^:(created-at|updated-at|neno-flags|alias-of|file|size)+:]], C_FIELD)

        vim.keymap.set('n', '<leader><CR>', function() jump_to_note() end, {noremap = true})

        vim.api.nvim_create_user_command('SubtextJump', jump_to_note,
          {nargs = 0, desc = 'follow subtext reference'}
        )

    end
})

vim.filetype.add({
  extension = {
    subtext = "subtext"
  }
})
