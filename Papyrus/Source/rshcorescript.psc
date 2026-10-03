Scriptname rshCoreScript extends Quest Conditional

Import RSEFollowerSKSE
Import RSEPlayerSKSE
Import RSEHorseSKSE

Event OnInit()
	Maintenance()
EndEvent

; Check if we need to mess with anything in case player upgraded this mod to a new version
Function Maintenance()
	RegisterForMenu("Loading Menu")
	RegisterForAnimationEvent(Game.GetPlayer(), "tailHorseMount")
	if rshAuthorizeRide.GetValue() >= 1
		if RSHUM.ReversePositions
			Keycode = Input.GetMappedKey("Activate")
			RegisterForKey(Keycode)
			mountedReversed = true
			RegisterForAnimationEvent(Game.GetPlayer(), "weaponSheathe")
			RegisterForAnimationEvent(Game.GetPlayer(), "LandEnd")
			RegisterForAnimationEvent(Game.GetPlayer(), "MTState")
			RegisterForAnimationEvent(Game.GetPlayer(), "HorseLocomotion")
			RegisterForAnimationEvent(Game.GetPlayer(), "HorseIdle")
		else
			RegisterForAnimationEvent(Game.GetPlayer(), "HorseExit")
			RegisterForAnimationEvent(Game.GetPlayer(), "tailHorseDismount")
			RegisterForAnimationEvent(Game.GetPlayer(), "tailHorseDismountSwim")
			RegisterForAnimationEvent(Game.GetPlayer(), "Getup")
		endif
	endif
	if RSHUM.Verbose
		debug.notification("Debug: Maintenance complete")
	endif
EndFunction

; Mount a horse and get a nearby follower on (if there is one)  
; Specify a horse to mount it, or None if unknown (for example when this function is called on a Mount animation event)
Function FollowerSearch()
	Actor Searchfollower1 = Follower1.getActorRef()
	Actor Searchfollower2 = Follower2.getActorRef()
	Follower3.clear()
	if (Searchfollower2 != None)
		follower3.ForceRefTo(Searchfollower2)
		Follower1.Clear()
		Follower2.Clear()
	elseif (Searchfollower1 != None)	; FIX patch (P-04) : ForceRefTo(None) est une erreur
		follower3.ForceRefTo(Searchfollower1)
		Follower1.Clear()
	endif
Endfunction

Function UpdatePlayerHorse()
	Actor playerLastHorse = Game.GetPlayersLastRiddenHorse()
	Actor currentAliasHorse = RSHPlayerHorse.GetActorRef()
	
	; 1. RESTAURATION : Si l'alias a sauté au chargement mais qu'on a notre backup
	if currentAliasHorse == none && RSHUM.BackupHorseRef != none
		currentAliasHorse = RSHUM.BackupHorseRef
	endif
	
	; 2. MISE À JOUR : Le dernier cheval monté par le joueur prime toujours
	if playerLastHorse != none
		currentAliasHorse = playerLastHorse
	endif
	
	; 3. ASSIGNATION : On remplit l'alias ET on met à jour notre backup
	if currentAliasHorse != none
		RSHPlayerHorse.ForceRefTo(currentAliasHorse)
		RSHUM.BackupHorseRef = currentAliasHorse
	endif
	
	; 4. NETTOYAGE : Si le cheval est mort, on vide tout proprement
	if currentAliasHorse != none && currentAliasHorse.IsDead()
		RSHPlayerHorse.Clear()
		RSHUM.BackupHorseRef = none
	endif
EndFunction

;Function UpdatePlayerHorse()

;	Actor playerLastHorse = Game.GetPlayersLastRiddenHorse()
;	Actor playerHorse = RSHPlayerHorse.GetActorRef()
	
;	if playerLastHorse == none
;		playerLastHorse = playerHorse
;	endif
	
;	if playerLastHorse != none
;		playerHorse = playerLastHorse
;		RSHPlayerHorse.ForceRefTo(playerHorse)
;	endif
	
;	if playerHorse != none && playerHorse.IsDead()
;		RSHPlayerHorse.Clear()
;		playerHorse = none
;	endif
;EndFunction

Function RideWithFollower(ObjectReference horse)

	rshTracker.Start()
	FollowerSearch()
	
	Utility.Wait(0.1)
	
	; Find nearby follower
	Actor follower = Follower3.getActorRef()
	Actor bandit = FollowerBandit.GetActorRef()
	
	UpdatePlayerHorse()
	Actor playerHorse = RSHPlayerHorse.GetActorRef()
	
	if (horse != None)
		horse.Activate(Game.GetPlayer())
		follower = Follower1NoToken.getActorRef()
		Follower3.ForceRefTo(follower)
		follower.RemoveItem(rshHorseFriendToken, 999, true)
		follower.RemoveItem(rshHorseCrimeToken, 999, true)
		follower.AddItem(rshHorseFriendToken)
	endif
	
	Follower1NoToken.Clear()
	rshTracker.Stop()
	
	if RSHUM.Verbose
		debug.notification("Debug: RideWithFollower")
	endif
	
	if ((follower == none) && (bandit == None))
		if RSHUM.Verbose
			debug.notification("Debug: no follower or bandit")
		endif
		return
	else
		if RSHUM.Verbose
			debug.notification("Debug: follower or bandit found")
		endif
		RegisterForAnimationEvent(Game.GetPlayer(), "HorseExit")
		RegisterForAnimationEvent(Game.GetPlayer(), "tailHorseDismount")		; Dismount events
		RegisterForAnimationEvent(Game.GetPlayer(), "tailHorseDismountSwim")
		RegisterForAnimationEvent(Game.GetPlayer(), "Getup")
		
		if follower != none
			if (follower.GetAnimationVariableBool("bIsRiding"))
				return							; Follower has their own horse
			else
				FollowerPart(follower, playerHorse)
				If RSHUM.ReversePositions
					Game.DisablePlayerControls(false, false, false, false, false, false, false, false)
				endif
			endif
		endif
		
		if bandit != none
			BanditPart(bandit, playerHorse)
		endif
	endif
EndFunction
	
