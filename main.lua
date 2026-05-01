-- bashsudo.yazi/main.lua

local fs = os.getenv("HOME").. "/.config/yazi/plugins/bashsudo.yazi/assets/bashsudo.sh"

-- ── String helpers ────────────────────────────────────────────────────────────

function string:ends_with_char(suffix)
    return self:sub(-#suffix) == suffix
end

function string:is_path()
    local i = self:find("/")
    return self == "." or self == ".." or i and i ~= #self
end

function string:file_name()
    local file_name = self:match(".*/(.*)")
    if file_name ~= nil then
        return file_name
    else
        return self
    end
end

-- ── List helpers ──────────────────────────────────────────────────────────────

local function list_map(self, f)
    local i = nil
    return function()
        local v
        i, v = next(self, i)
        if v then
            return f(v)
        else
            return nil
        end
    end
end


local function extend_list(self, list)
    for _, value in ipairs(list) do
        table.insert(self, value)
    end
end

local function extend_iter(self, iter)
    for item in iter do
        table.insert(self, item)
    end
end

-- ── Ownership helper ──────────────────────────────────────────────────────────

local function i_own(path)
    local current_user = os.getenv("USER") or os.getenv("LOGNAME")
    local ok = os.execute(
        "[ \"$(stat -c '%U' ".. ya.quote(path).. ")\" = ".. ya.quote(current_user).. " ]"
    )
    return ok == true or ok == 0
end

local function is_dir(path)
    local ok = os.execute("[ -d ".. ya.quote(path).. " ]")
    return ok == true or ok == 0
end

-- ── State ─────────────────────────────────────────────────────────────────────

local get_state = ya.sync(function(_, cmd)
    if cmd == "paste" or cmd == "link" or cmd == "hardlink" then
        local yanked = {}
        for _, url in pairs(cx.yanked) do
            table.insert(yanked, tostring(url))
        end

        if #yanked == 0 then
            return {}
        end

        return {
            kind = cmd,
            value = {
                is_cut = cx.yanked.is_cut,
                yanked = yanked,
            },
        }
    elseif cmd == "create" then
        return { kind = cmd }
    elseif cmd == "remove" then
        local selected = {}
        if #cx.active.selected ~= 0 then
            for _, url in pairs(cx.active.selected) do
                table.insert(selected, tostring(url))
            end
        else
            table.insert(selected, tostring(cx.active.current.hovered.url))
        end
        return {
            kind = cmd,
            value = { selected = selected },
        }
    elseif cmd == "rename" then
        if #cx.active.selected == 0 then
            return {
                kind = cmd,
                value = {
                    hovered = tostring(cx.active.current.hovered.url),
                },
            }
        else
            return {}
        end
    elseif cmd == "chmod" then
        local selected = {}
        if #cx.active.selected ~= 0 then
            for _, url in pairs(cx.active.selected) do
                table.insert(selected, tostring(url))
            end
        else
            table.insert(selected, tostring(cx.active.current.hovered.url))
        end
        return {
            kind = cmd,
            value = { selected = selected },
        }
    elseif cmd == "edit" then
        return {
            kind = cmd,
            value = {
                hovered = tostring(cx.active.current.hovered.url),
            },
        }
    else
        return {}
    end
end)

-- ── Execute ───────────────────────────────────────────────────────────────────

local function execute(command)
    ya.emit("shell", {
        table.concat(command, " "),
        block = true,
        confirm = true,
    })
end

-- ── Handlers ──────────────────────────────────────────────────────────────────

local function bashsudo_paste(value)
    local args = { "sudo", "bash", ya.quote(fs) }

    if value.is_cut then
        table.insert(args, "mv")
    else
        table.insert(args, "cp")
    end
    if value.force then
        table.insert(args, "--force")
    end
    extend_iter(args, list_map(value.yanked, ya.quote))

    execute(args)
end

local function bashsudo_link(value)
    local args = { "sudo", "bash", ya.quote(fs), "link" }

    if value.relative then
        table.insert(args, "--relative")
    end
    extend_iter(args, list_map(value.yanked, ya.quote))

    execute(args)
end

local function bashsudo_hardlink(value)
    local args = { "sudo", "bash", ya.quote(fs), "hardlink" }
    extend_iter(args, list_map(value.yanked, ya.quote))

    execute(args)
end

-- bashsudo_create simplified
local function bashsudo_create(value)
    local name, event = ya.input({
        title = "Create (sudo) — append / for directory:",
        pos = { "top-center", y = 2, w = 50 },
    })

    if event == 1 and name and not name:is_path() then
        local args = {}
        if name:ends_with_char("/") then
            extend_list(args, { "sudo", "mkdir", "-p", ya.quote(name) })
        else
            extend_list(args, { "sudo", "touch", ya.quote(name) })
        end
        execute(args)
    end
end

local function bashsudo_rename(value)
    local initial = value.hovered:file_name()
    local current_value = initial

    while true do
        local new_name, event = ya.input({
            title = "Rename:",
            pos = { "top-center", y = 2, w = 40 },
            value = current_value,
        })

        -- User cancelled (Esc)
        if event ~= 1 then return end
        if not new_name or new_name == "" then return end
        if new_name:is_path() then return end

        local dir = value.hovered:match("^(.*)/[^/]+$") or "."
        local dest = dir.. "/".. new_name

        -- Check for conflict
        local conflict = os.execute("[ -e ".. ya.quote(dest).. " ]")
        if conflict == true or conflict == 0 then
            -- Show error then loop back with the conflicting name pre-filled
            ya.notify({
                title = "bashsudo rename",
                content = "'".. new_name.. "' already exists, please choose another name.",
                level = "warn",
                timeout = 3,
            })
            current_value = new_name
            -- Small delay so the notification is visible before input reopens
            ya.sleep(0.8)
        else
            -- No conflict, proceed
            local args = {}
            if not i_own(value.hovered) then
                table.insert(args, "sudo")
            end
            extend_list(args, { "mv", ya.quote(value.hovered), ya.quote(dest) })
            execute(args)
            return
        end
    end
end

local function bashsudo_remove(value)
    if value.permanently then
        -- Confirm before permanent delete
        local count = tostring(#value.selected)
        local confirmed, event = ya.input({
            title = "Permanently delete ".. count.. " item(s)? [y/N]:",
            pos = { "top-center", y = 2, w = 50 },
        })
        if event ~= 1 or not confirmed or confirmed:lower() ~= "y" then return end

        local args = { "sudo", "bash", ya.quote(fs), "remove", "--permanent" }
        extend_iter(args, list_map(value.selected, ya.quote))
        execute(args)
    else
        local args = { "bash", ya.quote(fs), "remove" }

        -- Check ownership of all selected files
        local need_sudo = false
        for _, path in ipairs(value.selected) do
            if not i_own(path) then
                need_sudo = true
                break
            end
        end
        if need_sudo then
            table.insert(args, 1, "sudo")
        end

        extend_iter(args, list_map(value.selected, ya.quote))
        execute(args)
    end
end

local function bashsudo_chmod(value)
    local mode, event = ya.input({
        title = "chmod — enter mode (e.g. 755, +x, -w):",
        pos = { "top-center", y = 2, w = 40 },
    })
    if event ~= 1 or not mode or mode == "" then return end

    -- Check ownership
    local need_sudo = false
    for _, path in ipairs(value.selected) do
        if not i_own(path) then
            need_sudo = true
            break
        end
    end

    -- Ask recursive only if any selected path is a directory
    local has_dir = false
    for _, path in ipairs(value.selected) do
        if is_dir(path) then
            has_dir = true
            break
        end
    end

    local recursive = false
    if has_dir then
        local answer, event2 = ya.input({
            title = "Apply recursively? [y/N]:",
            pos = { "top-center", y = 2, w = 40 },
        })
        if event2 ~= 1 then return end
        recursive = answer and answer:lower() == "y"
    end

    local args = {}
    if need_sudo then table.insert(args, "sudo") end
    table.insert(args, "chmod")
    if recursive then table.insert(args, "-R") end
    table.insert(args, mode)
    extend_iter(args, list_map(value.selected, ya.quote))
    execute(args)
end

local function bashsudo_edit(value)
    local editor = os.getenv("EDITOR") or "vi"

    local args = {}
    if not i_own(value.hovered) then
        table.insert(args, "sudo")
    end
    extend_list(args, { editor, ya.quote(value.hovered) })
    execute(args)
end

-- ── Entry ─────────────────────────────────────────────────────────────────────

return {
    entry = function(_, job)
        ya.emit("escape", { visual = true })

        local state = get_state(job.args[1])

        if state.kind == "paste" then
            state.value.force = job.args.force
            bashsudo_paste(state.value)
        elseif state.kind == "link" then
            state.value.relative = job.args.relative
            bashsudo_link(state.value)
        elseif state.kind == "hardlink" then
            bashsudo_hardlink(state.value)
        elseif state.kind == "create" then
            bashsudo_create(state.value)
        elseif state.kind == "remove" then
            state.value.permanently = job.args.permanent
            bashsudo_remove(state.value)
        elseif state.kind == "rename" then
            bashsudo_rename(state.value)
        elseif state.kind == "chmod" then
            bashsudo_chmod(state.value)
        elseif state.kind == "edit" then
            bashsudo_edit(state.value)
        end
    end,
}
