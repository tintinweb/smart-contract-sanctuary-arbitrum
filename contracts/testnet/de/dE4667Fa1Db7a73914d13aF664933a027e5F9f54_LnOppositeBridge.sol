/**
 *Submitted for verification at Arbiscan.io on 2023-09-09
*/

// SPDX-License-Identifier: MIT

/**
 * .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
 * | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
 * | |  ____  ____  | || |  _________   | || |   _____      | || |     _____    | || |  ____  ____  | |
 * | | |_   ||   _| | || | |_   ___  |  | || |  |_   _|     | || |    |_   _|   | || | |_  _||_  _| | |
 * | |   | |__| |   | || |   | |_  \_|  | || |    | |       | || |      | |     | || |   \ \  / /   | |
 * | |   |  __  |   | || |   |  _|  _   | || |    | |   _   | || |      | |     | || |    > `' <    | |
 * | |  _| |  | |_  | || |  _| |___/ |  | || |   _| |__/ |  | || |     _| |_    | || |  _/ /'`\ \_  | |
 * | | |____||____| | || | |_________|  | || |  |________|  | || |    |_____|   | || | |____||____| | |
 * | |              | || |              | || |              | || |              | || |              | |
 * | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 *  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' '
 * 
 *
 * 9/9/2023
 **/

pragma solidity ^0.8.10;

// File @zeppelin-solidity/contracts/utils/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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

// File @zeppelin-solidity/contracts/security/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File contracts/ln/base/LnAccessController.sol
// License-Identifier: MIT

/// @title LnAccessController
/// @notice LnAccessController is a contract to control the access permission 
/// @dev See https://github.com/helix-bridge/contracts/tree/master/helix-contract
contract LnAccessController is Pausable {
    address public dao;
    address public operator;

    modifier onlyDao() {
        require(msg.sender == dao, "!dao");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "!operator");
        _;
    }

    function _initialize(address _dao) internal {
        dao = _dao;
        operator = msg.sender;
    }

    function setOperator(address _operator) onlyDao external {
        operator = _operator;
    }

    function transferOwnership(address _dao) onlyDao external {
        dao = _dao;
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function pause() external onlyOperator {
        _pause();
    }
}

// File contracts/ln/interface/ILowLevelMessager.sol
// License-Identifier: MIT

interface ILowLevelMessageSender {
    function registerRemoteReceiver(uint256 remoteChainId, address remoteBridge) external;
    function sendMessage(uint256 remoteChainId, bytes memory message, bytes memory params) external payable;
}

interface ILowLevelMessageReceiver {
    function registerRemoteSender(uint256 remoteChainId, address remoteBridge) external;
    function recvMessage(address remoteSender, address localReceiver, bytes memory payload) external;
}

// File @zeppelin-solidity/contracts/token/ERC20/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)


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

// File contracts/ln/base/LnBridgeHelper.sol
// License-Identifier: MIT