Function FollowerPart(Actor follower, Actor Playerhorse)

	mountedReversed = false

	NFFNoHorse(follower, true)	; FIX patch (compat NFF) : pas de second cheval NFF pendant le duo
	follower.AddItem(rshNPCOnPlayerHorseToken)
	
	if follower.GetDistance(Game.GetPlayer()) > 2000
		follower.DisableNoWait()
		follower.moveto(Game.GetPlayer(), 100, -100, 0, true)
		follower.EnableNoWait()
	endif
	
	Debug.SendAnimationEvent(follower, "IdleForceDefaultState")
	
	if (RSHUM.ReversePositions)
		Keycode = Input.GetMappedKey("Activate")
		RegisterForKey(Keycode)				; Cannot capture regular dismount events when reversed, so listen for key
		mountedReversed = true
		RegisterForAnimationEvent(Game.GetPlayer(), "weaponSheathe")
		RegisterForAnimationEvent(Game.GetPlayer(), "LandEnd")
		RegisterForAnimationEvent(Game.GetPlayer(), "MTState")
		RegisterForAnimationEvent(Game.GetPlayer(), "HorseLocomotion")
		RegisterForAnimationEvent(Game.GetPlayer(), "HorseIdle")
		if RSHUM.Verbose
			debug.notification("Rider : " + follower.getDisplayName())
		endif
	else
		if RSHUM.Verbose
			debug.notification("Passenger : " + follower.getDisplayName())
		endif
	endif
	
	follower.BlockActivation(true)
	playerhorse.additem(rshHorseFollowerToken)
	RegisterForAnimationEvent(Game.GetPlayer(), "BeginWeaponDraw")		; Capture to dismount follower when weapon is drawn
	RegisterForAnimationEvent(Game.GetPlayer(), "BeginWeaponSheathe")
	
	AnimEventFollower(follower, true)

	LinkPillionRider(follower, Playerhorse)
	
EndFunction

Function BanditPart(Actor bandit, Actor playerHorse)
	Actor banditcarried = FollowerBanditCarried.GetActorRef()

	if (banditcarried == None)
		FollowerBanditCarried.ForceRefTo(bandit)
		Linkbanditcarried(banditcarried, playerhorse)
	else
		if (BanditCarried.GetItemCount(rshBanditOnPlayerHorseToken) > 0)
			BanditCarried.ForceRemoveRagdollFromWorld()
		endif
	endif
EndFunction

Function Linkbanditcarried(Actor banditcarried, Actor playerhorse)
	banditcarried.BlockActivation(true)
	rshBanditSync.SetValue(1)
	banditcarried.AddItem(rshBanditOnPlayerHorseToken, 1, true)
	banditcarried.MoveTo(rshXmarkerRef, 0, 0, 0, true)
	Utility.Wait(0.1)
	banditcarried.MoveTo(playerhorse, 0, 150, 50, true)
	banditcarried.SetAlpha(0)
	if (banditcarried.IsDead())
		Utility.Wait(1)
		banditcarried.SetMotionType(banditcarried.Motion_Keyframed, false)
		Utility.Wait(0.1)
		banditcarried.SetMotionType(banditcarried.Motion_Dynamic, true)
;		StartAttachmentHorse(playerHorse, pinHorseBone, banditcarried, 0, RSHUM.db, RSHUM.hb, 0, 0, 0, rshBanditSync)
		StartAttachmentPlayer(playerHorse, pinHorseBone, banditcarried, 0, RSHUM.db, RSHUM.hb, 0, 0, 0, rshBanditSync, false)
		SetAnimationBandit(BanditCarried)
		BanditCarried.ForceRemoveRagdollFromWorld()
	else
		banditcarried.SetMotionType(banditcarried.Motion_Keyframed, false)
		Utility.Wait(0.1)
		banditcarried.SetMotionType(banditcarried.Motion_Character, true)
		AnimEventFollower(banditcarried, true)
		SetAnimationBandit(banditcarried)
		banditcarried.EvaluatePackage()
		StartAttachmentHorse(playerHorse, pinHorseBone, banditcarried, 0, RSHUM.db, RSHUM.hb, 0, 0, 0, rshBanditSync)
;		if Game.GetPlayer().IsOnMount()
			BanditCarried.ForceRemoveRagdollFromWorld()
;		else
;			BanditCarried.ForceAddRagdollToWorld()
;		Endif
	Endif
	self.FadeIn(banditcarried)
EndFunction

Function LinkPillionRider(Actor follower, Actor Playerhorse)
	if (follower != None)
		self.FadeOut(follower)
		PillionRider.ForceRefTo(follower)
		SetAnimation(follower)
		follower.EvaluatePackage()
		SetRig(follower.IsChild(), Playerhorse)
		if follower.GetItemCount(rshHorseQuickStopToken) <= 0
			follower.AddItem(rshHorseQuickStopToken)
		endif
		Utility.wait(0.15)
		self.FadeIn(follower)
	endif
EndFunction

Function RemountOnTeleport(Actor follower, Actor Playerhorse)
	ClearRig()
	follower.DisableNoWait()
	follower.MoveTo(Game.GetPlayer(), 0, -500, 0, true)
	follower.Enable()
	WaitActor3D(follower)
	follower.SetAlpha(0)
	follower.BlockActivation(true)
	utility.wait(0.1)
	SetAnimation(follower)
	follower.EvaluatePackage()
	SetRig(follower.IsChild(), Playerhorse)
	Utility.wait(0.15)
	self.FadeIn(follower)
EndFunction

Function WaitActor3D(Actor akActor)
	int try = 0
	
	While !akActor.Is3DLoaded() && try < 50
		utility.wait(0.2)
		try += 1
	endwhile
	
	if akActor.Is3DLoaded()
		if RSHUM.Verbose
			debug.notification(akActor.getDisplayName() + " has loaded is 3D ")
		endif
	else
		if RSHUM.Verbose
			debug.notification(akActor.getDisplayName() + " failded to loaded is 3D ")
		endif
	endif
EndFunction

; Called when reattaching the rider (after teleport, game load or if a rig refresh is needed)
; Set Immediate true to remove all delays, this uses a second rig for a fast switchover
Function Remount(Actor follower, Actor Playerhorse)
	if (Game.GetPlayer().IsOnMount())
		if (follower != None)
			ClearRig()
			follower.DisableNoWait()
			follower.moveto(Game.GetPlayer(), 0, -250, 0, true)
			follower.Enable()
			follower.SetAlpha(0)
			PillionRider.ForceRefTo(follower)
			SetAnimation(follower)
			follower.EvaluatePackage()
			SetRig(follower.IsChild(), Playerhorse)
			AnimEventFollower(follower, true)
			if follower.GetItemCount(rshHorseQuickStopToken) <= 0
				follower.AddItem(rshHorseQuickStopToken)
			endif
			self.FadeIn(follower)
		endif
	endif
