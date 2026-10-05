Scriptname rshConfigMenu extends SKI_ConfigBase  

rshUpdateManagerScript Property RSHUM auto

int oidOptionMenu
int oidOptionSpell
int oidOptionMissingSpell
int oidOptionDialog
int oidOptionToken
int oidOptionSidesaddle
int oidOptionSidesaddleM
int oidOptionReversePos
int oidOptionReadyToFight
int oidOptionVerbose
int oidOptionSkyPrompt
int oidOptionSendAlarmNPC
int oidOptionFollowerCanSpeak
int oidOptionSkyPromptKeyKeyboard
int oidOptionSkyPromptKeyGamePad
int oidOptionSkyPromptBehind

; Variables locales pour stocker les valeurs temporaires
Int _valeurDC
Int _valeurHC
Int _valeurDH
Int _valeurHH
Int _valeurDF
Int _valeurHF
Int _valeurDB
Int _valeurHB

; IDs des options (pour identifier les sliders)
Int _sliderDCID
Int _sliderHCID
Int _sliderDHID
Int _sliderHHID
Int _sliderDFID
Int _sliderHFID
Int _sliderDBID
Int _sliderHBID

Event OnConfigInit()
	ModName = "RSE-ShoulderOrSaddle"
	Pages = new string[3]
	Pages[0] = "$MCM_Management"
	Pages[1] = "$MCM_Riding_Options"
	Pages[2] = "$MCM_Miscellaneous"
EndEvent

Function RenderLogo()
	if CurrentPage == ""
		LoadCustomContent("RSE-ShoulderOrSaddle/MCM.dds")
	else
		UnloadCustomContent()
	endif
EndFunction

Event OnPageReset(string page)
	_valeurDC = RSHUM.DC
	_valeurHC = RSHUM.HC
	_valeurDH = RSHUM.DH
	_valeurHH = RSHUM.HH
	_valeurDB = RSHUM.DB
	_valeurHB = RSHUM.HB
	_valeurDF = RSHUM.DF
	_valeurHF = RSHUM.HF
	RenderLogo()
		
	if(page == "$MCM_Management")
		SetCursorPosition(0)
		AddHeaderOption("$MCM_Follower_Options")
		AddEmptyOption()
		oidOptionMenu = AddToggleOption("$MCM_Management_MENU", RSHUM.UseHorseMenu)
		oidOptionSpell = AddToggleOption("$MCM_Management_SPELL", RSHUM.UseHorseSpell)
		oidOptionDialog = AddToggleOption("$MCM_Management_TALK", RSHUM.UseHorseDialogue)
		oidOptionToken = AddToggleOption("$MCM_Management_MEDAILLON", !RSHUM.UseHorseMenu)
		oidOptionMissingSpell = AddToggleOption("$MCM_Management_MISSINGPELL", RSHUM.MissingSpell)
		oidOptionSendAlarmNPC = AddToggleOption("$MCM_Management_SENDALARMNPC", RSHUM.SendAlarmNPC)
		
		SetCursorPosition(10)
		AddHeaderOption("$MCM_UI_Options")
		AddEmptyOption()
		oidOptionSkyPrompt = AddToggleOption("$MCM_Management_SKYPROMPT", RSHUM.UseSkyPrompt)
		oidOptionSkyPromptBehind = AddToggleOption("$MCM_UI_SKYPROMPT_BEHIND", RSHUM.SkyPromptBehind)
		oidOptionSkyPromptKeyKeyboard = AddKeyMapOption("$MCM_UI_SKYPROMPT_KEY_KEYBOARD", RSHUM.SkyPromptKeyKeyboard)
		oidOptionSkyPromptKeyGamePad = AddKeyMapOption("$MCM_UI_SKYPROMPT_KEY_GAMEPAD", RSHUM.SkyPromptKeyGamePad)
		
	elseif(page == "$MCM_Riding_Options")
		SetCursorPosition(0)
		AddHeaderOption("$MCM_Riding_Options")
		AddEmptyOption()
		oidOptionSidesaddle = AddToggleOption("$MCM_RO_FEMALE_SIDESADDLE", RSHUM.RideSidesaddle)
		oidOptionSidesaddleM = AddToggleOption("$MCM_RO_MALE_SIDESADDLE", RSHUM.RideSidesaddleM)
		oidOptionReversePos = AddToggleOption("$MCM_RO_PLAYER_BEHIND", RSHUM.ReversePositions)
		oidOptionReadyToFight = AddToggleOption("$MCM_RO_READY_TO_FIGHT", RSHUM.ReadyToFight)
		oidOptionFollowerCanSpeak = AddToggleOption("$MCM_RO_FOLLOWERCANSPEAK", RSHUM.FollowerCanSpeak)	; FIX patch : la case affichait l'inverse du reglage (OnOptionSelect affiche la vraie valeur)
		
		SetCursorPosition(8)
		AddHeaderOption("$MCM_Positioning")
		AddEmptyOption()
		_sliderDCID = AddSliderOption("$MCM_PO_DISTANCE_CHILD_SADDLE", _valeurDC, "{0}")
		_sliderHCID = AddSliderOption("$MCM_PO_HEIGHT_CHILD_SADDLE", _valeurHC, "{0}")
		_sliderDHID = AddSliderOption("$MCM_PO_DISTANCE_MALE_SADDLE", _valeurDH, "{0}")
		_sliderHHID = AddSliderOption("$MCM_PO_HEIGHT_MALE_SADDLE", _valeurHH, "{0}")
		_sliderDFID = AddSliderOption("$MCM_PO_DISTANCE_FEMALE_SADDLE", _valeurDF, "{0}")
		_sliderHFID = AddSliderOption("$MCM_PO_HEIGHT_FEMALE_SADDLE", _valeurHF, "{0}")
		_sliderDBID = AddSliderOption("$MCM_PO_DISTANCE_DEAD_SADDLE", _valeurDB, "{0}")
		_sliderHBID = AddSliderOption("$MCM_PO_HEIGHT_DEAD_SADDLE", _valeurHB, "{0}")
		
	elseif(page == "$MCM_Miscellaneous")
		SetCursorFillMode(TOP_TO_BOTTOM)
		SetCursorPosition(0)
		AddHeaderOption("$MCM_Miscellaneous")
		oidOptionVerbose = AddToggleOption("$MCM_Verbose", RSHUM.Verbose)
	endif
