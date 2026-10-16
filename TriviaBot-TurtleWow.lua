--[[
--
-- TriviaBot-TurtleWow Version 1.0
-- Author: CloudNine_Ex
-- Turtle WoW 1.18.1 enhancements and maintenance by CloudNine_Ex
-- Maintained by LizzardBerry
-- Based on work created by Roadblock of Nostalrius, by Guri of Trollbane and by Psy on Frostwolf
--
--]]

-- Global Variables

-- Declared colour codes for console messages
local RED     = "|cffff0000";
local MAGENTA = "|cffff00ff";
local WHITE   = "|cffffffff";

TRIVIA_ENABLED = false;
TRIVIA_LOADED = false;

TRIVIA_QUESTION_TIMEOUT = 45;  --45 Seconds to Answer Correctly
TRIVIA_QUESTION_TIMEWARN = 25;  --20 Second warning.

TRIVIA_VERSION = "2.0.0-alpha23" -- Version number

NEW_TRIVIA_CHANNEL = nil; -- For changing channels

TRIVIA_ACTIVE_QUESTION = 0; -- The currently active question
TRIVIA_QUESTION_ORDER = {}; -- An array to store in which order the questions will be asked
TRIVIA_SCORE_REPORT = 5; -- How often the score is reported
TRIVIA_QUESTION_STARTTIME = 0; -- When the question was started
TRIVIA_TIME_RECORD = { ["time"] = TRIVIA_QUESTION_TIMEOUT + 1, ["holder"] = "noone" }; -- Fastest correct answer this session
TRIVIA_SLOW_RECORD = { ["time"] = 0, ["holder"] = "noone" }; -- Slowest correct answer this session
TRIVIA_QUESTION_ANSWERED = {}; -- Players who already scored on the current question
TRIVIA_QUESTION_CORRECT_COUNT = 0; -- Classic mode: 0 or 1 correct answer per question
TRIVIA_MANUAL_QUESTION_INDEX = nil; -- Question explicitly selected in the UI
TRIVIA_UI_PAGE = 1;
TRIVIA_UI_SELECTED_QUESTION = nil;
TRIVIA_UI_SCORE_PAGE = 1;
TRIVIA_UI_BROADCAST_CHANNEL = "SAY";
TRIVIA_BETTING_ENABLED = false;
TRIVIA_BETS = {};
TRIVIA_BET_POT = 0;
TRIVIA_BET_OPEN_TIME = 0;
TRIVIA_BET_WINDOW_SECONDS = 30;
TRIVIA_QUIZ_LENGTH = 10; -- Planned quiz length: 5, 10, or 20 questions
TRIVIA_TIE_PLAYERS = nil;
TRIVIA_TIE_MODE = false;
TRIVIA_QUESTIONS_ASKED = 0;
TRIVIA_BET_MULTIPLIER = 1.0;


TRIVIA_SCORES = {}; -- The scores table
TRIVIA_SCHEDULE = {}; -- The array used for scheduling events

INVALID_COMMAND = RED .. "Invalid Command Entered. " .. WHITE .. "Try '/trivia help'";

TRIVIA_UPDATEINTERVAL = 0.5; -- How often the OnUpdate code will run (in seconds)

-- Load Function
function Trivia_OnLoad()
	-- Register Events
	this:RegisterEvent("CHAT_MSG_CHANNEL");    
	this:RegisterEvent("CHAT_MSG_RAID");		
	this:RegisterEvent("CHAT_MSG_SAY");
    this:RegisterEvent("CHAT_MSG_YELL");		
	this:RegisterEvent("CHAT_MSG_PARTY");		
	this:RegisterEvent("CHAT_MSG_GUILD");
	this:RegisterEvent("ADDON_LOADED");

    --Register Slash Command
  SLASH_TRIVIA1 = "/trivia";
  SlashCmdList["TRIVIA"] = Trivia_Command;


end

function Trivia_OnUpdate(elapsed)
	-- OnUpdate
	this.TimeSinceLastUpdate = this.TimeSinceLastUpdate + elapsed; 	

	if (this.TimeSinceLastUpdate > TRIVIA_UPDATEINTERVAL) then
		Trivia_DoSchedule();
		this.TimeSinceLastUpdate = 0;
	end
end


-- Question bank helpers. Keep the original parallel-array format for Lua 5.0 compatibility.
local function Trivia_ResetActiveQuestionBank()
    TRIVIA_QUESTIONS = {};
    TRIVIA_ANSWERS1 = {};
    TRIVIA_ANSWERS2 = {};
    TRIVIA_ANSWERS3 = {};
    TRIVIA_ANSWERS4 = {};
    TRIVIA_ANSWERS5 = {};
    TRIVIA_ANSWERS6 = {};
    TRIVIA_ANSWERS7 = {};
    TRIVIA_ANSWERS8 = {};
end

-- Lua 5.0 table.getn() is unreliable for question banks with holes in their
-- numeric keys. Count the actual numeric question indices instead, and append
-- only existing questions so sparse translated banks are not truncated at 30.
local function Trivia_GetQuestionIndices(questions)
    local indices = {};
    if (not questions) then return indices; end
    local key;
    for key, value in pairs(questions) do
        if (type(key) == "number" and value ~= nil) then
            table.insert(indices, key);
        end
    end
    table.sort(indices);
    return indices;
end

function Trivia_AppendQuestionBank(questions, a1, a2, a3, a4, a5, a6, a7, a8)
    if (not questions) then return; end
    local indices = Trivia_GetQuestionIndices(questions);
    local n;
    -- Do not use table.getn(TRIVIA_QUESTIONS) as the append cursor: Lua 5.0
    -- may report an unexpected length after earlier sparse-bank operations.
    local target = 1;
    while TRIVIA_QUESTIONS[target] ~= nil do target = target + 1; end
    for n = 1, table.getn(indices) do
        local i = indices[n];
        TRIVIA_QUESTIONS[target] = questions[i];
        if (a1 and a1[i]) then TRIVIA_ANSWERS1[target] = a1[i]; end
        if (a2 and a2[i]) then TRIVIA_ANSWERS2[target] = a2[i]; end
        if (a3 and a3[i]) then TRIVIA_ANSWERS3[target] = a3[i]; end
        if (a4 and a4[i]) then TRIVIA_ANSWERS4[target] = a4[i]; end
        if (a5 and a5[i]) then TRIVIA_ANSWERS5[target] = a5[i]; end
        if (a6 and a6[i]) then TRIVIA_ANSWERS6[target] = a6[i]; end
        if (a7 and a7[i]) then TRIVIA_ANSWERS7[target] = a7[i]; end
        if (a8 and a8[i]) then TRIVIA_ANSWERS8[target] = a8[i]; end
        target = target + 1;
    end
end