EndFunction

; Dismount follower
; Set quicktop = true if you intend to remount the follower later on
Function Dismount(bool quickStop)
	
	Actor follower = follower3.GetActorRef()
	Actor playerhorse = RshPlayerHorse.GetActorRef()

	ClearRig()

	if (follower != None)	; FIX patch (P-04) : Dismount est aussi appelé quand seul un PNJ porté existe
		follower.RemoveItem(rshHorseQuickStopToken, 999, true)

		follower.ForceAddRagdollToWorld()

		follower.SetMotionType(follower.Motion_Keyframed, false)
		Utility.Wait(0.1)
		follower.SetMotionType(follower.Motion_Character, true)

		follower.Disable()
		Utility.Wait(0.2)
		follower.Enable()
	endif
	
	if (RSHUM.ReversePositions)
		if DismountPlayermountedReversed
			Game.EnablePlayerControls()
			if (follower != None)	; FIX patch (P-04)
				follower.SetHeadTracking(true)
			endif
			Debug.SendAnimationEvent(Game.GetPlayer(), "HorseEnterInstant")		; Get player out of anim as well  in this case
			return
		endif
	endif
	
	UnregisterForKey(Keycode)

	if (DismountedForCombat)
		if (!quickStop)
			; Player dismounts while follower was dismounted for a quick stop, so do some cleanup 	
			DismountedForCombat = false
			UnregisterForAnimationEvent(Game.GetPlayer(), "BeginWeaponSheathe")
			UnregisterForAnimationEvent(Game.GetPlayer(), "Getup")
			UnregisterForAnimationEvent(Game.GetPlayer(), "GetupEnd")
			AnimEventFollower(follower, false)
			if RSHUM.Verbose
				debug.notification("Dismount: quickstop clean up")
			endif
		endif
	endif
	DismountedForCombat = quickStop			; Remember if this is a quickstop for subsequent calls
	
	; Detach follower
	if (follower != None)
		PillionRider.Clear()
		follower.BlockActivation(false)
		follower.EvaluatePackage()
		follower.moveto(playerhorse, 150, 0, 50, true)
		Debug.SendAnimationEvent(follower, "IdleForceDefaultState")
	endif
		
	if (!quickstop)
		UnregisterForAnimationEvent(Game.GetPlayer(), "HorseExit")
		UnregisterForAnimationEvent(Game.GetPlayer(), "tailHorseDismount")	
		UnregisterForAnimationEvent(Game.GetPlayer(), "tailHorseDismountSwim")
		UnregisterForAnimationEvent(Game.GetPlayer(), "BeginWeaponDraw")
		UnregisterForAnimationEvent(Game.GetPlayer(), "BeginWeaponSheathe")
		UnregisterForAnimationEvent(Game.GetPlayer(), "Getup")
		UnregisterForAnimationEvent(Game.GetPlayer(), "LandEnd")
		UnregisterForAnimationEvent(Game.GetPlayer(), "MTState")
		UnregisterForAnimationEvent(Game.GetPlayer(), "HorseLocomotion")
		UnregisterForAnimationEvent(Game.GetPlayer(), "HorseIdle")
		AnimEventFollower(follower, false)
		if (follower != None)					; Need to retry this sometimes.
;			self.FadeOut(follower)
;			Utility.Wait(1)
			Debug.SendAnimationEvent(follower, "IdleForceDefaultState")
			if follower.GetItemCount(rshHorseFriendToken) >= 1
				follower.removeitem(rshHorseFriendToken, 999, true)
				Follower2.Clear()
			endif
			follower.removeitem(rshNPCOnPlayerHorseToken, 999, true)
			; FIX patch (compat NFF) : les followers « always share » (médaillon/dialogue) restent exclus des chevaux NFF
			if (follower.GetItemCount(rshHorseToken) <= 0) && (follower.GetItemCount(rshHorseTokenPlayable) <= 0)
				NFFNoHorse(follower, false)
			endif
			if (playerhorse != None)	; FIX patch (P-04)
				playerhorse.removeitem(rshHorseFollowerToken, 999, true)
			endif
			follower3.Clear()
			PillionRider.Clear()
;			self.FadeIn(follower)
		endif
	endif
EndFunction

Function SetRig(bool isChild, Actor Playerhorse)
	Actor follower = PillionRider.GetActorRef()
	Actor npc = Game.GetPlayer()
		
	rshAuthorizeRide.SetValue(1)
	
	follower.StopCombat()
	follower.StopCombatAlarm()
	follower.SetRestrained(true)

	int h	; Height offset
	int d	; Distance from front rider

	if follower.isChild()
		d = RSHUM.dc		; Kids ride in front
		h = RSHUM.hc
	elseif (mountedReversed)
		d = 0		; Player behind follower
		h = 0
	elseif follower.GetActorBase().GetSex() == 1
		d = RSHUM.df
		h = RSHUM.hf
	else
		d = RSHUM.dh
		h = RSHUM.hh
	endif
	
	
	StartAttachmentFollower(Playerhorse, pinHorseBone, follower, 0, d, h, 0, 0, 0, rshAuthorizeRide)
	
	Utility.Wait(0.1)
	
	follower.SetGhost(true)
	follower.ForceRemoveRagdollFromWorld()
EndFunction

Function ClearRig()
	Actor follower = follower3.GetActorRef()
	rshAuthorizeRide.SetValue(0)
	if (follower != None)	; FIX patch (P-04)
		follower.SetRestrained(false)
		StopAttachmentFollower(follower)
		follower.SetGhost(false)
	endif
EndFunction

