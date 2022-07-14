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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "../interfaces/IVectorChannel.sol";
import "../ChannelFactory.sol";

/// @title TestChannelFactory
/// @author Layne Haber <[email protected]>
/// @notice This factory is used for testing *ONLY* and allows you to
///         deploy contracts without setting them up (to run the CMCCore
///         setup tests)
contract TestChannelFactory is ChannelFactory {
    constructor(address _mastercopy, uint256 _chainId)
        ChannelFactory(_mastercopy, _chainId)
    {}

    function deployChannelProxyWithoutSetup(address alice, address bob)
        public
        returns (address)
    {
        return deployChannelProxy(alice, bob);
    }

    function createChannelWithoutSetup(address alice, address bob)
        public
        returns (address channel)
    {
        channel = deployChannelProxy(alice, bob);
        emit ChannelCreation(channel);
        return channel;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IVectorChannel.sol";

contract ReentrantToken is ERC20 {
    address private immutable channel;

    constructor(address _channel) ERC20("Reentrant Token", "BADBOI") {
        channel = _channel;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    // Designed to be called alongside CMCDeposit.depositAlice
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        IVectorChannel(channel).depositAlice(address(this), amount);
        return super.transferFrom(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/* This token is ONLY useful for testing
 * Anybody can mint as many tokens as they like
 * Anybody can burn anyone else's tokens
 */
contract TestToken is ERC20 {
    constructor() ERC20("Test Token", "TEST") {
        _mint(msg.sender, 1000000 ether);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./interfaces/ICMCDeposit.sol";
import "./CMCCore.sol";
import "./CMCAsset.sol";
import "./lib/LibAsset.sol";
import "./lib/LibERC20.sol";

/// @title CMCDeposit
/// @author Connext <[email protected]>
/// @notice Contains logic supporting channel multisig deposits. Channel
///         funding is asymmetric, with `alice` having to call a deposit
///         function which tracks the total amount she has deposited so far,
///         and any other funds in the multisig being attributed to `bob`.

contract CMCDeposit is CMCCore, CMCAsset, ICMCDeposit {
    mapping(address => uint256) private depositsAlice;

    receive() external payable onlyViaProxy nonReentrant {}

    function getTotalDepositsAlice(address assetId)
        external
        view
        override
        onlyViaProxy
        nonReentrantView
        returns (uint256)
    {
        return _getTotalDepositsAlice(assetId);
    }

    function _getTotalDepositsAlice(address assetId)
        internal
        view
        returns (uint256)
    {
        return depositsAlice[assetId];
    }

    function getTotalDepositsBob(address assetId)
        external
        view
        override
        onlyViaProxy
        nonReentrantView
        returns (uint256)
    {
        return _getTotalDepositsBob(assetId);
    }

    // Calculated using invariant onchain properties. Note we DONT use safemath here
    function _getTotalDepositsBob(address assetId)
        internal
        view
        returns (uint256)
    {
        return
            LibAsset.getOwnBalance(assetId) +
            totalTransferred[assetId] -
            depositsAlice[assetId];
    }

    function depositAlice(address assetId, uint256 amount)
        external
        payable
        override
        onlyViaProxy
        nonReentrant
    {
        if (LibAsset.isEther(assetId)) {
            require(msg.value == amount, "CMCDeposit: VALUE_MISMATCH");
        } else {
            // If ETH is sent along, it will be attributed to bob
            require(msg.value == 0, "CMCDeposit: ETH_WITH_ERC_TRANSFER");
            require(
                LibERC20.transferFrom(
                    assetId,
                    msg.sender,
                    address(this),
                    amount
                ),
                "CMCDeposit: ERC20_TRANSFER_FAILED"
            );
        }
        // NOTE: explicitly do NOT use safemath here
        depositsAlice[assetId] += amount;
        emit AliceDeposited(assetId, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./interfaces/ICMCCore.sol";
import "./ReentrancyGuard.sol";

/// @title CMCCore
/// @author Connext <[email protected]>
/// @notice Contains logic pertaining to the participants of a channel,
///         including setting and retrieving the participants and the
///         mastercopy.

contract CMCCore is ReentrancyGuard, ICMCCore {
    address private immutable mastercopyAddress;

    address internal alice;
    address internal bob;

    /// @notice Set invalid participants to block the mastercopy from being used directly
    ///         Nonzero address also prevents the mastercopy from being setup
    ///         Only setting alice is sufficient, setting bob too wouldn't change anything
    constructor() {
        mastercopyAddress = address(this);
    }

    // Prevents us from calling methods directly from the mastercopy contract
    modifier onlyViaProxy {
        require(
            address(this) != mastercopyAddress,
            "Mastercopy: ONLY_VIA_PROXY"
        );
        _;
    }

    /// @notice Contract constructor for Proxied copies
    /// @param _alice: Address representing user with function deposit
    /// @param _bob: Address representing user with multisig deposit
    function setup(address _alice, address _bob)
        external
        override
        onlyViaProxy
    {
        require(alice == address(0), "CMCCore: ALREADY_SETUP");
        require(
            _alice != address(0) && _bob != address(0),
            "CMCCore: INVALID_PARTICIPANT"
        );
        require(_alice != _bob, "CMCCore: IDENTICAL_PARTICIPANTS");
        ReentrancyGuard.setup();
        alice = _alice;
        bob = _bob;
    }

    /// @notice A getter function for the bob of the multisig
    /// @return Bob's signer address
    function getAlice()
        external
        view
        override
        onlyViaProxy
        nonReentrantView
        returns (address)
    {
        return alice;
    }

    /// @notice A getter function for the bob of the multisig
    /// @return Alice's signer address
    function getBob()
        external
        view
        override
        onlyViaProxy
        nonReentrantView
        returns (address)
    {
        return bob;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./interfaces/ICMCAsset.sol";
import "./interfaces/Types.sol";
import "./CMCCore.sol";
import "./lib/LibAsset.sol";
import "./lib/LibMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title CMCAsset
/// @author Connext <[email protected]>
/// @notice Contains logic to safely transfer channel assets (even if they are
///         noncompliant). During adjudication, balances from defunding the
///         channel or defunding transfers are registered as withdrawable. Once
///         they are registered, the owner (or a watchtower on behalf of the
///         owner), may call `exit` to reclaim funds from the multisig.

contract CMCAsset is CMCCore, ICMCAsset {
    using SafeMath for uint256;
    using LibMath for uint256;

    mapping(address => uint256) internal totalTransferred;
    mapping(address => mapping(address => uint256))
        private exitableAmount;

    function registerTransfer(address assetId, uint256 amount) internal {
        totalTransferred[assetId] += amount;
    }

    function getTotalTransferred(address assetId)
        external
        view
        override
        onlyViaProxy
        nonReentrantView
        returns (uint256)
    {
        return totalTransferred[assetId];
    }

    function makeExitable(
        address assetId,
        address recipient,
        uint256 amount
    ) internal {
        exitableAmount[assetId][
            recipient
        ] = exitableAmount[assetId][recipient].satAdd(amount);
    }

    function makeBalanceExitable(
        address assetId,
        Balance memory balance
    ) internal {
        for (uint256 i = 0; i < 2; i++) {
            uint256 amount = balance.amount[i];
            if (amount > 0) {
                makeExitable(assetId, balance.to[i], amount);
            }
        }
    }

    function getExitableAmount(address assetId, address owner)
        external
        view
        override
        onlyViaProxy
        nonReentrantView
        returns (uint256)
    {
        return exitableAmount[assetId][owner];
    }

    function getAvailableAmount(address assetId, uint256 maxAmount)
        internal
        view
        returns (uint256)
    {
        // Taking the min protects against the case where the multisig
        // holds less than the amount that is trying to be withdrawn
        // while still allowing the total of the funds to be removed
        // without the transaction reverting.
        return Math.min(maxAmount, LibAsset.getOwnBalance(assetId));
    }

    function transferAsset(
        address assetId,
        address payable recipient,
        uint256 amount
    ) internal {
        registerTransfer(assetId, amount);
        require(
            LibAsset.unregisteredTransfer(assetId, recipient, amount),
            "CMCAsset: TRANSFER_FAILED"
        );
    }

    function exit(
        address assetId,
        address owner,
        address payable recipient
    ) external override onlyViaProxy nonReentrant {
        // Either the owner must be the recipient, or in control
        // of setting the recipient of the funds to whomever they
        // choose
        require(
            msg.sender == owner || owner == recipient,
            "CMCAsset: OWNER_MISMATCH"
        );

        uint256 amount =
            getAvailableAmount(
                assetId,
                exitableAmount[assetId][owner]
            );

        // Revert if amount is 0
        require(amount > 0, "CMCAsset: NO_OP");

        // Reduce the amount claimable from the multisig by the owner
        exitableAmount[assetId][
            owner
        ] = exitableAmount[assetId][owner].sub(amount);

        // Perform transfer
        transferAsset(assetId, recipient, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/// @title CMCWithdraw
/// @author Connext <[email protected]>
/// @notice A "mutex" reentrancy guard, heavily influenced by OpenZeppelin.

contract ReentrancyGuard {
    uint256 private constant OPEN = 1;
    uint256 private constant LOCKED = 2;

    uint256 public lock;

    function setup() internal {
        lock = OPEN;
    }

    modifier nonReentrant() {
        require(lock == OPEN, "ReentrancyGuard: REENTRANT_CALL");
        lock = LOCKED;
        _;
        lock = OPEN;
    }

    modifier nonReentrantView() {
        require(lock == OPEN, "ReentrancyGuard: REENTRANT_CALL");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/// @title LibMath
/// @author Connext <[email protected]>
/// @notice This library allows functions that would otherwise overflow and
///         revert if SafeMath was used to instead return the UINT_MAX. In the
///         adjudicator, this is used to ensure you can get the majority of
///         funds out in the event your balance > UINT_MAX and there is an
///         onchain dispute.
library LibMath {
    /// @dev Returns the maximum uint256 for an addition that would overflow
    ///      (saturation arithmetic)
    function satAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 sum = x + y;
        return sum >= x ? sum : type(uint256).max;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./interfaces/Commitment.sol";
import "./interfaces/ICMCAdjudicator.sol";
import "./interfaces/ITransferDefinition.sol";
import "./interfaces/Types.sol";
import "./CMCCore.sol";
import "./CMCAsset.sol";
import "./CMCDeposit.sol";
import "./lib/LibChannelCrypto.sol";
import "./lib/LibMath.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title CMCAdjudicator
/// @author Connext <[email protected]>
/// @notice Contains logic for disputing a single channel and all active
///         transfers associated with the channel. Contains two major phases:
///         (1) consensus: settle on latest channel state
///         (2) defund: remove assets and dispute active transfers
contract CMCAdjudicator is CMCCore, CMCAsset, CMCDeposit, ICMCAdjudicator {
    using LibChannelCrypto for bytes32;
    using LibMath for uint256;
    using SafeMath for uint256;

    uint256 private constant INITIAL_DEFUND_NONCE = 1;

    ChannelDispute private channelDispute;
    mapping(address => uint256) private defundNonces;
    mapping(bytes32 => TransferDispute) private transferDisputes;

    modifier validateChannel(CoreChannelState calldata ccs) {
        require(
            ccs.channelAddress == address(this) &&
                ccs.alice == alice &&
                ccs.bob == bob,
            "CMCAdjudicator: INVALID_CHANNEL"
        );
        _;
    }

    modifier validateTransfer(CoreTransferState calldata cts) {
        require(
            cts.channelAddress == address(this),
            "CMCAdjudicator: INVALID_TRANSFER"
        );
        _;
    }

    function getChannelDispute()
        external
        view
        override
        onlyViaProxy
        nonReentrantView
        returns (ChannelDispute memory)
    {
        return channelDispute;
    }

    function getDefundNonce(address assetId)
        external
        view
        override
        onlyViaProxy
        nonReentrantView
        returns (uint256)
    {
        return defundNonces[assetId];
    }

    function getTransferDispute(bytes32 transferId)
        external
        view
        override
        onlyViaProxy
        nonReentrantView
        returns (TransferDispute memory)
    {
        return transferDisputes[transferId];
    }

    function disputeChannel(
        CoreChannelState calldata ccs,
        bytes calldata aliceSignature,
        bytes calldata bobSignature
    ) external override onlyViaProxy nonReentrant validateChannel(ccs) {
        // Generate hash
        bytes32 ccsHash = hashChannelState(ccs);

        // Verify Alice's and Bob's signature on the channel state
        verifySignaturesOnChannelStateHash(ccs, ccsHash, aliceSignature, bobSignature);

        // We cannot dispute a channel in its defund phase
        require(!inDefundPhase(), "CMCAdjudicator: INVALID_PHASE");

        // New nonce must be strictly greater than the stored one
        require(
            channelDispute.nonce < ccs.nonce,
            "CMCAdjudicator: INVALID_NONCE"
        );

        if (!inConsensusPhase()) {
            // We are not already in a dispute
            // Set expiries
            // TODO: offchain-ensure that there can't be an overflow
            channelDispute.consensusExpiry = block.timestamp.add(ccs.timeout);
            channelDispute.defundExpiry = block.timestamp.add(
                ccs.timeout.mul(2)
            );
        }

        // Store newer state
        channelDispute.channelStateHash = ccsHash;
        channelDispute.nonce = ccs.nonce;
        channelDispute.merkleRoot = ccs.merkleRoot;

        // Emit event
        emit ChannelDisputed(msg.sender, ccs, channelDispute);
    }

    function defundChannel(
        CoreChannelState calldata ccs,
        address[] calldata assetIds,
        uint256[] calldata indices
    ) external override onlyViaProxy nonReentrant validateChannel(ccs) {
        // These checks are not strictly necessary, but it's a bit cleaner this way
        require(assetIds.length > 0, "CMCAdjudicator: NO_ASSETS_GIVEN");
        require(
            indices.length <= assetIds.length,
            "CMCAdjudicator: WRONG_ARRAY_LENGTHS"
        );

        // Verify that the given channel state matches the stored one
        require(
            hashChannelState(ccs) == channelDispute.channelStateHash,
            "CMCAdjudicator: INVALID_CHANNEL_HASH"
        );

        // We need to be in defund phase for that
        require(inDefundPhase(), "CMCAdjudicator: INVALID_PHASE");

        // TODO SECURITY: Beware of reentrancy
        // TODO: offchain-ensure that all arrays have the same length:
        // assetIds, balances, processedDepositsA, processedDepositsB, defundNonces
        // Make sure there are no duplicates in the assetIds -- duplicates are often a source of double-spends

        // Defund all assets given
        for (uint256 i = 0; i < assetIds.length; i++) {
            address assetId = assetIds[i];

            // Verify or find the index of the assetId in the ccs.assetIds
            uint256 index;
            if (i < indices.length) {
                // The index was supposedly given -- we verify
                index = indices[i];
                require(
                    assetId == ccs.assetIds[index],
                    "CMCAdjudicator: INDEX_MISMATCH"
                );
            } else {
                // we search through the assets in ccs
                for (index = 0; index < ccs.assetIds.length; index++) {
                    if (assetId == ccs.assetIds[index]) {
                        break;
                    }
                }
            }

            // Now, if `index`  is equal to the number of assets in ccs,
            // then the current asset is not in ccs;
            // otherwise, `index` is the index in ccs for the current asset

            // Check the assets haven't already been defunded + update the
            // defundNonce for that asset
            {
                // Open a new block to avoid "stack too deep" error
                uint256 defundNonce =
                    (index == ccs.assetIds.length)
                        ? INITIAL_DEFUND_NONCE
                        : ccs.defundNonces[index];
                require(
                    defundNonces[assetId] < defundNonce,
                    "CMCAdjudicator: CHANNEL_ALREADY_DEFUNDED"
                );
                defundNonces[assetId] = defundNonce;
            }

            // Get total deposits
            uint256 tdAlice = _getTotalDepositsAlice(assetId);
            uint256 tdBob = _getTotalDepositsBob(assetId);

            Balance memory balance;

            if (index == ccs.assetIds.length) {
                // The current asset is not a part of ccs; refund what has been deposited
                balance = Balance({
                    amount: [tdAlice, tdBob],
                    to: [payable(ccs.alice), payable(ccs.bob)]
                });
            } else {
                // Start with the final balances in ccs
                balance = ccs.balances[index];
                // Add unprocessed deposits
                balance.amount[0] = balance.amount[0].satAdd(
                    tdAlice - ccs.processedDepositsA[index]
                );
                balance.amount[1] = balance.amount[1].satAdd(
                    tdBob - ccs.processedDepositsB[index]
                );
            }

            // Add result to exitable amounts
            makeBalanceExitable(assetId, balance);
        }

        emit ChannelDefunded(
            msg.sender,
            ccs,
            channelDispute,
            assetIds
        );
    }

    function disputeTransfer(
        CoreTransferState calldata cts,
        bytes32[] calldata merkleProofData
    ) external override onlyViaProxy nonReentrant validateTransfer(cts) {
        // Verify that the given transfer state is included in the "finalized" channel state
        bytes32 transferStateHash = hashTransferState(cts);
        verifyMerkleProof(
            merkleProofData,
            channelDispute.merkleRoot,
            transferStateHash
        );

        // The channel needs to be in defund phase for that, i.e. channel state is "finalized"
        require(inDefundPhase(), "CMCAdjudicator: INVALID_PHASE");

        // Get stored dispute for this transfer
        TransferDispute storage transferDispute =
            transferDisputes[cts.transferId];

        // Verify that this transfer has not been disputed before
        require(
            transferDispute.transferDisputeExpiry == 0,
            "CMCAdjudicator: TRANSFER_ALREADY_DISPUTED"
        );

        // Store transfer state and set expiry
        transferDispute.transferStateHash = transferStateHash;
        // TODO: offchain-ensure that there can't be an overflow
        transferDispute.transferDisputeExpiry = block.timestamp.add(
            cts.transferTimeout
        );

        emit TransferDisputed(
            msg.sender,
            cts,
            transferDispute
        );
    }

    function defundTransfer(
        CoreTransferState calldata cts,
        bytes calldata encodedInitialTransferState,
        bytes calldata encodedTransferResolver,
        bytes calldata responderSignature
    ) external override onlyViaProxy nonReentrant validateTransfer(cts) {
        // Get stored dispute for this transfer
        TransferDispute storage transferDispute =
            transferDisputes[cts.transferId];

        // Verify that a dispute for this transfer has already been started
        require(
            transferDispute.transferDisputeExpiry != 0,
            "CMCAdjudicator: TRANSFER_NOT_DISPUTED"
        );

        // Verify that the given transfer state matches the stored one
        require(
            hashTransferState(cts) == transferDispute.transferStateHash,
            "CMCAdjudicator: INVALID_TRANSFER_HASH"
        );

        // We can't defund twice
        require(
            !transferDispute.isDefunded,
            "CMCAdjudicator: TRANSFER_ALREADY_DEFUNDED"
        );
        transferDispute.isDefunded = true;

        Balance memory balance;

        if (block.timestamp < transferDispute.transferDisputeExpiry) {
            // Ensure the correct hash is provided
            require(
                keccak256(encodedInitialTransferState) == cts.initialStateHash,
                "CMCAdjudicator: INVALID_TRANSFER_HASH"
            );
            
            // Before dispute expiry, responder or responder-authorized
            // agent (i.e. watchtower) can resolve
            require(
                msg.sender == cts.responder || cts.initialStateHash.checkSignature(responderSignature, cts.responder),
                "CMCAdjudicator: INVALID_RESOLVER"
            );
            
            ITransferDefinition transferDefinition =
                ITransferDefinition(cts.transferDefinition);
            balance = transferDefinition.resolve(
                abi.encode(cts.balance),
                encodedInitialTransferState,
                encodedTransferResolver
            );
            // Verify that returned balances don't exceed initial balances
            require(
                balance.amount[0].add(balance.amount[1]) <=
                    cts.balance.amount[0].add(cts.balance.amount[1]),
                "CMCAdjudicator: INVALID_BALANCES"
            );
        } else {
            // After dispute expiry, if the responder hasn't resolved, we defund the initial balance
            balance = cts.balance;
        }

        // Depending on previous code path, defund either resolved or initial balance
        makeBalanceExitable(cts.assetId, balance);

        // Emit event
        emit TransferDefunded(
            msg.sender,
            cts,
            transferDispute,
            encodedInitialTransferState,
            encodedTransferResolver,
            balance
        );
    }

    function verifySignaturesOnChannelStateHash(
        CoreChannelState calldata ccs,
        bytes32 ccsHash,
        bytes calldata aliceSignature,
        bytes calldata bobSignature
    ) internal pure {
        bytes32 commitment =
            keccak256(abi.encode(CommitmentType.ChannelState, ccsHash));
        require(
            commitment.checkSignature(aliceSignature, ccs.alice),
            "CMCAdjudicator: INVALID_ALICE_SIG"
        );
        require(
            commitment.checkSignature(bobSignature, ccs.bob),
            "CMCAdjudicator: INVALID_BOB_SIG"
        );
    }

    function verifyMerkleProof(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure {
        require(
            MerkleProof.verify(proof, root, leaf),
            "CMCAdjudicator: INVALID_MERKLE_PROOF"
        );
    }

    function inConsensusPhase() internal view returns (bool) {
        return block.timestamp < channelDispute.consensusExpiry;
    }

    function inDefundPhase() internal view returns (bool) {
        return
            channelDispute.consensusExpiry <= block.timestamp &&
            block.timestamp < channelDispute.defundExpiry;
    }

    function hashChannelState(CoreChannelState calldata ccs)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(ccs));
    }

    function hashTransferState(CoreTransferState calldata cts)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(cts));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

enum CommitmentType {ChannelState, WithdrawData}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./ITransferRegistry.sol";
import "./Types.sol";

interface ITransferDefinition {
    // Validates the initial state of the transfer.
    // Called by validator.ts during `create` updates.
    function create(bytes calldata encodedBalance, bytes calldata)
        external
        view
        returns (bool);

    // Performs a state transition to resolve a transfer and returns final balances.
    // Called by validator.ts during `resolve` updates.
    function resolve(
        bytes calldata encodedBalance,
        bytes calldata,
        bytes calldata
    ) external view returns (Balance memory);

    // Should also have the following properties:
    // string public constant override Name = "...";
    // string public constant override StateEncoding = "...";
    // string public constant override ResolverEncoding = "...";
    // These properties are included on the transfer specifically
    // to make it easier for implementers to add new transfers by
    // only include a `.sol` file
    function Name() external view returns (string memory);

    function StateEncoding() external view returns (string memory);

    function ResolverEncoding() external view returns (string memory);

    function EncodedCancel() external view returns (bytes memory);

    function getRegistryInformation()
        external
        view
        returns (RegisteredTransfer memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
		
/// @author Connext <[email protected]>		
/// @notice This library contains helpers for recovering signatures from a		
///         Vector commitments. Channels do not allow for arbitrary signing of		
///         messages to prevent misuse of private keys by injected providers,		
///         and instead only sign messages with a Vector channel prefix.
library LibChannelCrypto {
    function checkSignature(
        bytes32 hash,
        bytes memory signature,
        address allegedSigner
    ) internal pure returns (bool) {
        return recoverChannelMessageSigner(hash, signature) == allegedSigner;
    }

    function recoverChannelMessageSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 digest = toChannelSignedMessage(hash);
        return ECDSA.recover(digest, signature);
    }

    function toChannelSignedMessage(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(abi.encodePacked("\x16Vector Signed Message:\n32", hash));
    }

    function checkUtilitySignature(
        bytes32 hash,
        bytes memory signature,
        address allegedSigner
    ) internal pure returns (bool) {
        return recoverChannelMessageSigner(hash, signature) == allegedSigner;
    }

    function recoverUtilityMessageSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 digest = toUtilitySignedMessage(hash);
        return ECDSA.recover(digest, signature);
    }

    function toUtilitySignedMessage(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(abi.encodePacked("\x17Utility Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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
pragma solidity ^0.7.1;
pragma experimental "ABIEncoderV2";

struct RegisteredTransfer {
    string name;
    address definition;
    string stateEncoding;
    string resolverEncoding;
    bytes encodedCancel;
}

interface ITransferRegistry {
    event TransferAdded(RegisteredTransfer transfer);

    event TransferRemoved(RegisteredTransfer transfer);

    // Should add a transfer definition to the registry
    // onlyOwner
    function addTransferDefinition(RegisteredTransfer memory transfer) external;

    // Should remove a transfer definition to the registry
    // onlyOwner
    function removeTransferDefinition(string memory name) external;

    // Should return all transfer defintions in registry
    function getTransferDefinitions()
        external
        view
        returns (RegisteredTransfer[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.1;

import "@openzeppelin/contracts/math/SafeMath.sol";

/* This token is ONLY useful for testing
 * Anybody can mint as many tokens as they like
 * Anybody can burn anyone else's tokens
 * It is intentionally not compliant to the ERC20 standard,
 * i.e. returns nothing instead of `true` for
 * several functions.
 * Based on OpenZeppelin's (standard-conforming) implementation.
 */
contract NonconformingToken {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        _name = "Nonconforming Token";
        _symbol = "USDT";
        _decimals = 18;
        _mint(msg.sender, 1000000 ether);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual {
        _transfer(msg.sender, recipient, amount);
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual {
        _approve(msg.sender, spender, amount);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./interfaces/Commitment.sol";
import "./interfaces/ICMCWithdraw.sol";
import "./interfaces/WithdrawHelper.sol";
import "./CMCCore.sol";
import "./CMCAsset.sol";
import "./lib/LibAsset.sol";
import "./lib/LibChannelCrypto.sol";
import "./lib/LibUtils.sol";

/// @title CMCWithdraw
/// @author Connext <[email protected]>
/// @notice Contains logic for all cooperative channel multisig withdrawals.
///         Cooperative withdrawal commitments must be signed by both channel
///         participants. As part of the channel withdrawals, an arbitrary
///         call can be made, which is extracted from the withdraw data.

contract CMCWithdraw is CMCCore, CMCAsset, ICMCWithdraw {
    using LibChannelCrypto for bytes32;

    mapping(bytes32 => bool) private isExecuted;

    modifier validateWithdrawData(WithdrawData calldata wd) {
        require(
            wd.channelAddress == address(this),
            "CMCWithdraw: CHANNEL_MISMATCH"
        );
        _;
    }

    function getWithdrawalTransactionRecord(WithdrawData calldata wd)
        external
        view
        override
        onlyViaProxy
        nonReentrantView
        returns (bool)
    {
        return isExecuted[hashWithdrawData(wd)];
    }

    /// @param wd The withdraw data consisting of
    /// semantic withdraw information, i.e. assetId, recipient, and amount;
    /// information to make an optional call in addition to the actual transfer,
    /// i.e. target address for the call and call payload;
    /// additional information, i.e. channel address and nonce.
    /// @param aliceSignature Signature of owner a
    /// @param bobSignature Signature of owner b
    function withdraw(
        WithdrawData calldata wd,
        bytes calldata aliceSignature,
        bytes calldata bobSignature
    ) external override onlyViaProxy nonReentrant validateWithdrawData(wd) {
        // Generate hash
        bytes32 wdHash = hashWithdrawData(wd);

        // Verify Alice's and Bob's signature on the withdraw data
        verifySignaturesOnWithdrawDataHash(wdHash, aliceSignature, bobSignature);

        // Replay protection
        require(!isExecuted[wdHash], "CMCWithdraw: ALREADY_EXECUTED");
        isExecuted[wdHash] = true;

        // Determine actually transferable amount
        uint256 actualAmount = getAvailableAmount(wd.assetId, wd.amount);

        // Revert if actualAmount is zero && callTo is 0
        require(
            actualAmount > 0 || wd.callTo != address(0),
            "CMCWithdraw: NO_OP"
        );

        // Register and execute the transfer
        transferAsset(wd.assetId, wd.recipient, actualAmount);

        // Do we have to make a call in addition to the actual transfer?
        if (wd.callTo != address(0)) {
            WithdrawHelper(wd.callTo).execute(wd, actualAmount);
        }
    }

    function verifySignaturesOnWithdrawDataHash(
        bytes32 wdHash,
        bytes calldata aliceSignature,
        bytes calldata bobSignature
    ) internal view {
        bytes32 commitment =
            keccak256(abi.encode(CommitmentType.WithdrawData, wdHash));
        require(
            commitment.checkSignature(aliceSignature, alice),
            "CMCWithdraw: INVALID_ALICE_SIG"
        );
        require(
            commitment.checkSignature(bobSignature, bob),
            "CMCWithdraw: INVALID_BOB_SIG"
        );
    }

    function hashWithdrawData(WithdrawData calldata wd)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(wd));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./ICMCWithdraw.sol";

interface WithdrawHelper {
    function execute(WithdrawData calldata wd, uint256 actualAmount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./TransferDefinition.sol";
import "../lib/LibChannelCrypto.sol";

/// @title Withdraw
/// @author Connext <[email protected]>
/// @notice This contract burns the initiator's funds if a mutually signed
///         withdraw commitment can be generated

contract Withdraw is TransferDefinition {
    using LibChannelCrypto for bytes32;

    struct TransferState {
        bytes initiatorSignature;
        address initiator;
        address responder;
        bytes32 data;
        uint256 nonce; // included so that each withdraw commitment has a unique hash
        uint256 fee;
        address callTo;
        bytes callData;
    }

    struct TransferResolver {
        bytes responderSignature;
    }

    // Provide registry information
    string public constant override Name = "Withdraw";
    string public constant override StateEncoding =
        "tuple(bytes initiatorSignature, address initiator, address responder, bytes32 data, uint256 nonce, uint256 fee, address callTo, bytes callData)";
    string public constant override ResolverEncoding =
        "tuple(bytes responderSignature)";

    function EncodedCancel() external pure override returns(bytes memory) {
      TransferResolver memory resolver;
      resolver.responderSignature = new bytes(65);
      return abi.encode(resolver);
    }

    function create(bytes calldata encodedBalance, bytes calldata encodedState)
        external
        pure
        override
        returns (bool)
    {
        // Get unencoded information
        TransferState memory state = abi.decode(encodedState, (TransferState));
        Balance memory balance = abi.decode(encodedBalance, (Balance));

        require(balance.amount[1] == 0, "Withdraw: NONZERO_RECIPIENT_BALANCE");
        require(
            state.initiator != address(0) && state.responder != address(0),
            "Withdraw: EMPTY_SIGNERS"
        );
        require(state.data != bytes32(0), "Withdraw: EMPTY_DATA");
        require(state.nonce != uint256(0), "Withdraw: EMPTY_NONCE");
        require(
            state.fee <= balance.amount[0],
            "Withdraw: INSUFFICIENT_BALANCE"
        );
        require(
            state.data.checkSignature(
                state.initiatorSignature,
                state.initiator
            ),
            "Withdraw: INVALID_INITIATOR_SIG"
        );
        
        // Valid initial transfer state
        return true;
    }

    function resolve(
        bytes calldata encodedBalance,
        bytes calldata encodedState,
        bytes calldata encodedResolver
    ) external pure override returns (Balance memory) {
        TransferState memory state = abi.decode(encodedState, (TransferState));
        TransferResolver memory resolver =
            abi.decode(encodedResolver, (TransferResolver));
        Balance memory balance = abi.decode(encodedBalance, (Balance));

        // Allow for a withdrawal to be canceled if an empty signature is 
        // passed in. Should have *specific* cancellation action, not just
        // any invalid sig
        bytes memory b = new bytes(65);
        if (keccak256(resolver.responderSignature) == keccak256(b)) {
            // Withdraw should be cancelled, no state manipulation needed
        } else {
            require(
                state.data.checkSignature(
                    resolver.responderSignature,
                    state.responder
                ),
                "Withdraw: INVALID_RESPONDER_SIG"
            );
            // Reduce withdraw amount by optional fee
            // It's up to the offchain validators to ensure that the withdraw commitment takes this fee into account
            balance.amount[1] = state.fee;
            balance.amount[0] = 0;
        }

        return balance;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "../interfaces/ITransferDefinition.sol";
import "../interfaces/ITransferRegistry.sol";

/// @title TransferDefinition
/// @author Connext <[email protected]>
/// @notice This contract helps reduce boilerplate needed when creating
///         new transfer definitions by providing an implementation of
///         the required getter

abstract contract TransferDefinition is ITransferDefinition {
    function getRegistryInformation()
        external
        view
        override
        returns (RegisteredTransfer memory)
    {
        return
            RegisteredTransfer({
                name: this.Name(),
                stateEncoding: this.StateEncoding(),
                resolverEncoding: this.ResolverEncoding(),
                definition: address(this),
                encodedCancel: this.EncodedCancel()
            });
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./interfaces/ITransferRegistry.sol";
import "./lib/LibIterableMapping.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title TransferRegistry
/// @author Connext <[email protected]>
/// @notice The TransferRegistry maintains an onchain record of all
///         supported transfers (specifically holds the registry information
///         defined within the contracts). The offchain protocol uses
///         this information to get the correct encodings when generating
///         signatures. The information stored here can only be updated
///         by the owner of the contract

contract TransferRegistry is Ownable, ITransferRegistry {
    using LibIterableMapping for LibIterableMapping.IterableMapping;

    LibIterableMapping.IterableMapping transfers;

    /// @dev Should add a transfer definition to the registry
    function addTransferDefinition(RegisteredTransfer memory definition)
        external
        override
        onlyOwner
    {
        // Get index transfer will be added at
        uint256 idx = transfers.length();
        
        // Add registered transfer
        transfers.addTransferDefinition(definition);

        // Emit event
        emit TransferAdded(transfers.getTransferDefinitionByIndex(idx));
    }

    /// @dev Should remove a transfer definition from the registry
    function removeTransferDefinition(string memory name)
        external
        override
        onlyOwner
    {
        // Get transfer from library to remove for event
        RegisteredTransfer memory transfer = transfers.getTransferDefinitionByName(name);

        // Remove transfer
        transfers.removeTransferDefinition(name);

        // Emit event
        emit TransferRemoved(transfer);
    }

    /// @dev Should return all transfer defintions in registry
    function getTransferDefinitions()
        external
        view
        override
        returns (RegisteredTransfer[] memory)
    {
        return transfers.getTransferDefinitions();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "../interfaces/ITransferRegistry.sol";

/// @title LibIterableMapping
/// @author Connext <[email protected]>
/// @notice This library provides an efficient way to store and retrieve
///         RegisteredTransfers. This contract is used to manage the transfers
///         stored by `TransferRegistry.sol`
library LibIterableMapping {
    struct TransferDefinitionWithIndex {
        RegisteredTransfer transfer;
        uint256 index;
    }

    struct IterableMapping {
        mapping(string => TransferDefinitionWithIndex) transfers;
        string[] names;
    }

    function stringEqual(string memory s, string memory t)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(s)) == keccak256(abi.encodePacked(t));
    }

    function isEmptyString(string memory s) internal pure returns (bool) {
        return stringEqual(s, "");
    }

    function nameExists(IterableMapping storage self, string memory name)
        internal
        view
        returns (bool)
    {
        return
            !isEmptyString(name) &&
            self.names.length != 0 &&
            stringEqual(self.names[self.transfers[name].index], name);
    }

    function length(IterableMapping storage self)
        internal
        view
        returns (uint256)
    {
        return self.names.length;
    }

    function getTransferDefinitionByName(
        IterableMapping storage self,
        string memory name
    ) internal view returns (RegisteredTransfer memory) {
        require(nameExists(self, name), "LibIterableMapping: NAME_NOT_FOUND");
        return self.transfers[name].transfer;
    }

    function getTransferDefinitionByIndex(
        IterableMapping storage self,
        uint256 index
    ) internal view returns (RegisteredTransfer memory) {
        require(index < self.names.length, "LibIterableMapping: INVALID_INDEX");
        return self.transfers[self.names[index]].transfer;
    }

    function getTransferDefinitions(IterableMapping storage self)
        internal
        view
        returns (RegisteredTransfer[] memory)
    {
        uint256 l = self.names.length;
        RegisteredTransfer[] memory transfers = new RegisteredTransfer[](l);
        for (uint256 i = 0; i < l; i++) {
            transfers[i] = self.transfers[self.names[i]].transfer;
        }
        return transfers;
    }

    function addTransferDefinition(
        IterableMapping storage self,
        RegisteredTransfer memory transfer
    ) internal {
        string memory name = transfer.name;
        require(!isEmptyString(name), "LibIterableMapping: EMPTY_NAME");
        require(!nameExists(self, name), "LibIterableMapping: NAME_ALREADY_ADDED");
        self.transfers[name] = TransferDefinitionWithIndex({
            transfer: transfer,
            index: self.names.length
        });
        self.names.push(name);
    }

    function removeTransferDefinition(
        IterableMapping storage self,
        string memory name
    ) internal {
        require(!isEmptyString(name), "LibIterableMapping: EMPTY_NAME");
        require(nameExists(self, name), "LibIterableMapping: NAME_NOT_FOUND");
        uint256 index = self.transfers[name].index;
        string memory lastName = self.names[self.names.length - 1];
        self.transfers[lastName].index = index;
        self.names[index] = lastName;
        delete self.transfers[name];
        self.names.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "../interfaces/ITransferRegistry.sol";
import "../lib/LibIterableMapping.sol";

/// @title TestLibIterableMapping
/// @author Layne Haber <[email protected]>
/// @notice Used to easily test the internal methods of
///         LibIterableMapping.sol by aliasing them to public
///         methods.
contract TestLibIterableMapping {
    using LibIterableMapping for LibIterableMapping.IterableMapping;

    LibIterableMapping.IterableMapping data;

    constructor() {}

    function stringEqual(string memory s, string memory t)
        public
        pure
        returns (bool)
    {
        return LibIterableMapping.stringEqual(s, t);
    }

    function isEmptyString(string memory s) public pure returns (bool) {
        return LibIterableMapping.isEmptyString(s);
    }

    function nameExists(string memory name) public view returns (bool) {
        return LibIterableMapping.nameExists(data, name);
    }

    function length() public view returns (uint256) {
        return LibIterableMapping.length(data);
    }

    function getTransferDefinitionByName(string memory name)
        public
        view
        returns (RegisteredTransfer memory)
    {
        return LibIterableMapping.getTransferDefinitionByName(data, name);
    }

    function getTransferDefinitionByIndex(uint256 index)
        public
        view
        returns (RegisteredTransfer memory)
    {
        return LibIterableMapping.getTransferDefinitionByIndex(data, index);
    }

    function getTransferDefinitions()
        public
        view
        returns (RegisteredTransfer[] memory)
    {
        return LibIterableMapping.getTransferDefinitions(data);
    }

    function addTransferDefinition(RegisteredTransfer memory transfer) public {
        return LibIterableMapping.addTransferDefinition(data, transfer);
    }

    function removeTransferDefinition(string memory name) public {
        return LibIterableMapping.removeTransferDefinition(data, name);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./IVectorChannel.sol";
import "./Types.sol";

interface ITestChannel is IVectorChannel {
    function testMakeExitable(
        address assetId,
        address payable recipient,
        uint256 maxAmount
    ) external;

    function testMakeBalanceExitable(
        address assetId,
        Balance memory balance
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental "ABIEncoderV2";

import "../ChannelMastercopy.sol";
import "../interfaces/ITestChannel.sol";

/// @title TestChannel
/// @author Layne Haber <[email protected]>
/// @notice This contract will help test the `ChannelMastercopy` contract and
///         the associated bits of functionality. This contract should *only*
///         contain aliases to internal functions that should be unit-tested,
///         like the `makeExitable` call on `CMCAsset.sol`. Using this
///         contract will help reduce the amount of boilerplate needed to test
///         component functionality. For example, `CMCAsset.sol` is only
///         able to be tested via the adjudicator in many practical cases.
///         Creating a helper function allows for easier testing of only
///         that functionality.

contract TestChannel is ChannelMastercopy, ITestChannel {
    function testMakeExitable(
        address assetId,
        address payable recipient,
        uint256 maxAmount
    ) public override {
        makeExitable(assetId, recipient, maxAmount);
    }

    function testMakeBalanceExitable(
        address assetId,
        Balance memory balance
    ) public override {
        makeBalanceExitable(assetId, balance);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./interfaces/IVectorChannel.sol";
import "./CMCCore.sol";
import "./CMCAsset.sol";
import "./CMCDeposit.sol";
import "./CMCWithdraw.sol";
import "./CMCAdjudicator.sol";

/// @title ChannelMastercopy
/// @author Connext <[email protected]>
/// @notice Contains the logic used by all Vector multisigs. A proxy to this
///         contract is deployed per-channel using the ChannelFactory.sol.
///         Supports channel adjudication logic, deposit logic, and arbitrary
///         calls when a commitment is double-signed.
contract ChannelMastercopy is
    CMCCore,
    CMCAsset,
    CMCDeposit,
    CMCWithdraw,
    CMCAdjudicator,
    IVectorChannel
{

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./TransferDefinition.sol";

/// @title HashlockTransfer
/// @author Connext <[email protected]>
/// @notice This contract allows users to claim a payment locked in
///         the application if they provide the correct preImage. The payment is
///         reverted if not unlocked by the timelock if one is provided.

contract HashlockTransfer is TransferDefinition {
    struct TransferState {
        bytes32 lockHash;
        uint256 expiry; // If 0, then no timelock is enforced
    }

    struct TransferResolver {
        bytes32 preImage;
    }

    // Provide registry information
    string public constant override Name = "HashlockTransfer";
    string public constant override StateEncoding =
        "tuple(bytes32 lockHash, uint256 expiry)";
    string public constant override ResolverEncoding =
        "tuple(bytes32 preImage)";

    function EncodedCancel() external pure override returns(bytes memory) {
      TransferResolver memory resolver;
      resolver.preImage = bytes32(0);
      return abi.encode(resolver);
    } 

    function create(bytes calldata encodedBalance, bytes calldata encodedState)
        external
        view
        override
        returns (bool)
    {
        // Decode parameters
        TransferState memory state = abi.decode(encodedState, (TransferState));
        Balance memory balance = abi.decode(encodedBalance, (Balance));

        require(
            balance.amount[0] > 0,
            "HashlockTransfer: ZER0_SENDER_BALANCE"
        );

        require(
            balance.amount[1] == 0,
            "HashlockTransfer: NONZERO_RECIPIENT_BALANCE"
        );
        require(
            state.lockHash != bytes32(0),
            "HashlockTransfer: EMPTY_LOCKHASH"
        );
        require(
            state.expiry == 0 || state.expiry > block.timestamp,
            "HashlockTransfer: EXPIRED_TIMELOCK"
        );

        // Valid transfer state
        return true;
    }

    function resolve(
        bytes calldata encodedBalance,
        bytes calldata encodedState,
        bytes calldata encodedResolver
    ) external view override returns (Balance memory) {
        TransferState memory state = abi.decode(encodedState, (TransferState));
        TransferResolver memory resolver =
            abi.decode(encodedResolver, (TransferResolver));
        Balance memory balance = abi.decode(encodedBalance, (Balance));

        // If you pass in bytes32(0), payment is canceled
        // If timelock is nonzero and has expired, payment must be canceled
        // otherwise resolve will revert
        if (resolver.preImage != bytes32(0)) {
            // Payment must not be expired
            require(state.expiry == 0 || state.expiry > block.timestamp, "HashlockTransfer: PAYMENT_EXPIRED");

            // Check hash for normal payment unlock
            bytes32 generatedHash = sha256(abi.encode(resolver.preImage));
            require(
                state.lockHash == generatedHash,
                "HashlockTransfer: INVALID_PREIMAGE"
            );

            // Update state
            balance.amount[1] = balance.amount[0];
            balance.amount[0] = 0;
        }
        // To cancel, the preImage must be empty (not simply incorrect)
        // There are no additional state mutations, and the preImage is
        // asserted by the `if` statement

        return balance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/* This token is ONLY useful for testing
 * Anybody can mint as many tokens as they like
 * Anybody can burn anyone else's tokens
 * Will fail to transfer ANY tokens
 */
contract FailingToken is ERC20 {
    bool public transferShouldRevert;
    bool public transferShouldFail;
    bool public rejectEther;

    constructor() ERC20("Failing Token", "FAIL") {
        transferShouldRevert = true;
        _mint(msg.sender, 1000000 ether);
    }

    receive() external payable {
        if (rejectEther) {
            revert("ERC20: ETHER_REJECTED");
        }
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if (transferShouldRevert) {
            revert("FAIL: Failing token");
        }
        if (transferShouldFail) {
            return false;
        }
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (transferShouldRevert) {
            revert("FAIL: Failing token");
        }
        if (transferShouldFail) {
            return false;
        }
        return super.transferFrom(sender, recipient, amount);
    }

    function setTransferShouldRevert(bool _transferShouldRevert)
        public
        returns (bool)
    {
        transferShouldRevert = _transferShouldRevert;
        return transferShouldRevert;
    }

    function setTransferShouldFail(bool _transferShouldFail)
        public
        returns (bool)
    {
        transferShouldFail = _transferShouldFail;
        return transferShouldFail;
    }

    function setRejectEther(bool _rejectEther) public returns (bool) {
        rejectEther = _rejectEther;
        return rejectEther;
    }

    function succeedingTransfer(address recipient, uint256 amount)
        public
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }
}