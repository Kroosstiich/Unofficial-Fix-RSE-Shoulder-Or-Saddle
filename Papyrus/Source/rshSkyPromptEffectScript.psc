Scriptname rshSkyPromptEffectScript extends ActiveMagicEffect  

; Properties

Import SkyPrompt

GlobalVariable Property rshBanditSync Auto

Keyword Property ActorTypeNPC Auto

MiscObject Property rshBanditOnPlayerToken Auto
MiscObject Property rshBanditOnPlayerHorseToken Auto

ReferenceAlias Property FollowerBandit Auto
ReferenceAlias Property FollowerBanditCarried Auto
ReferenceAlias Property RSHPlayerHorse Auto

rshCoreScript Property RSHCS auto
rshUpdateManagerScript Property RSHUM auto
rshSkyPromptScript Property RSHSP auto

Function OnEffectStart(Actor aktarget, Actor akcaster)
	if (RSHSP.RSEID == 0)
;		debug.Notification("RSE not registered to SkyPrompt)")
		return
	else
		if RSHUM.Verbose	; FIX patch : notification affichée à chaque session → mode verbeux uniquement
			debug.Notification("RSE succesfully registered to SkyPrompt")
		endif
	endif
	
	RegisterForCrosshairRef()
EndFunction

int shownPrompt = 0	; FIX patch (P-02) : invite actuellement affichée (0 = aucune)

Function RemovePrt()
	; FIX patch (P-02) : ne retirer que l'invite affichée (5 appels natifs à chaque changement de viseur → 0 ou 1)
	if shownPrompt != 0
		RemovePrompt(RSHSP.RSEID, shownPrompt, 0)
		shownPrompt = 0
	endif
EndFunction

Function ShowPrompt(string asText, int aiEventID, int[] aiDevices, int[] aiKeys, float afProgress)
	SendPrompt(RSHSP.RSEID, asText, aiEventID, 0, 1, none, aiDevices, aiKeys, afProgress)
	shownPrompt = aiEventID
EndFunction

Event OnCrosshairRefChange(ObjectReference ref)
if RSHUM.UseSkyPrompt
	Actor bandit = FollowerBandit.GetActorRef()
	Actor banditcarried = FollowerBanditCarried.GetActorRef()
	Actor refActor = ref as Actor
	
	RemovePrt()
	
	int[] devices = new int[2]
	int[] keys = new int[2]
	devices[0] = 0
	devices[1] = 2
	keys[0] = RSHUM.SkyPromptKeyKeyboard
	keys[1] = RSHUM.SkyPromptKeyGamePad
	
	If !ref
		; Cas 4: Déposer le bandit/corps au sol
		if banditcarried && banditcarried.GetItemCount(rshBanditOnPlayerToken) > 0 && !(Game.GetPlayer().IsOnMount())
;			RemovePrt()
			ShowPrompt("$PROMPT_DROP", 4, devices, keys, 2.5)
			return
		endif
		return
	else
		if refActor && !(Game.GetPlayer().IsOnMount())
			if rshBanditSync.GetValue() == 1
				RSHCS.UpdatePlayerHorse()
				Actor playerHorse = RSHPlayerHorse.GetActorRef()
				
				If (refActor == playerHorse && playerHorse != none)
					if RSHUM.SkyPromptBehind
						if !(refActor.HasLOS(Game.GetPlayer()))
							; Cas 1: Bandit sur cheval -> Passer au joueur
							If banditcarried && banditcarried.GetItemCount(rshBanditOnPlayerHorseToken) > 0
;								RemovePrt()
								ShowPrompt("$PROMPT_PICKUP_HOLD", 1, devices, keys, 2.5)
								return
							
							; Cas 2: Bandit sur joueur -> Attacher bandit au cheval
							elseif banditcarried && banditcarried.GetItemCount(rshBanditOnPlayerToken) > 0
;								RemovePrt()
								ShowPrompt("$PROMPT_LOADMOUNT_HOLD", 2, devices, keys, 2.5)
								return
							endif
							return
						endif
						return
					else
						; Cas 1: Bandit sur cheval -> Passer au joueur
						If banditcarried && banditcarried.GetItemCount(rshBanditOnPlayerHorseToken) > 0
;							RemovePrt()
							ShowPrompt("$PROMPT_PICKUP_HOLD", 1, devices, keys, 2.5)
							return
						
						; Cas 2: Bandit sur joueur -> Attacher bandit au cheval
						elseif banditcarried && banditcarried.GetItemCount(rshBanditOnPlayerToken) > 0
;							RemovePrt()
							ShowPrompt("$PROMPT_LOADMOUNT_HOLD", 2, devices, keys, 2.5)
							return
						endif
						return
					return
					endif
				return
				endif
			else
				If refActor.haskeyword(ActorTypeNPC)
					if refActor.IsDead()
;						RemovePrt()
						ShowPrompt("$PROMPT_PICKUP_HOLD", 5, devices, keys, 2.5)
						return
					else
						if RSHUM.SkyPromptBehind
							if (!(refActor.HasLOS(Game.GetPlayer())) || refActor.IsBleedingOut())
	;							RemovePrt()
								ShowPrompt("$PROMPT_PICKUP_HOLD", 6, devices, keys, 5.0)
								return
							endif
							return
						else
;							RemovePrt()
							ShowPrompt("$PROMPT_PICKUP_HOLD", 6, devices, keys, 5.0)
							return
						endif
						return
					endif
					return
				endif
				return
			endif
			return
		endif
		return
	endif
	return
endif
EndEvent

Function OnEffectFinish(Actor aktarget, Actor akcaster)
	UnregisterForCrosshairRef()
EndFunction
