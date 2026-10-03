#include <RE/Skyrim.h>
#include <SKSE/SKSE.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <spdlog/sinks/msvc_sink.h>
#include "HooksRSE-FH.h"
#include "ActorCollisionManagerRSE-FH.h"
#include "ConfigRSE-H.h"

using namespace SKSE;
using namespace RE;
using namespace SKSE;

// Fonction B : Mise à jour légère de la position (appelée chaque frame si autorisée)
// Appelée sous g_attachmentLock depuis le hook de mise à jour (thread principal)
void UpdateActorPosition() {
    auto manager = ActorCollisionManager::GetSingleton();
    auto& data = manager->GetAttachmentData();

    // FIX patch (C-03) : acteurs via handles (nullptr si l'acteur a été déchargé ou supprimé)
    auto actorAPtr = data.actorA.get();
    auto actorBPtr = data.actorB.get();
    if (!actorAPtr || !actorBPtr) {
        return;
    }

    // FIX patch (C-03/C-13) : squelette 3e personne ; nœud re-résolu si le 3D de l'acteur A a changé
    auto actorA3D = actorAPtr->Get3D(false);
    if (!actorA3D) {
        return;
    }
    if (actorA3D != data.root3D.get() || !data.virtualNodeX) {
        auto nodeObj = actorA3D->GetObjectByName(data.nodeName);
        auto node = nodeObj ? nodeObj->AsNode() : nullptr;
        if (!node) {
            return;
        }
        data.root3D.reset(actorA3D);
        data.virtualNodeX.reset(node);
    }

    // Extraire les angles d'Euler de la matrice de rotation du virtualNodeX
    RE::NiMatrix3& rotMatrix = data.virtualNodeX->world.rotate;

    // Calculer les angles d'Euler à partir de la matrice de rotation
    // Format de rotation ZXY utilisé par Skyrim
    float nodeRotX, nodeRotY, nodeRotZ;

    // Extraction des angles (ordre ZXY)
    if (rotMatrix.entry[2][1] < 1.0f) {
        if (rotMatrix.entry[2][1] > -1.0f) {
            nodeRotX = asin(-rotMatrix.entry[2][1]);
            nodeRotZ = atan2(rotMatrix.entry[0][1], rotMatrix.entry[1][1]);
            nodeRotY = atan2(rotMatrix.entry[2][0], rotMatrix.entry[2][2]);
        } else {
            // Gimbal lock cas 1
            nodeRotX = 1.57079632679f;  // PI/2
            nodeRotZ = -atan2(-rotMatrix.entry[0][2], rotMatrix.entry[0][0]);
            nodeRotY = 0.0f;
        }
    } else {
        // Gimbal lock cas 2
        nodeRotX = -1.57079632679f;  // -PI/2
        nodeRotZ = atan2(-rotMatrix.entry[0][2], rotMatrix.entry[0][0]);
        nodeRotY = 0.0f;
    }

    // Appliquer les offsets de rotation personnalisés
    auto targetAngle = actorBPtr->data.angle;
    targetAngle.x = nodeRotX + data.afRotationX;
    targetAngle.y = nodeRotY + data.afRotationY;
    targetAngle.z = nodeRotZ + data.afRotationZ;
    actorBPtr->data.angle = targetAngle;

    // Calculer la position du node X avec l'offset X,Y,Z
    RE::NiPoint3 offset(data.afOffsetX, data.afOffsetY, data.afOffsetZ);
    RE::NiPoint3 worldOffset = rotMatrix * offset;
    RE::NiPoint3 targetPos = data.virtualNodeX->world.translate + worldOffset;

    // Mettre à jour la position de l'Actor B
    actorBPtr->SetPosition(targetPos, false);
    actorBPtr->Update3DPosition(false);
}

// Hook pour le Update du jeu (appelé chaque frame sur le thread principal)
class UpdateHook {
public:
    static void Install() {
        // Utiliser PlayerCharacter::Update pour avoir un hook fiable chaque frame
        REL::Relocation<std::uintptr_t> pcVtbl{RE::VTABLE_PlayerCharacter[0]};
        _Update = pcVtbl.write_vfunc(0xAD, Update);

        log::info("Update hook installer");
    }

private:
    static void Update(RE::PlayerCharacter* a_this, float a_delta) {
        _Update(a_this, a_delta);

        auto manager = ActorCollisionManager::GetSingleton();
        std::lock_guard lock(g_attachmentLock);  // FIX patch (C-12)
        auto& data = manager->GetAttachmentData();

        // Vérifier si la fonction B est autorisée ET si la GlobalVariable = 1
        if (data.isAuthorized && data.globalVar && data.globalVar->value == 1.0f) {
            UpdateActorPosition();
        }
    }

    static inline REL::Relocation<decltype(Update)> _Update;
};

