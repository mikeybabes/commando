-- Commando memory map (preliminary)
-- Visualizes all sprite bounding boxes for Commando

cpu = manager.machine.devices[":maincpu"]
mem = cpu.spaces["program"]
screen = manager.machine.screens[":screen"]

-- sprite RAM base address
SPRITE_RAM_BASE = 0xfe00

-- Number of sprites
NUM_SPRITES = (0x180 / 4) - 1 -- 95 sprites, first 4 bytes are not used

-- Y position adjustment
Y_ADJUSTMENT = -16

-- toggle sprites on/off
SHOW_SPRITES = true

-- Text size
TEXT_SCALE = 0.5

function read_sprite_ram(offset)
    return mem:read_u8(SPRITE_RAM_BASE + offset)
end

function get_sprite_code(index)
    local code = read_sprite_ram(index * 4)
    local attributes = read_sprite_ram(index * 4 + 1)
    local high_bits = (attributes & 0xC0) >> 6
    local full_code = string.format("%X%X", high_bits, code):gsub("^0+", "")
    return full_code
end

function get_sprite_palette(index)
    return (read_sprite_ram(index * 4 + 1) & 0x30) >> 4
end

function get_flip_x(index)
    return (read_sprite_ram(index * 4 + 1) & 0x04) ~= 0
end

function get_flip_y(index)
    return (read_sprite_ram(index * 4 + 1) & 0x08) ~= 0
end

function get_sprite_x(index)
    return read_sprite_ram(index * 4 + 3) - ((read_sprite_ram(index * 4 + 1) & 0x01) << 8)
end

function get_sprite_y(index)
    return read_sprite_ram(index * 4 + 2) + Y_ADJUSTMENT
end

function get_sprite_height(index)
    return 1 -- fixed height of 1 for simplicity; adjust as necessary
end

function clamp(v, min, max)
    return math.min(max, math.max(min, v))
end

function isOnScreen(left, top, right, bottom)
    return not (right < 0 or bottom < 0 or left > 255 or top > 224)
end

RED = 0xffff0000
ORANGE = 0xffffaa00
PURPLE = 0xffaa00ff
WHITE = 0xffffffff

colors = { RED, ORANGE, PURPLE, WHITE }

function visualize_boundingBoxes()
    if not SHOW_SPRITES then
        return
    end
    
    for i = 1, NUM_SPRITES do
        local x = get_sprite_x(i)
        local y = get_sprite_y(i)
        
        if x ~= 0 and y ~= Y_ADJUSTMENT then -- Check if sprite is enabled
            local h = get_sprite_height(i) * 16

            local left = x
            local top = y
            local right = x + 16
            local bottom = y + h

            if isOnScreen(left, top, right, bottom) then
                screen:draw_box(
                    clamp(left, 0, 255),
                    clamp(top, 0, 224),
                    clamp(right, 0, 255),
                    clamp(bottom, 0, 224),
                    colors[i % 4],
                    0
                )
                local sprite_code = get_sprite_code(i)
                screen:draw_text(
                    clamp(left, 0, 255),
                    clamp(top, 0, 224),
                    tostring(i) .. "\n" .. sprite_code,
                    0xffffffff,
                    TEXT_SCALE
                )
            end
        end
    end
end

function on_frame()
    visualize_boundingBoxes()
end

function on_pause()
    for i = 1, NUM_SPRITES do
        local x = get_sprite_x(i)
        local y = get_sprite_y(i)

        if x ~= 0 and y ~= Y_ADJUSTMENT then -- Check if sprite is enabled
            local sprite_code = get_sprite_code(i)
            local palette = get_sprite_palette(i)
            local flip_x = get_flip_x(i)
            local flip_y = get_flip_y(i)
            print(string.format(
                "Sprite %d: x: %d, y: %d, code: %s, palette: %X, flip_x: %s, flip_y: %s",
                i, x, y, sprite_code, palette, tostring(flip_x), tostring(flip_y)
            ))
        end
    end
end

emu.register_frame_done(on_frame, "frame")
emu.register_pause(on_pause, "pause")
