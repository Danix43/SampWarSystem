#include <a_samp>

#define FIXES_ServerVarMsg 0
#define FIXES_GetMaxPlayersMsg 0

#include <fixes> 
#include <izcmd>
#include <sscanf2>
#include <a_zone>
#include <strlib>
#include <samp_bcrypt>
#include <tdw_dialog>

#define BCRYPT_COST 12

#define DIALOG_LOGIN 1337
#define DIALOG_REGISTER 1338

enum {
    COLOR_RED = 0xFF0000,
        COLOR_GREEN = 0x7FFF00,
        COLOR_BLUE = 0x0FFFF,
        COLOR_PURPLE = 0x8A2BE2
}

enum Player {
    bool:isCivil;,
    mafia[9],
        rank,
        kills,
        deaths,
        bests,
        worths
}

// all turfs 
new turfs[24];

static DB:connection;

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
    createDBs();
    loadTurfs();
    return 1;
}

public OnGameModeExit() {
    if (db_close(connection)) {
        connection = DB:0;
    }
    return 1;
}

public OnPlayerConnect(playerid) {
    new query[100];

    new name[30];
    GetPlayerName(playerid, name, sizeof(name));

    format(query, sizeof(query), "SELECT player_name FROM 'Players' where player_name = '%s'", name);

    new DBResult:result = db_query(connection, query);

    if (db_num_rows(result) == 1) {
        OpenDialog(playerid, "loginPlayer", DIALOG_STYLE_PASSWORD, "Login", "Login using your password", "Login", "Cancel");
    } else if (db_num_rows(result) == 0) {
        OpenDialog(playerid, "registerPlayer", DIALOG_STYLE_PASSWORD, "Register", "Register using your password", "Register", "Cancel");
    }
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason) {
    SendDeathMessage(killerid, playerid, reason);

    if (killerid != INVALID_PLAYER_ID) {
        new playerKills = GetPVarInt(killerid, "kills");
        SetPVarInt(killerid, "kills", playerKills++);
        pointFromKill(playerid, killerid);
    }

    new playerDeaths = GetPVarInt(playerid, "deaths");
    SetPVarInt(playerid, "deaths", playerDeaths++);

    return 1;
}

// ----------------------- DB RELATED ----------------------- 

createDBs() {
    connection = db_open("data.db");

    if (connection) {} else {
        print("failed to connect to db");
    }
    new query[386] = "CREATE TABLE IF NOT EXISTS 'Players' (player_id INTEGER PRIMARY KEY, player_name TEXT NOT NULL UNIQUE, player_password TEXT NOT NULL, player_faction TEXT NOT NULL, faction_rank INTEGER NOT NULL, player_kills INTEGER, player_deaths INTEGER, player_bests INTEGER, player_worths INTEGER)";
    db_free_result(db_query(connection, query));

    query = "CREATE TABLE IF NOT EXISTS 'Turfs' (turf_id INTEGER PRIMARY KEY, turf_name TEXT NOT NULL, turf_number INTEGER NOT NULL, owner TEXT NOT NULL, owner_color TEXT NOT NULL, attacked TEXT NOT NULL DEFAULT 'false', minX REAL, minY REAL, maxX REAL, maxY REAL, poiX REAL, poiY REAL, poiZ REAL)";
    db_free_result(db_query(connection, query));

    query = "CREATE TABLE IF NOT EXISTS 'Wars' (war_id INTEGER PRIMARY KEY, turf_id INTEGER NOT NULL, defender TEXT NOT NULL, attacker TEXT NOT NULL, count INTEGER, FOREIGN KEY (turf_id) REFERENCES Turfs (turf_id))";
    db_free_result(db_query(connection, query));
}

loadTurfs() {
    new query[50];

    for (new i = 1; i <= 24; i++) {
        format(query, sizeof(query), "SELECT * FROM 'Turfs' WHERE turf_id = %d", i);

        new DBResult:queryResult = db_query(connection, query);
        if (db_num_rows(queryResult)) {
            new turfId;
            new turfName[15];
            new turfNumber;
            new turfOwner[5];
            new turfOwnerColor[11];
            new turfAttacked[6];
            new Float:turfMinX;
            new Float:turfMinY;
            new Float:turfMaxX;
            new Float:turfMaxY;

            turfId = db_get_field_assoc_int(queryResult, "turf_id");
            db_get_field_assoc(queryResult, "turf_name", turfName, sizeof(turfName));
            turfNumber = db_get_field_assoc_int(queryResult, "turf_number");
            db_get_field_assoc(queryResult, "owner", turfOwner, sizeof(turfOwner));
            db_get_field_assoc(queryResult, "owner_color", turfOwnerColor, sizeof(turfOwnerColor));
            db_get_field_assoc(queryResult, "attacked", turfAttacked, sizeof(turfAttacked));
            turfMinX = Float:db_get_field_assoc_float(queryResult, "minX");
            turfMinY = Float:db_get_field_assoc_float(queryResult, "minY");
            turfMaxX = Float:db_get_field_assoc_float(queryResult, "maxX");
            turfMaxY = Float:db_get_field_assoc_float(queryResult, "maxY");

            turfs[turfId] = CreateZone(turfMinX, turfMinY, turfMaxX, turfMaxY);
            CreateZoneBorders(turfs[turfId]);
            CreateZoneNumber(turfs[turfId], turfNumber, 0.7);

            db_next_row(queryResult);
        }
        db_free_result(queryResult);
    }
}

