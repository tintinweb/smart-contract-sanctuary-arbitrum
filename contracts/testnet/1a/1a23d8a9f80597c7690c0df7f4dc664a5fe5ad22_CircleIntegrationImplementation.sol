// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {ERC1967Upgrade} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

import {CircleIntegration} from "./CircleIntegration.sol";

contract CircleIntegrationImplementation is CircleIntegration {
    function initialize() public virtual initializer {
        // this function needs to be exposed for an upgrade to pass
    }

    modifier initializer() {
        address impl = ERC1967Upgrade._getImplementation();

        require(!isInitialized(impl), "already initialized");

        setInitialized(impl);

        _;
    }

    function circleIntegrationImplementation() public pure returns (bytes32) {
        return keccak256("circleIntegrationImplementation()");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWormhole} from "wormhole/interfaces/IWormhole.sol";
import {BytesLib} from "wormhole/libraries/external/BytesLib.sol";

import {ICircleBridge} from "../interfaces/circle/ICircleBridge.sol";

import {CircleIntegrationGovernance} from "./CircleIntegrationGovernance.sol";
import {CircleIntegrationMessages} from "./CircleIntegrationMessages.sol";

/**
 * @notice This contract burns and mints Circle-supported tokens by using Circle's Cross-Chain Transfer Protocol. It also emits
 * Wormhole messages with arbitrary payloads to allow for additional composability when performing cross-chain
 * transfers of Circle-suppored assets.
 */
contract CircleIntegration is CircleIntegrationMessages, CircleIntegrationGovernance, ReentrancyGuard {
    using BytesLib for bytes;

    /**
     * @notice Emitted when Circle-supported assets have been minted to the mintRecipient
     * @param emitterChainId Wormhole chain ID of emitter contract on source chain
     * @param emitterAddress Address (bytes32 zero-left-padded) of emitter on source chain
     * @param sequence Sequence of Wormhole message used to mint tokens
     */
    event Redeemed(uint16 indexed emitterChainId, bytes32 indexed emitterAddress, uint64 indexed sequence);

    /**
     * @notice `transferTokensWithPayload` calls the Circle Bridge contract to burn Circle-supported tokens. It emits
     * a Wormhole message containing a user-specified payload with instructions for what to do with
     * the Circle-supported assets once they have been minted on the target chain.
     * @dev reverts if:
     * - user passes insufficient value to pay Wormhole message fee
     * - `token` is not supported by Circle Bridge
     * - `amount` is zero
     * - `targetChain` is not supported
     * - `mintRecipient` is bytes32(0)
     * @param transferParams Struct containing the following attributes:
     * - `token` Address of the token to be burned
     * - `amount` Amount of `token` to be burned
     * - `targetChain` Wormhole chain ID of the target blockchain
     * - `mintRecipient` The recipient wallet or contract address on the target chain
     * @param batchId ID for Wormhole message batching
     * @param payload Arbitrary payload to be delivered to the target chain via Wormhole
     * @return messageSequence Wormhole sequence number for this contract
     */
    function transferTokensWithPayload(TransferParameters memory transferParams, uint32 batchId, bytes memory payload)
        public
        payable
        nonReentrant
        returns (uint64 messageSequence)
    {
        // cache wormhole instance and fees to save on gas
        IWormhole wormhole = wormhole();
        uint256 wormholeFee = wormhole.messageFee();

        // confirm that the caller has sent enough ether to pay for the wormhole message fee
        require(msg.value == wormholeFee, "insufficient value");

        // Call the circle bridge and `depositForBurnWithCaller`. The `mintRecipient`
        // should be the target contract (or wallet) composing on this contract.
        (uint64 nonce, uint256 amountReceived) = _transferTokens(
            transferParams.token, transferParams.amount, transferParams.targetChain, transferParams.mintRecipient
        );

        // encode DepositWithPayload message
        bytes memory encodedMessage = encodeDepositWithPayload(
            DepositWithPayload({
                token: addressToBytes32(transferParams.token),
                amount: amountReceived,
                sourceDomain: localDomain(),
                targetDomain: getDomainFromChainId(transferParams.targetChain),
                nonce: nonce,
                fromAddress: addressToBytes32(msg.sender),
                mintRecipient: transferParams.mintRecipient,
                payload: payload
            })
        );

        // send the DepositWithPayload wormhole message
        messageSequence = wormhole.publishMessage{value: wormholeFee}(batchId, encodedMessage, wormholeFinality());
    }

    function _transferTokens(address token, uint256 amount, uint16 targetChain, bytes32 mintRecipient)
        internal
        returns (uint64 nonce, uint256 amountReceived)
    {
        // sanity check user input
        require(amount > 0, "amount must be > 0");
        require(mintRecipient != bytes32(0), "invalid mint recipient");
        require(isAcceptedToken(token), "token not accepted");
        require(getRegisteredEmitter(targetChain) != bytes32(0), "target contract not registered");

        // take custody of tokens
        amountReceived = custodyTokens(token, amount);

        // cache Circle Bridge instance
        ICircleBridge circleBridge = circleBridge();

        // approve the Circle Bridge to spend tokens
        SafeERC20.safeApprove(IERC20(token), address(circleBridge), amountReceived);

        // burn tokens on the bridge
        nonce = circleBridge.depositForBurnWithCaller(
            amountReceived, getDomainFromChainId(targetChain), mintRecipient, token, getRegisteredEmitter(targetChain)
        );
    }

    function custodyTokens(address token, uint256 amount) internal returns (uint256) {
        // query own token balance before transfer
        (, bytes memory queriedBalanceBefore) =
            token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)));
        uint256 balanceBefore = abi.decode(queriedBalanceBefore, (uint256));

        // deposit tokens
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);

        // query own token balance after transfer
        (, bytes memory queriedBalanceAfter) =
            token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)));
        uint256 balanceAfter = abi.decode(queriedBalanceAfter, (uint256));

        return balanceAfter - balanceBefore;
    }

    /**
     * @notice `redeemTokensWithPayload` verifies the Wormhole message from the source chain and
     * verifies that the passed Circle Bridge message is valid. It calls the Circle Bridge
     * contract by passing the Circle message and attestation to mint tokens to the specified
     * mint recipient. It also verifies that the caller is the specified mint recipient to ensure
     * atomic execution of the additional instructions in the Wormhole message.
     * @dev reverts if:
     * - Wormhole message is not properly attested
     * - Wormhole message was not emitted from a registered contrat
     * - Wormhole message was already consumed by this contract
     * - msg.sender is not the encoded mintRecipient
     * - Circle Bridge message and Wormhole message are not associated
     * - `receiveMessage` call to Circle Transmitter fails
     * @param params Struct containing the following attributes:
     * - `encodedWormholeMessage` Wormhole message emitted by a registered contract including
     * information regarding the token burn on the source chain and an arbitrary message.
     * - `circleBridgeMessage` Message emitted by Circle Bridge contract with information regarding
     * the token burn on the source chain.
     * - `circleAttestation` Serialized EC Signature attesting the cross-chain transfer
     * @return depositInfo Struct containing the following attributes:
     * - `token` Address (bytes32 left-zero-padded) of token to be minted
     * - `amount` Amount of tokens to be minted
     * - `sourceDomain` Circle domain for the source chain
     * - `targetDomain` Circle domain for the target chain
     * - `nonce` Circle sequence number for the transfer
     * - `fromAddress` Source CircleIntegration contract caller's address
     * - `mintRecipient` Recipient of minted tokens (must be caller of this contract)
     * - `payload` Arbitrary Wormhole message payload
     */
    function redeemTokensWithPayload(RedeemParameters calldata params)
        public
        returns (DepositWithPayload memory depositInfo)
    {
        // verify the wormhole message
        IWormhole.VM memory verifiedMessage = verifyWormholeRedeemMessage(params.encodedWormholeMessage);

        // Decode the message payload into the DepositWithPayload struct. Call the Circle TokenMinter
        // contract to determine the address of the encoded token on this chain.
        depositInfo = decodeDepositWithPayload(verifiedMessage.payload);
        depositInfo.token = fetchLocalTokenAddress(depositInfo.sourceDomain, depositInfo.token);

        // confirm that circle gave us a valid token address
        require(depositInfo.token != bytes32(0), "invalid local token address");

        // confirm that the caller is the `mintRecipient` to ensure atomic execution
        require(addressToBytes32(msg.sender) == depositInfo.mintRecipient, "caller must be mintRecipient");

        // confirm that the caller passed the correct message pair
        require(
            verifyCircleMessage(
                params.circleBridgeMessage, depositInfo.sourceDomain, depositInfo.targetDomain, depositInfo.nonce
            ),
            "invalid message pair"
        );

        // call the circle bridge to mint tokens to the recipient
        bool success = circleTransmitter().receiveMessage(params.circleBridgeMessage, params.circleAttestation);
        require(success, "CIRCLE_INTEGRATION: failed to mint tokens");

        // emit Redeemed event
        emit Redeemed(verifiedMessage.emitterChainId, verifiedMessage.emitterAddress, verifiedMessage.sequence);
    }

    function verifyWormholeRedeemMessage(bytes memory encodedMessage) internal returns (IWormhole.VM memory) {
        require(evmChain() == block.chainid, "invalid evm chain");

        // parse and verify the Wormhole core message
        (IWormhole.VM memory verifiedMessage, bool valid, string memory reason) =
            wormhole().parseAndVerifyVM(encodedMessage);

        // confirm that the core layer verified the message
        require(valid, reason);

        // verify that this message was emitted by a trusted contract
        require(verifyEmitter(verifiedMessage), "unknown emitter");

        // revert if this message has been consumed already
        require(!isMessageConsumed(verifiedMessage.hash), "message already consumed");
        consumeMessage(verifiedMessage.hash);

        return verifiedMessage;
    }

    function verifyEmitter(IWormhole.VM memory vm) internal view returns (bool) {
        // verify that the sender of the wormhole message is a trusted
        return (
            getRegisteredEmitter(vm.emitterChainId) == vm.emitterAddress &&
            vm.emitterAddress != bytes32(0)
        );
    }

    function verifyCircleMessage(bytes memory circleMessage, uint32 sourceDomain, uint32 targetDomain, uint64 nonce)
        internal
        pure
        returns (bool)
    {
        // parse the circle bridge message inline
        uint32 circleSourceDomain = circleMessage.toUint32(4);
        uint32 circleTargetDomain = circleMessage.toUint32(8);
        uint64 circleNonce = circleMessage.toUint64(12);

        // confirm that both the Wormhole message and Circle message share the same transfer info
        return (sourceDomain == circleSourceDomain && targetDomain == circleTargetDomain && nonce == circleNonce);
    }

    /**
     * @notice Fetches the local token address given an address and domain from
     * a different chain.
     * @param sourceDomain Circle domain for the sending chain.
     * @param sourceToken Address of the token for the sending chain.
     * @return Address bytes32 formatted address of the `sourceToken` on this chain.
     */
    function fetchLocalTokenAddress(uint32 sourceDomain, bytes32 sourceToken)
        public
        view
        returns (bytes32)
    {
        return addressToBytes32(
            circleTokenMinter().remoteTokensToLocalTokens(
                keccak256(abi.encodePacked(sourceDomain, sourceToken))
            )
        );
    }

    /**
     * @notice Converts type address to bytes32 (left-zero-padded)
     * @param address_ Address to convert to bytes32
     * @return Address bytes32
     */
    function addressToBytes32(address address_) public pure returns (bytes32) {
        return bytes32(uint256(uint160(address_)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;

        uint32 guardianSetIndex;
        Signature[] signatures;

        bytes32 hash;
    }

    struct ContractUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        address newContract;
    }

    struct GuardianSetUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        GuardianSet newGuardianSet;
        uint32 newGuardianSetIndex;
    }

    struct SetMessageFee {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 messageFee;
    }

    struct TransferFees {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 amount;
        bytes32 recipient;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;

        uint256 evmChainId;
        uint16 newChainId;
    }

    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);
    event ContractUpgraded(address indexed oldContract, address indexed newContract);
    event GuardianSetAdded(uint32 indexed index);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function initialize() external;

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Signature[] memory signatures, GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

    function quorum(uint numGuardians) external pure returns (uint numSignaturesRequiredForQuorum);

    function getGuardianSet(uint32 index) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);

    function parseContractUpgrade(bytes memory encodedUpgrade) external pure returns (ContractUpgrade memory cu);

    function parseGuardianSetUpgrade(bytes memory encodedUpgrade) external pure returns (GuardianSetUpgrade memory gsu);

    function parseSetMessageFee(bytes memory encodedSetMessageFee) external pure returns (SetMessageFee memory smf);

    function parseTransferFees(bytes memory encodedTransferFees) external pure returns (TransferFees memory tf);

    function parseRecoverChainId(bytes memory encodedRecoverChainId) external pure returns (RecoverChainId memory rci);

    function submitContractUpgrade(bytes memory _vm) external;

    function submitSetMessageFee(bytes memory _vm) external;

    function submitNewGuardianSet(bytes memory _vm) external;

    function submitTransferFees(bytes memory _vm) external;

    function submitRecoverChainId(bytes memory _vm) external;
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {IMessageTransmitter} from "./IMessageTransmitter.sol";
import {ITokenMinter} from "./ITokenMinter.sol";

