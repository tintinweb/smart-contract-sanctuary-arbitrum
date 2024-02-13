// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Originally copied from:
 * https://github.com/OffchainLabs/arbitrum/tree/e3a6307ad8a2dc2cad35728a2a9908cfd8dd8ef9/packages/arb-bridge-peripherals
 *
 * MODIFIED from Offchain Labs' implementation:
 * - Changed solidity version to 0.7.6 ([email protected])
 *
 */

pragma solidity ^0.7.6;

interface ITokenGateway {
    /// @notice event deprecated in favor of DepositInitiated and WithdrawalInitiated
    // event OutboundTransferInitiated(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    /// @notice event deprecated in favor of DepositFinalized and WithdrawalFinalized
    // event InboundTransferFinalized(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable;

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev the L1 and L2 address oracles may not always be in sync.
     * For example, a custom token may have been registered but not deployed or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(address l1ERC20) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Multicall interface
 * @notice Enables calling multiple methods in a single call to the contract
 */
interface IMulticall {
    /**
     * @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
     * @param data The encoded function data for each of the calls to make to this contract
     * @return results The results from each of the calls passed in via data
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

/**
 * @title Curation Interface
 * @dev Interface for the Curation contract (and L2Curation too)
 */
interface ICuration {
    // -- Configuration --

    /**
     * @notice Update the default reserve ratio to `_defaultReserveRatio`
     * @param _defaultReserveRatio Reserve ratio (in PPM)
     */
    function setDefaultReserveRatio(uint32 _defaultReserveRatio) external;

    /**
     * @notice Update the minimum deposit amount needed to intialize a new subgraph
     * @param _minimumCurationDeposit Minimum amount of tokens required deposit
     */
    function setMinimumCurationDeposit(uint256 _minimumCurationDeposit) external;

    /**
     * @notice Set the curation tax percentage to charge when a curator deposits GRT tokens.
     * @param _percentage Curation tax percentage charged when depositing GRT tokens
     */
    function setCurationTaxPercentage(uint32 _percentage) external;

    /**
     * @notice Set the master copy to use as clones for the curation token.
     * @param _curationTokenMaster Address of implementation contract to use for curation tokens
     */
    function setCurationTokenMaster(address _curationTokenMaster) external;

    // -- Curation --

    /**
     * @notice Deposit Graph Tokens in exchange for signal of a SubgraphDeployment curation pool.
     * @param _subgraphDeploymentID Subgraph deployment pool from where to mint signal
     * @param _tokensIn Amount of Graph Tokens to deposit
     * @param _signalOutMin Expected minimum amount of signal to receive
     * @return Amount of signal minted
     * @return Amount of curation tax burned
     */
    function mint(
        bytes32 _subgraphDeploymentID,
        uint256 _tokensIn,
        uint256 _signalOutMin
    ) external returns (uint256, uint256);

    /**
     * @notice Burn _signal from the SubgraphDeployment curation pool
     * @param _subgraphDeploymentID SubgraphDeployment the curator is returning signal
     * @param _signalIn Amount of signal to return
     * @param _tokensOutMin Expected minimum amount of tokens to receive
     * @return Tokens returned
     */
    function burn(
        bytes32 _subgraphDeploymentID,
        uint256 _signalIn,
        uint256 _tokensOutMin
    ) external returns (uint256);

    /**
     * @notice Assign Graph Tokens collected as curation fees to the curation pool reserve.
     * @param _subgraphDeploymentID SubgraphDeployment where funds should be allocated as reserves
     * @param _tokens Amount of Graph Tokens to add to reserves
     */
    function collect(bytes32 _subgraphDeploymentID, uint256 _tokens) external;

    // -- Getters --

    /**
     * @notice Check if any GRT tokens are deposited for a SubgraphDeployment.
     * @param _subgraphDeploymentID SubgraphDeployment to check if curated
     * @return True if curated, false otherwise
     */
    function isCurated(bytes32 _subgraphDeploymentID) external view returns (bool);

