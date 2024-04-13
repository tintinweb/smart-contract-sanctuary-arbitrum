// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Types} from "./Types.sol";

/**
 * @title Events and errors for HotPotSale.
 */
abstract contract EventsAndErrors {
    /**
     * Emitted when deposited.
     * @param account The account address
     * @param amount The deposit amount
     * @param numTickets The number of tickets
     * @param ticketRange The range of tickets
     */
    event Deposit(address indexed account, uint256 amount, uint64 numTickets, Types.TicketRange ticketRange);

    /**
     * The caller is not user.
     */
    error CallerIsNotUser();

    /**
     * The public sale is not started.
     */
    error PublicSaleNotStarted();

    /**
     * Invalid number of tickets.
     */
    error InvalidTicketNum();

    /**
     * Insufficient value.
     */
    error InsufficientValue();

    /**
     * Insufficient balance.
     */
    error InsufficientBalance();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {EventsAndErrors} from "./EventsAndErrors.sol";
import {Refundable} from "./Refundable.sol";
import {Types} from "./Types.sol";

/**
 * @title HotPot sale contract implementation.
 */
contract HotPotSale is Ownable, Types, Refundable, EventsAndErrors {
    // ticket price in ETH
    uint256 public constant TICKET_PRICE = 0.05 ether;

    // total number of tickets
    uint64 public totalTickets;

    // deposit states
    mapping(address => DepositState) internal _depositStates;

    // phase states
    mapping(PhaseEnum => PhaseState) internal _phaseStates;

    // public sale config
    PublicSaleConfig internal _config;

    /**
     * @notice Check if the caller is contract.
     */
    modifier callerIsUser() {
        if (tx.origin != _msgSender()) revert CallerIsNotUser();

        _;
    }

    /**
     * @notice Constructor.
     * @param config The config of the public sale
     */
    constructor(PublicSaleConfig memory config) {
        _setConfig(config);
    }

    /**
     * @notice Deposit ETH to participate in the public sale.
     * @param numTickets The number of tickets
     */
    function deposit(uint64 numTickets) external payable callerIsUser {
        if (!isPublicSaleStarted()) revert PublicSaleNotStarted();
        if (numTickets == 0) revert InvalidTicketNum();

        _deposit(_msgSender(), numTickets);
    }

    /**
     * @notice Update the public sale config.
     * @param newConfig The new config of the public sale
     */
    function updateConfig(PublicSaleConfig memory newConfig) external onlyOwner {
        _setConfig(newConfig);
    }

    /**
     * @notice Get the deposit state of the given account.
     * @param account The target account
     * @return depositState The deposit state of the target account
     */
    function getDepositState(
        address account
    ) public view returns (DepositState memory) {
        return _depositStates[account];
    }

    /**
     * @notice Get the state of the given phase.
     * @param phase The target phase
     * @return phaseState The state of the target phase
     */
    function getPhaseState(
        PhaseEnum phase
    ) public view returns (PhaseState memory) {
        return _phaseStates[phase];
    }

    /**
     * @notice Get the public sale config.
     * @return config The public sale config
     */
    function getConfig(
    ) public view returns (PublicSaleConfig memory) {
        return _config;
    }

    /**
     * @notice Check if the public sale is started.
     * @return bool True if the public sale is started, false otherwise
     */
    function isPublicSaleStarted() public view returns (bool) {
        return
            _config.phases[0].startTime != 0 &&
            block.timestamp >= _config.phases[0].startTime &&
            _config.phases[2].endTime != 0 &&
            block.timestamp < _config.phases[2].endTime;
    }

    /**
     * @notice Set the public sale config.
     * @param config The config of the public sale
     */
    function _setConfig(PublicSaleConfig memory config) internal {
        _config.phases[0] = config.phases[0];
        _config.phases[1] = config.phases[1];
        _config.phases[2] = config.phases[2];
    }

    /**
     * @notice Handle the deposit.
     * @param account The account address
     * @param numTickets The number of tickets
     */
    function _deposit(address account, uint64 numTickets) internal {
        uint256 depositAmount = TICKET_PRICE * numTickets;
        uint64 effectiveTickets = numTickets * _getBoostMultiplier();
        TicketRange memory ticketRange = TicketRange(totalTickets + 1, totalTickets + effectiveTickets);

        _fundHandler(account, depositAmount);

        _updateDepositState(account, depositAmount, effectiveTickets, ticketRange);
        _advancePhaseState(depositAmount, effectiveTickets);

        totalTickets += effectiveTickets;

        emit Deposit(account, depositAmount, effectiveTickets, ticketRange);
    }

    /**
     * @notice Fund handler.
     * @param account The account address
     * @param amount The amount to be deducted
     */
    function _fundHandler(address account, uint256 amount) internal {
        if (msg.value < amount) revert InsufficientValue();

        if (msg.value > amount) {
            payable(account).transfer(msg.value - amount);
        }
    }

    /**
     * @notice Update the deposit state of the given account.
     * @param account The target account
     * @param amount The deposit amount
     * @param numTickets The number of tickets
     * @param ticketRange The range of tickets
     */
    function _updateDepositState(address account, uint256 amount, uint64 numTickets, TicketRange memory ticketRange) internal {
        DepositState storage state = _depositStates[account];

        state.amount += amount;
        state.numTickets += numTickets;
        state.tickets.push(ticketRange);
    }

    /**
     * @notice Advance the current phase
     * @param amount The increased deposit amount
     * @param numTickets The increased number of tickets
     */
    function _advancePhaseState(uint256 amount, uint64 numTickets) internal {
        PhaseEnum currentPhase = _getCurrentPhase();

        _phaseStates[currentPhase].amount += amount;
        _phaseStates[currentPhase].numTickets += numTickets;
    }

    /**
     * @notice Get the boost multiplier of the current phase.
     * @return multiplier The boost multiplier of the current phase
     */
    function _getBoostMultiplier() internal view returns (uint64) {
        PhaseEnum currentPhase = _getCurrentPhase();
        
        return _config.phases[uint256(currentPhase) - 1].multiplier;
    }

    /**
     * @notice Get the current phase.
     * @return phase The current phase
     */
    function _getCurrentPhase() internal view returns (PhaseEnum phase) {
        if (block.timestamp < _config.phases[0].endTime) return PhaseEnum.ONE;

        if (block.timestamp < _config.phases[1].endTime) return PhaseEnum.TWO;

        return PhaseEnum.THREE;
    }

    /**
     * @notice Override Refundable._beforeRefund().
     */
    function _beforeRefund(address account, uint256 amount) internal virtual override {
        if (amount > _depositStates[account].amount) revert InsufficientBalance();
    }

    /**
     * @notice Withdraw balance.
     * @param token The address of the specified token, 0 for ETH
     * @param to The recipient address
     */
    function withdraw(address token, address to) external onlyOwner {
        if (token == address(0)) {
            uint256 balance = address(this).balance;
            if (balance == 0) revert InsufficientBalance();

            payable(to).transfer(balance);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance == 0) revert InsufficientBalance();

            IERC20(token).transfer(to, balance);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title HotPot refund contract implementation.
 */
contract Refundable is Ownable {
    // refund states
    mapping(address => uint256) internal _refundStates;

    // verification root for refund
    bytes32 internal _refundRoot;

    /**
     * @notice Refund.
     * @param amount The amount to be refunded
     * @param proof The merkle proof
     */
    function refund(uint256 amount, bytes32[] calldata proof) external {
        require(_refundRoot != 0, "refund not enabled");
        require(_refundStates[_msgSender()] == 0, "already refunded");
        require(refundable(_msgSender(), amount, proof), "not refundable");

        _refund(_msgSender(), amount);
    }

    /**
     * @notice Set the refund root.
     * @param refundRoot The refund root
     */
    function setRefundRoot(bytes32 refundRoot) external onlyOwner {
        _refundRoot = refundRoot;
    }

    /**
     * @notice Get the refund state of the given account.
     * @param account The target account
     * @return refundState The refund state of the target account
     */
    function getRefundState(
        address account
    ) public view returns (uint256) {
        return _refundStates[account];
    }

    /**
     * @notice Verify whether the given account is eligible for refund.
     * @param account The target account
     * @param amount The amount to be refunded
     * @param proof The merkle proof
     * @return refundable True if the given account is eligible for refund, false otherwise
     */
    function refundable(
        address account,
        uint256 amount,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                proof,
                _refundRoot,
                keccak256(abi.encodePacked(account, amount))
            );
    }

    /**
     * @notice Refund handler.
     * @param account The target account
     * @param amount The amount to be refunded
     */
    function _refund(address account, uint256 amount) internal {
        _beforeRefund(account, amount);

        _refundStates[_msgSender()] = amount;

        payable(account).transfer(amount);
    }

    /**
     * @notice Refund hook. Expected to be overrided by the derived contracts.
     * @param account The target account
     * @param amount The amount to be refunded
     */
    function _beforeRefund(address account, uint256 amount) internal virtual {

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Type definitions.
 */
abstract contract Types {
    // phase enum
    enum PhaseEnum {
        ZERO,
        ONE,
        TWO,
        THREE
    }

    // phase details
    struct Phase {
        uint64 startTime; // start time
        uint64 endTime; // end time
        uint64 multiplier; // bonus multiplier
        uint256 target; // target amount in ETH
    }

    // config for public sale
    struct PublicSaleConfig {
        Phase[3] phases; // phases
    }

    // deposit state
    struct DepositState {
        uint256 amount; // total ETH amount
        uint256 numTickets; // total number of the tickets
        TicketRange[] tickets; // the range list of the tickets
    }

    // phase state
    struct PhaseState {
        uint256 amount; // total ETH amount deposited in the phase
        uint256 numTickets; // total tickets in the phase
    }
    
    // ticket range
    struct TicketRange {
        uint64 start; // start id from 1
        uint64 end; // end id
    }
}