interface ICircleBridge {
    /**
     * @notice Deposits and burns tokens from sender to be minted on destination domain.
     * Emits a `DepositForBurn` event.
     * @dev reverts if:
     * - given burnToken is not supported
     * - given destinationDomain has no CircleBridge registered
     * - transferFrom() reverts. For example, if sender's burnToken balance or approved allowance
     * to this contract is less than `amount`.
     * - burn() reverts. For example, if `amount` is 0.
     * - MessageTransmitter returns false or reverts.
     * @param _amount amount of tokens to burn
     * @param _destinationDomain destination domain (ETH = 0, AVAX = 1)
     * @param _mintRecipient address of mint recipient on destination domain
     * @param _burnToken address of contract to burn deposited tokens, on local domain
     * @return _nonce unique nonce reserved by message
     */
    function depositForBurn(uint256 _amount, uint32 _destinationDomain, bytes32 _mintRecipient, address _burnToken)
        external
        returns (uint64 _nonce);

    /**
     * @notice Deposits and burns tokens from sender to be minted on destination domain. The mint
     * on the destination domain must be called by `_destinationCaller`.
     * WARNING: if the `_destinationCaller` does not represent a valid address as bytes32, then it will not be possible
     * to broadcast the message on the destination domain. This is an advanced feature, and the standard
     * depositForBurn() should be preferred for use cases where a specific destination caller is not required.
     * Emits a `DepositForBurn` event.
     * @dev reverts if:
     * - given destinationCaller is zero address
     * - given burnToken is not supported
     * - given destinationDomain has no CircleBridge registered
     * - transferFrom() reverts. For example, if sender's burnToken balance or approved allowance
     * to this contract is less than `amount`.
     * - burn() reverts. For example, if `amount` is 0.
     * - MessageTransmitter returns false or reverts.
     * @param _amount amount of tokens to burn
     * @param _destinationDomain destination domain
     * @param _mintRecipient address of mint recipient on destination domain
     * @param _burnToken address of contract to burn deposited tokens, on local domain
     * @param _destinationCaller caller on the destination domain, as bytes32
     * @return _nonce unique nonce reserved by message
     */
    function depositForBurnWithCaller(
        uint256 _amount,
        uint32 _destinationDomain,
        bytes32 _mintRecipient,
        address _burnToken,
        bytes32 _destinationCaller
    ) external returns (uint64 _nonce);

