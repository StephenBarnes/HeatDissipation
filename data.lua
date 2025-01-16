--[[ Tried adding heating energy to various entities that don't do anything, but it seems none of them work, so I decided to use an assembler instead.
data.raw["heat-pipe"]["heat-pipe"].heating_energy = "10MW" -- Doesn't work.
data.raw.wall["stone-wall"].heating_energy = "10MW" -- Also doesn't do anything.
data.raw["simple-entity-with-force"]["textplate-large-concrete"].heating_energy = "10MW" -- Also doesn't do anything. (Must be in dff, not data.)
data.raw["solar-panel"]["solar-panel"].heating_energy = "10MW" -- Still nothing.
]]

local heatingEnergyPerTileKW = settings.startup["HeatDissipation-kw-per-tile"].value

-- Create a dummy assembling machine that just exists to suck heat out of the heat pipes.
---@type data.AssemblingMachinePrototype
local heatSinkTimes2 = {
	type = "assembling-machine",
	name = "heat-sink-dummy-assembler-2x",
	icon = data.raw["heat-pipe"]["heat-pipe"].icon,
	icon_size = data.raw["heat-pipe"]["heat-pipe"].icon_size,
	crafting_categories = {"heat-sink-dummy-crafting-category"},
	flags = {"not-on-map", "not-in-kill-statistics", "not-deconstructable", "not-flammable"},
	collision_box = {{0, 0}, {0, 0}},
	selection_box = {{0, 0}, {0, 0}},
	tile_height = 1,
	tile_width = 1,
	heating_energy = (2 * heatingEnergyPerTileKW) .. "kW",
	energy_usage = "1W",
	crafting_speed = 1,
	energy_source = {type = "void"},
	hidden = true,
	show_recipe_icon = false,
	show_recipe_icon_on_map = false,
	selectable_in_game = false,
}

-- Create another dummy assembler for 5x the energy consumption, for heating towers.
local heatSinkTimes9 = table.deepcopy(heatSinkTimes2)
heatSinkTimes9.name = "heat-sink-dummy-assembler-9x"
heatSinkTimes9.heating_energy = (9 * heatingEnergyPerTileKW) .. "kW"

-- Create dummy crafting category. Probably not really necessary but seems prudent, might avoid some issues, IDK.
local heatSinkCraftingCategory = {
	type = "recipe-category",
	name = "heat-sink-dummy-crafting-category"
}

data:extend{heatSinkTimes2, heatSinkTimes9, heatSinkCraftingCategory}