Function SetAnimation(Actor follower)
	if !follower
		return
	endif
	; Set the correct mounted idle animations
	if (!follower.IsChild())
		if (!RSHUM.ReversePositions)
			if (IsFemale(follower))
				if (RSHUM.RideSidesaddle)
					if RSHUM.df < -25 || RSHUM.df > 20
						Debug.SendAnimationEvent(follower, "IdleForceDefaultState")
						Utility.wait(0.1)
						Debug.SendAnimationEvent(follower, "rshpsidesd")
						return
					elseif RSHUM.df >= -25 && RSHUM.df <= 20
						Debug.SendAnimationEvent(follower, "IdleForceDefaultState")
						Utility.wait(0.1)
						Debug.SendAnimationEvent(follower, "rshpsides")
						return
					endif
				else
					if RSHUM.df < -25 || RSHUM.df > 20
						Debug.SendAnimationEvent(follower, "IdleForceDefaultState")
						Utility.wait(0.1)
						Debug.SendAnimationEvent(follower, "rshpiniond")
						return
					elseif RSHUM.df >= -25 && RSHUM.df <= 20
						Debug.SendAnimationEvent(follower, "IdleForceDefaultState")
						Utility.wait(0.1)
						Debug.SendAnimationEvent(follower, "rshpinion")
						return
					endif
				endif
			else
				if (RSHUM.RideSidesaddleM)
					if RSHUM.dh < -25 || RSHUM.dh > 20
						Debug.SendAnimationEvent(follower, "IdleForceDefaultState")
						Utility.wait(0.1)
						Debug.SendAnimationEvent(follower, "rshpsidesd")
						return
					elseif RSHUM.dh >= -25 && RSHUM.dh <= 20
						Debug.SendAnimationEvent(follower, "IdleForceDefaultState")
						Utility.wait(0.1)
						Debug.SendAnimationEvent(follower, "rshpsides")
						return
					endif
				else
					if RSHUM.dh < -25 || RSHUM.dh > 20
						Debug.SendAnimationEvent(follower, "IdleForceDefaultState")
						Utility.wait(0.1)
						Debug.SendAnimationEvent(follower, "rshpiniond")
						return
					elseif  RSHUM.dh >= -25 && RSHUM.dh <= 20
						Debug.SendAnimationEvent(follower, "IdleForceDefaultState")
						Utility.wait(0.1)
						Debug.SendAnimationEvent(follower, "rshpinion")
						return
					endif
				endif
			endif
		else
			follower.SetHeadTracking(false)
			Debug.SendAnimationEvent(follower, "horseenterinstant")
			Debug.SendAnimationEvent(Game.GetPlayer(), "rshplayer")
			return
		endif
	else
		Debug.SendAnimationEvent(follower, "rshpchild")
	endif
EndFunction

Function SetAnimationBandit(Actor akactor)
	if !akactor
		return
	endif
	; Set the correct mounted idle animations
	if (akactor.IsDead())
		if akActor.GetItemCount(rshBanditOnPlayerHorseToken) >= 1
			Debug.SendAnimationEvent(akactor, "rshhoDead")
		elseif akActor.GetItemCount(rshBanditOnPlayerToken) >= 1
			Debug.SendAnimationEvent(akactor, "rshpldead")
		endif
	else
		if akActor.GetItemCount(rshBanditOnPlayerHorseToken) >= 1
			if akactor.GetItemCount(rshCarriedAllyToken) >= 1
				Debug.SendAnimationEvent(akactor, "RSHHoAlly")
			else
				Debug.SendAnimationEvent(akactor, "rshbandit")
			endif
		elseif akActor.GetItemCount(rshBanditOnPlayerToken) >= 1
			if akactor.GetItemCount(rshCarriedAllyToken) >= 1
				Debug.SendAnimationEvent(akactor, "RSHPlAlly")
			elseif akactor.GetItemCount(rshCarriedSpouseToken) >= 1 && Game.GetPlayer().IsOnMount() && !(RSHUM.ReversePositions)
				Debug.SendAnimationEvent(akactor, "RSHHoSpouse")
			elseif akactor.GetItemCount(rshCarriedSpouseToken) >= 1 && Game.GetPlayer().IsOnMount() && (RSHUM.ReversePositions)
				Debug.SendAnimationEvent(akactor, "RSHPinionD")
			elseif akactor.GetItemCount(rshCarriedSpouseToken) >= 1
				Debug.SendAnimationEvent(akactor, "RSHPlSpouse")
			elseif akactor.GetItemCount(rshCarriedChildToken) >= 1
				Debug.SendAnimationEvent(akactor, "RSHPlChild")
			else
				Debug.SendAnimationEvent(akactor, "rshbandit")
			endif
		endif
	endif
EndFunction

Event OnAnimationEvent(ObjectReference akSource, string asEventName)
	Actor followerRider = PillionRider.GetActorRef()
	Actor follower = follower3.GetActorRef()
	Actor banditcarried = FollowerBanditCarried.GetActorRef()
	Actor Playerhorse = RSHPlayerHorse.GetActorRef()
	
	if (akSource == followerRider) && (rshAuthorizeRide.GetValue() == 1)
		bool isValidEvent = (asEventName == "IdleForceDefaultState") || \
			(asEventName == "OffsetStop") || \
			(asEventName == "Equiphelmet") || \
			(asEventName == "unequiphelmet") || \
			(asEventName == "Equiphood") || \
			(asEventName == "Equiphands") || \
			(asEventName == "unequiphands") || \
			(asEventName == "Equipcuirass") || \
			(asEventName == "unequipcuirass") || \
			(asEventName == "Equipneck") || \
			(asEventName == "unequipneck") || \
			(asEventName == "equipboots") || \
			(asEventName == "unequipboots") || \
			(asEventName == "equipring") || \
			(asEventName == "IdlePlayer") || \
			(asEventName == "JumpFall") || \
			(asEventName == "JumpLand") || \
			(asEventName == "MotionDrivenIdle")
		if isValidEvent
			SetAnimation(followerRider)
		endif
		return
	endif
	
	if (akSource == banditcarried) && (rshBanditSync.GetValue() == 1)
		bool isValidEvent = (asEventName == "IdleForceDefaultState") || \
			(asEventName == "OffsetStop") || \
			(asEventName == "Equiphelmet") || \
			(asEventName == "unequiphelmet") || \
			(asEventName == "Equiphood") || \
			(asEventName == "Equiphands") || \
			(asEventName == "unequiphands") || \
			(asEventName == "Equipcuirass") || \
			(asEventName == "unequipcuirass") || \
			(asEventName == "Equipneck") || \
			(asEventName == "unequipneck") || \
			(asEventName == "equipboots") || \
			(asEventName == "unequipboots") || \
			(asEventName == "equipring") || \
			(asEventName == "IdlePlayer") || \
			(asEventName == "JumpLand") || \
			(asEventName == "JumpFall") || \
			(asEventName == "MotionDrivenIdle")
			
		if isValidEvent