library LnBridgeHelper {
    // the time(seconds) for liquidity provider to delivery message
    // if timeout, slasher can work.
    uint256 constant public SLASH_EXPIRE_TIME = 30 * 60;
    bytes32 constant public INIT_SLASH_TRANSFER_ID = bytes32(uint256(1));
    // liquidity fee base rate
    // liquidityFee = liquidityFeeRate / LIQUIDITY_FEE_RATE_BASE * sendAmount
    uint256 constant public LIQUIDITY_FEE_RATE_BASE = 100000;

    struct TransferParameter {
        bytes32 previousTransferId;
        address provider;
        address sourceToken;
        address targetToken;
        uint112 amount;
        uint256 timestamp;
        address receiver;
    }

    // sourceToken and targetToken is the pair of erc20 token(or native) addresses
    // if sourceToken == address(0), then it's native token
    // if targetToken == address(0), then remote is native token
    // * `protocolFee` is the protocol fee charged by system
    // * `penaltyLnCollateral` is penalty from lnProvider when the transfer slashed, if we adjust this value, it'll not affect the old transfers.
    struct TokenInfo {
        uint112 protocolFee;
        uint112 penaltyLnCollateral;
        uint8 sourceDecimals;
        uint8 targetDecimals;
        bool isRegistered;
    }

    function sourceAmountToTargetAmount(
        TokenInfo memory tokenInfo,
        uint112 amount
    ) internal pure returns(uint112) {
        uint256 targetAmount = uint256(amount) * 10**tokenInfo.targetDecimals / 10**tokenInfo.sourceDecimals;
        require(targetAmount < type(uint112).max, "overflow amount");
        return uint112(targetAmount);
    }

    function calculateProviderFee(uint112 baseFee, uint16 liquidityFeeRate, uint112 amount) internal pure returns(uint112) {
        uint256 fee = uint256(baseFee) + uint256(liquidityFeeRate) * uint256(amount) / LIQUIDITY_FEE_RATE_BASE;
        require(fee < type(uint112).max, "overflow fee");
        return uint112(fee);
    }

    function safeTransfer(
        address token,
        address receiver,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(
            IERC20.transfer.selector,
            receiver,
            amount
        ));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "lnBridgeHelper:transfer token failed");
    }

    function safeTransferFrom(
        address token,
        address sender,
        address receiver,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            sender,
            receiver,
            amount
        ));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "lnBridgeHelper:transferFrom token failed");
    }

    function safeTransferNative(
        address receiver,
        uint256 amount
    ) internal {
        (bool success,) = payable(receiver).call{value: amount}("");
        require(success, "lnBridgeHelper:transfer native token failed");
    }

    function getProviderKey(uint256 remoteChainId, address provider, address sourceToken, address targetToken) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(
            remoteChainId,
            provider,
            sourceToken,
            targetToken
        ));
    }

    function getTokenKey(uint256 remoteChainId, address sourceToken, address targetToken) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(
            remoteChainId,
            sourceToken,
            targetToken
        ));
    }
}

// File contracts/ln/interface/ILnOppositeBridgeSource.sol
// License-Identifier: MIT


interface ILnOppositeBridgeSource {
    function slash(
        bytes32 lastRefundTransferId,
        bytes32 transferId,
        uint256 remoteChainId,
        uint256 timestamp,
        address sourceToken,
        address targetToken,
        address provider,
        address slasher
    ) external;

    function withdrawMargin(
        bytes32 lastRefundTransferId,
        bytes32 lastTransferId,
        uint256 remoteChainId,
        address provider,
        address sourceToken,
        address targetToken,
        uint112 amount
    ) external;
}

// File contracts/ln/base/LnOppositeBridgeTarget.sol
// License-Identifier: MIT


