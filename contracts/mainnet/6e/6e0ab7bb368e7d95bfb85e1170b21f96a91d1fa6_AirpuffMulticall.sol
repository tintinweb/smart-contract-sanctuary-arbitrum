// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IAirpuff1x} from "./interfaces/IAirpuff1x.sol";
import {IAirpuff} from "./interfaces/IAirpuff.sol";


contract AirpuffMulticall {

    mapping(string => address) public vaultAddresses;

    struct DtvValues {
        uint256 currentDTV;
        uint256 currentPositionValue;
        uint256 currentPosValueBorrowedAsset;
        uint256 leverageWithInterests;
        uint256 totalInterests;
    }

    /* ##################################################################
                                HELPERS
    ################################################################## */
    function setVaultAddress(string memory vault, address vaultAddress) external {
        vaultAddresses[vault] = vaultAddress;
    }

    function setVaultAddresses(string[] memory vaults, address[] memory addresses) external {
        require(vaults.length == addresses.length, "length not match");

        for (uint256 i = 0; i < vaults.length; i++) {
        vaultAddresses[vaults[i]] = addresses[i];
        }
    }

    function getVaultAddress(string memory vault) external view returns (address) {
        return vaultAddresses[vault];
    }

    /* ##################################################################
                                INTERNAL
    ################################################################## */
    function _getNumberOfPositions(string memory _vault, address _user) internal view returns (uint256) {
        address vaultAddress = vaultAddresses[_vault];
        return IAirpuff(vaultAddress).getTotalNumbersOfOpenPositionBy(_user);

    }

    function _getDtv(string memory _vault, uint256 _positionId, address _user) internal view returns (DtvValues memory){
        address vaultAddress = vaultAddresses[_vault];
        DtvValues memory dtv;
        (dtv.currentDTV, dtv.currentPositionValue, dtv.currentPosValueBorrowedAsset, dtv.leverageWithInterests, dtv.totalInterests) = IAirpuff(vaultAddress).getUpdatedDebt(_positionId, _user);

        return dtv;
    }

    /* ##################################################################
                                EXTERNAL
    ################################################################## */
    function fetchAllUsersDtv(string memory _vault, address[] memory _users) external view returns (DtvValues[][] memory) {
        address vaultAddress = vaultAddresses[_vault];
        require(vaultAddress != address(0), "dont have this vault");

        DtvValues[][] memory dtv = new DtvValues[][](_users.length);

        for (uint256 i = 0; i < _users.length; i++) {
        uint256 numberOfPositions = _getNumberOfPositions(_vault, _users[i]);
        dtv[i] = new DtvValues[](numberOfPositions);

        for (uint256 j = 0; j < numberOfPositions; j++) {
            DtvValues memory dtvValues = _getDtv(_vault, j, _users[i]);
            dtv[i][j] = dtvValues;
        }
        }

        return dtv;
    }

    function fetchAirpuffAllUsersPositions(string memory _vault, address[] memory _users) external view returns (IAirpuff.PositionInfo[][] memory) {
        address vaultAddress = vaultAddresses[_vault];
        require(vaultAddress != address(0), "dont have this vault");

        IAirpuff.PositionInfo[][] memory positions = new IAirpuff.PositionInfo[][](_users.length);

        for (uint256 i = 0; i < _users.length; i++) {
            uint256 numberOfPositions = _getNumberOfPositions(_vault, _users[i]);
            positions[i] = new IAirpuff.PositionInfo[](numberOfPositions);

            for (uint256 j = 0; j < numberOfPositions; j++) {
                IAirpuff.UserInfo memory userInfo = IAirpuff(vaultAddress).userInfo(_users[i], j);

                address depositAsset = IAirpuff(vaultAddress).positionDepositAsset(_users[i], j);
                address borrowAsset = IAirpuff(vaultAddress).positionBorrowAsset(_users[i], j);

                positions[i][j] = IAirpuff.PositionInfo({
                    user: userInfo.user,
                    deposit: userInfo.deposit,
                    leverage: userInfo.leverage,
                    position: userInfo.position,
                    originalPositionValue: userInfo.originalPositionValue,
                    liquidated: userInfo.liquidated,
                    closedPositionValue: userInfo.closedPositionValue,
                    liquidator: userInfo.liquidator,
                    positionSwappedBorrowedAmount: userInfo.positionSwappedBorrowedAmount,
                    leverageAmount: userInfo.leverageAmount,
                    positionId: userInfo.positionId,
                    closed: userInfo.closed,
                    depositAsset: depositAsset,
                    borrowAsset: borrowAsset
                });
            }
        }

        return positions;
    }

    function fetchAirpuff1xAllUsersPositions(string memory _vault, address[] memory _users) external view returns (IAirpuff1x.UserInfo[][] memory) {
        address vaultAddress = vaultAddresses[_vault];
        require(vaultAddress != address(0), "dont have this vault");

        IAirpuff1x.UserInfo[][] memory positions = new IAirpuff1x.UserInfo[][](_users.length);

        for (uint256 i = 0; i < _users.length; i++) {
            uint256 numberOfPositions = _getNumberOfPositions(_vault, _users[i]);
            positions[i] = new IAirpuff1x.UserInfo[](numberOfPositions);

            for (uint256 j = 0; j < numberOfPositions; j++) {
                IAirpuff1x.UserInfo memory userInfo = IAirpuff1x(vaultAddress).userInfo(_users[i], j);
                positions[i][j] = userInfo;
            }
        }

        return positions;
    }

    function fetchAllOpenRequests(string memory _vault, address[] memory _users) external view returns (IAirpuff.OpenPositionRequest[][] memory) {
        address vaultAddress = vaultAddresses[_vault];
        require(vaultAddress != address(0), "dont have this vault");

        IAirpuff.OpenPositionRequest[][] memory requests = new IAirpuff.OpenPositionRequest[][](_users.length);

        for (uint256 i = 0; i < _users.length; i++) {
            uint256 numberOfRequests = IAirpuff(vaultAddress).getPositionOpenRequestCount(_users[i]);
            requests[i] = new IAirpuff.OpenPositionRequest[](numberOfRequests);

            for (uint256 j = 0; j < numberOfRequests; j++) {
                IAirpuff.OpenPositionRequest memory request = IAirpuff(vaultAddress).openPositionRequests(_users[i], j);
                requests[i][j] = request;
            }
        }

        return requests;
    }

        function fetchAllCloseRequests(string memory _vault, address[] memory _users) external view returns (IAirpuff.ClosePositionRequest[][] memory) {
        address vaultAddress = vaultAddresses[_vault];
        require(vaultAddress != address(0), "dont have this vault");

        IAirpuff.ClosePositionRequest[][] memory requests = new IAirpuff.ClosePositionRequest[][](_users.length);

        for (uint256 i = 0; i < _users.length; i++) {
            uint256 numberOfRequests = IAirpuff(vaultAddress).getPositionCloseRequestCount(_users[i]);
            requests[i] = new IAirpuff.ClosePositionRequest[](numberOfRequests);

            for (uint256 j = 0; j < numberOfRequests; j++) {
                IAirpuff.ClosePositionRequest memory request = IAirpuff(vaultAddress).closePositionRequests(_users[i], j);
                requests[i][j] = request;
            }
        }

        return requests;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAirpuff {
    struct UserInfo {
        address user;
        uint256 deposit;
        uint256 leverage;
        uint256 position;
        uint256 originalPositionValue;
        bool liquidated;
        uint256 closedPositionValue;
        address liquidator;
        uint256 positionSwappedBorrowedAmount;
        uint256 leverageAmount;
        uint256 positionId;
        bool    closed;
    }

    struct PositionInfo {
        address user;
        uint256 deposit;
        uint256 leverage;
        uint256 position;
        uint256 originalPositionValue;
        bool liquidated;
        uint256 closedPositionValue;
        address liquidator;
        uint256 positionSwappedBorrowedAmount;
        uint256 leverageAmount;
        uint256 positionId;
        bool    closed;
        address depositAsset;
        address borrowAsset;
    }

    struct Dtv {
        uint256 currentDTV;
        uint256 currentPositionValue;
        uint256 currentPosValueBorrowedAsset;
        uint256 leverageWithInterests;
        uint256 totalInterests;
    }

    struct OpenPositionRequest {
        address user;
        uint256 leveragedAmount;
        uint256 leverage;
        uint256 amount;
        address asset;
        address toBorrow;
        uint256 toSwap1;
        uint256 toSwap2;
        bool isweWETH;
        bool done;
    }

    struct ClosePositionRequest {
        address user;
        uint256 userPositionID;
        uint256 closeRequestID;
        uint256 lendingRepayment;
        uint256 mFee;
        uint256 toLeverageUser;
        bool isLiquidation;
        bool done;
        uint256 totalInterests;
    }

    function getTotalNumbersOfOpenPositionBy(address _user) external view returns (uint256);
    function getUpdatedDebt(uint256 _positionID, address _user) external view returns (uint256, uint256, uint256, uint256, uint256);
    function userInfo(address _user, uint256 _positionID) external view returns (UserInfo memory);
    function getCurrentPositionValue(uint256 _positionID, address _user) external view returns (uint256);
    function positionDepositAsset(address _user, uint256 _positionID) external view returns (address);
    function positionBorrowAsset(address _user, uint256 _positionID) external view returns (address);
    function getPositionOpenRequestCount(address _user) external view returns (uint256);
    function getPositionCloseRequestCount(address _user) external view returns (uint256);
    function openPositionRequests(address _user, uint256 _openRequestId) external view returns (OpenPositionRequest memory);
    function closePositionRequests(address _user, uint256 _closeRequestId) external view returns (ClosePositionRequest memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAirpuff1x {
    struct UserInfo {
        address user;
        uint256 deposit;
        uint256 positionId;
        uint256 openTimestamp;
        uint256 closeTimestamp;
        bool closed;
    }
    
    function getTotalNumbersOfOpenPositionBy(address _user) external view returns (uint256);
    function userInfo(address _user, uint256 _positionID) external view returns (UserInfo memory);

}