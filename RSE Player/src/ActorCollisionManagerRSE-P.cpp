#include "ActorCollisionManagerRSE-P.h"

bool ManagerCallPlayerActif = false;
bool ManagerCallHorseActif = false;
bool ManagerCallPlayerOnHorseActif = false;

void ActorCollisionManager::ManageActorCollision(RE::Actor* akActor, bool akEnable) {
    if (!akActor) return;

    auto manager = GetSingleton();

    if (akEnable) {
        manager->RemoveFromIgnoredActors(akActor);
        ActorCollisionManager::Hook_Collision(akActor);
        ManagerCallPlayerActif = false;
        ManagerCallHorseActif = false;
        ManagerCallPlayerOnHorseActif = false;
        SKSE::log::info("Collision process enabled for actor 0x{:X}", akActor->GetFormID());
    } else {
        manager->AddToIgnoredActors(akActor);
        ManagerCallPlayerActif = true;
        ManagerCallHorseActif = true;
        SKSE::log::info("Collision disabled for actor 0x{:X}", akActor->GetFormID());
    }
}

// FIX patch (C-04) : rien de la session précédente ne doit survivre au chargement d'une partie
void ActorCollisionManager::ResetForLoad() {
    auto manager = GetSingleton();
    manager->_ignoredActors.clear();
    manager->_collisionObjects.clear();
    ManagerCallPlayerActif = false;
    ManagerCallHorseActif = false;
    ManagerCallPlayerOnHorseActif = false;
    SKSE::log::info("État de collision réinitialisé (chargement / nouvelle partie)");
}

void ActorCollisionManager::AddToIgnoredActors(RE::Actor* akActor) { _ignoredActors.insert(akActor->GetFormID()); }

void ActorCollisionManager::RemoveFromIgnoredActors(RE::Actor* akActor) { _ignoredActors.erase(akActor->GetFormID()); }

bool ActorCollisionManager::IsActorIgnored(RE::Actor* akActor) {
    return akActor && _ignoredActors.contains(akActor->GetFormID());
}

bool ActorCollisionManager::SetCollisionFlag(RE::hkpWorldObject* a_collisionObj, bool a_enable) {
    if (!a_collisionObj) return false;

    // FIX 1.7.104 : CommonLibSSE-NG 10 encapsule le filtre dans RE::CFilter (même bit kNoCollision = 1 << 14).
    static constexpr auto COLLISION_FLAG = static_cast<std::uint32_t>(RE::CFilter::Flags::kNoCollision);
    auto& filter = a_collisionObj->collidable.broadPhaseHandle.collisionFilterInfo.filter;

    /* bool currentlyEnabled = (filter & COLLISION_FLAG) == 0;*/

    if (a_enable /* && !currentlyEnabled */) {
        filter &= ~COLLISION_FLAG;  // Activer
        SKSE::log::debug("COLLISION_FLAG Activer, Adresse WorldObj : {:p} ", static_cast<void*>(a_collisionObj));
        return true;
    } else if (!a_enable /* && currentlyEnabled */) {
        filter |= COLLISION_FLAG;  // Désactiver
        SKSE::log::debug("COLLISION_FLAG Désactiver, Adresse WorldObj: {:p}", static_cast<void*>(a_collisionObj));
        return true;
    }

    return false;  // Aucun changement nécessaire
}

void ActorCollisionManager::Install() {
    auto& trampoline = SKSE::GetTrampoline();
    REL::Relocation<std::uintptr_t> target{RELOCATION_ID(36359, 37350),
                                           REL::Module::GetRuntime() != REL::Module::Runtime::AE ? 0xF0 : 0xFB};
    _applyMovementDelta = trampoline.write_call<5>(target.address(), Hook_ApplyMovementDelta);
    SKSE::log::info("ActorCollisionManager hooks installed");
}

void DisableActorHavok(RE::Actor* actor) {
    if (!actor) return;

    auto ctrl = actor->GetCharController();
    if (!ctrl) return;

    // Désactiver les collisions en définissant le flag approprié
    ctrl->flags.set(RE::CHARACTER_FLAGS::kNoCharacterCollisions);
    SKSE::log::debug("CHARACTER_FLAGS kNoCharacterCollisions pour l'acteur {} (FormID: {:08X})", actor->GetName(),
                     actor->GetFormID());
   
    // Optionnel: désactiver la simulation
    ctrl->flags.set(RE::CHARACTER_FLAGS::kNoSim);
    SKSE::log::debug("CHARACTER_FLAGS kNoSim pour l'acteur {} (FormID: {:08X})", actor->GetName(), actor->GetFormID());
}

void EnableActorHavok(RE::Actor* actor) {
    if (!actor) return;

    auto ctrl = actor->GetCharController();
    if (!ctrl) return;

    // Réactiver les collisions
    ctrl->flags.reset(RE::CHARACTER_FLAGS::kNoCharacterCollisions);
    SKSE::log::debug("CHARACTER_FLAGS kNoCharacterCollisions désactivé pour l'acteur {} (FormID: {:08X})",
                     actor->GetName(), actor->GetFormID());

    // Réactiver la gravité (valeur par défaut du jeu)
    ctrl->gravity = 1.0f;

    // Réactiver la simulation
    ctrl->flags.reset(RE::CHARACTER_FLAGS::kNoSim);
    SKSE::log::debug("CHARACTER_FLAGS kNoSim désactivé pour l'acteur {} (FormID: {:08X})", actor->GetName(),
                     actor->GetFormID());
}

bool PlayerHorse(RE::Actor* a_actor) {
    if (!a_actor) return false;

    // Vérifier si c'est le joueur
    // if (a_actor->IsPlayerRef()) return true;

    // Vérifier si c'est la monture du joueur
    auto player = RE::PlayerCharacter::GetSingleton();
    if (player) {
        RE::NiPointer<RE::Actor> lastMount;
        if (player->GetMount(lastMount) && lastMount.get() == a_actor) {
            return true;
        }
    }

    return false;
}