function Trivia_LoadQuestionList(listName)
    -- The original French translations are part of the Core.
    -- Optional extensions may add extra French and English questions.
    local hasExtraEN = (WOWOPTEN_TRIVIA_QUESTIONS ~= nil);
    local hasExtraFR = (WOWOPTFR_TRIVIA_QUESTIONS ~= nil);

    if (listName == "wow") then listName = "wowen"; end
    Trivia_ResetActiveQuestionBank();

    if (listName == "normal") then
        Trivia_AppendQuestionBank(NORMAL_TRIVIA_QUESTIONS, NORMAL_TRIVIA_ANSWERS1, NORMAL_TRIVIA_ANSWERS2, NORMAL_TRIVIA_ANSWERS3, NORMAL_TRIVIA_ANSWERS4, NORMAL_TRIVIA_ANSWERS5, NORMAL_TRIVIA_ANSWERS6, NORMAL_TRIVIA_ANSWERS7, NORMAL_TRIVIA_ANSWERS8);
    elseif (listName == "geography" or listName == "geog") then
        listName = "geography";
        Trivia_AppendQuestionBank(GEOGRAPHY_TRIVIA_QUESTIONS, GEOGRAPHY_TRIVIA_ANSWERS1, GEOGRAPHY_TRIVIA_ANSWERS2, GEOGRAPHY_TRIVIA_ANSWERS3, GEOGRAPHY_TRIVIA_ANSWERS4, GEOGRAPHY_TRIVIA_ANSWERS5, GEOGRAPHY_TRIVIA_ANSWERS6, GEOGRAPHY_TRIVIA_ANSWERS7, GEOGRAPHY_TRIVIA_ANSWERS8);
    elseif (listName == "wowfr") then
        listName = "wowfr";
        Trivia_AppendQuestionBank(WOWBASEFR_TRIVIA_QUESTIONS, WOWBASEFR_TRIVIA_ANSWERS1, WOWBASEFR_TRIVIA_ANSWERS2, WOWBASEFR_TRIVIA_ANSWERS3, WOWBASEFR_TRIVIA_ANSWERS4, WOWBASEFR_TRIVIA_ANSWERS5, WOWBASEFR_TRIVIA_ANSWERS6, WOWBASEFR_TRIVIA_ANSWERS7, WOWBASEFR_TRIVIA_ANSWERS8);
        if (hasExtraFR) then
            Trivia_AppendQuestionBank(WOWOPTFR_TRIVIA_QUESTIONS, WOWOPTFR_TRIVIA_ANSWERS1, WOWOPTFR_TRIVIA_ANSWERS2, WOWOPTFR_TRIVIA_ANSWERS3, WOWOPTFR_TRIVIA_ANSWERS4, WOWOPTFR_TRIVIA_ANSWERS5, WOWOPTFR_TRIVIA_ANSWERS6, WOWOPTFR_TRIVIA_ANSWERS7, WOWOPTFR_TRIVIA_ANSWERS8);
        end
    elseif (listName == "mixed") then
        Trivia_AppendQuestionBank(WOW_TRIVIA_QUESTIONS, WOW_TRIVIA_ANSWERS1, WOW_TRIVIA_ANSWERS2, WOW_TRIVIA_ANSWERS3, WOW_TRIVIA_ANSWERS4, WOW_TRIVIA_ANSWERS5, WOW_TRIVIA_ANSWERS6, WOW_TRIVIA_ANSWERS7, WOW_TRIVIA_ANSWERS8);
        if (hasExtraEN) then
            Trivia_AppendQuestionBank(WOWOPTEN_TRIVIA_QUESTIONS, WOWOPTEN_TRIVIA_ANSWERS1, WOWOPTEN_TRIVIA_ANSWERS2, WOWOPTEN_TRIVIA_ANSWERS3, WOWOPTEN_TRIVIA_ANSWERS4, WOWOPTEN_TRIVIA_ANSWERS5, WOWOPTEN_TRIVIA_ANSWERS6, WOWOPTEN_TRIVIA_ANSWERS7, WOWOPTEN_TRIVIA_ANSWERS8);
        end
        Trivia_AppendQuestionBank(WOWBASEFR_TRIVIA_QUESTIONS, WOWBASEFR_TRIVIA_ANSWERS1, WOWBASEFR_TRIVIA_ANSWERS2, WOWBASEFR_TRIVIA_ANSWERS3, WOWBASEFR_TRIVIA_ANSWERS4, WOWBASEFR_TRIVIA_ANSWERS5, WOWBASEFR_TRIVIA_ANSWERS6, WOWBASEFR_TRIVIA_ANSWERS7, WOWBASEFR_TRIVIA_ANSWERS8);
        if (hasExtraFR) then
            Trivia_AppendQuestionBank(WOWOPTFR_TRIVIA_QUESTIONS, WOWOPTFR_TRIVIA_ANSWERS1, WOWOPTFR_TRIVIA_ANSWERS2, WOWOPTFR_TRIVIA_ANSWERS3, WOWOPTFR_TRIVIA_ANSWERS4, WOWOPTFR_TRIVIA_ANSWERS5, WOWOPTFR_TRIVIA_ANSWERS6, WOWOPTFR_TRIVIA_ANSWERS7, WOWOPTFR_TRIVIA_ANSWERS8);
        end
    else -- wowen: original English bank, plus optional English questions if installed.
        listName = "wowen";
        Trivia_AppendQuestionBank(WOW_TRIVIA_QUESTIONS, WOW_TRIVIA_ANSWERS1, WOW_TRIVIA_ANSWERS2, WOW_TRIVIA_ANSWERS3, WOW_TRIVIA_ANSWERS4, WOW_TRIVIA_ANSWERS5, WOW_TRIVIA_ANSWERS6, WOW_TRIVIA_ANSWERS7, WOW_TRIVIA_ANSWERS8);
        if (hasExtraEN) then
            Trivia_AppendQuestionBank(WOWOPTEN_TRIVIA_QUESTIONS, WOWOPTEN_TRIVIA_ANSWERS1, WOWOPTEN_TRIVIA_ANSWERS2, WOWOPTEN_TRIVIA_ANSWERS3, WOWOPTEN_TRIVIA_ANSWERS4, WOWOPTEN_TRIVIA_ANSWERS5, WOWOPTEN_TRIVIA_ANSWERS6, WOWOPTEN_TRIVIA_ANSWERS7, WOWOPTEN_TRIVIA_ANSWERS8);
        end
    end

    TRIVIA_QLIST = listName;
    Trivia_RandomiseOrder();
    return true;
end

