#define FILTERSCRIPT

#include <a_samp>
#include <nex-ac>

new Text:tdTime;
new Text:tdDate;
new PlayerText:tdPlayerName[MAX_PLAYERS];

new PlayerText:tdLoginTitle[MAX_PLAYERS];

main() {}

// -------------------- CALLBACKS --------------------

public OnFilterScriptInit() {
    print("Player textdraws loaded");

    tdTime = TextDrawCreate(577.000000, 20.000000, "00:00");
    TextDrawFont(tdTime, 3);
    TextDrawLetterSize(tdTime, 0.554166, 2.449999);
    TextDrawTextSize(tdTime, 400.000000, 17.000000);
    TextDrawSetOutline(tdTime, 2);
    TextDrawSetShadow(tdTime, 0);
    TextDrawAlignment(tdTime, 2);
    TextDrawColor(tdTime, -1);
    TextDrawBackgroundColor(tdTime, 255);
    TextDrawBoxColor(tdTime, 50);
    TextDrawUseBox(tdTime, 0);
    TextDrawSetProportional(tdTime, 1);
    TextDrawSetSelectable(tdTime, 0);

    tdDate = TextDrawCreate(577.000000, 8.000000, "00.00.0000");
    TextDrawFont(tdDate, 3);
    TextDrawLetterSize(tdDate, 0.266665, 1.299998);
    TextDrawTextSize(tdDate, 400.000000, 17.000000);
    TextDrawSetOutline(tdDate, 2);
    TextDrawSetShadow(tdDate, 0);
    TextDrawAlignment(tdDate, 2);
    TextDrawColor(tdDate, -1);
    TextDrawBackgroundColor(tdDate, 255);
    TextDrawBoxColor(tdDate, 50);
    TextDrawUseBox(tdDate, 0);
    TextDrawSetProportional(tdDate, 1);
    TextDrawSetSelectable(tdDate, 0);

    SetTimer("updateTimeDate", 1000, true);
    return 1;
}

public OnFilterScriptExit() {
    print("Player textdraws unloaded");
    return 1;
}

public OnPlayerConnect(playerid) {
    tdLoginTitle[playerid] = CreatePlayerTextDraw(playerid, 473.000000, 55.000000, "SAMP Wars");
    PlayerTextDrawFont(playerid, tdLoginTitle[playerid], 3);
    PlayerTextDrawLetterSize(playerid, tdLoginTitle[playerid], 1.516666, 3.049999);
    PlayerTextDrawTextSize(playerid, tdLoginTitle[playerid], 349.000000, 2.000000);
    PlayerTextDrawSetOutline(playerid, tdLoginTitle[playerid], 1);
    PlayerTextDrawSetShadow(playerid, tdLoginTitle[playerid], 0);
    PlayerTextDrawAlignment(playerid, tdLoginTitle[playerid], 3);
    PlayerTextDrawColor(playerid, tdLoginTitle[playerid], -1);
    PlayerTextDrawBackgroundColor(playerid, tdLoginTitle[playerid], -16777176);
    PlayerTextDrawBoxColor(playerid, tdLoginTitle[playerid], 50);
    PlayerTextDrawUseBox(playerid, tdLoginTitle[playerid], 0);
    PlayerTextDrawSetProportional(playerid, tdLoginTitle[playerid], 1);
    PlayerTextDrawSetSelectable(playerid, tdLoginTitle[playerid], 0);

    PlayerTextDrawShow(playerid, tdLoginTitle[playerid]);
    return 1;
}

public OnPlayerSpawn(playerid) {
    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));

    tdPlayerName[playerid] = CreatePlayerTextDraw(playerid, 86.000000, 430.000000, playerName);
    PlayerTextDrawFont(playerid, tdPlayerName[playerid], 1);
    PlayerTextDrawLetterSize(playerid, tdPlayerName[playerid], 0.354166, 1.500000);
    PlayerTextDrawTextSize(playerid, tdPlayerName[playerid], 140.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, tdPlayerName[playerid], 1);
    PlayerTextDrawSetShadow(playerid, tdPlayerName[playerid], 0);
    PlayerTextDrawAlignment(playerid, tdPlayerName[playerid], 2);
    PlayerTextDrawColor(playerid, tdPlayerName[playerid], -1);
    PlayerTextDrawBackgroundColor(playerid, tdPlayerName[playerid], 255);
    PlayerTextDrawBoxColor(playerid, tdPlayerName[playerid], 50);
    PlayerTextDrawUseBox(playerid, tdPlayerName[playerid], 0);
    PlayerTextDrawSetProportional(playerid, tdPlayerName[playerid], 1);
    PlayerTextDrawSetSelectable(playerid, tdPlayerName[playerid], 0);

    PlayerTextDrawHide(playerid, tdLoginTitle[playerid]);

    PlayerTextDrawShow(playerid, tdPlayerName[playerid]);
    TextDrawShowForPlayer(playerid, tdTime);
    TextDrawShowForPlayer(playerid, tdDate);
    return 1;
}

forward updateTimeDate();
public updateTimeDate() {
    new string[50], year, month, day, hours, minutes, seconds;
    getdate(year, month, day), gettime(hours, minutes, seconds);
    format(string, sizeof string, "%d/%s%d/%s%d", day, ((month < 10) ? ("0") : ("")), month, (year < 10) ? ("0") : (""), year);
    TextDrawSetString(tdDate, string);
    format(string, sizeof string, "%s%d:%s%d:%s%d", (hours < 10) ? ("0") : (""), hours, (minutes < 10) ? ("0") : (""), minutes, (seconds < 10) ? ("0") : (""), seconds);
    TextDrawSetString(tdTime, string);
}