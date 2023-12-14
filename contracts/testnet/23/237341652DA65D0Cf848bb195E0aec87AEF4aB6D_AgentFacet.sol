// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(BitMap storage bitmap, uint256 index, bool value) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {StrategyTypes} from "../libraries/StrategyTypes.sol";
import {LibAgent} from "../libraries/LibAgent.sol";
import {IAgent} from "../interfaces/IAgent.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

contract AgentFacet is IAgent {
    using BitMaps for BitMaps.BitMap;

    /**
     * @notice Add Agent
     * @dev An address that has a history of being an admin can never become an agent.
     * However, if an address's history only involves being an agent, it can still become either an admin or an agent, even after being removed.
     * @param _agent The address of the agent
     * @custom:event emits a AgentAddRequested event
     */
    function addAgent(address _agent) external {
        LibAgent.Layout storage l = LibAgent.layout();
        // 验证该地址是否当过admin
        uint256 accountId = uint256(uint160(_agent));
        if (l.adminHistory.get(accountId)) {
            revert Agent__Failure(_agent);
        }
        // 验证该地址是否是0地址
        if (l.agentToAdmin[_agent] != address(0)) {
            revert Agent__AlreadyAdd(_agent);
        }
        l.pendingAgentToAdmin[_agent] = msg.sender;
        emit AgentAddRequested(msg.sender, _agent);
    }

    /**
     * @dev The new agent accepts the agent access.
     * @custom:event emits a AgentAdded event
     */
    function acceptAgent(address _admin) external {
        LibAgent.Layout storage l = LibAgent.layout();
        address pendingAdmin = l.pendingAgentToAdmin[msg.sender];
        if (pendingAdmin == _admin) {
            delete l.pendingAgentToAdmin[msg.sender];
            l.agentToAdmin[msg.sender] = _admin;
            emit AgentAdded(_admin, msg.sender);
        } else {
            revert Agent__Mismatch(msg.sender, pendingAdmin);
        }
    }

    /**
     * @notice Remove Agent
     * @param _agent The address of the agent
     * @custom:event emits a AgentRemoved event
     */
    function removeAgent(address _agent) external {
        LibAgent.Layout storage l = LibAgent.layout();
        if (l.agentToAdmin[_agent] == msg.sender) {
            delete l.agentToAdmin[_agent];
            emit AgentRemoved(msg.sender, _agent);
        } else {
            revert Agent__Mismatch(_agent, msg.sender);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

interface IAgent {
    error Agent__Failure(address agent);
    error Agent__AlreadyAdd(address agent);
    error Agent__Mismatch(address agent, address admin);

    event AgentAddRequested(address admin, address agent);
    event AgentAdded(address admin, address agent);
    event AgentRemoved(address admin, address agent);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

library LibAgent {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.Agent");

    using BitMaps for BitMaps.BitMap;

    struct Layout {
        /// @notice /* agent */ /* admin */
        mapping(address => address) pendingAgentToAdmin;
        /// @notice Associates agents with their corresponding admins /* agent */ /* admin */
        mapping(address => address) agentToAdmin;
        /// @notice Keeps a record of whether an agent has ever acted as an admin.
        //        mapping(address => bool) adminHistory;
        BitMaps.BitMap adminHistory;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice If the address of the admin is the zero address,
    /// it signifies that this address serves as the admin address, and its status should be recorded.
    function _getAdminAndUpdate(address _account) internal returns (address) {
        LibAgent.Layout storage l = LibAgent.layout();
        address admin = l.agentToAdmin[_account];
        if (admin == address(0)) {
            _updateAdminHistory(l, _account);
            return _account;
        } else {
            return admin;
        }
    }

    /// @notice Update the address status.
    function _updateAdminHistory(LibAgent.Layout storage l, address _account) internal {
        uint256 _accountId = uint256(uint160(_account));
        if (!l.adminHistory.get(_accountId)) {
            l.adminHistory.set(_accountId);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

library StrategyTypes {
    enum AssetType {
        OPTION,
        FUTURE
    }

    enum OptionType {
        LONG_CALL,
        LONG_PUT,
        SHORT_CALL,
        SHORT_PUT
    }

    ///////////////////
    // Internal Data //
    ///////////////////

    struct Option {
        uint256 positionId;
        // underlying asset address
        address underlying;
        // option strike price (with 18 decimals)
        uint256 strikePrice;
        int256 premium;
        // option expiry timestamp
        uint256 expiryTime;
        // order size
        uint256 size;
        // option type
        OptionType optionType;
        bool isActive;
    }

    struct Future {
        uint256 positionId;
        // underlying asset address
        address underlying;
        // (with 18 decimals)
        uint256 entryPrice;
        // future expiry timestamp
        uint256 expiryTime;
        // order size
        uint256 size;
        bool isLong;
        bool isActive;
    }

    struct PositionData {
        uint256 positionId;
        AssetType assetType;
        bool isActive;
    }

    struct StrategyData {
        uint256 strategyId;
        // usdc 计价的抵押品余额
        uint256 collateralAmount;
        uint256 timestamp;
        uint256 unsettled;
        int256 realisedPnl;
        uint256[] positionIds;
        bool isActive;
    }

    struct StrategyDataWithOwner {
        uint256 strategyId;
        uint256 collateralAmount;
        uint256 timestamp;
        uint256 unsettled;
        int256 realisedPnl;
        uint256[] positionIds;
        bool isActive;
        address owner;
    }

    struct StrategyAllData {
        uint256 strategyId;
        // usdc 计价的抵押品余额
        uint256 collateralAmount;
        uint256 timestamp;
        uint256 unsettled;
        int256 realisedPnl;
        bool isActive;
        address owner;
        Option[] option;
        Future[] future;
    }

    struct Strategy {
        address owner;
        // usdc 计价的抵押品余额
        uint256 collateralAmount;
        uint256 timestamp;
        int256 realisedPnl;
        // 合并的id：如果为0，表示不合并；有值进行验证并合并
        uint256 mergeId;
        bool isActive;
        Option[] option;
        Future[] future;
    }

    struct DecreaseStrategyCollateralRequest {
        address owner;
        uint256 strategyId;
        uint256 collateralAmount;
    }

    struct MergeStrategyRequest {
        address owner;
        uint256 firstStrategyId;
        uint256 secondStrategyId;
        uint256 collateralAmount;
    }

    struct SpiltStrategyRequest {
        address owner;
        uint256 strategyId;
        uint256[] positionIds;
        uint256 originalCollateralsToTopUpAmount;
        uint256 originalSplitCollateralAmount;
        uint256 newlySplitCollateralAmount;
    }

    struct LiquidateStrategyRequest {
        uint256 strategyId;
        uint256 mergeId;
        uint256 collateralAmount;
        address owner;
        Future[] future;
        Option[] option;
    }

    struct StrategyRequest {
        address owner;
        uint256 collateralAmount;
        uint256 timestamp;
        uint256 mergeId;
        Option[] option;
        Future[] future;
    }

    struct SellStrategyRequest {
        uint256 strategyId;
        uint256 collateralAmount;
        // uint256[] positionIds;
        address receiver;
        address owner;
        Option[] option;
        Future[] future;
    }

    struct ADLStrategyRequest {
        uint256 strategyId;
        uint256 positionId;
    }

    struct Market {
        // Whether or not this market is listed
        bool isListed;
        // 保证金缩水率
        uint256 marginScale;
        // 合约乘数
        // 上限
        // 下限
    }

    ///////////////////
    // Margin Oracle //
    ///////////////////

    struct MarginItemWithId {
        uint256 strategyId;
        uint256 im;
        uint256 mm;
        int256 futureUnrealizedPnl;
        int256 futurePredictUnrealizedPnl;
        int256 optionValue; // 已有期权价值的盈利或亏损
        int256 optionValueToBeTraded; // 新开期权价值的盈利或亏损
        uint256 updateAt;
    }

    struct MarginItemWithHash {
        bytes32 requestHash;
        uint256 im;
        uint256 mm;
        int256 futureUnrealizedPnl;
        int256 futurePredictUnrealizedPnl;
        int256 optionValue; // 已有期权价值的盈利或亏损
        int256 optionValueToBeTraded; // 新开期权价值的盈利或亏损
        uint256 updateAt;
    }

    ///////////////////
    //   Mark Price  //
    ///////////////////

    struct MarkPriceItemWithId {
        uint256 positionId;
        uint256 price;
        uint256 updateAt;
    }
}