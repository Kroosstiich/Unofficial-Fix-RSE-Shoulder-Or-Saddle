Scriptname rshinvitescript extends Quest  

Import RSEPlayerSKSE
Import RSEHorseSKSE

; Properties

Faction Property rshCarriedFaction Auto

GlobalVariable Property rshBanditSync Auto

Message Property RSHFollowerMessage Auto
Message Property RSHDeadCorpsMessage Auto
Message Property RSHUnFollowMessage Auto
Message Property RSHUnFollowOrCarryMessage Auto
Message Property RSHSpecialMessage Auto

MiscObject Property rshCarriedBridalToken Auto
MiscObject Property rshCarriedShouldersToken Auto
MiscObject Property rshCarriedAllyToken Auto
MiscObject Property rshHorseFriendToken Auto
MiscObject Property rshHorseCrimeToken Auto
MiscObject Property rshBanditOnPlayerToken Auto
MiscObject Property rshBanditOnPlayerHorseToken Auto
MiscObject Property rshHorseBanditToken Auto

ObjectReference property rshXmarkerRef Auto
ObjectReference property rshXmarkerRefDrop Auto

ReferenceAlias Property Follower2 Auto
ReferenceAlias Property FollowerBandit Auto
ReferenceAlias Property FollowerBanditCarried Auto
ReferenceAlias Property RSHPlayerHorse Auto

rshCoreScript Property RSHCS auto
rshUpdateManagerScript Property RSHUM auto

Int X = -24
Int Y = -10
Int Z = 23
float RX = 0.0
float RY = 0.0;78539805
float RZ = -1.75;1.5707961

string pinNPCBone = "NPC Spine2 [Spn2]"
string pinHorseBone = "SaddleBone"
string pinNPCNeckBone = "NPC Neck [Neck]"

Event OnAnimationEvent(ObjectReference akSource, string asEventName)
	if (akSource == Game.GetPlayer())
		Actor banditcarried = FollowerBanditCarried.GetActorRef()
		if banditcarried == None	; FIX patch (P-04) : personne n'est porté → rien à faire (évitait des erreurs à chaque montée/descente)
			return
		endif
		if (asEventName == "tailHorseMount")
			if banditcarried.GetItemCount(rshCarriedBridalToken) >= 1 && !(RSHUM.ReversePositions)
				StopAttachmentPlayer(banditcarried)
				StartAttachmentHorse(Game.GetPlayer(), pinNPCBone, banditcarried, 0.0, 25, -13, 0.0, 0.0, 0.0, rshBanditSync)
				banditcarried.ForceRemoveRagdollFromWorld()
				RSHCS.SetAnimationBandit(banditcarried)
				banditcarried.EvaluatePackage()
			elseif banditcarried.GetItemCount(rshCarriedBridalToken) >= 1 && (RSHUM.ReversePositions)
				StopAttachmentPlayer(banditcarried)
				StartAttachmentHorse(Game.GetPlayer(), "NPC COM [COM ]", banditcarried, 0.0, -30, 0.0, 0.0, 0.0, 0.0, rshBanditSync)
				banditcarried.ForceRemoveRagdollFromWorld()
				RSHCS.SetAnimationBandit(banditcarried)
				banditcarried.EvaluatePackage()
			endif
;			RegisterForAnimationEvent(Game.GetPlayer(), "HorseExit")
;			RegisterForAnimationEvent(Game.GetPlayer(), "tailHorseDismount")
;			RegisterForAnimationEvent(Game.GetPlayer(), "tailHorseDismountSwim")
;			RegisterForAnimationEvent(Game.GetPlayer(), "Getup")
		elseif (asEventName == "HorseExit") || (asEventName == "tailHorseDismount") || (asEventName == "tailHorseDismountSwim") || (asEventName == "Getup")
			if banditcarried.GetItemCount(rshCarriedBridalToken) >= 1
				Utility.wait(1)
				StopAttachmentHorse(banditcarried)
				AttachmentPlayer(banditcarried, Game.GetPlayer())
				RSHCS.SetAnimationBandit(banditcarried)
				banditcarried.EvaluatePackage()
			endif
