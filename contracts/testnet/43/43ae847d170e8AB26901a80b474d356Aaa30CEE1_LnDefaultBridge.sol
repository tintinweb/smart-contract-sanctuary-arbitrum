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

// File contracts/ln/base/LnDefaultBridgeTarget.sol
// License-Identifier: MIT

contract LnDefaultBridgeTarget {
    struct TargetProviderInfo {
        uint256 margin;
        // use this slash gas reserve to pay the slash fee if transfer filled but timeout
        uint256 slashReserveFund;
        uint64 lastExpireFillTime;
        uint64 withdrawNonce;
    }

    // providerKey => margin
    // providerKey = hash(remoteChainId, provider, sourceToken, targetToken)
    mapping(bytes32=>TargetProviderInfo) public tgtProviders;

    // if timestamp > 0, the Transfer has been relayed or slashed
    // if slasher == address(0), this FillTransfer is relayed by lnProvider
    // otherwise, this FillTransfer is slashed by slasher
    struct FillTransfer {
        uint64 timestamp;
        address slasher;
    }

    // transferId => FillTransfer
    mapping(bytes32 => FillTransfer) public fillTransfers;

    event TransferFilled(bytes32 transferId, address provider);
    event Slash(bytes32 transferId, uint256 remoteChainId, address provider, address sourceToken, address targetToken, uint256 margin, address slasher);
    event MarginUpdated(uint256 remoteChainId, address provider, address sourceToken, address targetToken, uint256 amount, uint64 withdrawNonce);
    event SlashReserveUpdated(address provider, address sourceToken, address targetToken, uint256 amount);

    modifier allowRemoteCall(uint256 _remoteChainId) {
        _verifyRemote(_remoteChainId);
        _;
    }

    function _verifyRemote(uint256 _remoteChainId) internal virtual {}

    function depositProviderMargin(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint256 _margin
    ) external payable {
        require(_margin > 0, "invalid margin");
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);
        TargetProviderInfo memory providerInfo = tgtProviders[providerKey];
        uint256 updatedMargin = providerInfo.margin + _margin;
        tgtProviders[providerKey].margin = updatedMargin;
        if (_targetToken == address(0)) {
            require(msg.value == _margin, "invalid margin value");
        } else {
            LnBridgeHelper.safeTransferFrom(_targetToken, msg.sender, address(this), _margin);
        }
        emit MarginUpdated(_remoteChainId, msg.sender, _sourceToken, _targetToken, updatedMargin, providerInfo.withdrawNonce);
    }

    function transferAndReleaseMargin(
        LnBridgeHelper.TransferParameter calldata _params,
        uint256 _remoteChainId,
        bytes32 _expectedTransferId
    ) external payable {
        require(_params.provider == msg.sender, "invalid provider");
        require(_params.previousTransferId == bytes32(0) || fillTransfers[_params.previousTransferId].timestamp > 0, "last transfer not filled");
        bytes32 transferId = keccak256(abi.encodePacked(
           _remoteChainId,
           block.chainid,
           _params.previousTransferId,
           _params.provider,
           _params.sourceToken,
           _params.targetToken,
           _params.receiver,
           _params.amount
        ));
        require(_expectedTransferId == transferId, "check expected transferId failed");
        FillTransfer memory fillTransfer = fillTransfers[transferId];
        // Make sure this transfer was never filled before 
        require(fillTransfer.timestamp == 0, "transfer has been filled");

        fillTransfers[transferId].timestamp = uint64(block.timestamp);
        if (block.timestamp - LnBridgeHelper.SLASH_EXPIRE_TIME > _params.timestamp) {
            bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _params.sourceToken, _params.targetToken);
            tgtProviders[providerKey].lastExpireFillTime = uint64(block.timestamp);
        }

        if (_params.targetToken == address(0)) {
            require(msg.value == _params.amount, "lnBridgeTarget:invalid amount");
            LnBridgeHelper.safeTransferNative(_params.receiver, _params.amount);
        } else {
            LnBridgeHelper.safeTransferFrom(_params.targetToken, msg.sender, _params.receiver, uint256(_params.amount));
        }
        emit TransferFilled(transferId, _params.provider);
    }

    function depositSlashFundReserve(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint256 _amount
    ) external payable {
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);
        TargetProviderInfo memory providerInfo = tgtProviders[providerKey];
        uint256 updatedAmount = providerInfo.slashReserveFund + _amount;
        tgtProviders[providerKey].slashReserveFund = updatedAmount;
        if (_targetToken == address(0)) {
            require(msg.value == _amount, "amount invalid");
        } else {
            LnBridgeHelper.safeTransferFrom(_targetToken, msg.sender, address(this), _amount);
        }
        emit SlashReserveUpdated(msg.sender, _sourceToken, _targetToken, updatedAmount);
    }

    // withdraw slash fund
    // provider can't withdraw until the block.timestamp overtime lastExpireFillTime for a period of time 
    function withdrawSlashFundReserve(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint256 _amount
    ) external {
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);
        TargetProviderInfo memory providerInfo = tgtProviders[providerKey];
        require(_amount <= providerInfo.slashReserveFund, "reserve not enough");
        require(block.timestamp - LnBridgeHelper.SLASH_EXPIRE_TIME >= providerInfo.lastExpireFillTime, "time not expired");
        uint256 updatedAmount = providerInfo.slashReserveFund - _amount;
        tgtProviders[providerKey].slashReserveFund = updatedAmount;
        if (_targetToken == address(0)) {
            LnBridgeHelper.safeTransferNative(msg.sender, _amount);
        } else {
            LnBridgeHelper.safeTransfer(_targetToken, msg.sender, _amount);
        }
        emit SlashReserveUpdated(msg.sender, _sourceToken, _targetToken, updatedAmount);
    }

    function withdraw(
        uint256 _remoteChainId,
        bytes32 _lastTransferId,
        uint64  _withdrawNonce,
        address _provider,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) external allowRemoteCall(_remoteChainId) {
        // ensure all transfer has finished
        require(_lastTransferId == bytes32(0) || fillTransfers[_lastTransferId].timestamp > 0, "last transfer not filled");

        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, _provider, _sourceToken, _targetToken);
        TargetProviderInfo memory providerInfo = tgtProviders[providerKey];
        // all the early withdraw info ignored
        require(providerInfo.withdrawNonce < _withdrawNonce, "withdraw nonce expired");

        // transfer token
        require(providerInfo.margin >= _amount, "margin not enough");
        uint256 updatedMargin = providerInfo.margin - _amount;
        tgtProviders[providerKey].margin = updatedMargin;
        tgtProviders[providerKey].withdrawNonce = _withdrawNonce;

        if (_targetToken == address(0)) {
            LnBridgeHelper.safeTransferNative(_provider, _amount);
        } else {
            LnBridgeHelper.safeTransfer(_targetToken, _provider, _amount);
        }
        emit MarginUpdated(_remoteChainId, _provider, _sourceToken, _targetToken, updatedMargin, _withdrawNonce);
    }

    function slash(
        LnBridgeHelper.TransferParameter memory _params,
        uint256 _remoteChainId,
        address _slasher,
        uint112 _fee,
        uint112 _penalty
    ) external allowRemoteCall(_remoteChainId) {
        require(_params.previousTransferId == bytes32(0) || fillTransfers[_params.previousTransferId].timestamp > 0, "last transfer not filled");

        bytes32 transferId = keccak256(abi.encodePacked(
            _remoteChainId,
            block.chainid,
            _params.previousTransferId,
            _params.provider,
            _params.sourceToken,
            _params.targetToken,
            _params.receiver,
            _params.amount
        ));
        FillTransfer memory fillTransfer = fillTransfers[transferId];
        require(fillTransfer.slasher == address(0), "transfer has been slashed");
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, _params.provider, _params.sourceToken, _params.targetToken);
        TargetProviderInfo memory providerInfo = tgtProviders[providerKey];
        uint256 updatedMargin = providerInfo.margin;
        // transfer is not filled
        if (fillTransfer.timestamp == 0) {
            require(_params.timestamp < block.timestamp - LnBridgeHelper.SLASH_EXPIRE_TIME, "time not expired");
            fillTransfers[transferId] = FillTransfer(uint64(block.timestamp), _slasher);

            // 1. transfer token to receiver
            // 2. trnasfer fee and penalty to slasher
            // update margin
            uint256 marginCost = _params.amount + _fee + _penalty;
            require(providerInfo.margin >= marginCost, "margin not enough");
            updatedMargin = providerInfo.margin - marginCost;
            tgtProviders[providerKey].margin = updatedMargin;

            if (_params.targetToken == address(0)) {
                LnBridgeHelper.safeTransferNative(_params.receiver, _params.amount);
                LnBridgeHelper.safeTransferNative(_slasher, _fee + _penalty);
            } else {
                LnBridgeHelper.safeTransfer(_params.targetToken, _params.receiver, uint256(_params.amount));
                LnBridgeHelper.safeTransfer(_params.targetToken, _slasher, _fee + _penalty);
            }
        } else {
            require(fillTransfer.timestamp > _params.timestamp + LnBridgeHelper.SLASH_EXPIRE_TIME, "time not expired");
            fillTransfers[transferId].slasher = _slasher;
            uint112 slashRefund = _penalty / 5;
            // transfer slashRefund to slasher
            require(providerInfo.slashReserveFund >= slashRefund, "slashReserveFund not enough");
            tgtProviders[providerKey].slashReserveFund = providerInfo.slashReserveFund - slashRefund;
            if (_params.targetToken == address(0)) {
                LnBridgeHelper.safeTransferNative(_slasher, slashRefund);
            } else {
                LnBridgeHelper.safeTransfer(_params.targetToken, _slasher, slashRefund);
            }
        }
        emit Slash(transferId, _remoteChainId, _params.provider, _params.sourceToken, _params.targetToken, updatedMargin, _slasher);
    }
}

