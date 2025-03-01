-- subtext cmp source module
-- https://github.com/subconsciousnetwork/subtext/


local function map(tbl, f)
  local r = {}
  for k, x in pairs(tbl) do
    r[k] = f(x)
  end
  return r
end


local function list_subtext_files(root, quoteSlash)
    local function get_name(path)
        local rel_path = string.sub(path, #root + 2)
        local ending_removed = rel_path:match("(.+)%.subtext$")
        if quoteSlash then
            return string.gsub(ending_removed, "/", "//")
        else
            return ending_removed
        end
    end

    local files = vim.fn.glob(root .. '/**/*.subtext', true, true)
    return map(files, get_name)
end


local source = {}

source.new = function()
  local self = setmetatable({}, { __index = source })
  return self
end

function source:complete(request, callback)
  local items = {}
  local line = request.context.cursor_before_line
  local isWikiLink = false
  if string.sub(line, -2) == "[["
  then
    isWikiLink = true
  end
  if line == ":alias-of:" or
     string.sub(line, -1) == "/" or
     isWikiLink
  then
    local root = vim.fn.getcwd()
    local notes = list_subtext_files(root, isWikiLink)
    for _, note in ipairs(notes) do
      table.insert(items, { label = note, kind = require('cmp.types').lsp.CompletionItemKind.Reference })
    end
  end
  callback({ items = items })
end

return source