;			UnregisterForAnimationEvent(Game.GetPlayer(), "HorseExit")
;			UnregisterForAnimationEvent(Game.GetPlayer(), "tailHorseDismount")
;			UnregisterForAnimationEvent(Game.GetPlayer(), "tailHorseDismountSwim")
;			UnregisterForAnimationEvent(Game.GetPlayer(), "Getup")
		endif
	endif
EndEvent

; Gestion des cibles vivantes
Function HandleLivingTarget(Actor aktarget)
	Actor follower2Actor = Follower2.GetActorRef()
	Actor banditActor = FollowerBandit.GetActorRef()
	
	; Cas 1: Nouveau passager
	if aktarget != follower2Actor && aktarget != banditActor
		HandleNewPassenger(aktarget)
		
	; Cas 2: Passager ami existant
	elseif aktarget == follower2Actor
		HandleExistingFollower(follower2Actor)
		
	; Cas 3: Passager bandit existant
	elseif aktarget == banditActor
		HandleExistingBandit(banditActor)
	endif
EndFunction

; Gestion d'un nouveau passager
Function HandleNewPassenger(Actor aktarget)
if aktarget.GetRelationshipRank(Game.GetPlayer()) > 0
	int choice = RSHSpecialMessage.Show()
	
	if choice == 0 ;MENU_OPTION_FOLLOWER
		SetPassenger(Follower2, aktarget, rshHorseFriendToken, "Passenger")
		
	elseif choice == 1 ;MENU_OPTION_BANDIT
		SetPassenger(FollowerBandit, aktarget, rshHorseCrimeToken, "Captured passenger")
		
	elseif choice == 2 ;MENU_OPTION_CARRY
		LivingTarget(aktarget)
		
	elseif choice == 3 ;MENU_OPTION_BRIDAL_CARRY
		SpecialTarget(aktarget, "bridal")
		
	elseif choice == 4 ;MENU_OPTION_SHOULDERS_CARRY
		SpecialTarget(aktarget, "shoulders")
		
	elseif choice == 5 ;MENU_OPTION_CANCEL ;-> Ne rien faire
		return
	endif
else
	int choice = RSHFollowerMessage.Show()
	
	if choice == 0 ;MENU_OPTION_FOLLOWER
		SetPassenger(Follower2, aktarget, rshHorseFriendToken, "Passenger")
		
	elseif choice == 1 ;MENU_OPTION_BANDIT
		SetPassenger(FollowerBandit, aktarget, rshHorseCrimeToken, "Captured passenger")
		
	elseif choice == 2 ;MENU_OPTION_CARRY
		LivingTarget(aktarget)
		
	elseif choice == 3 ;MENU_OPTION_CANCEL ;-> Ne rien faire
		return
	endif
endif
EndFunction

; Gestion d'un passager ami existant
Function HandleExistingFollower(Actor follower)
	int choice = RSHUnFollowMessage.Show()
	
	if choice == 0 ; Libérer
		ClearPassenger(Follower2, follower)
	endif
EndFunction

; Gestion d'un passager bandit existant
Function HandleExistingBandit(Actor aktarget)
	int choice = RSHUnFollowOrCarryMessage.Show()
	Actor player = Game.GetPlayer()

	if choice == 0 ; Libérer
		ClearPassenger(FollowerBandit, aktarget)
		FollowerBanditCarried.Clear()
		rshBanditSync.SetValue(0)
		aktarget.RemoveItem(rshBanditOnPlayerToken, 999, true)
		aktarget.RemoveItem(rshBanditOnPlayerHorseToken, 999, true)
		player.RemoveItem(rshBanditOnPlayerToken, 999, true)
		aktarget.BlockActivation(false)	; FIX patch (P-05) : PNJ relâché de nouveau activable
		aktarget.RemoveFromFaction(rshCarriedFaction)	; FIX patch : ne reste pas allié au joueur après libération
		RemoveAddonCuffs(aktarget)	; FIX patch (P-08)
		Debug.SendAnimationEvent(aktarget, "IdleForceDefaultState")
		
	elseif choice == 1 ; Porter sur soi
		LivingTarget(aktarget)
	endif
EndFunction