-- Slash Command
function Trivia_Command(cmd)

	-- Convert to lower case
	cmd = string.lower(cmd);

	local msgArgs = {};
	local numArgs = 0;

	-- Search for seperators in the string and return
	-- the separated data.
	for value in string.gfind(cmd, "[^ ]+") do
		numArgs = numArgs + 1;
		msgArgs[numArgs] = value;
	end -- end for
	
	-- Get the number of arguments
	--numArgs = table.getn(msgArgs);
    
	if (numArgs == 0) then
		-- Show the help screen
		Trivia_Help();
        
	elseif (numArgs == 1) then
		if (msgArgs[1] == "skip") then
			-- Skip a question
			Trivia_SkipQuestion();
			Trivia_ConsoleMessage("Question skipped");
		elseif (msgArgs[1] == "shuffle") then
			-- Restart and reshuffle the questions
            TRIVIA_ENABLED = false;
			Trivia_UnSchedule("all"); -- Stop the current question
			Trivia_ConsoleMessage("Questions shuffled");
			Trivia_SendMessage("Questions shuffled. Restarting with a new question in 5 seconds");
			Trivia_RandomiseOrder();
			Trivia_Schedule("NEXT_QUESTION", 5); -- Schedule a new one
		elseif (msgArgs[1] == "stop") then
			-- Stop the bot
			Trivia_Stop();
        elseif (msgArgs[1] == "debugbanks") then
            local function Trivia_CountBank(bank)
                local count = 0;
                if (bank) then
                    local k, v;
                    for k, v in pairs(bank) do
                        if (type(k) == "number" and v ~= nil) then count = count + 1; end
                    end
                end
                return count;
            end
            Trivia_ConsoleMessage("Core FR bank: " .. Trivia_CountBank(WOWBASEFR_TRIVIA_QUESTIONS));
            Trivia_ConsoleMessage("Optional FR bank: " .. Trivia_CountBank(WOWOPTFR_TRIVIA_QUESTIONS));
            Trivia_ConsoleMessage("Core EN bank: " .. Trivia_CountBank(WOW_TRIVIA_QUESTIONS));
            Trivia_ConsoleMessage("Optional EN bank: " .. Trivia_CountBank(WOWOPTEN_TRIVIA_QUESTIONS));
            Trivia_ConsoleMessage("Active bank: " .. Trivia_CountBank(TRIVIA_QUESTIONS));
		elseif (msgArgs[1] == "qlist") then
            Trivia_ConsoleMessage("Question lists: normal, wowen, wowfr, mixed, geography. French base questions are included in the Core.");
            Trivia_ConsoleMessage("Use /trivia qlist <name> while the bot is stopped.");
		elseif (msgArgs[1] == "clear") then
			-- Clear the scores
			TRIVIA_SCORES = {};
            Trivia_UIRefresh();
			TRIVIA_TIME_RECORD = {["time"] = TRIVIA_QUESTION_TIMEOUT + 1, ["holder"] = "noone"};
            TRIVIA_SLOW_RECORD = {["time"] = 0, ["holder"] = "noone"};
			Trivia_ConsoleMessage("Trivia: Scores cleared.");
			Trivia_SendMessage("Scores cleared.");
		elseif (msgArgs[1] == "start") then
            if (TRIVIA_ENABLED) then
                Trivia_ConsoleMessage("Trivia is already running.");
            else
                -- Start a fresh speed-record session without deleting the score table.
                TRIVIA_TIME_RECORD = { ["time"] = TRIVIA_QUESTION_TIMEOUT + 1, ["holder"] = "noone" };
                TRIVIA_SLOW_RECORD = { ["time"] = 0, ["holder"] = "noone" };
                TRIVIA_ACTIVE_QUESTION = 0;
                TRIVIA_QUESTIONS_ASKED = 0;
                TRIVIA_BET_MULTIPLIER = 1.0;
                TRIVIA_SCORE_REPORT = 5;
                Trivia_UnSchedule("all");
                Trivia_ConsoleMessage("Trivia started in channel " .. TRIVIA_CHANNEL);
                Trivia_ConsoleMessage("First question coming up!");
                Trivia_Schedule("NEXT_QUESTION", 2);
            end
        elseif (msgArgs[1] == "ui" or msgArgs[1] == "menu") then
            Trivia_ToggleMainFrame();
        elseif (msgArgs[1] == "board" or msgArgs[1] == "scores") then
            Trivia_ToggleScoreFrame();
        elseif (msgArgs[1] == "help") then
			Trivia_Help();
		elseif (msgArgs[1] == "channel") then
			-- Produce an error
			Trivia_ConsoleMessage("Usage: /trivia channel <channel name>");
			Trivia_ConsoleMessage("Try SAY|PARTY|RAID|GUILD|<custom channel>");
		else
			Trivia_ErrorMessage("Invalid Command - Try '/trivia help'");
		end
    elseif (numArgs == 3) then
        if (msgArgs[1] == "contribution") then
            local player = msgArgs[2];
            local raw = string.lower(msgArgs[3] or "");
            local gold = tonumber(string.match(raw, "^(%d+)%s*g$")) or 0;
            local silver = tonumber(string.match(raw, "^(%d+)%s*s$")) or 0;
            local amount = gold * 100 + silver;
            if (amount <= 0) then
                Trivia_ConsoleMessage("Usage: /trivia contribution PlayerName 5s (or 1g). This records a direct trade; it does not move money.");
            else
                TRIVIA_CONTRIBUTIONS = TRIVIA_CONTRIBUTIONS or {};
                TRIVIA_CONTRIBUTIONS[player] = (TRIVIA_CONTRIBUTIONS[player] or 0) + amount;
                TRIVIA_BET_POT = (TRIVIA_BET_POT or 0) + amount;
                Trivia_ConsoleMessage("Contribution recorded for " .. player .. ": " .. gold .. "g " .. silver .. "s. Total pot: " .. math.floor(TRIVIA_BET_POT / 100) .. "g " .. math.mod(TRIVIA_BET_POT, 100) .. "s. Keep the trade record until final settlement.");
                Trivia_UIRefreshScores();
            end
        elseif (msgArgs[1] == "tie") then
            TRIVIA_TIE_PLAYERS = { msgArgs[2], msgArgs[3] };
            if (TriviaTieTitle) then TriviaTieTitle:SetText("Tie: " .. msgArgs[2] .. " / " .. msgArgs[3]); end
            if (TriviaTieFrame) then TriviaTieFrame:Show(); end
            Trivia_ConsoleMessage("Tie-break opened for " .. msgArgs[2] .. " and " .. msgArgs[3] .. ". Choose a question, /roll, or split.");
        else
            Trivia_ErrorMessage("Invalid Command - Try '/trivia help'");
        end
    elseif (numArgs == 2) then
        if (msgArgs[1] == "paid") then
            TRIVIA_CONTRIBUTIONS = {};
            TRIVIA_BET_POT = 0;
            Trivia_ConsoleMessage("Ledger cleared after manual payout trades.");
        elseif (msgArgs[1] == "length") then
            local length = tonumber(msgArgs[2]);
            if (TRIVIA_ENABLED) then
                Trivia_ConsoleMessage("Set quiz length before starting the quiz.");
            elseif (length == 5 or length == 10 or length == 20) then
                TRIVIA_QUIZ_LENGTH = length;
                Trivia_ConsoleMessage("Quiz length set to " .. length .. " questions. Suggested contribution: " .. Trivia_GetMinimumBet() .. " silver.");
                Trivia_UIRefreshScores();
            else
                Trivia_ConsoleMessage("Usage: /trivia length 5, /trivia length 10, or /trivia length 20.");
            end
        elseif (msgArgs[1] == "winner") then
            local winner = msgArgs[2];
            if (winner and TRIVIA_TIE_PLAYERS and (winner == TRIVIA_TIE_PLAYERS[1] or winner == TRIVIA_TIE_PLAYERS[2])) then
                TRIVIA_TIE_PLAYERS = nil; TRIVIA_TIE_MODE = false;
                Trivia_SendMessage("Tie-break winner: " .. winner .. ". Please settle the agreed reward manually.");
            else
                Trivia_ConsoleMessage("Winner must be one of the two players in the active tie.");
            end
        elseif (msgArgs[1] == "tie") then
            local rest = string.gsub(cmd, "^tie%s+", "");
            local first, second = string.match(rest, "^(%S+)%s+(%S+)$");
            if (first and second) then
                TRIVIA_TIE_PLAYERS = { first, second };
                if (TriviaTieFrame) then TriviaTieFrame:Show(); end
                Trivia_ConsoleMessage("Tie-break opened for " .. first .. " and " .. second .. ". Choose a question, /roll, or split.");
            else
                Trivia_ConsoleMessage("Usage: /trivia tie PlayerOne PlayerTwo (names without spaces).");
            end
        elseif (msgArgs[1] == "channel") then
			-- Leave the old channel first
			if (GetChannelName(TRIVIA_CHANNEL) > 0) then
				LeaveChannelByName(TRIVIA_CHANNEL);
			end
			
			-- Set the new channel type
			if (msgArgs[2] == "guild") then
				TRIVIA_CHANNEL = "GUILD";
				Trivia_ConsoleMessage("Channel set to: "..TRIVIA_CHANNEL);
			elseif (msgArgs[2] == "say") then
				TRIVIA_CHANNEL = "SAY";
				Trivia_ConsoleMessage("Channel set to: "..TRIVIA_CHANNEL);
			elseif (msgArgs[2] == "party") then
				TRIVIA_CHANNEL = "PARTY";
				Trivia_ConsoleMessage("Channel set to: "..TRIVIA_CHANNEL);
			elseif (msgArgs[2] == "raid") then
				TRIVIA_CHANNEL = "RAID";
				Trivia_ConsoleMessage("Channel set to: "..TRIVIA_CHANNEL);
			else
				-- Joining a new private channel
				NEW_TRIVIA_CHANNEL = msgArgs[2];
				Trivia_ChangeChannel();
			end
				
		elseif (msgArgs[1] == "qlist") then
            if (not TRIVIA_ENABLED) then
                local requested = msgArgs[2];
                if (requested == "wow") then requested = "wowen"; end
                if (requested == "normal" or requested == "wowen" or requested == "wowfr" or requested == "mixed" or requested == "geography" or requested == "geog") then
                    Trivia_LoadQuestionList(requested);
                    Trivia_ConsoleMessage("Question set selected: " .. TRIVIA_QLIST .. " (" .. table.getn(TRIVIA_QUESTIONS) .. " questions)");
                else
                    Trivia_ConsoleMessage("Unknown question set. Use /trivia qlist for options.");
                end
            else
                Trivia_ConsoleMessage("Stop the trivia bot first!");
            end
		else
			Trivia_ErrorMessage("Invalid Command - Try '/trivia help'");
		end
	else
		Trivia_ErrorMessage("Invalid Command - Try '/trivia help'" );
	end

end
	
-- Return the currently active question, including a question chosen manually in the UI.
function Trivia_GetCurrentQuestionIndex()
    if (TRIVIA_MANUAL_QUESTION_INDEX) then
        return TRIVIA_MANUAL_QUESTION_INDEX;
    end
    return TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION];
end

