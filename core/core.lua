--------------------------------------------------
--------- Incredible mod configuration -----------
--------------------------------------------------

local copy_when_highlighted
-- Blueprint will stop copying texture when highlighted (by clicking on it)
-- Remove -- in front of next line to disable this behaviour
-- copy_when_highlighted = true

local inverted_colors = false
-- Blueprint shader normally inverts sprite colors
-- Remove -- in front of next line to disable this behaviour
-- inverted_colors = false

local use_debuff_logic = true
-- Dont change sprite for debuffed jokers

local use_brainstorm_logic = true
-- Normally blueprint copying brainstorm will show sprite of joker copied by brainstorm
-- Remove -- in front of next line to disable this behaviour
-- use_brainstorm_logic = false

-- Decreasing this value makes blueprinted sprites darker, going above 0.28 is not recommended.
local lightness_offset = 0.131

-- Change coloring mode
-- 1 = linear (1 or less)
-- 2 = exponent
-- 3 = parabola
-- 4 = sin
local coloring_mode = 1

-- Change pow for exponent and parabola modes
local power = 1



--------------------------------------------------

-- Avg blueprint color
local canvas_background_color = {
    (62 + 198) / 255 / 2,
    (96 + 210) / 255 / 2,
    (212 + 252) / 255 / 2,
    0
}

-- Blueprinted border color
canvas_background_color = {
    76 / 255,
    108 / 255,
    216 / 255,
    0
}

local function is_blueprint(card)
    return card and card.config and card.config.center and card.config.center.key == 'j_blueprint'
end

local function is_brainstorm(card)
    return card and card.config and card.config.center and card.config.center.key == 'j_brainstorm'
end

Blueprint.is_blueprint = is_blueprint
Blueprint.is_brainstorm = is_brainstorm


local function process_texture_blueprint(image)
    local width, height = image:getDimensions()
    local canvas = love.graphics.newCanvas(width, height, {type = '2d', readable = true, dpiscale = image:getDPIScale()})

    love.graphics.push("all")

    love.graphics.setCanvas( canvas )
    love.graphics.clear(canvas_background_color)
    
    love.graphics.setColor(1, 1, 1, 1)

    G.SHADERS['blueprint_shader']:send('inverted', inverted_colors)
    G.SHADERS['blueprint_shader']:send('lightness_offset', lightness_offset)
    G.SHADERS['blueprint_shader']:send('mode', coloring_mode)
    G.SHADERS['blueprint_shader']:send('expo', power)
    love.graphics.setShader( G.SHADERS['blueprint_shader'] )
    
    -- Draw image with blueprint shader on new canvas
    love.graphics.draw( image )

    love.graphics.pop()

    return love.graphics.newImage(canvas:newImageData(), {mipmaps = true, dpiscale = image:getDPIScale()})
end

local function process_texture_brainstorm(image, px, py, floating_image, offset)
    local width, height = image:getDimensions()
    local canvas = love.graphics.newCanvas(width, height, {type = '2d', readable = true, dpiscale = image:getDPIScale()})

    love.graphics.push("all")
    love.graphics.setCanvas( canvas )
    love.graphics.clear(canvas_background_color)
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setShader()
    love.graphics.draw( image )
    if floating_image and offset then
        love.graphics.draw(floating_image, -offset.x, -offset.y)
    end

    love.graphics.pop()

    local canvas2 = love.graphics.newCanvas(width, height, {type = '2d', readable = true, dpiscale = image:getDPIScale()})
    love.graphics.push("all")
    love.graphics.setCanvas( canvas2 )
    love.graphics.clear(canvas_background_color)
    love.graphics.setColor(1, 1, 1, 1)

    G.SHADERS['brainstorm_shader']:send('dpi', image:getDPIScale())
    G.SHADERS['brainstorm_shader']:send('greyscale_weights', {0.299, 0.587, 0.114})
    G.SHADERS['brainstorm_shader']:send('blur_amount', 1)
    G.SHADERS['brainstorm_shader']:send('card_size', {px, py})
    G.SHADERS['brainstorm_shader']:send('margin', {5, 5})
    G.SHADERS['brainstorm_shader']:send('blue_low', {60.0/255.0, 100.0/255.0, 200.0/255.0, 0.4})
    G.SHADERS['brainstorm_shader']:send('blue_high', {60.0/255.0, 100.0/255.0, 200.0/255.0, 0.8})
    G.SHADERS['brainstorm_shader']:send('red_low', {255.0/255.0, 150.0/255.0, 0.0/255.0, 0.5})
    G.SHADERS['brainstorm_shader']:send('red_high', {255.0/255.0, 80.0/255.0, 0.0/255.0, 0.9})
    G.SHADERS['brainstorm_shader']:send('blue_threshold', 0.75)
    G.SHADERS['brainstorm_shader']:send('red_threshold', 0.2)
    
    love.graphics.setShader(G.SHADERS['brainstorm_shader'])
    love.graphics.draw(canvas)

    love.graphics.pop()

    return love.graphics.newImage(canvas2:newImageData(), {mipmaps = true, dpiscale = image:getDPIScale()})
