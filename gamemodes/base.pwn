#include <a_samp>
#include <izcmd>
#include <sscanf2>
#include <a_zone>

// all turfs 
new turfs[25];

main() {
    print("\n----------------------------------");
    print("      War Between Mafia System");
    print("             By Danix43");
    print("----------------------------------\n");
}

public OnGameModeInit() {
    SetGameModeText("War Between Mafia System");
    UsePlayerPedAnims();
    DisableInteriorEnterExits();
    loadTurfs();
    return 1;
}

public OnGameModeExit() {
    return 1;
}

loadTurfs() {
    turfs[0] = CreateZone(899, 1948.5, 1308, 2413.5);
    CreateZoneBorders(turfs[0]);
    turfs[1] = CreateZone(899.0001220703125, 1483.4999794960022, 1308.0001220703125, 1948.4999794960022);
    CreateZoneBorders(turfs[1]);
    turfs[2] = CreateZone(1308.0001220703125, 1483.5, 1717.0001220703125, 1948.5);
    CreateZoneBorders(turfs[2]);
    turfs[3] = CreateZone(1308.0001220703125, 1948.499984741211, 1717.0001220703125, 2413.499984741211);
    CreateZoneBorders(turfs[3]);
    turfs[4] = CreateZone(1308.9921875, 2413.5, 1717.9921875, 2878.5);
    CreateZoneBorders(turfs[4]);
    turfs[5] = CreateZone(898.9921875, 1019.5, 1307.9921875, 1484.5);
    CreateZoneBorders(turfs[5]);

    turfs[6] = CreateZone(1308.9921875, 1018.5, 1717.9921875, 1484.5);
    CreateZoneBorders(turfs[6]);
    turfs[7] = CreateZone(1718, 1491.015625, 2127, 1956.015625);
    CreateZoneBorders(turfs[7]);
    turfs[8] = CreateZone(2127.9921875, 1487.0234375, 2536.9921875, 1956.0234375);
    CreateZoneBorders(turfs[8]);
    turfs[9] = CreateZone(2535.984375, 1491.0234375, 2944.984375, 1956.0234375);
    CreateZoneBorders(turfs[9]);
    turfs[10] = CreateZone(1718, 1948.5, 2127, 2413.5);
    CreateZoneBorders(turfs[10]);
    turfs[11] = CreateZone(1718, 1026.0234375, 2127, 1491.0234375);
    CreateZoneBorders(turfs[11]);

    turfs[12] = CreateZone(2127.984375, 1021.0234375, 2536.984375, 1486.0234375);
    CreateZoneBorders(turfs[12]);
    turfs[13] = CreateZone(2535.984375, 1026.0234375, 2944.984375, 1491.0234375);
    CreateZoneBorders(turfs[13]);
    turfs[14] = CreateZone(1718.984375, 2413.5, 2127.984375, 2878.5);
    CreateZoneBorders(turfs[14]);
    turfs[15] = CreateZone(2127.9921875, 1948.5, 2536.9921875, 2413.5);
    CreateZoneBorders(turfs[15]);
    turfs[16] = CreateZone(2128.9765625, 2413.5, 2537.9765625, 2878.5);
    CreateZoneBorders(turfs[16]);
    turfs[17] = CreateZone(1308.9921875, 554.5078125, 1717.9921875, 1019.5078125);
    CreateZoneBorders(turfs[17]);

    turfs[18] = CreateZone(900.9921875, 554.5078125, 1309.9921875, 1019.5078125);
    CreateZoneBorders(turfs[18]);
    turfs[19] = CreateZone(1716.984375, 561.0234375, 2125.984375, 1026.0234375);
    CreateZoneBorders(turfs[19]);
    turfs[20] = CreateZone(2127.9921875, 561.0234375, 2536.9921875, 1026.0234375);
    CreateZoneBorders(turfs[20]);
    turfs[21] = CreateZone(2535.984375, 561.0234375, 2944.984375, 1026.0234375);
    CreateZoneBorders(turfs[21]);
    turfs[22] = CreateZone(2535.984375, 1956.0234375, 2944.984375, 2421.0234375);
    CreateZoneBorders(turfs[22]);
    turfs[23] = CreateZone(2535.984375, 2413.5, 2944.984375, 2878.5);
    CreateZoneBorders(turfs[23]);
}

public OnPlayerRequestClass(playerid, classid) {
    SetSpawnInfo(playerid, 0, 0, 1958.33, 1343.12, 15.36, 269.15, 0, 0, 0, 0, 0, 0);
    SpawnPlayer(playerid);
}

public OnPlayerConnect(playerid) {
    return 1;
}

public OnPlayerDisconnect(playerid, reason) {
    return 1;
}

public OnPlayerSpawn(playerid) {
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason) {
    return 1;
}

public OnVehicleSpawn(vehicleid) {
    return 1;
}

public OnVehicleDeath(vehicleid, killerid) {
    return 1;
}

public OnPlayerText(playerid, text[]) {
    return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger) {
    return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid) {
    return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate) {
    return 1;
}

public OnPlayerEnterCheckpoint(playerid) {
    return 1;
}

public OnPlayerLeaveCheckpoint(playerid) {
    return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid) {
    return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid) {
    return 1;
}

public OnRconCommand(cmd[]) {
    return 1;
}

public OnPlayerRequestSpawn(playerid) {
    return 1;
}

public OnObjectMoved(objectid) {
    return 1;
}

public OnPlayerObjectMoved(playerid, objectid) {
    return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid) {
    return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid) {
    return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid) {
    return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2) {
    return 1;
}

public OnPlayerSelectedMenuRow(playerid, row) {
    return 1;
}

public OnPlayerExitedMenu(playerid) {
    return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid) {
    return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    return 1;
}

public OnRconLoginAttempt(ip[], password[], success) {
    return 1;
}

public OnPlayerUpdate(playerid) {
    return 1;
}

public OnPlayerStreamIn(playerid, forplayerid) {
    return 1;
}

public OnPlayerStreamOut(playerid, forplayerid) {
    return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid) {
    return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid) {
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
    return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source) {
    return 1;
}

// ----------------------- COMMANDS ----------------------- 

COMMAND:setskin(playerid, params[]) {
    new skinid;
    if (sscanf(params, "i", skinid)) {
        SendClientMessage(playerid, -1, "Foloseste: /setskin [skinid]");
    } else {
        SetPlayerSkin(playerid, skinid);
    }
    return 1;
}

COMMAND:turfs(playerid, params[]) {
    new i;
    for (i = 0; i < 23; i++) {
        ShowZoneForPlayer(playerid, turfs[i], 0xFF000073, 0xFFFFFFAA, 0xFFFFFFAA);
    }
    return 1;
}