    function owner() external view returns (address);

    function handleReceiveMessage(uint32 _remoteDomain, bytes32 _sender, bytes memory messageBody)
        external
        view
        returns (bool);

    function localMessageTransmitter() external view returns (IMessageTransmitter);

    function localMinter() external view returns (ITokenMinter);

    function remoteCircleBridges(uint32 domain) external view returns (bytes32);

    // owner only methods
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {ERC1967Upgrade} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

import {IWormhole} from "wormhole/interfaces/IWormhole.sol";
import {BytesLib} from "wormhole/libraries/external/BytesLib.sol";

import {CircleIntegrationSetters} from "./CircleIntegrationSetters.sol";
import {CircleIntegrationGetters} from "./CircleIntegrationGetters.sol";
import {CircleIntegrationState} from "./CircleIntegrationState.sol";
import {ICircleIntegration} from "../interfaces/ICircleIntegration.sol";

contract CircleIntegrationGovernance is CircleIntegrationGetters, ERC1967Upgrade {
    using BytesLib for bytes;

    /**
     * @notice Emitted when implementation (logic) contracts are upgraded
     * @param oldContract Previous implementation contract address
     * @param newContract New implementation contract address
     */
    event ContractUpgraded(address indexed oldContract, address indexed newContract);

    /**
     * @notice Emitted when the Wormhole message finality state variable changes
     * @param oldFinality Previous `wormholeFinality` value
     * @param newFinality New `wormholeFinality` value
     */
    event WormholeFinalityUpdated(uint8 indexed oldFinality, uint8 indexed newFinality);

    // "CircleIntegration" (left-zero-padded)
    bytes32 constant GOVERNANCE_MODULE = 0x000000000000000000000000000000436972636c65496e746567726174696f6e;

    // for updating `wormholeFinality`
    uint8 constant GOVERNANCE_UPDATE_WORMHOLE_FINALITY = 1;
    uint256 constant GOVERNANCE_UPDATE_WORMHOLE_FINALITY_LENGTH = 36;

    // for registering an emitter (CircleIntegration contact on other blockchains) and Circle Bridge domain
    uint8 constant GOVERNANCE_REGISTER_EMITTER_AND_DOMAIN = 2;
    uint256 constant GOVERNANCE_REGISTER_EMITTER_AND_DOMAIN_LENGTH = 73;

    // for upgrading implementation (logic) contracts
    uint8 constant GOVERNANCE_UPGRADE_CONTRACT = 3;
    uint256 constant GOVERNANCE_UPGRADE_CONTRACT_LENGTH = 67;

    /**
     * @notice `updateWormholeFinality` changes the wormhole message consistencyLevel.
     * @param encodedMessage Attested Wormhole governance message with the following
     * relevant fields:
     * - Field Bytes Type Index
     * - finality 1 uint8 35
     */
    function updateWormholeFinality(bytes memory encodedMessage) public {
        bytes memory payload = verifyAndConsumeGovernanceMessage(encodedMessage, GOVERNANCE_UPDATE_WORMHOLE_FINALITY);
        require(payload.length == GOVERNANCE_UPDATE_WORMHOLE_FINALITY_LENGTH, "invalid governance payload length");

        // cache the current `wormholeFinality` value
        uint8 currentWormholeFinality = wormholeFinality();

        // updating finality should only be relevant for this contract's chain ID
        require(payload.toUint16(33) == chainId(), "invalid target chain");

        // parse the new `wormholeFinality` value at byte 35
        uint8 newWormholeFinality = payload.toUint8(35);
        require(newWormholeFinality > 0, "invalid finality");

        setWormholeFinality(newWormholeFinality);

        emit WormholeFinalityUpdated(currentWormholeFinality, newWormholeFinality);
    }

    /**
     * @notice `registerEmitterAndDomain` saves trusted CircleIntegration contract addresses
     * and Circle's chain domains.
     * @param encodedMessage Attested Wormhole governance message with the following
     * relevant fields:
     * - Field Bytes Type Index
     * - foreignEmitterChainId 2 uint16 35
     * - foreignEmitterAddress 32 bytes32 37
     * - domain 4 uint32 69
     */
    function registerEmitterAndDomain(bytes memory encodedMessage) public {
        bytes memory payload = verifyAndConsumeGovernanceMessage(encodedMessage, GOVERNANCE_REGISTER_EMITTER_AND_DOMAIN);
        require(payload.length == GOVERNANCE_REGISTER_EMITTER_AND_DOMAIN_LENGTH, "invalid governance payload length");

        // registering emitters should only be relevant for this contract's chain ID
        require(payload.toUint16(33) == chainId(), "invalid target chain");

        // emitterChainId at byte 35
        uint16 emitterChainId = payload.toUint16(35);
        require(emitterChainId > 0 && emitterChainId != chainId(), "invalid chain");
        require(getRegisteredEmitter(emitterChainId) == bytes32(0), "chain already registered");

        // emitterAddress at byte 37
        bytes32 emitterAddress = payload.toBytes32(37);
        require(emitterAddress != bytes32(0), "emitter cannot be zero address");

        // domain at byte 69 (hehe)
        uint32 domain = payload.toUint32(69);
        require(domain != localDomain(), "domain == localDomain()");

        // update the registeredEmitters state variable
        setEmitter(emitterChainId, emitterAddress);

        // update the chainId to domain (and domain to chainId) mappings
        setChainIdToDomain(emitterChainId, domain);
        setDomainToChainId(domain, emitterChainId);
    }

    /**
     * @notice `upgradeContract` upgrades the implementation (logic) contract and
     * initializes the new implementation.
     * @param encodedMessage Attested Wormhole governance message with the following
     * relevant fields:
     * - Field Bytes Type Index
     * - newImplementation 32 bytes32 35
     */
    function upgradeContract(bytes memory encodedMessage) public {
        bytes memory payload = verifyAndConsumeGovernanceMessage(encodedMessage, GOVERNANCE_UPGRADE_CONTRACT);
        require(payload.length == GOVERNANCE_UPGRADE_CONTRACT_LENGTH, "invalid governance payload length");

        // contract upgrades should only be relevant for this contract's chain ID
        require(payload.toUint16(33) == chainId(), "invalid target chain");

        address currentImplementation = _getImplementation();

        // newImplementation at byte 35 (32 bytes, but last 20 is the address)
        address newImplementation = readAddressFromBytes32(payload, 35);
        {
            (, bytes memory queried) =
                newImplementation.staticcall(abi.encodeWithSignature("circleIntegrationImplementation()"));
            require(queried.length == 32, "invalid implementation");
            require(
                abi.decode(queried, (bytes32)) == keccak256("circleIntegrationImplementation()"),
                "invalid implementation"
            );
        }

        _upgradeTo(newImplementation);

        // call initialize function of the new implementation
        (bool success, bytes memory reason) = newImplementation.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success, string(reason));

        emit ContractUpgraded(currentImplementation, newImplementation);
    }

