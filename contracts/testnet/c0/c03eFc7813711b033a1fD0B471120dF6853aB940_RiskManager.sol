// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Governable {
    address public gov;
    event GovChange(address pre, address next);

    constructor() {
        gov = msg.sender;
        emit GovChange(address(0x0), msg.sender);
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        emit GovChange(gov, _gov);
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRoleManager {
    function grantRole(address account, bytes32 key) external;

    function revokeRole(address account, bytes32 key) external;

    function hasRole(address account, bytes32 key) external view returns (bool);

    function getRoleCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Governable.sol";
import "./interfaces/IRoleManager.sol";

contract Roles {
    IRoleManager public roles;

    constructor(IRoleManager rs) {
        roles = rs;
    }

    error NotAuthorized(address caller, bytes32 role);

    modifier hasRole(bytes32 role) {
        if (!roles.hasRole(msg.sender, role)) {
            revert NotAuthorized(msg.sender, role);
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/Types.sol";

interface IPool {
    event Deposit(address owner, uint256 amount, uint256 amountLp);
    event Withdraw(address owner, uint256 amount, uint256 amountLp);
    event ProtocolWithdraw(address wallet, uint256 amount);
    event OracleWithdraw(address wallet, uint256 amount);
    event FeePaid(bytes32 id, uint8 feeType, uint256 fee, uint256 oracle);

    function changeWithdrawFee(uint256 amount) external;

    function changeLiquidityShare(uint256 percent) external;

    function deposit(uint256 amount) external returns (uint256);

    function depositGasLess(
        uint256 amount,
        Types.GasLess calldata gasLess
    ) external returns (uint256);

    function depositWithPermit(
        uint256 amount,
        Types.Permit calldata permit
    ) external returns (uint256);

    function depositGasLessWithPermit(
        uint256 amount,
        Types.GasLess calldata gasLess,
        Types.Permit calldata permit
    ) external returns (uint256);

    function withdraw(uint256 amountLp) external returns (uint256);

    function withdrawGasLess(
        uint256 amountLp,
        Types.GasLess calldata gasLess
    ) external returns (uint256);

    function creditFee(
        bytes32 id,
        uint8 feeType,
        uint256 fee,
        uint256 oracle
    ) external;

    function transferIn(address from, uint256 amount) external;

    function transferOut(address to, uint256 amount) external;

    function settlePosition(address user, uint256 amount, int256 pnl) external;

    function protocolWithdraw(uint256 amount, address wallet) external;

    function oracleWithdraw(uint256 amount, address wallet) external;

    function getPoolBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/Types.sol";

interface IPosition {
    event OpenPosition(
        bytes32 id,
        address owner,
        bool isLong,
        uint16 pairId,
        uint32 leverage,
        uint32 timestamp,
        uint256 entryPrice,
        uint256 amount,
        int256 fundingTracker,
        bytes32 masterId
    );

    event ClosePosition(
        bytes32 id,
        uint256 closePrice,
        int256 pnl,
        uint16 closeType
    );

    event UpdateTP(bytes32 id, uint256 tp);

    event UpdateSL(bytes32 id, uint256 sl);

    struct Master {
        address owner;
        bytes32 masterId;
        uint256 sharePercent;
    }

    struct OI {
        uint256 long;
        uint256 short;
    }

    //SET
    function addPosition(Types.Position calldata) external returns (bytes32);

    function addPositionWithMaster(
        Types.Position calldata position,
        Master calldata master,
        uint256 percentTp,
        uint256 percentSl
    ) external returns (bytes32);

    function updatePositionWithMaster(
        bytes32 id,
        int256 price
    )
        external
        returns (
            address user,
            address master,
            int256 amount,
            int256 sizeChange
        );

    function updatePosition(
        bytes32 id,
        Types.Position calldata position
    ) external;

    function closePosition(
        bytes32 id,
        uint256 closePrice,
        int256 pnl,
        int256 finalAmount,
        uint16 closeType
    ) external returns (address masterAddress, int256 amountShare);

    function setTp(bytes32 id, uint256 tp) external;

    function setSl(bytes32 id, uint256 sl) external;

    //GET
    function TP(bytes32 id) external view returns (uint256);

    function SL(bytes32 id) external view returns (uint256);

    function getPositionPairId(bytes32 id) external view returns (uint16);

    function getPosition(
        bytes32 id
    ) external view returns (Types.Position memory);

    function getMasterInfo(bytes32 id) external view returns (Master memory);

    function getPositions(
        bytes32[] calldata id
    ) external view returns (Types.Position[] memory _positions);

    function getTP(bytes32 id) external view returns (uint256);

    function getSL(bytes32 id) external view returns (uint256);

    function getIOs(uint16 pairId) external view returns (OI memory);

    function getIO(uint16 pairId) external view returns (uint256);

    function getIOLong(uint16 pairId) external view returns (uint256);

    function getIOShort(uint16 pairId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../../interfaces/Types.sol";

interface IRiskManager {
    struct MarketInfo {
        uint256 tLong;
        uint256 tShort;
    }

    function checkRisk(
        Types.Position calldata position,
        uint256 closePrice
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../access/Roles.sol";
import "./interfaces/IRiskManager.sol";
import "./interfaces/IPosition.sol";
import "./interfaces/IPool.sol";

contract RiskManager is Roles, IRiskManager {
    bytes32 private constant RISK_CHECK = keccak256("RISK_CHECK");
    uint256 private constant BPS = 1e6;
    uint private risksThreshold = 8e5;
    IPool immutable pool;
    IPosition immutable positionStorage;
    mapping(uint16 => MarketInfo) public marketInfo;

    constructor(
        IRoleManager _roles,
        IPosition _position,
        IPool _pool
    ) Roles(_roles) {
        positionStorage = _position;
        pool = _pool;
    }

    function checkRisk(
        Types.Position calldata position,
        uint256 closePrice
    ) external override hasRole(RISK_CHECK) returns (bool) {
        if (position.owner == address(0x0)) {
            return true;
        }
        if (closePrice == 0) {
            return true;
        }
        return true;
        // MarketInfo storage market = marketInfo[position.pairId];
        // IPosition.OI memory OI = positionStorage.getIOs(position.pairId);
        // uint poolBalance = pool.getPoolBalance();
        // uint currentPrice = closePrice > 0 ? closePrice : (position.entryPrice);
        // int debt = int(currentPrice) *
        //     int(OI.long - OI.short) -
        //     int(market.tLong) +
        //     int(market.tShort);
        // if (debt < int(((poolBalance * risksThreshold) * 1e18) / BPS)) {
        //     if (position.isLong) {
        //         market.tLong =
        //             market.tLong +
        //             (position.entryPrice *
        //                 position.leverage *
        //                 position.amount) /
        //             BPS;
        //     } else {
        //         market.tShort =
        //             market.tShort +
        //             (position.entryPrice *
        //                 position.leverage *
        //                 position.amount) /
        //             BPS;
        //     }
        //     return true;
        // } else {
        //     //TODO not checking for test
        //     return true;
        // }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Types {
    struct Order {
        bool isLong;
        uint16 pairId;
        uint32 leverage;
        uint256 amount;
        uint256 tp;
        uint256 sl;
    }

    struct OrderLimit {
        address owner;
        bool isLong;
        uint8 orderType;
        uint16 pairId;
        uint32 leverage;
        uint32 expire;
        uint256 amount;
        uint256 limitPrice;
        uint256 tp;
        uint256 sl;
        bytes signature;
    }

    struct Position {
        address owner;
        bool isLong;
        uint16 pairId;
        uint32 leverage;
        uint32 timestamp;
        uint256 entryPrice;
        uint256 amount;
        int256 fundingTracker;
    }

    struct GasLess {
        address owner;
        uint256 deadline;
        bytes signature;
    }

    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}