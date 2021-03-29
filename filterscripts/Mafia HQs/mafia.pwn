#include <a_samp>
#include <izcmd>
#include <strlib>

#define FILTERSCRIPT

// PRESSED(keys)
#define PRESSED(%0) \
(((newkeys & ( % 0)) == ( % 0)) && ((oldkeys & ( % 0)) != ( % 0)))


// SP
new spvehicles[10];

// RDT
new rdtvehicles[10];


main() {
    print("Filterscript loaded in main");
}

public OnFilterScriptInit() {
    print("Mafia HQs and Vehicles filterscript loaded");
    // SP
    addHQSP();
    addVehiclesSP();

    // RDT
    addHQRDT();
    addVehiclesRDT();
}

public OnFilterScriptExit() {
    print("Mafia HQs and Vehicles filterscript unloaded");
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    if ((newkeys & KEY_SECONDARY_ATTACK) && !(oldkeys & KEY_SECONDARY_ATTACK)) {
        if (GetPlayerInterior(playerid) == 0) {
            // SP HQ
            if (IsPlayerInRangeOfPoint(playerid, 10, 1454.88538, 751.07147, 11.02340)) {
                SetPlayerInterior(playerid, 18);
                SetPlayerPos(playerid, 1727.2853, -1642.9451, 20.2254);
            }
            // RDT HQ
            if (IsPlayerInRangeOfPoint(playerid, 10, 2633.78174, 1825.46545, 11.02340)) {
                SetPlayerInterior(playerid, 3);
                SetPlayerPos(playerid, -2638.8232, 1407.3395, 906.4609);
            }
        }
        // SP HQ
        if (GetPlayerInterior(playerid) == 18) {
            SetPlayerInterior(playerid, 0);
            SetPlayerPos(playerid, 1454.88538, 751.07147, 11.02340);
        }
        // RDT HQ
        if (GetPlayerInterior(playerid) == 3) {
            SetPlayerInterior(playerid, 0);
            SetPlayerPos(playerid, 2633.78174, 1825.46545, 11.02340);
        }
    }
}

// -------------------- SETUPS --------------------  

addHQSP() {
    CreateObject(1239, 1454.88538, 751.07147, 11.02340, 0.00000, 0.00000, 0.00000);
}

addHQRDT() {
    CreateObject(1239, 2633.78174, 1825.46545, 11.02340, 0.00000, 0.00000, 0.00000);
}


// color 149
addVehiclesSP() {
    spvehicles[0] = AddStaticVehicle(522, 1412.7795, 746.3126, 10.3922, 267.8583, 211, 255); // nrgsp1
    spvehicles[1] = AddStaticVehicle(522, 1413.5082, 749.2159, 10.3936, 272.6732, 211, 255); // nrgsp2
    spvehicles[2] = AddStaticVehicle(522, 1412.5800, 755.8980, 10.3909, 271.5344, 211, 255); // nrgsp3
    spvehicles[3] = AddStaticVehicle(522, 1413.1470, 759.3210, 10.3994, 275.6730, 211, 255); // nrgsp4
    spvehicles[4] = AddStaticVehicle(411, 1445.7037, 762.5338, 10.5474, 89.8119, 211, 255); // infsp
    spvehicles[5] = AddStaticVehicle(411, 1445.6853, 743.2895, 10.5474, 90.9583, 211, 255); // infsp
    spvehicles[6] = AddStaticVehicle(409, 1446.6243, 751.2015, 10.6203, 359.1673, 211, 255); // limosp
    spvehicles[7] = AddStaticVehicle(579, 1413.0048, 752.7371, 10.6317, 269.8256, 211, 255); // huntleysp
}

// color 161
addVehiclesRDT() {
    rdtvehicles[0] = AddStaticVehicle(409, 2619.5093, 1823.1813, 10.6203, 0.4462, 161, 255); // limordt
    rdtvehicles[1] = AddStaticVehicle(411, 2619.4358, 1831.5000, 10.5474, 359.7305, 161, 255); // infrdt
    rdtvehicles[2] = AddStaticVehicle(411, 2619.2791, 1815.8684, 10.5474, 179.2588, 161, 255); // infrdt
    rdtvehicles[3] = AddStaticVehicle(522, 2591.7991, 1811.8635, 10.3947, 91.3857, 161, 255); // nrgrdt
    rdtvehicles[4] = AddStaticVehicle(522, 2591.5432, 1815.1005, 10.3918, 90.2116, 161, 255); // nrgrdt
    rdtvehicles[5] = AddStaticVehicle(522, 2591.2476, 1833.6570, 10.4048, 89.9670, 161, 255); // nrgrdt
    rdtvehicles[6] = AddStaticVehicle(522, 2591.3049, 1837.1725, 10.4036, 89.3817, 161, 255); // nrgrdt
    rdtvehicles[7] = AddStaticVehicle(579, 2595.3154, 1823.3834, 10.6317, 91.7420, 161, 255); // huntleyrdt
}



// -------------------- COMMANDS --------------------  

COMMAND:fvr(playerid, params[]) {
    if (isequal(params[0], "rdt")) {
        new i;
        for (i = 0; i <= 10; i++) {
            SetVehicleToRespawn(rdtvehicles[i]);
        }
        return 1;
    } else if (isequal(params[0], "sp")) {
        new i;
        for (i = 0; i <= 10; i++) {
            SetVehicleToRespawn(spvehicles[i]);
        }
        return 1;
    } else {
        new i;
        for (i = 0; i <= 10; i++) {
            SetVehicleToRespawn(spvehicles[i]);
        }
        new j;
        for (j = 0; j <= 10; j++) {
            SetVehicleToRespawn(rdtvehicles[j]);
        }
        return 1;
    }
}