-- Event Handler
function Trivia_OnEvent(event)

	if (event == "ADDON_LOADED") then
		if (not TRIVIA_LOADED) then
			--Start in the 'off' state
			TRIVIA_ENABLED = false;
			
			-- Send a message
			Trivia_ConsoleMessage("Version" .. TRIVIA_VERSION .. " loaded.");
			
			-- Load the saved variables
			if (not TRIVIA_CHANNEL) then
				TRIVIA_CHANNEL = "triviatest"; -- The default used (private chan, guild, say, party etc)
			end
			
			if (not TRIVIA_QLIST) then
				TRIVIA_QLIST = "wow"; -- Default question list
			end
			
			-- Auto-Join the channel (probably annoying)
			--if (GetChannelName(TRIVIA_CHANNEL) <= 0) then
				--NEW_TRIVIA_CHANNEL = TRIVIA_CHANNEL;
				--Trivia_ChangeChannel();
			--end
		
            -- Load the saved question list; old "wow" saves map to the expanded English bank.
            if (TRIVIA_QLIST == "wow") then TRIVIA_QLIST = "wowen"; end
            if (not Trivia_LoadQuestionList(TRIVIA_QLIST or "wowen")) then
                TRIVIA_QLIST = "wowen";
                Trivia_LoadQuestionList("wowen");
            end
            TRIVIA_TIME_RECORD = { ["time"] = TRIVIA_QUESTION_TIMEOUT + 1, ["holder"] = "noone" };
            TRIVIA_SLOW_RECORD = { ["time"] = 0, ["holder"] = "noone" };
			
			-- Set loaded state
			TRIVIA_LOADED = true;
            Trivia_CreateInterface();
		end
		
	elseif (event == "CHAT_MSG_CHANNEL") then
		local msg = arg1;
		local player = arg2;
        local channel = nil;
        if (arg9) then channel = string.lower(arg9); end

        if (msg and player and channel) then
            if(channel == TRIVIA_CHANNEL) then
                if (Trivia_BetMessage(player, msg)) then
                    return;
                elseif ( string.lower(msg) == "score" ) then
                    Trivia_WhisperScore(player);
    		    elseif ( TRIVIA_ENABLED ) then
                    Trivia_CheckAnswer(player, msg);
                end
            end
		end
	
	elseif ((event == "CHAT_MSG_SAY" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_PARTY") and TRIVIA_ENABLED) then
		
		-- Something was said, and the bot is on
		local msg = arg1;
		local player = arg2;

        if ((msg and player) ~= nil) then if (not Trivia_BetMessage(player, msg) and TRIVIA_ENABLED) then Trivia_CheckAnswer(player, msg); end end
		
	elseif (event == "RETRY_CHANNEL_CHANGE") then
		Trivia_ChangeChannel();
		
	elseif (event == "NEXT_QUESTION") then
		TRIVIA_ENABLED = true;
		Trivia_AskQuestion();
		
	elseif (event == "QUESTION_TIMEOUT") then
		Trivia_QuestionTimeout();
		
	elseif (event == "QUESTION_WARN") then
		Trivia_SendMessage("20 seconds left!");
		
	elseif (event == "REPORT_SCORERS") then
		Trivia_ReportScores();
		
	elseif (event == "SHOW_ANSWER") then
        local questionIndex = Trivia_GetCurrentQuestionIndex();
        if (questionIndex and TRIVIA_ANSWERS1[questionIndex]) then
            Trivia_SendMessage("The correct answer was: " .. TRIVIA_ANSWERS1[questionIndex]);
        end
	end
	
end

function Trivia_Help()
	
	-- Prints instructions
	Trivia_ConsoleMessage("'/trivia channel [SAY|PARTY|RAID|GUILD|<custom channel>]' - Sets the trivia channel.");
  Trivia_ConsoleMessage("'/trivia start' - Starts the trivia game.");
  Trivia_ConsoleMessage("'/trivia stop' - Stops the current game.");
	Trivia_ConsoleMessage("'/trivia skip' - Skips the current question.");
	Trivia_ConsoleMessage("'/trivia shuffle' - Shuffles the questions (restarts from beginning).");
	Trivia_ConsoleMessage("'/trivia clear' - Clears the scores.");
    Trivia_ConsoleMessage("'/trivia qlist [normal|wow|wowen|wowfr|mixed|geography]' selects questions; wowfr and mixed include the French base bank.");
    Trivia_ConsoleMessage("Classic scoring: only the first correct answer earns a point.");
    Trivia_ConsoleMessage("No !bet command: exchange each player's agreed contribution directly and keep the trade/chat record until settlement.");
    Trivia_ConsoleMessage("Quiz minimums: 5 questions = 1s; 10 = 5s; 20 = 10s. Betting window: 30 seconds per question.");
    Trivia_ConsoleMessage("One winner: 70% winner / 30% organizer. Two-way tie: choose a question, /roll, or split 85% between both winners (organizer keeps 15%).");
    Trivia_ConsoleMessage("Session titles: fastest and slowest correct winning answer.");
	Trivia_ConsoleMessage("'/trivia ui' - Opens the TriviaBot menu and question selector.");
    Trivia_ConsoleMessage("'/trivia length 5|10|20' - Sets quiz length and suggested contribution (1s/5s/10s).");
    Trivia_ConsoleMessage("'/trivia tie PlayerOne PlayerTwo' - Opens tie-break choices.");
    Trivia_ConsoleMessage("'/trivia winner PlayerName' - Records the winner of a /roll tie-break.");
    Trivia_ConsoleMessage("'/trivia board' - Shows or hides the participant leaderboard.");
	Trivia_ConsoleMessage("'/trivia help' shows this information.");
	
end

function Trivia_RandomiseOrder()
	-- Randomise the order of the questions
	TRIVIA_QUESTION_ORDER = {};
	
	-- Initialise the table
	local noOfQuestions = table.getn(TRIVIA_QUESTIONS);
    if (not noOfQuestions or noOfQuestions < 1) then
        TRIVIA_QUESTION_ORDER = {};
        return;
    end
	local n = 1;
	
	while (n <= noOfQuestions) do
		TRIVIA_QUESTION_ORDER[n] = n;
		n = n + 1;
	end
	
	local tmp, random;
	local i;
	local j = 5;
	
	while (j > 0) do
		i = 1;
		-- Swap each element with a random element
		while (i <= noOfQuestions) do
			random = math.random(noOfQuestions);
			tmp = TRIVIA_QUESTION_ORDER[i];
			TRIVIA_QUESTION_ORDER[i] = TRIVIA_QUESTION_ORDER[random]
			TRIVIA_QUESTION_ORDER[random] = tmp;
			i = i + 1;
		end
		
		-- Decrement J
		j = j - 1
	end
	
end

-- Channel changer
function Trivia_ChangeChannel()
	
	-- Check the old channel is really gone

	if (GetChannelName(TRIVIA_CHANNEL) > 0) then
		-- It still exists, try to leave it, and re-try this method.
		LeaveChannelByName(TRIVIA_CHANNEL);
		Trivia_Schedule("RETRY_CHANNEL_CHANGE", 1);
	else
		-- The channel is gone, begin joining a new one
	
		-- Protect global channels
    local protected_channel = {"general","trade","lookingforgroup","guildrecruitment","localdefence","worlddefence"}
    local protected = false
    for _,channel in ipairs(protected_channel) do
      if string.find(string.lower(NEW_TRIVIA_CHANNEL),"^"..channel.."[.]*")~=nil then
        protected = channel
        break
      end
    end
		if protected ~= false then
			-- Announce protected Channel
			Trivia_ErrorMessage("Channel '" .. NEW_TRIVIA_CHANNEL .. "' contains a protected keyword: " .. protected .. ", unable to change channel.");
      Trivia_ErrorMessage("Spamming a global server channel can get you muted or even banned.");
			JoinChannelByName(TRIVIA_CHANNEL);
			NEW_TRIVIA_CHANNEL = TRIVIA_CHANNEL;
			ChatFrame_AddChannel(DEFAULT_CHAT_FRAME, TRIVIA_CHANNEL);
		else
			-- Set and join the channel
			JoinChannelByName(NEW_TRIVIA_CHANNEL);
			ChatFrame_AddChannel(DEFAULT_CHAT_FRAME, NEW_TRIVIA_CHANNEL);

		end
	
		-- Check the channel exists now
		if (GetChannelName(NEW_TRIVIA_CHANNEL) > 0) then
			-- Finalise the Change
			TRIVIA_CHANNEL = NEW_TRIVIA_CHANNEL;
	
			-- Announce the action
			Trivia_ConsoleMessage("Channel set to: "..TRIVIA_CHANNEL);

		else
			-- It doesn't exist yet, re-try
			Trivia_Schedule("RETRY_CHANNEL_CHANGE", 1);
		end
	end

end


-- Asks a question
function Trivia_AskQuestion()
    if (not TRIVIA_TIE_MODE and (TRIVIA_QUESTIONS_ASKED or 0) >= (TRIVIA_QUIZ_LENGTH or 10)) then Trivia_FinishQuiz(); return; end
    TRIVIA_MANUAL_QUESTION_INDEX = nil;
    local questionCount = table.getn(TRIVIA_QUESTIONS);
    if (not questionCount or questionCount < 1) then
        TRIVIA_ENABLED = false;
        Trivia_ConsoleMessage("No questions are loaded for this category.");
        return;
    end

    TRIVIA_ACTIVE_QUESTION = TRIVIA_ACTIVE_QUESTION + 1;
    if (TRIVIA_ACTIVE_QUESTION > questionCount) then
        Trivia_RandomiseOrder();
        TRIVIA_ACTIVE_QUESTION = 1;
        Trivia_ConsoleMessage("Out of questions... Reshuffled and restarted.");
    end

    TRIVIA_QUESTION_CORRECT_COUNT = 0;
    if (not TRIVIA_TIE_MODE) then
        Trivia_ResetBets();
        TRIVIA_QUESTIONS_ASKED = (TRIVIA_QUESTIONS_ASKED or 0) + 1;
    end
    TRIVIA_BET_OPEN_TIME = GetTime();
    TRIVIA_QUESTION_STARTTIME = GetTime();
    TRIVIA_ENABLED = true;
    Trivia_SendMessage("Q: " .. TRIVIA_QUESTIONS[TRIVIA_QUESTION_ORDER[TRIVIA_ACTIVE_QUESTION]]);
    Trivia_UIRefresh();
    Trivia_Schedule("QUESTION_TIMEOUT", TRIVIA_QUESTION_TIMEOUT);
    Trivia_Schedule("QUESTION_WARN", TRIVIA_QUESTION_TIMEWARN);
end

-- Ask a question selected from the in-game question browser.
function Trivia_AskQuestionByIndex(questionIndex)
    if ((TRIVIA_QUESTIONS_ASKED or 0) >= (TRIVIA_QUIZ_LENGTH or 10)) then Trivia_FinishQuiz(); return; end
    if (not questionIndex or not TRIVIA_QUESTIONS or not TRIVIA_QUESTIONS[questionIndex]) then
        Trivia_ConsoleMessage("Select a valid question first.");
        return;
    end
    Trivia_UnSchedule("all");
    if (TRIVIA_ENABLED) then
        Trivia_SendMessage("The current question was replaced by the moderator.");
    end
    TRIVIA_MANUAL_QUESTION_INDEX = questionIndex;
    TRIVIA_QUESTION_CORRECT_COUNT = 0;
    if (not TRIVIA_TIE_MODE) then
        Trivia_ResetBets();
        TRIVIA_QUESTIONS_ASKED = (TRIVIA_QUESTIONS_ASKED or 0) + 1;
    end
    TRIVIA_BET_OPEN_TIME = GetTime();
    TRIVIA_QUESTION_STARTTIME = GetTime();
    TRIVIA_ENABLED = true;
    Trivia_SendMessage("Q: " .. TRIVIA_QUESTIONS[questionIndex]);
    Trivia_Schedule("QUESTION_TIMEOUT", TRIVIA_QUESTION_TIMEOUT);
    Trivia_Schedule("QUESTION_WARN", TRIVIA_QUESTION_TIMEWARN);
    Trivia_UIRefresh();
end

-- Answers the question and prepares the next if no one successfully answered the question
function Trivia_QuestionTimeout()
    if (not TRIVIA_ENABLED) then return; end
    TRIVIA_ENABLED = false;
    Trivia_SendMessage("Time is up! No correct answer was given.");

    if (TRIVIA_SCORE_REPORT == 1) then
        Trivia_Schedule("SHOW_ANSWER", 4);
        Trivia_Schedule("REPORT_SCORERS", 8);
        Trivia_Schedule("NEXT_QUESTION", 16);
        TRIVIA_SCORE_REPORT = 5;
    else
        TRIVIA_SCORE_REPORT = TRIVIA_SCORE_REPORT - 1;
        Trivia_Schedule("SHOW_ANSWER", 4);
        Trivia_Schedule("NEXT_QUESTION", 8);
    end
end

-- Skip a question
function Trivia_SkipQuestion()

	if (TRIVIA_ENABLED == true) then
		Trivia_SendMessage("Question was skipped.");
        TRIVIA_ENABLED = false;
		Trivia_UnSchedule("all");
		
		-- Show the answer anyway (for those that wanted to know)
		Trivia_Schedule("SHOW_ANSWER", 2);
		
		-- Schedule the next question
		Trivia_Schedule("NEXT_QUESTION", 4);
	end
	
end

function Trivia_Stop()
    -- Announce the session awards before stopping.
    if (TRIVIA_TIME_RECORD["holder"] ~= "noone" or TRIVIA_SLOW_RECORD["holder"] ~= "noone") then
        Trivia_ReportSessionTitles();
    end
    Trivia_UnSchedule("all");
    TRIVIA_ENABLED = false;
    TRIVIA_QUESTION_CORRECT_COUNT = 0;
    Trivia_SendMessage("Trivia bot stopped.");
    Trivia_ConsoleMessage("Trivia bot stopped.");
end

local function Trivia_NormalizeAnswer(value)
    if (not value) then return ""; end
    value = string.lower(value);
    value = string.gsub(value, "^%s+", "");
    value = string.gsub(value, "%s+$", "");
    return value;
end


function Trivia_GetMinimumBet()
    if (TRIVIA_QUIZ_LENGTH == 5) then return 1; end
    if (TRIVIA_QUIZ_LENGTH == 10) then return 5; end
    return 10;
end

function Trivia_FinishQuiz()
    TRIVIA_ENABLED = false;
    Trivia_UnSchedule("all");
    Trivia_SendMessage("Quiz finished after " .. (TRIVIA_QUESTIONS_ASKED or 0) .. " questions.");
    Trivia_ReportScores();
    local rows = Trivia_UISortedScores();
    if (table.getn(rows) >= 2 and rows[1].score == rows[2].score) then
        TRIVIA_TIE_PLAYERS = { rows[1].player, rows[2].player };
        if (TriviaTieTitle) then TriviaTieTitle:SetText("Tie: " .. rows[1].player .. " / " .. rows[2].player); end
        if (TriviaTieFrame) then TriviaTieFrame:Show(); end
        Trivia_SendMessage("ÉGALITÉ : " .. rows[1].player .. " et " .. rows[2].player .. " sont ex æquo ! Choisissez : question aléatoire, /roll (le plus haut gagne) ou partage équitable des 85% du pot. Si départage : 70% au gagnant, 30% organisateur. Sinon : 85% partagés, 15% organisateur.");
    end
    Trivia_ConsoleMessage("Quiz complete. Use /trivia start to begin another quiz.");
    Trivia_UIRefresh();
end

-- Manual contribution ledger: record completed trades with /trivia contribution PlayerName 5s (or 1g).
-- No !bet chat command and no automatic transfers. The ledger persists between questions.
function Trivia_ResetBets()
    TRIVIA_BETS = {};
end
function Trivia_BetMessage(player, msg)
    return false; -- legacy !bet intentionally disabled
end
function Trivia_BroadcastBetStatus()
    local minBet = Trivia_GetMinimumBet and Trivia_GetMinimumBet() or 0;
    Trivia_SendMessage("No !bet command. Organizer records direct trades. Minimum for " .. (TRIVIA_QUIZ_LENGTH or 10) .. " questions: " .. minBet .. " silver. Use /trivia contribution PlayerName 5s to log a completed trade.");
    Trivia_SendMessage("Settlement: one winner = 70% winner / 30% organizer. Two-way tie = question, /roll, or split 85% between both winners (15% organizer).");
end
function Trivia_SettleBets(winner, splitTie)
    if not TRIVIA_BET_POT or TRIVIA_BET_POT <= 0 then
        Trivia_ConsoleMessage("No contributions recorded. Use /trivia contribution PlayerName 5s after a direct trade.");
        return;
    end
    local pot = TRIVIA_BET_POT;
    local winnerShare, organizerShare;
    if (splitTie and type(winner) == "table" and winner[1] and winner[2]) then
        winnerShare = math.floor(pot * 0.85);
        organizerShare = pot - winnerShare;
        local each = math.floor(winnerShare / 2);
        Trivia_SendMessage("TIE SETTLEMENT: " .. winner[1] .. " and " .. winner[2] .. " share 85% of the pot (" .. math.floor(each / 100) .. "g " .. math.mod(each, 100) .. "s each); organizer keeps 15%. Trade manually.");
    else
        winnerShare = math.floor(pot * 0.70);
        organizerShare = pot - winnerShare;
        Trivia_SendMessage("SETTLEMENT: " .. tostring(winner) .. " receives 70% of the pot (" .. math.floor(winnerShare / 100) .. "g " .. math.mod(winnerShare, 100) .. "s); organizer keeps 30% (" .. math.floor(organizerShare / 100) .. "g " .. math.mod(organizerShare, 100) .. "s). Trade manually.");
    end
    Trivia_ConsoleMessage("After completing payout trades, use /trivia paid to clear the ledger.");
end

function Trivia_TieChoice(choice)
    if (not TRIVIA_TIE_PLAYERS or not TRIVIA_TIE_PLAYERS[1] or not TRIVIA_TIE_PLAYERS[2]) then
        Trivia_ConsoleMessage("No tie-break is active. Use /trivia tie PlayerOne PlayerTwo."); return;
    end
    local p1, p2 = TRIVIA_TIE_PLAYERS[1], TRIVIA_TIE_PLAYERS[2];
    if (choice == "split") then
        Trivia_SendMessage("Tie resolved: " .. p1 .. " and " .. p2 .. " share the agreed reward. Please settle payment manually.");
        TRIVIA_TIE_PLAYERS = nil;
        if (TriviaTieFrame) then TriviaTieFrame:Hide(); end
    elseif (choice == "roll") then
        Trivia_SendMessage("Tie-break: " .. p1 .. " and " .. p2 .. ", use /roll. The highest roll wins. Please settle the agreed reward manually.");
        Trivia_ConsoleMessage("After /roll, use /trivia winner PlayerName to record the winner. Payment is manual.");
        if (TriviaTieFrame) then TriviaTieFrame:Hide(); end
    elseif (choice == "question") then
        TRIVIA_TIE_MODE = true;
        TRIVIA_ENABLED = false;
        Trivia_UnSchedule("all");
        if (TriviaTieFrame) then TriviaTieFrame:Hide(); end
        Trivia_SendMessage("Tie-break question for " .. p1 .. " and " .. p2 .. "!");
        Trivia_Schedule("NEXT_QUESTION", 1);
    end
end

function Trivia_CheckAnswer(player, msg)
    if (not TRIVIA_ENABLED or not player or not msg or not Trivia_GetCurrentQuestionIndex()) then
        return;
    end

    local questionIndex = Trivia_GetCurrentQuestionIndex();
    local submitted = Trivia_NormalizeAnswer(msg);
    local answers = {
        TRIVIA_ANSWERS1[questionIndex], TRIVIA_ANSWERS2[questionIndex],
        TRIVIA_ANSWERS3[questionIndex], TRIVIA_ANSWERS4[questionIndex],
        TRIVIA_ANSWERS5[questionIndex], TRIVIA_ANSWERS6[questionIndex],
        TRIVIA_ANSWERS7[questionIndex], TRIVIA_ANSWERS8[questionIndex]
    };
    local correct = false;
    local i;
    for i = 1, 8 do
        if (answers[i] and submitted == Trivia_NormalizeAnswer(answers[i])) then
            correct = true;
            break;
        end
    end
    if (not correct) then return; end
    if (TRIVIA_TIE_MODE and TRIVIA_TIE_PLAYERS and player ~= TRIVIA_TIE_PLAYERS[1] and player ~= TRIVIA_TIE_PLAYERS[2]) then return; end

    -- Classic scoring: the first correct answer closes the question and earns the point.
    TRIVIA_ENABLED = false;
    Trivia_UnSchedule("all");
    local timeTaken = GetTime() - TRIVIA_QUESTION_STARTTIME;
    timeTaken = math.floor(timeTaken * 100 + 0.5) / 100;
    TRIVIA_QUESTION_CORRECT_COUNT = 1;

    TRIVIA_SCORES[player] = (TRIVIA_SCORES[player] or 0) + 1;
    if (TRIVIA_TIE_MODE) then
        TRIVIA_TIE_MODE = false; TRIVIA_TIE_PLAYERS = nil;
    end
    Trivia_UIRefresh();
    Trivia_SendMessage("Correct answer, " .. player .. "! (+1 point, " .. timeTaken .. " sec)");

    if (timeTaken < TRIVIA_TIME_RECORD["time"]) then
        TRIVIA_TIME_RECORD["holder"] = player;
        TRIVIA_TIME_RECORD["time"] = timeTaken;
        Trivia_SendMessage("SESSION FASTEST RECORD! " .. player .. " answered in " .. timeTaken .. " sec.");
    end
    if (timeTaken > TRIVIA_SLOW_RECORD["time"]) then
        TRIVIA_SLOW_RECORD["holder"] = player;
        TRIVIA_SLOW_RECORD["time"] = timeTaken;
    end
    Trivia_UIRefreshScores();

    -- Preserve the original pacing: score report every five questions, then continue.
    if (TRIVIA_SCORE_REPORT == 1) then
        Trivia_Schedule("REPORT_SCORERS", 4);
        Trivia_Schedule("NEXT_QUESTION", 14);
        TRIVIA_SCORE_REPORT = 5;
    else
        TRIVIA_SCORE_REPORT = TRIVIA_SCORE_REPORT - 1;
        Trivia_Schedule("NEXT_QUESTION", 8);
    end
end

function Trivia_ReportSessionTitles()
    if (TRIVIA_TIME_RECORD["holder"] ~= "noone") then
        Trivia_SendMessage("Session title - Swift Mind (fastest): " .. TRIVIA_TIME_RECORD["holder"] .. " (" .. TRIVIA_TIME_RECORD["time"] .. " sec)");
    end
    if (TRIVIA_SLOW_RECORD["holder"] ~= "noone") then
        Trivia_SendMessage("Session title - Deep Thinker (slowest winning answer): " .. TRIVIA_SLOW_RECORD["holder"] .. " (" .. TRIVIA_SLOW_RECORD["time"] .. " sec)");
    end
end

function Trivia_ReportScores()
	
	-- Sort the table
	local TRIVIA_SORTED = {};
	
	for player, score in TRIVIA_SCORES do
		-- Add them to the sorting table
		table.insert(TRIVIA_SORTED, {["player"] = player, ["score"] = score});
	end
	
	table.sort(TRIVIA_SORTED, function(v1, v2)
		return v1["score"] > v2["score"];
		end);

	Trivia_SendMessage("Standing so far:");
		-- Report the top 3 scorers
	for id, record in TRIVIA_SORTED do
		if (id <= 3) then
			-- Report the top 3
			
			-- Ensure correct grammar.
			local ess = "s";
			if (record["score"] == 1) then
				ess = "";
			end

			Trivia_SendMessage(id .. "]: " .. record["player"] .. " (" .. record["score"] .." point" .. ess .. ")");
			
		end
	end
	
    -- Session-wide temporary titles, based on records from the whole session.
    Trivia_ReportSessionTitles();
	
	
end


function Trivia_WhisperScore(player)
    local score = TRIVIA_SCORES[player] or 0;
    SendChatMessage("Your Trivia score is " .. score .. " point(s).", "WHISPER", nil, player);
end

function Trivia_ClearTells(player)
    if (TRIVIA_TELLS) then TRIVIA_TELLS[player] = nil; end
end


function Trivia_DoSchedule()
    -- Remove an event before dispatching it. Event handlers may schedule new events.
    local i = 1;
    local now = GetTime();
    while (i <= table.getn(TRIVIA_SCHEDULE)) do
        local scheduled = TRIVIA_SCHEDULE[i];
        if (scheduled["time"] <= now) then
            table.remove(TRIVIA_SCHEDULE, i);
            Trivia_OnEvent(scheduled["name"]);
        else
            i = i + 1;
        end
    end
end

function Trivia_Schedule(name, delay)
    local scheduled = { ["name"] = name, ["time"] = GetTime() + delay };
    table.insert(TRIVIA_SCHEDULE, scheduled);
end

function Trivia_UnSchedule(id)
		-- Unschedule an event
		
		if (id == "all") then
			TRIVIA_SCHEDULE = {};
		else
			table.remove(TRIVIA_SCHEDULE, id);
		end
end


function Trivia_SendMessage(msg)
	-- Send a message to the trivia channel
	
	-- Append the trivia tag to each message 
	msg = "[TurtleTrivia]: " .. msg;
	
	-- Send the message to the right channel.
	if (TRIVIA_CHANNEL == "GUILD") then
		SendChatMessage(msg, "GUILD");
	elseif (TRIVIA_CHANNEL == "SAY") then
		SendChatMessage(msg, "SAY");
	elseif (TRIVIA_CHANNEL == "PARTY") then
		SendChatMessage(msg, "PARTY");
	elseif (TRIVIA_CHANNEL == "RAID") then
		SendChatMessage(msg, "RAID");
	elseif (TRIVIA_CHANNEL ~= nil) then
	
		-- Check the channel exists, and send
		id = GetChannelName(TRIVIA_CHANNEL);
		
		if (id > 0) then
			SendChatMessage(msg, "CHANNEL", nil, id);
		else
			-- Channel send error, stop the current game
			Trivia_ErrorMessage("Unable to send to channel.");
			Trivia_ErrorMessage("Reset channel with '/trivia channel'");
			Trivia_ErrorMessage("Current Trivia game stopped.");
			Trivia_UnSchedule("all");
			TRIVIA_ENABLED = false;
		end

	end
	
end

function Trivia_ConsoleMessage(msg)
	-- Check the default frame exists
	if (DEFAULT_CHAT_FRAME) then
		-- Format the message
		msg = MAGENTA .. "Trivia: " .. WHITE .. msg;
		DEFAULT_CHAT_FRAME:AddMessage(msg);
	end
end

function Trivia_ErrorMessage(msg)
	-- Check the default frame exists
	if (DEFAULT_CHAT_FRAME) then
		-- Format the message
		msg = MAGENTA .. "Trivia: " .. RED .. "ERROR! - " .. WHITE .. msg;
		DEFAULT_CHAT_FRAME:AddMessage(msg);
	end
end


-- Lightweight Vanilla-style interface: uses Blizzard's classic dialog and button templates.
local function Trivia_UIButton(parent, name, text, width, height, x, y, callback)
    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate");
    button:SetWidth(width); button:SetHeight(height); button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y);
    button:SetText(text);
    button:SetScript("OnClick", callback);
    return button;
end


local TRIVIA_UI_BROADCAST_CHANNELS = {
    { label = "Say", type = "SAY" },
    { label = "Yell", type = "YELL" },
    { label = "Party", type = "PARTY" },
    { label = "Raid", type = "RAID" },
    { label = "Guild", type = "GUILD" }
};

function Trivia_UIBroadcastChannelLabel()
    local i, entry;
    for i, entry in ipairs(TRIVIA_UI_BROADCAST_CHANNELS) do
        if (entry.type == TRIVIA_UI_BROADCAST_CHANNEL) then return entry.label; end
    end
    return "Say";
end

function Trivia_UICycleBroadcastChannel()
    local i, entry;
    for i, entry in ipairs(TRIVIA_UI_BROADCAST_CHANNELS) do
        if (entry.type == TRIVIA_UI_BROADCAST_CHANNEL) then
            local nextIndex = i + 1;
            if (nextIndex > table.getn(TRIVIA_UI_BROADCAST_CHANNELS)) then nextIndex = 1; end
            TRIVIA_UI_BROADCAST_CHANNEL = TRIVIA_UI_BROADCAST_CHANNELS[nextIndex].type;
            if (TriviaScoreBroadcastChannelButton) then
                TriviaScoreBroadcastChannelButton:SetText("Channel: " .. Trivia_UIBroadcastChannelLabel());
            end
            return;
        end
    end
    TRIVIA_UI_BROADCAST_CHANNEL = "SAY";
    if (TriviaScoreBroadcastChannelButton) then
        TriviaScoreBroadcastChannelButton:SetText("Channel: " .. Trivia_UIBroadcastChannelLabel());
    end
end

function Trivia_UIPublishLeaderboard()
    local rows = Trivia_UISortedScores();
    if (table.getn(rows) == 0) then
        Trivia_ConsoleMessage("The leaderboard is empty; nothing to publish.");
        return;
    end

    local parts = {};
    local i, row;
    table.insert(parts, "[Trivia] Leaderboard:");
    for i, row in ipairs(rows) do
        local part = i .. ". " .. row.player .. " " .. row.score;
        local candidate = table.concat(parts, " - ") .. " - " .. part;
        if (string.len(candidate) > 245) then break; end
        table.insert(parts, part);
    end
    local message = table.concat(parts, " - ");
    if (string.len(message) > 255) then message = string.sub(message, 1, 252) .. "..."; end

    local channel = TRIVIA_UI_BROADCAST_CHANNEL or "SAY";
    if (channel == "RAID" and (not GetNumRaidMembers or GetNumRaidMembers() == 0)) then
        Trivia_ConsoleMessage("You must be in a raid to publish the leaderboard to Raid.");
        return;
    elseif (channel == "PARTY" and (not GetNumPartyMembers or GetNumPartyMembers() == 0)) then
        Trivia_ConsoleMessage("You must be in a party to publish the leaderboard to Party.");
        return;
    elseif (channel == "GUILD" and (not IsInGuild or not IsInGuild())) then
        Trivia_ConsoleMessage("You must be in a guild to publish the leaderboard to Guild.");
        return;
    end

    SendChatMessage(message, channel);
    Trivia_ConsoleMessage("Leaderboard published to " .. Trivia_UIBroadcastChannelLabel() .. ".");
end

function Trivia_UISortedScores()
    local rows = {};
    local player, score;
    for player, score in pairs(TRIVIA_SCORES or {}) do
        table.insert(rows, { player = player, score = score });
    end
    table.sort(rows, function(a, b)
        if (a.score == b.score) then return string.lower(a.player) < string.lower(b.player); end
        return a.score > b.score;
    end);
    return rows;
end

function Trivia_CreateInterface()
    if (TriviaMainFrame) then return; end

    local main = CreateFrame("Frame", "TriviaMainFrame", UIParent);
    main:SetWidth(520); main:SetHeight(460); main:SetPoint("CENTER", UIParent, "CENTER", 0, 20);
    main:SetFrameStrata("DIALOG"); main:SetMovable(true); main:EnableMouse(true); main:RegisterForDrag("LeftButton");
    main:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } });
    main:SetScript("OnDragStart", function() this:StartMoving(); end);
    main:SetScript("OnDragStop", function() this:StopMovingOrSizing(); end);
    main:SetScript("OnShow", function() Trivia_UIRefresh(); end);
    main:Hide();

    local title = main:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    title:SetPoint("TOP", main, "TOP", 0, -18); title:SetText("TriviaBot |cffd5b35a2.0|r");
    local close = CreateFrame("Button", "TriviaMainCloseButton", main, "UIPanelCloseButton");
    close:SetPoint("TOPRIGHT", main, "TOPRIGHT", -6, -6); close:SetScript("OnClick", function() TriviaMainFrame:Hide(); end);

    local status = main:CreateFontString("TriviaUIStatus", "OVERLAY", "GameFontHighlightSmall");
    status:SetPoint("TOPLEFT", main, "TOPLEFT", 22, -48); status:SetWidth(470); status:SetJustifyH("LEFT");
    status:SetText("Choose a question bank or browse questions below.");

    Trivia_UIButton(main, "TriviaBankEN", "WoW English", 92, 24, 18, -68, function() Trivia_UISelectBank("wowen"); end);
    Trivia_UIButton(main, "TriviaBankFR", "WoW Français", 92, 24, 114, -68, function() Trivia_UISelectBank("wowfr"); end);
    Trivia_UIButton(main, "TriviaBankMixed", "WoW Mix", 78, 24, 210, -68, function() Trivia_UISelectBank("mixed"); end);
    Trivia_UIButton(main, "TriviaBankNormal", "General", 78, 24, 292, -68, function() Trivia_UISelectBank("normal"); end);
    Trivia_UIButton(main, "TriviaBankGeo", "Geography", 92, 24, 374, -68, function() Trivia_UISelectBank("geography"); end);

    local selected = main:CreateFontString("TriviaUISelected", "OVERLAY", "GameFontHighlight");
    selected:SetPoint("TOPLEFT", main, "TOPLEFT", 24, -103); selected:SetWidth(468); selected:SetHeight(30); selected:SetJustifyH("LEFT"); selected:SetJustifyV("TOP");
    selected:SetText("Selected question: none");

    TriviaUIQuestionButtons = {};
    local row;
    for row = 1, 8 do
        local y = -132 - ((row - 1) * 25);
        local b = Trivia_UIButton(main, "TriviaQuestionButton" .. row, row .. ". (empty)", 476, 23, 22, y, function()
            local index = this.triviaQuestionIndex;
            if (index) then
                TRIVIA_UI_SELECTED_QUESTION = index;
                Trivia_UIRefresh();
            end
        end);
        b.triviaQuestionIndex = nil;
        TriviaUIQuestionButtons[row] = b;
    end

    Trivia_UIButton(main, "TriviaQuestionPrev", "<< Previous", 90, 24, 22, -343, function()
        if (TRIVIA_UI_PAGE > 1) then TRIVIA_UI_PAGE = TRIVIA_UI_PAGE - 1; Trivia_UIRefresh(); end
    end);
    local pageText = main:CreateFontString("TriviaUIPage", "OVERLAY", "GameFontHighlightSmall");
    pageText:SetPoint("TOP", main, "TOP", 0, -349); pageText:SetWidth(150); pageText:SetJustifyH("CENTER");
    Trivia_UIButton(main, "TriviaQuestionNext", "Next >>", 90, 24, 410, -343, function()
        local count = table.getn(TRIVIA_QUESTIONS or {});
        local pages = math.max(1, math.ceil(count / 8));
        if (TRIVIA_UI_PAGE < pages) then TRIVIA_UI_PAGE = TRIVIA_UI_PAGE + 1; Trivia_UIRefresh(); end
    end);

    Trivia_UIButton(main, "TriviaAskSelected", "Ask selected question", 150, 28, 22, -380, function()
        if (TRIVIA_UI_SELECTED_QUESTION) then Trivia_AskQuestionByIndex(TRIVIA_UI_SELECTED_QUESTION); else Trivia_ConsoleMessage("Select a question from the list first."); end
    end);
    Trivia_UIButton(main, "TriviaStartButton", "Start + annonce", 112, 28, 166, -380, function()
        if (TRIVIA_ENABLED) then
            Trivia_ConsoleMessage("Le quiz est déjà en cours.");
            return;
        end
        Trivia_Command("start");
        Trivia_SendMessage("TriviaBot : quiz de " .. TRIVIA_QUIZ_LENGTH .. " questions ! Contribution minimale convenue : " .. Trivia_GetMinimumBet() .. " silver par joueur. Échangez directement avec l’organisateur ; aucune commande !bet.");
        Trivia_SendMessage("Mises : 30 secondes au début de chaque question. Gagnant unique : 70% gagnant / 30% organisateur. Égalité à 2 : question de départage, /roll ou partage équitable des 85% (15% organisateur).");
    end);
    Trivia_UIButton(main, "TriviaStopButton", "Stop", 70, 28, 288, -380, function() Trivia_Stop(); Trivia_UIRefresh(); end);
    Trivia_UIButton(main, "TriviaSkipButton", "Skip", 70, 28, 364, -380, function() Trivia_SkipQuestion(); end);
    Trivia_UIButton(main, "TriviaLengthButton", "Quiz: " .. TRIVIA_QUIZ_LENGTH .. " (" .. Trivia_GetMinimumBet() .. "s min.)", 150, 24, 22, -410, function()
        if (TRIVIA_ENABLED) then Trivia_ConsoleMessage("Stop the quiz before changing its length."); return; end
        if (TRIVIA_QUIZ_LENGTH == 5) then TRIVIA_QUIZ_LENGTH = 10 elseif (TRIVIA_QUIZ_LENGTH == 10) then TRIVIA_QUIZ_LENGTH = 20 else TRIVIA_QUIZ_LENGTH = 5 end
        this:SetText("Quiz: " .. TRIVIA_QUIZ_LENGTH .. " (" .. Trivia_GetMinimumBet() .. "s min.)"); Trivia_UIRefreshScores();
        Trivia_ConsoleMessage("Quiz length: " .. TRIVIA_QUIZ_LENGTH .. "; suggested contribution: " .. Trivia_GetMinimumBet() .. " silver. Payment is manual.");
    end);

    Trivia_UIButton(main, "TriviaLeaderboardToggle", "Leaderboard", 120, 24, 180, -410, function()
        if (TriviaScoreFrame and TriviaScoreFrame:IsShown()) then
            TriviaScoreFrame:Hide();
        elseif (TriviaScoreFrame) then
            TriviaScoreFrame:Show();
            Trivia_UIRefreshScores();
        end
    end);


    local tie = CreateFrame("Frame", "TriviaTieFrame", main);
    tie:SetWidth(300); tie:SetHeight(125); tie:SetPoint("CENTER", UIParent, "CENTER", 0, 0); tie:SetFrameStrata("DIALOG"); tie:SetMovable(false); tie:EnableMouse(true);
    tie:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } });
    local tieTitle = tie:CreateFontString("TriviaTieTitle", "OVERLAY", "GameFontNormalLarge"); tieTitle:SetPoint("TOP", tie, "TOP", 0, -15); tieTitle:SetText("Tie-break options"); TriviaTieTitle = tieTitle;
    Trivia_UIButton(tie, "TriviaTieQuestion", "Question", 85, 26, 12, -45, function() Trivia_TieChoice("question"); end);
    Trivia_UIButton(tie, "TriviaTieRoll", "/roll", 75, 26, 108, -45, function() Trivia_TieChoice("roll"); end);
    Trivia_UIButton(tie, "TriviaTieSplit", "Share reward", 95, 26, 190, -45, function() Trivia_TieChoice("split"); end);
    tie:Hide();

    local board = CreateFrame("Frame", "TriviaScoreFrame", TriviaMainFrame);
    board:SetWidth(330); board:SetHeight(390); board:SetPoint("RIGHT", TriviaMainFrame, "LEFT", -8, 0);
    board:SetFrameStrata("DIALOG"); board:SetMovable(false); board:EnableMouse(true);
    board:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } });
    board:SetScript("OnShow", function() Trivia_UIRefreshScores(); end);
    board:Hide();
    local boardTitle = board:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    boardTitle:SetPoint("TOP", board, "TOP", 0, -18); boardTitle:SetText("Trivia Leaderboard");
    local boardClose = CreateFrame("Button", "TriviaScoreCloseButton", board, "UIPanelCloseButton");
    boardClose:SetPoint("TOPRIGHT", board, "TOPRIGHT", -6, -6); boardClose:SetScript("OnClick", function() TriviaScoreFrame:Hide(); end);
    local records = board:CreateFontString("TriviaScoreRecords", "OVERLAY", "GameFontHighlightSmall");
    records:SetPoint("TOPLEFT", board, "TOPLEFT", 22, -48); records:SetWidth(285); records:SetHeight(56); records:SetJustifyH("LEFT"); records:SetJustifyV("TOP");
    TriviaUIScoreRows = {};
    for row = 1, 12 do
        local fs = board:CreateFontString("TriviaScoreRow" .. row, "OVERLAY", "GameFontHighlight");
        fs:SetPoint("TOPLEFT", board, "TOPLEFT", 24, -112 - ((row - 1) * 19)); fs:SetWidth(280); fs:SetJustifyH("LEFT");
        TriviaUIScoreRows[row] = fs;
    end
    Trivia_UIButton(board, "TriviaScorePrev", "<<", 50, 22, 22, -348, function() if (TRIVIA_UI_SCORE_PAGE > 1) then TRIVIA_UI_SCORE_PAGE = TRIVIA_UI_SCORE_PAGE - 1; Trivia_UIRefreshScores(); end end);
    local scorePage = board:CreateFontString("TriviaScorePage", "OVERLAY", "GameFontHighlightSmall");
    scorePage:SetPoint("TOP", board, "TOP", 0, -353); scorePage:SetWidth(120); scorePage:SetJustifyH("CENTER");
    Trivia_UIButton(board, "TriviaScoreNext", ">>", 50, 22, 258, -348, function()
        local pages = math.max(1, math.ceil(table.getn(Trivia_UISortedScores()) / 12));
        if (TRIVIA_UI_SCORE_PAGE < pages) then TRIVIA_UI_SCORE_PAGE = TRIVIA_UI_SCORE_PAGE + 1; Trivia_UIRefreshScores(); end
    end);
    Trivia_UIButton(board, "TriviaScoreRefresh", "Refresh", 90, 22, 120, -348, function() Trivia_UIRefreshScores(); end);
    TriviaScoreBroadcastChannelButton = Trivia_UIButton(board, "TriviaScoreBroadcastChannel", "Channel: " .. Trivia_UIBroadcastChannelLabel(), 112, 22, 20, -374, function()
        Trivia_UICycleBroadcastChannel();
    end);
    Trivia_UIButton(board, "TriviaScorePublish", "Publish", 100, 22, 192, -374, function()
        Trivia_UIPublishLeaderboard();
    end);

    Trivia_UIRefresh();
    Trivia_UIRefreshScores();
