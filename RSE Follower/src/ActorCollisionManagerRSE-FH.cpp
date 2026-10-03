#include "ActorCollisionManagerRSE-FH.h"

#include <excpt.h>

#include <chrono>
#include <shared_mutex>

bool ManagerCallPlayerActif = false;

// ============================================================================
// PROTECTION MULTI-THREADING
// ============================================================================
static std::shared_timed_mutex g_havokMutex;
static std::unordered_map<RE::FormID, bool> g_actorHavokState;
static std::mutex g_stateMutex;

// ============================================================================
// PROTECTION RATE LIMITING
// ============================================================================
static std::unordered_map<RE::FormID, std::chrono::steady_clock::time_point> g_lastHavokOp;
static std::mutex g_rateLimitMutex;
constexpr auto MIN_HAVOK_INTERVAL = std::chrono::milliseconds(200);

// ============================================================================
// PROTECTION RÉ-ENTRANCE
// ============================================================================
static thread_local bool g_inHavokOperation = false;

// ============================================================================
// CONSTANTES
// ============================================================================
constexpr auto CLEANUP_INTERVAL = std::chrono::minutes(5);
constexpr auto LOCK_TIMEOUT = std::chrono::milliseconds(100);

// ============================================================================
// PROTECTION SEH (STRUCTURED EXCEPTION HANDLING)
// ============================================================================
namespace SafeAccess {

    // Fonctions simples sans objets C++ - compatibles SEH
    bool SafeGetCharController(RE::Actor* actor) {
        if (!actor) return false;

        __try {
            auto controller = actor->GetCharController();
            return controller != nullptr;
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            SKSE::log::error("SafeGetCharController: Exception 0x{:X}", GetExceptionCode());
            return false;
        }
    }

    bool SafeGet3D(RE::Actor* actor) {
        if (!actor) return false;

        __try {
            auto node = actor->Get3D();
            return node != nullptr;
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            return false;
        }
    }

    bool SafeIsDeleted(RE::Actor* actor) {
        if (!actor) return true;

        __try {
            return actor->IsDeleted();
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            return true;
        }
    }

    bool SafeIsDisabled(RE::Actor* actor) {
        if (!actor) return true;

        __try {
            return actor->IsDisabled();
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            return true;
        }
    }

    bool SafeGetCurrentProcess(RE::Actor* actor) {
        if (!actor) return false;

        __try {
            auto middleProcess = actor->GetActorRuntimeData().currentProcess;
            return middleProcess != nullptr;
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            return false;
        }
    }

    RE::NiAVObject* SafeGetNode(RE::Actor* actor) {
        if (!actor) return nullptr;

        __try {
            return actor->Get3D();
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            return nullptr;
        }
    }

    bool SafeDetachHavok(RE::Actor* actor, RE::NiAVObject* node) {
        if (!actor || !node) return false;

        __try {
            actor->DetachHavok(node);
            return true;
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            SKSE::log::error("SafeDetachHavok: Exception 0x{:X} pour actor 0x{:X}", GetExceptionCode(),
                             actor->GetFormID());
            return false;
        }
    }

    bool SafeInitHavok(RE::Actor* actor) {
        if (!actor) return false;

        __try {
            actor->InitHavok();
            return true;
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            SKSE::log::error("SafeInitHavok: Exception 0x{:X} pour actor 0x{:X}", GetExceptionCode(),
                             actor->GetFormID());
            return false;
        }
    }

    RE::FormID SafeGetFormID(RE::Actor* actor) {
        if (!actor) return 0;

        __try {
            return actor->GetFormID();
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            return 0;
        }
    }

    // Structure pour retourner le résultat du lookup
    struct LookupResult {
        RE::Actor* actor = nullptr;
        bool exception = false;
    };

    LookupResult SafeLookupActor(RE::FormID formID) {
        LookupResult result;

        __try {
            result.actor = RE::TESForm::LookupByID<RE::Actor>(formID);
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            result.exception = true;
            SKSE::log::error("SafeLookupActor: Exception 0x{:X} pour FormID 0x{:X}", GetExceptionCode(), formID);
        }

        return result;
    }

}  // namespace SafeAccess