// Fonction A : Initialisation de l'attachement
void StartAttachmentHorse(RE::StaticFunctionTag*, RE::Actor* actorA, RE::BSFixedString nodeName, RE::Actor* actorB,
                     float offsetX, float offsetY, float offsetZ, float rotationX, float rotationY,
                     float rotationZ,  // NOUVEAUX PARAMÈTRES
                     RE::TESGlobal* globalVar) {

    if (!HavokUtils::IsActorValid(actorB, "StartAttachment")) {
        log::error("ActorB est dans un état invalide, attachement annulé");
        return;
    }

    if (!actorA || !actorB || !globalVar) {
        log::error("Parametres invalides pour StartAttachment");
        return;
    }

    log::info("Attachement demarre");

    auto manager = ActorCollisionManager::GetSingleton();

    // Récupérer le 3D de l'Actor A (FIX patch C-13 : squelette 3e personne)
    auto actorA3D = actorA->Get3D(false);
    if (!actorA3D) {
        log::error("Actor A n'a pas de 3D");
        return;
    }

    // Récupérer le Node X
    auto nodeX = actorA3D->GetObjectByName(nodeName.c_str());
    if (!nodeX) {
        log::error("Node '{}' introuvable sur Actor A", nodeName.c_str());
        return;
    }

    // Cast du node X en NiNode
    auto nodeXAsNode = nodeX->AsNode();
    if (!nodeXAsNode) {
        log::error("Le node '{}' n'est pas un NiNode", nodeName.c_str());
        return;
    }

    // Stocker les données (FIX patch C-03/C-12 : handles, références comptées, sous verrou)
    std::unique_lock lock(g_attachmentLock);
    auto& data = manager->GetAttachmentData();
    data.actorA = actorA->GetHandle();
    data.actorB = actorB->GetHandle();
    data.nodeName = nodeName;
    data.root3D.reset(actorA3D);
    data.virtualNodeX.reset(nodeXAsNode);
    data.globalVar = globalVar;
    data.afOffsetX = offsetX;
    data.afOffsetY = offsetY;
    data.afOffsetZ = offsetZ;
    data.afRotationX = rotationX;  // NOUVEAU
    data.afRotationY = rotationY;  // NOUVEAU
    data.afRotationZ = rotationZ;  // NOUVEAU

    data.isAuthorized = true;  // Autoriser la fonction B à tourner
    lock.unlock();

    ActorCollisionManager::ManageActorCollision(actorB, false);

    log::info("Attachement démarré : Actor A={}, Node={}, Actor B={}, Offset=({},{},{}), Rotation=({},{},{})",
              actorA->GetFormID(), nodeName.c_str(), actorB->GetFormID(), offsetX, offsetY, offsetZ, rotationX,
              rotationY, rotationZ);

    return;
}

// Fonction pour arrêter l'attachement
// FIX patch : le paramètre Actor est déclaré dans le .psc (Stop…(Actor actorB)) ; sans lui la VM refusait de lier la fonction.
void StopAttachmentHorse(RE::StaticFunctionTag*, RE::Actor*) {
    auto manager = ActorCollisionManager::GetSingleton();
    RE::NiPointer<RE::Actor> actorBPtr;
    {
        std::lock_guard lock(g_attachmentLock);  // FIX patch (C-12)
        auto& data = manager->GetAttachmentData();
        actorBPtr = data.actorB.get();
        // Désautoriser la fonction B
        data.Reset();
    }

    if (actorBPtr) {
        ActorCollisionManager::ManageActorCollision(actorBPtr.get(), true);
    }

    log::info("Attachement arrêté");
}

// Enregistrement des fonctions Papyrus
bool RegisterPapyrusFunctions(RE::BSScript::IVirtualMachine* vm) {
    vm->RegisterFunction("StartAttachmentHorse", "RSEHorseSKSE", StartAttachmentHorse);
    vm->RegisterFunction("StopAttachmentHorse", "RSEHorseSKSE", StopAttachmentHorse);

    log::info("Fonctions Papyrus enregistrées");
    return true;
}

// NOUVEAU : Fonction pour initialiser le logging avec la configuration
void InitializeLogging() {
    auto path = SKSE::log::log_directory();
    if (!path) {
        return;
    }

    // Charger la configuration
    auto& config = Config::GetSingleton();
    config.Load();

    // Créer le chemin du fichier de log
    *path /= config.log.fileName;

    // Créer les sinks selon la configuration
    std::vector<spdlog::sink_ptr> sinks;
    
    // Sink fichier (toujours actif)
    auto file_sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>(path->string(), true);
    sinks.push_back(file_sink);
    
    // Sink console (optionnel)
    if (config.log.enableConsole) {
        auto console_sink = std::make_shared<spdlog::sinks::msvc_sink_mt>();
        sinks.push_back(console_sink);
    }

    // Créer le logger avec tous les sinks
    auto logger = std::make_shared<spdlog::logger>("global log", sinks.begin(), sinks.end());
    
    // Configurer le niveau de log
    logger->set_level(config.GetLogLevel());
    
    // Configurer le flush
    if (config.log.flushOnInfo) {
        logger->flush_on(spdlog::level::info);
    } else {
        logger->flush_on(spdlog::level::warn);
    }

    spdlog::set_default_logger(std::move(logger));
    
    log::info("==============================================");
    log::info("RideSharingExpandedHorseSKSE Plugin Initialized");
    log::info("==============================================");
}

// Point d'entrée du plugin
SKSEPluginLoad(const LoadInterface* skse) {
    Init(skse);

    // MODIFIÉ : Initialisation du logging avec configuration
    InitializeLogging();

    log::info("Plugin chargé");

    // Installer le hook pour le Update
    SKSE::GetMessagingInterface()->RegisterListener([](MessagingInterface::Message* msg) {
        switch (msg->type) {
        case MessagingInterface::kDataLoaded:
            UpdateHook::Install();
            ActorCollisionManager::RegisterEventSink();  // FIX patch (C-11)
            break;
        case MessagingInterface::kPreLoadGame:  // FIX patch (C-04)
        case MessagingInterface::kNewGame:
            ActorCollisionManager::ResetForLoad();
            break;
        default:
            break;
        }
    });

    // Enregistrer les fonctions Papyrus
    auto papyrus = SKSE::GetPapyrusInterface();
    if (papyrus) {
        papyrus->Register(RegisterPapyrusFunctions);
    }

    SKSE::AllocTrampoline(1 << 4);

    // Installer le gestionnaire de collisions

    Hooks::Install();

    log::info("Hook installé");

    return true;
}