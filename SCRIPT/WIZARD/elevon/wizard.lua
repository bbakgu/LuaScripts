---- #########################################################################
---- #                                                                       #
---- # Copyright (C) OpenTX                                                  #
-----#                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- # This program is free software; you can redistribute it and/or modify  #
---- # it under the terms of the GNU General Public License version 2 as     #
---- # published by the Free Software Foundation.                            #
---- #                                                                       #
---- # This program is distributed in the hope that it will be useful        #
---- # but WITHOUT ANY WARRANTY; without even the implied warranty of        #
---- # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
---- # GNU General Public License for more details.                          #
---- #                                                                       #
---- #########################################################################
local VALUE = 0
local COMBO = 1

local edit = false
local page = 1
local current = 1
local pages = {}
local fields = {}

-- load common Bitmaps
local ImgMarkBg = Bitmap.open("img/mark_bg.png")
local BackgroundImg = Bitmap.open("img/background.png")
local ImgPlane = Bitmap.open("img/elevons.bmp")
local ImgPageUp = Bitmap.open("img/pageup.png")
local ImgPageDn = Bitmap.open("img/pagedn.png")


-- Change display attribute to current field
local function addField(step)
  local field = fields[current]
  local min, max
  if field[3] == VALUE then
    min = field[6]
    max = field[7]
  elseif field[3] == COMBO then
    min = 0
    max = #(field[6]) - 1
  end
  if (step < 0 and field[5] > min) or (step > 0 and field[5] < max) then
    field[5] = field[5] + step
  end
end