; Gestion des cibles mortes
Function HandleDeadTarget(Actor aktarget)
	int choice = RSHDeadCorpsMessage.Show()
	Actor player = Game.GetPlayer()

	if choice == 0 ; Transporter le corps
		SetPassenger(FollowerBandit, aktarget, rshHorseCrimeToken, "")
		
	elseif choice == 1 ; Porter le corps sur soi
		DeadTarget(aktarget)
	endif
EndFunction

; Fonction utilitaire: Définir un passager
Function SetPassenger(ReferenceAlias akalias, Actor newPassenger, MiscObject token, string notificationPrefix)
	Actor oldPassenger = akalias.GetActorRef()
	
	; Nettoyer l'ancien passager
	if oldPassenger
		oldPassenger.RemoveItem(rshHorseFriendToken, 999, true)
		oldPassenger.RemoveItem(rshHorseCrimeToken, 999, true)
	endif
	
	Utility.Wait(0.1)
	akalias.Clear()
	Utility.Wait(0.1)
	
	; Assigner le nouveau passager
	akalias.ForceRefTo(newPassenger)
	newPassenger.AddItem(token, 1, true)
	if RSHUM.Verbose
		if notificationPrefix != ""
			Debug.Notification(notificationPrefix + " : " + newPassenger.GetDisplayName())
		endif
	endif
EndFunction

; Fonction utilitaire: Libérer un passager
Function ClearPassenger(ReferenceAlias akalias, Actor passenger)
	passenger.RemoveItem(rshHorseFriendToken, 999, true)
	passenger.RemoveItem(rshHorseCrimeToken, 999, true)
	akalias.Clear()
EndFunction

; Cas 1: Bandit sur cheval -> Passer au joueur
Function Cas1(Actor banditcarried, Actor playerHorse, Actor player)
	if player.IsWeaponDrawn()
		player.SheatheWeapon()
		return
	endif
	if rshFixOptions.ForceThirdPersonOnPickup()	; FIX patch : vue 3e personne au portage (option FOMOD)
		Game.ForceThirdPerson()
	endif
	
	Game.DisablePlayerControls()
	Debug.SendAnimationEvent(player, "idlepray")
	banditcarried.RemoveItem(rshBanditOnPlayerHorseToken, 999, true)
	playerHorse.RemoveItem(rshHorseBanditToken, 999, true)
	banditcarried.AddItem(rshBanditOnPlayerToken, 1, true)
	player.AddItem(rshBanditOnPlayerToken, 1, true)
	StopAttachmentHorse(banditcarried)
	if (banditcarried.IsDead())
		banditcarried.SetMotionType(banditcarried.Motion_Keyframed, false)
		Utility.Wait(0.1)
		banditcarried.SetMotionType(banditcarried.Motion_Dynamic, true)
	endif
	AttachmentPlayer(banditcarried, player)
	RSHCS.SetAnimationBandit(banditcarried)
	banditcarried.EvaluatePackage()
	if RSHUM.Verbose
		Debug.Notification(banditcarried.GetDisplayName() + " transfered to me " + player.GetDisplayName())
	endif
	banditcarried.ForceRemoveRagdollFromWorld()
	Utility.Wait(1.4)
	Debug.SendAnimationEvent(player, "IdleForceDefaultState")
	Game.EnablePlayerControls()
;	Game.DisablePlayerControls(false, false, false, false, True, false, false, false)
EndFunction

; Cas 2: Bandit sur joueur -> Attacher bandit au cheval
Function Cas2(Actor banditcarried, Actor playerHorse, Actor player)
if banditcarried.GetItemCount(rshCarriedShouldersToken) >= 1 || banditcarried.GetItemCount(rshCarriedBridalToken) >= 1
	Debug.Notification(banditcarried.GetDisplayName() + " doesn't want to leave you ")
