#include "ConfigRSE-F.h"
#include <fstream>
#include <filesystem>
#include <SKSE/SKSE.h>
#include "SimpleIni.h"

void Config::Load() {
    auto configPath = std::filesystem::path("Data/SKSE/Plugins/RSEFollowerSKSE.ini");
    
    CSimpleIniA ini;
    ini.SetUnicode();
    
    // Si le fichier n'existe pas, créer une configuration par défaut
    if (!std::filesystem::exists(configPath)) {
        SKSE::log::info("Configuration file not found, creating default: {}", configPath.string());
        
        ini.SetValue("Logging", "level", "info", "; Log level: trace, debug, info, warn, error, critical");
        ini.SetBoolValue("Logging", "flushOnInfo", true, "; Flush logs immediately on info messages");
        ini.SetBoolValue("Logging", "enableConsole", false, "; Enable console output (in addition to file)");
        ini.SetValue("Logging", "fileName", "RideSharingExpandedFollowerSKSE.log", "; Log file name");
        
        ini.SaveFile(configPath.string().c_str());
        return;
    }

    // Charger le fichier INI
    SI_Error rc = ini.LoadFile(configPath.string().c_str());
    if (rc < 0) {
        SKSE::log::error("Failed to load config file: {}", configPath.string());
        return;
    }

    // Lire les paramètres de logging
    log.level = ini.GetValue("Logging", "level", "info");
    log.flushOnInfo = ini.GetBoolValue("Logging", "flushOnInfo", true);
    log.enableConsole = ini.GetBoolValue("Logging", "enableConsole", false);
    log.fileName = ini.GetValue("Logging", "fileName", "RideSharingExpandedFollowerSKSE.log");
    
    SKSE::log::info("Configuration loaded successfully");
    SKSE::log::info("  Log level: {}", log.level);
    SKSE::log::info("  Flush on info: {}", log.flushOnInfo);
    SKSE::log::info("  Console output: {}", log.enableConsole);
    SKSE::log::info("  Log file: {}", log.fileName);
}

spdlog::level::level_enum Config::GetLogLevel() const {
    if (log.level == "trace") return spdlog::level::trace;
    if (log.level == "debug") return spdlog::level::debug;
    if (log.level == "info") return spdlog::level::info;
    if (log.level == "warn") return spdlog::level::warn;
    if (log.level == "error") return spdlog::level::err;
    if (log.level == "critical") return spdlog::level::critical;
    
    // Par défaut
    return spdlog::level::info;
}