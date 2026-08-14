local obs = obslua

local RETRY_INTERVAL_MS = 500
local MAX_ATTEMPTS = 40

local attempts = 0

-- The macOS camera extension finishes activating a few hundred ms after OBS
-- reports startup complete, so a single start attempt loses the race and
-- fails silently. Retry until the output reports itself active.
local function try_start()
	if obs.obs_frontend_virtualcam_active() then
		obs.remove_current_callback()
		return
	end

	attempts = attempts + 1
	if attempts > MAX_ATTEMPTS then
		obs.script_log(obs.LOG_WARNING, "gave up starting the virtual camera")
		obs.remove_current_callback()
		return
	end

	obs.obs_frontend_start_virtualcam()
end

local function on_frontend_event(event)
	if event == obs.OBS_FRONTEND_EVENT_FINISHED_LOADING then
		obs.timer_add(try_start, RETRY_INTERVAL_MS)
	end
end

function script_description()
	return "Starts the virtual camera automatically when OBS finishes loading."
end

function script_load()
	obs.obs_frontend_add_event_callback(on_frontend_event)
end
