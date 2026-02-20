-- executor.lua
-- Runs user code inside coroutines with a debug hook preemption guard.
-- Provides .run_string(name, code, env) and .run_file(filename, env_creator)

local executor = {}

-- From Codex: "fariness cap per Love frame."
executor.max_resumes_per_frame = 6

local coros = {} -- list of { co = coroutine, name = <>, status = "running"/"dead"/"error", last_err = str }

local function make_wrapper(chunk, env, name)
    -- this is the body of the coroutine.
    return function()
        -- expose yield to user env during execution
        env.yield = coroutine.yield

        -- Run user code directly.
        -- NOTE: We intentionally do not use debug-hook forced yielding here;
        -- in LuaJIT this can raise "attempt to yield across C-call boundary".
        chunk()

        -- clear env.yield on normal completion
        env.yield = nil
        -- end of chunk; coroutine dies (I guess this means it's garbage-collected?)
    end
end

--[[
Per Codex:
- load(..., "t", env) compiles code as text chunk with sandbox env
- On compile failure, returns "load error: ..."
- Wraps chunk, creates coroutine, stores metadata in coros, returns entry.
]]
function executor.run_string(code, name, env)
    local chunk, load_err = load(code, name or "user_code", "t", env)

    -- return a load error if no chunk was passed.
    if not chunk then
        return nil, ("load error: %s"):format(tostring(load_err))
    end

    -- create the coroutine that wil run this code.
    local wrapped = make_wrapper(chunk, env, name)
    local co = coroutine.create(wrapped)

    -- create an entry record with more details, and add it to the list of coroutines. chunk itself is called inside co.
    local entry = {
        co = co,
        env = env,
        name = name or "user_code",
        status = "running",
        last_err = nil,
        resume_count = 0
    }
    table.insert(coros, entry)
    return entry
end

--[[
Per Codex:
- Reads file via love.filesystem, then calls run_string.
]]
function executor.run_file(filename, env)
    if not love.filesystem.getInfo(filename) then
        return nil, ("file not found: %s"):format(filename)
    end
    local code, err = love.filesystem.read(filename)
    if not code then return nil, ("read error: %s"):format(tostring(err)) end
    return executor.run_string(code, filename, env)
end

--[[
Per Codex:

- Iterates active coroutine entries.
- Skips once `resumes >= max_resumes_per_frame`
- If already dead, marks for removal, else resumes coroutine
- If resume failed (`ok == false`), records runtime error and removes
- If resumed with "__INSTR_HOOK_YIELD__", marks "preempted" (forced timeslice)
- Else checks if dead (finished) or still suspended (voluntary yield)
- Removes finished/errored entries in reverse pass
- Returns message list, though main.lua currently ignores it.       
]]
function executor.update(dt)
    local messages = {}
    local resumes = 0

    -- iterate and resume up to max_resumes_per_frame
    for i = 1, #coros do
        if resumes >= executor.max_resumes_per_frame then break end         -- some kind of limit
        local e = coros[i]
        if not e then goto cont end

    -- check to see if coroutine is dead; if it is, remove it.
        local co = e.co
        if coroutine.status(co) == "dead" then
            e.status = "dead"
            table.insert(messages, ("finished: %s"):format(e.name))
            e._remove = true
    -- if not dead, resume
        else
            local ok, res = coroutine.resume(co)
    -- increment resume counter
            resumes = resumes + 1 
            e.resume_count = e.resume_count + 1
    -- if resume throws an error, change its status, insert an error message, and remove the coroutine
            if not ok then
                e.status = "error"
                e.last_err = tostring(res)
                if e.env then e.env.yield = nil end
                table.insert(messages, ("error in %s: %s"):format(e.name, tostring(res)))
                e._remove = true
            else
    -- normal yield or nil -> still running or finished
                if coroutine.status(co) == "dead" then
                    e.status = "dead"
                    if e.env then e.env.yield = nil end
                    table.insert(messages, ("finished: %s"):format(e.name))
    -- remove the dead coroutine
                    e._remove = true                                        
                else
                    e.status = "running"
                    table.insert(messages, ("yielded: %s"):format(e.name))
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

-- Per Codex: flags all entries for removal
function executor.interrupt_all()
    for i = 1, #coros do coros[i]._remove = true end
end

-- inspection helper: check length of coros
function executor.has_running()
    return #coros > 0
end

-- inspection helper: return the full coroutine table
function executor.list()
    return coros
end

return executor

--[[
NOTES

So this file is responsible for calling the example.lua file, in order. Still not sure why this needs to be done with
coroutines. But it seems like its only function is to step through the chunks in that file, which themselves alter
the turtle canvas—and that canvas is what is drawn in each frame of love.draw() (love.draw is itself called inside
the turtle.draw method, in this current iteration.)

What are pcall, goto, and load?

Why are we using coroutines? Gut sense: we don't need to, 
at least not at the level of every chunk—is that what it's doing?

Don't like that the sandbox in main.lua is passed to each coroutine as its env value.
Also believe this version does not require the `name` value passed to make_wrapper.

]]
