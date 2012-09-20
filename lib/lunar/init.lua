local app_root, argv = ...

local function set_package_path(...)
  local paths = {}
  for _, path in ipairs({...}) do
    paths[#paths + 1] = app_root .. '/' .. path .. '/?.lua'
    paths[#paths + 1] = app_root .. '/' .. path .. '/?/init.lua'
  end
  package.path = table.concat(paths, ';') .. ';' .. package.path
end

local function lazily_loaded_module(name)
  return setmetatable(
    {},
    { __index = function (t, key)
      local req_name = name .. '.' .. key:lower()
      local status, mod = pcall(require, req_name)
      if not status then
        if mod:match('module.*not found') then
          mod = lazily_loaded_module(req_name)
        else
          error(mod)
        end
      end

      t[key] = mod
      return mod
    end})
end

package.path = ''
set_package_path('lib', 'lib/ext', 'lib/ext/moonscript')
package.cpath = ''

moonscript = require('moonscript')

lua_loadfile = loadfile
loadfile = function(filename, mode, env)
  filename = type(filename) == 'string' and filename or tostring(filename)
  if (filename:match('%.moon$')) then
    return moonscript.loadfile(filename)
  else
    return lua_loadfile(filename, mode, env)
  end
end

-- set up globals (lpeg/lfs already setup from C)
lgi = require('lgi')
lunar = lazily_loaded_module('lunar')
moon = require('moon')
require('lunar.globals')

lunar.app = lunar.Application(lunar.fs.File(app_root), argv)
_G.log = require('lunar.log')

if #argv > 1 and argv[2] == '--spec' then
  set_package_path('lib/ext/telescope')
  lunar.spec.Runner({select(3, unpack(argv))}):run()
else
  lunar.app:run()
end