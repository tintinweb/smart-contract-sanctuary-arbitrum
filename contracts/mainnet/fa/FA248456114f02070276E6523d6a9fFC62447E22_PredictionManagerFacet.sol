// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../utils/Constants.sol";
import {ZeroAddress} from "../../utils/Errors.sol";
import "../interfaces/IPredictionManager.sol";
import "../libraries/LibPredictionManager.sol";
import "../libraries/LibAccessControlEnumerable.sol";

contract PredictionManagerFacet is IPredictionManager {

    function addPredictionPair(
        address base, string calldata name, PredictionPeriod[] calldata predictionPeriods
    ) external override {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        _isBaseNonZero(base);
        _predictionPeriodsCheck(predictionPeriods);
        LibPredictionManager.addPredictionPair(base, name, predictionPeriods);
    }

    function removePredictionPair(address base) external override {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        _isBaseNonZero(base);
        LibPredictionManager.removePredictionPair(base);
    }

    function updatePredictionPairStatus(address base, PredictionPairStatus status) external override {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        _isBaseNonZero(base);
        LibPredictionManager.updatePredictionPairStatus(base, status);
    }

    function updatePredictionPairMaxCap(address base, PeriodCap[] calldata periodCaps) external override {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        _isBaseNonZero(base);
        LibPredictionManager.PredictionPair storage pp = LibPredictionManager.requireExists(base);
        for (uint256 i = 0; i < periodCaps.length;) {
            PeriodCap memory ic = periodCaps[i];
            LibPredictionManager.updatePredictionPairPeriodMaxCap(pp, ic.period, ic.maxUpUsd, ic.maxDownUsd);
            unchecked{++i;}
        }
    }

    function updatePredictionPairWinRatio(address base, PeriodWinRatio[] calldata periodWinRatios) external override {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        _isBaseNonZero(base);
        LibPredictionManager.PredictionPair storage pp = LibPredictionManager.requireExists(base);
        for (uint256 i = 0; i < periodWinRatios.length;) {
            PeriodWinRatio memory iwr = periodWinRatios[i];
            require(iwr.winRatio > 5000 && iwr.winRatio <= 1e4, "PredictionManagerFacet: invalid winRatio");
            LibPredictionManager.updatePredictionPairPeriodWinRatio(pp, iwr.period, iwr.winRatio);
            unchecked{++i;}
        }
    }

    function updatePredictionPairFee(address base, PeriodFee[] calldata periodFees) external override {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        _isBaseNonZero(base);
        LibPredictionManager.PredictionPair storage pp = LibPredictionManager.requireExists(base);
        for (uint256 i = 0; i < periodFees.length;) {
            PeriodFee memory iFee = periodFees[i];
            require(
                iFee.openFeeP < 1e4 && iFee.winCloseFeeP < 1e4 && iFee.loseCloseFeeP < 1e4,
                "PredictionManagerFacet: invalid openFeeP or closeFeeP"
            );
            LibPredictionManager.updatePredictionPairPeriodFee(pp, iFee.period, iFee.openFeeP, iFee.winCloseFeeP, iFee.loseCloseFeeP);
            unchecked{++i;}
        }
    }

    function addPeriodForPredictionPair(address base, PredictionPeriod[] calldata predictionPeriods) external override {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        _isBaseNonZero(base);
        _predictionPeriodsCheck(predictionPeriods);
        LibPredictionManager.PredictionPair storage pp = LibPredictionManager.requireExists(base);
        LibPredictionManager.addPeriodForPredictionPair(pp, predictionPeriods);
    }

    function replacePredictionPairPeriod(address base, PredictionPeriod[] calldata predictionPeriods) external override {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        _isBaseNonZero(base);
        _predictionPeriodsCheck(predictionPeriods);
        LibPredictionManager.PredictionPair storage pp = LibPredictionManager.requireExists(base);
        LibPredictionManager.replacePredictionPairPeriod(pp, predictionPeriods);
    }

    function _isBaseNonZero(address base) private pure {
        if (base == address(0)) revert ZeroAddress();
    }

    function _predictionPeriodsCheck(PredictionPeriod[] calldata predictionPeriods) private pure {
        require(predictionPeriods.length > 0, "PredictionManagerFacet: contains at least one period");
        for (uint256 i = 0; i < predictionPeriods.length;) {
            PredictionPeriod memory pi = predictionPeriods[i];
            require(pi.winRatio > 5000 && pi.winRatio <= 1e4, "PredictionManagerFacet: invalid winRatio");
            require(
                pi.openFeeP < 1e4 && pi.winCloseFeeP < 1e4 && pi.loseCloseFeeP < 1e4,
                "PredictionManagerFacet: invalid openFeeP or closeFeeP"
            );
            unchecked{++i;}
        }
    }

    function getPredictionPairByBase(address base) public view override returns (PredictionPairView memory) {
        LibPredictionManager.PredictionPair storage pp = LibPredictionManager.predictionManagerStorage().predictionPairs[base];
        PredictionPeriod[] memory predictionPeriods = new PredictionPeriod[](pp.periods.length);
        for (uint256 i = 0; i < pp.periods.length;) {
            predictionPeriods[i] = pp.predictionPeriods[pp.periods[i]];
            unchecked{++i;}
        }
        return PredictionPairView(pp.name, pp.base, predictionPeriods);
    }

    function predictionPairs(uint start, uint8 size) external view override returns (PredictionPairView[] memory predictPairViews) {
        LibPredictionManager.PredictionManagerStorage storage pms = LibPredictionManager.predictionManagerStorage();
        if (start >= pms.predictionPairBases.length || size == 0) {
            predictPairViews = new PredictionPairView[](0);
        } else {
            uint count = pms.predictionPairBases.length - start > size ? size : pms.predictionPairBases.length - start;
            predictPairViews = new PredictionPairView[](count);
            for (uint256 i = 0; i < count;) {
                uint256 index;
                unchecked{index = i + start;}
                predictPairViews[i] = getPredictionPairByBase(pms.predictionPairBases[index]);
                unchecked{++i;}
            }
        }
        return predictPairViews;
    }

    function getPredictionPeriod(address base, Period period) external view override returns (PredictionPeriod memory) {
        return LibPredictionManager.predictionManagerStorage().predictionPairs[base].predictionPeriods[period];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Invalid Insufficient Nonexistent Existent

error ZeroAddress();

interface IPriceFacadeError {
    error NonexistentRequestId(bytes32 requestId);
}

interface ITradingCoreError {
    error UnsupportedMarginToken(address token);
}

interface ISlippageManagerError {
    error InvalidSlippage(uint16 slippageLongP, uint16 slippageShortP);
    error InvalidOnePercentDepthUsd(uint256 onePercentDepthAboveUsd, uint256 onePercentDepthBelowUsd);
    error ExistentSlippage(uint16 index, string name);
    error NonexistentSlippage(uint16 index);
    error SlippageInUse(uint16 index, string name);
}

interface ITradingPortalError {
    error NonexistentTrade();
    error UnauthorizedOperation(address operator);
    error MarketClosed();
    error PairClosed(address pairBase);
    error InvalidStopLoss(bytes32 tradeHash, uint64 entryPrice, uint64 newStopLoss);
    error InsufficientMarginAmount(bytes32 tradeHash, uint256 amount);
    error BelowDegenModeMinLeverage(bytes32 tradeHash, uint256 minRequiredLeverage, uint256 newLeverage);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../dependencies/ArbSys.sol";

type Price8 is uint64;
type Qty10 is uint80;
type Usd18 is uint96;

library Constants {

    ArbSys constant public arbSys = ArbSys(address(100));

    /*-------------------------------- Role --------------------------------*/
    // 0x0000000000000000000000000000000000000000000000000000000000000000
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    // 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // 0xfc425f2263d0df187444b70e47283d622c70181c5baebb1306a01edba1ce184c
    bytes32 constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    // 0x62150a51582c26f4255242a3c4ca35fb04250e7315069523d650676aed01a56a
    bytes32 constant TOKEN_OPERATOR_ROLE = keccak256("TOKEN_OPERATOR_ROLE");
    // 0xa6fbd0d4ef0ac50b4de984ab8f303863596293cce6d67dd6111979bcf56abe74
    bytes32 constant STAKE_OPERATOR_ROLE = keccak256("STAKE_OPERATOR_ROLE");
    // 0xc24d2c87036c9189cc45e221d5dff8eaffb4966ee49ea36b4ffc88a2d85bf890
    bytes32 constant PRICE_FEED_OPERATOR_ROLE = keccak256("PRICE_FEED_OPERATOR_ROLE");
    // 0x04fcf77d802b9769438bfcbfc6eae4865484c9853501897657f1d28c3f3c603e
    bytes32 constant PAIR_OPERATOR_ROLE = keccak256("PAIR_OPERATOR_ROLE");
    // 0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab
    bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    // 0x4e89f34ce8e0125b1b19130806ace319a8a06b7e1b4d6ef98c0eac043b6f119a
    bytes32 constant PREDICTION_KEEPER_ROLE = keccak256("PREDICTION_KEEPER_ROLE");
    // 0x7d867aa9d791a9a4be418f90a2f248aa2c5f1348317792a6f6412f94df9819f7
    bytes32 constant PRICE_FEEDER_ROLE = keccak256("PRICE_FEEDER_ROLE");
    // 0x8227712ef8ad39d0f26f06731ef0df8665eb7ada7f41b1ee089adf3c238862a2
    bytes32 constant MONITOR_ROLE = keccak256("MONITOR_ROLE");

    /*-------------------------------- Decimals --------------------------------*/
    uint8 constant public PRICE_DECIMALS = 8;
    uint8 constant public QTY_DECIMALS = 10;
    uint8 constant public USD_DECIMALS = 18;

    uint16 constant public BASIS_POINTS_DIVISOR = 1e4;
    uint16 constant public MAX_LEVERAGE = 1e3;
    int256 constant public FUNDING_FEE_RATE_DIVISOR = 1e18;
    uint8 constant public FEED_DELAY_BLOCK = 100;
    uint8 constant public MAX_REQUESTS_PER_PAIR_IN_BLOCK = 100;
    uint256 constant public TIME_LOCK_DELAY = 2 hours;
    uint256 constant public TIME_LOCK_GRACE_PERIOD = 24 hours;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IPriceFacade.sol";
import {Period, PredictionPairStatus, PredictionPeriod} from  "../interfaces/IPredictionManager.sol";
import {IPredictUpDown, PredictionMarket} from  "../interfaces/IPredictUpDown.sol";

library LibPredictionManager {

    bytes32 constant PREDICTION_MANAGER_STORAGE_POSITION = keccak256("apollox.prediction.manager.storage");

    struct PredictionPair {
        string name;
        address base;
        uint16 basePosition;
        mapping(Period => PredictionPeriod) predictionPeriods;
        Period[] periods;
    }

    struct PredictionManagerStorage {
        mapping(address base => PredictionPair) predictionPairs;
        address[] predictionPairBases;
    }

    function predictionManagerStorage() internal pure returns (PredictionManagerStorage storage pms) {
        bytes32 position = PREDICTION_MANAGER_STORAGE_POSITION;
        assembly {
            pms.slot := position
        }
    }

    event AddPredictionPair(address indexed base, string name, PredictionPeriod[] predictionPeriods);
    event RemovePredictionPair(address indexed base);
    event UpdatePredictionPairStatus(address indexed base, PredictionPairStatus status);
    event UpdatePredictionPairPeriodMaxCap(address indexed base, Period indexed period, uint256 maxUpUsd, uint256 maxDownUsd);
    event UpdatePredictionPairPeriodWinRatio(address indexed base, Period indexed period, uint16 winRatio);
    event UpdatePredictionPairPeriodFee(address indexed base, Period indexed period, uint16 openFeeP, uint16 winCloseFeeP, uint16 loseCloseFeeP);
    event AddPeriodForPredictionPair(address indexed base, PredictionPeriod[] predictionPeriods);
    event ReplacePredictionPairPeriod(address indexed base, PredictionPeriod[] predictionPeriods);

    function requireExists(address base) internal view returns (PredictionPair storage) {
        PredictionManagerStorage storage pms = predictionManagerStorage();
        PredictionPair storage pp = pms.predictionPairs[base];
        require(pp.base != address(0), "LibPredictionManager: Predict pair not exist");
        return pp;
    }

    function addPredictionPair(address base, string calldata name, PredictionPeriod[] calldata predictionPeriods) internal {
        PredictionManagerStorage storage pms = predictionManagerStorage();
        PredictionPair storage pp = pms.predictionPairs[base];
        require(pp.base == address(0), "LibPredictionManager: Predict pair already exists");
        require(IPriceFacade(address(this)).getPrice(base) > 0, "LibPredictionManager: No price feed has been configured for the predict pair");
        pp.base = base;
        pp.name = name;
        pp.basePosition = uint16(pms.predictionPairBases.length);
        pms.predictionPairBases.push(base);
        Period[] memory periods = new Period[](predictionPeriods.length);
        for (uint256 i = 0; i < predictionPeriods.length;) {
            PredictionPeriod memory pi = predictionPeriods[i];
            pp.predictionPeriods[pi.period] = pi;
            periods[i] = pi.period;
            unchecked{++i;}
        }
        pp.periods = periods;
        emit AddPredictionPair(base, name, predictionPeriods);
    }

    function removePredictionPair(address base) internal {
        PredictionPair storage pp = requireExists(base);
        PredictionManagerStorage storage pms = predictionManagerStorage();

        PredictionMarket[] memory markets = IPredictUpDown(address(this)).getPredictionMarket(base, pp.periods);
        for (uint256 i = 0; i < markets.length;) {
            PredictionMarket memory pm = markets[i];
            if (pm.upUsd > 0 || pm.downUsd > 0) {
                revert("LibPredictionManager: There are still unclosed predictions.");
            }
            unchecked{++i;}
        }
        _removeAllPeriodFromPredictionPair(pp);
        uint lastPosition = pms.predictionPairBases.length - 1;
        uint basePosition = pp.basePosition;
        if (basePosition != lastPosition) {
            address lastBase = pms.predictionPairBases[lastPosition];
            pms.predictionPairBases[basePosition] = lastBase;
            pms.predictionPairs[lastBase].basePosition = uint16(basePosition);
        }
        pms.predictionPairBases.pop();
        delete pms.predictionPairs[base];
        emit RemovePredictionPair(base);
    }

    function updatePredictionPairStatus(address base, PredictionPairStatus status) internal {
        PredictionPair storage pp = requireExists(base);
        for (uint256 i = 0; i < pp.periods.length;) {
            pp.predictionPeriods[pp.periods[i]].status = status;
            unchecked{++i;}
        }
        emit UpdatePredictionPairStatus(base, status);
    }

    function _requireExistsPeriod(PredictionPair storage pp, Period period) private view returns (PredictionPeriod storage){
        PredictionPeriod storage pi = pp.predictionPeriods[period];
        require(pi.winRatio > 0, "LibPredictionManager: The period does not exist.");
        return pi;
    }

    function updatePredictionPairPeriodMaxCap(
        PredictionPair storage pp, Period period, uint256 maxUpUsd, uint256 maxDownUsd
    ) internal {
        PredictionPeriod storage pi = _requireExistsPeriod(pp, period);
        pi.maxUpUsd = maxUpUsd;
        pi.maxDownUsd = maxDownUsd;
        emit UpdatePredictionPairPeriodMaxCap(pp.base, period, maxUpUsd, maxDownUsd);
    }

    function updatePredictionPairPeriodWinRatio(PredictionPair storage pp, Period period, uint16 winRatio) internal {
        PredictionPeriod storage pi = _requireExistsPeriod(pp, period);
        pi.winRatio = winRatio;
        emit UpdatePredictionPairPeriodWinRatio(pp.base, period, winRatio);
    }

    function updatePredictionPairPeriodFee(
        PredictionPair storage pp, Period period, uint16 openFeeP, uint16 winCloseFeeP, uint16 loseCloseFeeP
    ) internal {
        PredictionPeriod storage pi = _requireExistsPeriod(pp, period);
        pi.openFeeP = openFeeP;
        pi.winCloseFeeP = winCloseFeeP;
        pi.loseCloseFeeP = loseCloseFeeP;
        emit UpdatePredictionPairPeriodFee(pp.base, period, openFeeP, winCloseFeeP, loseCloseFeeP);
    }

    function addPeriodForPredictionPair(PredictionPair storage pp, PredictionPeriod[] calldata predictionPeriods) internal {
        for (uint256 i = 0; i < predictionPeriods.length;) {
            PredictionPeriod calldata pi = predictionPeriods[i];
            require(pp.predictionPeriods[pi.period].winRatio == 0, "LibPredictionManager: The period already exists");
            pp.predictionPeriods[pi.period] = pi;
            pp.periods.push(pi.period);
            unchecked{++i;}
        }
        emit AddPeriodForPredictionPair(pp.base, predictionPeriods);
    }

    function replacePredictionPairPeriod(PredictionPair storage pp, PredictionPeriod[] calldata predictionPeriods) internal {
        _removeAllPeriodFromPredictionPair(pp);
        for (uint256 i = 0; i < predictionPeriods.length;) {
            PredictionPeriod calldata pi = predictionPeriods[i];
            pp.predictionPeriods[pi.period] = pi;
            pp.periods.push(pi.period);
            unchecked{++i;}
        }
        emit ReplacePredictionPairPeriod(pp.base, predictionPeriods);
    }

    function _removeAllPeriodFromPredictionPair(PredictionPair storage pp) private {
        uint oldCount = pp.periods.length;
        for (uint256 i = 0; i < oldCount;) {
            Period period = pp.periods[i];
            delete pp.predictionPeriods[period];
            unchecked{++i;}
        }
        for (uint256 i = 0; i < oldCount;) {
            pp.periods.pop();
            unchecked{++i;}
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibAccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 constant ACCESS_CONTROL_STORAGE_POSITION = keccak256("apollox.access.control.storage");

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct AccessControlStorage {
        mapping(bytes32 => RoleData) roles;
        mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;
        mapping(bytes4 => bool) supportedInterfaces;
    }

    function accessControlStorage() internal pure returns (AccessControlStorage storage acs) {
        bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;
        assembly {
            acs.slot := position
        }
    }

    function checkRole(bytes32 role) internal view {
        checkRole(role, msg.sender);
    }

    function checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(account),
                    " is missing role ",
                    Strings.toHexString(uint256(role), 32)
                )
            )
            );
        }
    }

    function hasRole(bytes32 role, address account) internal view returns (bool) {
        AccessControlStorage storage acs = accessControlStorage();
        return acs.roles[role].members[account];
    }

    function grantRole(bytes32 role, address account) internal {
        AccessControlStorage storage acs = accessControlStorage();
        if (!hasRole(role, account)) {
            acs.roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
            acs.roleMembers[role].add(account);
        }
    }

    function revokeRole(bytes32 role, address account) internal {
        AccessControlStorage storage acs = accessControlStorage();
        if (hasRole(role, account)) {
            acs.roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
            acs.roleMembers[role].remove(account);
        }
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        AccessControlStorage storage acs = accessControlStorage();
        bytes32 previousAdminRole = acs.roles[role].adminRole;
        acs.roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

enum RequestType {CLOSE, OPEN, PREDICT}

interface IPriceFacade {

    struct Config {
        uint16 lowPriceGapP;
        uint16 highPriceGapP;
        uint16 maxDelay;
        uint16 triggerLowPriceGapP;   // 1e4
        uint16 triggerHighPriceGapP;  // 1e4
    }

    struct PriceCallbackParam {
        bytes32 requestId;
        uint64 price;
    }

    function setLowAndHighPriceGapP(uint16 lowPriceGapP, uint16 highPriceGapP) external;

    function setTriggerLowAndHighPriceGapP(uint16 triggerLowPriceGapP, uint16 triggerHighPriceGapP) external;

    function setMaxDelay(uint16 maxDelay) external;

    function getPriceFacadeConfig() external view returns (Config memory);

    function getPrice(address token) external view returns (uint256);

    function getPriceFromCacheOrOracle(address token) external view returns (uint64 price, uint40 updatedAt);

    function requestPrice(bytes32 tradeHash, address token, RequestType requestType) external;

    function requestPriceCallback(bytes32 requestId, uint64 price) external;

    function batchRequestPriceCallback(PriceCallbackParam[] calldata params) external;

    function confirmTriggerPrice(address token, uint64 price) external returns (bool, uint64, uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

enum Period{MINUTE1, MINUTE5, MINUTE10, MINUTE15, MINUTE30, HOUR1, HOUR2, HOUR3, HOUR4, HOUR6, HOUR8, HOUR12, DAY1}
enum PredictionPairStatus{AVAILABLE, CLOSE_ONLY, CLOSED}

struct PredictionPeriod {
    uint256 maxUpUsd;     // USD 1e18
    uint256 maxDownUsd;   // USD 1e18
    Period period;
    PredictionPairStatus status;
    uint16 winRatio;      // 1e4
    uint16 openFeeP;      // 1e4
    uint16 winCloseFeeP;  // 1e4
    uint16 loseCloseFeeP; // 1e4
}

interface IPredictionManager {

    event AddPredictionPair(address indexed base, string name, PredictionPeriod[] predictionPeriods);
    event RemovePredictionPair(address indexed base);
    event UpdatePredictionPairStatus(address indexed base, PredictionPairStatus status);
    event UpdatePredictionPairPeriodMaxCap(address indexed base, Period indexed period, uint256 maxUpUsd, uint256 maxDownUsd);
    event UpdatePredictionPairPeriodWinRatio(address indexed base, Period indexed period, uint16 winRatio);
    event UpdatePredictionPairPeriodFee(address indexed base, Period indexed period, uint16 openFeeP, uint16 winCloseFeeP, uint16 loseCloseFeeP);
    event AddPeriodForPredictionPair(address indexed base, PredictionPeriod[] predictionPeriods);
    event ReplacePredictionPairPeriod(address indexed base, PredictionPeriod[] predictionPeriods);

    struct PeriodCap {
        Period period;
        uint256 maxUpUsd;     // USD 1e18
        uint256 maxDownUsd;   // USD 1e18
    }

    struct PeriodWinRatio {
        Period period;
        uint16 winRatio;
    }

    struct PeriodFee {
        Period period;
        uint16 openFeeP;      // 1e4
        uint16 winCloseFeeP;  // 1e4
        uint16 loseCloseFeeP; // 1e4
    }

    struct PredictionPairView {
        string name;
        address base;
        PredictionPeriod[] predictionPeriods;
    }

    function addPredictionPair(
        address base, string calldata name, PredictionPeriod[] calldata predictionPeriods
    ) external;

    function removePredictionPair(address base) external;

    function updatePredictionPairStatus(address base, PredictionPairStatus status) external;

    function updatePredictionPairMaxCap(address base, PeriodCap[] calldata periodCaps) external;

    function updatePredictionPairWinRatio(address base, PeriodWinRatio[] calldata periodWinRatios) external;

    function updatePredictionPairFee(address base, PeriodFee[] calldata periodFees) external;

    function addPeriodForPredictionPair(address base, PredictionPeriod[] calldata predictionPeriods) external;

    function replacePredictionPairPeriod(address base, PredictionPeriod[] calldata predictionPeriods) external;

    function getPredictionPairByBase(address base) external returns (PredictionPairView memory);

    function predictionPairs(uint start, uint8 size) external returns (PredictionPairView[] memory);

    function getPredictionPeriod(address base, Period period) external returns (PredictionPeriod memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Period} from "./IPredictionManager.sol";

struct PendingPrediction {
    address tokenIn;
    uint96 amountIn;     // tokenIn decimals
    address predictionPairBase;
    uint96 openFee;      // tokenIn decimals
    address user;
    uint64 price;        // 1e8
    uint24 broker;
    bool isUp;
    uint128 blockNumber;
    Period period;
}

struct OpenPrediction {
    address tokenIn;
    uint96 betAmount;      // tokenIn decimals
    address predictionPairBase;
    uint96 openFee;        // tokenIn decimals
    address user;
    uint96 betAmountUsd;
    uint32 userOpenPredictIndex;
    uint64 entryPrice;     // 1e8
    uint40 startTime;
    uint24 broker;
    bool isUp;
    Period period;
}

struct PredictionMarket {
    uint96 upUsd;
    uint96 downUsd;
}

interface IPredictUpDown {

    event PredictAndBetPending(address indexed user, uint256 indexed id, PendingPrediction pp);
    event PendingPredictionRefund(address indexed user, uint256 indexed id, PredictionRefund refund);
    event PredictAndBet(address indexed user, uint256 indexed id, OpenPrediction op);
    event SettlePredictionReject(uint256 indexed id, Period period, uint256 correctTime);
    event SettlePredictionSuccessful(
        uint256 indexed id, bool win, uint256 endPrice, address token, uint256 profitOrLoss, uint256 closeFee
    );

    enum PredictionRefund{NO, FEED_DELAY, USER_PRICE, MAX_OI}

    struct PredictionInput {
        address predictionPairBase;
        bool isUp;
        Period period;
        address tokenIn;
        uint96 amountIn;
        uint64 price;
        uint24 broker;
    }

    struct SettlePrediction {
        uint256 id;
        uint64 price;
    }

    struct PredictionView {
        uint256 id;
        address tokenIn;
        uint96 betAmount;      // tokenIn decimals
        address predictionPairBase;
        uint96 openFee;        // tokenIn decimals
        uint64 entryPrice;     // 1e8
        uint40 startTime;
        bool isUp;
        Period period;
    }

    function predictAndBet(PredictionInput memory pi) external;

    function predictAndBetBNB(PredictionInput memory pi) external payable;

    function predictionCallback(bytes32 id, uint256 price) external;

    function settlePredictions(SettlePrediction[] calldata) external;

    function getPredictionById(uint256 id) external view returns (PredictionView memory);

    function getPredictions(address user, address predictionPairBase) external view returns (PredictionView[] memory);

    function getPredictionMarket(
        address predictionPairBase, Period[] calldata periods
    ) external view returns (PredictionMarket[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ArbSys {
    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */
    function arbBlockNumber() external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}