loadDataForAttack() {
    new query[100];
    new returnData[550];

    new headers[33];
    headers = "Turf Number\tTurf Name\tOwner\n";
    strcatmid(returnData, headers);

    for (new i = 1; i <= 24; i++) {
        format(query, sizeof(query), "SELECT turf_name, turf_number, owner, attacked FROM 'Turfs' WHERE turf_id = %d", i);

        new DBResult:queryResult = db_query(connection, query);
        if (db_num_rows(queryResult)) {
            new turfName[15];
            new turfNumber;
            new turfOwner[5];
            new turfAttacked[6];

            db_get_field_assoc(queryResult, "turf_name", turfName, sizeof(turfName));
            turfNumber = db_get_field_assoc_int(queryResult, "turf_number");
            db_get_field_assoc(queryResult, "owner", turfOwner, sizeof(turfOwner));
            db_get_field_assoc(queryResult, "attacked", turfAttacked, sizeof(turfAttacked));

            new trueStr[6];
            trueStr = "true";
            if (isequal(turfAttacked, trueStr)) {
                db_next_row(queryResult);
            }

            new temp[50];
            format(temp, sizeof(temp), "%d\t%s\t%s\n", turfNumber, turfName, turfOwner);

            strcatmid(returnData, temp);

            db_next_row(queryResult);
        }
        db_free_result(queryResult);
    }
    return returnData;
}

forward savePlayerStats(playerid);
public savePlayerStats(playerid) {

}

dialog loginPlayer(playerid, response, listitem, inputtext[]) {
    new name[30];
    GetPlayerName(playerid, name, sizeof(name));

    new query[512];

    format(query, sizeof(query), "SELECT player_password FROM 'Players' where player_name = '%s'", name);

    new DBResult:result = db_query(connection, query);

    if (db_num_rows(result)) {
        new playerPassword[250];

        db_get_field_assoc(result, "player_password", playerPassword, 250);

        bcrypt_verify(playerid, "OnPasswordVerify", inputtext, playerPassword);
    }
}

dialog registerPlayer(playerid, response, listitem, inputtext[]) {
    bcrypt_hash(playerid, "OnPasswordHash", inputtext, BCRYPT_COST);
}

dialog attack(playerid, response, listitem, inputtext[]) {
    if (response == 0) {
        return;
    }

    new message[100];
    format(message, sizeof(message), "Input: response: %d, listitem: %d, inputtext: %s", response, listitem, inputtext);

    SendClientMessage(playerid, 0xFFFFFFFF, message);
}

forward OnPasswordHash(playerid);
public OnPasswordHash(playerid) {
    new name[30];
    GetPlayerName(playerid, name, sizeof(name));

    new hashedPass[250];
    bcrypt_get_hash(hashedPass);

    new query[512];

    format(query, sizeof(query),
        "INSERT INTO 'Players' (player_name, player_password, player_faction, faction_rank) VALUES ('%s', '%s', 'Civilian', '0')", name, hashedPass);

    if (db_free_result(db_query(connection, query)) >= 1) {
        print("Insert query done");
    } else {
        print("Insert query failed");
    }
}

forward OnPasswordVerify(playerid, bool:success);
public OnPasswordVerify(playerid, bool:success) {
    if (success) {
        SendClientMessage(playerid, -1, "Your logged in!");
    } else {
        SendClientMessage(playerid, 0xFF0000, "Login failed!");
        SetTimerEx("KickWithDelay", 1000, false, "i", playerid);
    }
}

forward KickWithDelay(playerid);
public KickWithDelay(playerid) {
    Kick(playerid);
    return 1;
}

// ----------------------- CORE ----------------------- 

checkIfCivil(playername[]) {
    new query[150];

    format(query, sizeof(query), "SELECT player_faction FROM 'Players' WHERE player_name = '%s'", playername);

    new DBResult:queryResult = db_query(connection, query);

    if (db_num_rows(queryResult) == 1) {
        new playerFaction[10];

        db_get_field_assoc(queryResult, "player_faction", playerFaction, sizeof(playerFaction));

        db_free_result(queryResult);
        if (isequal(playerFaction, "Civilian")) {
            return true;
        } else {
            return false;
        }
    } else {
        return true;
    }
}

