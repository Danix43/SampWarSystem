#include <a_samp>
#include <izcmd>

#define FILTERSCRIPT

main() {
    print("Filterscript loaded in main");
}

public OnFilterScriptInit() {
    print("Weapon order filterscript loaded");
}

public OnFilterScriptExit() {
    print("Weapon order filterscript unloaded");
}

// -------------------- COMMANDS --------------------  

COMMAND:order1(playerid, params[]) {
    if (GetPlayerInterior(playerid) != 0) {
        GivePlayerWeapon(playerid, 24, 150);
        SendClientMessage(playerid, 0x000000FF, "Given order 1");
    }
    return 1;
}

COMMAND:order2(playerid, params[]) {
    if (GetPlayerInterior(playerid) != 0) {
        GivePlayerWeapon(playerid, 24, 150);
        GivePlayerWeapon(playerid, 31, 150);
        SendClientMessage(playerid, 0x000000FF, "Given order 2");
    }
    return 1;
}

COMMAND:order3(playerid, params[]) {
    if (GetPlayerInterior(playerid) != 0) {
        GivePlayerWeapon(playerid, 24, 150);
        GivePlayerWeapon(playerid, 31, 150);
        GivePlayerWeapon(playerid, 33, 150);
        SendClientMessage(playerid, 0x000000FF, "Given order 3");
    }
    return 1;
}

COMMAND:order4(playerid, params[]) {
    GivePlayerWeapon(playerid, 24, 150);
    GivePlayerWeapon(playerid, 31, 150);
    GivePlayerWeapon(playerid, 33, 150);
    GivePlayerWeapon(playerid, 32, 150);
    GivePlayerWeapon(playerid, 27, 150);
    SendClientMessage(playerid, 0xFFFFFF, "Given order 4");
    return 1;
}