// ============================================================================
// NAMESPACE HAVOKUTILS - UTILITAIRES DE SÉCURITÉ
// ============================================================================
namespace HavokUtils {

    bool IsValidActorPointer(RE::Actor* actor) {
        if (!actor) return false;

        auto formID = SafeAccess::SafeGetFormID(actor);
        return formID != 0;
    }

    bool IsActorValid(RE::Actor* actor, const char* context) {
        if (!IsValidActorPointer(actor)) {
            SKSE::log::error("{}: Pointeur acteur invalide", context);
            return false;
        }

        auto formID = SafeAccess::SafeGetFormID(actor);

        if (SafeAccess::SafeIsDeleted(actor)) {
            SKSE::log::warn("{}: Acteur 0x{:X} est deleted", context, formID);
            return false;
        }

        if (SafeAccess::SafeIsDisabled(actor)) {
            SKSE::log::trace("{}: Acteur 0x{:X} est disabled", context, formID);
            return false;
        }

        if (!SafeAccess::SafeGet3D(actor)) {
            SKSE::log::trace("{}: Acteur 0x{:X} n'a pas de 3D", context, formID);
            return false;
        }

        if (!SafeAccess::SafeGetCharController(actor)) {
            SKSE::log::warn("{}: Acteur 0x{:X} n'a pas de CharController valide", context, formID);
            return false;
        }

        if (!SafeAccess::SafeGetCurrentProcess(actor)) {
            SKSE::log::warn("{}: Acteur 0x{:X} n'a pas de process valide", context, formID);
            return false;
        }

        return true;
    }

    bool CanManipulateHavok(RE::Actor* actor) {
        std::lock_guard<std::mutex> lock(g_rateLimitMutex);

        auto now = std::chrono::steady_clock::now();
        auto formID = SafeAccess::SafeGetFormID(actor);
        auto it = g_lastHavokOp.find(formID);

        if (it != g_lastHavokOp.end()) {
            auto elapsed = now - it->second;
            if (elapsed < MIN_HAVOK_INTERVAL) {
                SKSE::log::trace("Rate limit: opération Havok trop fréquente pour 0x{:X}", formID);
                return false;
            }
        }

        g_lastHavokOp[formID] = now;
        return true;
    }

    bool IsHavokAttached(RE::Actor* actor) {
        if (!actor) return false;

        std::lock_guard<std::mutex> lock(g_stateMutex);
        auto formID = SafeAccess::SafeGetFormID(actor);
        auto it = g_actorHavokState.find(formID);
        return it != g_actorHavokState.end() ? it->second : true;
    }

    void SetHavokState(RE::Actor* actor, bool attached) {
        if (!actor) return;

        std::lock_guard<std::mutex> lock(g_stateMutex);
        auto formID = SafeAccess::SafeGetFormID(actor);
        g_actorHavokState[formID] = attached;
    }

    void ForceCleanupActor(RE::FormID formID) {
        {
            std::lock_guard<std::mutex> lock(g_stateMutex);
            g_actorHavokState.erase(formID);
        }
        {
            std::lock_guard<std::mutex> lock(g_rateLimitMutex);
            g_lastHavokOp.erase(formID);
        }
        SKSE::log::trace("ForceCleanupActor: État nettoyé pour 0x{:X}", formID);
    }

    // Fonction helper pour nettoyer une seule entrée
    bool ShouldRemoveActor(RE::FormID formID) {
        auto result = SafeAccess::SafeLookupActor(formID);

        if (result.exception) {
            return true;  // Exception = nettoyer
        }

        if (!result.actor) {
            return true;  // Actor null = nettoyer
        }

        if (SafeAccess::SafeIsDeleted(result.actor)) {
            return true;  // Deleted = nettoyer
        }

        if (!SafeAccess::SafeGet3D(result.actor)) {
            return true;  // Pas de 3D = nettoyer
        }

        return false;
    }

