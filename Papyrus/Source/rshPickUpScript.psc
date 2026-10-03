Scriptname rshPickUpScript extends activemagiceffect  

; Properties

GlobalVariable Property rshBanditSync Auto

Keyword Property ActorTypeNPC Auto

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
