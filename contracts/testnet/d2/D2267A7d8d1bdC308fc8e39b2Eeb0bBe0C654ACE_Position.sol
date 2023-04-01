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

    event MasterShare(bytes32 id, address master, uint256 amount);

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

    function updatePositionWithMaster(bytes32 id)
        external
        returns (
            address user,
            address master,
            int256 amount
        );

    function updatePosition(bytes32 id, Types.Position calldata position)
        external;

    function closePosition(
        bytes32 id,
        uint256 closePrice,
        int256 pnl,
        int256 finalAmount,
        uint16 closeType
    ) external returns (address masterAddress, uint256 amountShare);

    function setTp(bytes32 id, uint256 tp) external;

    function setSl(bytes32 id, uint256 sl) external;

    //GET
    function TP(bytes32 id) external view returns (uint256);

    function SL(bytes32 id) external view returns (uint256);

    function getPositionPairId(bytes32 id) external view returns (uint16);

    function getPosition(bytes32 id)
        external
        view
        returns (Types.Position memory);

    function getMasterInfo(bytes32 id) external view returns (Master memory);

    function getPositions(bytes32[] calldata id)
        external
        view
        returns (Types.Position[] memory _positions);

    function getTP(bytes32 id) external view returns (uint256);

    function getSL(bytes32 id) external view returns (uint256);

    function getIOs(uint16 pairId) external view returns (OI memory);

    function getIO(uint16 pairId) external view returns (uint256);

    function getIOLong(uint16 pairId) external view returns (uint256);

    function getIOShort(uint16 pairId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../access/Roles.sol";
import "./interfaces/IPosition.sol";
import "./interfaces/IFunding.sol";

contract Position is Roles, IPosition {
    bytes32 private constant TRADING = keccak256("TRADING");
    bytes32 private constant GOV = keccak256("GOV");
    IFunding public funding;
    mapping(bytes32 => Types.Position) private positions;
    mapping(bytes32 => Master) private masterInfo;
    mapping(bytes32 => uint256) public TP;
    mapping(bytes32 => uint256) public SL;
    mapping(uint16 => IPosition.OI) private OIs;
    uint256 private constant BPS = 1e6; //Base Percent

    constructor(IRoleManager _roles) Roles(_roles) {}

    function setFunding(IFunding _funding) external hasRole(GOV) {
        funding = _funding;
    }

    //SET

    function addPositionWithMaster(
        Types.Position calldata position,
        Master calldata master,
        uint256 percentTp,
        uint256 percentSl
    ) external override hasRole(TRADING) returns (bytes32) {
        require(
            masterInfo[master.masterId].owner == address(0x0),
            "!master-position"
        );
        bytes32 id = _addPosition(position, master.masterId);
        masterInfo[id] = master;
        if (percentTp > 0) {
            uint256 tp = _getPricePnL(
                position.isLong,
                position.entryPrice,
                true,
                position.leverage,
                percentTp
            );
            TP[id] = tp;
            emit UpdateTP(id, tp);
        } else {
            if (TP[master.masterId] > 0) {
                TP[id] = TP[master.masterId];
                emit UpdateTP(id, TP[id]);
            }
        }
        if (percentSl > 0) {
            uint256 sl = _getPricePnL(
                position.isLong,
                position.entryPrice,
                false,
                position.leverage,
                percentSl
            );
            SL[id] = sl;
            emit UpdateSL(id, sl);
        } else {
            if (SL[master.masterId] > 0) {
                SL[id] = SL[master.masterId];
                emit UpdateSL(id, SL[id]);
            }
        }
        return id;
    }

    function _getPricePnL(
        bool isLong,
        uint256 entryPrice,
        bool isTP,
        uint256 leverage,
        uint256 percent
    ) internal pure returns (uint256) {
        uint256 price;
        uint256 priceChange = (percent * entryPrice) / leverage;
        if ((isLong && isTP) || (!isLong && !isTP)) {
            price = entryPrice + priceChange;
        } else {
            if (entryPrice > priceChange) {
                price = entryPrice - priceChange;
            }
        }
        return price;
    }

    function addPosition(Types.Position calldata position)
        external
        override
        hasRole(TRADING)
        returns (bytes32)
    {
        return _addPosition(position, bytes32(0));
    }

    function _addPosition(Types.Position calldata position, bytes32 masterId)
        internal
        returns (bytes32)
    {
        bytes32 id = _getPositionId(position);
        require(positions[id].owner == address(0x0), "!exist");
        positions[id] = position;
        uint256 positionSize = (position.amount * position.leverage) / BPS;
        IPosition.OI storage oi = OIs[position.pairId];
        if (position.isLong) {
            oi.long += positionSize;
        } else {
            oi.short += positionSize;
        }
        emit OpenPosition(
            id,
            position.owner,
            position.isLong,
            position.pairId,
            position.leverage,
            position.timestamp,
            position.entryPrice,
            position.amount,
            position.fundingTracker,
            masterId
        );
        funding.updateFunding(position.pairId);
        return id;
    }

    function updatePosition(bytes32 id, Types.Position calldata position)
        external
        override
        hasRole(TRADING)
    {
        _updatePosition(id, position);
        if (masterInfo[id].masterId != bytes32(0x0)) {
            masterInfo[id].masterId = bytes32(0x0);
        }
    }

    function updatePositionWithMaster(bytes32 id)
        external
        override
        returns (
            address user,
            address master,
            int256 amount
        )
    {
        bytes32 masterId = masterInfo[id].masterId;
        require(masterId != bytes32(0x0), "!not-linking");
        Types.Position memory masterPosition = positions[masterId];
        Types.Position memory position = positions[id];
        int256 amountChange;
        if (masterPosition.entryPrice == position.entryPrice) {
            amountChange =
                int256(position.leverage * position.amount) /
                int256(int32(masterPosition.leverage)) -
                int256(position.amount);
        } else {
            //TODO fee open/fee close
            amountChange =
                int256(position.entryPrice * position.amount) /
                int256(masterPosition.entryPrice) -
                int256(position.amount);
        }
        _updatePosition(id, position);
        return (position.owner, masterPosition.owner, amountChange);
    }

    function _updatePosition(bytes32 id, Types.Position memory position)
        internal
    {
        IPosition.OI storage oi = OIs[position.pairId];
        Types.Position memory lastPosition = positions[id];
        require(lastPosition.amount > 0, "!exist-position");
        uint256 lastPositionSize = (lastPosition.amount *
            lastPosition.leverage) / BPS;
        uint256 currentPositionSize = (position.amount * position.leverage) /
            BPS;
        uint256 sizeDiff = currentPositionSize > lastPositionSize
            ? currentPositionSize - lastPositionSize
            : lastPositionSize - currentPositionSize;
        if (currentPositionSize > lastPositionSize) {
            if (position.isLong) {
                oi.long += sizeDiff;
            } else {
                oi.short += sizeDiff;
            }
        } else {
            if (position.isLong) {
                oi.long -= sizeDiff;
            } else {
                oi.short -= sizeDiff;
            }
        }
        positions[id] = position;
        emit OpenPosition(
            id,
            position.owner,
            position.isLong,
            position.pairId,
            position.leverage,
            position.timestamp,
            position.entryPrice,
            position.amount,
            position.fundingTracker,
            bytes32(0)
        );
        funding.updateFunding(position.pairId);
    }

    function closePosition(
        bytes32 id,
        uint256 closePrice,
        int256 pnl,
        int256 finalAmount,
        uint16 closeType
    )
        external
        override
        hasRole(TRADING)
        returns (address masterAddress, uint256 amountShare)
    {
        Master memory master = masterInfo[id];
        emit ClosePosition(id, closePrice, pnl, closeType);
        if (closeType == 4) {
            require(positions[master.masterId].amount == 0, "!master-closed");
        }
        if (
            master.sharePercent > 0 &&
            uint256(finalAmount) > positions[id].amount
        ) {
            amountShare =
                ((uint256(finalAmount) - positions[id].amount) *
                    master.sharePercent) /
                BPS;
            emit MasterShare(id, master.owner, amountShare);
        }
        return (master.owner, amountShare);
    }

    function setTp(bytes32 id, uint256 tp) external override hasRole(TRADING) {
        TP[id] = tp;
        emit UpdateTP(id, tp);
    }

    function setSl(bytes32 id, uint256 sl) external override hasRole(TRADING) {
        SL[id] = sl;
        emit UpdateSL(id, sl);
    }

    //GET

    function getPositionPairId(bytes32 id)
        external
        view
        override
        returns (uint16)
    {
        return positions[id].pairId;
    }

    function getPosition(bytes32 id)
        external
        view
        override
        returns (Types.Position memory)
    {
        return positions[id];
    }

    function getMasterInfo(bytes32 id)
        external
        view
        override
        returns (Master memory)
    {
        return masterInfo[id];
    }

    function getPositions(bytes32[] calldata id)
        external
        view
        override
        returns (Types.Position[] memory _positions)
    {
        uint256 length = id.length;
        _positions = new Types.Position[](length);
        for (uint256 i = 0; i < length; ) {
            _positions[i] = positions[id[i]];
            unchecked {
                i++;
            }
        }
        return _positions;
    }

    function getIOs(uint16 pairId)
        external
        view
        override
        returns (IPosition.OI memory)
    {
        return OIs[pairId];
    }

    function getIO(uint16 pairId) external view override returns (uint256) {
        return OIs[pairId].long + OIs[pairId].short;
    }

    function getIOLong(uint16 pairId) external view override returns (uint256) {
        return OIs[pairId].long;
    }

    function getIOShort(uint16 pairId)
        external
        view
        override
        returns (uint256)
    {
        return OIs[pairId].short;
    }

    function getTP(bytes32 id) external view override returns (uint256) {
        return TP[id];
    }

    function getSL(bytes32 id) external view override returns (uint256) {
        return SL[id];
    }

    function _getPositionId(Types.Position calldata position)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    position.owner,
                    position.isLong,
                    position.pairId,
                    position.timestamp
                )
            );
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