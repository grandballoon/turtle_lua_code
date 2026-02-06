-- executor.lua
-- Runs user code inside coroutines with a debug hook preemption guard.
-- Provides .run_string(name, code, env) and .run_file(filename, env_creator)

local executor = {}

-- tuning
executor.instruction_limit = 20000
executor.max_resumes_per_frame = 6

local coros = {} -- list of { co = coroutine, name = <>, status = "running"/"dead"/"error", last_err = str }

local function make_wrapper(chunk, env, name)
    local limit = executor.instruction_limit

    return function()
        -- expose yield to user env during execution
        env.yield = coroutine.yield

        -- hook yields after 'limit' VM instructions
        local function hook()
            coroutine.yield("__INSTR_HOOK_YIELD__")
        end
        debug.sethook(hook, "", limit)

        local ok, err = pcall(chunk)

        -- clear hook and env.yield
        debug.sethook()
        env.yield = nil

        if not ok then
            error(err)
        end
        -- end of chunk; coroutine dies
    end
end

-- run a code string inside a fresh coroutine
-- name is for messages (filename or "<repl>")
-- env must be a table (sandbox)
function executor.run_string(code, name, env)
    local chunk, load_err = load(code, name or "user_code", "t", env)
    if not chunk then
        return nil, ("load error: %s"):format(tostring(load_err))
    end

    local wrapped = make_wrapper(chunk, env, name)
    local co = coroutine.create(wrapped)

    local entry = { co = co, name = name or "user_code", status = "running", last_err = nil }
    table.insert(coros, entry)
    return entry
end

-- convenience: run a file by reading it and calling run_string
function executor.run_file(filename, env)
    if not love.filesystem.getInfo(filename) then
        return nil, ("file not found: %s"):format(filename)
    end
    local code, err = love.filesystem.read(filename)
    if not code then return nil, ("read error: %s"):format(tostring(err)) end
    return executor.run_string(code, filename, env)
end

-- update: resume coroutines cooperatively; returns list of messages
function executor.update(dt)
    local messages = {}
    local resumes = 0

    -- iterate and resume up to max_resumes_per_frame
    for i = 1, #coros do
        if resumes >= executor.max_resumes_per_frame then break end
        local e = coros[i]
        if not e then goto cont end

        local co = e.co
        if coroutine.status(co) == "dead" then
            e.status = "dead"
            table.insert(messages, ("finished: %s"):format(e.name))
            e._remove = true
        else
            local ok, res = coroutine.resume(co)
            resumes = resumes + 1
            if not ok then
                e.status = "error"
                e.last_err = tostring(res)
                table.insert(messages, ("error in %s: %s"):format(e.name, tostring(res)))
                e._remove = true
            else
                if res == "__INSTR_HOOK_YIELD__" then
                    e.status = "running"
                    table.insert(messages, ("preempted: %s"):format(e.name))
                else
                    -- normal yield or nil -> still running or finished
                    if coroutine.status(co) == "dead" then
                        e.status = "dead"
                        table.insert(messages, ("finished: %s"):format(e.name))
                        e._remove = true
                    else
                        e.status = "running"
                        table.insert(messages, ("yielded: %s"):format(e.name))
                    end
                end
            end
        end
        ::cont::
    end

    -- remove finished/errored coroutines (iterate backwards)
    for idx = #coros, 1, -1 do
        if coros[idx]._remove then table.remove(coros, idx) end
    end

    return messages
end

function executor.interrupt_all()
    for i = 1, #coros do coros[i]._remove = true end
end

function executor.has_running()
    return #coros > 0
end

function executor.list()
    return coros
end

return executor