EndEvent

Event OnOptionSelect(int option)
	if (option == oidOptionMenu)
		SetHorseMenu(!RSHUM.UseHorseMenu)
	elseif (option == oidOptionSpell)
		SetHorseSpell(!RSHUM.UseHorseSpell)
	elseif (option == oidOptionMissingSpell)
		SetMissingSpell(!RSHUM.MissingSpell)
	elseif (option == oidOptionSkyPrompt)
		SetSkyPromptSpell(!RSHUM.UseSkyPrompt)
	elseif (option == oidOptionSendAlarmNPC)
		RSHUM.SendAlarmNPC = !RSHUM.SendAlarmNPC
		SetToggleOptionValue(oidOptionSendAlarmNPC, RSHUM.SendAlarmNPC)
	elseif (option == oidOptionSkyPromptBehind)
		RSHUM.SkyPromptBehind = !RSHUM.SkyPromptBehind
		SetToggleOptionValue(oidOptionSkyPromptBehind, RSHUM.SkyPromptBehind)
	elseif (option == oidOptionDialog)
		SetHorseDialog(!RSHUM.UseHorseDialogue)
	elseif (option == oidOptionSidesaddle)
		SetSideSaddle(!RSHUM.RideSidesaddle)
	elseif (option == oidOptionSidesaddleM)
		SetSideSaddleM(!RSHUM.RideSidesaddleM)
	elseif (option == oidOptionReversePos)
		SetReversePosition(!RSHUM.ReversePositions)
	elseif (option == oidOptionFollowerCanSpeak)
		RSHUM.FollowerCanSpeak = !RSHUM.FollowerCanSpeak
		SetToggleOptionValue(oidOptionFollowerCanSpeak, RSHUM.FollowerCanSpeak)
	elseif (option == oidOptionReadyToFight)
		RSHUM.ReadyToFight = !RSHUM.ReadyToFight
		SetToggleOptionValue(oidOptionReadyToFight, RSHUM.ReadyToFight)
	elseif (option == oidOptionVerbose)
		RSHUM.Verbose = !RSHUM.Verbose
		SetToggleOptionValue(oidOptionVerbose, RSHUM.Verbose)
	endif
EndEvent

