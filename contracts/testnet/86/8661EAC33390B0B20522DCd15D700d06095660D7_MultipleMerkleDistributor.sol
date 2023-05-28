// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IMultipleMerkleDistributor.sol";

abstract contract $IMultipleMerkleDistributor is IMultipleMerkleDistributor {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IRewardEscrow.sol";

contract $VestingEntries {
    constructor() {}
}

abstract contract $IRewardEscrow is IRewardEscrow {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/MultipleMerkleDistributor.sol";

contract $MultipleMerkleDistributor is MultipleMerkleDistributor {
    constructor(address _owner, address _token) MultipleMerkleDistributor(_owner, _token) {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/utils/Owned.sol";

contract $Owned is Owned {
    constructor(address _owner) Owned(_owner) {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMultipleMerkleDistributor {
    /// @notice data structure for aggregating multiple claims
    struct Claims {
        uint256 index;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
        uint256 epoch;
    }

    /// @notice event is triggered whenever a call to `claim` succeeds
    event Claimed(
        uint256 index,
        address account,
        uint256 amount,
        uint256 epoch
    );

    /// @notice event is triggered whenever a merkle root is set
    event MerkleRootModified(uint256 epoch);

    /// @return token to be distributed
    function token() external view returns (address);

    // @return the merkle root of the merkle tree containing account balances available to claim
    function merkleRoots(uint256) external view returns (bytes32);

    /// @notice determine if indexed claim has been claimed
    /// @param index: used for claim managment
    /// @param epoch: distribution index number
    /// @return true if indexed claim has been claimed
    function isClaimed(uint256 index, uint256 epoch)
        external
        view
        returns (bool);

    /// @notice attempt to claim as `account` and transfer `amount` to `account`
    /// @param index: used for merkle tree managment and verification
    /// @param account: address used for escrow entry
    /// @param amount: token amount to be escrowed
    /// @param merkleProof: off-chain generated proof of merkle tree inclusion
    /// @param epoch: distribution index number
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 epoch
    ) external;

    /// @notice function that aggregates multiple claims
    /// @param claims: array of valid claims
    function claimMultiple(Claims[] calldata claims) external;

    /// @notice modify merkle root for existing distribution epoch
    /// @param merkleRoot: new merkle root
    /// @param epoch: distribution index number
    function setMerkleRootForEpoch(bytes32 merkleRoot, uint256 epoch) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library VestingEntries {
    struct VestingEntry {
        uint64 endTime;
        uint256 escrowAmount;
        uint256 duration;
    }
    struct VestingEntryWithID {
        uint64 endTime;
        uint256 escrowAmount;
        uint256 entryID;
    }
}

interface IRewardEscrow {
    // Views
    function getKwentaAddress() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function numVestingEntries(address account) external view returns (uint256);

    function totalEscrowedAccountBalance(address account)
        external
        view
        returns (uint256);

    function totalVestedAccountBalance(address account)
        external
        view
        returns (uint256);

    function getVestingQuantity(address account, uint256[] calldata entryIDs)
        external
        view
        returns (uint256, uint256);

    function getVestingSchedules(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (VestingEntries.VestingEntryWithID[] memory);

    function getAccountVestingEntryIDs(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (uint256[] memory);

    function getVestingEntryClaimable(address account, uint256 entryID)
        external
        view
        returns (uint256, uint256);

    function getVestingEntry(address account, uint256 entryID)
        external
        view
        returns (
            uint64,
            uint256,
            uint256
        );

    // Mutative functions
    function vest(uint256[] calldata entryIDs) external;

    function createEscrowEntry(
        address beneficiary,
        uint256 deposit,
        uint256 duration
    ) external;

    function appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) external;

    function stakeEscrow(uint256 _amount) external;

    function unstakeEscrow(uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/Owned.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IRewardEscrow.sol";
import "./interfaces/IMultipleMerkleDistributor.sol";

/// @title Kwenta MultipleMerkleDistributor
/// @author JaredBorders and JChiaramonte7
/// @notice Facilitates trading incentives distribution over multiple periods.
contract MultipleMerkleDistributor is IMultipleMerkleDistributor, Owned {
    using SafeERC20 for IERC20;
    /// @inheritdoc IMultipleMerkleDistributor
    address public immutable override token;

    /// @inheritdoc IMultipleMerkleDistributor
    mapping(uint256 => bytes32) public override merkleRoots;

    /// @notice an epoch to packed array of claimed booleans mapping
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMaps;

    /// @notice set addresses ERC20 contract
    /// Establish merkle root for verification
    /// @param _owner: designated owner of this contract
    /// @param _token: address of erc20 token to be distributed
    constructor(address _owner, address _token) Owned(_owner) {
        token = _token;
    }

    /// @inheritdoc IMultipleMerkleDistributor
    function setMerkleRootForEpoch(bytes32 merkleRoot, uint256 epoch)
        external
        override
        onlyOwner
    {
        merkleRoots[epoch] = merkleRoot;
        emit MerkleRootModified(epoch);
    }

    /// @inheritdoc IMultipleMerkleDistributor
    function isClaimed(uint256 index, uint256 epoch)
        public
        view
        override
        returns (bool)
    {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMaps[epoch][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /// @notice set claimed status for indexed claim to true
    /// @param index: used for claim managment
    /// @param epoch: distribution index to check
    function _setClaimed(uint256 index, uint256 epoch) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMaps[epoch][claimedWordIndex] =
            claimedBitMaps[epoch][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /// @inheritdoc IMultipleMerkleDistributor
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 epoch
    ) public override {
        require(
            !isClaimed(index, epoch),
            "MultipleMerkleDistributor: Drop already claimed."
        );

        // verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoots[epoch], node),
            "MultipleMerkleDistributor: Invalid proof."
        );

        // mark it claimed and send the token
        _setClaimed(index, epoch);
        IERC20(token).safeTransfer(account, amount);

        emit Claimed(index, account, amount, epoch);
    }

    /// @inheritdoc IMultipleMerkleDistributor
    function claimMultiple(Claims[] calldata claims) external override {
        uint256 cacheLength = claims.length;
        for (uint256 i = 0; i < cacheLength; ) {
            claim(
                claims[i].index,
                claims[i].account,
                claims[i].amount,
                claims[i].merkleProof,
                claims[i].epoch
            );
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}