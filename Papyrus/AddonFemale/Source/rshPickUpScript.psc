Scriptname rshPickUpScript extends activemagiceffect  

; Properties

GlobalVariable Property rshBanditSync Auto

Keyword Property ActorTypeNPC Auto

MiscObject Property DeadToken Auto
MiscObject Property HostileToken Auto
MiscObject Property FriendlyToken Auto
MiscObject Property NaptimeToken Auto
Form Cuffs

MiscObject Property rshBanditOnPlayerToken Auto
MiscObject Property rshBanditOnPlayerHorseToken Auto

ReferenceAlias Property FollowerBandit Auto
ReferenceAlias Property FollowerBanditCarried Auto
ReferenceAlias Property RSHPlayerHorse Auto

rshCoreScript Property RSHCS auto
rshinvitescript Property RSHINV auto
rshUpdateManagerScript Property RSHUM auto

Function OnEffectStart(Actor aktarget, Actor akcaster)
Actor targetActor = Game.GetCurrentCrosshairRef() as Actor

	; FIX patch (P-08) : sans cible sous le viseur, ce bloc appelait 12 fonctions sur None
	if targetActor
		cuffs = Game.GetForm(0x103941)
		targetActor.RemoveItem(DeadToken,5,true)||targetActor.RemoveItem(HostileToken,5,true)
		targetActor.RemoveItem(FriendlyToken,5,true)||targetActor.RemoveItem(NaptimeToken,5,true)||targetActor.RemoveItem(cuffs,5,true)
		if targetActor.IsUnconscious()
			targetActor.additem(NaptimeToken,1,true)
		elseif targetActor.IsDead()
			targetActor.additem(DeadToken,1,true)
		else
			if targetActor.IsHostileToActor(akcaster)
				targetActor.additem(HostileToken,1,true)
				targetActor.EquipItem(cuffs, true)
			else
				targetActor.additem(FriendlyToken,1,true)
			endif
		endif
	endif
	
	if rshBanditSync.GetValue() == 1
		HandleBanditSync(targetActor)
		return
	endif
	
	if RSHUM.UseHorseSpell
		if targetActor && targetActor.haskeyword(ActorTypeNPC)
			if targetActor.IsDead()
				RSHINV.HandleDeadTarget(targetActor)
			else
				RSHINV.HandleLivingTarget(targetActor)
			endif
		endif
	else
		if targetActor && targetActor.haskeyword(ActorTypeNPC)
			if targetActor.IsDead()
				RSHINV.DeadTarget(targetActor)
			else
				RSHINV.LivingTarget(targetActor)
			endif
		endif
	endif
EndFunction

; Gestion de la synchronisation
Function HandleBanditSync(Actor aktarget)
	Actor bandit = FollowerBandit.GetActorRef()
	Actor banditcarried = FollowerBanditCarried.GetActorRef()
	Actor player = Game.GetPlayer()
	
	RSHCS.UpdatePlayerHorse()
	Actor playerHorse = RSHPlayerHorse.GetActorRef()
	
	; Cas 1: Bandit sur cheval -> Passer au joueur
	if (aktarget == banditcarried || (aktarget == playerHorse && playerHorse != none)) && banditcarried.GetItemCount(rshBanditOnPlayerHorseToken) > 0
		RSHINV.Cas1(banditcarried, playerHorse, player)
		
	; Cas 2: Bandit sur joueur -> Attacher bandit au cheval
	elseif (aktarget == playerHorse && playerHorse != none) && banditcarried.GetItemCount(rshBanditOnPlayerToken) > 0
		RSHINV.Cas2(banditcarried, playerHorse, player)
		
	; Cas 3: Gestion follower
	elseif aktarget && aktarget.haskeyword(ActorTypeNPC) && !aktarget.IsDead() && RSHUM.UseHorseSpell ; FIX patch : garde None (dépôt sans cible)
		RSHINV.HandleLivingTarget(aktarget)

	; Cas 4: Déposer le bandit/corps au sol
	elseif banditcarried.GetItemCount(rshBanditOnPlayerToken) > 0
		RSHINV.Cas4(bandit, banditcarried, player)
	endif

EndFunction