    void CleanupHavokStateMap() {
        size_t removedState = 0;
        size_t removedRate = 0;

        // Nettoyage de g_actorHavokState
        {
            std::lock_guard<std::mutex> lock(g_stateMutex);
            for (auto it = g_actorHavokState.begin(); it != g_actorHavokState.end();) {
                if (ShouldRemoveActor(it->first)) {
                    it = g_actorHavokState.erase(it);
                    removedState++;
                } else {
                    ++it;
                }
            }
        }

        // Nettoyage de g_lastHavokOp
        {
            std::lock_guard<std::mutex> lock(g_rateLimitMutex);
            for (auto it = g_lastHavokOp.begin(); it != g_lastHavokOp.end();) {
                if (ShouldRemoveActor(it->first)) {
                    it = g_lastHavokOp.erase(it);
                    removedRate++;
                } else {
                    ++it;
                }
            }
        }

        if (removedState > 0 || removedRate > 0) {
            SKSE::log::info("CleanupHavokStateMap: Nettoyé {} états et {} rate limits", removedState, removedRate);
        }
    }

}  // namespace HavokUtils

// ============================================================================
// OPÉRATIONS HAVOK ULTRA-SÉCURISÉES AVEC PROTECTION SEH
// ============================================================================

void MakeActorGhost(RE::Actor* actor) {
    if (g_inHavokOperation) {
        SKSE::log::warn("MakeActorGhost: Appel récursif détecté");
        return;
    }

    if (!HavokUtils::IsActorValid(actor, "MakeActorGhost")) {
        if (actor) {
            auto formID = SafeAccess::SafeGetFormID(actor);
            if (formID) HavokUtils::ForceCleanupActor(formID);
        }
        return;
    }

    if (!HavokUtils::CanManipulateHavok(actor)) {
        return;
    }

    auto actorFormID = SafeAccess::SafeGetFormID(actor);
    g_inHavokOperation = true;

    struct ReentranceGuard {
        ~ReentranceGuard() { g_inHavokOperation = false; }
    } guard;

    {
        std::shared_lock<std::shared_timed_mutex> readLock(g_havokMutex);
        if (!HavokUtils::IsHavokAttached(actor)) {
            SKSE::log::trace("MakeActorGhost: Havok déjà détaché pour 0x{:X}", actorFormID);
            return;
        }
    }

    std::unique_lock<std::shared_timed_mutex> writeLock(g_havokMutex, std::defer_lock);
    if (!writeLock.try_lock_for(LOCK_TIMEOUT)) {
        SKSE::log::error("MakeActorGhost: Timeout sur le lock pour 0x{:X}", actorFormID);
        return;
    }

    // Double vérification après lock
    if (!HavokUtils::IsActorValid(actor, "MakeActorGhost(post-lock)")) {
        HavokUtils::ForceCleanupActor(actorFormID);
        return;
    }

    if (!HavokUtils::IsHavokAttached(actor)) {
        SKSE::log::trace("MakeActorGhost: Havok déjà détaché (après lock) pour 0x{:X}", actorFormID);
        return;
    }

    // Récupérer le node 3D de manière sécurisée
    auto cell3D = SafeAccess::SafeGetNode(actor);
    if (!cell3D) {
        SKSE::log::warn("MakeActorGhost: cell3D devenu null pour 0x{:X}", actorFormID);
        return;
    }

    // Détachement Havok avec protection SEH
    bool success = SafeAccess::SafeDetachHavok(actor, cell3D);

    if (success) {
        HavokUtils::SetHavokState(actor, false);
        SKSE::log::info("MakeActorGhost: Havok détaché avec succès pour 0x{:X}", actorFormID);
    } else {
        SKSE::log::error("MakeActorGhost: Échec DetachHavok pour 0x{:X}", actorFormID);
        HavokUtils::ForceCleanupActor(actorFormID);
    }
}

