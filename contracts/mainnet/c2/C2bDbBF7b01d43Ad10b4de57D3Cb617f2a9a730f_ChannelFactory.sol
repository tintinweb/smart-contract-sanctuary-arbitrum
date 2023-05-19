// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/IChannelFactory.sol";
import "./interfaces/IVectorChannel.sol";
import "./lib/LibAsset.sol";
import "./lib/LibERC20.sol";

/// @title ChannelFactory
/// @author Connext <[email protected]>
/// @notice Creates and sets up a new channel proxy contract
contract ChannelFactory is IChannelFactory {
    // Creation code constants taken from EIP1167
    bytes private constant proxyCreationCodePrefix =
        hex"3d602d80600a3d3981f3_363d3d373d3d3d363d73";
    bytes private constant proxyCreationCodeSuffix =
        hex"5af43d82803e903d91602b57fd5bf3";

    bytes32 private creationCodeHash;
    address private immutable mastercopy;
    uint256 private immutable chainId;

    /// @dev Creates a new `ChannelFactory`
    /// @param _mastercopy the address of the `ChannelMastercopy` (channel logic)
    /// @param _chainId the chain identifier when generating the CREATE2 salt. If zero, the chain identifier used in the proxy salt will be the result of the opcode
    constructor(address _mastercopy, uint256 _chainId) {
        mastercopy = _mastercopy;
        chainId = _chainId;
        creationCodeHash = keccak256(_getProxyCreationCode(_mastercopy));
    }

    ////////////////////////////////////////
    // Public Methods

    /// @dev Allows us to get the mastercopy that this factory will deploy channels against
    function getMastercopy() external view override returns (address) {
        return mastercopy;
    }

    /// @dev Allows us to get the chainId that this factory will use in the create2 salt
    function getChainId() public view override returns (uint256 _chainId) {
        // Hold in memory to reduce sload calls
        uint256 chain = chainId;
        if (chain == 0) {
            assembly {
                _chainId := chainid()
            }
        } else {
            _chainId = chain;
        }
    }

    /// @dev Allows us to get the chainId that this factory has stored
    function getStoredChainId() external view override returns (uint256) {
        return chainId;
    }

    /// @dev Returns the proxy code used to both calculate the CREATE2 address and deploy the channel proxy pointed to the `ChannelMastercopy`
    function getProxyCreationCode()
        public
        view
        override
        returns (bytes memory)
    {
        return _getProxyCreationCode(mastercopy);
    }

    /// @dev Allows us to get the address for a new channel contract created via `createChannel`
    /// @param alice address of the igh fidelity channel participant
    /// @param bob address of the other channel participant
    function getChannelAddress(address alice, address bob)
        external
        view
        override
        returns (address)
    {
        return
            Create2.computeAddress(
                generateSalt(alice, bob),
                creationCodeHash
            );
    }

    /// @dev Allows us to create new channel contract and get it all set up in one transaction
    /// @param alice address of the high fidelity channel participant
    /// @param bob address of the other channel participant
    function createChannel(address alice, address bob)
        public
        override
        returns (address channel)
    {
        channel = deployChannelProxy(alice, bob);
        IVectorChannel(channel).setup(alice, bob);
        emit ChannelCreation(channel);
    }

    /// @dev Allows us to create a new channel contract and fund it in one transaction
    /// @param bob address of the other channel participant
    function createChannelAndDepositAlice(
        address alice,
        address bob,
        address assetId,
        uint256 amount
    ) external payable override returns (address channel) {
        channel = createChannel(alice, bob);
        // Deposit funds (if a token) must be approved for the
        // `ChannelFactory`, which then claims the funds and transfers
        // to the channel address. While this is inefficient, this is
        // the safest/clearest way to transfer funds
        if (!LibAsset.isEther(assetId)) {
            require(
                LibERC20.transferFrom(
                    assetId,
                    msg.sender,
                    address(this),
                    amount
                ),
                "ChannelFactory: ERC20_TRANSFER_FAILED"
            );
            require(
                LibERC20.approve(assetId, address(channel), amount),
                "ChannelFactory: ERC20_APPROVE_FAILED"
            );
        }
        IVectorChannel(channel).depositAlice{value: msg.value}(assetId, amount);
    }

    ////////////////////////////////////////
    // Internal Methods

    function _getProxyCreationCode(address _mastercopy) internal pure returns (bytes memory) {
      return abi.encodePacked(
                proxyCreationCodePrefix,
                _mastercopy,
                proxyCreationCodeSuffix
            );
    }

    /// @dev Allows us to create new channel contact using CREATE2
    /// @param alice address of the high fidelity participant in the channel
    /// @param bob address of the other channel participant
    function deployChannelProxy(address alice, address bob)
        internal
        returns (address)
    {
        bytes32 salt = generateSalt(alice, bob);
        return Create2.deploy(0, salt, getProxyCreationCode());
    }

    /// @dev Generates the unique salt for calculating the CREATE2 address of the channel proxy
    function generateSalt(address alice, address bob)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(alice, bob, getChainId()));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint256(_data));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

