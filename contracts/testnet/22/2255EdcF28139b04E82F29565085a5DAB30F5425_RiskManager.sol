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

    modifier hasRole(bytes32 role) {
        require(
            roles.hasRole(msg.sender, role),
            string(abi.encodePacked("!role:", role))
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../../interfaces/Types.sol";

interface IRiskManager {
    function checkRisk(
        Types.Position calldata position,
        bool isClose
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../access/Roles.sol";
import "./interfaces/IRiskManager.sol";

contract RiskManager is Roles, IRiskManager {
    bytes32 private constant RISK_CHECK = keccak256("RISK_CHECK");
    bool isStop;

    constructor(IRoleManager _roles) Roles(_roles) {}

    function checkRisk(
        Types.Position calldata position,
        bool isClose
    ) external override hasRole(RISK_CHECK) returns (bool) {
        if (!isStop) {
            isStop = true;
        }
        if (isClose) {}
        if (position.amount > 1e30) {}
        return true;
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