contract LnOppositeBridgeTarget {
    // if slasher == address(0), this FillTransfer is relayed by lnProvider
    // otherwise, this FillTransfer is slashed by slasher
    // if there is no slash transfer before, then it's latestSlashTransferId is assigned by INIT_SLASH_TRANSFER_ID, a special flag
    struct SlashInfo {
        address provider;
        address sourceToken;
        address targetToken;
        address slasher;
        uint256 timestamp;
    }

    // transferId => latest slash transfer Id
    mapping(bytes32 => bytes32) public fillTransfers;
    // transferId => Slash info
    mapping(bytes32 => SlashInfo) public slashInfos;

    event TransferFilled(bytes32 transferId, address slasher);
    event SlashRequest(uint256 remoteChainId, address sourceToken, address targetToken, bytes32 transferId);
    event WithdrawMarginRequest(uint256 remoteChainId, address sourceToken, address targetToken, uint112 amount);

    // if slasher is nonzero, then it's a slash fill transfer
    function _checkPreviousAndFillTransfer(
        bytes32 _transferId,
        bytes32 _previousTransferId
    ) internal {
        // the first fill transfer, we fill the INIT_SLASH_TRANSFER_ID as the latest slash transferId
        if (_previousTransferId == bytes32(0)) {
            fillTransfers[_transferId] = LnBridgeHelper.INIT_SLASH_TRANSFER_ID;
        } else {
            // Find the previous slash fill, it is a slash fill if the slasher is not zero address.
            bytes32 previousLatestSlashTransferId = fillTransfers[_previousTransferId];
            require(previousLatestSlashTransferId != bytes32(0), "previous fill not exist");

            SlashInfo memory previousSlashInfo = slashInfos[_previousTransferId];
            // we use latestSlashTransferId to store the latest slash transferId
            // if previous.slasher != 0, then previous is slashed
            // if previous.slasher == 0, then previous is not slashed
            bytes32 latestSlashTransferId = previousSlashInfo.slasher != address(0) ? _previousTransferId : previousLatestSlashTransferId;

            fillTransfers[_transferId] = latestSlashTransferId;
        }
    }

    // fill transfer
    // 1. if transfer is not slashed or relayed, LnProvider relay message to fill the transfer, and the transfer finished on target chain
    // 2. if transfer is timeout and not processed, slasher(any account) can fill the transfer and request slash
    // if it's filled by slasher, we store the address of the slasher
    // expectedTransferId used to ensure the parameter is the same as on source chain
    // some cases
    // 1) If transferId is not exist on source chain, it'll be rejected by source chain when shashed.
    // 2) If transferId exist on source chain. We have the same hash process on source and target chain, so the previousTransferId is trusted.
    //    2.1) If transferId is the first transfer Id of this provider, then previousTransferId is zero and the latestSlashTransferId is INIT_SLASH_TRANSFER_ID
    //    2.2) If transferId is not the first transfer, then it's latestSlashTransferId has the next two scenarios
    //         * the previousTransfer is a slash transfer, then latestSlashTransferId is previousTransferId
    //         * the previousTransfer is a normal relayed transfer, then latestSlashTransferId is previousTransfer's latestSlashTransferId
    //    I.   transferId is trusted => previousTransferId is trusted => previousTransfer.previousTransferId is trusted => ... => firstTransfer is trusted
    //    II.  transferId is trusted => previousTransferId is trusted => latestSlashTransferId is trusted if previousTransfer is a slash transfer
    //    III. Both I and II => latestSlashTransferId is trusted if previousTransfer is normal relayed tranfer
    function _fillTransfer(
        LnBridgeHelper.TransferParameter calldata _params,
        uint256 _remoteChainId,
        bytes32 _expectedTransferId
    ) internal {
        bytes32 transferId = keccak256(abi.encodePacked(
            _remoteChainId,
            block.chainid,
            _params.previousTransferId,
            _params.provider,
            _params.sourceToken,
            _params.targetToken,
            _params.receiver,
            _params.amount));
        require(_expectedTransferId == transferId, "check expected transferId failed");
        // Make sure this transfer was never filled before 
        require(fillTransfers[transferId] == bytes32(0), "fill exist");

        _checkPreviousAndFillTransfer(transferId, _params.previousTransferId);

        if (_params.targetToken == address(0)) {
            require(msg.value >= _params.amount, "invalid amount");
            LnBridgeHelper.safeTransferNative(_params.receiver, _params.amount);
        } else {
            LnBridgeHelper.safeTransferFrom(_params.targetToken, msg.sender, _params.receiver, uint256(_params.amount));
        }
    }

    function transferAndReleaseMargin(
        LnBridgeHelper.TransferParameter calldata _params,
        uint256 _remoteChainId,
        bytes32 _expectedTransferId
    ) payable external {
        // normal relay message, fill slasher as zero
        require(_params.provider == msg.sender, "invalid provider");
        _fillTransfer(_params, _remoteChainId, _expectedTransferId);

        emit TransferFilled(_expectedTransferId, address(0));
    }

    // The condition for slash is that the transfer has timed out
    // Meanwhile we need to request a slash transaction to the source chain to withdraw the LnProvider's margin
    // On the source chain, we need to verify all the transfers before has been relayed or slashed.
    // So we needs to carry the the previous shash transferId to ensure that the slash is continuous.
    function _slashAndRemoteReleaseCall(
        LnBridgeHelper.TransferParameter calldata _params,
        uint256 _remoteChainId,
        bytes32 _expectedTransferId
    ) internal returns(bytes memory message) {
        require(block.timestamp > _params.timestamp + LnBridgeHelper.SLASH_EXPIRE_TIME, "slash time not expired");
        _fillTransfer(_params, _remoteChainId, _expectedTransferId);

        // slasher = msg.sender
        slashInfos[_expectedTransferId] = SlashInfo(_params.provider, _params.sourceToken, _params.targetToken, msg.sender, _params.timestamp);

        // Do not slash `transferId` in source chain unless `latestSlashTransferId` has been slashed
        message = _encodeSlashCall(
            fillTransfers[_expectedTransferId],
            _expectedTransferId,
            _params.timestamp,
            _params.sourceToken,
            _params.targetToken,
            _params.provider,
            msg.sender
        );
        emit TransferFilled(_expectedTransferId, msg.sender);
    }

    // we use this to verify that the transfer has been slashed by user and it can resend the slash request
    function _retrySlashAndRemoteReleaseCall(bytes32 _transferId) internal view returns(bytes memory message) {
        bytes32 latestSlashTransferId = fillTransfers[_transferId];
        // transfer must be filled
        require(latestSlashTransferId != bytes32(0), "invalid transfer id");
        // transfer must be slashed
        SlashInfo memory slashInfo = slashInfos[_transferId];
        require(slashInfo.slasher != address(0), "slasher not exist");
        message = _encodeSlashCall(
            latestSlashTransferId,
            _transferId,
            slashInfo.timestamp,
            slashInfo.sourceToken,
            slashInfo.targetToken,
            slashInfo.provider,
            slashInfo.slasher
        );
    }

    function _encodeSlashCall(
        bytes32 _latestSlashTransferId,
        bytes32 _transferId,
        uint256 _timestamp,
        address _sourceToken,
        address _targetToken,
        address _provider,
        address _slasher
    ) internal view returns(bytes memory) {
        return abi.encodeWithSelector(
            ILnOppositeBridgeSource.slash.selector,
            _latestSlashTransferId,
            _transferId,
            block.chainid,
            _timestamp,
            _sourceToken,
            _targetToken,
            _provider,
            _slasher
        );
    }

    function _sendMessageToTarget(uint256 _remoteChainId, bytes memory _payload, bytes memory _extParams) internal virtual {}

    function requestSlashAndRemoteRelease(
        LnBridgeHelper.TransferParameter calldata _params,
        uint256 _remoteChainId,
        bytes32 _expectedTransferId,
        bytes memory _extParams
    ) payable external {
        bytes memory slashCallMessage = _slashAndRemoteReleaseCall(
           _params,
           _remoteChainId,
           _expectedTransferId
        );
        _sendMessageToTarget(_remoteChainId, slashCallMessage, _extParams);
        emit SlashRequest(_remoteChainId, _params.sourceToken, _params.targetToken, _expectedTransferId);
    }

    function requestRetrySlashAndRemoteRelease(
        uint256 remoteChainId,
        bytes32 _transferId,
        bytes memory _extParams
    ) payable external {
        bytes memory retryCallMessage = _retrySlashAndRemoteReleaseCall(_transferId);
        _sendMessageToTarget(remoteChainId, retryCallMessage, _extParams);
    }

    function _requestWithdrawMargin(
        bytes32 _lastTransferId,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) internal view returns(bytes memory message) {
        bytes32 latestSlashTransferId = fillTransfers[_lastTransferId];
        require(latestSlashTransferId != bytes32(0), "invalid last transfer");

        return abi.encodeWithSelector(
            ILnOppositeBridgeSource.withdrawMargin.selector,
            latestSlashTransferId,
            _lastTransferId,
            block.chainid,
            msg.sender,
            _sourceToken,
            _targetToken,
            _amount
        );
    }

    function requestWithdrawMargin(
        uint256 _remoteChainId,
        bytes32 _lastTransferId,
        address _sourceToken,
        address _targetToken,
        uint112 _amount,
        bytes memory _extParams
    ) payable external {
        bytes memory withdrawCallMessage = _requestWithdrawMargin(
            _lastTransferId,
            _sourceToken,
            _targetToken,
            _amount
        );
        _sendMessageToTarget(_remoteChainId, withdrawCallMessage, _extParams);
        emit WithdrawMarginRequest(_remoteChainId, _sourceToken, _targetToken, _amount);
    }
}