void ActorCollisionManager::Hook_ApplyMovementDelta(RE::Actor* a_actor, float a_delta) {
    auto managerbase = GetSingleton();

    if (!ManagerCallPlayerActif && !ManagerCallHorseActif) {
        managerbase->_applyMovementDelta(a_actor, a_delta);
        return;
    }

    // Vérifier si l'acteur courant est le cheval du joueur
    bool isPlayerHorse = PlayerHorse(a_actor);

    // Vérifier si l'acteur courant est dans la liste des ignorés
    bool isCurrentActorIgnored = managerbase->IsActorIgnored(a_actor);

    // CAS 1 : L'acteur courant est le joueur
    // Si le système n'est pas actif, exécuter normalement
    if (ManagerCallPlayerActif) {
        auto manager = GetSingleton();
        if (a_actor->IsPlayerRef()) {
            SKSE::log::debug("DEBUG: Traitement joueur - Acteur: {} (FormID: {:08X}), Acteurs ignorés: {}",
                             a_actor->GetName(), a_actor->GetFormID(), manager->_ignoredActors.size());

            const auto controller = a_actor->GetCharController();
            if (!controller) {
                manager->_applyMovementDelta(a_actor, a_delta);
                return;
            }
            const auto collisionObj = controller->bumpedCharCollisionObject.get();
            if (!collisionObj) {
                manager->_applyMovementDelta(a_actor, a_delta);
                return;
            }
            // Obtenir la référence de l'objet en collision
            const auto colRef = RE::TESHavokUtilities::FindCollidableRef(collisionObj->collidable);
            // Si c'est un acteur
            if (colRef && colRef->Is(RE::FormType::ActorCharacter)) {
                const auto colActor = static_cast<RE::Actor*>(colRef);
                const auto colActorFormID = colActor->GetFormID();
                // Stocker l'objet de collision pour cet acteur
                manager->_collisionObjects[colActorFormID] = collisionObj;
                // Si cet acteur doit être ignoré, désactiver sa collision de manière permanente
                if (manager->IsActorIgnored(colActor)) {
                    ManagerCallPlayerActif = false;
                    manager->SetCollisionFlag(collisionObj, false);
                }
            }
            // Appliquer le mouvement
            manager->_applyMovementDelta(a_actor, a_delta);
            return;
        }
    }

    // CAS 2 : L'acteur courant est le cheval du joueur
    // On désactive les collisions de tous les acteurs ignorés
    if (ManagerCallHorseActif) {
        auto manager = GetSingleton();
        if (isPlayerHorse) {
            SKSE::log::debug("DEBUG: Traitement cheval - Acteur: {} (FormID: {:08X}), Acteurs ignorés: {}",
                             a_actor->GetName(), a_actor->GetFormID(), manager->_ignoredActors.size());

            const auto controller = a_actor->GetCharController();
            if (!controller) {
                manager->_applyMovementDelta(a_actor, a_delta);
                return;
            }
            const auto collisionObj = controller->bumpedCharCollisionObject.get();
            if (!collisionObj) {
                manager->_applyMovementDelta(a_actor, a_delta);
                return;
            }
            // Obtenir la référence de l'objet en collision
            const auto colRef = RE::TESHavokUtilities::FindCollidableRef(collisionObj->collidable);
            // Si c'est un acteur
            if (colRef && colRef->Is(RE::FormType::ActorCharacter)) {
                const auto colActor = static_cast<RE::Actor*>(colRef);
                const auto colActorFormID = colActor->GetFormID();
                // Stocker l'objet de collision pour cet acteur
                manager->_collisionObjects[colActorFormID] = collisionObj;
                // Si cet acteur doit être ignoré, désactiver sa collision de manière permanente
                if (manager->IsActorIgnored(colActor)) {
                    ManagerCallHorseActif = false;
                    ManagerCallPlayerOnHorseActif = true;
                    manager->SetCollisionFlag(collisionObj, false);
                }
            }
            // Appliquer le mouvement
            manager->_applyMovementDelta(a_actor, a_delta);
            return;
        }
    }
    
    // CAS 3 : L'acteur courant est le cheval du joueur et le joueur est sur le cheval (collision du joueur partiel)
    auto player = RE::PlayerCharacter::GetSingleton();
    if (ManagerCallPlayerOnHorseActif && player->IsOnMount()) {
        auto manager = GetSingleton();
        SKSE::log::debug("DEBUG: Traitement joueur sur cheval - Acteur: {} (FormID: {:08X}), Acteurs ignorés: {}",
                         player->GetName(), player->GetFormID(), manager->_ignoredActors.size());
        ManagerCallPlayerActif = false;
        ManagerCallPlayerOnHorseActif = false;
    //    DisableActorHavok(player);
    }
    
    managerbase->_applyMovementDelta(a_actor, a_delta);
}

void ActorCollisionManager::Hook_Collision(RE::Actor* a_actor) {
    auto manager = GetSingleton();
    if (!a_actor) return;

    auto it = manager->_collisionObjects.find(a_actor->GetFormID());
    if (it != manager->_collisionObjects.end() && it->second) {
        SKSE::log::debug("Collision en cours de réactivation pour {} (FormID: {:08X})", a_actor->GetName(),
                         a_actor->GetFormID());

        if (manager->SetCollisionFlag(it->second, true)) {
            // EnableActorHavok(a_actor);
            SKSE::log::info("Collision stabilisée (Réactivée) pour 0x{:X}", a_actor->GetFormID());
        }

        // Nettoyer le cache
        manager->_collisionObjects.erase(it);
    }
}