Event OnOptionHighlight(int option)
	if (option == oidOptionMenu)
		SetInfotext("$MCM_DESC_MENU")
	elseif (option == oidOptionSkyPromptKeyKeyboard)
		SetInfotext("$MCM_DESC_SKYPROMPT_KEY_KEYBOARD")
	elseif (option == oidOptionSkyPromptKeyGamePad)
		SetInfotext("$MCM_DESC_SKYPROMPT_KEY_GAMEPAD")
	elseif (option == oidOptionSkyPromptBehind)
		SetInfotext("$MCM_DESC_SKYPROMPT_BEHIND")
	elseif (option == oidOptionSpell)
		SetInfotext("$MCM_DESC_SPELL")
	elseif (option == oidOptionMissingSpell)
		SetInfotext("$MCM_DESC_MISSINGSPELL")
	elseif (option == oidOptionSkyPrompt)
		SetInfotext("$MCM_DESC_SKYPROMPT")
	elseif (option == oidOptionSendAlarmNPC)
		SetInfotext("$MCM_DESC_SENDALARMNPC")
	elseif (option == oidOptionFollowerCanSpeak)
		SetInfotext("$MCM_DESC_FOLLOWERCANSPEAK")
	elseif (option == oidOptionDialog)
		SetInfotext("$MCM_DESC_TALK")
	elseif (option == oidOptionToken)
		SetInfotext("$MCM_DESC_MEDAILLON")
	elseif (option == oidOptionSidesaddle)
		SetInfotext("$MCM_DESC_FEMALE_SIDESADDLE")
	elseif (option == oidOptionSidesaddleM)
		SetInfotext("$MCM_DESC_MALE_SIDESADDLE")
	elseif (option == oidOptionReversePos)
		SetInfotext("$MCM_DESC_PLAYER_BEHIND")
	elseif (option == oidOptionReadyToFight)
		SetInfotext("$MCM_DESC_READY_TO_FIGHT")
	elseif (option == _sliderDCID)
        SetInfoText("$MCM_DESC_DISTANCE_CHILD_SADDLE")
    elseif (option == _sliderHCID)
        SetInfoText("$MCM_DESC_HEIGHT_CHILD_SADDLE")
	elseif (option == _sliderDHID)
        SetInfoText("$MCM_DESC_DISTANCE_MALE_SADDLE")
    elseif (option == _sliderHHID)
        SetInfoText("$MCM_DESC_HEIGHT_MALE_SADDLE")
	elseif (option == _sliderDFID)
        SetInfoText("$MCM_DESC_DISTANCE_FEMALE_SADDLE")
    elseif (option == _sliderHFID)
        SetInfoText("$MCM_DESC_HEIGHT_FEMALE_SADDLE")
	elseif (option == _sliderDBID)
        SetInfoText("$MCM_DESC_DISTANCE_DEAD_SADDLE")
    elseif (option == _sliderHBID)
        SetInfoText("$MCM_DESC_HEIGHT_DEAD_SADDLE")
	elseif (option == oidOptionVerbose)
		SetInfotext("$MCM_DESC_VERBOSE")
	endif
EndEvent

Event OnOptionKeyMapChange(int option, int keyCode, string conflictControl, string conflictName)
	if (option == oidOptionSkyPromptKeyKeyboard)
		RSHUM.SkyPromptKeyKeyboard = keyCode
		SetKeyMapOptionValue(oidOptionSkyPromptKeyKeyboard, RSHUM.SkyPromptKeyKeyboard)
	elseif (option == oidOptionSkyPromptKeyGamePad)
		RSHUM.SkyPromptKeyGamePad = keyCode
		SetKeyMapOptionValue(oidOptionSkyPromptKeyGamePad, RSHUM.SkyPromptKeyGamePad)
	endIf
EndEvent

Function SetHorseMenu(bool value)
	RSHUM.UseHorseMenu = value
	SetToggleOptionValue(oidOptionMenu, value)
	SetToggleOptionValue(oidOptionToken, !value)
	if (value)
		Game.GetPlayer().AddPerk(RSHUM.RideSharePerk)
		SetHorseSpell(false)
		SetHorseDialog(false)
	else
		Game.GetPlayer().RemovePerk(RSHUM.RideSharePerk)
		SetToggleOptionValue(oidOptionDialog, !value)
		RSHUM.UseHorseDialogue = !value
	endif
EndFunction

Function SetSkyPromptSpell(bool value)
	RSHUM.UseSkyPrompt = value
	SetToggleOptionValue(oidOptionSkyPrompt, RSHUM.UseSkyPrompt)
	if (value)
		RSHUM.RSHSkyPromptWarning.Show()
		Game.GetPlayer().AddSpell(RSHUM.rshSkyPromptSpell)
	else
		Game.GetPlayer().RemoveSpell(RSHUM.rshSkyPromptSpell)
	endif
EndFunction

Function SetHorseSpell(bool value)
	RSHUM.UseHorseSpell = value
	SetToggleOptionValue(oidOptionSpell, value)
	if (value)
		SetHorseMenu(false)
	endif
EndFunction

Function SetMissingSpell(bool value)
	RSHUM.MissingSpell = value
	SetToggleOptionValue(oidOptionMissingSpell, value)
	if (value)
		Game.GetPlayer().AddSpell(RSHUM.rshBringMissingActorSpell)
	else
		Game.GetPlayer().RemoveSpell(RSHUM.rshBringMissingActorSpell)
	endif
EndFunction

