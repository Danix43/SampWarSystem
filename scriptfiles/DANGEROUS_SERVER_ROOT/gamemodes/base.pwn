#include <a_samp>
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

// ----------------------- DB RELATED ----------------------- 

createDBs() {
    connection = db_open("data.db");

    if (connection) {
        print("connected to db");
    } else {
        print("failed to connect to db");
    }

    new query[256] = "CREATE TABLE IF NOT EXISTS 'Players' (player_id INTEGER PRIMARY KEY, player_name TEXT NOT NULL UNIQUE, player_password TEXT NOT NULL, player_faction TEXT NOT NULL, faction_rank TEXT NOT NULL)";
    db_free_result(db_query(connection, query));
    print("player database loaded");
    //                                                                                                                                  Float:gzMinX, Float:gzMinY, Float:gzMaxX, Float:gzMaxY
    query = "CREATE TABLE IF NOT EXISTS 'Turfs' (turf_id INTEGER PRIMARY KEY, owner TEXT NOT NULL, owner_color TEXT NOT NULL, minX INTEGER, minY INTEGER, maxX INTEGER, maxY INTEGER)";
    db_free_result(db_query(connection, query));
    print("turfs database loaded");
}

loadTurfs() {
    new query[200];

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

    }
    return 1;
}

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

        ShowZoneForPlayer(playerid, turfs[turfId], 0xFF000073, 0xFFFFFFAA, 0xFFFFFFAA);

        db_next_row(result);
    }
    db_free_result(result);
    return 1;
}