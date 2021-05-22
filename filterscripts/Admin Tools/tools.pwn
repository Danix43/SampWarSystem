#define FILTERSCRIPT

#include <a_samp>
#include <izcmd>
#include <sscanf2>
#include <strlib>

static DB:connection;

enum {
    COLOR_RED = 0xFF0000FF,
        COLOR_GREEN = 0x00FF00FF,
        COLOR_BLUE = 0x00FFFFFF,
        COLOR_PURPLE = 0x8A2BE2FF,
        COLOR_GREY = 0xAAAAAAFF,
        COLOR_WHITE = 0xFFFFFFFF,
        COLOR_YELLOW = 0xFFFF00FF
}

// PRESSED(keys)
#define PRESSED(%0) \
(((newkeys & ( % 0)) == ( % 0)) && ((oldkeys & ( % 0)) != ( % 0)))

// ----------------------- GAME CALLBACKS ----------------------- 

public OnFilterScriptInit() {
    loadDB();
    print("Admin Components loaded");
}

public OnFilterScriptExit() {
    if (db_close(connection)) {
        connection = DB:0;
    }
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    if ((newkeys & KEY_SECONDARY_ATTACK) && !(oldkeys & KEY_SECONDARY_ATTACK)) {

    }
    return 1;
}

// ----------------------- SETUPS ----------------------- 

loadDB() {
    connection = db_open("data.db");

    if (connection) {

    } else {
        print("failed to connect to db");
    }
}
// --------------------- COMMANDS --------------------- 

COMMAND:spec(playerid, params[]) {
    if (IsPlayerAdmin(playerid)) {
        new takerId;
        if (sscanf(params, "r", takerId)) {
            SendClientMessage(playerid, COLOR_RED, "Foloseste: /spec <id | nume player>");
            return 1;
        } else {
            return 1;
        }
    } else {
        SendClientMessage(playerid, COLOR_RED, "Nu poti folosi acesta comanda deoarece nu esti admin!");
        return 1;
    }
}

COMMAND:ban(playerid, params[]) {
    if (IsPlayerAdmin(playerid)) {
        new takerId;
        new banReason[100];
        if (sscanf(params, "us[100]", takerId, banReason)) {
            SendClientMessage(playerid, COLOR_RED, "Foloseste: /ban [id / nume player] [motiv kick]");
            return 1;
        } else {
            if (IsPlayerConnected(takerId)) {
                new takerName[MAX_PLAYER_NAME];
                GetPlayerName(takerId, takerName, sizeof(takerName));

                new query[100];
                format(query, sizeof(query), "UPDATE Players SET isBanned = 1, banReason = %s WHERE name = %s;", banReason, takerName);

                new DBResult:queryResult = db_query(connection, query);
                if (db_num_rows(queryResult)) {
                    new message[144];
                    format(message, sizeof(message), "Jucatorul %s a primit ban! Motiv: %s", takerName, banReason);
                    SendClientMessageToAll(COLOR_RED, message);
                    SetTimerEx("KickWithDelay", 1000, false, "i", takerId);
                    db_free_result(queryResult);
                    return 1;
                } else {
                    SendClientMessage(playerid, COLOR_RED, "Eroare la banarea playerului!");\
                    db_free_result(queryResult);
                    return 1;
                }
            } else {
                SendClientMessage(playerid, COLOR_RED, "Playerul nu este conectat!");
                return 1;
            }
        }
    } else {
        SendClientMessage(playerid, COLOR_RED, "Nu poti folosi acesta comanda deoarece nu esti admin!");
        return 1;
    }
}

COMMAND:kick(playerid, params[]) {
    if (IsPlayerAdmin(playerid)) {
        new takerId;
        new kickReason[100];
        if (sscanf(params, "us[100]", takerId, kickReason)) {
            SendClientMessage(playerid, COLOR_RED, "Foloseste: /kick [id / nume player] [motiv kick]");
            return 1;
        } else {
            if (IsPlayerConnected(takerId)) {
                new takerName[MAX_PLAYER_NAME];
                GetPlayerName(takerId, takerName, sizeof(takerName));

                new message[144];
                format(message, sizeof(message), "Jucatorul %s a primit kick! Motiv: %s", takerName, kickReason);
                SendClientMessageToAll(COLOR_RED, message);
                SetTimerEx("KickWithDelay", 1000, false, "i", takerId);
                return 1;
            } else {
                SendClientMessage(playerid, COLOR_RED, "Playerul nu este conectat!");
                return 1;
            }
        }
    } else {
        SendClientMessage(playerid, COLOR_RED, "Nu poti folosi acesta comanda deoarece nu esti admin!");
        return 1;
    }
}

COMMAND:slap(playerid, params[]) {
    if (IsPlayerAdmin(playerid)) {
        new takerId;
        if (sscanf(params, "u", takerId)) {
            SendClientMessage(playerid, COLOR_RED, "Foloseste: /slap [id | nume player]!");
            return 1;
        } else {
            new giverName[MAX_PLAYER_NAME];
            GetPlayerName(playerid, giverName, sizeof(giverName));

            new Float:playerPosX, Float:playerPosY, Float:playerPosZ;
            GetPlayerPos(takerId, playerPosX, playerPosY, playerPosZ);

            SetPlayerPos(takerId, playerPosX, playerPosY, (playerPosZ + 2));

            new message[100];
            format(message, sizeof(message), "Ai primit slap de la adminul %s!", giverName);
            SendClientMessage(takerId, COLOR_YELLOW, message);
            return 1;
        }
    } else {
        SendClientMessage(playerid, COLOR_RED, "Nu poti folosi acesta comanda deoarece nu esti admin!");
        return 1;
    }
}

COMMAND:pm(playerid, params[]) {
    if (IsPlayerAdmin(playerid)) {
        new takerId;
        new pmMessage[120];
        if (sscanf(params, "us[120]", takerId, pmMessage)) {
            SendClientMessage(playerid, COLOR_RED, "Foloseste: /pm [id | nume player] [mesaj]");
            return 1;
        } else {
            if (IsPlayerConnected(takerId)) {

                new giverName[MAX_PLAYER_NAME];
                GetPlayerName(playerid, giverName, sizeof(giverName));

                new messageToPlayer[120 + MAX_PLAYER_NAME];
                format(messageToPlayer, sizeof(messageToPlayer), "Admin %s : %s", giverName, pmMessage);

                SendClientMessage(playerid, COLOR_YELLOW, messageToPlayer);
                SendClientMessage(takerId, COLOR_YELLOW, messageToPlayer);
                return 1;
            } else {
                SendClientMessage(playerid, COLOR_RED, "Playerul nu este conectat!");
                return 1;
            }
        }
    } else {
        SendClientMessage(playerid, COLOR_RED, "Nu poti folosi acesta comanda deoarece nu esti admin!");
        return 1;
    }
}

COMMAND:skemamilsugiana(playerid, params[]) {
    return 1;
}