// File contracts/ln/base/LnOppositeBridgeSource.sol
// License-Identifier: MIT

/// @title LnBridgeSource
/// @notice LnBridgeSource is a contract to help user transfer token to liquidity node and generate proof,
///         then the liquidity node must transfer the same amount of the token to the user on target chain.
///         Otherwise if timeout the slasher can paid for relayer and slash the transfer, then request slash from lnProvider's margin.
/// @dev See https://github.com/helix-bridge/contracts/tree/master/helix-contract
contract LnOppositeBridgeSource {
    // the Liquidity Node provider info
    // Liquidity Node need register first
    struct SourceProviderConfigure {
        uint112 margin;
        uint112 baseFee;
        // liquidityFeeRate / 100,000 * amount = liquidityFee
        // the max liquidity fee rate is 0.255%
        uint16 liquidityFeeRate;
        bool pause;
    }
    struct SourceProviderInfo {
        SourceProviderConfigure config;
        bytes32 lastTransferId;
    }
    
    // the Snapshot is the state of the token bridge when user prepare to transfer across chains.
    // If the snapshot updated when the across chain transfer confirmed, it will
    // 1. if lastTransferId updated, revert
    // 2. if margin decrease or totalFee increase, revert
    // 3. if margin increase or totalFee decrease, success
    struct Snapshot {
        uint256 remoteChainId;
        address provider;
        address sourceToken;
        address targetToken;
        bytes32 transferId;
        uint112 totalFee;
        uint112 depositedMargin;
    }
    // registered token info
    // tokenKey => token info
    mapping(bytes32=>LnBridgeHelper.TokenInfo) public tokenInfos;
    // registered srcProviders
    mapping(bytes32=>SourceProviderInfo) public srcProviders;
    // each time cross chain transfer, amount and fee can't be larger than type(uint112).max
    struct LockInfo {
        // amount + providerFee + penaltyLnCollateral
        // the Indexer should be care about this value, it will frozen lnProvider's margin when the transfer not finished.
        // and when the slasher slash success, this amount of token will be transfer from lnProvider's margin to slasher.
        uint112 amountWithFeeAndPenalty;
        uint32 timestamp;
        bool hasSlashed;
    }
    // key: transferId = hash(proviousTransferId, targetToken, receiver, targetAmount)
    // * `proviousTransferId` is used to ensure the continuous of the transfer
    // * `timestamp` is the block.timestmap to judge timeout on target chain(here we support source and target chain has the same world clock)
    // * `targetToken`, `receiver` and `targetAmount` are used on target chain to transfer target token.
    mapping(bytes32 => LockInfo) public lockInfos;

    address public protocolFeeReceiver;

    event TokenLocked(
        uint256 remoteChainId,
        bytes32 transferId,
        address provider,
        address sourceToken,
        address targetToken,
        uint112 amount,
        uint112 fee,
        uint64 timestamp,
        address receiver);
    event LiquidityWithdrawn(uint256 remoteChainId, address provider, address sourceToken, address targetToken, uint112 amount);
    event Slash(uint256 remoteChainId, bytes32 transferId, address provider, address sourceToken, address targetToken, uint112 margin, address slasher);
    // relayer
    event LnProviderUpdated(uint256 remoteChainId, address provider, address sourceToken, address targetToken, uint112 margin, uint112 baseFee, uint16 liquidityfeeRate);

    modifier allowRemoteCall(uint256 _remoteChainId) {
        _verifyRemote(_remoteChainId);
        _;
    }

    function _verifyRemote(uint256 _remoteChainId) internal virtual {}

    function _updateFeeReceiver(address _feeReceiver) internal {
        require(_feeReceiver != address(this), "invalid system fee receiver");
        protocolFeeReceiver = _feeReceiver;
    }

    function _setTokenInfo(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _protocolFee,
        uint112 _penaltyLnCollateral,
        uint8 _sourceDecimals,
        uint8 _targetDecimals
    ) internal {
        bytes32 tokenKey = LnBridgeHelper.getTokenKey(_remoteChainId, _sourceToken, _targetToken);
        tokenInfos[tokenKey] = LnBridgeHelper.TokenInfo(
            _protocolFee,
            _penaltyLnCollateral,
            _sourceDecimals,
            _targetDecimals,
            true
        );
    }

    function providerPause(uint256 _remoteChainId, address _sourceToken, address _targetToken) external {
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);
        srcProviders[providerKey].config.pause = true;
    }

    function providerUnpause(uint256 _remoteChainId, address _sourceToken, address _targetToken) external {
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);
        srcProviders[providerKey].config.pause = false;
    }

    // lnProvider can register or update its configure by using this function
    // * `margin` is the increased value of the deposited margin
    function updateProviderFeeAndMargin(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _margin,
        uint112 _baseFee,
        uint16 _liquidityFeeRate
    ) external payable {
        require(_liquidityFeeRate < LnBridgeHelper.LIQUIDITY_FEE_RATE_BASE, "liquidity fee too large");
        bytes32 tokenKey = LnBridgeHelper.getTokenKey(_remoteChainId, _sourceToken, _targetToken);
        LnBridgeHelper.TokenInfo memory tokenInfo = tokenInfos[tokenKey];
        require(tokenInfo.isRegistered, "token is not registered");

        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);
        SourceProviderInfo memory providerInfo = srcProviders[providerKey];

        SourceProviderConfigure memory config = SourceProviderConfigure(
            // the margin can be only increased here
            _margin + providerInfo.config.margin,
            _baseFee,
            _liquidityFeeRate,
            providerInfo.config.pause
        );

        srcProviders[providerKey].config = config;

        if (_sourceToken == address(0)) {
            require(msg.value == _margin, "invalid margin value");
        } else {
            if (_margin > 0) {
                LnBridgeHelper.safeTransferFrom(_sourceToken, msg.sender, address(this), _margin);
            }
        }
        emit LnProviderUpdated(_remoteChainId, msg.sender, _sourceToken, _targetToken, config.margin, _baseFee, _liquidityFeeRate);
    }

    // the fee user should paid when transfer.
    // totalFee = providerFee + protocolFee
    // providerFee = provider.baseFee + provider.liquidityFeeRate * amount
    function totalFee(
        uint256 _remoteChainId,
        address _provider,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) external view returns(uint256) {
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, _provider, _sourceToken, _targetToken);
        SourceProviderInfo memory providerInfo = srcProviders[providerKey];
        uint112 providerFee = LnBridgeHelper.calculateProviderFee(providerInfo.config.baseFee, providerInfo.config.liquidityFeeRate, _amount);
        bytes32 tokenKey = LnBridgeHelper.getTokenKey(_remoteChainId, _sourceToken, _targetToken);
        return providerFee + tokenInfos[tokenKey].protocolFee;
    }

    // This function transfers tokens from the user to LnProvider and generates a proof on the source chain.
    // The snapshot represents the state of the LN bridge for this LnProvider, obtained by the off-chain indexer.
    // If the chain state is updated and does not match the snapshot state, the transaction will be reverted.
    // 1. the state(lastTransferId, fee, margin) must match snapshot
    // 2. transferId not exist
    function transferAndLockMargin(
        Snapshot calldata _snapshot,
        uint112 _amount,
        address _receiver
    ) external payable {
        require(_amount > 0, "invalid amount");

        bytes32 providerKey = LnBridgeHelper.getProviderKey(_snapshot.remoteChainId, _snapshot.provider, _snapshot.sourceToken, _snapshot.targetToken);
        SourceProviderInfo memory providerInfo = srcProviders[providerKey];

        require(!providerInfo.config.pause, "provider paused");

        LnBridgeHelper.TokenInfo memory tokenInfo = tokenInfos[
            LnBridgeHelper.getTokenKey(_snapshot.remoteChainId, _snapshot.sourceToken, _snapshot.targetToken)
        ];

        uint112 providerFee = LnBridgeHelper.calculateProviderFee(providerInfo.config.baseFee, providerInfo.config.liquidityFeeRate, _amount);
        
        // the chain state not match snapshot
        require(providerInfo.lastTransferId == _snapshot.transferId, "snapshot expired");
        // Note: this requirement is not enough to ensure that the lnProvider's margin is enough because there maybe some frozen margins in other transfers
        require(providerInfo.config.margin >= _amount + tokenInfo.penaltyLnCollateral + providerFee, "amount not valid");
        require(_snapshot.depositedMargin <= providerInfo.config.margin, "margin updated");
        require(_snapshot.totalFee >= tokenInfo.protocolFee + providerFee, "fee is invalid");
        
        uint112 targetAmount = LnBridgeHelper.sourceAmountToTargetAmount(tokenInfo, _amount);
        require(block.timestamp < type(uint32).max, "timestamp overflow");
        bytes32 transferId = keccak256(abi.encodePacked(
            block.chainid,
            _snapshot.remoteChainId,
            _snapshot.transferId,
            _snapshot.provider,
            _snapshot.sourceToken,
            _snapshot.targetToken,
            _receiver,
            targetAmount));
        require(lockInfos[transferId].timestamp == 0, "transferId exist");
        lockInfos[transferId] = LockInfo(_amount + tokenInfo.penaltyLnCollateral + providerFee, uint32(block.timestamp), false);

        // update the state to prevent other transfers using the same snapshot
        srcProviders[providerKey].lastTransferId = transferId;

        if (_snapshot.sourceToken == address(0)) {
            require(_amount + _snapshot.totalFee == msg.value, "amount unmatched");
            LnBridgeHelper.safeTransferNative(_snapshot.provider, _amount + providerFee);
            if (tokenInfo.protocolFee > 0) {
                LnBridgeHelper.safeTransferNative(protocolFeeReceiver, tokenInfo.protocolFee);
            }
            uint256 refund = _snapshot.totalFee - tokenInfo.protocolFee - providerFee;
            if ( refund > 0 ) {
                LnBridgeHelper.safeTransferNative(msg.sender, refund);
            }
        } else {
            LnBridgeHelper.safeTransferFrom(
                _snapshot.sourceToken,
                msg.sender,
                _snapshot.provider,
                _amount + providerFee
            );
            if (tokenInfo.protocolFee > 0) {
                LnBridgeHelper.safeTransferFrom(
                    _snapshot.sourceToken,
                    msg.sender,
                    protocolFeeReceiver,
                    tokenInfo.protocolFee
                );
            }
        }
        emit TokenLocked(
            _snapshot.remoteChainId,
            transferId,
            _snapshot.provider,
            _snapshot.sourceToken,
            _snapshot.targetToken,
            _amount,
            providerFee,
            uint64(block.timestamp),
            _receiver);
    }

    // this slash is called by remote message
    // the token should be sent to the slasher who slash and finish the transfer on target chain.
    // latestSlashTransferId is the latest slashed transfer trusted from the target chain, and the current slash transfer cannot be executed before the latestSlash transfer.
    // after slash, the margin of lnProvider need to be updated
    function slash(
        bytes32 _latestSlashTransferId,
        bytes32 _transferId,
        uint256 _remoteChainId,
        uint256 _timestamp,
        address _sourceToken,
        address _targetToken,
        address _provider,
        address _slasher
    ) external allowRemoteCall(_remoteChainId) {
        // check lastTransfer
        // ensure last slash transfer(checked on target chain) has been slashed
        LockInfo memory lastLockInfo = lockInfos[_latestSlashTransferId];
        require(lastLockInfo.hasSlashed || _latestSlashTransferId == LnBridgeHelper.INIT_SLASH_TRANSFER_ID, "latest slash transfer invalid");
        LockInfo memory lockInfo = lockInfos[_transferId];

        // ensure transfer exist and not slashed yet
        require(!lockInfo.hasSlashed, "transfer has been slashed");
        require(lockInfo.timestamp > 0 && lockInfo.timestamp == _timestamp, "lnBridgeSource:invalid timestamp");

        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, _provider, _sourceToken, _targetToken);

        SourceProviderInfo memory lnProvider = srcProviders[providerKey];
        lockInfos[_transferId].hasSlashed = true;
        // transfer token to the slasher
        uint112 slashAmount = lockInfo.amountWithFeeAndPenalty;
        require(lnProvider.config.margin >= slashAmount, "margin not enough");
        uint112 updatedMargin = lnProvider.config.margin - slashAmount;
        srcProviders[providerKey].config.margin = updatedMargin;

        if (_sourceToken == address(0)) {
            LnBridgeHelper.safeTransferNative(_slasher, slashAmount);
        } else {
            LnBridgeHelper.safeTransfer(_sourceToken, _slasher, slashAmount);
        }

        emit Slash(_remoteChainId, _transferId, _provider, _sourceToken, _targetToken, updatedMargin, _slasher);
    }

    // lastTransfer is the latest slash transfer, all transfer must be relayed or slashed
    // if user use the snapshot before this transaction to send cross-chain transfer, it should be reverted because this `withdrawMargin` will decrease margin.
    function withdrawMargin(
        bytes32 _latestSlashTransferId,
        bytes32 _lastTransferId,
        uint256 _remoteChainId,
        address _provider,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) external allowRemoteCall(_remoteChainId) {
        // check the latest slash transfer 
        // ensure latest slash tranfer(verified on target chain) has been slashed on source chain
        LockInfo memory lastRefundLockInfo = lockInfos[_latestSlashTransferId];
        require(lastRefundLockInfo.hasSlashed || _latestSlashTransferId == LnBridgeHelper.INIT_SLASH_TRANSFER_ID, "latest slash transfer invalid");

        // use this condition to ensure that the withdraw message is sent by the provider
        // the parameter provider is the message sender of this remote withdraw call
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, _provider, _sourceToken, _targetToken);
        SourceProviderInfo memory lnProvider = srcProviders[providerKey];

        // ensure all transfer has finished
        require(lnProvider.lastTransferId == _lastTransferId, "invalid last transferid");
        require(lnProvider.config.margin >= _amount, "margin not enough");
        uint112 updatedMargin = lnProvider.config.margin - _amount;
        srcProviders[providerKey].config.margin = updatedMargin;
        if (_sourceToken == address(0)) {
            LnBridgeHelper.safeTransferNative(_provider, _amount);
        } else {
            LnBridgeHelper.safeTransfer(_sourceToken, _provider, _amount);
        }
        emit LiquidityWithdrawn(_remoteChainId, _provider, _sourceToken, _targetToken, updatedMargin);
    }
}