void ReattachActorToHavok(RE::Actor* actor) {
    if (g_inHavokOperation) {
        SKSE::log::warn("ReattachActorToHavok: Appel récursif détecté");
        return;
    }

    if (!HavokUtils::IsActorValid(actor, "ReattachActorToHavok")) {
        if (actor) {
            auto formID = SafeAccess::SafeGetFormID(actor);
            if (formID) HavokUtils::ForceCleanupActor(formID);
        }
        return;
    }

    if (!HavokUtils::CanManipulateHavok(actor)) {
        return;
    }

    auto actorFormID = SafeAccess::SafeGetFormID(actor);
    g_inHavokOperation = true;

    struct ReentranceGuard {
        ~ReentranceGuard() { g_inHavokOperation = false; }
    } guard;

    {
        std::shared_lock<std::shared_timed_mutex> readLock(g_havokMutex);
        if (HavokUtils::IsHavokAttached(actor)) {
            SKSE::log::trace("ReattachActorToHavok: Havok déjà attaché pour 0x{:X}", actorFormID);
            return;
        }
    }

    std::unique_lock<std::shared_timed_mutex> writeLock(g_havokMutex, std::defer_lock);
    if (!writeLock.try_lock_for(LOCK_TIMEOUT)) {
        SKSE::log::error("ReattachActorToHavok: Timeout sur le lock pour 0x{:X}", actorFormID);
        return;
    }

    // Double vérification après lock
    if (!HavokUtils::IsActorValid(actor, "ReattachActorToHavok(post-lock)")) {
        HavokUtils::ForceCleanupActor(actorFormID);
        return;
    }

    if (HavokUtils::IsHavokAttached(actor)) {
        SKSE::log::trace("ReattachActorToHavok: Havok déjà attaché (après lock) pour 0x{:X}", actorFormID);
        return;
    }

    // Vérifier que le node 3D existe
    auto cell3D = SafeAccess::SafeGetNode(actor);
    if (!cell3D) {
        SKSE::log::warn("ReattachActorToHavok: cell3D devenu null pour 0x{:X}", actorFormID);
        return;
    }

    // Réattachement Havok avec protection SEH
    bool success = SafeAccess::SafeInitHavok(actor);

    if (success) {
        HavokUtils::SetHavokState(actor, true);
        SKSE::log::info("ReattachActorToHavok: Havok réattaché avec succès pour 0x{:X}", actorFormID);
    } else {
        SKSE::log::error("ReattachActorToHavok: Échec InitHavok pour 0x{:X}", actorFormID);
        HavokUtils::ForceCleanupActor(actorFormID);
    }
}

// ============================================================================
// MÉTHODES DE CLASSE ACTORCOLLISIONMANAGER
// ============================================================================

void ActorCollisionManager::ManageActorCollision(RE::Actor* akActor, bool akEnable) {
    if (!akActor) return;

    if (akEnable) {
        ActorCollisionManager::Hook_Collision(akActor);
        ManagerCallPlayerActif = false;
        auto formID = SafeAccess::SafeGetFormID(akActor);
        SKSE::log::info("Collision process enabled for actor 0x{:X}", formID);
    } else {
        ManagerCallPlayerActif = true;
        auto formID = SafeAccess::SafeGetFormID(akActor);
        SKSE::log::info("Collision disabled for actor 0x{:X}", formID);
    }
}

void ActorCollisionManager::Install() {
    auto& trampoline = SKSE::GetTrampoline();
    REL::Relocation<std::uintptr_t> target{RELOCATION_ID(36359, 37350),
                                           REL::Module::GetRuntime() != REL::Module::Runtime::AE ? 0xF0 : 0xFB};
    _applyMovementDelta = trampoline.write_call<5>(target.address(), Hook_ApplyMovementDelta);

    GetSingleton()->lastCleanupTime = std::chrono::steady_clock::now();

    SKSE::log::info("ActorCollisionManager hooks installed");
}

// FIX patch (C-11) : enregistré sur kDataLoaded (la source d'événements n'est pas garantie prête au chargement du plugin)
void ActorCollisionManager::RegisterEventSink() {
    auto* eventSourceHolder = RE::ScriptEventSourceHolder::GetSingleton();
    if (eventSourceHolder) {
        eventSourceHolder->GetEventSource<RE::TESCellAttachDetachEvent>()->AddEventSink(GetSingleton());
        SKSE::log::info("ActorCollisionManager: Event sink enregistré");
    }
}

// FIX patch (C-04) : au chargement d'une partie, l'état d'attachement de la session précédente ne doit pas
// survivre (handles et nœuds invalides). Les scripts ré-attachent ensuite si nécessaire.
void ActorCollisionManager::ResetForLoad() {
    {
        std::lock_guard lock(g_attachmentLock);
        GetSingleton()->GetAttachmentData().Reset();
    }
    ManagerCallPlayerActif = false;
    {
        std::lock_guard lock(g_stateMutex);
        g_actorHavokState.clear();
    }
    {
        std::lock_guard lock(g_rateLimitMutex);
        g_lastHavokOp.clear();
    }
    SKSE::log::info("État d'attachement réinitialisé (chargement / nouvelle partie)");
}

