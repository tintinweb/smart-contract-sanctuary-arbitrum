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

    error NotAuthorized(bytes32 role);

    modifier hasRole(bytes32 role) {
        if (!roles.hasRole(msg.sender, role)) {
            revert NotAuthorized(role);
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPair {
    event PairUpdated(
        uint16 pairId,
        address chainlinkFeed,
        bool isClosed,
        bool allowSelfExecution,
        uint32 maxLeverage,
        uint32 minLeverage,
        uint32 openFee,
        uint32 closeFee,
        uint32 spread,
        uint32 minAge,
        uint256 maxDeviation,
        uint256 liqThreshold
    );

    struct Pair {
        address chainlinkFeed;
        bool isClosed;
        bool allowSelfExecution;
        uint32 maxLeverage;
        uint32 minLeverage;
        uint32 openFee;
        uint32 closeFee;
        uint32 spread;
        uint32 minAge;
        uint256 maxDeviation;
        uint256 liqThreshold;
    }

    function set(uint16 pairId, Pair memory pairInfo) external;

    function setStatus(
        uint16[] calldata pairIds,
        bool[] calldata isClosed
    ) external;

    function get(uint16 pairId) external view returns (Pair memory);

    function getOpenFee(uint16 pairId) external view returns (uint32);

    function getCloseFee(uint16 pairId) external view returns (uint32);

    function getMany(
        uint16[] calldata pairIds
    ) external view returns (Pair[] memory);

    function getChainlinkFeed(uint16 pairId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../access/Roles.sol";
import "./interfaces/IPair.sol";

contract Pair is Roles, IPair {
    bytes32 private constant GOV = keccak256("GOV");
    bytes32 private constant MARKET = keccak256("MARKET");
    mapping(uint16 => IPair.Pair) public pairList;

    constructor(IRoleManager _roles) Roles(_roles) {}

    function set(
        uint16 pairId,
        Pair memory pairInfo
    ) external override hasRole(GOV) {
        require(pairInfo.maxLeverage >= 1, "!max-leverage");
        require(pairInfo.openFee <= 5e5, "!open-fee");
        require(pairInfo.closeFee <= 5e5, "!close-fee");
        require(pairInfo.spread <= 1e5, "!spread-fee");
        require(pairInfo.maxDeviation <= 1e5, "!maxDeviation-fee");
        require(pairInfo.liqThreshold < 1e6, "!max-liq-threshold");
        pairList[pairId] = pairInfo;
        emit PairUpdated(
            pairId,
            pairInfo.chainlinkFeed,
            pairInfo.isClosed,
            pairInfo.allowSelfExecution,
            pairInfo.maxLeverage,
            pairInfo.minLeverage,
            pairInfo.openFee,
            pairInfo.closeFee,
            pairInfo.spread,
            pairInfo.minAge,
            pairInfo.maxDeviation,
            pairInfo.liqThreshold
        );
    }

    function setStatus(
        uint16[] calldata pairIds,
        bool[] calldata isClosed
    ) external override hasRole(MARKET) {
        for (uint256 i; i < pairIds.length; ) {
            Pair storage pair = pairList[pairIds[i]];
            pair.isClosed = isClosed[i];
            unchecked {
                ++i;
            }
        }
    }

    function get(uint16 pairId) external view override returns (Pair memory) {
        return pairList[pairId];
    }

    function getOpenFee(uint16 pairId) external view override returns (uint32) {
        return pairList[pairId].openFee;
    }

    function getCloseFee(
        uint16 pairId
    ) external view override returns (uint32) {
        return pairList[pairId].closeFee;
    }

    function getMany(
        uint16[] calldata pairIds
    ) external view override returns (Pair[] memory pairInfos) {
        uint256 length = pairIds.length;
        pairInfos = new Pair[](length);
        for (uint256 i; i < length; ) {
            pairInfos[i] = pairList[pairIds[i]];
            unchecked {
                ++i;
            }
        }
        return pairInfos;
    }

    function getChainlinkFeed(
        uint16 pairId
    ) external view override returns (address) {
        return pairList[pairId].chainlinkFeed;
    }
}