;			SetAnimationBandit(banditcarried)
		endif
		return
	endif
	
	if (akSource == Game.GetPlayer())
		if (follower == None)
			if RSHUM.Verbose
				debug.notification("RSE : no follower yet")
			endif
			if (asEventName == "tailHorseMount")
				if (!RSHUM.UseHorseMenu)
					RideWithFollower(None)
					return
				endif
			endif
		else
			if RSHUM.Verbose
				debug.notification("RSE : follower found : " + follower.getDisplayName())
			endif
		endif
		
		if ((follower != None) || (banditcarried != None))
			if (asEventName == "BeginWeaponDraw")
				if ((follower.GetItemCount(rshHorseToken) >= 1) || (follower.GetItemCount(rshHorseTokenPlayable) >= 1)) && (RSHUM.ReadyToFight) 
					utility.wait(0.2)
					AnimEventFollower(follower, false)
					Dismount(true)
				endif
				return
			elseif (asEventName == "weaponSheathe")
				if DismountPlayermountedReversed
					DismountPlayermountedReversed = false
					UnregisterForAnimationEvent(Game.GetPlayer(), "weaponSheathe")
					Game.GetPlayer().Dismount()
					Dismount(false)
					return
				endif
			elseif (asEventName == "BeginWeaponSheathe")
				if ((follower.GetItemCount(rshHorseToken) >= 1) || (follower.GetItemCount(rshHorseTokenPlayable) >= 1)) && follower.GetItemCount(rshHorseFriendToken) <= 0
					if (DismountedForCombat)
						utility.wait(4)
						if (DismountedForCombat)			; Check again, it may have been set to false on aother thread. When player dismounts with weapon drawn
							Remount(follower, Playerhorse)
						endif
					endif
				endif
				return
			elseif (asEventName == "tailHorseDismount") || (asEventName == "tailHorseDismountSwim") || (asEventName == "HorseExit")
				mountedReversed = false
				Dismount(false)
;				if (banditcarried != none) && (BanditCarried.GetItemCount(rshBanditOnPlayerHorseToken) > 0) && !banditcarried.IsDead()
;					BanditCarried.ForceAddRagdollToWorld()
;				endif
				return
			elseif (asEventName == "Getup")
				mountedReversed = false
				RegisterForAnimationEvent(Game.GetPlayer(), "GetupEnd")
				Dismount(false)
				return
			elseif (asEventName == "GetupEnd")
				Debug.SendAnimationEvent(Game.GetPlayer(), "IdleForceDefaultState")
				Debug.SendAnimationEvent(follower, "IdleForceDefaultState")
				UnregisterForAnimationEvent(Game.GetPlayer(), "GetupEnd")
				return
			elseif (asEventName == "LandEnd") || (asEventName == "MTState") || (asEventName == "HorseLocomotion") || (asEventName == "HorseIdle")
				if (RSHUM.ReversePositions)
					Debug.SendAnimationEvent(Game.GetPlayer(), "rshplayer")
				endif
				return
			endif
			return
		endif
	endif
EndEvent

Event OnKeyUp(int k, Float HoldTime)
if Game.GetPlayer().IsOnMount() && PillionRider != none && RSHUM.ReversePositions
	if (k == Keycode)
		DismountPlayermountedReversed = true
		UnregisterForAnimationEvent(Game.GetPlayer(), "LandEnd")
		UnregisterForAnimationEvent(Game.GetPlayer(), "MTState")
		UnregisterForAnimationEvent(Game.GetPlayer(), "HorseLocomotion")
		UnregisterForAnimationEvent(Game.GetPlayer(), "HorseIdle")
		Dismount(false)
	endif
endif
EndEvent

Function ManagerDismountReversed()
	DismountPlayermountedReversed = true
	UnregisterForAnimationEvent(Game.GetPlayer(), "LandEnd")
	UnregisterForAnimationEvent(Game.GetPlayer(), "MTState")
	UnregisterForAnimationEvent(Game.GetPlayer(), "HorseLocomotion")
	UnregisterForAnimationEvent(Game.GetPlayer(), "HorseIdle")
	Dismount(false)
EndFunction

; FIX patch (compat NFF) : Nether's Follower Framework donne un cheval aux followers sauf s'ils sont dans
; nwsFF_NoHorseFac (0x153FBE). Le MCM de NFF utilise aussi cette faction comme réglage par follower : RSE marque
; ses propres ajouts avec un rang dédié et ne retire QUE ceux-là. Dépendance souple : sans NFF, rien ne se passe.
Function NFFNoHorse(Actor akActor, bool abExclude) global
	if (akActor == None) || (Game.GetModByName("nwsFollowerFramework.esp") == 255)
		return
	endif
	Faction noHorseFac = Game.GetFormFromFile(0x153FBE, "nwsFollowerFramework.esp") as Faction
	if noHorseFac == None
		return
	endif
	int rseRank = 77	; marque « ajouté par RSE »
	if abExclude
		if !akActor.IsInFaction(noHorseFac)
			akActor.AddToFaction(noHorseFac)
			akActor.SetFactionRank(noHorseFac, rseRank)
		endif
	elseif akActor.IsInFaction(noHorseFac) && (akActor.GetFactionRank(noHorseFac) == rseRank)
		akActor.RemoveFromFaction(noHorseFac)
	endif
EndFunction

bool Function IsFemale(Actor a)
	ActorBase b = a.GetActorBase()
	if (b != None)
		return (b.GetSex() == 1)
	else
		return false
	endif
EndFunction