RE::BSEventNotifyControl ActorCollisionManager::ProcessEvent(
    const RE::TESCellAttachDetachEvent* a_event, RE::BSTEventSource<RE::TESCellAttachDetachEvent>* a_eventSource) {
    (void)a_eventSource;

    if (!a_event) return RE::BSEventNotifyControl::kContinue;

    if (!a_event->attached && a_event->reference) {
        auto actor = a_event->reference->As<RE::Actor>();
        if (actor) {
            auto formID = SafeAccess::SafeGetFormID(actor);
            SKSE::log::trace("Actor 0x{:X} détaché de la cellule, nettoyage de l'état", formID);
            HavokUtils::ForceCleanupActor(formID);
        }
    }

    auto now = std::chrono::steady_clock::now();
    auto elapsed = std::chrono::duration_cast<std::chrono::minutes>(now - lastCleanupTime);

    if (elapsed >= CLEANUP_INTERVAL) {
        SKSE::log::info("Nettoyage périodique de la map Havok...");
        HavokUtils::CleanupHavokStateMap();
        lastCleanupTime = now;
    }

    return RE::BSEventNotifyControl::kContinue;
}

// ============================================================================
// HOOK PRINCIPAL - Hook_ApplyMovementDelta
// ============================================================================
// FIX patch (C-05/C-06/C-07) : ce hook est appelé pour CHAQUE acteur qui bouge, à chaque frame.
// La version d'origine sautait le mouvement de tout acteur jugé « non sûr » (PNJ vanilla figés),
// l'entourait de SEH (exceptions du moteur avalées) et journalisait à chaque frame.
// Désormais le mouvement d'origine est toujours appliqué ; seul l'acteur attaché est traité.

void ActorCollisionManager::Hook_ApplyMovementDelta(RE::Actor* a_actor, float a_delta) {
    // Chemin rapide : aucun attachement en attente de traitement → comportement vanilla
    if (!ManagerCallPlayerActif) {
        _applyMovementDelta(a_actor, a_delta);
        return;
    }

    // Gestion collision désactivée (une seule fois après StartAttachment)
    auto manager = ActorCollisionManager::GetSingleton();
    RE::NiPointer<RE::Actor> actorBPtr;
    {
        std::lock_guard lock(g_attachmentLock);
        actorBPtr = manager->GetAttachmentData().actorB.get();
    }
    auto ActorB = actorBPtr.get();
    ManagerCallPlayerActif = false;

    if (ActorB) {
        if (HavokUtils::IsActorValid(ActorB, "Hook_ApplyMovementDelta")) {
            MakeActorGhost(ActorB);
            auto formID = SafeAccess::SafeGetFormID(ActorB);
            SKSE::log::info("Collision désactivée pour 0x{:X}", formID);
        } else {
            auto formID = SafeAccess::SafeGetFormID(ActorB);
            SKSE::log::warn("ActorB 0x{:X} est dans un état invalide", formID);
            if (formID) {
                HavokUtils::ForceCleanupActor(formID);
            }
        }
    } else {
        SKSE::log::warn("ActorB est null, impossible de désactiver la collision");
    }

    _applyMovementDelta(a_actor, a_delta);
}

void ActorCollisionManager::Hook_Collision(RE::Actor* a_actor) {
    if (!a_actor) {
        SKSE::log::warn("Hook_Collision: actor est null");
        return;
    }

    if (HavokUtils::IsActorValid(a_actor, "Hook_Collision")) {
        ReattachActorToHavok(a_actor);
        auto formID = SafeAccess::SafeGetFormID(a_actor);
        SKSE::log::info("Collision réactivée pour 0x{:X}", formID);
    } else {
        auto formID = SafeAccess::SafeGetFormID(a_actor);
        SKSE::log::warn("Actor 0x{:X} est dans un état invalide", formID);
        if (formID) {
            HavokUtils::ForceCleanupActor(formID);
        }
    }
}