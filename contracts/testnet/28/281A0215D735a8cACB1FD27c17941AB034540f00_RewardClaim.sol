//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISignature.sol";

/// Claim isn't valid.
error ClaimNotOngoing();

/// Insufficient privileges. 
error Forbidden();

/// Already Claimed.
error AlreadyClaimed();

/// Invalid Parameters. 
/// @param param The parameter that was invalid.
error BadUserInput(string param);

/// Invalid Address. 
/// @param addr invalid address.
error InvalidAddress(address addr);

/// Value too large. Maximum `maximum` but `attempt` provided.
/// @param attempt balance available.
/// @param maximum maximum value.
error ValueOverflow(uint256 attempt, uint256 maximum);

/// @title Claim Portal for Tales of Elleria.
/// @author Wayne (Ellerian Prince)
/// @notice Uses merkle proofs to set up reward pools for ERC20 tokens for players to claim.
/// * 1. Anyone to deposit the token ERC20 into the contract.
/// * 2. Owner calls SetupReward with the relevant parameters (amount in WEI)
/// * 3. Users can claim through contract or UI in https://app.talesofelleria.com/
/// @dev There is no direct withdraw function if required, set up a new pool and claim from it instead.
contract RewardClaim is ReentrancyGuard, Ownable {
    /// @notice The struct represents a reward pool.
    struct RewardPool {
        /// @dev Merkle root of this pool.
        bytes32 root;
        /// @dev Whether this pool is valid for claims.
        bool isValid;
        /// @dev Address of the reward ERC20 token.
        address rewardErc20Address;
        /// @dev Amount of tokens claimable per address.
        uint256 rewardAmount;
        /// @dev Mapping if an address has claimed.
        mapping (address => bool) isClaimed;
    }

    /// @dev Mapping from ID to its RewardPool.
    mapping(uint256 => RewardPool) private rewards;

    /// @dev Reference to the contract that does signature verifications.
    ISignature private signatureAbi;

    /// @notice Address used to verify signatures.
    address public signerAddr;

    /// @dev Default value of bytes32 for root comparison.
    bytes32 private defaultBytes32;

    /// @dev Initialize signature and signer.
    constructor(address signatureAddress, address signerAddress) {
        signatureAbi = ISignature(signatureAddress);
        signerAddr = signerAddress;
    }

    /// @notice Returns RewardPool for the specified rewardId.
    /// @param rewardId ID of the reward pool.
    /// @return rewardEntry RewardPool per rewardId specified.
    function getRewardPool(uint256 rewardId) external view returns (
        uint256, address, bool
    ) {
        return (
            rewards[rewardId].rewardAmount,
            rewards[rewardId].rewardErc20Address,
            rewards[rewardId].isValid
        );
    }

    /// @dev Verify that the wallet address (leaf) is part of the recipients.
    /// @param rewardId ID of the reward pool.
    /// @param leaf Encoded recipient.
    /// @param proof Merkle proof for the reward pool.
    function verify(uint256 rewardId, bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i += 1) {
        bytes32 proofElement = proof[i];

        if (computedHash <= proofElement) {
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
        } else {
            computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
        }
        }

        return computedHash == rewards[rewardId].root;
    }

    /// @notice Call to claim rewards. Rewards can only be claimed once.
    /// @dev Uses merkle proof to verify eligibility.
    /// @param rewardIds IDs of the reward pool to claim from.
    /// @param signature Signed signature to authenticate the claim.
    /// @param proof Merkle proof for the reward pool.
    function claimReward(
        uint256[] memory rewardIds,
        bytes memory signature,
        bytes32[] memory proof
    ) external nonReentrant {
        // Perform all eligibility checks
        for (uint256 i = 0; i < rewardIds.length; i += 1) {
            uint256 rewardId = rewardIds[i];

            if(!rewards[rewardId].isValid) {
                revert ClaimNotOngoing();
            }

            if (rewards[rewardId].isClaimed[msg.sender]) {
                revert AlreadyClaimed();
            }

            if (
                !verify(rewardId, keccak256(abi.encode(msg.sender)), proof) || 
                !signatureAbi.verify(
                    signerAddr,
                    msg.sender,
                    rewardId,
                    "reward claim",
                    rewards[rewardId].rewardAmount,
                    signature
                )
            ) {
                revert Forbidden();
            }

            rewards[rewardId].isClaimed[msg.sender] = true;
        }
      
        // Transfer reward tokens.
        for (uint256 i = 0; i < rewardIds.length; i += 1) {
            uint256 rewardId = rewardIds[i];

            IERC20(rewards[rewardId].rewardErc20Address).transfer(msg.sender, rewards[rewardId].rewardAmount);
            emit RewardClaimed(
                rewardId,
                msg.sender,
                rewards[rewardId].rewardErc20Address,
                rewards[rewardId].rewardAmount
            );
        }
    }

    /// @notice Called by owner to initialize or update a pool.
    /// @dev rewardAmount is fixed per pool. Create multiple pools for different reward sizes.
    /// @param rewardId ID of the reward pool.
    /// @param root Merkle root of the pool.
    /// @param rewardAmount Reward amount available per user available (WEI).
    /// @param rewardErc20Address ERC20 address for this reward.
    function initRewardPool(
        uint256 rewardId,
        bytes32 root,
        uint256 rewardAmount,
        address rewardErc20Address
    ) external onlyOwner {
        if (rewards[rewardId].root != defaultBytes32) {
            revert Forbidden();
        }

        rewards[rewardId].root = root;
        rewards[rewardId].rewardAmount = rewardAmount;
        rewards[rewardId].rewardErc20Address = rewardErc20Address;
        rewards[rewardId].isValid = true;
    }

    /// @notice Called by owner to disable a pool.
    /// @param rewardId ID of the reward pool.
    function disableReward(uint256 rewardId) external onlyOwner {
        rewards[rewardId].isValid = false;
    }

    /// @notice Event emitted when a reward is claimed.
    /// @param rewardId Reward pool the reward was claimed from.
    /// @param claimedBy Address that claimed the reward.
    /// @param erc20Address Address of the reward token.
    /// @param amountClaimed Amount claimed.
    event RewardClaimed(
        uint256 indexed rewardId,
        address indexed claimedBy,
        address erc20Address,
        uint256 amountClaimed
    );
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

// Interface for the signature verifier.
contract ISignature {
    function verify(address _signer, address _to, uint256 _amount, string memory _message, uint256 _nonce, bytes memory signature) public pure returns (bool) { }
    function bigVerify(address _signer, address _to, uint256[] memory _data, bytes memory signature ) public pure returns (bool) {}
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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