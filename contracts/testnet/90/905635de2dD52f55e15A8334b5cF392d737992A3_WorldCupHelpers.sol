//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library WorldCupHelpers {

    uint256 constant private GROUP_A_DEADLINE = 1657071000;                       //1669017600;     //Date of first Group A match.
    uint256 constant private GROUP_B_DEADLINE = GROUP_A_DEADLINE + 2 minutes;     //1669028400;     //Date of first Group B match.
    uint256 constant private GROUP_C_DEADLINE = GROUP_A_DEADLINE + 4 minutes;     //1669104000;     //Date of first Group C match.
    uint256 constant private GROUP_D_DEADLINE = GROUP_A_DEADLINE + 6 minutes;     //1669114800;     //Date of first Group D match.
    uint256 constant private GROUP_E_DEADLINE = GROUP_A_DEADLINE + 8 minutes;     //1669190400;     //Date of first Group E match.
    uint256 constant private GROUP_F_DEADLINE = GROUP_A_DEADLINE + 10 minutes;    //1669201200;     //Date of first Group F match.
    uint256 constant private GROUP_G_DEADLINE = GROUP_A_DEADLINE + 12 minutes;    //1669276800;     //Date of first Group G match.
    uint256 constant private GROUP_H_DEADLINE = GROUP_A_DEADLINE + 14 minutes;    //1669287600;     //Date of first Group H match.

    uint256 constant private W_8A_DEADLINE = GROUP_A_DEADLINE + 16 minutes;       //1670072400;     //Date of match 8A.
    uint256 constant private W_8B_DEADLINE = GROUP_A_DEADLINE + 22 minutes;       //1670173200;     //Date of match 8B.
    uint256 constant private W_8C_DEADLINE = GROUP_A_DEADLINE + 18 minutes;       //1670086800;     //Date of match 8C.
    uint256 constant private W_8D_DEADLINE = GROUP_A_DEADLINE + 20 minutes;       //1670158800;     //Date of match 8D.
    uint256 constant private W_8E_DEADLINE = GROUP_A_DEADLINE + 24 minutes;       //1670245200;     //Date of match 8E.
    uint256 constant private W_8F_DEADLINE = GROUP_A_DEADLINE + 28 minutes;       //1670331600;     //Date of match 8F.
    uint256 constant private W_8G_DEADLINE = GROUP_A_DEADLINE + 26 minutes;       //1670259600;     //Date of match 8G.
    uint256 constant private W_8H_DEADLINE = GROUP_A_DEADLINE + 30 minutes;       //1670346000;     //Date of match 8H.

    uint256 constant private W_4A_DEADLINE = GROUP_A_DEADLINE + 34 minutes;       //1670605200;     //Date of match 4A.
    uint256 constant private W_4B_DEADLINE = GROUP_A_DEADLINE + 36 minutes;       //1670691600;     //Date of match 4B.
    uint256 constant private W_4C_DEADLINE = GROUP_A_DEADLINE + 32 minutes;       //1670590800;     //Date of match 4C.
    uint256 constant private W_4D_DEADLINE = GROUP_A_DEADLINE + 38 minutes;       //1670677200;     //Date of match 4D.

    uint256 constant private W_2A_DEADLINE = GROUP_A_DEADLINE + 40 minutes;       //1670950800;     //Date of match 2A.
    uint256 constant private W_2B_DEADLINE = GROUP_A_DEADLINE + 42 minutes;       //1671037200;     //Date of match 2B.

    uint256 constant private THIRD_DEADLINE = GROUP_A_DEADLINE + 44 minutes;      //1671282000;     //Date of 3rd. Place match.
    uint256 constant private FINAL_DEADLINE = GROUP_A_DEADLINE + 46 minutes;      //1671368400;     //Date of final match.

    struct Fixture {
        uint8 F_A; uint8 F_B; uint8 F_C; uint8 F_D; uint8 F_E; uint8 F_F; uint8 F_G; uint8 F_H;
        uint8 S_A; uint8 S_B; uint8 S_C; uint8 S_D; uint8 S_E; uint8 S_F; uint8 S_G; uint8 S_H;

        uint8 W_8A; uint8 W_8B; uint8 W_8C; uint8 W_8D; uint8 W_8E; uint8 W_8F; uint8 W_8G; uint8 W_8H;
        uint8 W_4A; uint8 W_4B; uint8 W_4C; uint8 W_4D;
        uint8 W_2A; uint8 W_2B;
        
        uint8 FRST; uint8 THRD;
        
        uint256 timestamp;
        uint256 value;
    }

    error Invalid();

    //Finds out if a Prediction is valid
    //Returns true if there are no contradictory results or missing predictions
    function isPredictionValid(Fixture memory prediction, bool verifyTimestamp, uint256 gap) external pure returns (bool) {
        //For every group A-H:
        // - Checks if the F_A (1st. Group A Team) and S_A (2nd. Group A Team) predictions belong to Group A and are different between each other
        if (!(prediction.F_A >=1  && prediction.F_A <=4  && prediction.S_A >=1  && prediction.S_A <=4  && prediction.F_A != prediction.S_A)) { return false; }
        if (!(prediction.F_B >=5  && prediction.F_B <=8  && prediction.S_B >=5  && prediction.S_B <=8  && prediction.F_B != prediction.S_B)) { return false; }
        if (!(prediction.F_C >=9  && prediction.F_C <=12 && prediction.S_C >=9  && prediction.S_C <=12 && prediction.F_C != prediction.S_C)) { return false; }
        if (!(prediction.F_D >=12 && prediction.F_D <=16 && prediction.S_D >=12 && prediction.S_D <=16 && prediction.F_D != prediction.S_D)) { return false; }
        if (!(prediction.F_E >=17 && prediction.F_E <=20 && prediction.S_E >=17 && prediction.S_E <=20 && prediction.F_E != prediction.S_E)) { return false; }
        if (!(prediction.F_F >=21 && prediction.F_F <=24 && prediction.S_F >=21 && prediction.S_F <=24 && prediction.F_F != prediction.S_F)) { return false; }
        if (!(prediction.F_G >=25 && prediction.F_G <=28 && prediction.S_G >=25 && prediction.S_G <=28 && prediction.F_G != prediction.S_G)) { return false; }
        if (!(prediction.F_H >=29 && prediction.F_H <=32 && prediction.S_H >=29 && prediction.S_H <=32 && prediction.F_H != prediction.S_H)) { return false; }

        //For every match after group phase and the first place:
        // - Checks that each winner is equal to one of the two participants of the prvious, corresponding match.
        if (prediction.W_8A != prediction.F_A && prediction.W_8A != prediction.S_B) { return false; }
        if (prediction.W_8B != prediction.F_B && prediction.W_8B != prediction.S_A) { return false; }
        if (prediction.W_8C != prediction.F_C && prediction.W_8C != prediction.S_D) { return false; }
        if (prediction.W_8D != prediction.F_D && prediction.W_8D != prediction.S_C) { return false; }
        if (prediction.W_8E != prediction.F_E && prediction.W_8E != prediction.S_F) { return false; }
        if (prediction.W_8F != prediction.F_F && prediction.W_8F != prediction.S_E) { return false; }
        if (prediction.W_8G != prediction.F_G && prediction.W_8G != prediction.S_H) { return false; }
        if (prediction.W_8H != prediction.F_H && prediction.W_8H != prediction.S_G) { return false; }

        if (prediction.W_4A != prediction.W_8A && prediction.W_4A != prediction.W_8C) { return false; }
        if (prediction.W_4B != prediction.W_8B && prediction.W_4B != prediction.W_8D) { return false; }
        if (prediction.W_4C != prediction.W_8E && prediction.W_4C != prediction.W_8G) { return false; }
        if (prediction.W_4D != prediction.W_8F && prediction.W_4D != prediction.W_8H) { return false; }

        if (prediction.W_2A != prediction.W_4A && prediction.W_2A != prediction.W_4C) { return false; }
        if (prediction.W_2B != prediction.W_4B && prediction.W_2B != prediction.W_4D) { return false; }

        if (prediction.FRST != prediction.W_2A && prediction.FRST != prediction.W_2B) { return false; }

        //For third place:
        // - Finds out the semi final losers and makes sure the third place is one of them
        uint8 L_2A = (prediction.W_2A == prediction.W_4A)?prediction.W_4C:prediction.W_4A;
        uint8 L_2B = (prediction.W_2B == prediction.W_4B)?prediction.W_4D:prediction.W_4B;
        if (prediction.THRD != L_2A && prediction.THRD != L_2B) { return false; }

        if ((prediction.timestamp >= (W_8A_DEADLINE - gap)) && verifyTimestamp) { return false; }

        return true;
    }


    //Compares a Prediction to the Results
    //Returns true if doesn't have differences with any result set in the state
    function isPredictionCurrent(Fixture memory prediction, Fixture memory results) external pure returns (bool) {
        if (results.F_A > 0 && results.F_A != prediction.F_A) { return false; }
        if (results.F_B > 0 && results.F_B != prediction.F_B) { return false; }
        if (results.F_C > 0 && results.F_C != prediction.F_C) { return false; }
        if (results.F_D > 0 && results.F_D != prediction.F_D) { return false; }
        if (results.F_E > 0 && results.F_E != prediction.F_E) { return false; }
        if (results.F_F > 0 && results.F_F != prediction.F_F) { return false; }
        if (results.F_G > 0 && results.F_G != prediction.F_G) { return false; }
        if (results.F_H > 0 && results.F_H != prediction.F_H) { return false; }

        if (results.S_A > 0 && results.S_A != prediction.S_A) { return false; }
        if (results.S_B > 0 && results.S_B != prediction.S_B) { return false; }
        if (results.S_C > 0 && results.S_C != prediction.S_C) { return false; }
        if (results.S_D > 0 && results.S_D != prediction.S_D) { return false; }
        if (results.S_E > 0 && results.S_E != prediction.S_E) { return false; }
        if (results.S_F > 0 && results.S_F != prediction.S_F) { return false; }
        if (results.S_G > 0 && results.S_G != prediction.S_G) { return false; }
        if (results.S_H > 0 && results.S_H != prediction.S_H) { return false; }

        if (results.W_8A > 0 && results.W_8A != prediction.W_8A) { return false; }
        if (results.W_8B > 0 && results.W_8B != prediction.W_8B) { return false; }
        if (results.W_8C > 0 && results.W_8C != prediction.W_8C) { return false; }
        if (results.W_8D > 0 && results.W_8D != prediction.W_8D) { return false; }
        if (results.W_8E > 0 && results.W_8E != prediction.W_8E) { return false; }
        if (results.W_8F > 0 && results.W_8F != prediction.W_8F) { return false; }
        if (results.W_8G > 0 && results.W_8G != prediction.W_8G) { return false; }
        if (results.W_8H > 0 && results.W_8H != prediction.W_8H) { return false; }

        if (results.W_4A > 0 && results.W_4A != prediction.W_4A) { return false; }
        if (results.W_4B > 0 && results.W_4B != prediction.W_4B) { return false; }
        if (results.W_4C > 0 && results.W_4C != prediction.W_4C) { return false; }
        if (results.W_4D > 0 && results.W_4D != prediction.W_4D) { return false; }

        if (results.W_2A > 0 && results.W_2A != prediction.W_2A) { return false; }
        if (results.W_2B > 0 && results.W_2B != prediction.W_2B) { return false; }

        if (results.FRST > 0 && results.FRST != prediction.FRST) { return false; }
        if (results.THRD > 0 && results.THRD != prediction.THRD) { return false; }

        return true;
    }

    //This function is used to update the results by the Oracle
    function stateTransition(Fixture memory results, uint8 n, uint8 value, uint256 timestamp) external pure returns (Fixture memory) {
        if (n == 0) { if (value == 0 || (value >=1 && value <=4 && results.S_A != value && timestamp > GROUP_A_DEADLINE)) { results.F_A = value; } else { revert Invalid(); }}
        if (n == 1)  { if (value == 0 || (value >=1 && value <=4 && results.F_A != value && timestamp > GROUP_A_DEADLINE)) { results.S_A = value; } else { revert Invalid(); }}
        if (n == 2) { if (value == 0 || (value >=5 && value <=8 && results.S_B != value && timestamp > GROUP_B_DEADLINE)) { results.F_B = value; } else { revert Invalid(); }}
        if (n == 3)  { if (value == 0 || (value >=5 && value <=8 && results.F_B != value && timestamp > GROUP_B_DEADLINE)) { results.S_B = value; } else { revert Invalid(); }}
        if (n == 4) { if (value == 0 || (value >=9 && value <=12 && results.S_C != value && timestamp > GROUP_C_DEADLINE)) { results.F_C = value; } else { revert Invalid(); }}
        if (n == 5) { if (value == 0 || (value >=9 && value <=12 && results.F_C != value && timestamp > GROUP_C_DEADLINE)) { results.S_C = value; } else { revert Invalid(); }}
        if (n == 6) { if (value == 0 || (value >=13 && value <=16 && results.S_D != value && timestamp > GROUP_D_DEADLINE)) { results.F_D = value; } else { revert Invalid(); }}
        if (n == 7) { if (value == 0 || (value >=13 && value <=16 && results.F_D != value && timestamp > GROUP_D_DEADLINE)) { results.S_D = value; } else { revert Invalid(); }}
        if (n == 8) { if (value == 0 || (value >=17 && value <=20 && results.S_E != value && timestamp > GROUP_E_DEADLINE)) { results.F_E = value; } else { revert Invalid(); }}
        if (n == 9) { if (value == 0 || (value >=17 && value <=20 && results.F_E != value && timestamp > GROUP_E_DEADLINE)) { results.S_E = value; } else { revert Invalid(); }}
        if (n == 10) { if (value == 0 || (value >=21 && value <=24 && results.S_F != value && timestamp > GROUP_F_DEADLINE)) { results.F_F = value; } else { revert Invalid(); }}
        if (n == 11) { if (value == 0 || (value >=21 && value <=24 && results.F_F != value && timestamp > GROUP_F_DEADLINE)) { results.S_F = value; } else { revert Invalid(); }}
        if (n == 12) { if (value == 0 || (value >=25 && value <=28 && results.S_G != value && timestamp > GROUP_G_DEADLINE)) { results.F_G = value; } else { revert Invalid(); }}
        if (n == 13) { if (value == 0 || (value >=25 && value <=28 && results.F_G != value && timestamp > GROUP_G_DEADLINE)) { results.S_G = value; } else { revert Invalid(); }}
        if (n == 14) { if (value == 0 || (value >=29 && value <=32 && results.S_H != value && timestamp > GROUP_H_DEADLINE)) { results.F_H = value; } else { revert Invalid(); }}
        if (n == 15) { if (value == 0 || (value >=29 && value <=32 && results.F_H != value && timestamp > GROUP_H_DEADLINE)) { results.S_H = value; } else { revert Invalid(); }}

        if (n == 16) { if (value == 0 || (value > 0 && (results.F_A == value || results.S_B == value) && timestamp > W_8A_DEADLINE)) { results.W_8A = value; } else { revert Invalid(); }}
        if (n == 17) { if (value == 0 || (value > 0 && (results.F_B == value || results.S_A == value) && timestamp > W_8B_DEADLINE)) { results.W_8B = value; } else { revert Invalid(); }}
        if (n == 18) { if (value == 0 || (value > 0 && (results.F_C == value || results.S_D == value) && timestamp > W_8C_DEADLINE)) { results.W_8C = value; } else { revert Invalid(); }}
        if (n == 19) { if (value == 0 || (value > 0 && (results.F_D == value || results.S_C == value) && timestamp > W_8D_DEADLINE)) { results.W_8D = value; } else { revert Invalid(); }}
        if (n == 20) { if (value == 0 || (value > 0 && (results.F_E == value || results.S_F == value) && timestamp > W_8E_DEADLINE)) { results.W_8E = value; } else { revert Invalid(); }}
        if (n == 21) { if (value == 0 || (value > 0 && (results.F_F == value || results.S_E == value) && timestamp > W_8F_DEADLINE)) { results.W_8F = value; } else { revert Invalid(); }}
        if (n == 22) { if (value == 0 || (value > 0 && (results.F_G == value || results.S_H == value) && timestamp > W_8G_DEADLINE)) { results.W_8G = value; } else { revert Invalid(); }}
        if (n == 23) { if (value == 0 || (value > 0 && (results.F_H == value || results.S_G == value) && timestamp > W_8H_DEADLINE)) { results.W_8H = value; } else { revert Invalid(); }}

        if (n == 24) { if (value == 0 || (value > 0 && (results.W_8A == value || results.W_8C == value) && timestamp > W_4A_DEADLINE)) { results.W_4A = value; } else { revert Invalid(); }}
        if (n == 25) { if (value == 0 || (value > 0 && (results.W_8B == value || results.W_8D == value) && timestamp > W_4B_DEADLINE)) { results.W_4B = value; } else { revert Invalid(); }}
        if (n == 26) { if (value == 0 || (value > 0 && (results.W_8E == value || results.W_8G == value) && timestamp > W_4C_DEADLINE)) { results.W_4C = value; } else { revert Invalid(); }}
        if (n == 27) { if (value == 0 || (value > 0 && (results.W_8F == value || results.W_8H == value) && timestamp > W_4D_DEADLINE)) { results.W_4D = value; } else { revert Invalid(); }}

        if (n == 28) { if (value == 0 || (value > 0 && (results.W_4A == value || results.W_4C == value) && timestamp > W_2A_DEADLINE)) { results.W_2A = value; } else { revert Invalid(); }}
        if (n == 29) { if (value == 0 || (value > 0 && (results.W_4B == value || results.W_4D == value) && timestamp > W_2B_DEADLINE)) { results.W_2B = value; } else { revert Invalid(); }}

        if (n == 30) {
            if (results.W_4A > 0 && results.W_4B > 0 && results.W_4C > 0 && results.W_4D > 0 && results.W_2A > 0 && results.W_2B > 0 &&
                (results.W_2A == results.W_4A || results.W_2A == results.W_4C) && (results.W_2B == results.W_4B || results.W_2B == results.W_4D)) { 
                uint8 L_2A = (results.W_2A == results.W_4A)?results.W_4C:results.W_4A;
                uint8 L_2B = (results.W_2B == results.W_4B)?results.W_4D:results.W_4B;
                if (value == 0 || (value > 0 && (L_2A == value || L_2B == value) && timestamp > THIRD_DEADLINE)) { results.THRD = value; } else { revert Invalid(); }
            } else { revert Invalid(); }
        }
        if (n == 31){ if (value == 0 || (value > 0 && (results.W_2A == value || results.W_2B == value) && timestamp > FINAL_DEADLINE)) { results.FRST = value; } else { revert Invalid(); }}

        results.timestamp = timestamp;
        return results;
    }

    //This function calculates the points of a Prediction as follows:
    //Group phase corret prediction:         +2 points       Group phase incorrect prediction:            -1 points
    //Round of 16 corret prediction:         +4 points       Round of 16 incorrect prediction:            -2 points
    //Quarter Finals corret prediction:      +8 points       Quarter Finals incorrect prediction:         -4 points
    //Semi Finals corret prediction:        +16 points       Semi Finals incorrect prediction:            -8 points
    //Final & 3rd. Place corret prediction: +32 points       Final & 3rd. Place incorrect prediction:    -16 points
    function calcPredictionPoints(Fixture memory prediction, Fixture memory results, uint256 gap) external pure returns (uint256) {
        uint256 points;

        if (results.F_A > 0 && results.F_A == prediction.F_A && prediction.timestamp <= (GROUP_A_DEADLINE - gap)) { points += 2; }
        if (results.F_B > 0 && results.F_B == prediction.F_B && prediction.timestamp <= (GROUP_B_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.F_C > 0 && results.F_C == prediction.F_C && prediction.timestamp <= (GROUP_C_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.F_D > 0 && results.F_D == prediction.F_D && prediction.timestamp <= (GROUP_D_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.F_E > 0 && results.F_E == prediction.F_E && prediction.timestamp <= (GROUP_E_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.F_F > 0 && results.F_F == prediction.F_F && prediction.timestamp <= (GROUP_F_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.F_G > 0 && results.F_G == prediction.F_G && prediction.timestamp <= (GROUP_G_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.F_H > 0 && results.F_H == prediction.F_H && prediction.timestamp <= (GROUP_H_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_A > 0 && results.S_A == prediction.S_A && prediction.timestamp <= (GROUP_A_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_B > 0 && results.S_B == prediction.S_B && prediction.timestamp <= (GROUP_B_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_C > 0 && results.S_C == prediction.S_C && prediction.timestamp <= (GROUP_C_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_D > 0 && results.S_D == prediction.S_D && prediction.timestamp <= (GROUP_D_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_E > 0 && results.S_E == prediction.S_E && prediction.timestamp <= (GROUP_E_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_F > 0 && results.S_F == prediction.S_F && prediction.timestamp <= (GROUP_F_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_G > 0 && results.S_G == prediction.S_G && prediction.timestamp <= (GROUP_G_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}
        if (results.S_H > 0 && results.S_H == prediction.S_H && prediction.timestamp <= (GROUP_H_DEADLINE - gap)) { points += 2; } else { if (points >= 1) { points -= 1; } else { points = 0; }}

        if (results.W_8A > 0 && results.W_8A == prediction.W_8A && prediction.timestamp <= (W_8A_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}
        if (results.W_8B > 0 && results.W_8B == prediction.W_8B && prediction.timestamp <= (W_8B_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}
        if (results.W_8C > 0 && results.W_8C == prediction.W_8C && prediction.timestamp <= (W_8C_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}
        if (results.W_8D > 0 && results.W_8D == prediction.W_8D && prediction.timestamp <= (W_8D_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}
        if (results.W_8E > 0 && results.W_8E == prediction.W_8E && prediction.timestamp <= (W_8E_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}
        if (results.W_8F > 0 && results.W_8F == prediction.W_8F && prediction.timestamp <= (W_8F_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}
        if (results.W_8G > 0 && results.W_8G == prediction.W_8G && prediction.timestamp <= (W_8G_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}
        if (results.W_8H > 0 && results.W_8H == prediction.W_8H && prediction.timestamp <= (W_8H_DEADLINE - gap)) { points += 4; } else { if (points >= 2) { points -= 2; } else { points = 0; }}

        if (results.W_4A > 0 && results.W_4A == prediction.W_4A && prediction.timestamp <= (W_4A_DEADLINE - gap)) { points += 8; } else { if (points >= 4) { points -= 4; } else { points = 0; }}
        if (results.W_4B > 0 && results.W_4B == prediction.W_4B && prediction.timestamp <= (W_4B_DEADLINE - gap)) { points += 8; } else { if (points >= 4) { points -= 4; } else { points = 0; }}
        if (results.W_4C > 0 && results.W_4C == prediction.W_4C && prediction.timestamp <= (W_4C_DEADLINE - gap)) { points += 8; } else { if (points >= 4) { points -= 4; } else { points = 0; }}
        if (results.W_4D > 0 && results.W_4D == prediction.W_4D && prediction.timestamp <= (W_4D_DEADLINE - gap)) { points += 8; } else { if (points >= 4) { points -= 4; } else { points = 0; }}

        if (results.W_2A > 0 && results.W_2A == prediction.W_2A && prediction.timestamp <= (W_2A_DEADLINE - gap)) { points += 16; } else { if (points >= 8) { points -= 4; } else { points = 0; }}
        if (results.W_2B > 0 && results.W_2B == prediction.W_2B && prediction.timestamp <= (W_2B_DEADLINE - gap)) { points += 16; } else { if (points >= 8) { points -= 4; } else { points = 0; }}

        if (results.THRD > 0 && results.THRD == prediction.THRD && prediction.timestamp <= (THIRD_DEADLINE - gap)) { points += 32; } else { if (points >= 16) { points -= 4; } else { points = 0; }}
        if (results.FRST > 0 && results.FRST == prediction.FRST && prediction.timestamp <= (FINAL_DEADLINE - gap)) { points += 32; } else { if (points >= 16) { points -= 4; } else { points = 0; }}

        return points;
    }
}