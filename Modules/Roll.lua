local Enhance = _G.Enhance
local Module = ModuleFactory.CreateModule(
   'roll',
   'Roll',
   {
      'AceConsole-3.0',
      'AceEvent-3.0',
      'AceTimer-3.0',
   }
)

Module:RegisterOptions({
   start = {
      name = "Start",
      desc = "Starts the roll tracker",
      type = "execute",
      guiHidden = true,
      func = function(args, arg1, arg2)
         if not Enhance.db.profile.modules.roll.enabled then
            Module:Print('Please enable the rolls module to use it.')
            return
         end

         if Module.isSessionActive then
            Module:Print('Roll already started.')
            return
         end

         local item = args.input:gsub('roll start ', '')

         Module:StartRoll(item)
      end
   },

   stop = {
      name = "Stop",
      desc = "Stops the roll tracker",
      type = "execute",
      guiHidden = true,
      func = function()
         if not Module.isSessionActive then
            Module:Print('No roll is in progress.')
            return
         end

         Module:StopRoll()
      end
   },

   mode = {
      name = 'Mode',
      desc = 'When set to `Automatic`, the roll closes after the configured amount of seconds. When set to `Manual`, the roll can only be stopped manually.',
      type = 'select',
      values = {
         AUTO = 'Automatic',
         MANUAL = 'Manual',
      },
      set = function(_, value)
         Module:SetOption('mode', value)
      end,
      get = function(_)
         return Module:GetOption('mode')
      end
   },

   sessionDuration = {
      name = 'Roll Duration',
      desc = '|cffcccccc(seconds)|r - Determines, after how many seconds a roll session stopped, when `Automatic` mode is used.',
      type = 'range',
      min = 5,
      max = 60,
      step = 5,
      set = function(_, value)
         Module:SetOption('sessionDuration', value)
      end,
      get = function(_)
         return Module:GetOption('sessionDuration')
      end,
   },

   channel = {
      name = 'Channel',
      desc = 'The channel is used to post chat messages for rolling on items',
      type = 'select',
      values = {
         SAY = 'Say',
         YELL = 'Yell',
         PARTY = 'Party',
         RAID = 'Raid',
      },
      set = function(_, value)
         Module:SetOption('channel', value)
      end,
      get = function(_)
         return Module:GetOption('channel')
      end,
   },
}, {
   mode = 'AUTO',
   channel = 'PARTY',
   sessionDuration = 5,
})

Module.isSessionActive = false
Module.rolls = {}

--- Evaluates the rolls for main- and off-spec and prints them them to chat.
function Module:ProcessResults()
   local finalResult = {
      winner = nil,
      category = 'MS',
      roll = 0,
   }

   local mainSpecResults = {
      winner = nil,
      highestRoll = 0,
      ties = {},
   }

   local offSpecResults = {
      winner = nil,
      highestRoll = 0,
   }

   for name, roll in pairs(self.rolls) do
      local value = tonumber(roll.value)
      local min = tonumber(roll.min)
      local max = tonumber(roll.max)
      local result = nil

      if min ~= 1 then
         result = nil
      elseif max == 100 then
         result = mainSpecResults
      elseif max == 99 then
         result = offSpecResults
      end

      if result ~= nil and value > result.highestRoll then
         result.highestRoll = value
         result.winner = name
         result.ties = {}
      elseif value == result.highestRoll then
         result.ties = {
            result.winner,
            name,
         }

         result.winner = ''
      end
   end

   if mainSpecResults.winner ~= nil then
      finalResult = {
         winner = mainSpecResults.winner,
         category = 'MS',
         roll = mainSpecResults.highestRoll,
      }
   elseif offSpecResults.winner ~= nil then
      finalResult = {
         winner = offSpecResults.winner,
         category = 'OS',
         roll = offSpecResults.highestRoll,
      }
   end

   if finalResult.winner ~= nil then
      SendChatMessage(
         string.format(
            'Congratulations to %s on winning the item for %s with a %d!',
            finalResult.winner,
            finalResult.category,
            finalResult.roll
         ),
         self:GetOption('channel')
      )
   else
      SendChatMessage(
         'No rolls detected.',
         self:GetOption('channel')
      )
   end

   self.rolls = {}
   self.isSessionActive = false
end

--- Validates a single roll and adds it to the list of rolls.
-- @param name string: Name of the rolling character
-- @param value number: Result of the dice roll
-- @param min number: Lower boundary of the roll
-- @param max number: Upper boundary of the roll
function Module:ProcessRoll(name, value, min, max)
   if self.rolls[name] then
      self:Printf('Duplicate roll from %s.', name)
   else
      self.rolls[name] = {
         value = value,
         min = min,
         max = max,
      };
   end
end

--- Parses the specified message for a roll.
-- This is an event handler for the `CHAT_MSG_SYSTEM` event.
function Module:WatchRolls(event, message)
   local name, value, min, max = message:match("(%S+) rolls (%d+) %((%d+)%-(%d+)%)")
   if not name then
      return
   end

   self:ProcessRoll(name, value, min, max)
end

function Module:HandleCountdownTick()
   if self.count <= 0 then
      self:StopCountdown()
   end

   if (self.count <= 3 and self.count > 0) then
      SendChatMessage(self.count, self:GetOption('channel'))
   end

   self.count = self.count - 1
end

function Module:StartCountdown(seconds)
   self.count = seconds
   self.timer = self:ScheduleRepeatingTimer("HandleCountdownTick", 1)
end

function Module:StopCountdown(force)
   self:CancelTimer(self.timer)

   if not force then
      self:ProcessResults();
   end
end

--- Starts a rolling session.
-- Start and additional rules of the rolling are also announced via chat.
function Module:StartRoll(item)
   self.isSessionActive = true
   self.item = item or '?'

   self:RegisterEvent("CHAT_MSG_SYSTEM", "WatchRolls")

   if self:GetOption('mode') == 'AUTO' then
      self:StartCountdown(self:GetOption('sessionDuration'))
   end

   SendChatMessage(
      "Roll started for item:",
      self:GetOption('channel')
   )

   SendChatMessage(
      item,
      self:GetOption('channel')
   )

   SendChatMessage(
      "(MS = 100; OS = 99)",
      self:GetOption('channel')
   )
end

--- Stops an active roll session.
function Module:StopRoll()
   self.isSessionActive = false
   self:UnregisterEvent("CHAT_MSG_SYSTEM")
   self:StopCountdown(true)

   if (self:GetOption('mode') == 'MANUAL') then
      self:ProcessResults()
   end
end

function Module:Initialize()
   if not self:IsEnabled() or self.isInitialized then
      return
   end

   self.isInitialized = true

   self:Print('Module initialized.')
end

function Module:Destroy()
   self.isInitialized = false

   self:Print('Module destroyed.')
end