end

function Trivia_UISelectBank(listName)
    if (TRIVIA_ENABLED) then
        Trivia_ConsoleMessage("Stop the trivia game before changing the question bank.");
        return;
    end
    if (Trivia_LoadQuestionList(listName)) then
        TRIVIA_UI_PAGE = 1;
        TRIVIA_UI_SELECTED_QUESTION = nil;
        Trivia_ConsoleMessage("Question set selected: " .. TRIVIA_QLIST .. " (" .. table.getn(TRIVIA_QUESTIONS) .. " questions)");
        Trivia_UIRefresh();
    else
        Trivia_UIRefresh();
    end
end

function Trivia_UIRefresh()
    if (not TriviaMainFrame) then return; end
    if (TriviaUIStatus) then
        local state = TRIVIA_ENABLED and "RUNNING" or "STOPPED";
        TriviaUIStatus:SetText("Status: " .. state .. "  |  Bank: " .. (TRIVIA_QLIST or "unknown") .. "  |  Questions: " .. table.getn(TRIVIA_QUESTIONS or {}));
    end
    local count = table.getn(TRIVIA_QUESTIONS or {});
    local pages = math.max(1, math.ceil(count / 8));
    if (TRIVIA_UI_PAGE > pages) then TRIVIA_UI_PAGE = pages; end
    local row;
    for row = 1, 8 do
        local index = ((TRIVIA_UI_PAGE - 1) * 8) + row;
        local button = TriviaUIQuestionButtons and TriviaUIQuestionButtons[row];
        if (button) then
            if (index <= count) then
                local question = TRIVIA_QUESTIONS[index] or "";
                if (string.len(question) > 68) then question = string.sub(question, 1, 65) .. "..."; end
                button:SetText(index .. ". " .. question);
                button.triviaQuestionIndex = index;
                if (index == TRIVIA_UI_SELECTED_QUESTION) then button:LockHighlight(); else button:UnlockHighlight(); end
                button:Show();
            else
                button:SetText(""); button.triviaQuestionIndex = nil; button:Hide();
            end
        end
    end
    if (TriviaUIPage) then TriviaUIPage:SetText("Page " .. TRIVIA_UI_PAGE .. " / " .. pages); end
    if (TriviaUISelected) then
        if (TRIVIA_UI_SELECTED_QUESTION and TRIVIA_QUESTIONS[TRIVIA_UI_SELECTED_QUESTION]) then
            TriviaUISelected:SetText("Selected: " .. TRIVIA_QUESTIONS[TRIVIA_UI_SELECTED_QUESTION]);
        else
            TriviaUISelected:SetText("Selected question: none");
        end
    end
    Trivia_UIRefreshScores();