else
	if player.IsWeaponDrawn()
		player.SheatheWeapon()
		return
	endif
	
	Game.DisablePlayerControls()
	Debug.SendAnimationEvent(player, "idlepray")
	player.RemoveItem(rshBanditOnPlayerToken, 999, true)
	banditcarried.RemoveItem(rshBanditOnPlayerToken, 999, true)
	banditcarried.AddItem(rshBanditOnPlayerHorseToken)
	playerHorse.AddItem(rshHorseBanditToken)
	StopAttachmentPlayer(banditcarried)
	StartAttachmentHorse(playerHorse, pinHorseBone, banditcarried, 0, RSHUM.db, RSHUM.hb, 0, 0, 0, rshBanditSync)
	RSHCS.SetAnimationBandit(banditcarried)
	banditcarried.EvaluatePackage()
	; FIX patch (N-21) : la monture attaquait le captif hostile posé sur son dos
	banditcarried.StopCombat()
	playerHorse.StopCombat()
	if RSHUM.Verbose
		Debug.Notification(banditcarried.GetDisplayName() + " transfered to my mount " + playerHorse.GetDisplayName())
	endif
	Utility.Wait(1.4)
	Debug.SendAnimationEvent(player, "IdleForceDefaultState")
	Game.EnablePlayerControls()
endif
EndFunction

; Cas 4: Déposer le bandit/corps au sol
Function Cas4(Actor bandit, Actor banditcarried, Actor player)
	if player.IsWeaponDrawn()
		player.SheatheWeapon()
		return
	endif

	RSHCS.FadeOut(banditcarried)
	Debug.SendAnimationEvent(player, "idlepickup_ground")
	rshBanditSync.SetValue(0)
	banditcarried.BlockActivation(false)	; FIX patch (P-05) : toujours rendre le PNJ/cadavre activable au dépôt
	if banditcarried.GetItemCount(rshBanditOnPlayerToken) >= 1
		banditcarried.ForceAddRagdollToWorld()
	endif
	banditcarried.RemoveItem(rshBanditOnPlayerToken, 999, true)
	banditcarried.RemoveItem(rshCarriedAllyToken, 999, true)
	banditcarried.RemoveItem(rshCarriedShouldersToken, 999, true)
	banditcarried.RemoveFromFaction(rshCarriedFaction)
	RemoveAddonCuffs(banditcarried)	; FIX patch (P-08)
	player.RemoveItem(rshBanditOnPlayerToken, 999, true)
	player.RemoveItem(rshCarriedBridalToken, 999, true)
	player.RemoveItem(rshCarriedShouldersToken, 999, true)
	StopAttachmentPlayer(banditcarried)
	RSHCS.FadeIn(banditcarried)
	banditcarried.SetRestrained(false)
	if (banditcarried.IsDead())
		banditcarried.MoveTo(rshXmarkerRef, 0, 0, 0, true)
		Utility.Wait(0.1)
		rshXmarkerRefDrop.MoveTo(Game.GetPlayer(), 0, 0, 50, true)
		banditcarried.MoveTo(rshXmarkerRefDrop, 0, 0, 0, true)
		banditcarried.SetMotionType(banditcarried.Motion_Keyframed, false)
		Utility.Wait(0.1)
		banditcarried.SetMotionType(banditcarried.Motion_Dynamic, true)
	else
		if banditcarried.GetItemCount(rshCarriedBridalToken) >= 1
			banditcarried.RemoveItem(rshCarriedBridalToken, 999, true)
			banditcarried.SetMotionType(banditcarried.Motion_Keyframed, false)
			Utility.Wait(0.1)
			banditcarried.SetMotionType(banditcarried.Motion_Dynamic, true)
			banditcarried.Disable()
			Utility.Wait(0.2)
			banditcarried.Enable()
		else
			RSHCS.AnimEventFollower(banditcarried, false)
			banditcarried.PushActorAway(banditcarried, 0.0)
		endif
	endif
	banditcarried.SetGhost(false)
	if RSHUM.Verbose
		Debug.Notification("Dropped : " + banditcarried.GetDisplayName())
	endif
	ClearPassenger(FollowerBandit, bandit)
	ClearPassenger(FollowerBanditCarried, banditcarried)
	Game.EnablePlayerControls()
EndFunction

