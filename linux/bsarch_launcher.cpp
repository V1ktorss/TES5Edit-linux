#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <iostream>
#include <string>
#include <vector>
#include <unistd.h>

static int run_exec(const std::string &bin, const std::vector<std::string> &args) {
    std::vector<char *> argv;
    argv.reserve(args.size() + 2);
    argv.push_back(const_cast<char *>(bin.c_str()));
    for (const auto &a : args) {
        argv.push_back(const_cast<char *>(a.c_str()));
    }
    argv.push_back(nullptr);
    execv(bin.c_str(), argv.data());
    return errno;
}

int main(int argc, char **argv) {
    namespace fs = std::filesystem;
    fs::path self = fs::canonical(argv[0]);
    fs::path root = self.parent_path();
    fs::path real_bin = root / "linux" / "bin" / "bsarch-core";
    fs::path ui = root / "linux" / "bsarch-ui.sh";

    if (!fs::exists(real_bin)) {
        std::cerr << "Missing real binary: " << real_bin << "\n";
        return 1;
    }

    if (argc > 1) {
        std::vector<std::string> args;
        for (int i = 1; i < argc; ++i) {
            args.emplace_back(argv[i]);
        }
        int ec = run_exec(real_bin.string(), args);
        std::cerr << "Failed to exec real binary: " << std::strerror(ec) << "\n";
        return 1;
    }

    setenv("BSARCH_BIN", real_bin.c_str(), 1);
    const char *disp = std::getenv("DISPLAY");
    const char *way = std::getenv("WAYLAND_DISPLAY");
    if ((disp && *disp) || (way && *way)) if (fs::exists(ui)) {
        int ec = run_exec(ui.string(), {});
        std::cerr << "Failed to exec UI launcher: " << std::strerror(ec) << "\n";
    }

    int ec = run_exec(real_bin.string(), {});
    std::cerr << "Failed to exec real binary: " << std::strerror(ec) << "\n";
    return 1;
}
