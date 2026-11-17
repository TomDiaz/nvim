local dap = require "dap"
local dapui = require "dapui"

dapui.setup()

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- netcoredbg instalado por Mason
local netcoredbg = vim.fn.stdpath "data" .. "/mason/packages/netcoredbg/netcoredbg/netcoredbg"
if vim.fn.has "win32" == 1 then
  netcoredbg = netcoredbg .. ".exe"
end

dap.adapters.coreclr = {
  type = "executable",
  command = netcoredbg,
  args = { "--interpreter=vscode" },
}

-- Intenta adivinar el .dll: bin/Debug/<tfm>/<NombreDelProyecto>.dll
local function find_dll()
  local cwd = vim.fn.getcwd()
  local csproj = vim.fn.glob(cwd .. "/*.csproj", false, true)[1]
  if csproj then
    local name = vim.fn.fnamemodify(csproj, ":t:r")
    local dll = vim.fn.glob(cwd .. "/bin/Debug/*/" .. name .. ".dll", false, true)[1]
    if dll then
      return dll
    end
  end
  return vim.fn.input("Ruta al dll: ", cwd .. "/bin/Debug/", "file")
end

dap.configurations.cs = {
  {
    type = "coreclr",
    name = "Launch (dotnet build primero)",
    request = "launch",
    program = find_dll,
    cwd = "${workspaceFolder}",
    env = { ASPNETCORE_ENVIRONMENT = "Development" },
  },
  {
    type = "coreclr",
    name = "Attach a proceso",
    request = "attach",
    processId = require("dap.utils").pick_process,
  },
}