getPlayerFactionName(playername[]) {
    new query[150];

    format(query, sizeof(query), "SELECT player_faction, faction_rank FROM 'Players' WHERE player_name = '%s'", playername);

    new DBResult:result = db_query(connection, query);
    if (db_num_rows(result) == 1) {
        new playerFaction[9];

        db_get_field_assoc(result, "player_faction", playerFaction, sizeof(playerFaction));

        db_free_result(result);

        return playerFaction;
    } else {
        new response[9];
        response = "Civilian";
        return response;
    }
}

getPlayerFactionRank(playername[]) {
    new query[150];

    format(query, sizeof(query), "SELECT faction_rank FROM 'Players' WHERE player_name = '%s'", playername);

    new DBResult:result = db_query(connection, query);
    if (db_num_rows(result) == 1) {
        new factionRank = db_get_field_assoc_int(result, "faction_rank");

        db_free_result(result);

        return factionRank;
    } else {
        return 0;
    }
}

preparePlayersForWar() {
    SendClientMessageToAll(COLOR_PURPLE, "War-urile intre mafii vor incepe incurand!");
    SendClientMessageToAll(COLOR_PURPLE, "Toti mafiotii vor fi respawnati la HQ-uri in cateva secunde");
    for (new i = 0; j = GetPlayerPoolSize(); i <= j, i++) {
        if (IsPlayerConnected(i)) {
            new playerName[30];
            GetPlayerName(i, playerName, sizeof(playerName));

            if (!checkIfCivil(playerName)) {
                SpawnPlayer(i);
                SendClientMessage(i, COLOR_PURPLE, "Ai fost respawnat la HQ deoarece va incepe war-ul");
                SetPlayerVirtualWorld(i, 2);
            }
        }
    }

}

prepareTurf(turfIdForWar) {
    new query[150];
    format(query, sizeof(query), "SELECT turf_number FROM Turfs WHERE turf_id = %d", turfIdForWar);

    new DBResult:result = db_query(connection, query);

    if (db_num_rows(result)) {
        new turfNumber;
        turfNumber = db_get_field_assoc_int(result, "turf_number");
        GangZoneFlashForAll(turfs[turfNumber], 0xFFFFFFAA);
    }
    db_free_result(result);
}

displayWarTextDraw(playerid) {

}

getPlayersOnTurf(playerMafia[], poiX, poiY, poiZ) {
    new players;
    new j = GetPlayerPoolSize();
    for (new i = 0; i <= j; i++) {
        if (GetPlayerVirtualWorld(i) == 2) {
            new playerName[30];
            GetPlayerName(i, playerName, sizeof(playerName));

            if (IsPlayerInRangeOfPoint(i, 250, poiX, poiY, poiZ)) {
                if (isequal(getPlayerFactionName(playerName), playerMafia)) {
                    players = players + 1;
                }
            }
        }
    }
    return players;
}

pointFromKill(playerid, killerid) {
    if (GetPlayerVirtualWorld(playerid) == 2 && GetPlayerVirtualWorld(killerid) == 2) {
        // both are in war vw
        new killerFaction[9];
        new killerName[30];
        GetPlayerName(killerid, killerName, sizeof(killerName));
        killerFaction = getPlayerFactionName(killerName);

        new rdtName[9], spName[9];
        rdtName = "RDT";
        spName = "SP";
        if (isequal(killerFaction, rdtName)) {
            new pointRDT = GetSVarInt("pointsRDT");
            SetSVarInt("pointsRDT", (pointRDT + 1));
        } else if (isequal(killerFaction, spName)) {
            new pointSP = GetSVarInt("pointsSP");
            SetSVarInt("pointsSP", (pointSP + 1));
        }
    }
}

calculateBestPlayer(playerid) {
    new j = GetPlayerPoolSize();
    for (new i = 0; i <= j; i++) {
        if (GetPlayerVirtualWorld(playerid) == 2) {
            new playerKills = GetPVarInt(playerid, "kills");
            new playerDeaths = GetPVarInt(playerid, "deaths");

            new playerKDA = playerKills - playerDeaths;
        }
    }
}

calculateWorstPlayer(playerid) {

}