Function AnimEventFollower(Actor akActor, bool Register)
	if (akActor == None)	; FIX patch (P-04) : 18 (dés)inscriptions sur None à chaque descente sans follower
		return
	endif
	If Register
		RegisterForAnimationEvent(akActor, "IdleForceDefaultState")
		RegisterForAnimationEvent(akActor, "OffsetStop")
		RegisterForAnimationEvent(akActor, "Equiphelmet")
		RegisterForAnimationEvent(akActor, "Equiphood")
		RegisterForAnimationEvent(akActor, "Equiphands")
		RegisterForAnimationEvent(akActor, "Equipcuirass")
		RegisterForAnimationEvent(akActor, "Equipneck")
		RegisterForAnimationEvent(akActor, "equipboots")
		RegisterForAnimationEvent(akActor, "equipring")
		RegisterForAnimationEvent(akActor, "unequiphelmet")
		RegisterForAnimationEvent(akActor, "unequiphands")
		RegisterForAnimationEvent(akActor, "unequipcuirass")
		RegisterForAnimationEvent(akActor, "unequipneck")
		RegisterForAnimationEvent(akActor, "unequipboots")
		RegisterForAnimationEvent(akActor, "IdlePlayer")
		RegisterForAnimationEvent(akActor, "JumpFall")
		RegisterForAnimationEvent(akActor, "JumpLand")
		RegisterForAnimationEvent(akActor, "MotionDrivenIdle")
	else
		UnregisterForAnimationEvent(akActor, "IdleForceDefaultState")
		UnregisterForAnimationEvent(akActor, "OffsetStop")
		UnregisterForAnimationEvent(akActor, "Equiphelmet")
		UnregisterForAnimationEvent(akActor, "Equiphood")
		UnregisterForAnimationEvent(akActor, "Equiphands")
		UnregisterForAnimationEvent(akActor, "Equipcuirass")
		UnregisterForAnimationEvent(akActor, "Equipneck")
		UnregisterForAnimationEvent(akActor, "equipboots")
		UnregisterForAnimationEvent(akActor, "equipring")
		UnregisterForAnimationEvent(akActor, "unequiphelmet")
		UnregisterForAnimationEvent(akActor, "unequiphands")
		UnregisterForAnimationEvent(akActor, "unequipcuirass")
		UnregisterForAnimationEvent(akActor, "unequipneck")
		UnregisterForAnimationEvent(akActor, "unequipboots")
		UnregisterForAnimationEvent(akActor, "IdlePlayer")
		UnregisterForAnimationEvent(akActor, "JumpFall")
		UnregisterForAnimationEvent(akActor, "JumpLand")
		UnregisterForAnimationEvent(akActor, "MotionDrivenIdle")
	endif
EndFunction

Event OnMenuClose(String MenuName)
	If MenuName == "Loading Menu"
		; Le joueur vient de faire une transition d'environnement
		
		if RSHUM.Verbose
			Debug.Notification("Debug: Transition avec chargement detectee !")
		endif

		FastTravelNPC()

	EndIf
EndEvent

Function BringActorToPlayer()
	Actor bandit = FollowerBandit.GetActorRef()
	Actor banditcarried = FollowerBanditCarried.GetActorRef()
	Actor player = Game.GetPlayer()

;	Utility.wait(2)
	
	if BanditCarried.GetItemCount(rshBanditOnPlayerToken)		
		rshBanditSync.SetValue(0)
		StopAttachmentPlayer(banditcarried)
		banditcarried.MoveTo(rshXmarkerRef, 0, 0, 0, true)
		Utility.wait(0.1)
		rshXmarkerRefDrop.MoveTo(Game.GetPlayer(), 0, 100, 50, true)
		banditcarried.SetAlpha(0)
		banditcarried.MoveTo(rshXmarkerRefDrop, 0, 0, 0, true)
		banditcarried.ForceAddRagdollToWorld()
		banditcarried.SetMotionType(banditcarried.Motion_Keyframed, false)
		Utility.Wait(0.1)
		if banditcarried.IsDead()
			banditcarried.SetMotionType(banditcarried.Motion_Dynamic, true)
		else
			banditcarried.SetMotionType(banditcarried.Motion_Character, true)
			banditcarried.Disable()
			Utility.Wait(0.2)
			banditcarried.Enable()
		endif
		
		FollowerBanditCarried.Clear()
		Utility.wait(0.1)
		FollowerBanditCarried.ForceRefTo(bandit)
		
		banditcarried.BlockActivation(true)
		if !banditcarried.IsDead()
			banditcarried.SetRestrained(false)
			SetAnimationBandit(banditcarried)
			banditcarried.EvaluatePackage()
		else
			SetAnimationBandit(banditcarried)
		endif
		
		rshBanditSync.SetValue(1)
		RSHINV.AttachmentPlayer(banditcarried, player)
		banditcarried.ForceRemoveRagdollFromWorld()
		Utility.wait(0.5)
		banditcarried.SetAlpha(1)
	endif
	
	Utility.wait(0.2)
	
	if !BanditCarried.Is3DLoaded()
		If !TryAgain
			TryAgain = true
			if RSHUM.Verbose
				debug.notification(banditcarried.getDisplayName() + " try again before getting released")
			endif
			BringActorToPlayer()
			return
		else
			BringMissingActor()
		endif
	endif
	
	TryAgain = false
EndFunction

Function FastTravelNPC()
	Actor follower = follower3.getActorRef()
	Actor BanditCarried = FollowerBanditCarried.GetActorRef()
	Actor player = Game.GetPlayer()
	UpdatePlayerHorse()
	Actor playerHorse = RSHPlayerHorse.GetActorRef()
	
	; FIX patch (P-04) : appelé à chaque écran de chargement, sans cheval ni PNJ porté → erreurs sur None
	bool horseHasFollower = (playerHorse != None) && (playerHorse.GetItemCount(rshHorseFollowerToken) > 0)
	if ((player.IsOnMount()) && (!DismountedForCombat)) || horseHasFollower
		if (follower != None)
			RemountOnTeleport(follower, Playerhorse)
		endif
	elseif !(player.IsOnMount()) && (follower != none)
		utility.wait(3)						; Allow time after teleport
		Dismount(false)
	endif
	
	if (BanditCarried == None)	; FIX patch (P-04) : personne n'est porté
		return
	endif
	if BanditCarried.GetItemCount(rshBanditOnPlayerToken)
		if RSHUM.Verbose
			debug.notification(BanditCarried.getDisplayName() + " fast traveled on "  + player.getDisplayName())
		endif
		BringActorToPlayer()
	else
		if (playerHorse != None) && !(playerHorse.IsDead()) && (BanditCarried.GetItemCount(rshBanditOnPlayerHorseToken) > 0)
			if RSHUM.Verbose
				debug.notification(BanditCarried.getDisplayName() + " fast traveled on "  + playerHorse.getDisplayName())
			endif
			ManageCarriedBanditTeleport(playerHorse, pinHorseBone, BanditCarried, 0, RSHUM.db, RSHUM.hb, 0, 0, 0, false)
		endif
	endif
EndFunction