interface IChannelFactory {
    event ChannelCreation(address channel);

    function getMastercopy() external view returns (address);

    function getChainId() external view returns (uint256);

    function getStoredChainId() external view returns (uint256);

    function getProxyCreationCode() external view returns (bytes memory);

    function getChannelAddress(address alice, address bob)
        external
        view
        returns (address);

    function createChannel(address alice, address bob)
        external
        returns (address);

    function createChannelAndDepositAlice(
        address alice,
        address bob,
        address assetId,
        uint256 amount
    ) external payable returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./ICMCCore.sol";
import "./ICMCAsset.sol";
import "./ICMCDeposit.sol";
import "./ICMCWithdraw.sol";
import "./ICMCAdjudicator.sol";

interface IVectorChannel is
    ICMCCore,
    ICMCAsset,
    ICMCDeposit,
    ICMCWithdraw,
    ICMCAdjudicator
{}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./LibERC20.sol";
import "./LibUtils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/// @title LibAsset
/// @author Connext <[email protected]>
/// @notice This library contains helpers for dealing with onchain transfers
///         of in-channel assets. It is designed to safely handle all asset
///         transfers out of channel in the event of an onchain dispute. Also
///         safely handles ERC20 transfers that may be non-compliant
library LibAsset {
    address constant ETHER_ASSETID = address(0);

    function isEther(address assetId) internal pure returns (bool) {
        return assetId == ETHER_ASSETID;
    }

    function getOwnBalance(address assetId) internal view returns (uint256) {
        return
            isEther(assetId)
                ? address(this).balance
                : IERC20(assetId).balanceOf(address(this));
    }

    function transferEther(address payable recipient, uint256 amount)
        internal
        returns (bool)
    {
        (bool success, bytes memory returnData) =
            recipient.call{value: amount}("");
        LibUtils.revertIfCallFailed(success, returnData);
        return true;
    }

    function transferERC20(
        address assetId,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        return LibERC20.transfer(assetId, recipient, amount);
    }

    // This function is a wrapper for transfers of Ether or ERC20 tokens,
    // both standard-compliant ones as well as tokens that exhibit the
    // missing-return-value bug.
    // Although it behaves very much like Solidity's `transfer` function
    // or the ERC20 `transfer` and is, in fact, designed to replace direct
    // usage of those, it is deliberately named `unregisteredTransfer`,
    // because we need to register every transfer out of the channel.
    // Therefore, it should normally not be used directly, with the single
    // exception of the `transferAsset` function in `CMCAsset.sol`,
    // which combines the "naked" unregistered transfer given below
    // with a registration.
    // USING THIS FUNCTION SOMEWHERE ELSE IS PROBABLY WRONG!
    function unregisteredTransfer(
        address assetId,
        address payable recipient,
        uint256 amount
    ) internal returns (bool) {
        return
            isEther(assetId)
                ? transferEther(recipient, amount)
                : transferERC20(assetId, recipient, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./LibUtils.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title LibERC20
/// @author Connext <[email protected]>
/// @notice This library provides several functions to safely handle
///         noncompliant tokens (i.e. does not return a boolean from
///         the transfer function)

library LibERC20 {
    function wrapCall(address assetId, bytes memory callData)
        internal
        returns (bool)
    {
        require(Address.isContract(assetId), "LibERC20: NO_CODE");
        (bool success, bytes memory returnData) = assetId.call(callData);
        LibUtils.revertIfCallFailed(success, returnData);
        return returnData.length == 0 || abi.decode(returnData, (bool));
    }

    function approve(
        address assetId,
        address spender,
        uint256 amount
    ) internal returns (bool) {
        return
            wrapCall(
                assetId,
                abi.encodeWithSignature(
                    "approve(address,uint256)",
                    spender,
                    amount
                )
            );
    }

    function transferFrom(
        address assetId,
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        return
            wrapCall(
                assetId,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    sender,
                    recipient,
                    amount
                )
            );
    }

    function transfer(
        address assetId,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        return
            wrapCall(
                assetId,
                abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    recipient,
                    amount
                )
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

interface ICMCCore {
    function setup(address _alice, address _bob) external;

    function getAlice() external view returns (address);

    function getBob() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

interface ICMCAsset {
    function getTotalTransferred(address assetId)
        external
        view
        returns (uint256);

    function getExitableAmount(address assetId, address owner)
        external
        view
        returns (uint256);

    function exit(
        address assetId,
        address owner,
        address payable recipient
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

interface ICMCDeposit {
    event AliceDeposited(address assetId, uint256 amount);
    
    function getTotalDepositsAlice(address assetId)
        external
        view
        returns (uint256);

    function getTotalDepositsBob(address assetId)
        external
        view
        returns (uint256);

    function depositAlice(address assetId, uint256 amount) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

struct WithdrawData {
    address channelAddress;
    address assetId;
    address payable recipient;
    uint256 amount;
    uint256 nonce;
    address callTo;
    bytes callData;
}

interface ICMCWithdraw {
    function getWithdrawalTransactionRecord(WithdrawData calldata wd)
        external
        view
        returns (bool);

    function withdraw(
        WithdrawData calldata wd,
        bytes calldata aliceSignature,
        bytes calldata bobSignature
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./Types.sol";

interface ICMCAdjudicator {
    struct CoreChannelState {
        address channelAddress;
        address alice;
        address bob;
        address[] assetIds;
        Balance[] balances;
        uint256[] processedDepositsA;
        uint256[] processedDepositsB;
        uint256[] defundNonces;
        uint256 timeout;
        uint256 nonce;
        bytes32 merkleRoot;
    }

    struct CoreTransferState {
        address channelAddress;
        bytes32 transferId;
        address transferDefinition;
        address initiator;
        address responder;
        address assetId;
        Balance balance;
        uint256 transferTimeout;
        bytes32 initialStateHash;
    }

    struct ChannelDispute {
        bytes32 channelStateHash;
        uint256 nonce;
        bytes32 merkleRoot;
        uint256 consensusExpiry;
        uint256 defundExpiry;
    }

    struct TransferDispute {
        bytes32 transferStateHash;
        uint256 transferDisputeExpiry;
        bool isDefunded;
    }

    event ChannelDisputed(
        address disputer,
        CoreChannelState state,
        ChannelDispute dispute
    );

    event ChannelDefunded(
        address defunder,
        CoreChannelState state,
        ChannelDispute dispute,
        address[] assetIds
    );

    event TransferDisputed(
        address disputer,
        CoreTransferState state,
        TransferDispute dispute
    );

    event TransferDefunded(
        address defunder,
        CoreTransferState state,
        TransferDispute dispute,
        bytes encodedInitialState,
        bytes encodedResolver,
        Balance balance
    );

    function getChannelDispute() external view returns (ChannelDispute memory);

    function getDefundNonce(address assetId) external view returns (uint256);

    function getTransferDispute(bytes32 transferId)
        external
        view
        returns (TransferDispute memory);

    function disputeChannel(
        CoreChannelState calldata ccs,
        bytes calldata aliceSignature,
        bytes calldata bobSignature
    ) external;

    function defundChannel(
        CoreChannelState calldata ccs,
        address[] calldata assetIds,
        uint256[] calldata indices
    ) external;

    function disputeTransfer(
        CoreTransferState calldata cts,
        bytes32[] calldata merkleProofData
    ) external;

    function defundTransfer(
        CoreTransferState calldata cts,
        bytes calldata encodedInitialTransferState,
        bytes calldata encodedTransferResolver,
        bytes calldata responderSignature
    ) external;

    function resetDispute() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

struct Balance {
    uint256[2] amount; // [alice, bob] in channel, [initiator, responder] in transfer
    address payable[2] to; // [alice, bob] in channel, [initiator, responder] in transfer
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/// @title LibUtils
/// @author Connext <[email protected]>
/// @notice Contains a helper to revert if a call was not successfully
///         made
library LibUtils {
    // If success is false, reverts and passes on the revert string.
    function revertIfCallFailed(bool success, bytes memory returnData)
        internal
        pure
    {
        if (!success) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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