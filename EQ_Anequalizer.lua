-- ==============================================================================
-- MPV 60-Band Anequalizer (VLC Presets)
-- Copyright (C) 2026 [https://github.com/YukiNeeSan]
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <https://www.gnu.org/licenses/>.
--
-- ------------------------------------------------------------------------------
-- LIABILITY DISCLAIMER:
-- This script is provided "as-is" without any warranty. The FFmpeg anequalizer 
-- and firequalizer filters are highly aggressive signal processing tools. 
-- Extreme manipulation of frequency parameters and gain (especially within 
-- custom presets) can cause severe audio clipping or unexpected outputs. 
-- Use at your own risk. The author is strictly not liable for any hardware 
-- damage (including blown speaker or headphone drivers), system malfunction, 
-- or hearing impairment resulting from the use or modification of this script.
-- ==============================================================================

local mp = require "mp"
local utils = require "mp.utils"
local msg = require "mp.msg"

--------------------------------------------
-- anequalizer.lua
-- 60-band 1/6-octave graphic EQ controller
-- FFmpeg anequalizer / Butterworth only
--------------------------------------------

local FILTER = "@anequalizer"

local MODE = "OFF"
local CURRENT_PRESET = nil
local eq_applied = false

--------------------------------------------
-- NOMINAL 1/6-OCTAVE BANDWIDTH
--------------------------------------------

local function band_width(f)
    return f * (2.0^(1.0 / 12.0) - 2.0^(-1.0 / 12.0))
end

--------------------------------------------
-- 60-BAND 1/6-OCTAVE FREQUENCIES
--------------------------------------------

local FREQUENCIES = {
    20, 22.449, 25.198, 28.284, 31.748, 35.636,
    40, 44.898, 50.397, 56.569, 63.496, 71.272,
    80, 89.797, 100.794, 113.137, 126.992, 142.544,
    160, 179.594, 201.587, 226.274, 253.984, 285.088,
    320, 359.188, 403.175, 452.548, 507.968, 570.175,
    640, 718.376, 806.349, 905.097, 1015.937, 1140.350,
    1280, 1436.751, 1612.699, 1810.193, 2031.873, 2280.701,
    2560, 2873.503, 3225.398, 3620.387, 4063.747, 4561.401,
    5120, 5747.006, 6450.796, 7240.773, 8127.493, 9122.803,
    10240, 11494.011, 12901.592, 14481.547, 16254.987, 18245.606
}

--------------------------------------------
-- VLC 10-BAND REFERENCE PRESETS
-- Converted to 60-band representation.
--------------------------------------------

local VLC_PRESETS = {

    Classical = {
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,-0.753,-1.953,-3.153,-4.353,-5.553,-6.753,
        -7.2,-7.2,-7.2,-7.2,-7.2,-7.2,-7.2,-7.808,-9.6,-9.6
    },

    Club = {
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.731,
        2.269,3.808,5.346,6.884,7.885,7.465,7.045,6.625,6.205,5.785,
        5.6,5.6,5.6,5.6,5.6,5.6,5.6,5.6,5.6,5.6,
        5.6,5.6,5.6,5.6,5.349,4.949,4.549,4.149,3.749,3.349,
        2.866,2.332,1.799,1.266,0.732,0.199,0,0,0,0
    },

    Dance = {
        9.6,9.6,9.6,9.6,9.6,9.6,9.6,9.6,9.6,9.6,
        9.469,9.203,8.937,8.671,8.405,8.138,7.872,7.606,7.34,6.761,
        5.838,4.915,3.992,3.069,2.285,1.865,1.445,1.025,0.605,0.185,
        0,0,0,0,-0.081,-0.669,-1.258,-1.847,-2.436,-3.025,
        -3.614,-4.203,-4.792,-5.38,-5.767,-6.034,-6.301,-6.567,-6.834,-7.101,
        -7.2,-7.2,-7.2,-7.2,-7.2,-7.2,-3.816,0,0,0
    },

    FullBass = {
        7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2,
        7.113,6.936,6.758,6.581,6.403,6.226,6.048,5.871,5.693,5.088,
        4.011,2.935,1.858,0.781,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0
    },

    ["FullBass & Treble"] = {
        7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2,
        7.113,6.936,6.758,6.581,6.403,6.226,6.048,5.871,5.693,5.088,
        4.011,2.935,1.858,0.781,-0.346,-1.606,-2.865,-4.125,-5.385,-6.644,
        -6.897,-6.354,-5.811,-5.268,-4.708,-4.035,-3.362,-2.689,-2.016,-1.343,
        -0.67,0.003,0.676,1.349,2.269,3.336,4.402,5.469,6.536,7.602,
        8.334,8.868,9.401,9.934,10.468,11.001,11.576,12,12,12
    },

    FullTreble = {
        -9.6,-9.6,-9.6,-9.6,-9.6,-9.6,-9.6,-9.6,-9.6,-9.6,
        -9.6,-9.6,-9.6,-9.6,-9.6,-9.6,-9.6,-9.6,-9.6,-9.6,
        -9.6,-9.6,-9.6,-9.6,-9.331,-8.351,-7.371,-6.392,-5.412,-4.432,
        -3.191,-1.744,-0.297,1.151,2.527,3.452,4.377,5.303,6.228,7.153,
        8.079,9.004,9.93,10.855,11.702,12.502,13.302,14.102,14.902,15.702,
        16,16,16,16,16,16,16.203,16.8,16.8,16.8
    },

    Headphones = {
        4.8,4.8,4.8,4.8,4.8,4.8,4.8,4.8,4.8,4.8,
        5.148,5.858,6.568,7.278,7.988,8.698,9.408,10.118,10.827,10.688,
        9.611,8.535,7.458,6.381,5.177,3.637,2.098,0.558,-0.981,-2.521,
        -3.099,-2.918,-2.737,-2.556,-2.342,-1.922,-1.501,-1.081,-0.66,-0.239,
        0.181,0.602,1.023,1.443,1.934,2.468,3.001,3.534,4.068,4.601,
        5.302,6.102,6.902,7.702,8.502,9.302,11.104,13.205,14.4,14.4
    },

    Live = {
        -4.8,-4.8,-4.8,-4.8,-4.8,-4.8,-4.8,-4.8,-4.8,-4.8,
        -4.539,-4.007,-3.474,-2.942,-2.409,-1.877,-1.344,-0.812,-0.279,0.366,
        1.135,1.904,2.673,3.442,4.077,4.357,4.637,4.917,5.197,5.476,
        5.6,5.6,5.6,5.6,5.6,5.6,5.6,5.6,5.6,5.6,
        5.6,5.6,5.6,5.6,5.433,5.166,4.899,4.633,4.366,4.099,
        3.833,3.566,3.299,3.033,2.766,2.499,2.4,2.4,2.4,2.4
    },

    Party = {
        7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2,
        7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2,7.2,6.542,
        5.158,3.773,2.389,1.004,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,3.384,7.2,7.2,7.2
    },

    Pop = {
        -1.6,-1.6,-1.6,-1.6,-1.6,-1.6,-1.6,-1.6,-1.6,-1.6,
        -1.252,-0.542,0.168,0.878,1.588,2.298,3.008,3.718,4.427,5.019,
        5.481,5.942,6.404,6.865,7.238,7.378,7.518,7.658,7.798,7.938,
        7.697,7.154,6.611,6.068,5.519,4.931,4.342,3.753,3.164,2.575,
        1.986,1.397,0.808,0.22,-0.251,-0.651,-1.051,-1.451,-1.851,-2.251,
        -2.4,-2.4,-2.4,-2.4,-2.4,-2.4,-2.024,-1.6,-1.6,-1.6
    },

    Reggae = {
        0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,-0.269,-1.249,-2.229,-3.208,-4.188,-5.168,
        -4.892,-3.626,-2.36,-1.093,0.092,0.765,1.438,2.111,2.784,3.457,
        4.13,4.803,5.476,6.149,6.4,6.4,6.4,6.4,6.4,6.4,
        5.731,4.664,3.598,2.531,1.464,0.398,0,0,0,0
    },

    Rock = {
        8,8,8,8,8,8,8,8,8,8,
        7.826,7.471,7.116,6.761,6.406,6.051,5.696,5.341,4.986,3.85,
        1.85,-0.15,-2.15,-4.15,-5.715,-6.135,-6.555,-6.975,-7.395,-7.815,
        -7.394,-6.308,-5.222,-4.137,-3.096,-2.339,-1.582,-0.825,-0.068,0.689,
        1.446,2.203,2.961,3.718,4.502,5.302,6.102,6.902,7.702,8.502,
        9.051,9.451,9.851,10.251,10.651,11.051,11.2,11.2,11.2,11.2
    },

    Ska = {
        -2.4,-2.4,-2.4,-2.4,-2.4,-2.4,-2.4,-2.4,-2.4,-2.4,
        -2.531,-2.797,-3.063,-3.329,-3.595,-3.862,-4.128,-4.394,-4.66,-4.727,
        -4.573,-4.419,-4.265,-4.112,-3.808,-3.108,-2.408,-1.708,-1.009,-0.309,
        0.505,1.41,2.315,3.219,4.023,4.191,4.36,4.528,4.696,4.864,
        5.033,5.201,5.369,5.537,5.934,6.468,7.001,7.534,8.068,8.601,
        8.884,9.017,9.15,9.284,9.417,9.55,10.352,10.795,9.6,9.6
    },

    Soft = {
        4.8,4.8,4.8,4.8,4.8,4.8,4.8,4.8,4.8,4.8,
        4.626,4.271,3.916,3.561,3.206,2.851,2.496,2.141,1.786,1.454,
        1.146,0.838,0.531,0.223,-0.115,-0.535,-0.955,-1.375,-1.795,-2.215,
        -2.097,-1.554,-1.011,-0.468,0.058,0.478,0.899,1.319,1.74,2.161,
        2.581,3.002,3.423,3.843,4.418,5.085,5.751,6.418,7.085,7.751,
        8.167,8.434,8.701,8.967,9.234,9.501,10.352,11.403,12,12
    },

    ["Soft Rock"] = {
        4,4,4,4,4,4,4,4,4,4,
        4,4,4,4,4,4,4,4,4,3.854,
        3.546,3.238,2.931,2.623,2.285,1.865,1.445,1.025,0.605,0.185,
        -0.505,-1.41,-2.315,-3.219,-4.023,-4.191,-4.36,-4.528,-4.696,-4.864,
        -5.033,-5.201,-5.369,-5.537,-5.349,-4.949,-4.549,-4.149,-3.749,-3.349,
        -2.866,-2.332,-1.799,-1.266,-0.732,-0.199,1.128,4.021,8.8,8.8
    },

    Techno = {
        8,8,8,8,8,8,8,8,8,8,
        7.869,7.603,7.337,7.071,6.805,6.538,6.272,6.006,5.74,5.088,
        4.011,2.935,1.858,0.781,-0.269,-1.249,-2.229,-3.208,-4.188,-5.168,
        -5.499,-5.318,-5.137,-4.956,-4.731,-4.226,-3.721,-3.217,-2.712,-2.207,
        -1.702,-1.198,-0.693,-0.188,0.836,2.169,3.503,4.836,6.169,7.503,
        8.167,8.434,8.701,8.967,9.234,9.501,9.6,9.397,8.8,8.8
    }
}

local presets = VLC_PRESETS

------------------------------
-- CUSTOM 1
-- Format: {frequency, gain}
------------------------------

presets["Custom 1"] = {
    {20,0},{22.449,0},{25.198,0},{28.284,0},{31.748,0},
    {35.636,0},{40,0},{44.898,0},{50.397,0},{56.569,0},
    {63.496,0},{71.272,0},{80,0},{89.797,0},{100.794,0},
    {113.137,0},{126.992,0},{142.544,0},{160,0},{179.594,0},
    {201.587,0},{226.274,0},{253.984,0},{285.088,0},{320,0},
    {359.188,0},{403.175,0},{452.548,0},{507.968,0},{570.175,0},
    {640,0},{718.376,0},{806.349,0},{905.097,0},{1015.937,0},
    {1140.350,0},{1280,0},{1436.751,0},{1612.699,0},{1810.193,0},
    {2031.873,0},{2280.701,0},{2560,0},{2873.503,0},{3225.398,0},
    {3620.387,0},{4063.747,0},{4561.401,0},{5120,0},{5747.006,0},
    {6450.796,0},{7240.773,0},{8127.493,0},{9122.803,0},{10240,0},
    {11494.011,0},{12901.592,0},{14481.547,0},{16254.987,0},{18245.606,0}
}

------------
-- CUSTOM 2
-------------

presets["Custom 2"] = {
    {20,0},{22.449,0},{25.198,0},{28.284,0},{31.748,0},
    {35.636,0},{40,0},{44.898,0},{50.397,0},{56.569,0},
    {63.496,0},{71.272,0},{80,0},{89.797,0},{100.794,0},
    {113.137,0},{126.992,0},{142.544,0},{160,0},{179.594,0},
    {201.587,0},{226.274,0},{253.984,0},{285.088,0},{320,0},
    {359.188,0},{403.175,0},{452.548,0},{507.968,0},{570.175,0},
    {640,0},{718.376,0},{806.349,0},{905.097,0},{1015.937,0},
    {1140.350,0},{1280,0},{1436.751,0},{1612.699,0},{1810.193,0},
    {2031.873,0},{2280.701,0},{2560,0},{2873.503,0},{3225.398,0},
    {3620.387,0},{4063.747,0},{4561.401,0},{5120,0},{5747.006,0},
    {6450.796,0},{7240.773,0},{8127.493,0},{9122.803,0},{10240,0},
    {11494.011,0},{12901.592,0},{14481.547,0},{16254.987,0},{18245.606,0}
}

--------------------------------
-- BUILD anequalizer PARAMETER
--------------------------------
local function build_params(preset, custom)

    local parts = {}

    for i, band in ipairs(preset) do

        local f, g

        if custom then
            f = band[1]
            g = band[2]
        else
            f = FREQUENCIES[i]
            g = band
        end

        if math.abs(g) > 0.0001 then
            local w = band_width(f)

            parts[#parts + 1] = string.format(
                "c0 f=%.3f w=%.3f g=%.3f t=0",
                f, w, g
            )

            parts[#parts + 1] = string.format(
                "c1 f=%.3f w=%.3f g=%.3f t=0",
                f, w, g
            )
        end
    end

    return table.concat(parts, "|")
end

--------------------------
-- REMOVE OUR FILTER ONLY
---------------------------

local function remove_filter()
	if not eq_applied then
        return
    end

    mp.commandv("af", "remove", FILTER)

    eq_applied = false
end

----------------
-- APPLY PRESET
-----------------

local function apply_preset(name)

    local preset = presets[name]

    if not preset then
        msg.error("Unknown preset: " .. tostring(name))
        return
    end

    -- Remove previous EQ only if it actually exists.
    remove_filter()

    -- Empty preset = no EQ.
    if #preset == 0 then
        MODE = "OFF"
        CURRENT_PRESET = name
        mp.osd_message("EQ: " .. name .. " (empty)")
        return
    end

    local custom =
        (name == "Custom 1" or name == "Custom 2")

    local params = build_params(preset, custom)

    -- All gains are zero = flat.
    if params == "" then
        MODE = "OFF"
        CURRENT_PRESET = name
        mp.osd_message("EQ: " .. name .. " (flat)")
        return
    end

    local filter =
        FILTER ..
        ":lavfi=[anequalizer=params=" ..
        params ..
        "]"

    mp.commandv("af", "add", filter)

    -- Mark as installed only AFTER successful add command.
    eq_applied = true

    MODE = "MANUAL"
    CURRENT_PRESET = name

    mp.osd_message("EQ: " .. name)
    msg.info("anequalizer applied: " .. name)
end

--------
-- OFF
--------

local function eq_off()

    remove_filter()

    MODE = "OFF"
    CURRENT_PRESET = nil

    mp.osd_message("EQ: OFF")
    msg.info("anequalizer disabled")
end

------------------------
-- ffprobe LOCATION
-- MPV/
--   scripts/
--       anequalizer.lua
-------------------------

local function get_ffprobe()
    local script_dir = mp.get_script_directory()
    local sep = package.config:sub(1,1)

    if not script_dir then
        return sep == "\\" and "ffprobe.exe" or "ffprobe"
    end

    local parent =
        script_dir:match("^(.*)[/\\][^/\\]+$")
        or script_dir

    if sep == "\\" then
        return parent .. "\\ffprobe.exe"
    else
        return parent .. "/ffprobe"
    end
end

local function detect_he_aac(path)
    if not path or path == "" then
        return false, "no media path"
    end

    local ffprobe = get_ffprobe()
    local args = {
        ffprobe, "-v", "error",
        "-select_streams", "a:0",
        "-show_entries", "stream=codec_name,profile",
        "-of", "default=noprint_wrappers=1:nokey=0",
        path
    }

    local result = utils.subprocess({
        args = args, cancellable = false,
        capture_stdout = true, capture_stderr = true,
        capture_size = 65536
    })

    if not result or result.status ~= 0 then
        msg.warn("ffprobe failed; assuming non-HE-AAC, EQ will apply")
        return false, "ffprobe failed"
    end

    local output = (result.stdout or ""):lower()

    if output:find("profile=he%-aacv2", 1, false) then return true, "HE-AACv2" end
    if output:find("profile=he%-aac",   1, false) then return true, "HE-AAC"   end
    if output:find("spectral band replication", 1, true) then return true, "SBR" end
    if output:find("sbr", 1, true) then return true, "SBR" end
    if output:find("profile=aac lc", 1, true) then return false, "AAC LC" end
    if output:find("codec_name=aac", 1, true) then return true, "AAC profile unknown" end

    return false, "not HE-AAC"
end

------------------------------------
-- SYNCHRONIZE WITH sox_resample.lua
------------------------------------

local function sync_eq()

    local path = mp.get_property("path")

    local is_he_aac, reason =
        detect_he_aac(path)

    if is_he_aac then

        remove_filter()

        msg.info(
            "EQ bypass: " .. tostring(reason)
        )

        mp.osd_message(
            "EQ bypass: " .. tostring(reason),
            2
        )

        return
    end

    if MODE == "MANUAL" and CURRENT_PRESET then
        apply_preset(CURRENT_PRESET)
    end
end

------------
-- HOTKEYS
-----------

mp.add_key_binding("F1", "EQ_OFF", function()
    eq_off()
end)

mp.add_key_binding("F2", "EQ_Classical", function()
    apply_preset("Classical")
end)

mp.add_key_binding("F3", "EQ_Club", function()
    apply_preset("Club")
end)

mp.add_key_binding("F4", "EQ_Dance", function()
    apply_preset("Dance")
end)

mp.add_key_binding("F5", "EQ_FullBass", function()
    apply_preset("FullBass")
end)

mp.add_key_binding("F6", "EQ_FullBassTreble", function()
    apply_preset("FullBass & Treble")
end)

mp.add_key_binding("F7", "EQ_FullTreble", function()
    apply_preset("FullTreble")
end)

mp.add_key_binding("F8", "EQ_Headphones", function()
    apply_preset("Headphones")
end)

mp.add_key_binding("F9", "EQ_Live", function()
    apply_preset("Live")
end)

mp.add_key_binding("F10", "EQ_Party", function()
    apply_preset("Party")
end)

mp.add_key_binding("F11", "EQ_Pop", function()
    apply_preset("Pop")
end)

mp.add_key_binding("F12", "EQ_Rock", function()
    apply_preset("Rock")
end)

--------------------------
-- EXTRA PRESET HOTKEYS
-------------------------

mp.add_key_binding("Ctrl+F1", "EQ_Reggae", function()
    apply_preset("Reggae")
end)

mp.add_key_binding("Ctrl+F2", "EQ_Ska", function()
    apply_preset("Ska")
end)

mp.add_key_binding("Ctrl+F3", "EQ_Soft", function()
    apply_preset("Soft")
end)

mp.add_key_binding("Ctrl+F4", "EQ_SoftRock", function()
    apply_preset("Soft Rock")
end)

mp.add_key_binding("Ctrl+F5", "EQ_Techno", function()
    apply_preset("Techno")
end)

mp.add_key_binding("Ctrl+F6", "EQ_Custom1", function()
    apply_preset("Custom 1")
end)

mp.add_key_binding("Ctrl+F7", "EQ_Custom2", function()
    apply_preset("Custom 2")
end)

---------------
-- FILE EVENT
---------------

local soxr_ready_received = false

mp.register_event("file-loaded", function()
    soxr_ready_received = false
    mp.add_timeout(2.0, function()
        if not soxr_ready_received and MODE == "MANUAL" and CURRENT_PRESET then
            sync_eq()
        end
    end)
end)

mp.register_script_message("soxr-ready", function()
    soxr_ready_received = true
    sync_eq()
end)
msg.info(
    string.format(
        "anequalizer loaded: %d bands, Butterworth t=0",
        #FREQUENCIES
    )
)