Function LivingTarget(Actor aktarget)
	if !aktarget
		return
	endif
	
	Actor player = Game.GetPlayer()
	
	if player.IsWeaponDrawn()
		player.SheatheWeapon()
		return
	endif
	if rshFixOptions.ForceThirdPersonOnPickup()	; FIX patch : vue 3e personne au portage (option FOMOD)
		Game.ForceThirdPerson()
	endif

	aktarget.AddItem(rshBanditOnPlayerToken, 1, true)
	aktarget.SetRestrained(true)
	aktarget.StopCombatAlarm()
	if aktarget.GetRelationshipRank(player) <= 0
		Debug.SendAnimationEvent(player, "IdleLockPick")
		Utility.Wait(2)
		Debug.SendAnimationEvent(aktarget, "IdleHandsBehindBack")
		Debug.SendAnimationEvent(player, "IdleForceDefaultState")
	else
		aktarget.AddItem(rshCarriedAllyToken, 1, true)
	endif
	aktarget.AddToFaction(rshCarriedFaction)
	Debug.SendAnimationEvent(player, "idlepickup_ground")
	player.AddItem(rshBanditOnPlayerToken, 1, true)
	Utility.Wait(1.25)
	RSHCS.FadeOut(aktarget)
	Debug.SendAnimationEvent(aktarget, "IdleForceDefaultState")
	FollowerBanditCarried.ForceRefTo(aktarget)
;	Actor banditcarried = FollowerBanditCarried.GetActorRef()
	SetPassenger(FollowerBandit, aktarget, rshHorseCrimeToken, "Captured passenger")
	aktarget.BlockActivation(true)
	aktarget.SetRestrained(false)
	RSHCS.SetAnimationBandit(aktarget)
	aktarget.EvaluatePackage()
	rshBanditSync.SetValue(1)
	aktarget.SetGhost(true)
	AttachmentPlayer(aktarget, player)
	RSHCS.AnimEventFollower(aktarget, true)
;	Game.DisablePlayerControls(false, false, false, false, True, false, false, false)
	aktarget.ForceRemoveRagdollFromWorld()
	RSHCS.FadeIn(aktarget)
EndFunction

Function SpecialTarget(Actor aktarget, String akstring)
	if !aktarget
		return
	endif
	
	Actor player = Game.GetPlayer()
	
	if player.IsWeaponDrawn()
		player.SheatheWeapon()
		return
	endif
	if rshFixOptions.ForceThirdPersonOnPickup()	; FIX patch : vue 3e personne au portage (option FOMOD)
		Game.ForceThirdPerson()
	endif
	
	aktarget.AddItem(rshBanditOnPlayerToken, 1, true)
	aktarget.SetRestrained(true)
	aktarget.StopCombatAlarm()
	aktarget.AddToFaction(rshCarriedFaction)
	Debug.SendAnimationEvent(player, "idlepickup_ground")
	player.AddItem(rshBanditOnPlayerToken, 1, true)
	Utility.Wait(1.25)
	RSHCS.FadeOut(aktarget)
	Debug.SendAnimationEvent(aktarget, "IdleForceDefaultState")
	if akstring == "bridal"
		aktarget.AddItem(rshCarriedBridalToken, 1, true)
		player.AddItem(rshCarriedBridalToken, 1, true)
	elseif akstring == "shoulders"
		aktarget.AddItem(rshCarriedShouldersToken, 1, true)
		player.AddItem(rshCarriedShouldersToken, 1, true)
	endif
	FollowerBanditCarried.ForceRefTo(aktarget)
	SetPassenger(FollowerBandit, aktarget, rshHorseCrimeToken, "Carried passenger")
	aktarget.BlockActivation(true)
	aktarget.SetRestrained(false)
	RSHCS.SetAnimationBandit(aktarget)
	aktarget.EvaluatePackage()
	rshBanditSync.SetValue(1)
	aktarget.SetGhost(true)
	AttachmentPlayer(aktarget, player)
	RSHCS.AnimEventFollower(aktarget, true)
	if RSHUM.UseSkyPrompt
		Game.DisablePlayerControls(false, True, false, false, True, false, false, false)
	else
		Game.DisablePlayerControls(false, false, false, false, True, false, false, false)
	endif
;	aktarget.ForceRemoveRagdollFromWorld()
	RSHCS.FadeIn(aktarget)
EndFunction

Function AttachmentPlayer(Actor akActor, Actor akTarget)
if akActor.GetItemCount(rshCarriedShouldersToken) >= 1
	StartAttachmentPlayer(akTarget, pinNPCNeckBone, akActor, 0, -15, 0, 0, 0, 0, rshBanditSync, false)
elseif akActor.GetItemCount(rshCarriedBridalToken) >= 1
	StartAttachmentPlayer(akTarget, pinNPCBone, akActor, 0, 25, -13, 0, 0, 0, rshBanditSync, false)
