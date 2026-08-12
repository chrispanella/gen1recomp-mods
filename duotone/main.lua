-- duotone: retro two-tone looks via a small shader (maps brightness onto a
-- dark->light color ramp). OPTIONS: OFF / GB GREEN / SEPIA / NOIR. Falls
-- through unchanged if the shader will not compile.
local LEVELS = { "OFF", "GB GREEN", "SEPIA", "NOIR" }
-- lo (dark) and hi (light) colors per level
local RAMP = {
  { { 0.06, 0.22, 0.06 }, { 0.61, 0.74, 0.06 } }, -- Game Boy green
  { { 0.20, 0.12, 0.05 }, { 0.98, 0.86, 0.62 } }, -- sepia
  { { 0.03, 0.03, 0.05 }, { 0.95, 0.95, 0.98 } }, -- noir
}

local SHADER = [[
extern vec3 lo;
extern vec3 hi;
extern number amt;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
  vec4 p = Texel(tex, uv);
  float l = dot(p.rgb, vec3(0.299, 0.587, 0.114));
  vec3 duo = mix(lo, hi, l);
  vec3 rgb = mix(p.rgb, duo, amt);
  return vec4(rgb, p.a) * color;
}
]]

return function(mod)
  local out, ramp, shader = nil, nil, nil
  local function ensure(w, h)
    if not out or out:getWidth() ~= w or out:getHeight() ~= h then
      if out then out:release() end
      out = love.graphics.newCanvas(w, h)
    end
    return out
  end
  mod.content.render_pipelines:register("duotone", {
    label = "DUOTONE",
    levels = LEVELS,
    priority = 6,
    available = function() return love and love.graphics and love.graphics.newShader ~= nil end,
    update = function(dt, level) ramp = RAMP[level] or nil end,
    present = function(canvas, ctx)
      if canvas == nil or ramp == nil then return canvas end
      if shader == nil then
        local ok, sh = pcall(love.graphics.newShader, SHADER)
        shader = ok and sh or false
      end
      if not shader then return canvas end
      local w, h = canvas:getWidth(), canvas:getHeight()
      local o = ensure(w, h)
      love.graphics.push("all")
      love.graphics.setCanvas(o)
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setBlendMode("alpha", "premultiplied")
      shader:send("lo", ramp[1])
      shader:send("hi", ramp[2])
      shader:send("amt", 1.0)
      love.graphics.setShader(shader)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(canvas)
      love.graphics.pop()
      return o
    end,
  })
end