    function verifyAndConsumeGovernanceMessage(bytes memory encodedMessage, uint8 action)
        internal
        returns (bytes memory)
    {
        // verify the governance message
        (bytes32 messageHash, bytes memory payload) = verifyGovernanceMessage(encodedMessage, action);

        // store the hash for replay protection
        consumeMessage(messageHash);

        return payload;
    }

    /**
     * @notice `verifyGovernanceMessage` validates governance messages attested by
     * Wormhole's network of guardians.
     * @dev reverts if:
     * - the EVM blockchain has forked
     * - the governance message was not attested
     * - the governance message was generated on the wrong blockchain
     * - the governance message was already consumed
     * - the encoded governance module is incorrect
     * - the encoded governance action is incorrect
     * @param encodedMessage Attested Wormhole governance message with the following
     * relevant fields:
     * - Field Bytes Type Index
     * - governanceModule 32 bytes32 0
     * - governanceAction 1 uint8 32
     * @param action Expected governance action
     * @return messageHash Wormhole governance message hash
     * @return payload Verified Wormhole governance message payload
     */
    function verifyGovernanceMessage(bytes memory encodedMessage, uint8 action)
        public
        view
        returns (bytes32 messageHash, bytes memory payload)
    {
        // make sure the blockchain has not forked
        require(evmChain() == block.chainid, "invalid evm chain");

        // verify the governance message
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole().parseAndVerifyVM(encodedMessage);
        require(valid, reason);

        // confirm that the governance message was sent from the governance contract
        require(vm.emitterChainId == governanceChainId(), "invalid governance chain");
        require(vm.emitterAddress == governanceContract(), "invalid governance contract");

        // confirm that this governance action has not been consumed already
        require(!isMessageConsumed(vm.hash), "governance action already consumed");

        // module at byte 0
        require(vm.payload.toBytes32(0) == GOVERNANCE_MODULE, "invalid governance module");

        // action at byte 32
        require(vm.payload.toUint8(32) == action, "invalid governance action");

        // set return values
        payload = vm.payload;
        messageHash = vm.hash;
    }