// File @zeppelin-solidity/contracts/utils/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)


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

// File @zeppelin-solidity/contracts/proxy/utils/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// File contracts/ln/LnOppositeBridge.sol
// License-Identifier: MIT





contract LnOppositeBridge is Initializable, LnAccessController, LnOppositeBridgeSource, LnOppositeBridgeTarget {
    struct MessagerService {
        address sendService;
        address receiveService;
    }
    mapping(uint256=>MessagerService) messagers;

    receive() external payable {}

    function initialize(address _dao) public initializer {
        _initialize(_dao);
        _updateFeeReceiver(_dao);
    }

    function setSendService(uint256 _remoteChainId, address _remoteBridge, address _service) external onlyDao {
        messagers[_remoteChainId].sendService = _service;
        ILowLevelMessageSender(_service).registerRemoteReceiver(_remoteChainId, _remoteBridge);
    }

    function setReceiveService(uint256 _remoteChainId, address _remoteBridge, address _service) external onlyDao {
        messagers[_remoteChainId].receiveService = _service;
        ILowLevelMessageReceiver(_service).registerRemoteSender(_remoteChainId, _remoteBridge);
    }

    function updateFeeReceiver(address _receiver) external onlyDao {
        _updateFeeReceiver(_receiver);
    }

    function setTokenInfo(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _protocolFee,
        uint112 _penaltyLnCollateral,
        uint8 _sourceDecimals,
        uint8 _targetDecimals
    ) external onlyDao {
        _setTokenInfo(
            _remoteChainId,
            _sourceToken,
            _targetToken,
            _protocolFee,
            _penaltyLnCollateral,
            _sourceDecimals,
            _targetDecimals
        );
    }

    function _sendMessageToTarget(uint256 _remoteChainId, bytes memory _payload, bytes memory _extParams) internal override {
        address sendService = messagers[_remoteChainId].sendService;
        require(sendService != address(0), "invalid messager");
        ILowLevelMessageSender(sendService).sendMessage(_remoteChainId, _payload, _extParams);
    }

    function _verifyRemote(uint256 _remoteChainId) whenNotPaused internal view override {
        address receiveService = messagers[_remoteChainId].receiveService;
        require(receiveService == msg.sender, "invalid messager");
    }
}