end


local function pre_blueprinted(a)
    local atlas = a.name or a.key
    local name = atlas.."_".."blueprinted"
    if G.ASSET_ATLAS[name] then
        return {
            old_name = atlas,
            new_name = name,
            atlas = G.ASSET_ATLAS[name],
        }
    else
        return {
            old_name = atlas,
            new_name = name,
            atlas = nil
        }
    end
end

local function pre_brainstormed(a, f, offset)
    local atlas = a.name or a.key
    local floating_atlas = f and (f.name or f.key) or "nil"
    local name = atlas.."_"..floating_atlas.."_"..(offset and offset.x or "nil").."_"..(offset and offset.y or "nil").."_".."brainstormed"
    if G.ASSET_ATLAS[name] then
        return {
            old_name = atlas,
            old_floating_name = floating_atlas,
            new_name = name,
            atlas = G.ASSET_ATLAS[name],
        }
    else
        return {
            old_name = atlas,
            old_floating_name = floating_atlas,
            new_name = name,
            atlas = nil
        }
    end
end

local function blueprint_atlas(a)
    local blueprinted = pre_blueprinted(a)

    if not blueprinted.atlas then
        G.ASSET_ATLAS[blueprinted.new_name] = {}
        G.ASSET_ATLAS[blueprinted.new_name].blueprint = true
        G.ASSET_ATLAS[blueprinted.new_name].name = G.ASSET_ATLAS[blueprinted.old_name].name
        G.ASSET_ATLAS[blueprinted.new_name].type = G.ASSET_ATLAS[blueprinted.old_name].type
        G.ASSET_ATLAS[blueprinted.new_name].px = G.ASSET_ATLAS[blueprinted.old_name].px
        G.ASSET_ATLAS[blueprinted.new_name].py = G.ASSET_ATLAS[blueprinted.old_name].py
        G.ASSET_ATLAS[blueprinted.new_name].image = process_texture_blueprint(G.ASSET_ATLAS[blueprinted.old_name].image)
    end

    return G.ASSET_ATLAS[blueprinted.new_name]
end

local function brainstorm_atlas(a, f, offset)
    local brainstormed = pre_brainstormed(a, f, offset)

    if not brainstormed.atlas then
        G.ASSET_ATLAS[brainstormed.new_name] = {}
        -- using .blueprint for this aswell - Jonathan
        G.ASSET_ATLAS[brainstormed.new_name].blueprint = true
        G.ASSET_ATLAS[brainstormed.new_name].name = G.ASSET_ATLAS[brainstormed.old_name].name
        G.ASSET_ATLAS[brainstormed.new_name].type = G.ASSET_ATLAS[brainstormed.old_name].type
        G.ASSET_ATLAS[brainstormed.new_name].px = G.ASSET_ATLAS[brainstormed.old_name].px
        G.ASSET_ATLAS[brainstormed.new_name].py = G.ASSET_ATLAS[brainstormed.old_name].py
        G.ASSET_ATLAS[brainstormed.new_name].image = process_texture_brainstorm(G.ASSET_ATLAS[brainstormed.old_name].image, G.ASSET_ATLAS[brainstormed.old_name].px, G.ASSET_ATLAS[brainstormed.old_name].py, f and G.ASSET_ATLAS[brainstormed.old_floating_name].image or nil, offset)
    end

    return G.ASSET_ATLAS[brainstormed.new_name]
