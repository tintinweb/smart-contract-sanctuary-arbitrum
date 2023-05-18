// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Copyright Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.8;

import {IConsensus} from "./IConsensus.sol";

/// @title Abstract Consensus
/// @notice An abstract contract that partially implements `IConsensus`.
abstract contract AbstractConsensus is IConsensus {
    /// @notice Emits an `ApplicationJoined` event with the message sender.
    function join() external override {
        emit ApplicationJoined(msg.sender);
    }
}

// Copyright Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.8;

/// @title Consensus interface
///
/// @notice This contract defines a generic interface for consensuses.
/// We use the word "consensus" to designate a contract that provides claims
/// in the base layer regarding the state of off-chain machines running in
/// the execution layer. How this contract is able to reach consensus, who is
/// able to submit claims, and how are claims stored in the base layer are
/// some of the implementation details left unspecified by this interface.
///
/// From the point of view of a DApp, these claims are necessary to validate
/// on-chain action allowed by the off-chain machine in the form of vouchers
/// and notices. Each claim is composed of three parts: an epoch hash, a first
/// index, and a last index. We'll explain each of these parts below.
///
/// First, let us define the word "epoch". For finality reasons, we need to
/// divide the stream of inputs being fed into the off-chain machine into
/// batches of inputs, which we call "epoches". At the end of every epoch,
/// we summarize the state of the off-chain machine in a single hash, called
/// "epoch hash". Please note that this interface does not define how this
/// stream of inputs is being chopped up into epoches.
///
/// The other two parts are simply the indices of the first and last inputs
/// accepted during the epoch. Logically, the first index MUST BE less than
/// or equal to the last index. As a result, every epoch MUST accept at least
/// one input. This assumption stems from the fact that the state of a machine
/// can only change after an input is fed into it.
///
/// Examples of possible implementations of this interface include:
///
/// * An authority consensus, controlled by a single address who has full
///   control over epoch boundaries, claim submission, asset management, etc.
///
/// * A quorum consensus, controlled by a limited set of validators, that
///   vote on the state of the machine at the end of every epoch. Also, epoch
///   boundaries are determined by the timestamp in the base layer, and assets
///   are split equally amongst the validators.
///
/// * An NxN consensus, which allows anyone to submit and dispute claims
///   in the base layer. Epoch boundaries are determined in the same fashion
///   as in the quorum example.
///
interface IConsensus {
    /// @notice An application has joined the consensus' validation set.
    /// @param application The application
    /// @dev MUST be triggered on a successful call to `join`.
    event ApplicationJoined(address application);

    /// @notice Get a specific claim regarding a specific DApp.
    ///         The encoding of `_proofContext` might vary
    ///         depending on the implementation.
    /// @param _dapp The DApp address
    /// @param _proofContext Data for retrieving the desired claim
    /// @return epochHash_ The claimed epoch hash
    /// @return firstInputIndex_ The index of the first input of the epoch in the input box
    /// @return lastInputIndex_ The index of the last input of the epoch in the input box
    function getClaim(
        address _dapp,
        bytes calldata _proofContext
    )
        external
        view
        returns (
            bytes32 epochHash_,
            uint256 firstInputIndex_,
            uint256 lastInputIndex_
        );

    /// @notice Signal the consensus that the message sender wants to join its validation set.
    /// @dev MUST fire an `ApplicationJoined` event with the message sender as argument.
    function join() external;
}

// Copyright Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.8;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IConsensus} from "../IConsensus.sol";
import {AbstractConsensus} from "../AbstractConsensus.sol";
import {IInputBox} from "../../inputs/IInputBox.sol";
import {IHistory} from "../../history/IHistory.sol";

