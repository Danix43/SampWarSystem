#include <a_samp>
#include <izcmd>

main() {
    print("Filterscript loaded in main");
}

public OnFilterScriptInit() {
    print("Weapon order filterscript loaded");
}

public OnFilterScriptExit() {
    print("Weapon order filterscript unloaded");
}