// File contracts/ln/interface/ILnDefaultBridgeTarget.sol
// License-Identifier: MIT


interface ILnDefaultBridgeTarget {
    function slash(
        LnBridgeHelper.TransferParameter memory params,
        uint256 remoteChainId,
        address slasher,
        uint112 fee,
        uint112 penalty
    ) external;

    function withdraw(
        uint256 _sourceChainId,
        bytes32 lastTransferId,
        uint64 withdrawNonce,
        address provider,
        address sourceToken,
        address targetToken,
        uint112 amount
    ) external;
}

// File contracts/ln/base/LnDefaultBridgeSource.sol
// License-Identifier: MIT


/// @title LnDefaultBridgeSource
/// @notice LnDefaultBridgeSource is a contract to help user transfer token to liquidity node and generate proof,
///         then the liquidity node must transfer the same amount of the token to the user on target chain.
///         Otherwise if timeout the slasher can send a slash request message to target chain, then force transfer from lnProvider's margin to the user.
/// @dev See https://github.com/helix-bridge/contracts/tree/master/helix-contract
contract LnDefaultBridgeSource {
    // provider fee is paid to liquidity node's account
    // the fee is charged by the same token that user transfered
    // providerFee = baseFee + liquidityFeeRate/LIQUIDITY_FEE_RATE_BASE * sendAmount
    struct SourceProviderConfigure {
        uint112 baseFee;
        uint16 liquidityFeeRate;
        uint64 withdrawNonce;
        bool pause;
    }
    
    struct SourceProviderInfo {
        SourceProviderConfigure config;
        // we use this nonce to generate the unique withdraw id
        bytes32 lastTransferId;
    }
    // the Snapshot is the state of the token bridge when user prepare to transfer across chains.
    // If the snapshot updated when the across chain transfer confirmed, it will
    // 1. if lastTransferId or withdrawNonce updated, revert
    // 2. if totalFee increase, revert
    // 3. if totalFee decrease, success
    struct Snapshot {
        uint256 remoteChainId;
        address provider;
        address sourceToken;
        address targetToken;
        bytes32 transferId;
        uint112 totalFee;
        uint64 withdrawNonce;
    }

    // lock info
    // the fee and penalty is the state of the transfer confirmed
    struct LockInfo {
        uint112 fee;
        uint112 penalty;
        // the timestamp when token locked, if zero, the lockinfo not exist
        uint32 timestamp;
    }

    // hash(remoteChainId, sourceToken, targetToken) => token info
    mapping(bytes32=>LnBridgeHelper.TokenInfo) public tokenInfos;
    // hash(remoteChainId, provider, sourceToken, targetToken) => provider info
    mapping(bytes32=>SourceProviderInfo) public srcProviders;
    // transferId => lock info
    mapping(bytes32=>LockInfo) public lockInfos;

    address public protocolFeeReceiver;

    event TokenLocked(
        uint256 remoteChainId,
        bytes32 transferId,
        address provider,
        address sourceToken,
        address targetToken,
        uint112 amount,
        uint112 fee,
        uint64  timestamp,
        address receiver);
    event LnProviderUpdated(uint256 remoteChainId, address provider, address sourceToken, address targetToken, uint112 baseFee, uint8 liquidityfeeRate);

    event WithdrawMarginRequest(uint256 remoteChainId, address sourceToken, address targetToken, uint112 amount);
    event SlashRequest(uint256 remoteChainId, address sourceToken, address targetToken, bytes32 expectedTransferId);

    // protocolFeeReceiver is the protocol fee reciever, we don't use the contract itself as the receiver
    /// @notice should be called by special privileges
    function _updateFeeReceiver(address _feeReceiver) internal {
        require(_feeReceiver != address(this), "invalid system fee receiver");
        protocolFeeReceiver = _feeReceiver;
    }

    // register or update token info, it can be only called by contract owner
    // source token can only map a unique target token on target chain
    /// @notice should be called by special privileges
    function _setTokenInfo(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _protocolFee,
        uint112 _penaltyLnCollateral,
        uint8 _sourceDecimals,
        uint8 _targetDecimals
    ) internal {
        bytes32 key = keccak256(abi.encodePacked(_remoteChainId, _sourceToken, _targetToken));
        tokenInfos[key] = LnBridgeHelper.TokenInfo(
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

    // lnProvider register
    // 1. set fee on source chain
    // 2. deposit margin on target chain
    function setProviderFee(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _baseFee,
        uint8 _liquidityFeeRate
    ) external {
        bytes32 key = keccak256(abi.encodePacked(_remoteChainId, _sourceToken, _targetToken));
        LnBridgeHelper.TokenInfo memory tokenInfo = tokenInfos[key];
        require(tokenInfo.isRegistered, "token not registered");
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);

        require(_liquidityFeeRate < LnBridgeHelper.LIQUIDITY_FEE_RATE_BASE, "liquidity fee too large");
        SourceProviderConfigure memory providerConfigure = srcProviders[providerKey].config;
        providerConfigure.baseFee = _baseFee;
        providerConfigure.liquidityFeeRate = _liquidityFeeRate;

        // we only update the field fee of the provider info
        // if the provider has not been registered, then this line will register, otherwise update fee
        srcProviders[providerKey].config = providerConfigure;

        emit LnProviderUpdated(_remoteChainId, msg.sender, _sourceToken, _targetToken, _baseFee, _liquidityFeeRate);
    }

    // the fee user should paid when transfer.
    // totalFee = providerFee + protocolFee
    function totalFee(
        uint256 _remoteChainId,
        address _provider,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) external view returns(uint256) {
        bytes32 key = keccak256(abi.encodePacked(_remoteChainId, _sourceToken, _targetToken));
        LnBridgeHelper.TokenInfo memory tokenInfo = tokenInfos[key];
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, _provider, _sourceToken, _targetToken);
        SourceProviderInfo memory providerInfo = srcProviders[providerKey];
        uint112 providerFee = LnBridgeHelper.calculateProviderFee(providerInfo.config.baseFee, providerInfo.config.liquidityFeeRate, _amount);
        return providerFee + tokenInfo.protocolFee;
    }

    // This function transfers tokens from the user to LnProvider and generates a proof on the source chain.
    // The snapshot represents the state of the LN bridge for this LnProvider, obtained by the off-chain indexer.
    // If the chain state is updated and does not match the snapshot state, the transaction will be reverted.
    // 1. the state(lastTransferId, fee, withdrawNonce) must match snapshot
    // 2. transferId not exist
    function transferAndLockMargin(
        Snapshot calldata _snapshot,
        uint112 _amount,
        address _receiver
    ) external payable {
        require(_amount > 0, "invalid amount");
        LnBridgeHelper.TokenInfo memory tokenInfo = tokenInfos[
            LnBridgeHelper.getTokenKey(_snapshot.remoteChainId, _snapshot.sourceToken, _snapshot.targetToken)
        ];
        require(tokenInfo.isRegistered, "token not registered");
        
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_snapshot.remoteChainId, _snapshot.provider, _snapshot.sourceToken, _snapshot.targetToken);

        SourceProviderInfo memory providerInfo = srcProviders[providerKey];
        require(!providerInfo.config.pause, "provider paused");
        uint112 providerFee = LnBridgeHelper.calculateProviderFee(providerInfo.config.baseFee, providerInfo.config.liquidityFeeRate, _amount);

        // the chain state not match snapshot
        require(providerInfo.lastTransferId == _snapshot.transferId, "snapshot expired:transfer");
        require(_snapshot.withdrawNonce == providerInfo.config.withdrawNonce, "snapshot expired:withdraw");
        require(_snapshot.totalFee >= providerFee + tokenInfo.protocolFee && providerFee > 0, "fee is invalid");
        
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
            targetAmount
        ));
        require(lockInfos[transferId].timestamp == 0, "transferId exist");
        // if the transfer refund, then the fee and penalty should be given to slasher, but the protocol fee is ignored
        // and we use the penalty value configure at the moment transfer confirmed
        lockInfos[transferId] = LockInfo(_snapshot.totalFee, tokenInfo.penaltyLnCollateral, uint32(block.timestamp));

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
            targetAmount,
            providerFee,
            uint64(block.timestamp),
            _receiver);
    }

    function _slashAndRemoteReleaseCall(
        LnBridgeHelper.TransferParameter memory _params,
        uint256 _remoteChainId,
        bytes32 _expectedTransferId
    ) internal view returns(bytes memory message) {
        bytes32 key = keccak256(abi.encodePacked(_remoteChainId, _params.sourceToken, _params.targetToken));
        LnBridgeHelper.TokenInfo memory tokenInfo = tokenInfos[key];
        require(tokenInfo.isRegistered, "token not registered");
        uint112 targetAmount = LnBridgeHelper.sourceAmountToTargetAmount(tokenInfo, _params.amount);

        bytes32 transferId = keccak256(abi.encodePacked(
           block.chainid,
           _remoteChainId,
           _params.previousTransferId,
           _params.provider,
           _params.sourceToken,
           _params.targetToken,
           _params.receiver,
           targetAmount
        ));
        require(_expectedTransferId == transferId, "expected transfer id not match");
        LockInfo memory lockInfo = lockInfos[transferId];
        require(lockInfo.timestamp == _params.timestamp, "invalid timestamp");
        require(block.timestamp > lockInfo.timestamp + LnBridgeHelper.SLASH_EXPIRE_TIME, "invalid timestamp");
        uint112 targetFee = LnBridgeHelper.sourceAmountToTargetAmount(tokenInfo, lockInfo.fee);
        uint112 targetPenalty = LnBridgeHelper.sourceAmountToTargetAmount(tokenInfo, lockInfo.penalty);

        message = abi.encodeWithSelector(
           ILnDefaultBridgeTarget.slash.selector,
           _params,
           _remoteChainId,
           msg.sender, // slasher
           targetFee,
           targetPenalty
        );
    }

    function _withdrawMarginCall(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) internal returns(bytes memory message) {
        bytes32 key = keccak256(abi.encodePacked(_remoteChainId, _sourceToken, _targetToken));
        LnBridgeHelper.TokenInfo memory tokenInfo = tokenInfos[key];
        require(tokenInfo.isRegistered, "token not registered");

        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);
        SourceProviderInfo memory providerInfo = srcProviders[providerKey];
        srcProviders[providerKey].config.withdrawNonce = providerInfo.config.withdrawNonce + 1;
        uint112 targetAmount = LnBridgeHelper.sourceAmountToTargetAmount(tokenInfo, _amount);
        message = abi.encodeWithSelector(
            ILnDefaultBridgeTarget.withdraw.selector,
            block.chainid,
            providerInfo.lastTransferId,
            providerInfo.config.withdrawNonce + 1,
            msg.sender, //provider,
            _sourceToken,
            _targetToken,
            targetAmount
        );
    }

    function encodeSlashCall(
        LnBridgeHelper.TransferParameter memory _params,
        uint256 _remoteChainId,
        address _slasher,
        uint112 _fee,
        uint112 _penalty
    ) public pure returns(bytes memory message) {
        return abi.encodeWithSelector(
           ILnDefaultBridgeTarget.slash.selector,
           _params,
           _remoteChainId,
           _slasher,
           _fee,
           _penalty
        );
    }

    function encodeWithdrawCall(
        bytes32 _lastTransferId,
        uint64  _withdrawNonce,
        address _provider,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) public view returns(bytes memory message) {
        return abi.encodeWithSelector(
            ILnDefaultBridgeTarget.withdraw.selector,
            block.chainid,
            _lastTransferId,
            _withdrawNonce,
            _provider,
            _sourceToken,
            _targetToken,
            _amount
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

    function requestWithdrawMargin(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _amount,
        bytes memory _extParams
    ) payable external {
        bytes memory withdrawCallMessage = _withdrawMarginCall(
            _remoteChainId,
            _sourceToken,
            _targetToken,
            _amount
        );
        _sendMessageToTarget(_remoteChainId, withdrawCallMessage, _extParams);
        emit WithdrawMarginRequest(_remoteChainId, _sourceToken, _targetToken, _amount);
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

// File contracts/ln/LnDefaultBridge.sol
// License-Identifier: MIT





contract LnDefaultBridge is Initializable, LnAccessController, LnDefaultBridgeSource, LnDefaultBridgeTarget {
    struct MessagerService {
        address sendService;
        address receiveService;
    }

    // remoteChainId => messager
    mapping(uint256=>MessagerService) public messagers;

    receive() external payable {}

    function initialize(address dao) public initializer {
        _initialize(dao);
        _updateFeeReceiver(dao);
    }

    // the remote endpoint is unique, if we want multi-path to remote endpoint, then the messager should support multi-path
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