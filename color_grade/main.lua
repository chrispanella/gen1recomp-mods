-- color_grade: richer color (saturation + contrast) via a small shader.
-- OPTIONS: OFF / SOFT / RICH / MAX. If the shader ever fails to compile the
-- pipeline simply passes the frame through unchanged.
local LEVELS = { "OFF", "SOFT", "RICH", "MAX" }
local AMT = { 0.35, 0.7, 1.0 }

local SHADER = [[
extern number amt;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
  vec4 p = Texel(tex, uv);
  vec3 rgb = p.rgb;
  float l = dot(rgb, vec3(0.299, 0.587, 0.114));
  rgb = mix(vec3(l), rgb, 1.0 + 0.6 * amt);   // saturation
  rgb = mix(vec3(0.5), rgb, 1.0 + 0.22 * amt); // contrast
  return vec4(clamp(rgb, 0.0, 1.0), p.a) * color;
}
]]

return function(mod)
  local out, amt, shader = nil, 0, nil
  local function ensure(w, h)
    if not out or out:getWidth() ~= w or out:getHeight() ~= h then
      if out then out:release() end
      out = love.graphics.newCanvas(w, h)
    end
    return out
  end
  mod.content.render_pipelines:register("color_grade", {
    label = "COLOR GRADE",
    levels = LEVELS,
    priority = 6,
    available = function() return love and love.graphics and love.graphics.newShader ~= nil end,
    update = function(dt, level) amt = AMT[level] or 0 end,
    present = function(canvas, ctx)
      if canvas == nil or amt <= 0 then return canvas end
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
      shader:send("amt", amt)
      love.graphics.setShader(shader)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(canvas)
      love.graphics.pop()
      return o
    end,
  })
end