/*
use setimerex for time related activs
ex: settimerex(pointforinfluence, 30000);
    pointforinfluence() {
        checks for total players on turf 
        gives point for most of the same mafia on turf
    }
*/
new influenceTimer;
startWar() {
    new query[150];

    format(query, sizeof(query), "SELECT * FROM 'Wars' ORDER BY war_id ASC LIMIT 1");

    new DBResult:result = db_query(connection, query);
    if (db_num_rows(result)) {
        new defender[4];
        new attacker[4];
        new warCount;
        new turfId;

        db_get_field_assoc(result, "attacker", attacker, sizeof(attacker));
        db_get_field_assoc(result, "defender", defender, sizeof(defender));
        warCount = db_get_field_assoc_int(result, "count");
        turfId = db_get_field_assoc_int(result, "turf_id");

        new startMessage[50];
        format(startMessage, sizeof(startMessage), "%s vor ataca turf-ul %d detinut de mafia %s", attacker, turfId, defender);
        SendClientMessageToAll(COLOR_PURPLE, startMessage);

        prepareTurf(turfId);
        SetSVarInt("pointsRDT", 0);
        SetSVarInt("pointsSP", 0);
        SetSVarString("isWarOn", "true");

        influenceTimer = SetTimer("pointFromInfluence", 37500, true);

    } else {
        SendClientMessageToAll(COLOR_RED, "Nu exista war-uri pentru azi");
    }
    db_free_result(result);
}

forward pointFromInfluence(turfIdForWar);
public pointFromInfluence(turfIdForWar) {
    new query[150];
    format(query, sizeof(query), "SELECT poiX, poiY, poiZ FROM Turfs WHERE turf_id = %d", turfIdForWar);

    new DBResult:result = db_query(connection, query);

    if (db_num_rows(result)) {
        new Float:poiX, Float:poiY, Float:poiZ;

        poiX = db_get_field_assoc_float(result, "poiX");
        poiY = db_get_field_assoc_float(result, "poiY");
        poiZ = db_get_field_assoc_float(result, "poiZ");

        new playersRDT, playersSP;
        new rdtName[9];
        rdtName = "RDT";
        new spName[9];
        spName = "SP";
        playersRDT = getPlayersOnTurf(rdtName, poiX, poiY, poiZ);
        playersSP = getPlayersOnTurf(spName, poiX, poiY, poiZ);

        if (playersRDT > playersSP) {
            new pointRDT = GetSVarInt("pointsRDT");
            SetSVarInt("pointsRDT", (pointRDT + 1));
        } else if (playersRDT < playersSP) {
            new pointSP = GetSVarInt("pointsSP");
            SetSVarInt("pointsSP", (pointSP + 1));
        } else {}
    }
}

/*
should delete the played war from db
*/
endWar() {

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

COMMAND:help(playerid) {
    SendClientMessage(playerid, 0xF5E342FF, "Comenzi disponibile: ");
    SendClientMessage(playerid, 0xF5E342FF, "- /turfs - arata turfurile mafiilor");
    SendClientMessage(playerid, 0xF5E342FF, "- /order1-4 - pentru arme");
    SendClientMessage(playerid, 0xF5E342FF, "- /fvr - pentru a respawna toate masinile");
    SendClientMessage(playerid, 0xF5E342FF, "- /fvr (rdt / sp) - pentru a respawna masinile unei mafii");
    SendClientMessage(playerid, 0xF5E342FF, "- /setskin id - pentru a primi skinul dorit");
    SendClientMessage(playerid, 0xF5E342FF, "- /heal - pentru a primi heal");
    return 1;
}

COMMAND:id(playerid, params[]) {
    new id;
    if (sscanf(params, "u", id)) {
        SendClientMessage(playerid, COLOR_RED, "Foloseste: /id [id|nume player]");
    } else {
        SendClientMessage(playerid, COLOR_GREEN, "Inca nu s-a adaugat, asa ca asteapta in morti tai");
    }
    return 1;
}

// need to fix colors
COMMAND:turfs(playerid, params[]) {
    new query[150];

    format(query, sizeof(query), "SELECT turf_id, owner_color FROM 'Turfs'");

    new DBResult:result = db_query(connection, query);
    for (new i = 1; i <= db_num_rows(result); i++) {
        new turfId;
        new turfOwnerColor[11];

        turfId = db_get_field_assoc_int(result, "turf_id");
        db_get_field_assoc(result, "owner_color", turfOwnerColor, sizeof(turfOwnerColor));
        new turfOwnerColorInt = strval(turfOwnerColor);

        ShowZoneForPlayer(playerid, turfs[turfId], 0xFF000055, 0xFFFFFFFF, 0xFFFFFFFF);

        db_next_row(result);
    }
    db_free_result(result);
    return 1;
}

/*
 - attack a turf
 should be only 4 attacks on a sesh
*/
COMMAND:attack(playerid, params[]) {
    new turfData[550];
    turfData = loadDataForAttack();

    OpenDialog(playerid, "attack", DIALOG_STYLE_TABLIST_HEADERS,
        "Attack Menu",
        turfData,
        "Attack", "");
    return 1;
}