    /**
     * @notice Get the amount of signal a curator has in a curation pool.
     * @param _curator Curator owning the signal tokens
     * @param _subgraphDeploymentID Subgraph deployment curation pool
     * @return Amount of signal owned by a curator for the subgraph deployment
     */
    function getCuratorSignal(address _curator, bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    /**
     * @notice Get the amount of signal in a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment curation poool
     * @return Amount of signal minted for the subgraph deployment
     */
    function getCurationPoolSignal(bytes32 _subgraphDeploymentID) external view returns (uint256);

    /**
     * @notice Get the amount of token reserves in a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment curation poool
     * @return Amount of token reserves in the curation pool
     */
    function getCurationPoolTokens(bytes32 _subgraphDeploymentID) external view returns (uint256);

    /**
     * @notice Calculate amount of signal that can be bought with tokens in a curation pool.
     * This function considers and excludes the deposit tax.
     * @param _subgraphDeploymentID Subgraph deployment to mint signal
     * @param _tokensIn Amount of tokens used to mint signal
     * @return Amount of signal that can be bought
     * @return Amount of tokens that will be burned as curation tax
     */
    function tokensToSignal(bytes32 _subgraphDeploymentID, uint256 _tokensIn)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Calculate number of tokens to get when burning signal from a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment to burn signal
     * @param _signalIn Amount of signal to burn
     * @return Amount of tokens to get for the specified amount of signal
     */
    function signalToTokens(bytes32 _subgraphDeploymentID, uint256 _signalIn)
        external
        view
        returns (uint256);

    /**
     * @notice Tax charged when curators deposit funds.
     * Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
     * @return Curation tax percentage expressed in PPM
     */
    function curationTaxPercentage() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

/**
 * @title Interface for GNS
 */
interface IGNS {
    // -- Pool --

    /**
     * @dev The SubgraphData struct holds information about subgraphs
     * and their signal; both nSignal (i.e. name signal at the GNS level)
     * and vSignal (i.e. version signal at the Curation contract level)
     */
    struct SubgraphData {
        uint256 vSignal; // The token of the subgraph-deployment bonding curve
        uint256 nSignal; // The token of the subgraph bonding curve
        mapping(address => uint256) curatorNSignal;
        bytes32 subgraphDeploymentID;
        uint32 __DEPRECATED_reserveRatio; // solhint-disable-line var-name-mixedcase
        bool disabled;
        uint256 withdrawableGRT;
    }

    /**
     * @dev The LegacySubgraphKey struct holds the account and sequence ID
     * used to generate subgraph IDs in legacy subgraphs.
     */
    struct LegacySubgraphKey {
        address account;
        uint256 accountSeqID;
    }

    // -- Configuration --

    /**
     * @notice Approve curation contract to pull funds.
     */
    function approveAll() external;

    /**
     * @notice Set the owner fee percentage. This is used to prevent a subgraph owner to drain all
     * the name curators tokens while upgrading or deprecating and is configurable in parts per million.
     * @param _ownerTaxPercentage Owner tax percentage
     */
    function setOwnerTaxPercentage(uint32 _ownerTaxPercentage) external;

    // -- Publishing --

    /**
     * @notice Allows a graph account to set a default name
     * @param _graphAccount Account that is setting its name
     * @param _nameSystem Name system account already has ownership of a name in
     * @param _nameIdentifier The unique identifier that is used to identify the name in the system
     * @param _name The name being set as default
     */
    function setDefaultName(
        address _graphAccount,
        uint8 _nameSystem,
        bytes32 _nameIdentifier,
        string calldata _name
    ) external;

    /**
     * @notice Allows a subgraph owner to update the metadata of a subgraph they have published
     * @param _subgraphID Subgraph ID
     * @param _subgraphMetadata IPFS hash for the subgraph metadata
     */
    function updateSubgraphMetadata(uint256 _subgraphID, bytes32 _subgraphMetadata) external;

    /**
     * @notice Publish a new subgraph.
     * @param _subgraphDeploymentID Subgraph deployment for the subgraph
     * @param _versionMetadata IPFS hash for the subgraph version metadata
     * @param _subgraphMetadata IPFS hash for the subgraph metadata
     */
    function publishNewSubgraph(
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata,
        bytes32 _subgraphMetadata
    ) external;

    /**
     * @notice Publish a new version of an existing subgraph.
     * @param _subgraphID Subgraph ID
     * @param _subgraphDeploymentID Subgraph deployment ID of the new version
     * @param _versionMetadata IPFS hash for the subgraph version metadata
     */
    function publishNewVersion(
        uint256 _subgraphID,
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata
    ) external;

    /**
     * @notice Deprecate a subgraph. The bonding curve is destroyed, the vSignal is burned, and the GNS
     * contract holds the GRT from burning the vSignal, which all curators can withdraw manually.
     * Can only be done by the subgraph owner.
     * @param _subgraphID Subgraph ID
     */
    function deprecateSubgraph(uint256 _subgraphID) external;

    // -- Curation --

    /**
     * @notice Deposit GRT into a subgraph and mint signal.
     * @param _subgraphID Subgraph ID
     * @param _tokensIn The amount of tokens the nameCurator wants to deposit
     * @param _nSignalOutMin Expected minimum amount of name signal to receive
     */
    function mintSignal(
        uint256 _subgraphID,
        uint256 _tokensIn,
        uint256 _nSignalOutMin
    ) external;

    /**
     * @notice Burn signal for a subgraph and return the GRT.
     * @param _subgraphID Subgraph ID
     * @param _nSignal The amount of nSignal the nameCurator wants to burn
     * @param _tokensOutMin Expected minimum amount of tokens to receive
     */
    function burnSignal(
        uint256 _subgraphID,
        uint256 _nSignal,
        uint256 _tokensOutMin
    ) external;

    /**
     * @notice Move subgraph signal from sender to `_recipient`
     * @param _subgraphID Subgraph ID
     * @param _recipient Address to send the signal to
     * @param _amount The amount of nSignal to transfer
     */
    function transferSignal(
        uint256 _subgraphID,
        address _recipient,
        uint256 _amount
    ) external;

    /**
     * @notice Withdraw tokens from a deprecated subgraph.
     * When the subgraph is deprecated, any curator can call this function and
     * withdraw the GRT they are entitled for its original deposit
     * @param _subgraphID Subgraph ID
     */
    function withdraw(uint256 _subgraphID) external;

    // -- Getters --

    /**
     * @notice Return the owner of a subgraph.
     * @param _tokenID Subgraph ID
     * @return Owner address
     */
    function ownerOf(uint256 _tokenID) external view returns (address);

    /**
     * @notice Return the total signal on the subgraph.
     * @param _subgraphID Subgraph ID
     * @return Total signal on the subgraph
     */
    function subgraphSignal(uint256 _subgraphID) external view returns (uint256);

    /**
     * @notice Return the total tokens on the subgraph at current value.
     * @param _subgraphID Subgraph ID
     * @return Total tokens on the subgraph
     */
    function subgraphTokens(uint256 _subgraphID) external view returns (uint256);

    /**
     * @notice Calculate subgraph signal to be returned for an amount of tokens.
     * @param _subgraphID Subgraph ID
     * @param _tokensIn Tokens being exchanged for subgraph signal
     * @return Amount of subgraph signal and curation tax
     */
    function tokensToNSignal(uint256 _subgraphID, uint256 _tokensIn)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice Calculate tokens returned for an amount of subgraph signal.
     * @param _subgraphID Subgraph ID
     * @param _nSignalIn Subgraph signal being exchanged for tokens
     * @return Amount of tokens returned for an amount of subgraph signal
     */
    function nSignalToTokens(uint256 _subgraphID, uint256 _nSignalIn)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Calculate subgraph signal to be returned for an amount of subgraph deployment signal.
     * @param _subgraphID Subgraph ID
     * @param _vSignalIn Amount of subgraph deployment signal to exchange for subgraph signal
     * @return Amount of subgraph signal that can be bought
     */
    function vSignalToNSignal(uint256 _subgraphID, uint256 _vSignalIn)
        external
        view
        returns (uint256);

    /**
     * @notice Calculate subgraph deployment signal to be returned for an amount of subgraph signal.
     * @param _subgraphID Subgraph ID
     * @param _nSignalIn Subgraph signal being exchanged for subgraph deployment signal
     * @return Amount of subgraph deployment signal that can be returned
     */
    function nSignalToVSignal(uint256 _subgraphID, uint256 _nSignalIn)
        external
        view
        returns (uint256);

    /**
     * @notice Get the amount of subgraph signal a curator has.
     * @param _subgraphID Subgraph ID
     * @param _curator Curator address
     * @return Amount of subgraph signal owned by a curator
     */
    function getCuratorSignal(uint256 _subgraphID, address _curator)
        external
        view
        returns (uint256);

    /**
     * @notice Return whether a subgraph is published.
     * @param _subgraphID Subgraph ID
     * @return Return true if subgraph is currently published
     */
    function isPublished(uint256 _subgraphID) external view returns (bool);

    /**
     * @notice Return whether a subgraph is a legacy subgraph (created before subgraph NFTs).
     * @param _subgraphID Subgraph ID
     * @return Return true if subgraph is a legacy subgraph
     */
    function isLegacySubgraph(uint256 _subgraphID) external view returns (bool);

    /**
     * @notice Returns account and sequence ID for a legacy subgraph (created before subgraph NFTs).
     * @param _subgraphID Subgraph ID
     * @return account Account that created the subgraph (or 0 if it's not a legacy subgraph)
     * @return seqID Sequence number for the subgraph
     */
    function getLegacySubgraphKey(uint256 _subgraphID)
        external
        view
        returns (address account, uint256 seqID);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IEpochManager {
    // -- Configuration --

    function setEpochLength(uint256 _epochLength) external;

    // -- Epochs

    function runEpoch() external;

    // -- Getters --

    function isCurrentEpochRun() external view returns (bool);

    function blockNum() external view returns (uint256);

    function blockHash(uint256 _block) external view returns (bytes32);

    function currentEpoch() external view returns (uint256);

    function currentEpochBlock() external view returns (uint256);

    function currentEpochBlockSinceStart() external view returns (uint256);

    function epochsSince(uint256 _epoch) external view returns (uint256);

    function epochsSinceUpdate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;

interface IController {
    function getGovernor() external view returns (address);

    // -- Registry --

    function setContractProxy(bytes32 _id, address _contractAddress) external;

    function unsetContractProxy(bytes32 _id) external;

    function updateController(bytes32 _id, address _controller) external;

    function getContractProxy(bytes32 _id) external view returns (address);

    // -- Pausing --

    function setPartialPaused(bool _partialPaused) external;

    function setPaused(bool _paused) external;

    function setPauseGuardian(address _newPauseGuardian) external;

    function paused() external view returns (bool);

    function partialPaused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { IController } from "./IController.sol";

/**
 * @title Managed Interface
 * @dev Interface for contracts that can be managed by a controller.
 */
interface IManaged {
    /**
     * @notice Set the controller that manages this contract
     * @dev Only the current controller can set a new controller
     * @param _controller Address of the new controller
     */
    function setController(address _controller) external;

    /**
     * @notice Sync protocol contract addresses from the Controller registry
     * @dev This function will cache all the contracts using the latest addresses.
     * Anyone can call the function whenever a Proxy contract change in the
     * controller to ensure the protocol is using the latest version.
     */
    function syncAllContracts() external;

    /**
     * @notice Get the Controller that manages this contract
     * @return The Controller as an IController interface
     */
    function controller() external view returns (IController);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { IController } from "./IController.sol";

import { ICuration } from "../curation/ICuration.sol";
import { IEpochManager } from "../epochs/IEpochManager.sol";
import { IRewardsManager } from "../rewards/IRewardsManager.sol";
import { IStaking } from "../staking/IStaking.sol";
import { IStakingBase } from "../staking/IStakingBase.sol";
import { IGraphToken } from "../token/IGraphToken.sol";
import { ITokenGateway } from "../arbitrum/ITokenGateway.sol";
import { IGNS } from "../discovery/IGNS.sol";

import { IManaged } from "./IManaged.sol";

/**
 * @title Graph Managed contract
 * @dev The Managed contract provides an interface to interact with the Controller.
 * It also provides local caching for contract addresses. This mechanism relies on calling the
 * public `syncAllContracts()` function whenever a contract changes in the controller.
 *
 * Inspired by Livepeer:
 * https://github.com/livepeer/protocol/blob/streamflow/contracts/Controller.sol
 */
abstract contract Managed is IManaged {
    // -- State --

    /// Controller that manages this contract
    IController public override controller;
    /// @dev Cache for the addresses of the contracts retrieved from the controller
    mapping(bytes32 => address) private _addressCache;
    /// @dev Gap for future storage variables
    uint256[10] private __gap;

    // Immutables
    bytes32 private immutable CURATION = keccak256("Curation");
    bytes32 private immutable EPOCH_MANAGER = keccak256("EpochManager");
    bytes32 private immutable REWARDS_MANAGER = keccak256("RewardsManager");
    bytes32 private immutable STAKING = keccak256("Staking");
    bytes32 private immutable GRAPH_TOKEN = keccak256("GraphToken");
    bytes32 private immutable GRAPH_TOKEN_GATEWAY = keccak256("GraphTokenGateway");
    bytes32 private immutable GNS = keccak256("GNS");

    // -- Events --

    /// Emitted when a contract parameter has been updated
    event ParameterUpdated(string param);
    /// Emitted when the controller address has been set
    event SetController(address controller);

    /// Emitted when contract with `nameHash` is synced to `contractAddress`.
    event ContractSynced(bytes32 indexed nameHash, address contractAddress);

    // -- Modifiers --

    /**
     * @dev Revert if the controller is paused or partially paused
     */
    function _notPartialPaused() internal view {
        require(!controller.paused(), "Paused");
        require(!controller.partialPaused(), "Partial-paused");
    }

    /**
     * @dev Revert if the controller is paused
     */
    function _notPaused() internal view virtual {
        require(!controller.paused(), "Paused");
    }

    /**
     * @dev Revert if the caller is not the governor
     */
    function _onlyGovernor() internal view {
        require(msg.sender == controller.getGovernor(), "Only Controller governor");
    }

    /**
     * @dev Revert if the caller is not the Controller
     */
    function _onlyController() internal view {
        require(msg.sender == address(controller), "Caller must be Controller");
    }

    /**
     * @dev Revert if the controller is paused or partially paused
     */
    modifier notPartialPaused() {
        _notPartialPaused();
        _;
    }

    /**
     * @dev Revert if the controller is paused
     */
    modifier notPaused() {
        _notPaused();
        _;
    }

    /**
     * @dev Revert if the caller is not the Controller
     */
    modifier onlyController() {
        _onlyController();
        _;
    }

    /**
     * @dev Revert if the caller is not the governor
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    // -- Functions --

    /**
     * @dev Initialize a Managed contract
     * @param _controller Address for the Controller that manages this contract
     */
    function _initialize(address _controller) internal {
        _setController(_controller);
    }

    /**
     * @notice Set Controller. Only callable by current controller.
     * @param _controller Controller contract address
     */
    function setController(address _controller) external override onlyController {
        _setController(_controller);
    }

    /**
     * @dev Set controller.
     * @param _controller Controller contract address
     */
    function _setController(address _controller) internal {
        require(_controller != address(0), "Controller must be set");
        controller = IController(_controller);
        emit SetController(_controller);
    }

    /**
     * @dev Return Curation interface
     * @return Curation contract registered with Controller
     */
    function curation() internal view returns (ICuration) {
        return ICuration(_resolveContract(CURATION));
    }

    /**
     * @dev Return EpochManager interface
     * @return Epoch manager contract registered with Controller
     */
    function epochManager() internal view returns (IEpochManager) {
        return IEpochManager(_resolveContract(EPOCH_MANAGER));
    }

    /**
     * @dev Return RewardsManager interface
     * @return Rewards manager contract registered with Controller
     */
    function rewardsManager() internal view returns (IRewardsManager) {
        return IRewardsManager(_resolveContract(REWARDS_MANAGER));
    }

    /**
     * @dev Return Staking interface
     * @return Staking contract registered with Controller
     */
    function staking() internal view returns (IStaking) {
        return IStaking(_resolveContract(STAKING));
    }

    /**
     * @dev Return GraphToken interface
     * @return Graph token contract registered with Controller
     */
    function graphToken() internal view returns (IGraphToken) {
        return IGraphToken(_resolveContract(GRAPH_TOKEN));
    }

    /**
     * @dev Return GraphTokenGateway (L1 or L2) interface
     * @return Graph token gateway contract registered with Controller
     */
    function graphTokenGateway() internal view returns (ITokenGateway) {
        return ITokenGateway(_resolveContract(GRAPH_TOKEN_GATEWAY));
    }

    /**
     * @dev Return GNS (L1 or L2) interface.
     * @return Address of the GNS contract registered with Controller, as an IGNS interface.
     */
    function gns() internal view returns (IGNS) {
        return IGNS(_resolveContract(GNS));
    }

    /**
     * @dev Resolve a contract address from the cache or the Controller if not found.
     * @param _nameHash keccak256 hash of the contract name
     * @return Address of the contract
     */
    function _resolveContract(bytes32 _nameHash) internal view returns (address) {
        address contractAddress = _addressCache[_nameHash];
        if (contractAddress == address(0)) {
            contractAddress = controller.getContractProxy(_nameHash);
        }
        return contractAddress;
    }

    /**
     * @dev Cache a contract address from the Controller registry.
     * @param _nameHash keccak256 hash of the name of the contract to sync into the cache
     */
    function _syncContract(bytes32 _nameHash) internal {
        address contractAddress = controller.getContractProxy(_nameHash);
        if (_addressCache[_nameHash] != contractAddress) {
            _addressCache[_nameHash] = contractAddress;
            emit ContractSynced(_nameHash, contractAddress);
        }
    }

    /**
     * @notice Sync protocol contract addresses from the Controller registry
     * @dev This function will cache all the contracts using the latest addresses
     * Anyone can call the function whenever a Proxy contract change in the
     * controller to ensure the protocol is using the latest version
     */
    function syncAllContracts() external override {
        _syncContract(CURATION);
        _syncContract(EPOCH_MANAGER);
        _syncContract(REWARDS_MANAGER);
        _syncContract(STAKING);
        _syncContract(GRAPH_TOKEN);
        _syncContract(GRAPH_TOKEN_GATEWAY);
        _syncContract(GNS);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IRewardsManager {
    /**
     * @dev Stores accumulated rewards and snapshots related to a particular SubgraphDeployment.
     */
    struct Subgraph {
        uint256 accRewardsForSubgraph;
        uint256 accRewardsForSubgraphSnapshot;
        uint256 accRewardsPerSignalSnapshot;
        uint256 accRewardsPerAllocatedToken;
    }

    // -- Config --

    function setIssuancePerBlock(uint256 _issuancePerBlock) external;

    function setMinimumSubgraphSignal(uint256 _minimumSubgraphSignal) external;

    // -- Denylist --

    function setSubgraphAvailabilityOracle(address _subgraphAvailabilityOracle) external;

    function setDenied(bytes32 _subgraphDeploymentID, bool _deny) external;

    function setDeniedMany(bytes32[] calldata _subgraphDeploymentID, bool[] calldata _deny)
        external;

    function isDenied(bytes32 _subgraphDeploymentID) external view returns (bool);

    // -- Getters --

    function getNewRewardsPerSignal() external view returns (uint256);

    function getAccRewardsPerSignal() external view returns (uint256);

    function getAccRewardsForSubgraph(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    function getAccRewardsPerAllocatedToken(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256, uint256);

    function getRewards(address _allocationID) external view returns (uint256);

    // -- Updates --

    function updateAccRewardsPerSignal() external returns (uint256);

    function takeRewards(address _allocationID) external returns (uint256);

    // -- Hooks --

    function onSubgraphSignalUpdate(bytes32 _subgraphDeploymentID) external returns (uint256);

    function onSubgraphAllocationUpdate(bytes32 _subgraphDeploymentID) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;
pragma abicoder v2;

import { IStakingBase } from "./IStakingBase.sol";
import { IStakingExtension } from "./IStakingExtension.sol";
import { IMulticall } from "../base/IMulticall.sol";
import { IManaged } from "../governance/IManaged.sol";

/**
 * @title Interface for the Staking contract
 * @notice This is the interface that should be used when interacting with the Staking contract.
 * @dev Note that Staking doesn't actually inherit this interface. This is because of
 * the custom setup of the Staking contract where part of the functionality is implemented
 * in a separate contract (StakingExtension) to which calls are delegated through the fallback function.
 */
interface IStaking is IStakingBase, IStakingExtension, IMulticall, IManaged {
    // Nothing to see here
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;
pragma abicoder v2;

import { IStakingData } from "./IStakingData.sol";

/**
 * @title Base interface for the Staking contract.
 * @dev This interface includes only what's implemented in the base Staking contract.
 * It does not include the L1 and L2 specific functionality. It also does not include
 * several functions that are implemented in the StakingExtension contract, and are called
 * via delegatecall through the fallback function. See IStaking.sol for an interface
 * that includes the full functionality.
 */
interface IStakingBase is IStakingData {
    /**
     * @dev Emitted when `indexer` stakes `tokens` amount.
     */
    event StakeDeposited(address indexed indexer, uint256 tokens);

    /**
     * @dev Emitted when `indexer` unstaked and locked `tokens` amount until `until` block.
     */
    event StakeLocked(address indexed indexer, uint256 tokens, uint256 until);

    /**
     * @dev Emitted when `indexer` withdrew `tokens` staked.
     */
    event StakeWithdrawn(address indexed indexer, uint256 tokens);

    /**
     * @dev Emitted when `indexer` allocated `tokens` amount to `subgraphDeploymentID`
     * during `epoch`.
     * `allocationID` indexer derived address used to identify the allocation.
     * `metadata` additional information related to the allocation.
     */
    event AllocationCreated(
        address indexed indexer,
        bytes32 indexed subgraphDeploymentID,
        uint256 epoch,
        uint256 tokens,
        address indexed allocationID,
        bytes32 metadata
    );

    /**
     * @dev Emitted when `indexer` close an allocation in `epoch` for `allocationID`.
     * An amount of `tokens` get unallocated from `subgraphDeploymentID`.
     * This event also emits the POI (proof of indexing) submitted by the indexer.
     * `isPublic` is true if the sender was someone other than the indexer.
     */
    event AllocationClosed(
        address indexed indexer,
        bytes32 indexed subgraphDeploymentID,
        uint256 epoch,
        uint256 tokens,
        address indexed allocationID,
        address sender,
        bytes32 poi,
        bool isPublic
    );

    /**
     * @dev Emitted when `indexer` collects a rebate on `subgraphDeploymentID` for `allocationID`.
     * `epoch` is the protocol epoch the rebate was collected on
     * The rebate is for `tokens` amount which are being provided by `assetHolder`; `queryFees`
     * is the amount up for rebate after `curationFees` are distributed and `protocolTax` is burnt.
     * `queryRebates` is the amount distributed to the `indexer` with `delegationFees` collected
     * and sent to the delegation pool.
     */
    event RebateCollected(
        address assetHolder,
        address indexed indexer,
        bytes32 indexed subgraphDeploymentID,
        address indexed allocationID,
        uint256 epoch,
        uint256 tokens,
        uint256 protocolTax,
        uint256 curationFees,
        uint256 queryFees,
        uint256 queryRebates,
        uint256 delegationRewards
    );

    /**
     * @dev Emitted when `indexer` update the delegation parameters for its delegation pool.
     */
    event DelegationParametersUpdated(
        address indexed indexer,
        uint32 indexingRewardCut,
        uint32 queryFeeCut,
        uint32 __DEPRECATED_cooldownBlocks // solhint-disable-line var-name-mixedcase
    );

    /**
     * @dev Emitted when `indexer` set `operator` access.
     */
    event SetOperator(address indexed indexer, address indexed operator, bool allowed);

    /**
     * @dev Emitted when `indexer` set an address to receive rewards.
     */
    event SetRewardsDestination(address indexed indexer, address indexed destination);

    /**
     * @dev Emitted when `extensionImpl` was set as the address of the StakingExtension contract
     * to which extended functionality is delegated.
     */
    event ExtensionImplementationSet(address indexed extensionImpl);

    /**
     * @dev Possible states an allocation can be.
     * States:
     * - Null = indexer == address(0)
     * - Active = not Null && tokens > 0
     * - Closed = Active && closedAtEpoch != 0
     */
    enum AllocationState {
        Null,
        Active,
        Closed
    }

    /**
     * @notice Initialize this contract.
     * @param _controller Address of the controller that manages this contract
     * @param _minimumIndexerStake Minimum amount of tokens that an indexer must stake
     * @param _thawingPeriod Number of blocks that tokens get locked after unstaking
     * @param _protocolPercentage Percentage of query fees that are burned as protocol fee (in PPM)
     * @param _curationPercentage Percentage of query fees that are given to curators (in PPM)
     * @param _maxAllocationEpochs The maximum number of epochs that an allocation can be active
     * @param _delegationUnbondingPeriod The period in epochs that tokens get locked after undelegating
     * @param _delegationRatio The ratio between an indexer's own stake and the delegation they can use
     * @param _rebatesParameters Alpha and lambda parameters for rebates function
     * @param _extensionImpl Address of the StakingExtension implementation
     */
    function initialize(
        address _controller,
        uint256 _minimumIndexerStake,
        uint32 _thawingPeriod,
        uint32 _protocolPercentage,
        uint32 _curationPercentage,
        uint32 _maxAllocationEpochs,
        uint32 _delegationUnbondingPeriod,
        uint32 _delegationRatio,
        RebatesParameters calldata _rebatesParameters,
        address _extensionImpl
    ) external;

    /**
     * @notice Set the address of the StakingExtension implementation.
     * @dev This function can only be called by the governor.
     * @param _extensionImpl Address of the StakingExtension implementation
     */
    function setExtensionImpl(address _extensionImpl) external;

    /**
     * @notice Set the address of the counterpart (L1 or L2) staking contract.
     * @dev This function can only be called by the governor.
     * @param _counterpart Address of the counterpart staking contract in the other chain, without any aliasing.
     */
    function setCounterpartStakingAddress(address _counterpart) external;

    /**
     * @notice Set the minimum stake needed to be an Indexer
     * @dev This function can only be called by the governor.
     * @param _minimumIndexerStake Minimum amount of tokens that an indexer must stake
     */
    function setMinimumIndexerStake(uint256 _minimumIndexerStake) external;

    /**
     * @notice Set the number of blocks that tokens get locked after unstaking
     * @dev This function can only be called by the governor.
     * @param _thawingPeriod Number of blocks that tokens get locked after unstaking
     */
    function setThawingPeriod(uint32 _thawingPeriod) external;

    /**
     * @notice Set the curation percentage of query fees sent to curators.
     * @dev This function can only be called by the governor.
     * @param _percentage Percentage of query fees sent to curators
     */
    function setCurationPercentage(uint32 _percentage) external;

    /**
     * @notice Set a protocol percentage to burn when collecting query fees.
     * @dev This function can only be called by the governor.
     * @param _percentage Percentage of query fees to burn as protocol fee
     */
    function setProtocolPercentage(uint32 _percentage) external;

    /**
     * @notice Set the max time allowed for indexers to allocate on a subgraph
     * before others are allowed to close the allocation.
     * @dev This function can only be called by the governor.
     * @param _maxAllocationEpochs Allocation duration limit in epochs
     */
    function setMaxAllocationEpochs(uint32 _maxAllocationEpochs) external;

    /**
     * @notice Set the rebate parameters
     * @dev This function can only be called by the governor.
     * @param _alphaNumerator Numerator of `alpha`
     * @param _alphaDenominator Denominator of `alpha`
     * @param _lambdaNumerator Numerator of `lambda`
     * @param _lambdaDenominator Denominator of `lambda`
     */
    function setRebateParameters(
        uint32 _alphaNumerator,
        uint32 _alphaDenominator,
        uint32 _lambdaNumerator,
        uint32 _lambdaDenominator
    ) external;

    /**
     * @notice Authorize or unauthorize an address to be an operator for the caller.
     * @param _operator Address to authorize or unauthorize
     * @param _allowed Whether the operator is authorized or not
     */
    function setOperator(address _operator, bool _allowed) external;

    /**
     * @notice Deposit tokens on the indexer's stake.
     * The amount staked must be over the minimumIndexerStake.
     * @param _tokens Amount of tokens to stake
     */
    function stake(uint256 _tokens) external;

    /**
     * @notice Deposit tokens on the Indexer stake, on behalf of the Indexer.
     * The amount staked must be over the minimumIndexerStake.
     * @param _indexer Address of the indexer
     * @param _tokens Amount of tokens to stake
     */
    function stakeTo(address _indexer, uint256 _tokens) external;

    /**
     * @notice Unstake tokens from the indexer stake, lock them until the thawing period expires.
     * @dev NOTE: The function accepts an amount greater than the currently staked tokens.
     * If that happens, it will try to unstake the max amount of tokens it can.
     * The reason for this behaviour is to avoid time conditions while the transaction
     * is in flight.
     * @param _tokens Amount of tokens to unstake
     */
    function unstake(uint256 _tokens) external;

    /**
     * @notice Withdraw indexer tokens once the thawing period has passed.
     */
    function withdraw() external;

    /**
     * @notice Set the destination where to send rewards for an indexer.
     * @param _destination Rewards destination address. If set to zero, rewards will be restaked
     */
    function setRewardsDestination(address _destination) external;

    /**
     * @notice Set the delegation parameters for the caller.
     * @param _indexingRewardCut Percentage of indexing rewards left for the indexer
     * @param _queryFeeCut Percentage of query fees left for the indexer
     */
    function setDelegationParameters(
        uint32 _indexingRewardCut,
        uint32 _queryFeeCut,
        uint32 // _cooldownBlocks, deprecated
    ) external;

    /**
     * @notice Allocate available tokens to a subgraph deployment.
     * @param _subgraphDeploymentID ID of the SubgraphDeployment where tokens will be allocated
     * @param _tokens Amount of tokens to allocate
     * @param _allocationID The allocation identifier
     * @param _metadata IPFS hash for additional information about the allocation
     * @param _proof A 65-bytes Ethereum signed message of `keccak256(indexerAddress,allocationID)`
     */
    function allocate(
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    /**
     * @notice Allocate available tokens to a subgraph deployment from and indexer's stake.
     * The caller must be the indexer or the indexer's operator.
     * @param _indexer Indexer address to allocate funds from.
     * @param _subgraphDeploymentID ID of the SubgraphDeployment where tokens will be allocated
     * @param _tokens Amount of tokens to allocate
     * @param _allocationID The allocation identifier
     * @param _metadata IPFS hash for additional information about the allocation
     * @param _proof A 65-bytes Ethereum signed message of `keccak256(indexerAddress,allocationID)`
     */
    function allocateFrom(
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    /**
     * @notice Close an allocation and free the staked tokens.
     * To be eligible for rewards a proof of indexing must be presented.
     * Presenting a bad proof is subject to slashable condition.
     * To opt out of rewards set _poi to 0x0
     * @param _allocationID The allocation identifier
     * @param _poi Proof of indexing submitted for the allocated period
     */
    function closeAllocation(address _allocationID, bytes32 _poi) external;

    /**
     * @notice Collect query fees from state channels and assign them to an allocation.
     * Funds received are only accepted from a valid sender.
     * @dev To avoid reverting on the withdrawal from channel flow this function will:
     * 1) Accept calls with zero tokens.
     * 2) Accept calls after an allocation passed the dispute period, in that case, all
     *    the received tokens are burned.
     * @param _tokens Amount of tokens to collect
     * @param _allocationID Allocation where the tokens will be assigned
     */
    function collect(uint256 _tokens, address _allocationID) external;

    /**
     * @notice Return true if operator is allowed for indexer.
     * @param _operator Address of the operator
     * @param _indexer Address of the indexer
     * @return True if operator is allowed for indexer, false otherwise
     */
    function isOperator(address _operator, address _indexer) external view returns (bool);

    /**
     * @notice Getter that returns if an indexer has any stake.
     * @param _indexer Address of the indexer
     * @return True if indexer has staked tokens
     */
    function hasStake(address _indexer) external view returns (bool);

    /**
     * @notice Get the total amount of tokens staked by the indexer.
     * @param _indexer Address of the indexer
     * @return Amount of tokens staked by the indexer
     */
    function getIndexerStakedTokens(address _indexer) external view returns (uint256);

    /**
     * @notice Get the total amount of tokens available to use in allocations.
     * This considers the indexer stake and delegated tokens according to delegation ratio
     * @param _indexer Address of the indexer
     * @return Amount of tokens available to allocate including delegation
     */
    function getIndexerCapacity(address _indexer) external view returns (uint256);

    /**
     * @notice Return the allocation by ID.
     * @param _allocationID Address used as allocation identifier
     * @return Allocation data
     */
    function getAllocation(address _allocationID) external view returns (Allocation memory);

    /**
     * @notice Return the current state of an allocation
     * @param _allocationID Allocation identifier
     * @return AllocationState enum with the state of the allocation
     */
    function getAllocationState(address _allocationID) external view returns (AllocationState);

    /**
     * @notice Return if allocationID is used.
     * @param _allocationID Address used as signer by the indexer for an allocation
     * @return True if allocationID already used
     */
    function isAllocation(address _allocationID) external view returns (bool);

    /**
     * @notice Return the total amount of tokens allocated to subgraph.
     * @param _subgraphDeploymentID Deployment ID for the subgraph
     * @return Total tokens allocated to subgraph
     */
    function getSubgraphAllocatedTokens(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;

/**
 * @title Staking Data interface
 * @dev This interface defines some structures used by the Staking contract.
 */
interface IStakingData {
    /**
     * @dev Allocate GRT tokens for the purpose of serving queries of a subgraph deployment
     * An allocation is created in the allocate() function and closed in closeAllocation()
     */
    struct Allocation {
        address indexer;
        bytes32 subgraphDeploymentID;
        uint256 tokens; // Tokens allocated to a SubgraphDeployment
        uint256 createdAtEpoch; // Epoch when it was created
        uint256 closedAtEpoch; // Epoch when it was closed
        uint256 collectedFees; // Collected fees for the allocation
        uint256 __DEPRECATED_effectiveAllocation; // solhint-disable-line var-name-mixedcase
        uint256 accRewardsPerAllocatedToken; // Snapshot used for reward calc
        uint256 distributedRebates; // Collected rebates that have been rebated
    }

    // -- Delegation Data --

    /**
     * @dev Delegation pool information. One per indexer.
     */
    struct DelegationPool {
        uint32 __DEPRECATED_cooldownBlocks; // solhint-disable-line var-name-mixedcase
        uint32 indexingRewardCut; // in PPM
        uint32 queryFeeCut; // in PPM
        uint256 updatedAtBlock; // Block when the pool was last updated
        uint256 tokens; // Total tokens as pool reserves
        uint256 shares; // Total shares minted in the pool
        mapping(address => Delegation) delegators; // Mapping of delegator => Delegation
    }

    /**
     * @dev Individual delegation data of a delegator in a pool.
     */
    struct Delegation {
        uint256 shares; // Shares owned by a delegator in the pool
        uint256 tokensLocked; // Tokens locked for undelegation
        uint256 tokensLockedUntil; // Epoch when locked tokens can be withdrawn
    }

    /**
     * @dev Rebates parameters. Used to avoid stack too deep errors in Staking initialize function.
     */
    struct RebatesParameters {
        uint32 alphaNumerator;
        uint32 alphaDenominator;
        uint32 lambdaNumerator;
        uint32 lambdaDenominator;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;
pragma abicoder v2;

import { IStakingData } from "./IStakingData.sol";
import { Stakes } from "./libs/Stakes.sol";

/**
 * @title Interface for the StakingExtension contract
 * @dev This interface defines the events and functions implemented
 * in the StakingExtension contract, which is used to extend the functionality
 * of the Staking contract while keeping it within the 24kB mainnet size limit.
 * In particular, this interface includes delegation functions and various storage
 * getters.
 */
interface IStakingExtension is IStakingData {
    /**
     * @dev DelegationPool struct as returned by delegationPools(), since
     * the original DelegationPool in IStakingData.sol contains a nested mapping.
     */
    struct DelegationPoolReturn {
        uint32 __DEPRECATED_cooldownBlocks; // solhint-disable-line var-name-mixedcase
        uint32 indexingRewardCut; // in PPM
        uint32 queryFeeCut; // in PPM
        uint256 updatedAtBlock; // Block when the pool was last updated
        uint256 tokens; // Total tokens as pool reserves
        uint256 shares; // Total shares minted in the pool
    }

    /**
     * @dev Emitted when `delegator` delegated `tokens` to the `indexer`, the delegator
     * gets `shares` for the delegation pool proportionally to the tokens staked.
     */
    event StakeDelegated(
        address indexed indexer,
        address indexed delegator,
        uint256 tokens,
        uint256 shares
    );

    /**
     * @dev Emitted when `delegator` undelegated `tokens` from `indexer`.
     * Tokens get locked for withdrawal after a period of time.
     */
    event StakeDelegatedLocked(
        address indexed indexer,
        address indexed delegator,
        uint256 tokens,
        uint256 shares,
        uint256 until
    );

    /**
     * @dev Emitted when `delegator` withdrew delegated `tokens` from `indexer`.
     */
    event StakeDelegatedWithdrawn(
        address indexed indexer,
        address indexed delegator,
        uint256 tokens
    );

    /**
     * @dev Emitted when `indexer` was slashed for a total of `tokens` amount.
     * Tracks `reward` amount of tokens given to `beneficiary`.
     */
    event StakeSlashed(
        address indexed indexer,
        uint256 tokens,
        uint256 reward,
        address beneficiary
    );

    /**
     * @dev Emitted when `caller` set `slasher` address as `allowed` to slash stakes.
     */
    event SlasherUpdate(address indexed caller, address indexed slasher, bool allowed);

    /**
     * @notice Set the delegation ratio.
     * If set to 10 it means the indexer can use up to 10x the indexer staked amount
     * from their delegated tokens
     * @dev This function is only callable by the governor
     * @param _delegationRatio Delegation capacity multiplier
     */
    function setDelegationRatio(uint32 _delegationRatio) external;

    /**
     * @notice Set the time, in epochs, a Delegator needs to wait to withdraw tokens after undelegating.
     * @dev This function is only callable by the governor
     * @param _delegationUnbondingPeriod Period in epochs to wait for token withdrawals after undelegating
     */
    function setDelegationUnbondingPeriod(uint32 _delegationUnbondingPeriod) external;

    /**
     * @notice Set a delegation tax percentage to burn when delegated funds are deposited.
     * @dev This function is only callable by the governor
     * @param _percentage Percentage of delegated tokens to burn as delegation tax, expressed in parts per million
     */
    function setDelegationTaxPercentage(uint32 _percentage) external;

    /**
     * @notice Set or unset an address as allowed slasher.
     * @dev This function can only be called by the governor.
     * @param _slasher Address of the party allowed to slash indexers
     * @param _allowed True if slasher is allowed
     */
    function setSlasher(address _slasher, bool _allowed) external;

    /**
     * @notice Delegate tokens to an indexer.
     * @param _indexer Address of the indexer to which tokens are delegated
     * @param _tokens Amount of tokens to delegate
     * @return Amount of shares issued from the delegation pool
     */
    function delegate(address _indexer, uint256 _tokens) external returns (uint256);

    /**
     * @notice Undelegate tokens from an indexer. Tokens will be locked for the unbonding period.
     * @param _indexer Address of the indexer to which tokens had been delegated
     * @param _shares Amount of shares to return and undelegate tokens
     * @return Amount of tokens returned for the shares of the delegation pool
     */
    function undelegate(address _indexer, uint256 _shares) external returns (uint256);

    /**
     * @notice Withdraw undelegated tokens once the unbonding period has passed, and optionally
     * re-delegate to a new indexer.
     * @param _indexer Withdraw available tokens delegated to indexer
     * @param _newIndexer Re-delegate to indexer address if non-zero, withdraw if zero address
     */
    function withdrawDelegated(address _indexer, address _newIndexer) external returns (uint256);

    /**
     * @notice Slash the indexer stake. Delegated tokens are not subject to slashing.
     * @dev Can only be called by the slasher role.
     * @param _indexer Address of indexer to slash
     * @param _tokens Amount of tokens to slash from the indexer stake
     * @param _reward Amount of reward tokens to send to a beneficiary
     * @param _beneficiary Address of a beneficiary to receive a reward for the slashing
     */
    function slash(
        address _indexer,
        uint256 _tokens,
        uint256 _reward,
        address _beneficiary
    ) external;

    /**
     * @notice Return the delegation from a delegator to an indexer.
     * @param _indexer Address of the indexer where funds have been delegated
     * @param _delegator Address of the delegator
     * @return Delegation data
     */
    function getDelegation(address _indexer, address _delegator)
        external
        view
        returns (Delegation memory);

    /**
     * @notice Return whether the delegator has delegated to the indexer.
     * @param _indexer Address of the indexer where funds have been delegated
     * @param _delegator Address of the delegator
     * @return True if delegator has tokens delegated to the indexer
     */
    function isDelegator(address _indexer, address _delegator) external view returns (bool);

    /**
     * @notice Returns amount of delegated tokens ready to be withdrawn after unbonding period.
     * @param _delegation Delegation of tokens from delegator to indexer
     * @return Amount of tokens to withdraw
     */
    function getWithdraweableDelegatedTokens(Delegation memory _delegation)
        external
        view
        returns (uint256);

    /**
     * @notice Getter for the delegationRatio, i.e. the delegation capacity multiplier:
     * If delegation ratio is 100, and an Indexer has staked 5 GRT,
     * then they can use up to 500 GRT from the delegated stake
     * @return Delegation ratio
     */
    function delegationRatio() external view returns (uint32);

    /**
     * @notice Getter for delegationUnbondingPeriod:
     * Time in epochs a delegator needs to wait to withdraw delegated stake
     * @return Delegation unbonding period in epochs
     */
    function delegationUnbondingPeriod() external view returns (uint32);

    /**
     * @notice Getter for delegationTaxPercentage:
     * Percentage of tokens to tax a delegation deposit, expressed in parts per million
     * @return Delegation tax percentage in parts per million
     */
    function delegationTaxPercentage() external view returns (uint32);

    /**
     * @notice Getter for delegationPools[_indexer]:
     * gets the delegation pool structure for a particular indexer.
     * @param _indexer Address of the indexer for which to query the delegation pool
     * @return Delegation pool as a DelegationPoolReturn struct
     */
    function delegationPools(address _indexer) external view returns (DelegationPoolReturn memory);

    /**
     * @notice Getter for operatorAuth[_indexer][_maybeOperator]:
     * returns true if the operator is authorized to operate on behalf of the indexer.
     * @param _indexer The indexer address for which to query authorization
     * @param _maybeOperator The address that may or may not be an operator
     * @return True if the operator is authorized to operate on behalf of the indexer
     */
    function operatorAuth(address _indexer, address _maybeOperator) external view returns (bool);

    /**
     * @notice Getter for rewardsDestination[_indexer]:
     * returns the address where the indexer's rewards are sent.
     * @param _indexer The indexer address for which to query the rewards destination
     * @return The address where the indexer's rewards are sent, zero if none is set in which case rewards are re-staked
     */
    function rewardsDestination(address _indexer) external view returns (address);

    /**
     * @notice Getter for subgraphAllocations[_subgraphDeploymentId]:
     * returns the amount of tokens allocated to a subgraph deployment.
     * @param _subgraphDeploymentId The subgraph deployment for which to query the allocations
     * @return The amount of tokens allocated to the subgraph deployment
     */
    function subgraphAllocations(bytes32 _subgraphDeploymentId) external view returns (uint256);

    /**
     * @notice Getter for slashers[_maybeSlasher]:
     * returns true if the address is a slasher, i.e. an entity that can slash indexers
     * @param _maybeSlasher Address for which to check the slasher role
     * @return True if the address is a slasher
     */
    function slashers(address _maybeSlasher) external view returns (bool);

    /**
     * @notice Getter for minimumIndexerStake: the minimum
     * amount of GRT that an indexer needs to stake.
     * @return Minimum indexer stake in GRT
     */
    function minimumIndexerStake() external view returns (uint256);

    /**
     * @notice Getter for thawingPeriod: the time in blocks an
     * indexer needs to wait to unstake tokens.
     * @return Thawing period in blocks
     */
    function thawingPeriod() external view returns (uint32);

    /**
     * @notice Getter for curationPercentage: the percentage of
     * query fees that are distributed to curators.
     * @return Curation percentage in parts per million
     */
    function curationPercentage() external view returns (uint32);

    /**
     * @notice Getter for protocolPercentage: the percentage of
     * query fees that are burned as protocol fees.
     * @return Protocol percentage in parts per million
     */
    function protocolPercentage() external view returns (uint32);

    /**
     * @notice Getter for maxAllocationEpochs: the maximum time in epochs
     * that an allocation can be open before anyone is allowed to close it. This
     * also caps the effective allocation when sending the allocation's query fees
     * to the rebate pool.
     * @return Maximum allocation period in epochs
     */
    function maxAllocationEpochs() external view returns (uint32);

    /**
     * @notice Getter for the numerator of the rebates alpha parameter
     * @return Alpha numerator
     */
    function alphaNumerator() external view returns (uint32);

    /**
     * @notice Getter for the denominator of the rebates alpha parameter
     * @return Alpha denominator
     */
    function alphaDenominator() external view returns (uint32);

    /**
     * @notice Getter for the numerator of the rebates lambda parameter
     * @return Lambda numerator
     */
    function lambdaNumerator() external view returns (uint32);

    /**
     * @notice Getter for the denominator of the rebates lambda parameter
     * @return Lambda denominator
     */
    function lambdaDenominator() external view returns (uint32);

    /**
     * @notice Getter for stakes[_indexer]:
     * gets the stake information for an indexer as a Stakes.Indexer struct.
     * @param _indexer Indexer address for which to query the stake information
     * @return Stake information for the specified indexer, as a Stakes.Indexer struct
     */
    function stakes(address _indexer) external view returns (Stakes.Indexer memory);

    /**
     * @notice Getter for allocations[_allocationID]:
     * gets an allocation's information as an IStakingData.Allocation struct.
     * @param _allocationID Allocation ID for which to query the allocation information
     * @return The specified allocation, as an IStakingData.Allocation struct
     */
    function allocations(address _allocationID)
        external
        view
        returns (IStakingData.Allocation memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title MathUtils Library
 * @notice A collection of functions to perform math operations
 */
library MathUtils {
    using SafeMath for uint256;

    /**
     * @dev Calculates the weighted average of two values pondering each of these
     * values based on configured weights. The contribution of each value N is
     * weightN/(weightA + weightB). The calculation rounds up to ensure the result
     * is always greater than the smallest of the two values.
     * @param valueA The amount for value A
     * @param weightA The weight to use for value A
     * @param valueB The amount for value B
     * @param weightB The weight to use for value B
     */
    function weightedAverageRoundingUp(
        uint256 valueA,
        uint256 weightA,
        uint256 valueB,
        uint256 weightB
    ) internal pure returns (uint256) {
        return
            valueA.mul(weightA).add(valueB.mul(weightB)).add(weightA.add(weightB).sub(1)).div(
                weightA.add(weightB)
            );
    }

    /**
     * @dev Returns the minimum of two numbers.
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    /**
     * @dev Returns the difference between two numbers or zero if negative.
     */
    function diffOrZero(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y) ? x.sub(y) : 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./MathUtils.sol";

/**
 * @title A collection of data structures and functions to manage the Indexer Stake state.
 *        Used for low-level state changes, require() conditions should be evaluated
 *        at the caller function scope.
 */
library Stakes {
    using SafeMath for uint256;
    using Stakes for Stakes.Indexer;

    struct Indexer {
        uint256 tokensStaked; // Tokens on the indexer stake (staked by the indexer)
        uint256 tokensAllocated; // Tokens used in allocations
        uint256 tokensLocked; // Tokens locked for withdrawal subject to thawing period
        uint256 tokensLockedUntil; // Block when locked tokens can be withdrawn
    }

    /**
     * @dev Deposit tokens to the indexer stake.
     * @param stake Stake data
     * @param _tokens Amount of tokens to deposit
     */
    function deposit(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensStaked = stake.tokensStaked.add(_tokens);
    }

    /**
     * @dev Release tokens from the indexer stake.
     * @param stake Stake data
     * @param _tokens Amount of tokens to release
     */
    function release(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensStaked = stake.tokensStaked.sub(_tokens);
    }

    /**
     * @dev Allocate tokens from the main stack to a SubgraphDeployment.
     * @param stake Stake data
     * @param _tokens Amount of tokens to allocate
     */
    function allocate(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensAllocated = stake.tokensAllocated.add(_tokens);
    }

    /**
     * @dev Unallocate tokens from a SubgraphDeployment back to the main stack.
     * @param stake Stake data
     * @param _tokens Amount of tokens to unallocate
     */
    function unallocate(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensAllocated = stake.tokensAllocated.sub(_tokens);
    }

    /**
     * @dev Lock tokens until a thawing period pass.
     * @param stake Stake data
     * @param _tokens Amount of tokens to unstake
     * @param _period Period in blocks that need to pass before withdrawal
     */
    function lockTokens(
        Stakes.Indexer storage stake,
        uint256 _tokens,
        uint256 _period
    ) internal {
        // Take into account period averaging for multiple unstake requests
        uint256 lockingPeriod = _period;
        if (stake.tokensLocked > 0) {
            lockingPeriod = MathUtils.weightedAverageRoundingUp(
                MathUtils.diffOrZero(stake.tokensLockedUntil, block.number), // Remaining thawing period
                stake.tokensLocked, // Weighted by remaining unstaked tokens
                _period, // Thawing period
                _tokens // Weighted by new tokens to unstake
            );
        }

        // Update balances
        stake.tokensLocked = stake.tokensLocked.add(_tokens);
        stake.tokensLockedUntil = block.number.add(lockingPeriod);
    }

    /**
     * @dev Unlock tokens.
     * @param stake Stake data
     * @param _tokens Amount of tokens to unkock
     */
    function unlockTokens(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensLocked = stake.tokensLocked.sub(_tokens);
        if (stake.tokensLocked == 0) {
            stake.tokensLockedUntil = 0;
        }
    }

    /**
     * @dev Take all tokens out from the locked stake for withdrawal.
     * @param stake Stake data
     * @return Amount of tokens being withdrawn
     */
    function withdrawTokens(Stakes.Indexer storage stake) internal returns (uint256) {
        // Calculate tokens that can be released
        uint256 tokensToWithdraw = stake.tokensWithdrawable();

        if (tokensToWithdraw > 0) {
            // Reset locked tokens
            stake.unlockTokens(tokensToWithdraw);

            // Decrease indexer stake
            stake.release(tokensToWithdraw);
        }

        return tokensToWithdraw;
    }

    /**
     * @dev Return the amount of tokens used in allocations and locked for withdrawal.
     * @param stake Stake data
     * @return Token amount
     */
    function tokensUsed(Stakes.Indexer memory stake) internal pure returns (uint256) {
        return stake.tokensAllocated.add(stake.tokensLocked);
    }

    /**
     * @dev Return the amount of tokens staked not considering the ones that are already going
     * through the thawing period or are ready for withdrawal. We call it secure stake because
     * it is not subject to change by a withdraw call from the indexer.
     * @param stake Stake data
     * @return Token amount
     */
    function tokensSecureStake(Stakes.Indexer memory stake) internal pure returns (uint256) {
        return stake.tokensStaked.sub(stake.tokensLocked);
    }

    /**
     * @dev Tokens free balance on the indexer stake that can be used for any purpose.
     * Any token that is allocated cannot be used as well as tokens that are going through the
     * thawing period or are withdrawable
     * Calc: tokensStaked - tokensAllocated - tokensLocked
     * @param stake Stake data
     * @return Token amount
     */
    function tokensAvailable(Stakes.Indexer memory stake) internal pure returns (uint256) {
        return stake.tokensAvailableWithDelegation(0);
    }

    /**
     * @dev Tokens free balance on the indexer stake that can be used for allocations.
     * This function accepts a parameter for extra delegated capacity that takes into
     * account delegated tokens
     * @param stake Stake data
     * @param _delegatedCapacity Amount of tokens used from delegators to calculate availability
     * @return Token amount
     */
    function tokensAvailableWithDelegation(Stakes.Indexer memory stake, uint256 _delegatedCapacity)
        internal
        pure
        returns (uint256)
    {
        uint256 tokensCapacity = stake.tokensStaked.add(_delegatedCapacity);
        uint256 _tokensUsed = stake.tokensUsed();
        // If more tokens are used than the current capacity, the indexer is overallocated.
        // This means the indexer doesn't have available capacity to create new allocations.
        // We can reach this state when the indexer has funds allocated and then any
        // of these conditions happen:
        // - The delegationCapacity ratio is reduced.
        // - The indexer stake is slashed.
        // - A delegator removes enough stake.
        if (_tokensUsed > tokensCapacity) {
            // Indexer stake is over allocated: return 0 to avoid stake to be used until
            // the overallocation is restored by staking more tokens, unallocating tokens
            // or using more delegated funds
            return 0;
        }
        return tokensCapacity.sub(_tokensUsed);
    }

    /**
     * @dev Tokens available for withdrawal after thawing period.
     * @param stake Stake data
     * @return Token amount
     */
    function tokensWithdrawable(Stakes.Indexer memory stake) internal view returns (uint256) {
        // No tokens to withdraw before locking period
        if (stake.tokensLockedUntil == 0 || block.number < stake.tokensLockedUntil) {
            return 0;
        }
        return stake.tokensLocked;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { StakingV4Storage } from "./StakingStorage.sol";
import { IStakingExtension } from "./IStakingExtension.sol";
import { TokenUtils } from "../utils/TokenUtils.sol";
import { IGraphToken } from "../token/IGraphToken.sol";
import { GraphUpgradeable } from "../upgrades/GraphUpgradeable.sol";
import { Stakes } from "./libs/Stakes.sol";
import { IStakingData } from "./IStakingData.sol";
import { MathUtils } from "./libs/MathUtils.sol";

/**
 * @title StakingExtension contract
 * @dev This contract provides the logic to manage delegations and other Staking
 * extension features (e.g. storage getters). It is meant to be called through delegatecall from the
 * Staking contract, and is only kept separate to keep the Staking contract size
 * within limits.
 */
contract StakingExtension is StakingV4Storage, GraphUpgradeable, IStakingExtension {
    using SafeMath for uint256;
    using Stakes for Stakes.Indexer;

    /// @dev 100% in parts per million
    uint32 private constant MAX_PPM = 1000000;
    /// @dev Minimum amount of tokens that can be delegated
    uint256 private constant MINIMUM_DELEGATION = 1e18;

    /**
     * @dev Check if the caller is the slasher.
     */
    modifier onlySlasher() {
        require(__slashers[msg.sender] == true, "!slasher");
        _;
    }

    /**
     * @notice Initialize the StakingExtension contract
     * @dev This function is meant to be delegatecalled from the Staking contract's
     * initialize() function, so it uses the same access control check to ensure it is
     * being called by the Staking implementation as part of the proxy upgrade process.
     * @param _delegationUnbondingPeriod Delegation unbonding period in blocks
     * @param _delegationRatio Delegation capacity multiplier (e.g. 10 means 10x the indexer stake)
     * @param _delegationTaxPercentage Percentage of delegated tokens to burn as delegation tax, expressed in parts per million
     */
    function initialize(
        uint32 _delegationUnbondingPeriod,
        uint32, //_cooldownBlocks, deprecated
        uint32 _delegationRatio,
        uint32 _delegationTaxPercentage
    ) external onlyImpl {
        _setDelegationUnbondingPeriod(_delegationUnbondingPeriod);
        _setDelegationRatio(_delegationRatio);
        _setDelegationTaxPercentage(_delegationTaxPercentage);
    }

    /**
     * @notice Set a delegation tax percentage to burn when delegated funds are deposited.
     * @dev This function is only callable by the governor
     * @param _percentage Percentage of delegated tokens to burn as delegation tax, expressed in parts per million
     */
    function setDelegationTaxPercentage(uint32 _percentage) external override onlyGovernor {
        _setDelegationTaxPercentage(_percentage);
    }

    /**
     * @notice Set the delegation ratio.
     * If set to 10 it means the indexer can use up to 10x the indexer staked amount
     * from their delegated tokens
     * @dev This function is only callable by the governor
     * @param _delegationRatio Delegation capacity multiplier
     */
    function setDelegationRatio(uint32 _delegationRatio) external override onlyGovernor {
        _setDelegationRatio(_delegationRatio);
    }

    /**
     * @notice Set the time, in epochs, a Delegator needs to wait to withdraw tokens after undelegating.
     * @dev This function is only callable by the governor
     * @param _delegationUnbondingPeriod Period in epochs to wait for token withdrawals after undelegating
     */
    function setDelegationUnbondingPeriod(uint32 _delegationUnbondingPeriod)
        external
        override
        onlyGovernor
    {
        _setDelegationUnbondingPeriod(_delegationUnbondingPeriod);
    }

    /**
     * @notice Set or unset an address as allowed slasher.
     * @param _slasher Address of the party allowed to slash indexers
     * @param _allowed True if slasher is allowed
     */
    function setSlasher(address _slasher, bool _allowed) external override onlyGovernor {
        require(_slasher != address(0), "!slasher");
        __slashers[_slasher] = _allowed;
        emit SlasherUpdate(msg.sender, _slasher, _allowed);
    }

    /**
     * @notice Delegate tokens to an indexer.
     * @param _indexer Address of the indexer to which tokens are delegated
     * @param _tokens Amount of tokens to delegate
     * @return Amount of shares issued from the delegation pool
     */
    function delegate(address _indexer, uint256 _tokens)
        external
        override
        notPartialPaused
        returns (uint256)
    {
        address delegator = msg.sender;

        // Transfer tokens to delegate to this contract
        TokenUtils.pullTokens(graphToken(), delegator, _tokens);

        // Update state
        return _delegate(delegator, _indexer, _tokens);
    }

    /**
     * @notice Undelegate tokens from an indexer. Tokens will be locked for the unbonding period.
     * @param _indexer Address of the indexer to which tokens had been delegated
     * @param _shares Amount of shares to return and undelegate tokens
     * @return Amount of tokens returned for the shares of the delegation pool
     */
    function undelegate(address _indexer, uint256 _shares)
        external
        override
        notPartialPaused
        returns (uint256)
    {
        return _undelegate(msg.sender, _indexer, _shares);
    }

    /**
     * @notice Withdraw undelegated tokens once the unbonding period has passed, and optionally
     * re-delegate to a new indexer.
     * @param _indexer Withdraw available tokens delegated to indexer
     * @param _newIndexer Re-delegate to indexer address if non-zero, withdraw if zero address
     */
    function withdrawDelegated(address _indexer, address _newIndexer)
        external
        override
        notPaused
        returns (uint256)
    {
        return _withdrawDelegated(msg.sender, _indexer, _newIndexer);
    }

    /**
     * @notice Slash the indexer stake. Delegated tokens are not subject to slashing.
     * @dev Can only be called by the slasher role.
     * @param _indexer Address of indexer to slash
     * @param _tokens Amount of tokens to slash from the indexer stake
     * @param _reward Amount of reward tokens to send to a beneficiary
     * @param _beneficiary Address of a beneficiary to receive a reward for the slashing
     */
    function slash(
        address _indexer,
        uint256 _tokens,
        uint256 _reward,
        address _beneficiary
    ) external override onlySlasher notPartialPaused {
        Stakes.Indexer storage indexerStake = __stakes[_indexer];

        // Only able to slash a non-zero number of tokens
        require(_tokens > 0, "!tokens");

        // Rewards comes from tokens slashed balance
        require(_tokens >= _reward, "rewards>slash");

        // Cannot slash stake of an indexer without any or enough stake
        require(indexerStake.tokensStaked > 0, "!stake");
        require(_tokens <= indexerStake.tokensStaked, "slash>stake");

        // Validate beneficiary of slashed tokens
        require(_beneficiary != address(0), "!beneficiary");

        // Slashing more tokens than freely available (over allocation condition)
        // Unlock locked tokens to avoid the indexer to withdraw them
        if (_tokens > indexerStake.tokensAvailable() && indexerStake.tokensLocked > 0) {
            uint256 tokensOverAllocated = _tokens.sub(indexerStake.tokensAvailable());
            uint256 tokensToUnlock = MathUtils.min(tokensOverAllocated, indexerStake.tokensLocked);
            indexerStake.unlockTokens(tokensToUnlock);
        }

        // Remove tokens to slash from the stake
        indexerStake.release(_tokens);

        // -- Interactions --

        IGraphToken graphToken = graphToken();

        // Set apart the reward for the beneficiary and burn remaining slashed stake
        TokenUtils.burnTokens(graphToken, _tokens.sub(_reward));

        // Give the beneficiary a reward for slashing
        TokenUtils.pushTokens(graphToken, _beneficiary, _reward);

        emit StakeSlashed(_indexer, _tokens, _reward, _beneficiary);
    }

    /**
     * @notice Return the delegation from a delegator to an indexer.
     * @param _indexer Address of the indexer where funds have been delegated
     * @param _delegator Address of the delegator
     * @return Delegation data
     */
    function getDelegation(address _indexer, address _delegator)
        external
        view
        override
        returns (Delegation memory)
    {
        return __delegationPools[_indexer].delegators[_delegator];
    }

    /**
     * @notice Getter for the delegationRatio, i.e. the delegation capacity multiplier:
     * If delegation ratio is 100, and an Indexer has staked 5 GRT,
     * then they can use up to 500 GRT from the delegated stake
     * @return Delegation ratio
     */
    function delegationRatio() external view override returns (uint32) {
        return __delegationRatio;
    }

    /**
     * @notice Getter for delegationUnbondingPeriod:
     * Time in epochs a delegator needs to wait to withdraw delegated stake
     * @return Delegation unbonding period in epochs
     */
    function delegationUnbondingPeriod() external view override returns (uint32) {
        return __delegationUnbondingPeriod;
    }

    /**
     * @notice Getter for delegationTaxPercentage:
     * Percentage of tokens to tax a delegation deposit, expressed in parts per million
     * @return Delegation tax percentage in parts per million
     */
    function delegationTaxPercentage() external view override returns (uint32) {
        return __delegationTaxPercentage;
    }

    /**
     * @notice Getter for delegationPools[_indexer]:
     * gets the delegation pool structure for a particular indexer.
     * @param _indexer Address of the indexer for which to query the delegation pool
     * @return Delegation pool as a DelegationPoolReturn struct
     */
    function delegationPools(address _indexer)
        external
        view
        override
        returns (DelegationPoolReturn memory)
    {
        DelegationPool storage pool = __delegationPools[_indexer];
        return
            DelegationPoolReturn(
                0, // Blocks to wait before updating parameters (deprecated)
                pool.indexingRewardCut, // in PPM
                pool.queryFeeCut, // in PPM
                pool.updatedAtBlock, // Block when the pool was last updated
                pool.tokens, // Total tokens as pool reserves
                pool.shares // Total shares minted in the pool
            );
    }

    /**
     * @notice Getter for rewardsDestination[_indexer]:
     * returns the address where the indexer's rewards are sent.
     * @param _indexer The indexer address for which to query the rewards destination
     * @return The address where the indexer's rewards are sent, zero if none is set in which case rewards are re-staked
     */
    function rewardsDestination(address _indexer) external view override returns (address) {
        return __rewardsDestination[_indexer];
    }

    /**
     * @notice Getter for operatorAuth[_indexer][_maybeOperator]:
     * returns true if the operator is authorized to operate on behalf of the indexer.
     * @param _indexer The indexer address for which to query authorization
     * @param _maybeOperator The address that may or may not be an operator
     * @return True if the operator is authorized to operate on behalf of the indexer
     */
    function operatorAuth(address _indexer, address _maybeOperator)
        external
        view
        override
        returns (bool)
    {
        return __operatorAuth[_indexer][_maybeOperator];
    }

    /**
     * @notice Getter for subgraphAllocations[_subgraphDeploymentId]:
     * returns the amount of tokens allocated to a subgraph deployment.
     * @param _subgraphDeploymentId The subgraph deployment for which to query the allocations
     * @return The amount of tokens allocated to the subgraph deployment
     */
    function subgraphAllocations(bytes32 _subgraphDeploymentId)
        external
        view
        override
        returns (uint256)
    {
        return __subgraphAllocations[_subgraphDeploymentId];
    }

    /**
     * @notice Getter for slashers[_maybeSlasher]:
     * returns true if the address is a slasher, i.e. an entity that can slash indexers
     * @param _maybeSlasher Address for which to check the slasher role
     * @return True if the address is a slasher
     */
    function slashers(address _maybeSlasher) external view override returns (bool) {
        return __slashers[_maybeSlasher];
    }

    /**
     * @notice Getter for minimumIndexerStake: the minimum
     * amount of GRT that an indexer needs to stake.
     * @return Minimum indexer stake in GRT
     */
    function minimumIndexerStake() external view override returns (uint256) {
        return __minimumIndexerStake;
    }

    /**
     * @notice Getter for thawingPeriod: the time in blocks an
     * indexer needs to wait to unstake tokens.
     * @return Thawing period in blocks
     */
    function thawingPeriod() external view override returns (uint32) {
        return __thawingPeriod;
    }

    /**
     * @notice Getter for curationPercentage: the percentage of
     * query fees that are distributed to curators.
     * @return Curation percentage in parts per million
     */
    function curationPercentage() external view override returns (uint32) {
        return __curationPercentage;
    }

    /**
     * @notice Getter for protocolPercentage: the percentage of
     * query fees that are burned as protocol fees.
     * @return Protocol percentage in parts per million
     */
    function protocolPercentage() external view override returns (uint32) {
        return __protocolPercentage;
    }

    /**
     * @notice Getter for maxAllocationEpochs: the maximum time in epochs
     * that an allocation can be open before anyone is allowed to close it. This
     * also caps the effective allocation when sending the allocation's query fees
     * to the rebate pool.
     * @return Maximum allocation period in epochs
     */
    function maxAllocationEpochs() external view override returns (uint32) {
        return __maxAllocationEpochs;
    }

    /**
     * @notice Getter for the numerator of the rebates alpha parameter
     * @return Alpha numerator
     */
    function alphaNumerator() external view override returns (uint32) {
        return __alphaNumerator;
    }

    /**
     * @notice Getter for the denominator of the rebates alpha parameter
     * @return Alpha denominator
     */
    function alphaDenominator() external view override returns (uint32) {
        return __alphaDenominator;
    }

    /**
     * @notice Getter for the numerator of the rebates lambda parameter
     * @return Lambda numerator
     */
    function lambdaNumerator() external view override returns (uint32) {
        return __lambdaNumerator;
    }

    /**
     * @notice Getter for the denominator of the rebates lambda parameter
     * @return Lambda denominator
     */
    function lambdaDenominator() external view override returns (uint32) {
        return __lambdaDenominator;
    }

    /**
     * @notice Getter for stakes[_indexer]:
     * gets the stake information for an indexer as a Stakes.Indexer struct.
     * @param _indexer Indexer address for which to query the stake information
     * @return Stake information for the specified indexer, as a Stakes.Indexer struct
     */
    function stakes(address _indexer) external view override returns (Stakes.Indexer memory) {
        return __stakes[_indexer];
    }

    /**
     * @notice Getter for allocations[_allocationID]:
     * gets an allocation's information as an IStakingData.Allocation struct.
     * @param _allocationID Allocation ID for which to query the allocation information
     * @return The specified allocation, as an IStakingData.Allocation struct
     */
    function allocations(address _allocationID)
        external
        view
        override
        returns (IStakingData.Allocation memory)
    {
        return __allocations[_allocationID];
    }

    /**
     * @notice Return whether the delegator has delegated to the indexer.
     * @param _indexer Address of the indexer where funds have been delegated
     * @param _delegator Address of the delegator
     * @return True if delegator has tokens delegated to the indexer
     */
    function isDelegator(address _indexer, address _delegator) public view override returns (bool) {
        return __delegationPools[_indexer].delegators[_delegator].shares > 0;
    }

    /**
     * @notice Returns amount of delegated tokens ready to be withdrawn after unbonding period.
     * @param _delegation Delegation of tokens from delegator to indexer
     * @return Amount of tokens to withdraw
     */
    function getWithdraweableDelegatedTokens(Delegation memory _delegation)
        public
        view
        override
        returns (uint256)
    {
        // There must be locked tokens and period passed
        uint256 currentEpoch = epochManager().currentEpoch();
        if (_delegation.tokensLockedUntil > 0 && currentEpoch >= _delegation.tokensLockedUntil) {
            return _delegation.tokensLocked;
        }
        return 0;
    }

    /**
     * @dev Internal: Set a delegation tax percentage to burn when delegated funds are deposited.
     * @param _percentage Percentage of delegated tokens to burn as delegation tax
     */
    function _setDelegationTaxPercentage(uint32 _percentage) private {
        // Must be within 0% to 100% (inclusive)
        require(_percentage <= MAX_PPM, ">percentage");
        __delegationTaxPercentage = _percentage;
        emit ParameterUpdated("delegationTaxPercentage");
    }

    /**
     * @dev Internal: Set the delegation ratio.
     * If set to 10 it means the indexer can use up to 10x the indexer staked amount
     * from their delegated tokens
     * @param _delegationRatio Delegation capacity multiplier
     */
    function _setDelegationRatio(uint32 _delegationRatio) private {
        __delegationRatio = _delegationRatio;
        emit ParameterUpdated("delegationRatio");
    }

    /**
     * @dev Internal: Set the period for undelegation of stake from indexer.
     * @param _delegationUnbondingPeriod Period in epochs to wait for token withdrawals after undelegating
     */
    function _setDelegationUnbondingPeriod(uint32 _delegationUnbondingPeriod) private {
        require(_delegationUnbondingPeriod > 0, "!delegationUnbondingPeriod");
        __delegationUnbondingPeriod = _delegationUnbondingPeriod;
        emit ParameterUpdated("delegationUnbondingPeriod");
    }

    /**
     * @dev Delegate tokens to an indexer.
     * @param _delegator Address of the delegator
     * @param _indexer Address of the indexer to delegate tokens to
     * @param _tokens Amount of tokens to delegate
     * @return Amount of shares issued of the delegation pool
     */
    function _delegate(
        address _delegator,
        address _indexer,
        uint256 _tokens
    ) private returns (uint256) {
        // Only allow delegations over a minimum, to prevent rounding attacks
        require(_tokens >= MINIMUM_DELEGATION, "!minimum-delegation");
        // Only delegate to non-empty address
        require(_indexer != address(0), "!indexer");
        // Only delegate to staked indexer
        require(__stakes[_indexer].tokensStaked > 0, "!stake");

        // Get the delegation pool of the indexer
        DelegationPool storage pool = __delegationPools[_indexer];
        Delegation storage delegation = pool.delegators[_delegator];

        // Collect delegation tax
        uint256 delegationTax = _collectTax(graphToken(), _tokens, __delegationTaxPercentage);
        uint256 delegatedTokens = _tokens.sub(delegationTax);

        // Calculate shares to issue
        uint256 shares = (pool.tokens == 0)
            ? delegatedTokens
            : delegatedTokens.mul(pool.shares).div(pool.tokens);
        require(shares > 0, "!shares");

        // Update the delegation pool
        pool.tokens = pool.tokens.add(delegatedTokens);
        pool.shares = pool.shares.add(shares);

        // Update the individual delegation
        delegation.shares = delegation.shares.add(shares);

        emit StakeDelegated(_indexer, _delegator, delegatedTokens, shares);

        return shares;
    }

    /**
     * @dev Undelegate tokens from an indexer.
     * @param _delegator Address of the delegator
     * @param _indexer Address of the indexer where tokens had been delegated
     * @param _shares Amount of shares to return and undelegate tokens
     * @return Amount of tokens returned for the shares of the delegation pool
     */
    function _undelegate(
        address _delegator,
        address _indexer,
        uint256 _shares
    ) private returns (uint256) {
        // Can only undelegate a non-zero amount of shares
        require(_shares > 0, "!shares");

        // Get the delegation pool of the indexer
        DelegationPool storage pool = __delegationPools[_indexer];
        Delegation storage delegation = pool.delegators[_delegator];

        // Delegator need to have enough shares in the pool to undelegate
        require(delegation.shares >= _shares, "!shares-avail");

        // Withdraw tokens if available
        if (getWithdraweableDelegatedTokens(delegation) > 0) {
            _withdrawDelegated(_delegator, _indexer, address(0));
        }

        uint256 poolTokens = pool.tokens;
        uint256 poolShares = pool.shares;

        // Calculate tokens to get in exchange for the shares
        uint256 tokens = _shares.mul(poolTokens).div(poolShares);

        // Update the delegation pool
        poolTokens = poolTokens.sub(tokens);
        poolShares = poolShares.sub(_shares);
        pool.tokens = poolTokens;
        pool.shares = poolShares;

        // Update the delegation
        delegation.shares = delegation.shares.sub(_shares);
        // Enforce more than the minimum delegation is left,
        // to prevent rounding attacks
        if (delegation.shares > 0) {
            uint256 remainingDelegation = delegation.shares.mul(poolTokens).div(poolShares);
            require(remainingDelegation >= MINIMUM_DELEGATION, "!minimum-delegation");
        }
        delegation.tokensLocked = delegation.tokensLocked.add(tokens);
        delegation.tokensLockedUntil = epochManager().currentEpoch().add(
            __delegationUnbondingPeriod
        );

        emit StakeDelegatedLocked(
            _indexer,
            _delegator,
            tokens,
            _shares,
            delegation.tokensLockedUntil
        );

        return tokens;
    }

    /**
     * @dev Withdraw delegated tokens once the unbonding period has passed.
     * @param _delegator Delegator that is withdrawing tokens
     * @param _indexer Withdraw available tokens delegated to indexer
     * @param _delegateToIndexer Re-delegate to indexer address if non-zero, withdraw if zero address
     * @return Amount of tokens withdrawn or re-delegated
     */
    function _withdrawDelegated(
        address _delegator,
        address _indexer,
        address _delegateToIndexer
    ) private returns (uint256) {
        // Get the delegation pool of the indexer
        DelegationPool storage pool = __delegationPools[_indexer];
        Delegation storage delegation = pool.delegators[_delegator];

        // Validation
        uint256 tokensToWithdraw = getWithdraweableDelegatedTokens(delegation);
        require(tokensToWithdraw > 0, "!tokens");

        // Reset lock
        delegation.tokensLocked = 0;
        delegation.tokensLockedUntil = 0;

        emit StakeDelegatedWithdrawn(_indexer, _delegator, tokensToWithdraw);

        // -- Interactions --

        if (_delegateToIndexer != address(0)) {
            // Re-delegate tokens to a new indexer
            _delegate(_delegator, _delegateToIndexer, tokensToWithdraw);
        } else {
            // Return tokens to the delegator
            TokenUtils.pushTokens(graphToken(), _delegator, tokensToWithdraw);
        }

        return tokensToWithdraw;
    }

    /**
     * @dev Collect tax to burn for an amount of tokens.
     * @param _graphToken Token to burn
     * @param _tokens Total tokens received used to calculate the amount of tax to collect
     * @param _percentage Percentage of tokens to burn as tax
     * @return Amount of tax charged
     */
    function _collectTax(
        IGraphToken _graphToken,
        uint256 _tokens,
        uint256 _percentage
    ) private returns (uint256) {
        uint256 tax = uint256(_percentage).mul(_tokens).div(MAX_PPM);
        TokenUtils.burnTokens(_graphToken, tax); // Burn tax if any
        return tax;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { Managed } from "../governance/Managed.sol";

import { IStakingData } from "./IStakingData.sol";
import { Stakes } from "./libs/Stakes.sol";

/**
 * @title StakingV1Storage
 * @notice This contract holds all the storage variables for the Staking contract, version 1
 * @dev Note that we use a double underscore prefix for variable names; this prefix identifies
 * variables that used to be public but are now internal, getters can be found on StakingExtension.sol.
 */
// solhint-disable-next-line max-states-count
contract StakingV1Storage is Managed {
    // -- Staking --

    /// @dev Minimum amount of tokens an indexer needs to stake
    uint256 internal __minimumIndexerStake;

    /// @dev Time in blocks to unstake
    uint32 internal __thawingPeriod; // in blocks

    /// @dev Percentage of fees going to curators
    /// Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 internal __curationPercentage;

    /// @dev Percentage of fees burned as protocol fee
    /// Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 internal __protocolPercentage;

    /// @dev Period for allocation to be finalized
    uint32 private __DEPRECATED_channelDisputeEpochs; // solhint-disable-line var-name-mixedcase

    /// @dev Maximum allocation time
    uint32 internal __maxAllocationEpochs;

    /// @dev Rebate alpha numerator
    // Originally used for Cobb-Douglas rebates, now used for exponential rebates
    uint32 internal __alphaNumerator;

    /// @dev Rebate alpha denominator
    // Originally used for Cobb-Douglas rebates, now used for exponential rebates
    uint32 internal __alphaDenominator;

    /// @dev Indexer stakes : indexer => Stake
    mapping(address => Stakes.Indexer) internal __stakes;

    /// @dev Allocations : allocationID => Allocation
    mapping(address => IStakingData.Allocation) internal __allocations;

    /// @dev Subgraph Allocations: subgraphDeploymentID => tokens
    mapping(bytes32 => uint256) internal __subgraphAllocations;

    // Rebate pools : epoch => Pool
    mapping(uint256 => uint256) private __DEPRECATED_rebates; // solhint-disable-line var-name-mixedcase

    // -- Slashing --

    /// @dev List of addresses allowed to slash stakes
    mapping(address => bool) internal __slashers;

    // -- Delegation --

    /// @dev Set the delegation capacity multiplier defined by the delegation ratio
    /// If delegation ratio is 100, and an Indexer has staked 5 GRT,
    /// then they can use up to 500 GRT from the delegated stake
    uint32 internal __delegationRatio;

    /// @dev Time in blocks an indexer needs to wait to change delegation parameters (deprecated)
    uint32 internal __DEPRECATED_delegationParametersCooldown; // solhint-disable-line var-name-mixedcase

    /// @dev Time in epochs a delegator needs to wait to withdraw delegated stake
    uint32 internal __delegationUnbondingPeriod; // in epochs

    /// @dev Percentage of tokens to tax a delegation deposit
    /// Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 internal __delegationTaxPercentage;

    /// @dev Delegation pools : indexer => DelegationPool
    mapping(address => IStakingData.DelegationPool) internal __delegationPools;

    // -- Operators --

    /// @dev Operator auth : indexer => operator => is authorized
    mapping(address => mapping(address => bool)) internal __operatorAuth;

    // -- Asset Holders --

    /// @dev DEPRECATED: Allowed AssetHolders: assetHolder => is allowed
    mapping(address => bool) private __DEPRECATED_assetHolders; // solhint-disable-line var-name-mixedcase
}

/**
 * @title StakingV2Storage
 * @notice This contract holds all the storage variables for the Staking contract, version 2
 * @dev Note that we use a double underscore prefix for variable names; this prefix identifies
 * variables that used to be public but are now internal, getters can be found on StakingExtension.sol.
 */
contract StakingV2Storage is StakingV1Storage {
    /// @dev Destination of accrued rewards : beneficiary => rewards destination
    mapping(address => address) internal __rewardsDestination;
}

/**
 * @title StakingV3Storage
 * @notice This contract holds all the storage variables for the base Staking contract, version 3.
 */
contract StakingV3Storage is StakingV2Storage {
    /// @dev Address of the counterpart Staking contract on L1/L2
    address internal counterpartStakingAddress;
    /// @dev Address of the StakingExtension implementation
    address internal extensionImpl;
}

/**
 * @title StakingV4Storage
 * @notice This contract holds all the storage variables for the base Staking contract, version 4.
 * @dev Note that it includes a storage gap - if adding future versions, make sure to move the gap
 * to the new version and reduce the size of the gap accordingly.
 */
contract StakingV4Storage is StakingV3Storage {
    // Additional rebate parameters for exponential rebates
    uint32 internal __lambdaNumerator;
    uint32 internal __lambdaDenominator;

    /// @dev Gap to allow adding variables in future upgrades (since L1Staking and L2Staking can have their own storage as well)
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGraphToken is IERC20 {
    // -- Mint and Burn --

    function burn(uint256 amount) external;

    function burnFrom(address _from, uint256 amount) external;

    function mint(address _to, uint256 _amount) external;

    // -- Mint Admin --

    function addMinter(address _account) external;

    function removeMinter(address _account) external;

    function renounceMinter() external;

    function isMinter(address _account) external view returns (bool);

    // -- Permit --

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    // -- Allowance --

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { IGraphProxy } from "./IGraphProxy.sol";

/**
 * @title Graph Upgradeable
 * @dev This contract is intended to be inherited from upgradeable contracts.
 */
abstract contract GraphUpgradeable {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Check if the caller is the proxy admin.
     */
    modifier onlyProxyAdmin(IGraphProxy _proxy) {
        require(msg.sender == _proxy.admin(), "Caller must be the proxy admin");
        _;
    }

    /**
     * @dev Check if the caller is the implementation.
     */
    modifier onlyImpl() {
        require(msg.sender == _implementation(), "Only implementation");
        _;
    }

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @notice Accept to be an implementation of proxy.
     * @param _proxy Proxy to accept
     */
    function acceptProxy(IGraphProxy _proxy) external onlyProxyAdmin(_proxy) {
        _proxy.acceptUpgrade();
    }

    /**
     * @notice Accept to be an implementation of proxy and then call a function from the new
     * implementation as specified by `_data`, which should be an encoded function call. This is
     * useful to initialize new storage variables in the proxied contract.
     * @param _proxy Proxy to accept
     * @param _data Calldata for the initialization function call (including selector)
     */
    function acceptProxyAndCall(IGraphProxy _proxy, bytes calldata _data)
        external
        onlyProxyAdmin(_proxy)
    {
        _proxy.acceptUpgradeAndCall(_data);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IGraphProxy {
    function admin() external returns (address);

    function setAdmin(address _newAdmin) external;

    function implementation() external returns (address);

    function pendingImplementation() external returns (address);

    function upgradeTo(address _newImplementation) external;

    function acceptUpgrade() external;

    function acceptUpgradeAndCall(bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "../token/IGraphToken.sol";

library TokenUtils {
    /**
     * @dev Pull tokens from an address to this contract.
     * @param _graphToken Token to transfer
     * @param _from Address sending the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pullTokens(
        IGraphToken _graphToken,
        address _from,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(_graphToken.transferFrom(_from, address(this), _amount), "!transfer");
        }
    }

    /**
     * @dev Push tokens from this contract to a receiving address.
     * @param _graphToken Token to transfer
     * @param _to Address receiving the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pushTokens(
        IGraphToken _graphToken,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(_graphToken.transfer(_to, _amount), "!transfer");
        }
    }

    /**
     * @dev Burn tokens held by this contract.
     * @param _graphToken Token to burn
     * @param _amount Amount of tokens to burn
     */
    function burnTokens(IGraphToken _graphToken, uint256 _amount) internal {
        if (_amount > 0) {
            _graphToken.burn(_amount);
        }
    }
}