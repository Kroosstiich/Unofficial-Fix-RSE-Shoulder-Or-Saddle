Scriptname rshUpdateManagerScript extends Quest Conditional

Actor Property BackupHorseRef Auto Hidden 

Quest Property rshCore auto
Quest Property rshSkyPrompt auto
Quest Property rshTracker auto

GlobalVariable Property rshAuthorizeRide auto
GlobalVariable Property rshBanditSync auto
GlobalVariable property rshPluginVersion auto		; Check Update version

ReferenceAlias Property BanditLoadSave Auto
ReferenceAlias Property NPCLoadSave Auto
ReferenceAlias Property HorseLoadSave Auto

Message Property RSHSkyPromptWarning auto

Spell Property rshPickUpSpell Auto					; Spell to carry npc
Spell Property rshBringMissingActorSpell Auto
Spell Property rshSkyPromptSpell Auto					; Spell to carry npc

Perk property RideSharePerk Auto					; Perk to active the pop up menu when activating a horse
Perk property rshDropPerk Auto
Perk property rshDismountPerk Auto
		
bool Property UseHorseMenu Auto Conditional			; Use popup menu instead of mounting events
bool Property UseHorseSpell Auto Conditional		; Use spell to mark followers for mounting
bool Property MissingSpell Auto Conditional			; Give the Bring Dead Actor spell just in case
bool Property UseHorseDialogue Auto Conditional		; Use dialogue to invite followers for mounting
bool Property RideSidesaddle Auto Conditional		; Ladies will ride sidesaddle
bool Property RideSidesaddleM Auto Conditional		; Men will ride sidesaddle
bool Property ReversePositions Auto Conditional		; Player will ride behind follower
bool Property ReadyToFight Auto Conditional			; Follower dismount when player drawn a weapon
bool Property Verbose auto Conditional				; True to display all notifications
bool Property UseSkyPrompt Auto Conditional			; Use SkyPrompt instead of the spell
bool Property SendAlarmNPC Auto Conditional			; Kidnapped npc try to call for help
bool Property FollowerCanSpeak Auto Conditional		; Followers say random lines while mounting together
bool Property SkyPromptBehind Auto Conditional		; Need to be behind

int Property dc = 30 Auto	; Kids ride in front
int Property hc = 4 Auto	; Kids ride in front
int Property hh = 0 Auto	; Height offset from SaddleBone
int Property dh = -25 Auto	; Distance from SaddleBone
int Property hf = 0 Auto	; Height offset from SaddleBone
int Property df = -25 Auto	; Distance from SaddleBone
int Property hb = 0 Auto	; Height offset from SaddleBone
int Property db = -50 Auto	; Distance from SaddleBone
int Property SkyPromptKeyKeyboard = 19 Auto ; R
int Property SkyPromptKeyGamePad = 278 Auto ; X / []

rshCoreScript Property RSHCS auto
rshInviteScript Property RSHINV auto

bool bManaging = false	; FIX patch : empêche deux exécutions simultanées de ManageCoreQuest

Event OnInit() ; This event will run once, when the script is initialized
	; FIX patch (P-01) : ne pas arrêter/démarrer d'autres quêtes depuis OnInit (blocage au démarrage
	; d'une partie : ni sorts, ni perks, MCM vide). Le travail est différé hors de OnInit.
	RegisterForSingleUpdate(2.0)
EndEvent

Event OnUpdate()
	ManageCoreQuest()
EndEvent

Function ManageCoreQuest()
	if bManaging
		return
	endif
	bManaging = true

	if rshAuthorizeRide.GetValue() == 1 || rshBanditSync.GetValue() == 1
		MAJUpdate()
	else
		MAJUpdate1()
	endif
	
	if (rshPluginVersion.GetValue() < 1.0)
		rshPluginVersion.SetValue(1.4)
		Game.GetPlayer().AddSpell(rshPickUpSpell)
		Game.GetPlayer().AddSpell(rshBringMissingActorSpell)
		Game.GetPlayer().AddPerk(rshDropPerk)
		Game.GetPlayer().AddPerk(rshDismountPerk)
		debug.Notification("RSE Updated to v1.4")
	elseif (rshPluginVersion.GetValue() >= 1.0 && rshPluginVersion.GetValue() < 1.4)
		rshPluginVersion.SetValue(1.4)
		Game.GetPlayer().AddPerk(rshDropPerk)
		Game.GetPlayer().AddPerk(rshDismountPerk)
		debug.Notification("RSE Updated to v1.4")
	endif
	
	if Verbose	; FIX patch : notification de débogage affichée à chaque chargement → seulement en mode verbeux
		debug.Notification("RSE Manager finished is task")
	endif
	bManaging = false
EndFunction

Function MAJUpdate()
	rshTracker.Start()
	Utility.wait(0.2)
	MAJUpdate2()
;	rshTracker.Stop()
	
	Utility.wait(0.2)
	MAJUpdate1()
	
;	rshTracker.Start()
	Utility.wait(0.2)
	MAJUpdate2()
	Utility.wait(0.2)
	rshTracker.Stop()
	Utility.wait(0.2)
	RSHCS.FastTravelNPCS()
EndFunction
	
Function MAJUpdate1()
	rshCore.Stop()
	rshSkyPrompt.Stop()
	Game.GetPlayer().RemoveSpell(rshSkyPromptSpell)
	Utility.wait(0.2)
	rshCore.Start()
	Utility.wait(0.2)
	rshSkyPrompt.Start()
EndFunction
	
Function MAJUpdate2()
	Actor akHorse = HorseLoadSave.getActorRef()
	RSHCS.RSHPlayerHorse.ForceRefTo(akHorse)
;	RSHCS.UpdatePlayerHorse()
	if rshAuthorizeRide.GetValue() == 1
		Actor akNPC = NPCLoadSave.GetActorRef()
		if akNPC != None
			RSHCS.PillionRider.ForceRefTo(akNPC)
			RSHCS.follower3.ForceRefTo(akNPC)
			Utility.wait(0.1)
			RSHCS.AnimEventFollower(akNPC, true)
		endif
	endif
	
	if rshBanditSync.GetValue() == 1
		Actor akBandit = BanditLoadSave.GetActorRef()
		if akBandit != None
			RSHCS.FollowerBandit.ForceRefTo(akBandit)
			RSHCS.FollowerBanditCarried.ForceRefTo(akBandit)
		endif
	endif
EndFunction