Function FastTravelNPCS()
	Actor follower = follower3.getActorRef()
	Actor BanditCarried = FollowerBanditCarried.GetActorRef()
	Actor player = Game.GetPlayer()
	Actor playerHorse = RSHPlayerHorse.GetActorRef()
	
	; FIX patch (P-04) : appelé à chaque écran de chargement, sans cheval ni PNJ porté → erreurs sur None
	bool horseHasFollower = (playerHorse != None) && (playerHorse.GetItemCount(rshHorseFollowerToken) > 0)
	if ((player.IsOnMount()) && (!DismountedForCombat)) || horseHasFollower
		if (follower != None)
			RemountOnTeleport(follower, Playerhorse)
			if RSHUM.ReversePositions
				Keycode = Input.GetMappedKey("Activate")
				RegisterForKey(Keycode)
				mountedReversed = true
				RegisterForAnimationEvent(Game.GetPlayer(), "weaponSheathe")
				RegisterForAnimationEvent(Game.GetPlayer(), "LandEnd")
				RegisterForAnimationEvent(Game.GetPlayer(), "MTState")
				RegisterForAnimationEvent(Game.GetPlayer(), "HorseLocomotion")
				RegisterForAnimationEvent(Game.GetPlayer(), "HorseIdle")
			else
				RegisterForAnimationEvent(Game.GetPlayer(), "HorseExit")
				RegisterForAnimationEvent(Game.GetPlayer(), "tailHorseDismount")
				RegisterForAnimationEvent(Game.GetPlayer(), "tailHorseDismountSwim")
				RegisterForAnimationEvent(Game.GetPlayer(), "Getup")
			endif
		endif
	elseif !(player.IsOnMount()) && (follower != none)
		utility.wait(3)						; Allow time after teleport
		Dismount(false)
	endif
	
	if (BanditCarried == None)	; FIX patch (P-04) : personne n'est porté
		return
	endif
	if BanditCarried.GetItemCount(rshBanditOnPlayerToken)
		if RSHUM.Verbose
			debug.notification(BanditCarried.getDisplayName() + " fast traveled on "  + player.getDisplayName())
		endif
		BringActorToPlayer()
	else
		if (playerHorse != None) && !(playerHorse.IsDead()) && (BanditCarried.GetItemCount(rshBanditOnPlayerHorseToken) > 0)
			if RSHUM.Verbose
				debug.notification(BanditCarried.getDisplayName() + " fast traveled on "  + playerHorse.getDisplayName())
			endif
			ManageCarriedBanditTeleport(playerHorse, pinHorseBone, BanditCarried, 0, RSHUM.db, RSHUM.hb, 0, 0, 0, false)
		endif
	endif
EndFunction

Function ManageCarriedBanditTeleport(Actor aktarget, string nodeName, Actor akActor, float offsetX, float offsetY, float offsetZ, float rotationX, float rotationY, float rotationZ, bool IsPlayer)
	if RSHUM.Verbose
		debug.notification(akActor.getDisplayName() + "Fast travel started")
	endif
	
	if tentative == 0
		tentative = 1
		TryToLoadActor3D(akActor, aktarget)
		
		While !(akActor.Is3DLoaded()) && tentative < 6
			TryToLoadActor3D(akActor, aktarget)
			tentative += 1
		endwhile
		
		;utility.wait(10) ;wait all potential atempt to finish
		if !(akActor.Is3DLoaded()) || tentative > 5
		
			tentative = 0
			if RSHUM.Verbose
				debug.notification(akActor.getDisplayName() + " Too many atempt to load 3D, operation terminated")
			endif
			BringMissingActor()
			return
		endif
			
		tentative = 0
		
		SetAnimationBandit(akActor)
		akActor.EvaluatePackage()
		akActor.ForceRemoveRagdollFromWorld()
		
		if RSHUM.Verbose
			debug.notification(akActor.getDisplayName() + " 3D loaded")
		endif
	endif
EndFunction

Function TryToLoadActor3D(Actor akActor, Actor aktarget)
		if RSHUM.Verbose
			debug.notification(akActor.getDisplayName() + "No 3D Yet")
		endif
		rshBanditSync.SetValue(0)
		if akActor.IsDead()
			StopAttachmentHorse(akActor)
;			StopAttachmentPlayer(akActor)
			DeadHorse(aktarget, akActor)
		else
			StopAttachmentHorse(akActor)
			AliveHorse(aktarget, akActor)
		endif
		if RSHUM.Verbose
			debug.notification(akActor.getDisplayName() + " try to load 3D")
		endif
		utility.wait(5)
EndFunction

Function DeadHorse(Actor aktarget, Actor akActor)
	Actor bandit = FollowerBandit.GetActorRef()
	
	akActor.MoveTo(rshXmarkerRef, 0, 0, 0, true)
	Utility.wait(0.1)
	rshXmarkerRefDrop.MoveTo(aktarget, 0, 250, 50, true)
	akActor.MoveTo(rshXmarkerRefDrop, 0, 0, 0, true)
	akActor.SetAlpha(0)
	akActor.ForceAddRagdollToWorld()
	akActor.SetMotionType(akActor.Motion_Keyframed, false)
	Utility.Wait(0.1)
	akActor.SetMotionType(akActor.Motion_Dynamic, true)
	FollowerBanditCarried.Clear()
	Utility.wait(0.1)
	FollowerBanditCarried.ForceRefTo(bandit)
	akActor.BlockActivation(true)
	rshBanditSync.SetValue(1)
	StartAttachmentHorse(aktarget, pinHorseBone, akActor, 0, RSHUM.db, RSHUM.hb, 0, 0, 0, rshBanditSync)
;	StartAttachmentPlayer(aktarget, pinHorseBone, akActor, 0, RSHUM.db, RSHUM.hb, 0, 0, 0, rshBanditSync, false)
	SetAnimationBandit(akActor)
	Utility.wait(0.2)
	akActor.ForceRemoveRagdollFromWorld()
	akActor.SetAlpha(1)
EndFunction

Function AliveHorse(Actor aktarget, Actor akActor)
	akActor.SetRestrained(false)
	akActor.SetGhost(false)
	akActor.DisableNoWait()
	akActor.MoveTo(Game.GetPlayer(), 0, -500, 0, true)
	akActor.Enable()
	WaitActor3D(akActor)
	akActor.SetAlpha(0)
	akActor.BlockActivation(true)
	utility.wait(0.1)
	SetAnimationBandit(akActor)
	akActor.EvaluatePackage()
	rshBanditSync.SetValue(1)
	StartAttachmentHorse(aktarget, pinHorseBone, akActor, 0, RSHUM.db, RSHUM.hb, 0, 0, 0, rshBanditSync)
	Utility.Wait(0.1)
	akActor.SetGhost(true)
	akActor.ForceRemoveRagdollFromWorld()
	Utility.wait(0.15)
	self.FadeIn(akActor)
EndFunction