Function SetHorseDialog(bool value)
	RSHUM.UseHorseDialogue = value
	SetToggleOptionValue(oidOptionDialog, value)
	if (value)
		SetHorseMenu(false)
	endif
EndFunction

Function SetSideSaddle(bool value)
	RSHUM.RideSidesaddle = value
	SetToggleOptionValue(oidOptionSidesaddle, value)
	if (value)
		RSHUM.RideSidesaddle = true
		RSHUM.ReversePositions = false
	else
		RSHUM.RideSidesaddle = false
	endif
EndFunction

Function SetSideSaddleM(bool value)
	RSHUM.RideSidesaddleM = value
	SetToggleOptionValue(oidOptionSidesaddleM, value)
	if (value)
		RSHUM.RideSidesaddleM = true
		RSHUM.ReversePositions = false
	else
		RSHUM.RideSidesaddleM = false
	endif
EndFunction

Function SetReversePosition(bool value)
	RSHUM.ReversePositions = value
	SetToggleOptionValue(oidOptionReversePos, value)
	if (value)
		RSHUM.ReversePositions = true
		RSHUM.RideSidesaddle = false
		RSHUM.RideSidesaddleM = false
	else
		RSHUM.ReversePositions = false
	endif
EndFunction

Event OnOptionSliderOpen(int option)
    ; Quand on clique sur un slider
    If option == _sliderDCID
        SetSliderDialogStartValue(_valeurDC)
        SetSliderDialogDefaultValue(30)
        SetSliderDialogRange(-75, 25)
        SetSliderDialogInterval(5)
    ElseIf option == _sliderHCID
        SetSliderDialogStartValue(_valeurHC)
        SetSliderDialogDefaultValue(4)
        SetSliderDialogRange(-10, 10)
        SetSliderDialogInterval(1)
    ElseIf option == _sliderDHID
        SetSliderDialogStartValue(_valeurDH)
        SetSliderDialogDefaultValue(-25)
        SetSliderDialogRange(-75, 25)
        SetSliderDialogInterval(5)
    ElseIf option == _sliderHHID
        SetSliderDialogStartValue(_valeurHH)
        SetSliderDialogDefaultValue(0)
        SetSliderDialogRange(-10, 10)
        SetSliderDialogInterval(1)
	ElseIf option == _sliderDFID
        SetSliderDialogStartValue(_valeurDF)
        SetSliderDialogDefaultValue(-25)
        SetSliderDialogRange(-75, 25)
        SetSliderDialogInterval(5)
    ElseIf option == _sliderHFID
        SetSliderDialogStartValue(_valeurHF)
        SetSliderDialogDefaultValue(0)
        SetSliderDialogRange(-10, 10)
        SetSliderDialogInterval(1)
	ElseIf option == _sliderDBID
        SetSliderDialogStartValue(_valeurDB)
        SetSliderDialogDefaultValue(-25)
        SetSliderDialogRange(-75, 25)
        SetSliderDialogInterval(5)
    ElseIf option == _sliderHBID
        SetSliderDialogStartValue(_valeurHB)
        SetSliderDialogDefaultValue(0)
        SetSliderDialogRange(-10, 10)
        SetSliderDialogInterval(1)
    EndIf
EndEvent

Event OnOptionSliderAccept(int option, float value)
    ; Quand on valide une nouvelle valeur
    If option == _sliderDCID
        _valeurDC = value as Int
        RSHUM.DC = _valeurDC
        SetSliderOptionValue(option, _valeurDC, "{0}")
    ElseIf option == _sliderHCID
        _valeurHC = value as Int
        RSHUM.HC = _valeurHC
        SetSliderOptionValue(option, _valeurHC, "{0}")
    ElseIf option == _sliderDHID
        _valeurDH = value as Int
        RSHUM.DH = _valeurDH
        SetSliderOptionValue(option, _valeurDH, "{0}")
    ElseIf option == _sliderHHID
        _valeurHH = value as Int
        RSHUM.HH = _valeurHH
        SetSliderOptionValue(option, _valeurHH, "{0}")
	ElseIf option == _sliderDFID
        _valeurDF = value as Int
        RSHUM.DF = _valeurDF
        SetSliderOptionValue(option, _valeurDF, "{0}")
    ElseIf option == _sliderHFID
        _valeurHF = value as Int
        RSHUM.HF = _valeurHF
        SetSliderOptionValue(option, _valeurHF, "{0}")
	ElseIf option == _sliderDBID
        _valeurDB = value as Int
        RSHUM.DB = _valeurDB
        SetSliderOptionValue(option, _valeurDB, "{0}")
    ElseIf option == _sliderHBID
        _valeurHB = value as Int
        RSHUM.HB = _valeurHB
        SetSliderOptionValue(option, _valeurHB, "{0}")
    EndIf
EndEvent