-- Select the next or previous page
local function selectPage(step)
  page = 1 + ((page + step - 1 + #pages) % #pages)
  edit = false
  current = 1
end

-- Select the next or previous editable field
local function selectField(step)
  repeat
    current = 1 + ((current + step - 1 + #fields) % #fields)
  until fields[current][4]==1
end

-- Redraw the current page
local function redrawFieldsPage(event)

  for index = 1, 10, 1 do
    local field = fields[index]
    if field == nil then
      break
    end

    local attr = current == (index) and ((edit == true and BLINK or 0) + INVERS) or 0
    attr = attr + TEXT_COLOR

    if field[4] == 1 then
      if field[3] == VALUE then
        lcd.drawNumber(field[1], field[2], field[5], LEFT + attr)
      elseif field[3] == COMBO then
        if field[5] >= 0 and field[5] < #(field[6]) then
          lcd.drawText(field[1],field[2], field[6][1+field[5]], attr)
        end
      end
    end
  end
end

local function updateField(field)
  local value = field[5]
end

-- Main
local function runFieldsPage(event)
  if event == EVT_VIRTUAL_EXIT then -- exit script
    return 2
  elseif event == EVT_VIRTUAL_ENTER then -- toggle editing/selecting current field
    if fields[current][5] ~= nil then
      edit = not edit
      if edit == false then
        updateField(fields[current])
      end
    end
  elseif edit then
    if event == EVT_VIRTUAL_INC or event == EVT_VIRTUAL_INC_REPT then
      addField(1)
    elseif event == EVT_VIRTUAL_DEC or event == EVT_VIRTUAL_DEC_REPT then
      addField(-1)
    end
  else
    if event == EVT_VIRTUAL_NEXT then
      selectField(1)
    elseif event == EVT_VIRTUAL_PREV then
      selectField(-1)
    end
  end
  redrawFieldsPage(event)
  return 0
end

-- set visibility flags starting with SECOND field of fields
local function setFieldsVisible(...)
  local arg={...}
  local cnt = 2
  for i,v in ipairs(arg) do
    fields[cnt][4] = v
    cnt = cnt + 1
  end
end

-- draws one letter mark
local function drawMark(x, y, name)
  lcd.drawBitmap(ImgMarkBg, x, y)
  lcd.drawText(x+8, y+3, name, TEXT_COLOR)
end


local MotorFields = {
  {50, 50, COMBO, 1, 1, { "No", "Yes"} },
  {50, 127, COMBO, 1, 2, { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8" } },
}

local ImgEngine

local function runMotorConfig(event)
  lcd.clear()
  if ImgEngine == nil then
    ImgEngine = Bitmap.open("img/prop.png")
  end
  lcd.drawBitmap(BackgroundImg, 0, 0)
  lcd.drawBitmap(ImgPageDn, 455, 95)
  lcd.drawBitmap(ImgEngine, 310, 50)
  fields = MotorFields
  lcd.drawText(40, 20, "Does your model have a motor ?", TEXT_COLOR)
  lcd.drawFilledRectangle(40, 45, 200, 30, TEXT_BGCOLOR)
  fields[2][4]=0
  if fields[1][5] == 1 then
    lcd.drawText(40, 100, "What channel is it on ?", TEXT_COLOR)
    lcd.drawFilledRectangle(40, 122, 100, 30, TEXT_BGCOLOR)
    fields[2][4]=1
  end
  local result = runFieldsPage(event)
  return result
end

-- fields format : {[1]x, [2]y, [3]COMBO, [4]visible, [5]default, [6]{values}}
-- fields format : {[1]x, [2]y, [3]VALUE, [4]visible, [5]default, [6]min, [7]max}
local AilFields = {
  {50, 127, COMBO, 1, 0, { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8" } }, -- Ail1 chan
  {50, 167, COMBO, 1, 1, { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8" } }, -- Ail2 chan
}


local function runAilConfig(event)
  lcd.clear()

  lcd.drawBitmap(BackgroundImg, 0, 0)
  lcd.drawBitmap(ImgPageUp, 0, 95)
  lcd.drawBitmap(ImgPageDn, 455, 95)
  lcd.drawBitmap(ImgPlane, 252, 100)

  fields = AilFields

  drawMark(237, 148, "A")
  drawMark(302, 148, "B")
  lcd.drawFilledRectangle(40, 122, 100, 30, TEXT_BGCOLOR)
  drawMark(152, 124, "A")
  lcd.drawFilledRectangle(40, 162, 100, 30, TEXT_BGCOLOR)
  drawMark(152, 164, "B")


  lcd.drawText(40, 20, "Select elevon channels...", TEXT_COLOR)

  local result = runFieldsPage(event)
  return result
end

local FlapsFields = {
  {50, 50, COMBO, 1, 0, { "No", "Yes, on one channel", "Yes, on two channels"} },
  {50, 127, COMBO, 1, 6, { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8" } },
  {50, 167, COMBO, 1, 7, { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8" } },
}
local ImgFlp

local function runFlapsConfig(event)
  lcd.clear()

  lcd.drawBitmap(BackgroundImg, 0, 0)
  lcd.drawBitmap(ImgPageUp, 0, 95)
  lcd.drawBitmap(ImgPageDn, 455, 95)
  lcd.drawBitmap(ImgPlane, 252, 100)
  fields = FlapsFields
  if fields[1][5] == 1 then
    
    drawMark(237, 148, "A")
    drawMark(302, 148, "A")
    lcd.drawFilledRectangle(40, 122, 100, 30, TEXT_BGCOLOR)
    drawMark(152, 124, "A")
    setFieldsVisible(1, 0)
  elseif fields[1][5] == 2 then
    drawMark(237, 148, "A")
    drawMark(302, 148, "B")
    lcd.drawFilledRectangle(40, 122, 100, 30, TEXT_BGCOLOR)
    drawMark(152, 124, "A")
    lcd.drawFilledRectangle(40, 162, 100, 30, TEXT_BGCOLOR)
    drawMark(152, 164, "B")
    setFieldsVisible(1, 1)
  else
    setFieldsVisible(0, 0)
  end
  lcd.drawText(40, 20, "Does your model have flaps ?", TEXT_COLOR)
  lcd.drawFilledRectangle(40, 45, 400, 30, TEXT_BGCOLOR)
  local result = runFieldsPage(event)
  return result
end

local TailFields = {
  {50, 50, COMBO, 1, 0, { "No", "Yes"} },
  {50, 127, COMBO, 1, 3, { "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8" } }, --rud
}

local ImgRud

local function runRudderConfig(event)
  lcd.clear()
  if ImgRud == nil then
    ImgRud = Bitmap.open("img/drudder-1.bmp")
  end
  lcd.drawBitmap(BackgroundImg, 0, 0)
  lcd.drawBitmap(ImgPageUp, 0, 95)
  lcd.drawBitmap(ImgPageDn, 455, 95)
  fields = TailFields
  if fields[1][5] == 1 then
    lcd.drawBitmap(ImgRud, 252, 120)

    drawMark(325, 90, "A")
    lcd.drawFilledRectangle(40, 122, 100, 30, TEXT_BGCOLOR)
    drawMark(152, 124, "A")
    setFieldsVisible(1)
  else
    setFieldsVisible(0)
  end
  
  lcd.drawText(40, 20, "Does your model have rudder ?", TEXT_COLOR)
  lcd.drawFilledRectangle(40, 45, 400, 30, TEXT_BGCOLOR)
  local result = runFieldsPage(event)
  return result
end

local lineIndex
local function drawNextLine(text, text2)
  lcd.drawText(40, lineIndex, text, TEXT_COLOR)
  lcd.drawText(242, lineIndex, ": CH" .. text2 + 1, TEXT_COLOR)
  lineIndex = lineIndex + 20
end

local function drawNextLineNoCh(text)
  lcd.drawText(40, lineIndex, text, TEXT_COLOR)
  lineIndex = lineIndex + 20
end

local ConfigSummaryFields = {
  {110, 250, COMBO, 1, 0, { "No, I need to change something", "Yes, all is well, create the plane !"} },
}

local ImgSummary

local function runConfigSummary(event)
  lcd.clear()
  if ImgSummary == nil then
    ImgSummary = Bitmap.open("img/summary.png")
  end
  fields = ConfigSummaryFields
  lcd.drawBitmap(BackgroundImg, 0, 0)
  lcd.drawBitmap(ImgPageUp, 0, 95)
  lcd.drawBitmap(ImgSummary, 300, 60)
  lineIndex = 40
  -- motors
  if(MotorFields[1][5] == 1) then
    drawNextLine("Motor channel", MotorFields[2][5])
  end
  -- ail
  drawNextLine("Aileron/Ele Left channel",AilFields[1][5])
  drawNextLine("Aileron/Ele Right channel",AilFields[2][5])
  
  -- flaps
  if(FlapsFields[1][5] == 0) then
    drawNextLineNoCh("No flaps")
  elseif(FlapsFields[1][5] == 1) then
    drawNextLine("Flaps channel",FlapsFields[2][5])
  elseif (FlapsFields[1][5] == 2) then
    drawNextLine("Flaps Right channel",FlapsFields[2][5])
    drawNextLine("Flaps Left channel",FlapsFields[3][5])
  end
  -- tail
  if(TailFields[1][5] == 0) then
    drawNextLineNoCh("No rudder")
  elseif (TailFields[1][5] == 1) then
    drawNextLine("Rudder channel",TailFields[2][5])
  end
  local result = runFieldsPage(event)
  if(fields[1][5] == 1 and edit == false) then
    selectPage(1)
  end
  return result
end

local function addMix(channel, input, name, weight, index)
  local mix = { source=input, name=name }
  if weight ~= nil then
    mix.weight = weight
  end
  if index == nil then
    index = 0
  end
  model.insertMix(channel, index, mix)
end

local function createModel(event)
  lcd.clear()
  lcd.drawBitmap(BackgroundImg, 0, 0)
  lcd.drawBitmap(ImgSummary, 300, 60)
  model.defaultInputs()
  model.deleteMixes()

  -- motor
  if(MotorFields[1][5] == 1) then
    addMix(MotorFields[2][5], MIXSRC_FIRST_INPUT+defaultChannel(2), "Motor")
  end

  -- Ailerons / Ele
    addMix(AilFields[1][5], MIXSRC_FIRST_INPUT+defaultChannel(1), "D-EleL", 50)
    addMix(AilFields[1][5], MIXSRC_FIRST_INPUT+defaultChannel(3), "D-AilL", 50, 1)
    addMix(AilFields[2][5], MIXSRC_FIRST_INPUT+defaultChannel(1), "D-EleR", 50)
    addMix(AilFields[2][5], MIXSRC_FIRST_INPUT+defaultChannel(3), "D-AilR", -50, 1)
  
  -- Flaps
  if(FlapsFields[1][5] == 1) then
    addMix(FlapsFields[2][5], MIXSRC_SA, "Flaps")
  elseif (FlapsFields[1][5] == 2) then
    addMix(FlapsFields[2][5], MIXSRC_SA, "FlapsR")
    addMix(FlapsFields[3][5], MIXSRC_SA, "FlapsL")
  end
  -- Rudder
  if (TailFields[1][5] == 1) then
    addMix(TailFields[2][5], MIXSRC_FIRST_INPUT+defaultChannel(0), "Rudder")
  end
  lcd.drawText(70, 90, "Model successfully created !", TEXT_COLOR)
  lcd.drawText(100, 130, "Press RTN to exit", TEXT_COLOR)
  return 2
end

-- Init
local function init()
  current, edit = 1, false
  pages = {
    runMotorConfig,
    runAilConfig,
    runFlapsConfig,
    runRudderConfig,
    runConfigSummary,
    createModel,
  }
end

-- Main
local function run(event)
  if event == nil then
    error("Cannot be run as a model script!")
    return 2
  elseif event == EVT_VIRTUAL_NEXT_PAGE and page < #pages-1 then
    selectPage(1)
  elseif event == EVT_VIRTUAL_PREV_PAGE and page > 1 then
    killEvents(event);
    selectPage(-1)
  end

  local result = pages[page](event)
  return result
end

return { init=init, run=run }