end

function Trivia_UIRefreshScores()
    if (not TriviaScoreFrame or not TriviaUIScoreRows) then return; end
    local rows = Trivia_UISortedScores();
    local pages = math.max(1, math.ceil(table.getn(rows) / 12));
    if (TRIVIA_UI_SCORE_PAGE > pages) then TRIVIA_UI_SCORE_PAGE = pages; end
    local fastest = "Fastest: none";
    local slowest = "Slowest: none";
    if (TRIVIA_TIME_RECORD and TRIVIA_TIME_RECORD.holder ~= "noone") then fastest = "Fastest: " .. TRIVIA_TIME_RECORD.holder .. " (" .. TRIVIA_TIME_RECORD.time .. "s)"; end
    if (TRIVIA_SLOW_RECORD and TRIVIA_SLOW_RECORD.holder ~= "noone") then slowest = "Slowest: " .. TRIVIA_SLOW_RECORD.holder .. " (" .. TRIVIA_SLOW_RECORD.time .. "s)"; end
    if (TriviaScoreRecords) then TriviaScoreRecords:SetText(fastest .. "\n" .. slowest .. "\nQuiz: " .. TRIVIA_QUIZ_LENGTH .. " questions / suggested contribution " .. Trivia_GetMinimumBet() .. "s"); end
    local row;
    for row = 1, 12 do
        local index = ((TRIVIA_UI_SCORE_PAGE - 1) * 12) + row;
        local fs = TriviaUIScoreRows[row];
        if (rows[index]) then
            fs:SetText(index .. ". " .. rows[index].player .. " - " .. rows[index].score .. " point(s)");
        else
            fs:SetText("");
        end
    end
    if (TriviaScorePage) then TriviaScorePage:SetText("Page " .. TRIVIA_UI_SCORE_PAGE .. " / " .. pages); end
end

function Trivia_ToggleMainFrame()
    if (not TriviaMainFrame) then Trivia_CreateInterface(); end
    if (TriviaMainFrame:IsShown()) then TriviaMainFrame:Hide(); else TriviaMainFrame:Show(); Trivia_UIRefresh(); end
end

function Trivia_ToggleScoreFrame()
    if (not TriviaScoreFrame) then Trivia_CreateInterface(); end
    if (TriviaScoreFrame:IsShown()) then TriviaScoreFrame:Hide(); else TriviaScoreFrame:Show(); Trivia_UIRefreshScores(); end
end