    function readAddressFromBytes32(bytes memory serialized, uint256 start) internal pure returns (address) {
        uint256 end = start + 12;
        for (uint256 i = start; i < end;) {
            require(serialized.toUint8(i) == 0, "invalid address");
            unchecked {
                i += 1;
            }
        }
        return serialized.toAddress(end);
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {BytesLib} from "wormhole/libraries/external/BytesLib.sol";

import {CircleIntegrationStructs} from "./CircleIntegrationStructs.sol";

contract CircleIntegrationMessages is CircleIntegrationStructs {
    using BytesLib for bytes;

    /**
     * @notice `encodeDepositWithPayload` encodes the `DepositWithPayload` struct into bytes
     * so that it can be sent as an arbitrary message payload via Wormhole.
     * @param message `DepositWithPayload` struct containing the following attributes:
     * - `token` Address (bytes32 left-zero-padded) of token to be minted
     * - `amount` Amount of tokens to be minted
     * - `sourceDomain` Circle domain for the source chain
     * - `targetDomain` Circle domain for the target chain
     * - `nonce` Circle sequence number for the transfer
     * - `fromAddress` Source CircleIntegration contract caller's address
     * - `mintRecipient` Recipient of minted tokens (must be caller of this contract)
     * - `payload` Arbitrary Wormhole message payload
     * @return EncodedDepositWithPayload bytes
     */
    function encodeDepositWithPayload(DepositWithPayload memory message) public pure returns (bytes memory) {
        return abi.encodePacked(
            uint8(1), // payloadId
            message.token,
            message.amount,
            message.sourceDomain,
            message.targetDomain,
            message.nonce,
            message.fromAddress,
            message.mintRecipient,
            uint16(message.payload.length),
            message.payload
        );
    }

    /**
     * @notice `decodeDepositWithPayload` decodes an encoded `DepositWithPayload` struct
     * @dev reverts if:
     * - the first byte (payloadId) does not equal 1
     * - the length of the payload is short or longer than expected
     * @param encoded Encoded `DepositWithPayload` struct
     * @return message `DepositWithPayload` struct containing the following attributes:
     * - `token` Address (bytes32 left-zero-padded) of token to be minted
     * - `amount` Amount of tokens to be minted
     * - `sourceDomain` Circle domain for the source chain
     * - `targetDomain` Circle domain for the target chain
     * - `nonce` Circle sequence number for the transfer
     * - `fromAddress` Source CircleIntegration contract caller's address
     * - `mintRecipient` Recipient of minted tokens (must be caller of this contract)
     * - `payload` Arbitrary Wormhole message payload
     */
    function decodeDepositWithPayload(bytes memory encoded) public pure returns (DepositWithPayload memory message) {
        // payloadId
        require(encoded.toUint8(0) == 1, "invalid message payloadId");

        uint256 index = 1;

        // token address
        message.token = encoded.toBytes32(index);
        index += 32;

        // token amount
        message.amount = encoded.toUint256(index);
        index += 32;

        // source domain
        message.sourceDomain = encoded.toUint32(index);
        index += 4;

        // target domain
        message.targetDomain = encoded.toUint32(index);
        index += 4;

        // nonce
        message.nonce = encoded.toUint64(index);
        index += 8;

        // fromAddress (contract caller)
        message.fromAddress = encoded.toBytes32(index);
        index += 32;

        // mintRecipient (target contract)
        message.mintRecipient = encoded.toBytes32(index);
        index += 32;

        // message payload length
        uint256 payloadLen = encoded.toUint16(index);
        index += 2;

        // parse the additional payload to confirm the entire message was parsed
        message.payload = encoded.slice(index, payloadLen);
        index += payloadLen;

        // confirm that the message payload is the expected length
        require(index == encoded.length, "invalid message length");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

interface IMessageTransmitter {
    event MessageSent(bytes message);

    /**
     * @notice Emitted when tokens are minted
     * @param _mintRecipient recipient address of minted tokens
     * @param _amount amount of minted tokens
     * @param _mintToken contract address of minted token
     */
    event MintAndWithdraw(address _mintRecipient, uint256 _amount, address _mintToken);

    /**
     * @notice Receive a message. Messages with a given nonce
     * can only be broadcast once for a (sourceDomain, destinationDomain)
     * pair. The message body of a valid message is passed to the
     * specified recipient for further processing.
     *
     * @dev Attestation format:
     * A valid attestation is the concatenated 65-byte signature(s) of exactly
     * `thresholdSignature` signatures, in increasing order of attester address.
     * ***If the attester addresses recovered from signatures are not in
     * increasing order, signature verification will fail.***
     * If incorrect number of signatures or duplicate signatures are supplied,
     * signature verification will fail.
     *
     * Message format:
     * Field Bytes Type Index
     * version 4 uint32 0
     * sourceDomain 4 uint32 4
     * destinationDomain 4 uint32 8
     * nonce 8 uint64 12
     * sender 32 bytes32 20
     * recipient 32 bytes32 52
     * messageBody dynamic bytes 84
     * @param _message Message bytes
     * @param _attestation Concatenated 65-byte signature(s) of `_message`, in increasing order
     * of the attester address recovered from signatures.
     * @return success bool, true if successful
     */
    function receiveMessage(bytes memory _message, bytes calldata _attestation) external returns (bool success);

    function attesterManager() external view returns (address);

    function availableNonces(uint32 domain) external view returns (uint64);

    function getNumEnabledAttesters() external view returns (uint256);

    function isEnabledAttester(address _attester) external view returns (bool);

    function localDomain() external view returns (uint32);

    function maxMessageBodySize() external view returns (uint256);

    function owner() external view returns (address);

    function paused() external view returns (bool);

    function pauser() external view returns (address);

    function rescuer() external view returns (address);

    function version() external view returns (uint32);

    // owner only methods
    function transferOwnership(address newOwner) external;

    function updateAttesterManager(address _newAttesterManager) external;

    // attester manager only methods
    function getEnabledAttester(uint256 _index) external view returns (address);

    function disableAttester(address _attester) external;

    function enableAttester(address _attester) external;

    function setSignatureThreshold(uint256 newSignatureThreshold) external;
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

/**
 * @title ITokenMinter
 * @notice interface for minter of tokens that are mintable, burnable, and interchangeable
 * across domains.
 */
interface ITokenMinter {
    function burnLimitsPerMessage(address token) external view returns (uint256);

    function remoteTokensToLocalTokens(bytes32 sourceIdHash) external view returns (address);
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {CircleIntegrationState} from "./CircleIntegrationState.sol";

contract CircleIntegrationSetters is CircleIntegrationState {
    function setInitialized(address implementatiom) internal {
        _state.initializedImplementations[implementatiom] = true;
    }

    function setWormhole(address wormhole_) internal {
        _state.wormhole = payable(wormhole_);
    }

    function setChainId(uint16 chainId_) internal {
        _state.chainId = chainId_;
    }

    function setWormholeFinality(uint8 finality) internal {
        _state.wormholeFinality = finality;
    }

    function setCircleBridge(address circleBridgeAddress_) internal {
        _state.circleBridgeAddress = circleBridgeAddress_;
    }

    function setCircleTransmitter(address circleTransmitterAddress_) internal {
        _state.circleTransmitterAddress = circleTransmitterAddress_;
    }

    function setCircleTokenMinter(address circleTokenMinterAddress_) internal {
        _state.circleTokenMinterAddress = circleTokenMinterAddress_;
    }

    function setEmitter(uint16 chainId_, bytes32 emitter) internal {
        _state.registeredEmitters[chainId_] = emitter;
    }

    function setChainIdToDomain(uint16 chainId_, uint32 domain) internal {
        _state.chainIdToDomain[chainId_] = domain;
    }

    function setDomainToChainId(uint32 domain, uint16 chainId_) internal {
        _state.domainToChainId[domain] = chainId_;
    }

    function consumeMessage(bytes32 hash) internal {
        _state.consumedMessages[hash] = true;
    }

    function setLocalDomain(uint32 domain) internal {
        _state.localDomain = domain;
    }

    function setGovernance(uint16 governanceChainId, bytes32 governanceContract) internal {
        _state.governanceChainId = governanceChainId;
        _state.governanceContract = governanceContract;
    }

    function setEvmChain(uint256 evmChain) internal {
        _state.evmChain = evmChain;
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {IWormhole} from "wormhole/interfaces/IWormhole.sol";
import {ICircleBridge} from "../interfaces/circle/ICircleBridge.sol";
import {IMessageTransmitter} from "../interfaces/circle/IMessageTransmitter.sol";
import {ITokenMinter} from "../interfaces/circle/ITokenMinter.sol";

import {CircleIntegrationSetters} from "./CircleIntegrationSetters.sol";

contract CircleIntegrationGetters is CircleIntegrationSetters {
    /**
     * @notice isInitialized boolean for implementation (logic) contract
     * @param impl Address of implementation contract
     * @return IsInitialized bool
     */
    function isInitialized(address impl) public view returns (bool) {
        return _state.initializedImplementations[impl];
    }

    /**
     * @notice Wormhole contract interface
     * @return IWormhole interface
     */
    function wormhole() public view returns (IWormhole) {
        return IWormhole(_state.wormhole);
    }

    /**
     * @notice Wormhole chain ID of this chain
     * @return chainId uint16
     */
    function chainId() public view returns (uint16) {
        return _state.chainId;
    }

    /**
     * @notice Wormhole message finality
     * @return wormholeFinality uint8
     */
    function wormholeFinality() public view returns (uint8) {
        return _state.wormholeFinality;
    }

    /**
     * @notice Circle Bridge contract interface
     * @return ICircleBridge interface
     */
    function circleBridge() public view returns (ICircleBridge) {
        return ICircleBridge(_state.circleBridgeAddress);
    }

    /**
     * @notice Circle Transmitter contract interface
     * @return ICircleTransmitter interface
     */
    function circleTransmitter() public view returns (IMessageTransmitter) {
        return IMessageTransmitter(_state.circleTransmitterAddress);
    }

    /**
     * @notice Circle Token Minter contract interface
     * @return ITokenMinter interface
     */
    function circleTokenMinter() public view returns (ITokenMinter) {
        return ITokenMinter(_state.circleTokenMinterAddress);
    }

    /**
     * @notice Registered Circle Integration contracts on other blockchains
     * @param emitterChainId Wormhole chain ID for message sender
     * @return RegisteredEmitter bytes32
     */
    function getRegisteredEmitter(uint16 emitterChainId) public view returns (bytes32) {
        return _state.registeredEmitters[emitterChainId];
    }

    /**
     * @notice Circle Bridge registered token boolean
     * @param token Address of token being checked against the Circle TokenMinter
     * @return AcceptedToken bool
     */
    function isAcceptedToken(address token) public view returns (bool) {
        return circleTokenMinter().burnLimitsPerMessage(token) > 0;
    }

    /**
     * @notice Circle domain to Wormhole chain ID
     * @param chainId_ Wormhole chain ID
     * @return CircleDomain uint32
     */
    function getDomainFromChainId(uint16 chainId_) public view returns (uint32) {
        return _state.chainIdToDomain[chainId_];
    }

    /**
     * @notice Wormhole chain ID to Circle domain
     * @param domain Circle domain
     * @return chainId uint16
     */
    function getChainIdFromDomain(uint32 domain) public view returns (uint16) {
        return _state.domainToChainId[domain];
    }

    /**
     * @notice Checks if Wormhole message was already consumed by this contract
     * @param hash Wormhole message hash
     * @return IsMessageConsumed bool
     */
    function isMessageConsumed(bytes32 hash) public view returns (bool) {
        return _state.consumedMessages[hash];
    }

    /**
     * @notice Circle domain on this chain
     * @return LocalDomain uint32
     */
    function localDomain() public view returns (uint32) {
        return _state.localDomain;
    }

    /**
     * @notice Wormhole governance chain ID
     * @return GovernanceChainId uint16
     */
    function governanceChainId() public view returns (uint16) {
        return _state.governanceChainId;
    }

    /**
     * @notice Wormhole governance contract address (zero-left-padded address less than 32 bytes)
     * @return GovernanceContract bytes32
     */
    function governanceContract() public view returns (bytes32) {
        return _state.governanceContract;
    }

    /**
     * @notice EVM chain ID
     * @return EVMChainID uint256
     */
    function evmChain() public view returns (uint256) {
        return _state.evmChain;
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

contract CircleIntegrationStorage {
    struct State {
        /// Wormhole chain ID of this contract
        uint16 chainId;

        /**
         * The number of block confirmations needed before the wormhole network
         * will attest a message.
         */
        uint8 wormholeFinality;

        /// Circle domain for this blockchain (grabbed from Circle's MessageTransmitter)
        uint32 localDomain;

        /// address of the Wormhole contract on this chain
        address wormhole;

        /// Wormhole governance chain ID
        uint16 governanceChainId;

        /// Wormhole governance contract address (bytes32 zero-left-padded)
        bytes32 governanceContract;

        /// address of the Circle Bridge contract on this chain
        address circleBridgeAddress;

        /// address of the Circle Message Transmitter on this chain
        address circleTransmitterAddress;

        /// address of the Circle Token Minter on this chain
        address circleTokenMinterAddress;

        /// mapping of initialized implementation (logic) contracts
        mapping(address => bool) initializedImplementations;

        /// Wormhole chain ID to known emitter address mapping
        mapping(uint16 => bytes32) registeredEmitters;

        /// Wormhole chain ID to Circle chain domain mapping
        mapping(uint16 => uint32) chainIdToDomain;

        /// Wormhole chain ID to Circle chain domain mapping
        mapping(uint32 => uint16) domainToChainId;

        /// verified Wormhole message hash to boolean
        mapping(bytes32 => bool) consumedMessages;

        /// expected EVM chain ID
        uint256 evmChain;

        /// storage gap for additional state variables in future versions
        uint256[50] ______gap;
    }
}

contract CircleIntegrationState {
    CircleIntegrationStorage.State _state;
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.19;

import {IWormhole} from "wormhole/interfaces/IWormhole.sol";
import {ICircleBridge} from "./circle/ICircleBridge.sol";
import {IMessageTransmitter} from "./circle/IMessageTransmitter.sol";

interface ICircleIntegration {
    struct TransferParameters {
        address token;
        uint256 amount;
        uint16 targetChain;
        bytes32 mintRecipient;
    }

    struct RedeemParameters {
        bytes encodedWormholeMessage;
        bytes circleBridgeMessage;
        bytes circleAttestation;
    }

    struct DepositWithPayload {
        bytes32 token;
        uint256 amount;
        uint32 sourceDomain;
        uint32 targetDomain;
        uint64 nonce;
        bytes32 fromAddress;
        bytes32 mintRecipient;
        bytes payload;
    }

    function transferTokensWithPayload(TransferParameters memory transferParams, uint32 batchId, bytes memory payload)
        external
        payable
        returns (uint64 messageSequence);

    function redeemTokensWithPayload(RedeemParameters memory params)
        external
        returns (DepositWithPayload memory depositWithPayload);

    function fetchLocalTokenAddress(uint32 sourceDomain, bytes32 sourceToken)
        external
        view
        returns (bytes32);

    function encodeDepositWithPayload(DepositWithPayload memory message) external pure returns (bytes memory);

    function decodeDepositWithPayload(bytes memory encoded) external pure returns (DepositWithPayload memory message);

    function isInitialized(address impl) external view returns (bool);

    function wormhole() external view returns (IWormhole);

    function chainId() external view returns (uint16);

    function wormholeFinality() external view returns (uint8);

    function circleBridge() external view returns (ICircleBridge);

    function circleTransmitter() external view returns (IMessageTransmitter);

    function getRegisteredEmitter(uint16 emitterChainId) external view returns (bytes32);

    function isAcceptedToken(address token) external view returns (bool);

    function getDomainFromChainId(uint16 chainId_) external view returns (uint32);

    function getChainIdFromDomain(uint32 domain) external view returns (uint16);

    function isMessageConsumed(bytes32 hash) external view returns (bool);

    function localDomain() external view returns (uint32);

    function verifyGovernanceMessage(bytes memory encodedMessage, uint8 action)
        external
        view
        returns (bytes32 messageHash, bytes memory payload);

    function evmChain() external view returns (uint256);

    // guardian governance only
    function updateWormholeFinality(bytes memory encodedMessage) external;

    function registerEmitterAndDomain(bytes memory encodedMessage) external;

    function upgradeContract(bytes memory encodedMessage) external;
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

contract CircleIntegrationStructs {
    struct TransferParameters {
        address token;
        uint256 amount;
        uint16 targetChain;
        bytes32 mintRecipient;
    }

    struct RedeemParameters {
        bytes encodedWormholeMessage;
        bytes circleBridgeMessage;
        bytes circleAttestation;
    }

    struct DepositWithPayload {
        bytes32 token;
        uint256 amount;
        uint32 sourceDomain;
        uint32 targetDomain;
        uint64 nonce;
        bytes32 fromAddress;
        bytes32 mintRecipient;
        bytes payload;
    }
}