end

local function equal_sprites(first, second)
    if not first and not second then
        return true
    end
    if not first and second then
        return false
    end
    if first and not second then
        return false
    end
    -- Dynamically update sprite for animated jokers & multiple blueprint copies
    return first.atlas.name == second.atlas.name and first.sprite_pos.x == second.sprite_pos.x and first.sprite_pos.y == second.sprite_pos.y
end


local function align_sprite(self, card, restore)
    if restore then
        if self.blueprint_T then
            self.T.h = self.blueprint_T.h
            self.T.w = self.blueprint_T.w
--        else
--            self.T.h = G.CARD_H
--            self.T.w = G.CARD_W
        end
        return
    end

    if not self.blueprint_T then
        self.blueprint_T = {h = self.T.h, w = self.T.w}
    end

    self.T.h = card.T.h
    self.T.w = card.T.w
    self.children.center.scale.y = card.children.center.scale.y
end

local function blueprint_sprite(blueprint, card)
    if pre_blueprinted(card.children.center.atlas).atlas then
        if equal_sprites(blueprint.children.center, card.children.center) then
            if equal_sprites(blueprint.children.floating_sprite, card.children.floating_sprite) then
                return
            end
        end
    end
        
    -- Not copying any other joker's sprite at the moment. Cache current sprite before updating
    if not blueprint.blueprint_sprite_copy then
        blueprint.blueprint_sprite_copy = blueprint.children.center
    end
    blueprint.blueprint_copy_key = card.config.center.key

    -- Make sure to remove floating sprite before applying new one
    if blueprint.children.floating_sprite then
        blueprint.children.floating_sprite:remove()
        blueprint.children.floating_sprite = nil
    end

    align_sprite(blueprint, nil, true)

    blueprint.children.center = Sprite(blueprint.T.x, blueprint.T.y, blueprint.T.w, blueprint.T.h, blueprint_atlas(card.children.center.atlas), card.children.center.sprite_pos)
    blueprint.children.center.states.hover = blueprint.states.hover
    blueprint.children.center.states.click = blueprint.states.click
    blueprint.children.center.states.drag = blueprint.states.drag
    blueprint.children.center.states.collide.can = false
    blueprint.children.center:set_role({major = blueprint, role_type = 'Glued', draw_major = blueprint})

    if card.children.floating_sprite then
        blueprint.children.floating_sprite = Sprite(blueprint.T.x, blueprint.T.y, blueprint.T.w, blueprint.T.h, blueprint_atlas(card.children.floating_sprite.atlas), card.children.floating_sprite.sprite_pos)
        blueprint.children.floating_sprite.role.draw_major = blueprint
        blueprint.children.floating_sprite.states.hover.can = false
        blueprint.children.floating_sprite.states.click.can = false
    end

    --if card.children.floating_sprite2 then
    --    blueprint.children.floating_sprite2 = Sprite(blueprint.T.x, blueprint.T.y, blueprint.T.w, blueprint.T.h, G.ASSET_ATLAS[card.children.floating_sprite2.atlas.name], card.children.floating_sprite2.sprite_pos)
    --    blueprint.children.floating_sprite2.role.draw_major = blueprint
    --    blueprint.children.floating_sprite2.states.hover.can = false
    --    blueprint.children.floating_sprite2.states.click.can = false
    --end
    align_sprite(blueprint, card)
end

