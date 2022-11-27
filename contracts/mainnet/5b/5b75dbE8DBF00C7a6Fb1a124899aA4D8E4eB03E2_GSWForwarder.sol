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
pragma solidity >=0.8.17;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IGSWFactory} from "./interfaces/IGSWFactory.sol";
import {IGaslessSmartWallet} from "./interfaces/IGaslessSmartWallet.sol";

/// @title    GSWForwarder
/// @notice   Only compatible with forwarding `cast` calls to GaslessSmartWallet contracts. This is not a generic forwarder.
///           This is NOT a "TrustedForwarder" as proposed in EIP-2770. See notice in GaslessSmartWallet.
/// @dev      Does not validate the EIP712 signature (instead this is done in the Gasless Smart wallet)
contract GSWForwarder {
    using Address for address;

    IGSWFactory public immutable gswFactory;

    constructor(IGSWFactory _gswFactory) {
        gswFactory = _gswFactory;
    }

    /// @notice             Retrieves the current gswNonce of GSW for owner address, which is necessary to sign meta transactions
    /// @param owner        GaslessSmartWallet owner to retrieve the nonoce for. Address who signs a transaction (the signature creator)
    /// @return             returns the gswNonce for the owner necessary to sign a meta transaction
    function gswNonce(address owner) external view returns (uint256) {
        address gswAddress = gswFactory.computeAddress(owner);
        if (gswAddress.isContract()) {
            return IGaslessSmartWallet(gswAddress).gswNonce();
        }

        return 0;
    }

    /// @notice         Computes the deterministic address for owner based on Create2
    /// @param owner    GaslessSmartWallet owner
    /// @return         computed address for the contract
    function computeAddress(address owner) external view returns (address) {
        return gswFactory.computeAddress(owner);
    }

    /// @notice             Deploys GaslessSmartWallet for owner if necessary and calls `cast` on it.
    ///                     This method should be called by relayers.
    /// @param from         GaslessSmartWallet owner who signed the transaction (the signature creator)
    /// @param targets      the targets to execute the actions on
    /// @param datas        the data to be passed to the .call for each target
    /// @param values       the msg.value to be passed to the .call for each target. set to 0 if none
    /// @param signature    the EIP712 signature, should match keccak256(abi.encode(targets, datas, gswNonce, domainSeparatorV4()))
    ///                     see modifier validSignature
    /// @param validUntil   As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                     Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                     have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas          As EIP-2770: an amount of gas limit to set for the execution
    ///                     Protects gainst potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                     See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    function execute(
        address from,
        address[] calldata targets,
        bytes[] calldata datas,
        uint256[] calldata values,
        bytes calldata signature,
        uint256 validUntil,
        uint256 gas
    ) external payable {
        // gswFactory.deploy automatically checks if GSW has to be deployed
        // or if it already exists and simply returns the address in that case
        IGaslessSmartWallet gsw = IGaslessSmartWallet(gswFactory.deploy(from));

        gsw.cast{value: msg.value}(
            targets,
            datas,
            values,
            signature,
            validUntil,
            gas
        );
    }

    /// @notice             Verify the transaction is valid and can be executed.
    ///                     IMPORTANT: Expected to be called via callStatic
    ///                     Does not revert and returns successfully if the input is valid.
    ///                     Reverts if any validation has failed. For instance, if params or either signature or gswNonce are incorrect.
    /// @param from         GaslessSmartWallet owner who signed the transaction (the signature creator)
    /// @param targets      the targets to execute the actions on
    /// @param datas        the data to be passed to the .call for each target
    /// @param values       the msg.value to be passed to the .call for each target. set to 0 if none
    /// @param signature    the EIP712 signature, should match keccak256(abi.encode(targets, datas, gswNonce, domainSeparatorV4()))
    ///                     see modifier validSignature
    /// @param validUntil   As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                     Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                     have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas          As EIP-2770: an amount of gas limit to set for the execution
    ///                     Protects gainst potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                     See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @return             returns true if everything is valid, otherwise reverts
    /// @dev                not marked as view because it does potentially state by deploying the GaslessSmartWallet for "from" if it does not exist yet.
    ///                     Expected to be called via callStatic
    function verify(
        address from,
        address[] calldata targets,
        bytes[] calldata datas,
        uint256[] calldata values,
        bytes calldata signature,
        uint256 validUntil,
        uint256 gas
    ) external returns (bool) {
        // gswFactory.deploy automatically checks if GSW has to be deployed
        // or if it already exists and simply returns the address
        IGaslessSmartWallet gsw = IGaslessSmartWallet(gswFactory.deploy(from));

        return gsw.verify(targets, datas, values, signature, validUntil, gas);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IGaslessSmartWallet {
    function owner() external view returns (address);

    function gswNonce() external view returns (uint256);

    /// @notice             initializer called by factory after EIP-1167 minimal proxy clone deployment
    /// @param _owner       the owner (immutable) of this smart wallet
    function initialize(address _owner) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    /// @return             the bytes32 domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice             Verify the transaction is valid and can be executed.
    ///                     Does not revert and returns successfully if the input is valid.
    ///                     Reverts if any validation has failed. For instance, if params or either signature or gswNonce are incorrect.
    /// @param targets      the targets to execute the actions on
    /// @param datas        the data to be passed to the .call for each target
    /// @param values       the msg.value to be passed to the .call for each target. set to 0 if none
    /// @param signature    the EIP712 signature, should match keccak256(abi.encode(targets, datas, gswNonce, domainSeparatorV4()))
    ///                     see modifier validSignature
    /// @param validUntil   As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                     Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                     have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas          As EIP-2770: an amount of gas limit to set for the execution
    ///                     Protects gainst potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                     See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @return             returns true if everything is valid, otherwise reverts
    function verify(
        address[] calldata targets,
        bytes[] calldata datas,
        uint256[] calldata values,
        bytes calldata signature,
        uint256 validUntil,
        uint256 gas
    ) external view returns (bool);

    /// @notice             executes arbitrary actions according to datas on targets
    ///                     if one action fails, the transaction doesn't revert. Instead the CastFailed event is emitted
    ///                     and no further action is executed. On success, emits CastExecuted event.
    /// @dev                validates EIP712 signature then executes a .call for every action.
    /// @param targets      the targets to execute the actions on
    /// @param datas        the data to be passed to the .call for each target
    /// @param values       the msg.value to be passed to the .call for each target. set to 0 if none
    /// @param signature    the EIP712 signature, should match keccak256(abi.encode(targets, datas, gswNonce, domainSeparatorV4()))
    ///                     see modifier validSignature
    /// @param validUntil   As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                     Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                     have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas          As EIP-2770: an amount of gas limit to set for the execution
    ///                     Protects gainst potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                     See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    function cast(
        address[] calldata targets,
        bytes[] calldata datas,
        uint256[] calldata values,
        bytes calldata signature,
        uint256 validUntil,
        uint256 gas
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IGSWFactory {
    function gswImpl() external view returns (address);

    /// @notice         Computes the deterministic address for owner based on Create2
    /// @param owner    GaslessSmartWallet owner
    /// @return         computed address for the contract
    function computeAddress(address owner) external view returns (address);

    /// @notice         Deploys if necessary or gets the address for a GaslessSmartWallet for a certain owner
    /// @param owner    GaslessSmartWallet owner
    /// @return         deployed address for the contract
    function deploy(address owner) external returns (address);
}