/// @title Authority consensus
/// @notice A consensus model controlled by a single address, the owner.
///         Claims are stored in an auxiliary contract called `History`.
/// @dev This contract inherits `AbstractConsensus` and OpenZeppelin's `Ownable` contract.
///      For more information on `Ownable`, please consult OpenZeppelin's official documentation.
contract Authority is AbstractConsensus, Ownable {
    /// @notice The current history contract.
    /// @dev See the `getHistory` and `setHistory` functions.
    IHistory internal history;

    /// @notice The `Authority` contract was created.
    /// @param owner The address that initially owns the `Authority` contract
    /// @param inputBox The input box from which the authority fetches new inputs
    /// @dev MUST be triggered during construction.
    event ConsensusCreated(address owner, IInputBox inputBox);

    /// @notice A new history contract is used to store claims.
    /// @param history The new history contract
    /// @dev MUST be triggered on a successful call to `setHistory`.
    event NewHistory(IHistory history);

    /// @notice Constructs an `Authority` contract.
    /// @param _owner The initial contract owner
    /// @param _inputBox The input box contract
    /// @dev Emits a `ConsensusCreated` event.
    constructor(address _owner, IInputBox _inputBox) {
        // constructor in Ownable already called `transferOwnership(msg.sender)`, so
        // we only need to call `transferOwnership(_owner)` if _owner != msg.sender
        if (msg.sender != _owner) {
            transferOwnership(_owner);
        }
        emit ConsensusCreated(_owner, _inputBox);
    }

    /// @notice Submits a claim to the current history contract.
    ///         The encoding of `_claimData` might vary depending on the
    ///         implementation of the current history contract.
    /// @param _claimData Data for submitting a claim
    /// @dev Can only be called by the `Authority` owner,
    ///      and the `Authority` contract must have ownership over
    ///      its current history contract.
    function submitClaim(bytes calldata _claimData) external onlyOwner {
        history.submitClaim(_claimData);
    }

    /// @notice Transfer ownership over the current history contract to `_consensus`.
    /// @param _consensus The new owner of the current history contract
    /// @dev Can only be called by the `Authority` owner,
    ///      and the `Authority` contract must have ownership over
    ///      its current history contract.
    function migrateHistoryToConsensus(address _consensus) external onlyOwner {
        history.migrateToConsensus(_consensus);
    }

    /// @notice Make `Authority` point to another history contract.
    /// @param _history The new history contract
    /// @dev Emits a `NewHistory` event.
    ///      Can only be called by the `Authority` owner.
    function setHistory(IHistory _history) external onlyOwner {
        history = _history;
        emit NewHistory(_history);
    }

    /// @notice Get the current history contract.
    /// @return The current history contract
    function getHistory() external view returns (IHistory) {
        return history;
    }

    /// @notice Get a claim from the current history.
    ///         The encoding of `_proofContext` might vary depending on the
    ///         implementation of the current history contract.
    /// @inheritdoc IConsensus
    function getClaim(
        address _dapp,
        bytes calldata _proofContext
    ) external view override returns (bytes32, uint256, uint256) {
        return history.getClaim(_dapp, _proofContext);
    }

    /// @notice Transfer some amount of ERC-20 tokens to a recipient.
    /// @param _token The token contract
    /// @param _recipient The recipient address
    /// @param _amount The amount of tokens to be withdrawn
    /// @dev Can only be called by the `Authority` owner.
    function withdrawERC20Tokens(
        IERC20 _token,
        address _recipient,
        uint256 _amount
    ) external onlyOwner {
        require(
            _token.transfer(_recipient, _amount),
            "Authority: withdrawal failed"
        );
    }
}

// Copyright Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.8;

/// @title History interface
interface IHistory {
    // Permissioned functions

    /// @notice Submit a claim.
    ///         The encoding of `_claimData` might vary
    ///         depending on the history implementation.
    /// @param _claimData Data for submitting a claim
    /// @dev Should have access control.
    function submitClaim(bytes calldata _claimData) external;

    /// @notice Transfer ownership to another consensus.
    /// @param _consensus The new consensus
    /// @dev Should have access control.
    function migrateToConsensus(address _consensus) external;

    // Permissionless functions

    /// @notice Get a specific claim regarding a specific DApp.
    ///         The encoding of `_proofContext` might vary
    ///         depending on the history implementation.
    /// @param _dapp The DApp address
    /// @param _proofContext Data for retrieving the desired claim
    /// @return epochHash_ The claimed epoch hash
    /// @return firstInputIndex_ The index of the first input of the epoch in the input box
    /// @return lastInputIndex_ The index of the last input of the epoch in the input box
    function getClaim(
        address _dapp,
        bytes calldata _proofContext
    )
        external
        view
        returns (
            bytes32 epochHash_,
            uint256 firstInputIndex_,
            uint256 lastInputIndex_
        );
}

// Copyright Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.8;

/// @title Input Box interface
interface IInputBox {
    /// @notice Emitted when an input is added to a DApp's input box.
    /// @param dapp The address of the DApp
    /// @param inboxInputIndex The index of the input in the input box
    /// @param sender The address that sent the input
    /// @param input The contents of the input
    /// @dev MUST be triggered on a successful call to `addInput`.
    event InputAdded(
        address indexed dapp,
        uint256 indexed inboxInputIndex,
        address sender,
        bytes input
    );

    /// @notice Add an input to a DApp's input box.
    /// @param _dapp The address of the DApp
    /// @param _input The contents of the input
    /// @return The hash of the input plus some extra metadata
    /// @dev MUST fire an `InputAdded` event accordingly.
    function addInput(
        address _dapp,
        bytes calldata _input
    ) external returns (bytes32);

    /// @notice Get the number of inputs in a DApp's input box.
    /// @param _dapp The address of the DApp
    /// @return Number of inputs in the DApp's input box
    function getNumberOfInputs(address _dapp) external view returns (uint256);

    /// @notice Get the hash of an input in a DApp's input box.
    /// @param _dapp The address of the DApp
    /// @param _index The index of the input in the DApp's input box
    /// @return The hash of the input at the provided index in the DApp's input box
    /// @dev `_index` MUST be in the interval `[0,n)` where `n` is the number of
    ///      inputs in the DApp's input box. See the `getNumberOfInputs` function.
    function getInputHash(
        address _dapp,
        uint256 _index
    ) external view returns (bytes32);
}