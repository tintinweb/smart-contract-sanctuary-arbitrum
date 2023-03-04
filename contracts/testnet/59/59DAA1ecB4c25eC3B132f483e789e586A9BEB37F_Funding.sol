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
        require(roles.hasRole(msg.sender, role), "!role");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../access/Roles.sol";
import "./interfaces/IFunding.sol";
import "./interfaces/IPosition.sol";

contract Funding is Roles, IFunding {
    bytes32 public constant GOV = keccak256("GOV");
    IPosition public position;
    uint256 public defaultFundingFactor = 100; // In bps. 0.01% daily
    uint32 public fundingInterval = 1 hours; // In seconds 1 hours for main
    mapping(uint16 => IFunding.Funding) private fundingTrackers;
    mapping(uint16 => uint256) fundingFactors;

    constructor(IRoleManager _roles, IPosition _position) Roles(_roles) {
        position = _position;
    }

    //SET
    function setFundingInterval(uint32 amount) external override hasRole(GOV) {
        fundingInterval = amount;
    }

    function setFundingFactor(uint16 pairId, uint256 amount)
        external
        override
        hasRole(GOV)
    {
        fundingFactors[pairId] = amount;
    }

    function updateFunding(uint16 pairId) external override {
        IFunding.Funding storage funding = fundingTrackers[pairId];
        uint32 _now = uint32(block.timestamp);

        if (funding.lastUpdated == 0) {
            funding.lastUpdated = (_now / fundingInterval) * fundingInterval;
            return;
        }

        if (funding.lastUpdated + fundingInterval > _now) return;
        uint256 intervals = (_now - funding.lastUpdated) / fundingInterval;

        IPosition.OI memory OI = position.getIOs(pairId);

        if (OI.short == 0 && OI.long == 0) return;

        int256 fundingIncrement;

        uint256 OIDiff = OI.short > OI.long
            ? OI.short - OI.long
            : OI.long - OI.short;
        uint256 accruedFunding = (getFundingFactor(pairId) *
            OIDiff *
            intervals *
            fundingInterval) / (24 hours * (OI.long + OI.short));
        if (accruedFunding == 0) return;
        if (OI.long > OI.short) {
            fundingIncrement = int256(accruedFunding);
        } else {
            fundingIncrement = -1 * int256(accruedFunding);
        }

        funding.fundingTracker += fundingIncrement;
        funding.lastUpdated = _now;

        emit FundingUpdated(pairId, funding.fundingTracker, fundingIncrement);
    }

    //GET

    function getLastUpdated(uint16 pairId)
        external
        view
        override
        returns (uint32)
    {
        return fundingTrackers[pairId].lastUpdated;
    }

    function getFundingFactor(uint16 pairId)
        public
        view
        override
        returns (uint256)
    {
        if (fundingFactors[pairId] > 0) return fundingFactors[pairId];
        return defaultFundingFactor;
    }

    function getFundingTracker(uint16 pairId)
        external
        view
        override
        returns (int256)
    {
        IFunding.Funding memory funding = fundingTrackers[pairId];
        uint32 _now = uint32(block.timestamp);

        if (funding.lastUpdated == 0) {
            return 0;
        }

        if (funding.lastUpdated + fundingInterval > _now)
            return funding.fundingTracker;

        IPosition.OI memory OI = position.getIOs(pairId);

        if (OI.short == 0 && OI.long == 0) return funding.fundingTracker;
        uint256 intervals = (_now - funding.lastUpdated) / fundingInterval;

        int256 fundingIncrement;

        uint256 OIDiff = OI.short > OI.long
            ? OI.short - OI.long
            : OI.long - OI.short;
        uint256 accruedFunding = (getFundingFactor(pairId) *
            OIDiff *
            intervals *
            fundingInterval) / (24 hours * (OI.long + OI.short));
        if (accruedFunding == 0) return funding.fundingTracker;
        if (OI.long > OI.short) {
            fundingIncrement = int256(accruedFunding);
        } else {
            fundingIncrement = -1 * int256(accruedFunding);
        }
        return funding.fundingTracker + fundingIncrement;
    }

    function getFunding(uint16 pairId)
        external
        view
        override
        returns (IFunding.Funding memory)
    {
        return fundingTrackers[pairId];
    }

    function getFundings(uint16[] calldata pairId)
        external
        view
        override
        returns (IFunding.Funding[] memory fl)
    {
        uint256 length = pairId.length;
        fl = new IFunding.Funding[](length);
        for (uint16 i = 0; i < length; i++) {
            fl[i] = fundingTrackers[pairId[i]];
        }
        return fl;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/Types.sol";

interface IFunding {
    event FundingUpdated(
        uint16 pairId,
        int256 fundingTracker,
        int256 fundingIncrement
    );

    struct Funding {
        int256 fundingTracker;
        uint32 lastUpdated;
    }

    //SET
    function setFundingInterval(uint32 amount) external;

    function setFundingFactor(uint16 pairId, uint256 amount) external;

    function updateFunding(uint16 pairId) external;

    //GET
    function getLastUpdated(uint16 pairId) external view returns (uint32);

    function getFundingFactor(uint16 pairId) external view returns (uint256);

    function getFundingTracker(uint16 pairId) external view returns (int256);

    function getFunding(uint16 pairId) external view returns (Funding memory);

    function getFundings(uint16[] calldata pairId)
        external
        view
        returns (Funding[] memory);
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
        uint16 leverage,
        uint32 timestamp,
        uint256 entryPrice,
        uint256 amount,
        int256 fundingTracker
    );

    event ClosePosition(
        bytes32 id,
        uint256 closePrice,
        int256 pnl,
        uint16 closeType
    );

    event UpdateTP(bytes32 id, uint256 tp);

    event UpdateSL(bytes32 id, uint256 sl);

    struct OI {
        uint256 long;
        uint256 short;
    }

    //SET
    function addPosition(Types.Position calldata) external returns (bytes32);

    function updatePosition(bytes32 id, Types.Position calldata position)
        external;

    function closePosition(
        bytes32 id,
        uint256 closePrice,
        int256 pnl,
        uint16 closeType
    ) external;

    function setTp(bytes32 id, uint256 tp) external;

    function setSl(bytes32 id, uint256 sl) external;

    //GET
    function TP(bytes32 id) external view returns (uint256);

    function SL(bytes32 id) external view returns (uint256);

    function getPosition(bytes32 id)
        external
        view
        returns (Types.Position memory);

    function getPositions(bytes32[] calldata id)
        external
        view
        returns (Types.Position[] memory _positions);

    function getIOs(uint16 pairId) external view returns (OI memory);

    function getIO(uint16 pairId) external view returns (uint256);

    function getIOLong(uint16 pairId) external view returns (uint256);

    function getIOShort(uint16 pairId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Types {
    struct Order {
        bool isLong;
        uint16 pairId;
        uint16 leverage;
        uint256 amount;
        uint256 tp;
        uint256 sl;
    }

    struct OrderLimit {
        address owner;
        bool isLong;
        uint8 orderType;
        uint16 pairId;
        uint16 leverage;
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
        uint16 leverage;
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