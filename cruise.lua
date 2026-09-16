-- mixer script for cruise control

local my_input =
  {
    { "Throttle", SOURCE },           -- throttle input
    { "Shifter", SOURCE},               -- shifter input
    { "FactorAcc",   VALUE, 0, 100, 33 }, -- factor by how much to increase value, default = 33.
    { "FactorBrk",   VALUE, 0, 100, 55 }, -- factor by how much to decrease value, default = 55.
    { "Deadband", VALUE, 0, 100, 10}, -- deadband of the throttle to prevent output changes in center position, default = 10
  }

local my_output = { "Out", "Gear" }

local lastTime = 0
local lastOutput = 0
local currentShift = true -- HIGH is forward and LOW is backward

local function my_init()
    -- Called once when the script is loaded
end

local function my_run(Throttle, Shifter, FactorAcc, FactorBrk, Deadband) -- Must match input table
    local throttlePercentage = Throttle / 10.24
    if math.abs(throttlePercentage) < Deadband then
        throttlePercentage = 0
    end

    local factorAlign = 0
    if throttlePercentage < 0 then
        -- is braking then use other factor
        factorAlign = FactorBrk / 10000
    else
        factorAlign = FactorAcc / 10000
    end
    local deltaTime = getTime() - lastTime
    deltaTime = math.min(deltaTime, 5)
    lastTime = getTime()

    if currentShift == false then
        -- Reverse the throttle value to have same throttle direction when reversing
	throttlePercentage = -1 * throttlePercentage
    end

    local output = lastOutput + (throttlePercentage * factorAlign * deltaTime)

    -- Changing gear can only happen when throttle output is at 0
    if Shifter > 511 and lastOutput == 0 then
        currentShift = true
    elseif Shifter < -511 and lastOutput == 0 then
        currentShift = false
    end

    local shiftValue = 0
    if currentShift then
        output = math.max(0, math.min(100, output))
        shiftValue = 1024
    else
        output = math.max(-100, math.min(0, output))
        shiftValue = -1024
    end

    lastOutput = output
    output = output * 10.24
    output = math.ceil(output)
    output = math.max(-1024, math.min(1024, output))

  return output, shiftValue                        -- Must match output table
end

return { input = my_input, output = my_output, run = my_run, init = my_init }