local function brainstorm_sprite(brainstorm, card)
    local offset = nil
    if card.children.floating_sprite then
        offset = {}
        offset.x = card.children.floating_sprite.sprite_pos.x * card.children.floating_sprite.atlas.px - card.children.center.sprite_pos.x * card.children.center.atlas.px
        offset.y = card.children.floating_sprite.sprite_pos.y * card.children.floating_sprite.atlas.py - card.children.center.sprite_pos.y * card.children.center.atlas.py
        -- print(card.children.floating_sprite.sprite_pos.x - card.children.center.sprite_pos.x, card.children.floating_sprite.sprite_pos.y - card.children.center.sprite_pos.y)
        -- print(offset.x, offset.y)
    end

    if card.children.floating_sprite and pre_brainstormed(card.children.center.atlas, card.children.floating_sprite.atlas, offset).atlas or pre_brainstormed(card.children.center.atlas, nil, nil).atlas then
        if equal_sprites(brainstorm.children.center, card.children.center) then
            if equal_sprites(brainstorm.children.floating_sprite, card.children.floating_sprite) then
                return
            end
        end
    end

    -- Not copying any other joker's sprite at the moment. Cache current sprite before updating
    -- I'm using blueprint_sprite_copy for both blueprint and brainstorm - Jonathan
    if not brainstorm.blueprint_sprite_copy then
        brainstorm.blueprint_sprite_copy = brainstorm.children.center
    end
    -- I'm using blueprint_copy_key for both blueprint and brainstorm - Jonathan
    brainstorm.blueprint_copy_key = card.config.center.key

    -- Make sure to remove floating sprite before applying new one
    if brainstorm.children.floating_sprite then
        brainstorm.children.floating_sprite:remove()
        brainstorm.children.floating_sprite = nil
    end

    align_sprite(brainstorm, nil, true)

    if card.children.floating_sprite then
        brainstorm.children.center = Sprite(brainstorm.T.x, brainstorm.T.y, brainstorm.T.w, brainstorm.T.h, brainstorm_atlas(card.children.center.atlas, card.children.floating_sprite.atlas, offset), card.children.center.sprite_pos)
    else
        brainstorm.children.center = Sprite(brainstorm.T.x, brainstorm.T.y, brainstorm.T.w, brainstorm.T.h, brainstorm_atlas(card.children.center.atlas, nil, nil), card.children.center.sprite_pos)
    end
    brainstorm.children.center.states.hover = brainstorm.states.hover
    brainstorm.children.center.states.click = brainstorm.states.click
    brainstorm.children.center.states.drag = brainstorm.states.drag
    brainstorm.children.center.states.collide.can = false
    brainstorm.children.center:set_role({major = brainstorm, role_type = 'Glued', draw_major = brainstorm})

    -- if true and card.children.floating_sprite then
    --     brainstorm.children.floating_sprite = Sprite(brainstorm.T.x, brainstorm.T.y, brainstorm.T.w, brainstorm.T.h, card.children.floating_sprite.atlas, card.children.floating_sprite.sprite_pos)
    --     brainstorm.children.floating_sprite.role.draw_major = brainstorm
    --     brainstorm.children.floating_sprite.states.hover.can = false
    --     brainstorm.children.floating_sprite.states.click.can = false
    -- elseif card.children.floating_sprite then
    --     brainstorm.children.floating_sprite = Sprite(brainstorm.T.x, brainstorm.T.y, brainstorm.T.w, brainstorm.T.h, brainstorm_atlas(card.children.floating_sprite.atlas), card.children.floating_sprite.sprite_pos)
    --     brainstorm.children.floating_sprite.role.draw_major = brainstorm
    --     brainstorm.children.floating_sprite.states.hover.can = false
    --     brainstorm.children.floating_sprite.states.click.can = false
    -- end

    --if card.children.floating_sprite2 then
    --    brainstorm.children.floating_sprite2 = Sprite(brainstorm.T.x, brainstorm.T.y, brainstorm.T.w, brainstorm.T.h, G.ASSET_ATLAS[card.children.floating_sprite2.atlas.name], card.children.floating_sprite2.sprite_pos)
    --    brainstorm.children.floating_sprite2.role.draw_major = brainstorm
    --    brainstorm.children.floating_sprite2.states.hover.can = false
    --    brainstorm.children.floating_sprite2.states.click.can = false
    --end
    align_sprite(brainstorm, card)
