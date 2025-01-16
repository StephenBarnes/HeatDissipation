local TESTING = false

-- Function to decide which heat sink if any should be placed on the given ent.
---@param ent LuaEntity
local function getSinkName(ent)
	if ent.name == "heat-pipe" then
		-- Optimization: for heat pipes, we only create sinks if the x + y is even, so in a checkerboard pattern.
		-- This halves the number of dummy assemblers needed without changing total heat cost.
		local checkerboardPos = ent.position.x + ent.position.y
		if checkerboardPos % 2 == 0 then
			return "heat-sink-dummy-assembler-2x"
		else
			return nil
		end
	elseif ent.name == "heating-tower" then
		return "heat-sink-dummy-assembler-9x"
	end
end

---@param ent LuaEntity
local function entPlanetHasFreezing(ent)
	return (ent ~= nil
		and ent.valid
		and ent.surface ~= nil
		and ent.surface.valid
		and ent.surface.planet ~= nil
		and ent.surface.planet.valid
		and ent.surface.planet.prototype.entities_require_heating)
end

------------------------------------------------------------------------
--- Functions to create and remove heat sinks when entities are built and destroyed.

---@param ent LuaEntity
local function createSink(ent, sinkName)
	if not ent.valid then return end
	sinkName = sinkName or getSinkName(ent)
	if sinkName == nil then return end
	if TESTING then game.print("Creating heat-sink assembler...") end
	ent.surface.create_entity{
		name = sinkName,
		position = ent.position,
		force = ent.force,
	}
end

local function deleteSink(ent)
	if not ent.valid then return end
	local sinkName = getSinkName(ent)
	if sinkName == nil then return end
	if TESTING then game.print("Deleting sinks for an entity...") end
	local sinks = ent.surface.find_entities_filtered{
		name = sinkName,
		position = ent.position,
	}
	for i, sink in pairs(sinks) do
		sink.destroy()
		if TESTING then game.print("Deleted sink #" .. i) end
	end
end

local function maybeCreateSink(ent)
	-- Creates a heat-sink if one doesn't already exist.
	if not ent.valid then return end
	local sinkName = getSinkName(ent)
	if sinkName == nil then return end
	local numExisting = ent.surface.count_entities_filtered{
		name = sinkName,
		position = ent.position,
	}
	if numExisting == 0 then createSink(ent, sinkName) end
end

------------------------------------------------------------------------
--- Event handlers

---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.on_space_platform_built_entity | EventData.script_raised_built | EventData.script_raised_revive | EventData.on_entity_cloned
local function onCreatedHeatPipe(event)
	if not entPlanetHasFreezing(event.entity) then return end
	createSink(event.entity, nil)
end

local function onDestroyedHeatPipe(event)
	if not entPlanetHasFreezing(event.entity) then return end
	deleteSink(event.entity)
end

-- TODO could add support for Picker Dollies here. Destroy at last position, create at new position.

------------------------------------------------------------------------
--- Register handlers

local filters = {
	{filter = "name", name = "heat-pipe"},
	{filter = "name", name = "heating-tower"},
}

for _, event in pairs{
	defines.events.on_built_entity,
	defines.events.on_robot_built_entity,
	defines.events.on_space_platform_built_entity,
	defines.events.script_raised_built,
	defines.events.script_raised_revive,
	defines.events.on_entity_cloned,
} do
	script.on_event(event, onCreatedHeatPipe, filters)
end

for _, event in pairs{
	defines.events.on_player_mined_entity,
	defines.events.on_robot_mined_entity,
	defines.events.on_entity_died,
	defines.events.script_raised_destroy,
} do
	script.on_event(event, onDestroyedHeatPipe, filters)
end

------------------------------------------------------------------------
--- Handle the case where it's added to an existing game.

script.on_init(function()
	for _, surface in pairs(game.surfaces) do
		if surface.valid and surface.planet ~= nil and surface.planet.prototype.entities_require_heating then
			for _, ent in pairs(surface.find_entities_filtered{type = "heat-pipe", name = "heat-pipe"}) do
				maybeCreateSink(ent)
			end
			for _, ent in pairs(surface.find_entities_filtered{type = "reactor", name = "heating-tower"}) do
				maybeCreateSink(ent)
			end
		end
	end
end)

------------------------------------------------------------------------
--- For debugging: every n seconds, report number of heat-sinks.

if TESTING then
	script.on_nth_tick(60 * 5, function(_)
		for _, surface in pairs(game.surfaces) do
			if surface.valid and surface.planet ~= nil and surface.planet.prototype.entities_require_heating then
				local count1 = surface.count_entities_filtered{name = "heat-sink-dummy-assembler-2x"}
				local count5 = surface.count_entities_filtered{name = "heat-sink-dummy-assembler-9x"}
				game.print("Heat sinks on " .. surface.name .. ": " .. count1 .. " (2x), " .. count5 .. " (9x)")
			end
		end
	end)
end