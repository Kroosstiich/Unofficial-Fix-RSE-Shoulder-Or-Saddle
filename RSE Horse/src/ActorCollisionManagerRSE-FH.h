#pragma once

#include <atomic>
#include <chrono>
#include <unordered_map>
#include <unordered_set>
#include <mutex>

// Structure pour stocker les données d'attachement (partagée)
// FIX patch (C-03) : handles et références comptées au lieu de pointeurs bruts ; le nœud est re-résolu
// si le squelette de l'acteur A change (changement de cellule, d'équipement, rechargement du 3D).
struct AttachmentData {
    RE::ActorHandle actorA;
    RE::ActorHandle actorB;
    RE::BSFixedString nodeName;
    RE::NiPointer<RE::NiAVObject> root3D;   // squelette (3e personne) de l'acteur A lors de la résolution
    RE::NiPointer<RE::NiNode> virtualNodeX;  // nœud résolu sur ce squelette
    RE::TESGlobal* globalVar{nullptr};
    float afOffsetX{0.0f};
    float afOffsetY{0.0f};
    float afOffsetZ{0.0f};
    float afRotationX{0.0f};
    float afRotationY{0.0f};
    float afRotationZ{0.0f};
    bool isAuthorized{false};

    void Reset() { *this = AttachmentData(); }
};

// FIX patch (C-12) : StartAttachment/StopAttachment (thread de la VM Papyrus) et le hook de mise à jour
// (thread principal) accèdent aux mêmes données.
inline std::mutex g_attachmentLock;

// FIX patch (N-26) : FormID de l'acteur attaché (0 = aucun). Lu par le hook de mouvement à chaque frame,
// sans verrou : l'IA du passager ne doit pas le déplacer pendant que UpdateActorPosition le replace sur la selle.
inline std::atomic<RE::FormID> g_attachedActorID{0};

class ActorCollisionManager : public RE::BSTEventSink<RE::TESCellAttachDetachEvent> {
public:
    [[nodiscard]] static auto GetSingleton() -> ActorCollisionManager* {
        static ActorCollisionManager singleton;
        return &singleton;
    }

    static void ManageActorCollision(RE::Actor* akActor, bool akEnable);
    void Install();
    static void RegisterEventSink();  // FIX patch (C-11)
    static void ResetForLoad();  // FIX patch (C-04) : appelé sur kPreLoadGame / kNewGame

    // Accès aux données d'attachement partagées
    AttachmentData& GetAttachmentData() { return _attachmentData; }
    const AttachmentData& GetAttachmentData() const { return _attachmentData; }

    // Event handler pour nettoyage automatique
    RE::BSEventNotifyControl ProcessEvent(const RE::TESCellAttachDetachEvent* a_event,
                                          RE::BSTEventSource<RE::TESCellAttachDetachEvent>* a_eventSource) override;

private:
    ActorCollisionManager() = default;
    ActorCollisionManager(const ActorCollisionManager&) = delete;
    ActorCollisionManager& operator=(const ActorCollisionManager&) = delete;

    static void Hook_ApplyMovementDelta(RE::Actor* a_actor, float a_delta);
    static void Hook_Collision(RE::Actor* a_actor);

    inline static REL::Relocation<decltype(Hook_ApplyMovementDelta)> _applyMovementDelta;

    // Données d'attachement partagées
    AttachmentData _attachmentData;

    // Timer pour le nettoyage périodique
    std::chrono::steady_clock::time_point lastCleanupTime;
};

// Fonctions utilitaires pour la gestion Havok sécurisée
namespace HavokUtils {
    bool IsHavokAttached(RE::Actor* actor);
    void SetHavokState(RE::Actor* actor, bool attached);
    void ForceCleanupActor(RE::FormID formID);
    void CleanupHavokStateMap();
    bool IsValidActorPointer(RE::Actor* actor);
    bool IsActorValid(RE::Actor* actor, const char* context);
    bool CanManipulateHavok(RE::Actor* actor);
}

// Fonctions principales de manipulation Havok
void MakeActorGhost(RE::Actor* actor);
void ReattachActorToHavok(RE::Actor* actor);