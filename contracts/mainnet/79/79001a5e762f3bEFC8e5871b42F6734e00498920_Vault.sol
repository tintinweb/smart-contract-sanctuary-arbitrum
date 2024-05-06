// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "SafeERC20.sol";
import "IVault.sol";
import "IKeyManager.sol";
import "ICFReceiver.sol";
import "Shared.sol";
import "Deposit.sol";
import "AggKeyNonceConsumer.sol";
import "GovernanceCommunityGuarded.sol";

/**
 * @title    Vault contract
 * @notice   The vault for holding and transferring native or ERC20 tokens and deploying contracts for
 *           fetching individual deposits. It also allows users to do cross-chain swaps and(or) calls by
 *           making a function call directly to this contract.
 */
contract Vault is IVault, AggKeyNonceConsumer, GovernanceCommunityGuarded {
    using SafeERC20 for IERC20;

    uint256 private constant _AGG_KEY_EMERGENCY_TIMEOUT = 3 days;
    uint256 private constant _GAS_TO_FORWARD = 8_000;
    uint256 private constant _FINALIZE_GAS_BUFFER = 30_000;

    constructor(IKeyManager keyManager) AggKeyNonceConsumer(keyManager) {}

    /// @dev   Get the governor address from the KeyManager. This is called by the onlyGovernor
    ///        modifier in the GovernanceCommunityGuarded. This logic can't be moved to the
    ///        GovernanceCommunityGuarded since it requires a reference to the KeyManager.
    function _getGovernor() internal view override returns (address) {
        return getKeyManager().getGovernanceKey();
    }

    /// @dev   Get the community key from the KeyManager. This is called by the isCommunityKey
    ///        modifier in the GovernanceCommunityGuarded. This logic can't be moved to the
    ///        GovernanceCommunityGuarded since it requires a reference to the KeyManager.
    function _getCommunityKey() internal view override returns (address) {
        return getKeyManager().getCommunityKey();
    }

    /// @dev   Ensure that a new keyManager has the getGovernanceKey(), getCommunityKey()
    ///        and getLastValidateTime() are implemented. These are functions required for
    ///        this contract to at least be able to use the emergency mechanism.
    function _checkUpdateKeyManager(IKeyManager keyManager, bool omitChecks) internal view override {
        address newGovKey = keyManager.getGovernanceKey();
        address newCommKey = keyManager.getCommunityKey();
        uint256 lastValidateTime = keyManager.getLastValidateTime();

        if (!omitChecks) {
            // Ensure that the keys are the same
            require(newGovKey == _getGovernor() && newCommKey == _getCommunityKey());

            Key memory newAggKey = keyManager.getAggregateKey();
            Key memory currentAggKey = getKeyManager().getAggregateKey();

            require(
                newAggKey.pubKeyX == currentAggKey.pubKeyX && newAggKey.pubKeyYParity == currentAggKey.pubKeyYParity
            );

            // Ensure that the last validate time is not in the future
            require(lastValidateTime <= block.timestamp);
        } else {
            // Check that the addresses have been initialized
            require(newGovKey != address(0) && newCommKey != address(0));
        }
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  Transfer and Fetch                      //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Can do a combination of all fcns in this contract. It first fetches all
     *          deposits , then it performs all transfers specified with the rest
     *          of the inputs, the same as transferBatch (where all inputs are again required
     *          to be of equal length - however the lengths of the fetch inputs do not have to
     *          be equal to lengths of the transfer inputs). Fetches/transfers of native tokens are
     *          indicated with 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE as the token address.
     * @dev     FetchAndDeploy is executed first to handle the edge case , which probably shouldn't
     *          happen anyway, where a deploy and a fetch for the same address are in the same batch.
     *          Transfers are executed last to ensure that all fetching has been completed first.
     * @param sigData    Struct containing the signature data over the message
     *                   to verify, signed by the aggregate key.
     * @param deployFetchParamsArray    The array of deploy and fetch parameters
     * @param fetchParamsArray    The array of fetch parameters
     * @param transferParamsArray The array of transfer parameters
     */
    function allBatch(
        SigData calldata sigData,
        DeployFetchParams[] calldata deployFetchParamsArray,
        FetchParams[] calldata fetchParamsArray,
        TransferParams[] calldata transferParamsArray
    )
        external
        override
        onlyNotSuspended
        consumesKeyNonce(
            sigData,
            keccak256(abi.encode(this.allBatch.selector, deployFetchParamsArray, fetchParamsArray, transferParamsArray))
        )
    {
        // Fetch by deploying new deposits
        _deployAndFetchBatch(deployFetchParamsArray);

        // Fetch from already deployed deposits
        _fetchBatch(fetchParamsArray);

        // Send all transfers
        _transferBatch(transferParamsArray);
    }

    /**
     * @notice  Same functionality as allBatch but removing the contract deployments
     * @param sigData    Struct containing the signature data over the message
     *                   to verify, signed by the aggregate key.
     * @param fetchParamsArray    The array of fetch parameters
     * @param transferParamsArray The array of transfer parameters
     */
    function allBatchV2(
        SigData calldata sigData,
        FetchParams[] calldata fetchParamsArray,
        TransferParams[] calldata transferParamsArray
    )
        external
        override
        onlyNotSuspended
        consumesKeyNonce(
            sigData,
            keccak256(abi.encode(this.allBatchV2.selector, fetchParamsArray, transferParamsArray))
        )
    {
        // Fetch from already deployed deposits
        _fetchBatch(fetchParamsArray);

        // Send all transfers
        _transferBatch(transferParamsArray);
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Transfers                       //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Transfers native tokens or a ERC20 token from this vault to a recipient
     * @param sigData    Struct containing the signature data over the message
     *                   to verify, signed by the aggregate key.
     * @param transferParams       The transfer parameters
     */
    function transfer(
        SigData calldata sigData,
        TransferParams calldata transferParams
    )
        external
        override
        onlyNotSuspended
        nzAddr(transferParams.token)
        nzAddr(transferParams.recipient)
        nzUint(transferParams.amount)
        consumesKeyNonce(sigData, keccak256(abi.encode(this.transfer.selector, transferParams)))
    {
        _transfer(transferParams.token, transferParams.recipient, transferParams.amount);
    }

    /**
     * @notice  Fallback transfer tokens from this vault to a recipient with all the gas.
     * @param sigData    Struct containing the signature data over the message
     *                   to verify, signed by the aggregate key.
     * @param transferParams  The transfer parameters

     */
    function transferFallback(
        SigData calldata sigData,
        TransferParams calldata transferParams
    )
        external
        override
        onlyNotSuspended
        nzAddr(transferParams.token)
        nzAddr(transferParams.recipient)
        nzUint(transferParams.amount)
        consumesKeyNonce(sigData, keccak256(abi.encode(this.transferFallback.selector, transferParams)))
    {
        if (transferParams.token == _NATIVE_ADDR) {
            (bool success, ) = transferParams.recipient.call{value: transferParams.amount}("");
            require(success, "Vault: transfer fallback failed");
        } else {
            IERC20(transferParams.token).safeTransfer(transferParams.recipient, transferParams.amount);
        }
    }

    /**
     * @notice  Transfers native tokens or ERC20 tokens from this vault to recipients.
     * @param sigData    Struct containing the signature data over the message
     *                   to verify, signed by the aggregate key.
     * @param transferParamsArray The array of transfer parameters.
     */
    function transferBatch(
        SigData calldata sigData,
        TransferParams[] calldata transferParamsArray
    )
        external
        override
        onlyNotSuspended
        consumesKeyNonce(sigData, keccak256(abi.encode(this.transferBatch.selector, transferParamsArray)))
    {
        _transferBatch(transferParamsArray);
    }

    /**
     * @notice  Transfers native tokens or ERC20 tokens from this vault to recipients.
     * @param transferParamsArray The array of transfer parameters.
     */
    function _transferBatch(TransferParams[] calldata transferParamsArray) private {
        uint256 length = transferParamsArray.length;
        for (uint256 i = 0; i < length; ) {
            _transfer(transferParamsArray[i].token, transferParamsArray[i].recipient, transferParamsArray[i].amount);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice  Transfers ETH or a token from this vault to a recipient
     * @dev     When transfering native tokens, using call function limiting the amount of gas so
     *          the receivers can't consume all the gas. Setting that amount of gas to more than
     *          2300 to future-proof the contract in case of opcode gas costs changing.
     * @dev     When transferring ERC20 tokens, if it fails ensure the transfer fails gracefully
     *          to not revert an entire batch. e.g. usdc blacklisted recipient. Following safeTransfer
     *          approach to support tokens that don't return a bool.
     * @param token The address of the token to be transferred
     * @param recipient The address of the recipient of the transfer
     * @param amount    The amount to transfer, in wei (uint)
     */
    function _transfer(address token, address payable recipient, uint256 amount) private {
        if (address(token) == _NATIVE_ADDR) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = recipient.call{gas: _GAS_TO_FORWARD, value: amount}("");
            if (!success) {
                emit TransferNativeFailed(recipient, amount);
            }
        } else {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returndata) = token.call(
                abi.encodeWithSelector(IERC20(token).transfer.selector, recipient, amount)
            );

            // No need to check token.code.length since it comes from a gated call
            bool transferred = success && (returndata.length == uint256(0) || abi.decode(returndata, (bool)));
            if (!transferred) emit TransferTokenFailed(recipient, amount, token, returndata);
        }
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Fetch Deposits                    //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Retrieves any token from multiple address, deterministically generated using
     *          create2, by creating a contract for that address, sending it to this vault.
     * @param sigData    Struct containing the signature data over the message
     *                   to verify, signed by the aggregate key.
     * @param deployFetchParamsArray    The array of deploy and fetch parameters
     */
    function deployAndFetchBatch(
        SigData calldata sigData,
        DeployFetchParams[] calldata deployFetchParamsArray
    )
        external
        override
        onlyNotSuspended
        consumesKeyNonce(sigData, keccak256(abi.encode(this.deployAndFetchBatch.selector, deployFetchParamsArray)))
    {
        _deployAndFetchBatch(deployFetchParamsArray);
    }

    function _deployAndFetchBatch(DeployFetchParams[] calldata deployFetchParamsArray) private {
        // Deploy deposit contracts
        uint256 length = deployFetchParamsArray.length;
        for (uint256 i = 0; i < length; ) {
            new Deposit{salt: deployFetchParamsArray[i].swapID}(deployFetchParamsArray[i].token);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice  Retrieves any token addresses where a Deposit contract is already deployed.
     * @param sigData    Struct containing the signature data over the message
     *                   to verify, signed by the aggregate key.
     * @param fetchParamsArray    The array of fetch parameters
     */
    function fetchBatch(
        SigData calldata sigData,
        FetchParams[] calldata fetchParamsArray
    )
        external
        override
        onlyNotSuspended
        consumesKeyNonce(sigData, keccak256(abi.encode(this.fetchBatch.selector, fetchParamsArray)))
    {
        _fetchBatch(fetchParamsArray);
    }

    /**
     * @notice  Retrieves any token from multiple addresses where a Deposit contract is already deployed.
     *          It emits an event if the fetch fails.
     * @param fetchParamsArray    The array of fetch parameters
     */
    function _fetchBatch(FetchParams[] calldata fetchParamsArray) private {
        uint256 length = fetchParamsArray.length;
        for (uint256 i = 0; i < length; ) {
            Deposit(fetchParamsArray[i].fetchContract).fetch(fetchParamsArray[i].token);
            unchecked {
                ++i;
            }
        }
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //         Initiate cross-chain swaps (source chain)        //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Swaps native token for a token in another chain. The egress token will be transferred to the specified
     *          destination address on the destination chain.
     * @dev     Checking the validity of inputs shall be done as part of the event witnessing. Only the amount is checked
     *          to explicity indicate that an amount is required.  It isn't preventing spamming.
     * @param dstChain      The destination chain according to the Chainflip Protocol's nomenclature.
     * @param dstAddress    Bytes containing the destination address on the destination chain.
     * @param dstToken      Destination token to be swapped to.
     * @param cfParameters  Additional parameters to be passed to the Chainflip protocol.
     */
    function xSwapNative(
        uint32 dstChain,
        bytes memory dstAddress,
        uint32 dstToken,
        bytes calldata cfParameters
    ) external payable override onlyNotSuspended nzUint(msg.value) {
        emit SwapNative(dstChain, dstAddress, dstToken, msg.value, msg.sender, cfParameters);
    }

    /**
     * @notice  Swaps ERC20 token for a token in another chain. The desired token will be transferred to the specified
     *          destination address on the destination chain. The provided ERC20 token must be supported by the Chainflip Protocol.
     * @dev     Checking the validity of inputs shall be done as part of the event witnessing. Only the amount is checked
     *          to explicity indicate that an amount is required.
     * @param dstChain      The destination chain according to the Chainflip Protocol's nomenclature.
     * @param dstAddress    Bytes containing the destination address on the destination chain.
     * @param dstToken      Uint containing the specifics of the swap to be performed according to Chainflip's nomenclature.
     * @param srcToken      Address of the source token to swap.
     * @param amount        Amount of tokens to swap.
     * @param cfParameters  Additional parameters to be passed to the Chainflip protocol.
     */
    function xSwapToken(
        uint32 dstChain,
        bytes memory dstAddress,
        uint32 dstToken,
        IERC20 srcToken,
        uint256 amount,
        bytes calldata cfParameters
    ) external override onlyNotSuspended nzUint(amount) {
        srcToken.safeTransferFrom(msg.sender, address(this), amount);
        emit SwapToken(dstChain, dstAddress, dstToken, address(srcToken), amount, msg.sender, cfParameters);
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //     Initiate cross-chain call and swap (source chain)    //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Performs a cross-chain call to the destination address on the destination chain. Native tokens must be paid
     *          to this contract. The swap intent determines if the provided tokens should be swapped to a different token
     *          and transferred as part of the cross-chain call. Otherwise, all tokens are used as a payment for gas on the destination chain.
     *          The message parameter is transmitted to the destination chain as part of the cross-chain call.
     * @dev     Checking the validity of inputs shall be done as part of the event witnessing. Only the amount is checked
     *          to explicity inidcate that an amount is required. It isn't preventing spamming.
     * @param dstChain      The destination chain according to the Chainflip Protocol's nomenclature.
     * @param dstAddress    Bytes containing the destination address on the destination chain.
     * @param dstToken      Uint containing the specifics of the swap to be performed, if any, as part of the xCall. The string
     *                      must follow Chainflip's nomenclature. It can signal that no swap needs to take place
     *                      and the source token will be used for gas in a swapless xCall.
     * @param message       General purpose message to be sent to the egress chain. Notice that the Chainflip protocol has a limit size
     *                      for the message. Ensure that the message length is smaller that the limit before starting a swap.
     * @param gasAmount     The amount to be used for gas in the egress chain.
     * @param cfParameters  Additional parameters to be passed to the Chainflip protocol.
     */
    function xCallNative(
        uint32 dstChain,
        bytes calldata dstAddress,
        uint32 dstToken,
        bytes calldata message,
        uint256 gasAmount,
        bytes calldata cfParameters
    ) external payable override onlyNotSuspended nzUint(msg.value) {
        emit XCallNative(dstChain, dstAddress, dstToken, msg.value, msg.sender, message, gasAmount, cfParameters);
    }

    /**
     * @notice  Performs a cross-chain call to the destination chain and destination address. An ERC20 token amount
     *          needs to be approved to this contract. The ERC20 token must be supported by the Chainflip Protocol.
     *          The swap intent determines whether the provided tokens should be swapped to a different token
     *          by the Chainflip Protocol. If so, the swapped tokens will be transferred to the destination chain as part
     *          of the cross-chain call. Otherwise, the tokens are used as a payment for gas on the destination chain.
     *          The message parameter is transmitted to the destination chain as part of the cross-chain call.
     * @dev     Checking the validity of inputs shall be done as part of the event witnessing. Only the amount is checked
     *          to explicity indicate that an amount is required.
     * @param dstChain      The destination chain according to the Chainflip Protocol's nomenclature.
     * @param dstAddress    Bytes containing the destination address on the destination chain.
     * @param dstToken      Uint containing the specifics of the swap to be performed, if any, as part of the xCall. The string
     *                      must follow Chainflip's nomenclature. It can signal that no swap needs to take place
     *                      and the source token will be used for gas in a swapless xCall.
     * @param message       General purpose message to be sent to the egress chain. Notice that the Chainflip protocol has a limit size
     *                      for the message. Ensure that the message length is smaller that the limit before starting a swap.
     * @param gasAmount     The amount to be used for gas in the egress chain.
     * @param srcToken      Address of the source token.
     * @param amount        Amount of tokens to swap.
     * @param cfParameters  Additional parameters to be passed to the Chainflip protocol.
     */
    function xCallToken(
        uint32 dstChain,
        bytes memory dstAddress,
        uint32 dstToken,
        bytes calldata message,
        uint256 gasAmount,
        IERC20 srcToken,
        uint256 amount,
        bytes calldata cfParameters
    ) external override onlyNotSuspended nzUint(amount) {
        srcToken.safeTransferFrom(msg.sender, address(this), amount);
        emit XCallToken(
            dstChain,
            dstAddress,
            dstToken,
            address(srcToken),
            amount,
            msg.sender,
            message,
            gasAmount,
            cfParameters
        );
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                     Gas topups                           //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Add gas (topup) to an existing cross-chain call with the unique identifier swapID.
     *          Native tokens must be paid to this contract as part of the call.
     * @param swapID    The unique identifier for this swap (bytes32)
     */
    function addGasNative(bytes32 swapID) external payable override onlyNotSuspended nzUint(msg.value) {
        emit AddGasNative(swapID, msg.value);
    }

    /**
     * @notice  Add gas (topup) to an existing cross-chain call with the unique identifier swapID.
     *          A Chainflip supported token must be paid to this contract as part of the call.
     * @param swapID    The unique identifier for this swap (bytes32)
     * @param token     Address of the token to provide.
     * @param amount    Amount of tokens to provide.
     */
    function addGasToken(
        bytes32 swapID,
        uint256 amount,
        IERC20 token
    ) external override onlyNotSuspended nzUint(amount) {
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit AddGasToken(swapID, amount, address(token));
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //      Execute cross-chain call and swap (dest. chain)     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Transfers native tokens or an ERC20 token from this vault to a recipient and makes a function
     *          call completing a cross-chain swap and call. The ICFReceiver interface is expected on
     *          the receiver's address. A message is passed to the receiver along with other
     *          parameters specifying the origin of the swap.
     * @dev     Not checking nzUint(amount) to prevent reversions in edge cases (e.g. all input amount used for gas).
     * @param sigData    Struct containing the signature data over the message
     *                   to verify, signed by the aggregate key.
     * @param transferParams  The transfer parameters
     * @param srcChain        The source chain where the call originated from.
     * @param srcAddress      The address where the transfer originated within the ingress chain.
     * @param message         The message to be passed to the recipient.
     */
    function executexSwapAndCall(
        SigData calldata sigData,
        TransferParams calldata transferParams,
        uint32 srcChain,
        bytes calldata srcAddress,
        bytes calldata message
    )
        external
        override
        onlyNotSuspended
        nzAddr(transferParams.token)
        nzAddr(transferParams.recipient)
        consumesKeyNonce(
            sigData,
            keccak256(abi.encode(this.executexSwapAndCall.selector, transferParams, srcChain, srcAddress, message))
        )
    {
        // Logic in another internal function to avoid the stackTooDeep error
        _executexSwapAndCall(transferParams, srcChain, srcAddress, message);
    }

    /**
     * @notice Logic for transferring the tokens and calling the recipient. It's on the receiver to
     *         make sure the call doesn't revert, otherwise the tokens won't be transferred.
     *         The _transfer function is not used because we want to be able to embed the native token
     *         into the cfReceive call to avoid doing two external calls.
     *         In case of revertion the tokens will remain in the Vault. Therefore, the destination
     *         contract must ensure it doesn't revert e.g. using try-catch mechanisms.
     * @dev    In the case of the ERC20 transfer reverting, not handling the error to allow for tx replay.
     *         Also, to ensure the cfReceive call is made only if the transfer is successful.
     */
    function _executexSwapAndCall(
        TransferParams calldata transferParams,
        uint32 srcChain,
        bytes calldata srcAddress,
        bytes calldata message
    ) private {
        uint256 nativeAmount;

        if (transferParams.amount > 0) {
            if (transferParams.token == _NATIVE_ADDR) {
                nativeAmount = transferParams.amount;
            } else {
                IERC20(transferParams.token).safeTransfer(transferParams.recipient, transferParams.amount);
            }
        }

        ICFReceiver(transferParams.recipient).cfReceive{value: nativeAmount}(
            srcChain,
            srcAddress,
            message,
            transferParams.token,
            transferParams.amount
        );
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //          Execute cross-chain call (dest. chain)          //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Executes a cross-chain function call. The ICFReceiver interface is expected on
     *          the receiver's address. A message is passed to the receiver along with other
     *          parameters specifying the origin of the swap. This is used for cross-chain messaging
     *          without any swap taking place on the Chainflip Protocol.
     * @param sigData    Struct containing the signature data over the message
     *                   to verify, signed by the aggregate key.
     * @param srcChain       The source chain where the call originated from.
     * @param srcAddress     The address where the transfer originated from in the ingressParams.
     * @param message        The message to be passed to the recipient.
     */
    function executexCall(
        SigData calldata sigData,
        address recipient,
        uint32 srcChain,
        bytes calldata srcAddress,
        bytes calldata message
    )
        external
        override
        onlyNotSuspended
        nzAddr(recipient)
        consumesKeyNonce(
            sigData,
            keccak256(abi.encode(this.executexCall.selector, recipient, srcChain, srcAddress, message))
        )
    {
        ICFReceiver(recipient).cfReceivexCall(srcChain, srcAddress, message);
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                 Auxiliary chain actions                  //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Transfer funds and pass calldata to be executed on a Multicall contract.
     * @dev     For safety purposes it's preferred to execute calldata externally with
     *          a limited amount of funds instead of executing arbitrary calldata here.
     * @dev     Calls are not reverted upon Multicall.run() failure so the nonce gets consumed. The 
     *          gasMulticall parameters is needed to prevent an insufficient gas griefing attack. 
     *          The _GAS_BUFFER is a conservative estimation of the gas required to finalize the call.
     * @param sigData         Struct containing the signature data over the message
     *                        to verify, signed by the aggregate key.
     * @param transferParams  The transfer parameters inluding the token and amount to be transferred
     *                        and the multicall contract address.
     * @param calls           Array of actions to be executed.
     * @param gasMulticall    Gas that must be forwarded to the multicall.

     */
    function executeActions(
        SigData calldata sigData,
        TransferParams calldata transferParams,
        IMulticall.Call[] calldata calls,
        uint256 gasMulticall
    )
        external
        override
        onlyNotSuspended
        consumesKeyNonce(
            sigData,
            keccak256(abi.encode(this.executeActions.selector, transferParams, calls, gasMulticall))
        )
    {
        // Fund and run multicall
        uint256 valueToSend;

        if (transferParams.amount > 0) {
            if (transferParams.token == _NATIVE_ADDR) {
                valueToSend = transferParams.amount;
            } else {
                IERC20(transferParams.token).approve(transferParams.recipient, transferParams.amount);
            }
        }

        // Ensure that the amount of gas supplied to the call to the Multicall contract is at least the gas
        // limit specified. We can do this by enforcing that we still have gasMulticall + gas buffer available.
        // The gas buffer is to ensure there is enough gas to finalize the call, including a safety margin.
        // The 63/64 rule specified in EIP-150 needs to be taken into account.
        require(gasleft() >= ((gasMulticall + _FINALIZE_GAS_BUFFER) * 64) / 63, "Vault: insufficient gas");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory reason) = transferParams.recipient.call{
            gas: gasleft() - _FINALIZE_GAS_BUFFER,
            value: valueToSend
        }(abi.encodeWithSelector(IMulticall.run.selector, calls, transferParams.token, transferParams.amount));

        if (!success) {
            if (transferParams.amount > 0 && transferParams.token != _NATIVE_ADDR) {
                IERC20(transferParams.token).approve(transferParams.recipient, 0);
            }
            emit ExecuteActionsFailed(transferParams.recipient, transferParams.amount, transferParams.token, reason);
        } else {
            require(transferParams.recipient.code.length > 0);
        }
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Governance                        //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice Withdraw all funds to governance address in case of emergency. This withdrawal needs
     *         to be approved by the Community and it can only be executed if no nonce from the
     *         current AggKey had been consumed in _AGG_KEY_TIMEOUT time. It is a last resort and
     *         can be used to rectify an emergency.
     * @param tokens    The addresses of the tokens to be transferred
     */
    function govWithdraw(
        address[] calldata tokens
    ) external override onlyGovernor onlyCommunityGuardDisabled onlySuspended timeoutEmergency {
        // Could use msg.sender or getGovernor() but hardcoding the get call just for extra safety
        address payable recipient = payable(getKeyManager().getGovernanceKey());

        // Transfer all native tokens and ERC20 Tokens
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _NATIVE_ADDR) {
                _transfer(_NATIVE_ADDR, recipient, address(this).balance);
            } else {
                _transfer(tokens[i], recipient, IERC20(tokens[i]).balanceOf(address(this)));
            }
        }
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Modifiers                       //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /// @dev    Check that no nonce has been consumed in the last 3 days - emergency
    modifier timeoutEmergency() {
        require(
            block.timestamp - getKeyManager().getLastValidateTime() >= _AGG_KEY_EMERGENCY_TIMEOUT,
            "Vault: not enough time"
        );
        _;
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Fallbacks                       //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /// @dev For receiving native tokens from the Deposit contracts
    receive() external payable {
        emit FetchedNative(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "draft-IERC20Permit.sol";
import "Address.sol";

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IAggKeyNonceConsumer.sol";
import "IGovernanceCommunityGuarded.sol";
import "IMulticall.sol";

/**
 * @title    Vault interface
 * @notice   The interface for functions Vault implements
 */
interface IVault is IGovernanceCommunityGuarded, IAggKeyNonceConsumer {
    event FetchedNative(address indexed sender, uint256 amount);

    event TransferNativeFailed(address payable indexed recipient, uint256 amount);
    event TransferTokenFailed(address payable indexed recipient, uint256 amount, address indexed token, bytes reason);

    event SwapNative(
        uint32 dstChain,
        bytes dstAddress,
        uint32 dstToken,
        uint256 amount,
        address indexed sender,
        bytes cfParameters
    );
    event SwapToken(
        uint32 dstChain,
        bytes dstAddress,
        uint32 dstToken,
        address srcToken,
        uint256 amount,
        address indexed sender,
        bytes cfParameters
    );

    /// @dev bytes parameters is not indexed because indexing a dynamic type for it to be filtered
    ///      makes it so we won't be able to decode it unless we specifically search for it. If we want
    ///      to filter it and decode it then we would need to have both the indexed and the non-indexed
    ///      version in the event. That is unnecessary.
    event XCallNative(
        uint32 dstChain,
        bytes dstAddress,
        uint32 dstToken,
        uint256 amount,
        address indexed sender,
        bytes message,
        uint256 gasAmount,
        bytes cfParameters
    );
    event XCallToken(
        uint32 dstChain,
        bytes dstAddress,
        uint32 dstToken,
        address srcToken,
        uint256 amount,
        address indexed sender,
        bytes message,
        uint256 gasAmount,
        bytes cfParameters
    );

    event AddGasNative(bytes32 swapID, uint256 amount);
    event AddGasToken(bytes32 swapID, uint256 amount, address token);

    event ExecuteActionsFailed(
        address payable indexed multicallAddress,
        uint256 amount,
        address indexed token,
        bytes reason
    );

    function allBatch(
        SigData calldata sigData,
        DeployFetchParams[] calldata deployFetchParamsArray,
        FetchParams[] calldata fetchParamsArray,
        TransferParams[] calldata transferParamsArray
    ) external;

    function allBatchV2(
        SigData calldata sigData,
        FetchParams[] calldata fetchParamsArray,
        TransferParams[] calldata transferParamsArray
    ) external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Transfers                       //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function transfer(SigData calldata sigData, TransferParams calldata transferParams) external;

    function transferFallback(SigData calldata sigData, TransferParams calldata transferParams) external;

    function transferBatch(SigData calldata sigData, TransferParams[] calldata transferParamsArray) external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Fetch Deposits                    //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function deployAndFetchBatch(
        SigData calldata sigData,
        DeployFetchParams[] calldata deployFetchParamsArray
    ) external;

    function fetchBatch(SigData calldata sigData, FetchParams[] calldata fetchParamsArray) external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //         Initiate cross-chain swaps (source chain)        //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function xSwapToken(
        uint32 dstChain,
        bytes calldata dstAddress,
        uint32 dstToken,
        IERC20 srcToken,
        uint256 amount,
        bytes calldata cfParameters
    ) external;

    function xSwapNative(
        uint32 dstChain,
        bytes calldata dstAddress,
        uint32 dstToken,
        bytes calldata cfParameters
    ) external payable;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //     Initiate cross-chain call and swap (source chain)    //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function xCallNative(
        uint32 dstChain,
        bytes calldata dstAddress,
        uint32 dstToken,
        bytes calldata message,
        uint256 gasAmount,
        bytes calldata cfParameters
    ) external payable;

    function xCallToken(
        uint32 dstChain,
        bytes calldata dstAddress,
        uint32 dstToken,
        bytes calldata message,
        uint256 gasAmount,
        IERC20 srcToken,
        uint256 amount,
        bytes calldata cfParameters
    ) external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                     Gas topups                           //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function addGasNative(bytes32 swapID) external payable;

    function addGasToken(bytes32 swapID, uint256 amount, IERC20 token) external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //      Execute cross-chain call and swap (dest. chain)     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function executexSwapAndCall(
        SigData calldata sigData,
        TransferParams calldata transferParams,
        uint32 srcChain,
        bytes calldata srcAddress,
        bytes calldata message
    ) external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //          Execute cross-chain call (dest. chain)          //
    //                                                          //
    //////////////////////////////////////////////////////////////
    function executexCall(
        SigData calldata sigData,
        address recipient,
        uint32 srcChain,
        bytes calldata srcAddress,
        bytes calldata message
    ) external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                 Auxiliary chain actions                  //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function executeActions(
        SigData calldata sigData,
        TransferParams calldata transferParams,
        IMulticall.Call[] calldata calls,
        uint256 gasMulticall
    ) external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Governance                        //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function govWithdraw(address[] calldata tokens) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IShared.sol";
import "IKeyManager.sol";

/**
 * @title    AggKeyNonceConsumer interface
 */

interface IAggKeyNonceConsumer is IShared {
    event UpdatedKeyManager(address keyManager);

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  State-changing functions                //
    //                                                          //
    //////////////////////////////////////////////////////////////
    /**
     * @notice  Update KeyManager reference. Used if KeyManager contract is updated
     * @param sigData    Struct containing the signature data over the message
     *                   to verify, signed by the aggregate key.
     * @param keyManager New KeyManager's address
     * @param omitChecks Allow the omission of the extra checks in a special case
     */
    function updateKeyManager(SigData calldata sigData, IKeyManager keyManager, bool omitChecks) external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Get the KeyManager address/interface that's used to validate sigs
     * @return  The KeyManager (IKeyManager)
     */
    function getKeyManager() external view returns (IKeyManager);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "IERC20.sol";

/**
 * @title    Shared interface
 * @notice   Holds structs needed by other interfaces
 */
interface IShared {
    /**
     * @dev  SchnorrSECP256K1 requires that each key has a public key part (x coordinate),
     *       a parity for the y coordinate (0 if the y ordinate of the public key is even, 1
     *       if it's odd)
     */
    struct Key {
        uint256 pubKeyX;
        uint8 pubKeyYParity;
    }

    /**
     * @dev  Contains a signature and the nonce used to create it. Also the recovered address
     *       to check that the signature is valid
     */
    struct SigData {
        uint256 sig;
        uint256 nonce;
        address kTimesGAddress;
    }

    /**
     * @param token The address of the token to be transferred
     * @param recipient The address of the recipient of the transfer
     * @param amount    The amount to transfer, in wei (uint)
     */
    struct TransferParams {
        address token;
        address payable recipient;
        uint256 amount;
    }

    /**
     * @param swapID    The unique identifier for this swap (bytes32), used for create2
     * @param token     The token to be transferred
     */
    struct DeployFetchParams {
        bytes32 swapID;
        address token;
    }

    /**
     * @param fetchContract   The address of the deployed Deposit contract
     * @param token     The token to be transferred
     */
    struct FetchParams {
        address payable fetchContract;
        address token;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IShared.sol";

/**
 * @title    KeyManager interface
 * @notice   The interface for functions KeyManager implements
 */
interface IKeyManager is IShared {
    event AggKeySetByAggKey(Key oldAggKey, Key newAggKey);
    event AggKeySetByGovKey(Key oldAggKey, Key newAggKey);
    event GovKeySetByAggKey(address oldGovKey, address newGovKey);
    event GovKeySetByGovKey(address oldGovKey, address newGovKey);
    event CommKeySetByAggKey(address oldCommKey, address newCommKey);
    event CommKeySetByCommKey(address oldCommKey, address newCommKey);
    event SignatureAccepted(SigData sigData, address signer);
    event GovernanceAction(bytes32 message);

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  State-changing functions                //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function consumeKeyNonce(SigData memory sigData, bytes32 contractMsgHash) external;

    function setAggKeyWithAggKey(SigData memory sigData, Key memory newAggKey) external;

    function setAggKeyWithGovKey(Key memory newAggKey) external;

    function setGovKeyWithAggKey(SigData calldata sigData, address newGovKey) external;

    function setGovKeyWithGovKey(address newGovKey) external;

    function setCommKeyWithAggKey(SigData calldata sigData, address newCommKey) external;

    function setCommKeyWithCommKey(address newCommKey) external;

    function govAction(bytes32 message) external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  Non-state-changing functions            //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function getAggregateKey() external view returns (Key memory);

    function getGovernanceKey() external view returns (address);

    function getCommunityKey() external view returns (address);

    function isNonceUsedByAggKey(uint256 nonce) external view returns (bool);

    function getLastValidateTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IShared.sol";

/**
 * @title    GovernanceCommunityGuarded interface
 */

interface IGovernanceCommunityGuarded is IShared {
    event CommunityGuardDisabled(bool communityGuardDisabled);
    event Suspended(bool suspended);

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  State-changing functions                //
    //                                                          //
    //////////////////////////////////////////////////////////////
    /**
     * @notice  Enable Community Guard
     */

    function enableCommunityGuard() external;

    /**
     * @notice  Disable Community Guard
     */
    function disableCommunityGuard() external;

    /**
     * @notice  Can be used to suspend contract execution - only executable by
     *          governance and only to be used in case of emergency.
     */
    function suspend() external;

    /**
     * @notice      Resume contract execution
     */
    function resume() external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Get the Community Key
     * @return  The CommunityKey
     */
    function getCommunityKey() external view returns (address);

    /**
     * @notice  Get the Community Guard state
     * @return  The Community Guard state
     */
    function getCommunityGuardDisabled() external view returns (bool);

    /**
     * @notice  Get suspended state
     * @return  The suspended state
     */
    function getSuspendedState() external view returns (bool);

    /**
     * @notice  Get governor address
     * @return  The governor address
     */
    function getGovernor() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMulticall {
    enum CallType {
        Default,
        FullTokenBalance,
        FullNativeBalance,
        CollectTokenBalance
    }

    struct Call {
        CallType callType;
        address target;
        uint256 value;
        bytes callData;
        bytes payload;
    }

    error AlreadyRunning();
    error CallFailed(uint256 callPosition, bytes reason);

    function run(Call[] calldata calls, address tokenIn, uint256 amountIn) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title    CF Receiver interface
 * @dev      The ICFReceiver interface is the interface required to receive tokens and
 *           cross-chain calls from the Chainflip Protocol.
 */
interface ICFReceiver {
    /**
     * @notice  Receiver of a cross-chain swap and call made by the Chainflip Protocol.

     * @param srcChain      The source chain according to the Chainflip Protocol's nomenclature.
     * @param srcAddress    Bytes containing the source address on the source chain.
     * @param message       The message sent on the source chain. This is a general purpose message.
     * @param token         Address of the token received. _NATIVE_ADDR if it's native tokens.
     * @param amount        Amount of tokens received. This will match msg.value for native tokens.
     */
    function cfReceive(
        uint32 srcChain,
        bytes calldata srcAddress,
        bytes calldata message,
        address token,
        uint256 amount
    ) external payable;

    /**
     * @notice  Receiver of a cross-chain call made by the Chainflip Protocol.

     * @param srcChain      The source chain according to the Chainflip Protocol's nomenclature.
     * @param srcAddress    Bytes containing the source address on the source chain.
     * @param message       The message sent on the source chain. This is a general purpose message.
     */
    function cfReceivexCall(uint32 srcChain, bytes calldata srcAddress, bytes calldata message) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IShared.sol";

/**
 * @title    Shared contract
 * @notice   Holds constants and modifiers that are used in multiple contracts
 * @dev      It would be nice if this could be a library, but modifiers can't be exported :(
 */

abstract contract Shared is IShared {
    /// @dev The address used to indicate whether transfer should send native or a token
    address internal constant _NATIVE_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant _ZERO_ADDR = address(0);
    bytes32 internal constant _NULL = "";
    uint256 internal constant _E_18 = 1e18;

    /// @dev    Checks that a uint isn't zero/empty
    modifier nzUint(uint256 u) {
        require(u != 0, "Shared: uint input is empty");
        _;
    }

    /// @dev    Checks that an address isn't zero/empty
    modifier nzAddr(address a) {
        require(a != _ZERO_ADDR, "Shared: address input is empty");
        _;
    }

    /// @dev    Checks that a bytes32 isn't zero/empty
    modifier nzBytes32(bytes32 b) {
        require(b != _NULL, "Shared: bytes32 input is empty");
        _;
    }

    /// @dev    Checks that the pubKeyX is populated
    modifier nzKey(Key memory key) {
        require(key.pubKeyX != 0, "Shared: pubKeyX is empty");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20Lite.sol";

/**
 * @title    Deposit contract
 * @notice   Creates a contract with a known address and withdraws tokens from it.
 *           After deployment, the Vault will call fetch() to withdraw tokens.
 * @dev      Any change in this contract, including comments, will affect the final
 *           bytecode and therefore will affect the create2 derived addresses.
 *           Do NOT modify unless the consequences of doing so are fully understood.
 */
contract Deposit {
    address payable private immutable vault;

    /**
     * @notice  Upon deployment it fetches the tokens (native or ERC20) to the Vault.
     * @param token  The address of the token to fetch
     */
    constructor(address token) {
        vault = payable(msg.sender);
        // Slightly cheaper to use msg.sender instead of Vault.
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = msg.sender.call{value: address(this).balance}("");
            require(success);
        } else {
            // IERC20Lite.transfer doesn't have a return bool to avoid reverts on non-standard ERC20s
            IERC20Lite(token).transfer(msg.sender, IERC20Lite(token).balanceOf(address(this)));
        }
    }

    /**
     * @notice  Allows the Vault to fetch ERC20 tokens from this contract.
     * @param token  The address of the token to fetch
     */
    function fetch(address token) external {
        require(msg.sender == vault);
        // IERC20Lite.transfer doesn't have a return bool to avoid reverts on non-standard ERC20s
        IERC20Lite(token).transfer(msg.sender, IERC20Lite(token).balanceOf(address(this)));
    }

    /// @notice Receives native tokens, emits an event and sends them to the Vault. Note that this
    // requires the sender to forward some more gas than for a simple transfer.
    receive() external payable {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = vault.call{value: address(this).balance}("");
        require(success);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title    ERC20 Lite Interface
 * @notice   The interface for functions ERC20Lite implements. This is intended to
 *           be used only in the Deposit contract.
 * @dev      Any change in this contract, including comments, will affect the final
 *           bytecode and therefore will affect the create2 derived addresses.
 *           Do NOT modify unless the consequences of doing so are fully understood.
 */
interface IERC20Lite {
    /// @dev Removed the return bool to avoid reverts on non-standard ERC20s.
    function transfer(address, uint256) external;

    function balanceOf(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IKeyManager.sol";
import "IAggKeyNonceConsumer.sol";
import "Shared.sol";

/**
 * @title    AggKeyNonceConsumer contract
 * @notice   Manages the reference to the KeyManager contract. The address
 *           is set in the constructor and can only be updated with a valid
 *           signature validated by the current KeyManager contract. This shall
 *           be done if the KeyManager contract is updated.
 */
abstract contract AggKeyNonceConsumer is Shared, IAggKeyNonceConsumer {
    /// @dev    The KeyManager used to checks sigs used in functions here
    IKeyManager private _keyManager;

    constructor(IKeyManager keyManager) nzAddr(address(keyManager)) {
        _keyManager = keyManager;
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  State-changing functions                //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Update KeyManager reference. Used if KeyManager contract is updated
     * @param sigData    Struct containing the signature data over the message
     *                   to verify, signed by the aggregate key.
     * @param keyManager New KeyManager's address
     * @param omitChecks Allow the omission of the extra checks in a special case
     */
    function updateKeyManager(
        SigData calldata sigData,
        IKeyManager keyManager,
        bool omitChecks
    )
        external
        override
        nzAddr(address(keyManager))
        consumesKeyNonce(sigData, keccak256(abi.encode(this.updateKeyManager.selector, keyManager, omitChecks)))
    {
        // Check that the new KeyManager is a contract
        require(address(keyManager).code.length > 0);

        // Allow the child to check compatibility with the new KeyManager
        _checkUpdateKeyManager(keyManager, omitChecks);

        _keyManager = keyManager;
        emit UpdatedKeyManager(address(keyManager));
    }

    /// @dev   This will be called when upgrading to a new KeyManager. This allows the child's contract
    ///        to check its compatibility with the new KeyManager. This is to prevent the contract from
    //         getting bricked. There is no good way to enforce the implementation of consumeKeyNonce().
    function _checkUpdateKeyManager(IKeyManager keyManager, bool omitChecks) internal view virtual;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Get the KeyManager address/interface that's used to validate sigs
     * @return  The KeyManager (IKeyManager)
     */
    function getKeyManager() public view override returns (IKeyManager) {
        return _keyManager;
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                         Modifiers                        //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /// @dev    Calls consumeKeyNonce in _keyManager
    modifier consumesKeyNonce(SigData calldata sigData, bytes32 contractMsgHash) {
        getKeyManager().consumeKeyNonce(sigData, contractMsgHash);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IGovernanceCommunityGuarded.sol";
import "AggKeyNonceConsumer.sol";
import "Shared.sol";

/**
 * @title    GovernanceCommunityGuarded contract
 * @notice   Allows the governor to perform certain actions for the procotol's safety in
 *           case of emergency. The aim is to allow the governor to suspend execution of
 *           critical functions.
 *           Also, it allows the CommunityKey to safeguard certain functions so the
 *           governor can execute them iff the communityKey allows it.
 */
abstract contract GovernanceCommunityGuarded is Shared, IGovernanceCommunityGuarded {
    /// @dev    Community Guard Disabled
    bool private _communityGuardDisabled;

    /// @dev    Whether execution is suspended
    bool private _suspended = false;

    /**
     * @notice  Get the governor's address. The contracts inheriting this (StateChainGateway and Vault)
     *          get the governor's address from the KeyManager through the AggKeyNonceConsumer's
     *          inheritance. Therefore, the implementation of this function must be left
     *          to the children. This is not implemented as a virtual onlyGovernor modifier to force
     *          the children to implement this function - virtual modifiers don't enforce that.
     * @return  The governor's address
     */
    function _getGovernor() internal view virtual returns (address);

    /**
     * @notice  Get the community's address. The contracts inheriting this (StateChainGateway and Vault)
     *          get the community's address from the KeyManager through the AggKeyNonceConsumer's
     *          inheritance. Therefore, the implementation of this function must be left
     *          to the children. This is not implemented as a virtual onlyCommunityKey modifier to force
     *          the children to implement this function - virtual modifiers don't enforce that.
     * @return  The community's address
     */
    function _getCommunityKey() internal view virtual returns (address);

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  State-changing functions                //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Enable Community Guard
     */
    function enableCommunityGuard() external override onlyCommunityKey onlyCommunityGuardDisabled {
        _communityGuardDisabled = false;
        emit CommunityGuardDisabled(false);
    }

    /**
     * @notice  Disable Community Guard
     */
    function disableCommunityGuard() external override onlyCommunityKey onlyCommunityGuardEnabled {
        _communityGuardDisabled = true;
        emit CommunityGuardDisabled(true);
    }

    /**
     * @notice Can be used to suspend contract execution - only executable by
     * governance and only to be used in case of emergency.
     */
    function suspend() external override onlyGovernor onlyNotSuspended {
        _suspended = true;
        emit Suspended(true);
    }

    /**
     * @notice      Resume contract execution
     */
    function resume() external override onlyGovernor onlySuspended {
        _suspended = false;
        emit Suspended(false);
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Get the Community Key
     * @return  The CommunityKey
     */
    function getCommunityKey() external view override returns (address) {
        return _getCommunityKey();
    }

    /**
     * @notice  Get the Community Guard state
     * @return  The Community Guard state
     */
    function getCommunityGuardDisabled() external view override returns (bool) {
        return _communityGuardDisabled;
    }

    /**
     * @notice  Get suspended state
     * @return  The suspended state
     */
    function getSuspendedState() external view override returns (bool) {
        return _suspended;
    }

    /**
     * @notice  Get governor address
     * @return  The governor address
     */
    function getGovernor() external view override returns (address) {
        return _getGovernor();
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                         Modifiers                        //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /// @dev    Check that the caller is the Community Key address.
    modifier onlyCommunityKey() {
        require(msg.sender == _getCommunityKey(), "Governance: not Community Key");
        _;
    }

    /// @dev    Check that community has disabled the community guard.
    modifier onlyCommunityGuardDisabled() {
        require(_communityGuardDisabled, "Governance: community guard enabled");
        _;
    }

    /// @dev    Check that community has disabled the community guard.
    modifier onlyCommunityGuardEnabled() {
        require(!_communityGuardDisabled, "Governance: community guard disabled");
        _;
    }

    /// @notice Ensure that the caller is the governor address. Calls the getGovernor
    ///         function which is implemented by the children.
    modifier onlyGovernor() {
        require(msg.sender == _getGovernor(), "Governance: not governor");
        _;
    }

    // @notice Check execution is suspended
    modifier onlySuspended() {
        require(_suspended, "Governance: not suspended");
        _;
    }

    // @notice Check execution is not suspended
    modifier onlyNotSuspended() {
        require(!_suspended, "Governance: suspended");
        _;
    }
}