Function BringMissingActor()
	Actor bandit = FollowerBandit.GetActorRef()
	Actor banditcarried = FollowerBanditCarried.GetActorRef()
	
	rshBanditSync.SetValue(0)
	banditcarried.BlockActivation(false)
	StopAttachmentPlayer(banditcarried)
	StopAttachmentHorse(banditcarried)
	Game.GetPlayer().RemoveItem(rshBanditOnPlayerToken, 999, true)
	BanditCarried.RemoveItem(rshBanditOnPlayerToken, 999, true)
	banditcarried.RemoveItem(rshBanditOnPlayerHorseToken, 999, true)
	banditcarried.RemoveItem(rshHorseFriendToken, 999, true)
	banditcarried.RemoveItem(rshHorseCrimeToken, 999, true)
	banditcarried.RemoveItem(rshCarriedAllyToken, 999, true)
	banditcarried.RemoveFromFaction(rshCarriedFaction)
	bandit.RemoveItem(rshHorseFriendToken, 999, true)
	bandit.RemoveItem(rshHorseCrimeToken, 999, true)
	banditcarried.MoveTo(rshXmarkerRef, 0, 0, 0, true)
	Utility.wait(0.1)
	rshXmarkerRefDrop.MoveTo(Game.GetPlayer(), 0, 100, 50, true)
	banditcarried.SetAlpha(0)
	banditcarried.MoveTo(rshXmarkerRefDrop, 0, 0, 0, true)
	banditcarried.ForceAddRagdollToWorld()
	banditcarried.SetMotionType(banditcarried.Motion_Keyframed, false)
	Utility.Wait(0.1)
	if banditcarried.IsDead()
		banditcarried.SetMotionType(banditcarried.Motion_Dynamic, true)
	else
		banditcarried.SetMotionType(banditcarried.Motion_Character, true)
		banditcarried.Disable()
		Utility.Wait(0.2)
		banditcarried.Enable()
	endif
	FadeIn(banditcarried)
	
	FollowerBanditCarried.Clear()
	FollowerBandit.Clear()
	
	Game.EnablePlayerControls()
	
	if RSHUM.Verbose
		debug.notification("Missing actor found, look around")
	endif
	
Endfunction

function FadeIn(actor a)
	a.SetAlpha(0.1)
	utility.Wait(0.01)
	a.SetAlpha(0.2)
	utility.Wait(0.01)
	a.SetAlpha(0.3)
	utility.Wait(0.01)
	a.SetAlpha(0.4)
	utility.Wait(0.01)
	a.SetAlpha(0.5)
	utility.Wait(0.01)
	a.SetAlpha(0.6)
	utility.Wait(0.01)
	a.SetAlpha(0.7)
	utility.Wait(0.01)
	a.SetAlpha(0.8)
	utility.Wait(0.01)
	a.SetAlpha(0.9)
	utility.Wait(0.01)
	a.SetAlpha(1)
endFunction

function FadeOut(actor a)
	a.SetAlpha(0.9)
	utility.Wait(0.01)
	a.SetAlpha(0.8)
	utility.Wait(0.01)
	a.SetAlpha(0.7)
	utility.Wait(0.01)
	a.SetAlpha(0.6)
	utility.Wait(0.01)
	a.SetAlpha(0.5)
	utility.Wait(0.01)
	a.SetAlpha(0.4)
	utility.Wait(0.01)
	a.SetAlpha(0.3)
	utility.Wait(0.01)
	a.SetAlpha(0.2)
	utility.Wait(0.01)
	a.SetAlpha(0.1)
	utility.Wait(0.01)
	a.SetAlpha(0)
endFunction

bool Property DismountedForCombat Auto Conditional	; True if follower dismounted for combat
bool Property DismountPlayerMountedReversed auto	; True to properly dismount the player when he ride behind
bool Property mountedReversed auto					; True if player mounted behind follower
bool TryAgain = false

float Property WeaponDrawDistance Auto				; Used to store current game setting for this var, since we change it during riding

int tentative = 0

Int Property Keycode Auto							; Keycode to dismount when player ride behind

MiscObject Property rshCarriedSpouseToken Auto
MiscObject Property rshCarriedChildToken Auto
MiscObject Property rshCarriedAllyToken Auto
MiscObject Property rshHorseFriendToken Auto			; Token for friendly npc (include followers)
MiscObject Property rshHorseCrimeToken Auto				; Token for bandit npc
MiscObject Property rshHorseQuickStopToken Auto			; Token for dismounted followers during fight
MiscObject Property rshHorseToken Auto					; Token for followers
MiscObject Property rshHorseTokenPlayable Auto			; Craftable Token for followers
MiscObject Property rshBanditOnPlayerToken Auto			; Token for bandits when carried by the player
MiscObject Property rshBanditOnPlayerHorseToken Auto	; Token for bandits when settled on the horse back
MiscObject Property rshNPCOnPlayerHorseToken Auto
MiscObject Property rshHorseFollowerToken Auto

ObjectReference property rshXmarkerRef Auto				; Marker to move corps to avoid the nude bug
ObjectReference property rshXmarkerRefDrop Auto			; Marker to move corps to avoid the nude bug

GlobalVariable Property rshBanditSync Auto				; Variable to authorize movement per frame for bandits
GlobalVariable property rshAuthorizeRide Auto			; Variable to authorize movement per frame for followers

Faction Property rshCarriedFaction Auto
Faction Property CurrentFollowerFaction Auto
Faction Property PotentialFollowerFaction Auto

Perk property RideSharePerk Auto					; Perk to active the pop up menu when activating a horse

Quest property rshTracker auto						; Quest to find the closest authorized follower to mount

ReferenceAlias Property PillionRider Auto			; Alias ref for the current second rider
ReferenceAlias Property Follower1 Auto				; Alias ref for a follower with medaillon
ReferenceAlias Property Follower1NoToken Auto		; Alias ref for a follower without medaillon (Horse menu)
ReferenceAlias Property Follower2 Auto				; Alias ref for a friendly npc invited
ReferenceAlias Property Follower3 Auto				; Alias ref to determine priority between followers and friendly npc
ReferenceAlias property RSHPlayerHorse auto			; Alias ref for the current player's horse
ReferenceAlias Property FollowerBandit Auto			; Alias ref for the captured bandit
ReferenceAlias Property FollowerBanditCarried Auto	; Alias ref for the captured bandit settled on the horse

string pinNPCBone = "NPC Spine2 [Spn2]"				; String for the player bone
string pinHorseBone = "SaddleBone"					; String for the player's horse bone

rshUpdateManagerScript Property RSHUM auto
rshInviteScript Property RSHINV auto