end

-- for both blueprint and brainstorm - Jonathan
local function restore_sprite(blueprint)
    if not blueprint.blueprint_sprite_copy then
        return
    end

    blueprint.children.center:remove()
    blueprint.children.center = blueprint.blueprint_sprite_copy
    blueprint.blueprint_sprite_copy = nil
    blueprint.blueprint_copy_key = nil

    if blueprint.children.floating_sprite then
        blueprint.children.floating_sprite:remove()
        blueprint.children.floating_sprite = nil
    end

    --if blueprint.children.floating_sprite2 then
    --    blueprint.children.floating_sprite2:remove()
    --    blueprint.children.floating_sprite2 = nil
    --end

    align_sprite(blueprint, nil, true)
end

local sprite_reset = Sprite.reset
function Sprite:reset()
    if self.atlas.blueprint then
        if type(self.atlas.release) == "function" then
            self.atlas:release()
        end
        self.atlas = blueprint_atlas(self.atlas)
        self:set_sprite_pos(self.sprite_pos)
        return
    end
    
    return sprite_reset(self)
end

local function find_brainstormed_joker()
    local index = 1
    local max = #G.jokers.cards
    while index <= max do
        local current = G.jokers.cards[index]
        if not current or current.debuff then
            return nil
        end

        if is_blueprint(current) then
            index = index + 1
        elseif is_brainstorm(current) then
            -- Looped back into brainstorm
            return nil
        else
            return current
        end
    end

    return nil
end

local function find_blueprinted_joker(current_joker, previous_joker)
    if not previous_joker then
        return nil
    end

    if use_brainstorm_logic and is_brainstorm(previous_joker) then
        if use_debuff_logic and previous_joker.debuff then
            -- Brainstorm is debuffed, so it isn't copying leftmost
            return nil
        else
            previous_joker = find_brainstormed_joker()
        end
    end
    if not previous_joker then
        return
    end

    if use_debuff_logic then
        if current_joker.debuff or previous_joker.debuff then
            -- Copied card is debuffed, so shouldn't copy
            return nil
        end

        -- current joker is blueprint. it is debuffed. so blueprints to the left aren't copying anything
        if current_joker.debuff then
            return nil
        end
    end

    local should_copy = previous_joker.config.center.blueprint_compat and not current_joker.states.drag.is and (copy_when_highlighted or not current_joker.highlighted)
    if should_copy then
        return previous_joker
    end

    return nil
end

local cardarea_align_cards = CardArea.align_cards
function CardArea:align_cards()
    local ret = cardarea_align_cards(self)

    if self == G.jokers then
        local brainstormed_joker = find_brainstormed_joker()

        local previous_joker = nil
        local current_joker = nil
        for i = #G.jokers.cards, 1, -1  do
            current_joker = G.jokers.cards[i]
            if is_brainstorm(current_joker) then
                local should_copy = brainstormed_joker and not (use_debuff_logic and (current_joker.debuff or brainstormed_joker.debuff)) and brainstormed_joker.config.center.blueprint_compat and not current_joker.states.drag.is and (copy_when_highlighted or not current_joker.highlighted)
                if should_copy then
                    brainstorm_sprite(current_joker, brainstormed_joker)
                else
                    restore_sprite(current_joker)
                end

            elseif is_blueprint(current_joker) then
                previous_joker = find_blueprinted_joker(current_joker, previous_joker)

                if previous_joker then
                    blueprint_sprite(current_joker, previous_joker)
                else
                    restore_sprite(current_joker)
                end
            end
            if not (current_joker.config.center.key == 'j_blueprint') then
                previous_joker = current_joker
            end
        end

    end

    return ret
end