else
	StartAttachmentPlayer(akTarget, pinNPCBone, akActor, X, Y, Z, Rx, Ry, Rz, rshBanditSync, true)
endif
EndFunction

Function DeadTarget(Actor aktarget)
	if !aktarget
		return
	endif
	
	Actor player = Game.GetPlayer()
	
	if player.IsWeaponDrawn()
		player.SheatheWeapon()
		return
	endif
	if rshFixOptions.ForceThirdPersonOnPickup()	; FIX patch : vue 3e personne au portage (option FOMOD)
		Game.ForceThirdPerson()
	endif
	
	aktarget.AddItem(rshBanditOnPlayerToken, 1, true)
	player.AddItem(rshBanditOnPlayerToken, 1, true)
	Debug.SendAnimationEvent(player, "idlepickup_ground")
	Utility.Wait(1.25)
	RSHCS.FadeOut(aktarget)
	FollowerBanditCarried.ForceRefTo(aktarget)
	Actor banditcarried = FollowerBanditCarried.GetActorRef()
	SetPassenger(FollowerBandit, aktarget, rshHorseCrimeToken, "Captured passenger")
	aktarget.BlockActivation(true)
	rshBanditSync.SetValue(1)
	AttachmentPlayer(aktarget, player)
	RSHCS.SetAnimationBandit(aktarget)
	aktarget.EvaluatePackage()
	Game.DisablePlayerControls(false, false, false, false, True, false, false, false)
	aktarget.ForceRemoveRagdollFromWorld()
	Utility.Wait(0.5)
	RSHCS.FadeIn(aktarget)
EndFunction

Function AlerteFaction(Actor akSpeaker)
    Faction crimeFaction = akSpeaker.GetCrimeFaction()
    if !crimeFaction
        return
    endif
    
    ; Trouver un garde à proximité
    Actor nearbyGuard = FindNearestGuard(akSpeaker, crimeFaction, 2048.0)
    
    if nearbyGuard
		; FIX patch (P-06) : l'alarme est conservée, mais la faction criminelle du joueur (et son appartenance
		; à la faction) n'est plus modifiée durablement : on mémorise l'état avant l'appel et on le restaure après.
		Actor player = Game.GetPlayer()
		Faction previousCrimeFaction = player.GetCrimeFaction()
		bool wasMember = player.IsInFaction(crimeFaction)
        player.SetCrimeFaction(crimeFaction)
        crimeFaction.SendAssaultAlarm()
		akSpeaker.StopCombatAlarm()
		Utility.Wait(1.0)
		player.SetCrimeFaction(previousCrimeFaction)
		if !wasMember
			player.RemoveFromFaction(crimeFaction)
		endif
        
		if RSHUM.Verbose
			Debug.Notification("Prime given by :" + nearbyGuard.GetDisplayName())
		endif
    endif
EndFunction

; FIX patch (P-08) : l'add-on « ShoulderCarryState Female » équipe PrisonerCuffs (Skyrim.esm 0x103941) sur les
; captives hostiles sans jamais les retirer. Uniquement si l'add-on est chargé (son jeton 0x800 existe).
Function RemoveAddonCuffs(Actor akActor)
	if (akActor == None) || (Game.GetFormFromFile(0x800, "ShoulderCarryState-Female.esp") == None)
		return
	endif
	Form cuffs = Game.GetForm(0x103941)
	if cuffs && akActor.GetItemCount(cuffs) > 0
		akActor.RemoveItem(cuffs, 5, true)
	endif
EndFunction

Actor Function FindNearestGuard(Actor akSpeaker, Faction crimeFaction, float radius)
    int attempts = 0
    int maxAttempts = 20
    
    while attempts < maxAttempts
        Actor foundActor = Game.FindRandomActorFromRef(akSpeaker, radius)
        
        if foundActor && foundActor != akSpeaker && foundActor != Game.GetPlayer() && foundActor.GetRelationshipRank(Game.GetPlayer()) < 1 && !foundActor.IsDead() && foundActor.IsInFaction(crimeFaction)
            return foundActor
        endif
        
        attempts += 1
    endwhile
    
    return None
EndFunction
