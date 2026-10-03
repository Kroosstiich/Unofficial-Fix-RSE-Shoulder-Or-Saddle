#pragma once
#include <string>
#include <spdlog/spdlog.h>

class Config {
public:
    static Config& GetSingleton() {
        static Config instance;
        return instance;
    }

    // Paramètres de logging
    struct LogSettings {
        std::string level = "info";           // trace, debug, info, warn, error, critical
        bool flushOnInfo = true;
        bool enableConsole = false;
        std::string fileName = "RideSharingExpandedFollowerSKSE.log";
    } log;

    // Charger la configuration depuis le fichier TOML
    void Load();

    // Obtenir le niveau de log depuis la string
    spdlog::level::level_enum GetLogLevel() const;

private:
    Config() = default;
    ~Config() = default;
    Config(const Config&) = delete;
    Config& operator=(const Config&) = delete;
};