local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local Path = require 'plenary.path'

-- 1) Get “MyThing” from “MyThing.cs”
local function filename_to_classname()
  return vim.fn.expand '%:t:r'
end

-- 2) Climb up until you find a folder that contains either:
--    • a .git folder
--    • one or more *.sln files
--    • one or more *.csproj files
local function find_project_root()
  local current = Path:new(vim.fn.expand '%:p'):parent()
  while current do
    if current:joinpath('.git'):exists() then
      return current
    end
    if (#vim.fn.glob(current.filename .. '/*.sln') > 0) or (#vim.fn.glob(current.filename .. '/*.csproj') > 0) then
      return current
    end

    local parent = current:parent()
    if not parent or parent.filename == current.filename then
      break
    end
    current = parent
  end
  return nil
end

-- 3) Build a namespace by:
--    • taking the folder of the current .cs → file_dir,
--    • making it relative to the PROJECT ROOT,
--    • replacing all "/" or "\" with ".",
--    • then prefixing it with the project_root’s folder name.
-- If it’s directly under project_root, namespace = project_root.filename.
local function derive_namespace()
  local file = Path:new(vim.fn.expand '%:p')
  local project_root = find_project_root()
  if not project_root then
    return 'UnknownNamespace'
  end

  -- The directory containing the current .cs (e.g. “…/Symposia/Models/Registration/Billing”)
  local file_dir = file:parent()
  -- Make that directory relative to the project root’s absolute path
  local rel_dir = file_dir:make_relative(tostring(project_root:absolute()))
  local project_name = project_root.filename

  -- If the .cs is immediately inside project_root (no subfolders), rel_dir is "" or "."
  if rel_dir == '' or rel_dir == '.' then
    return project_name
  end

  -- Otherwise, replace any "/" or "\" with "."
  local dotted = rel_dir:gsub('[/\\]+', '.')
  return project_name .. '.' .. dotted
end

-- ───────────────────────────────────────────────────────────────────────────────
--   C# “class” snippet (with a blank line after the '{')
-- ───────────────────────────────────────────────────────────────────────────────
ls.add_snippets('cs', {
  s('cl_class', {
    -- “namespace Symposia.X.Y.Z”
    f(function()
      return 'namespace ' .. derive_namespace()
    end, {}),

    -- newline → "{"
    t { '', '{' },

    -- newline (blank line)
    t { '' },

    -- “    public class Foo”
    t { '    public class ' },
    f(filename_to_classname, {}),

    -- newline → “    {”, then blank indent for the body
    t { '', '    {', '        ' },
    i(0),

    -- close the class and namespace
    t { '', '    }', '}' },
  }),
})

-- ───────────────────────────────────────────────────────────────────────────────
--   C# “interface” snippet (with a blank line after the '{')
-- ───────────────────────────────────────────────────────────────────────────────
ls.add_snippets('cs', {
  s('in_interface', {
    f(function()
      return 'namespace ' .. derive_namespace()
    end, {}),

    t { '', '{' },
    t { '' }, -- blank line
    t { '    public interface ' },
    f(filename_to_classname, {}),

    t { '', '    {', '        ' },
    i(0),

    t { '', '    }', '}' },
  }),
})
