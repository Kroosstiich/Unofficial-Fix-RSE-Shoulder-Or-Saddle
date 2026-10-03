Scriptname rshSkyPromptScript extends Quest

Import SkyPrompt

Int Property RSEID = 0 Auto

; FIX patch (P-09) : propriété encore remplie par l'ESP (VMAD) ; redéclarée pour supprimer l'avertissement au chargement. Inutilisée.
Spell Property rshSkyPromptSpell Auto

ReferenceAlias Property FollowerBandit Auto
ReferenceAlias Property FollowerBanditCarried Auto
ReferenceAlias Property RSHPlayerHorse Auto

rshinvitescript Property RSHINV auto
rshUpdateManagerScript Property RSHUM auto

Event OnInit() ; This event will run once, when the script is initialized
	; FIX patch (P-02) : SkyPrompt n'est pas une dépendance obligatoire ; sans lui, l'appel échouait à chaque démarrage.
	if SKSE.GetPluginVersion("SkyPrompt") >= 0
		RSEID = RegisterForSkyPromptEvent(self as Form)
	else
		RSEID = 0
	endif
	
	if RSHUM.UseSkyPrompt == true
		if (Game.GetPlayer().HasSpell(RSHUM.rshSkyPromptSpell))
			Game.GetPlayer().RemoveSpell(RSHUM.rshSkyPromptSpell)
		endif
		
		if !(Game.GetPlayer().HasSpell(RSHUM.rshSkyPromptSpell))
			Game.GetPlayer().AddSpell(RSHUM.rshSkyPromptSpell, false)
		endif
	else
		if (Game.GetPlayer().HasSpell(RSHUM.rshSkyPromptSpell))
			Game.GetPlayer().RemoveSpell(RSHUM.rshSkyPromptSpell)
		endif
	endif
EndEvent

Event OnSkyPromptEvent(Int clientID, Int eventType, Int eventID, Int actionID, float dx, float dy, float progress)
	Actor bandit = FollowerBandit.GetActorRef()
	Actor banditcarried = FollowerBanditCarried.GetActorRef()
	Actor player = Game.GetPlayer()
	Actor playerHorse = RSHPlayerHorse.GetActorRef()
	Actor targetActor = Game.GetCurrentCrosshairRef() as Actor

	if eventType == 0
		
		RemovePrompt(clientID, eventID, actionID)
		
		if eventID == 1
			if RSHUM.Verbose
				debug.Notification("Skyprompt : EventType 1")
			endif
			RSHINV.Cas1(banditcarried, playerHorse, player)
			return

		elseif eventID == 2
			if RSHUM.Verbose
				debug.Notification("Skyprompt : EventType 2")
			endif
			RSHINV.Cas2(banditcarried, playerHorse, player)
			return
		
		elseif eventID == 4
			if RSHUM.Verbose
				debug.Notification("Skyprompt : EventType 4")
			endif
			RSHINV.Cas4(bandit, banditcarried, player)
			return

		elseif eventID == 5
			if RSHUM.Verbose
				debug.Notification("Skyprompt : EventType 5")
			endif
			RSHINV.DeadTarget(targetActor)
			return

		elseif eventID == 6
			if RSHUM.Verbose
				debug.Notification("Skyprompt : EventType 6")
			endif
			RSHINV.LivingTarget(targetActor)
			return
		endif
	endif
EndEvent
