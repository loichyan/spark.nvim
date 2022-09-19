--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local ____shared = require("spark.shared")
local CONFIG = ____shared.CONFIG
local PLUGINS = ____shared.PLUGINS
local sys = require("spark.sys")
local ____utils = require("spark.utils")
local deep_merge = ____utils.deep_merge
local join_path = ____utils.join_path
local log = require("spark.log")
local ____spec = require("spark.spec")
local new_spec = ____spec.new_spec
local validate = ____spec.validate
local ____sequence = require("spark.sequence")
local resolve = ____sequence.resolve
local ____job = require("spark.job")
local Job = ____job.Job
local function plug_path(is_start, name)
    local dir = "opt"
    if is_start then
        dir = "start"
    end
    return join_path(CONFIG.root, dir, name)
end
local function local_plugin()
    local plugins = {}
    for name in sys.scandir(plug_path(true, "")) do
        plugins[name] = true
    end
    for name in sys.scandir(plug_path(false, "")) do
        plugins[name] = false
    end
    return plugins
end
function ____exports.setup(config)
    deep_merge(true, CONFIG, config or ({}))
    local installed = local_plugin()
    local plugins = {}
    CONFIG[1](function(orig)
        local spec, err = validate(orig)
        if spec == nil then
            log.error(err)
            return
        end
        local name = spec[1]
        if spec.__state == "NONE" then
            local is_start = installed[name]
            installed[name] = nil
            if is_start == nil then
                spec.__state = "CLONE"
            elseif is_start then
                spec.__state = "AFTER_LOAD"
            elseif not spec.disable then
                spec.__state = "LOAD"
            elseif is_start ~= spec.start then
                spec.__state = "MOVE"
            end
            spec.__path = plug_path(spec.start, name)
        end
        table.insert(plugins, spec)
    end)
    for name, start in pairs(installed) do
        local spec = new_spec({[1] = name, start = start})
        spec.__state = "REMOVE"
        table.insert(plugins, spec)
    end
    local resolved, msg = resolve(plugins)
    if resolved == nil then
        log.error(msg)
        return
    end
    for _, v in ipairs(resolved) do
        table.insert(PLUGINS, v)
    end
end
function ____exports.plugins()
    return PLUGINS
end
local function post_update(spec)
    local run = spec.run
    if type(run) == "function" then
        run(nil)
    else
        Job.new({cmd = run, cwd = spec.__path}):run()
    end
end
function ____exports.install()
    for _, spec in ipairs(PLUGINS) do
        local name = spec[1]
        if spec.__state == "CLONE" then
            log.debug("clone %s", name)
            local code, signal, out, err = Job.new({cmd = {
                "git",
                "clone",
                spec.from,
                spec.__path,
                "--depth",
                "1"
            }}):run()
            if code == nil then
                return
            end
            log.debug(
                "code %d, signal: %d, err: %s, out: %s",
                code,
                signal,
                out,
                err
            )
            if code == 0 then
                spec.__state = "LOAD"
                post_update(spec)
            end
        elseif spec.__state == "MOVE" then
            log.debug("move %s", name)
            sys.rename(
                plug_path(not spec.start, name),
                spec.__path
            )
            spec.__state = "LOAD"
            break
        end
    end
end
function ____exports.load()
    for _, spec in ipairs(PLUGINS) do
        local name = spec[1]
        if spec.__state == "LOAD" then
            log.debug("load %s", name)
            vim.cmd("packadd " .. name)
            spec.__state = "AFTER_LOAD"
        end
        if spec.__state == "AFTER_LOAD" then
            log.debug("after load %s", name)
            CONFIG.after_load(spec)
        end
    end
end
function ____exports.clean()
    for _, spec in ipairs(PLUGINS) do
        if spec.__state == "REMOVE" then
            local name = spec[1]
            log.debug("remove %s", name)
            if sys.remove(spec.__path) then
                spec.__state = "NONE"
            end
        end
    end
end
return ____exports
