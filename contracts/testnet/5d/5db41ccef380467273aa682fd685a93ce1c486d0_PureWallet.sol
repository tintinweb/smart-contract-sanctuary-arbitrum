// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {TokenManager} from "./libraries/TokenManager.sol";
import {SharesManager} from "./libraries/SharesManager.sol";
import {SwapManager} from "./libraries/SwapManager.sol";
import {Converter} from "./libraries/Converter.sol";

contract PureWallet is ReentrancyGuard {
    using TransferHelper for address;

    error DepositError();
    error RedeemError();
    error UserFeeCalculation();
    error Unauthorized();
    error WalletNonActive();
    error WalletActive();
    error CodeExpired();
    error ReferralCodeExist();

    address internal dev;
    address public immutable WETH;

    uint256 internal timeCreated = block.timestamp;

    // Transaction Fee (deposit and redeem)
    uint256 public FEE_DEPOSIT; //in % or flat
    uint256 public FEE_REDEEM; //in % or flat

    uint32 internal constant FEE_PERCENTAGE = 0;
    uint32 internal constant FEE_FLAT = 1;
    uint32 internal feeType;

    // Percent Denominator
    uint32 internal constant DENOM_PERCENT = 1e6;

    // Action
    uint16 internal constant ACTION_DEPOSIT = 0;
    uint16 internal constant ACTION_REDEEM = 1;

    constructor(address _dev, address _weth, uint32 _feeChoice, uint256 _depositFee, uint256 _redeemFee) {
        owners[msg.sender] = true;
        dev = _dev;
        WETH = _weth;
        feeType = _feeChoice;
        FEE_DEPOSIT = _depositFee;
        FEE_REDEEM = _redeemFee;
        userStatus[_dev].isExcludedFromFee = true;
    }

    modifier ownerOnly() {
        if (!owners[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    //----------USER STATUS RELATED----------//

    struct UserStatus {
        bool isExcludedFromFee;
    }

    mapping(address => UserStatus) public userStatus;

    mapping(address => bool) public owners;

    //----------LOCAL INFORMATION, known only for a user----------//
    //this struct is recording the available offline tokens for each user
    struct Transaction {
        bytes32 offlineToken;
        uint256 amount;
        uint256 createdTime;
    }

    struct Balance {
        uint256 totalConvertedBalance;
        uint256 numTopUps; //start from zero
        mapping(uint256 => Transaction) topUps; // index=>struct Transaction
        mapping(bytes32 => uint256) tokenIdx;
    }

    mapping(address => Balance) internal localOfflineETH;
    mapping(address => mapping(address => Balance)) internal localOffline20; // mapping (addr_user => mapping (addr_token => balance))

    //----------GLOBAL INFORMATION, known for all users----------//
    // Properties of offline tokens
    struct TokenETHProperty {
        //for ETH
        uint256 amount;
        address minter;
        bool isExist;
    }

    struct Token20Property {
        //for ERC20 tokens
        address token;
        uint256 amount;
        address minter;
        bool isExist;
    }

    mapping(bytes32 => TokenETHProperty) internal globalOfflineETH; //for ETH
    mapping(bytes32 => Token20Property) internal globalOffline20; //for ERC20 tokens

    //----------SIGNATURE (HASH-3) ARRAY STORAGE----------//
    struct SignatureProperty {
        bytes32 signature;
        address minter;
        uint256 value;
    }
    //Hash3 library for verification

    SignatureProperty[] public signatureStorageETH; //for ETH
    mapping(address => SignatureProperty[]) public signatureStorageERC20; //for ERC20

    //----------EVENTS----------//
    event DepositSuccess(
        bytes32 indexed tokenSignature, address indexed token, address indexed minter, uint256 amount, uint256 time
    );
    event RedeemSuccess(
        bytes32 indexed offlineToken,
        address indexed token,
        address indexed withdrawer,
        address minter,
        uint256 amount,
        uint256 time
    );
    event NewDev(address indexed newDev, uint256 time);

    //----------FUNCTIONS----------//
    //deposit, only for ETH//
    function depositETH() public payable nonReentrant {
        require(msg.value > 0, "include value");

        //calculate fee
        uint256 fee = userFee(ACTION_DEPOSIT);

        //Split token value based on fee type
        uint256[2] memory dividedAmounts =
            SharesManager.divShares(feeType, ACTION_DEPOSIT, fee, msg.value, DENOM_PERCENT);

        //update token's information locally//
        // update total balance
        localOfflineETH[msg.sender].totalConvertedBalance += dividedAmounts[0];

        //generate offline and signature token//
        (bytes32 offlineToken, bytes32 signature) = TokenManager.genToken(
            msg.sender,
            dividedAmounts[0],
            localOfflineETH[msg.sender].numTopUps,
            block.timestamp - timeCreated,
            blockhash(block.number - 7)
        );

        //publish signature (Hash-3) to public
        SignatureProperty memory newSignatureProperty = SignatureProperty(signature, msg.sender, dividedAmounts[0]);
        signatureStorageETH.push(newSignatureProperty);

        //save real offline token to user's history
        Transaction memory newTransaction = Transaction(offlineToken, dividedAmounts[0], block.timestamp);
        localOfflineETH[msg.sender].topUps[localOfflineETH[msg.sender].numTopUps] = newTransaction;

        //record the offline token's index -> use for redeem later
        localOfflineETH[msg.sender].tokenIdx[offlineToken] = localOfflineETH[msg.sender].numTopUps;

        //update token's information globally//
        TokenETHProperty memory newTokenETHProperty = TokenETHProperty(dividedAmounts[0], msg.sender, true);
        globalOfflineETH[offlineToken] = newTokenETHProperty;

        //update number of top ups
        localOfflineETH[msg.sender].numTopUps++;

        //save dev's share to dev's wallet
        if (!userStatus[msg.sender].isExcludedFromFee) {
            dev.safeTransferETH(dividedAmounts[1]);
        }

        //emit event
        emit DepositSuccess(signature, address(0), msg.sender, dividedAmounts[0], block.timestamp);
    }

    //deposit ERC20 Tokens
    // this function must get approval from the ERC20 token contract
    function depositERC20(address token, uint256 amountWithFee) external nonReentrant {
        require(amountWithFee > 0, "insufficient token");

        //calculate fee
        uint256 fee = userFee(ACTION_DEPOSIT);

        //Split token value based on fee type
        uint256[2] memory dividedAmounts =
            SharesManager.divShares(feeType, ACTION_DEPOSIT, fee, amountWithFee, DENOM_PERCENT);

        //update token's information locally//
        // update total balance
        localOffline20[msg.sender][token].totalConvertedBalance += dividedAmounts[0];

        //generate offline and signature token//
        (bytes32 offlineToken, bytes32 signature) = TokenManager.genToken(
            msg.sender,
            dividedAmounts[0],
            localOffline20[msg.sender][token].numTopUps,
            block.timestamp - timeCreated,
            blockhash(block.number - 7)
        );

        //publish offlineToken3 (Hash-3) to public by online
        SignatureProperty memory newSignatureProperty = SignatureProperty(signature, msg.sender, dividedAmounts[0]);
        signatureStorageERC20[token].push(newSignatureProperty);

        //save to user's history
        Transaction memory newTransaction = Transaction(offlineToken, dividedAmounts[0], block.timestamp);
        localOffline20[msg.sender][token].topUps[localOffline20[msg.sender][token].numTopUps] = newTransaction;

        //update token's information globally//
        Token20Property memory newToken20Property = Token20Property(token, dividedAmounts[0], msg.sender, true);
        globalOffline20[offlineToken] = newToken20Property; //update everything

        //update number of top ups
        localOffline20[msg.sender][token].numTopUps++;

        //emit event
        emit DepositSuccess(signature, token, msg.sender, dividedAmounts[0], block.timestamp);

        //deposit ERC-20 token with amountWithFee from connector (msg.sender) to this contract
        token.safeTransferFrom(msg.sender, address(this), amountWithFee);

        //transfer dev's shares
        if (!userStatus[msg.sender].isExcludedFromFee) {
            token.safeTransfer(dev, dividedAmounts[1]);
        }
    }

    //redeem ETH
    function redeemETH(bytes32 offlineToken) external nonReentrant {
        require(globalOfflineETH[offlineToken].isExist, "Token not found"); //check existence of real offline token

        //Create hash-3 and its existence
        bytes32 signature = TokenManager.genSignature(offlineToken);

        //Erase Hash3 Globally//
        uint256 lastIndexSignature = signatureStorageETH.length - 1;
        for (uint256 i = 0; i < signatureStorageETH.length; i++) {
            if (signatureStorageETH[i].signature == signature) {
                signatureStorageETH[i] = signatureStorageETH[lastIndexSignature];
                signatureStorageETH.pop();
            }
        }

        //change token's information locally//
        address minter = globalOfflineETH[offlineToken].minter; //get token owner from global variable

        //substract token minter's balance after redeeming
        localOfflineETH[minter].totalConvertedBalance -= globalOfflineETH[offlineToken].amount;

        //erase offline token's info in minter's account based on its index
        localOfflineETH[minter].topUps[localOfflineETH[minter].tokenIdx[offlineToken]].offlineToken = bytes32(0);

        //change token's information globally//
        globalOfflineETH[offlineToken].isExist = false; //make the token not available

        //emit event
        emit RedeemSuccess(
            offlineToken,
            address(0),
            msg.sender,
            globalOfflineETH[offlineToken].minter,
            globalOfflineETH[offlineToken].amount,
            block.timestamp
        );

        //calculate fee
        uint256 fee = userFee(ACTION_REDEEM);

        //Split token value based on fee type
        uint256[2] memory dividedAmounts =
            SharesManager.divShares(feeType, ACTION_REDEEM, fee, globalOfflineETH[offlineToken].amount, DENOM_PERCENT);

        //transfer the token's amount to msg.sender
        (msg.sender).safeTransferETH(dividedAmounts[0]);

        //save dev's share to dev's wallet
        if (!userStatus[msg.sender].isExcludedFromFee) {
            dev.safeTransferETH(dividedAmounts[1]);
        }
    }

    //redeem ERC-20
    function redeemERC20(address token, bytes32 offlineToken) external nonReentrant {
        require(globalOffline20[offlineToken].isExist, "Token not found"); //check existence of real offline token

        //Create hash-3
        bytes32 signature = TokenManager.genSignature(offlineToken);

        //Erase Hash3 Globally//
        uint256 lastIndexSignature = signatureStorageERC20[token].length - 1;
        for (uint256 i = 0; i < signatureStorageERC20[token].length; i++) {
            if (signatureStorageERC20[token][i].signature == signature) {
                signatureStorageERC20[token][i] = signatureStorageERC20[token][lastIndexSignature];
                signatureStorageERC20[token].pop();
            }
        }

        //change token's information locally//
        address minter = globalOffline20[offlineToken].minter; //get token owner from global variable

        //substract token minter's balance before redeeming
        localOffline20[minter][token].totalConvertedBalance -= globalOffline20[offlineToken].amount;

        //erase offline token's info in minter's account by overwrite the selected token with the latest offline token based on its index
        localOffline20[minter][token].topUps[localOffline20[minter][token].tokenIdx[offlineToken]].offlineToken =
            bytes32(0);

        //change token's information globally//
        globalOffline20[offlineToken].isExist = false; //make the token not available

        //emit event
        emit RedeemSuccess(
            offlineToken,
            token,
            msg.sender,
            globalOffline20[offlineToken].minter,
            globalOffline20[offlineToken].amount,
            block.timestamp
        );

        //calculate fee
        uint256 fee = userFee(ACTION_REDEEM);

        //Split token value based on fee type
        uint256[2] memory dividedAmounts =
            SharesManager.divShares(feeType, ACTION_REDEEM, fee, globalOffline20[offlineToken].amount, DENOM_PERCENT);

        //transfer the token value (with fee deduction) to msg.sender
        token.safeTransfer(msg.sender, dividedAmounts[0]);

        //transfer dev's share to dev's account
        if (!userStatus[msg.sender].isExcludedFromFee) {
            token.safeTransfer(dev, dividedAmounts[1]);
        }
    }

    // Internal Functions
    function userFee(uint16 actionType) internal view returns (uint256) {
        uint256 fee;
        if (userStatus[msg.sender].isExcludedFromFee) {
            fee = 0;
        } else if (actionType == ACTION_DEPOSIT) {
            fee = FEE_DEPOSIT;
        } else if (actionType == ACTION_REDEEM) {
            fee = FEE_REDEEM;
        } else {
            revert();
        }
        return fee;
    }

    //----------FUNCTIONS ONLY FOR DEV AND OWNER----------//

    //change fee choice (percentage or flat, deposit, and redeem fees)
    function changeTxFee(uint32 _feeChoice, uint256 newDepositFee, uint256 newRedeemFee) external ownerOnly {
        feeType = _feeChoice;
        FEE_DEPOSIT = newDepositFee;
        FEE_REDEEM = newRedeemFee;
    }

    //changeDev
    function changeDev(address newDev) external ownerOnly {
        //change with the new dev
        dev = newDev;
        emit NewDev(newDev, block.timestamp);
    }

    //add or remove ownership priviledge
    function changeOwnerPriviledge(address user) external ownerOnly {
        owners[user] = !owners[user];
    }

    //get ETH total deposit for an account
    function totalDepositETH() external view returns (uint256) {
        return localOfflineETH[msg.sender].totalConvertedBalance;
    }

    //get ERC20 token total deposit for an account
    function totalDepositERC20(address token) external view returns (uint256) {
        return localOffline20[msg.sender][token].totalConvertedBalance;
    }

    //get counter for ETH offline tokens
    function depositCounterETH() external view returns (uint256) {
        return localOfflineETH[msg.sender].numTopUps;
    }

    //get counter for ERC20 offline tokens
    function depositCounterERC20(address token) external view returns (uint256) {
        return localOffline20[msg.sender][token].numTopUps;
    }

    //View history of deposited ETH offline tokens by their order
    // (offline token, amount, and it's created time)
    function getHistoryETH(uint256 idx) external view returns (bytes32, uint256, uint256) {
        return (
            localOfflineETH[msg.sender].topUps[idx].offlineToken,
            localOfflineETH[msg.sender].topUps[idx].amount,
            localOfflineETH[msg.sender].topUps[idx].createdTime
        );
    }

    //View history of deposited ERC-20 offline tokens by their order
    function getHistoryERC20(address token, uint256 idx) external view returns (bytes32, uint256, uint256) {
        return (
            localOffline20[msg.sender][token].topUps[idx].offlineToken,
            localOffline20[msg.sender][token].topUps[idx].amount,
            localOffline20[msg.sender][token].topUps[idx].createdTime
        );
    }

    receive() external payable {
        depositETH();
    }

    fallback() external payable {
        depositETH();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with "STF" if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with "SA" if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SA");
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library TokenManager {
    //generate offline and signature token
    function genToken(address caller, uint256 topUpAmount, uint256 numTopUps, uint256 uniqueNo, bytes32 uniqueHash)
        internal
        pure
        returns (bytes32, bytes32)
    {
        bytes32 offlineToken = tokenManagerKeccak(caller, topUpAmount, numTopUps, uniqueNo, uniqueHash);
        bytes32 sigToken = genSignature(offlineToken);
        return (offlineToken, sigToken);
    }

    function tokenManagerKeccak(address value1, uint256 value2, uint256 value3, uint256 value4, bytes32 value5)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(value1, value2, value3, value4, value5));
    }

    function tokenManagerSHA(bytes32 offlineTokenHex) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(offlineTokenHex));
    }

    //token manager assistant-1
    function toHex(bytes32 data) internal pure returns (bytes32) {
        return bytes32(abi.encodePacked("0x", toHex16(bytes16(data)), toHex16(bytes16(data << 128))));
    }

    //token manager assistant-2
    function toHex16(bytes16 data) internal pure returns (bytes32 result) {
        result = (bytes32(data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000)
            | ((bytes32(data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64);
        result = (result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000)
            | ((result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32);
        result = (result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000)
            | ((result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16);
        result = (result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000)
            | ((result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8);
        result = ((result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4)
            | ((result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8);
        result = bytes32(
            0x3030303030303030303030303030303030303030303030303030303030303030 + uint256(result)
                + (
                    ((uint256(result) + 0x0606060606060606060606060606060606060606060606060606060606060606) >> 4)
                        & 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
                ) * 39
        );
    }

    //Generate Hash3
    function genSignature(bytes32 realToken) internal pure returns (bytes32) {
        return tokenManagerSHA(toHex(tokenManagerSHA(toHex(realToken))));
    }

    // Swap
    function createPath(address tokenIn, address tokenOut) internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = tokenIn; //input token
        path[1] = tokenOut; //output token
        return path;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "forge-std/console.sol";

library SharesManager {
    error DividingFeeError();
    error ActionError();

    function divSharesAW(
        address rcv,
        uint32 callerSharesNoReferral,
        uint32 callerSharesWithReferral,
        uint32 rcvShares,
        uint32 baseShares,
        uint256 walletActFee
    ) internal pure returns (uint256[3] memory) {
        uint256[3] memory values;
        uint32 callerShares = (rcv == address(0)) ? callerSharesNoReferral : callerSharesWithReferral;

        values[0] = (walletActFee * callerShares) / baseShares; // to caller
        values[1] = (rcv == address(0)) ? 0 : (walletActFee * rcvShares) / baseShares; // to code referer
        values[2] = walletActFee - values[0] - values[1]; // to dev

        return values;
    }

    // calculate shares when depositing/redeeming
    function divShares(uint32 feeType, uint16 actionType, uint256 fee, uint256 tokenValue, uint256 DENOM_PERCENT)
        internal
        pure
        returns (uint256[2] memory)
    {
        uint256[2] memory dividedAmounts;
        if (feeType == 0) {
            if (actionType == 0) {
                /*
                tokenValue = addedAmount
                originalAmount = addedAmount / (1 + feeInDecimal)
                    = addedAmount / (1 + fee/DENOM_PERCENT)
                    = (DENOM_PERCENT * addedAmount) / (DENOM_PERCENT + fee)
                */
                dividedAmounts[0] = (DENOM_PERCENT * tokenValue) / (DENOM_PERCENT + fee);
                dividedAmounts[1] = tokenValue - dividedAmounts[0];
            } else if (actionType == 1) {
                dividedAmounts[1] = (tokenValue * fee) / DENOM_PERCENT; //amount to dev
                dividedAmounts[0] = tokenValue - dividedAmounts[1]; //amount to user
            } else {
                revert ActionError();
            }
        } else if (feeType == 1) {
            dividedAmounts[0] = tokenValue - fee;
            dividedAmounts[1] = fee;
        } else {
            revert DividingFeeError();
        }
        return dividedAmounts;
    }

    //calculate final price after fee
    function calcFinalDepositAmount(uint256 fee, uint256 DENOM_PERCENT, uint256 initPrice)
        internal
        pure
        returns (uint256)
    {
        return initPrice + ((initPrice * fee) / DENOM_PERCENT);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenManager} from "./TokenManager.sol";
import {ISwapV2Router} from "../interfaces/ISwapV2SupportingFee.sol";

library SwapManager {
    //convert ETH and send MMAI to sideAcc directly
    function ethToMMAI(ISwapV2Router swap, address sideAcc, address weth, address mmai, uint256 value) internal {
        // swap ETH to MMAI
        address[] memory path = TokenManager.createPath(weth, mmai);
        swap.swapExactETHForTokensSupportingFeeOnTransferTokens{value: value}(
            1000, path, sideAcc, block.timestamp + 3600
        );
    }
    //convert WETH and send MMAI to sideAcc directly

    function wethToMMAI(ISwapV2Router swap, address sideAcc, address weth, address mmai, uint256 value) internal {
        // swap ETH to MMAI
        address[] memory path = TokenManager.createPath(weth, mmai);
        swap.swapExactTokensForTokensSupportingFeeOnTransferTokens(value, 1000, path, sideAcc, block.timestamp + 3600);
    }

    //convert Tokens to WETH and save into smart contract
    function tokensToWETH(ISwapV2Router swap, address sender, address tokenIn, address weth, uint256 value)
        internal
        returns (uint256[] memory)
    {
        // ETH uses WETH as its path
        address[] memory pathETH = TokenManager.createPath(tokenIn, weth); //create path for WETH
        uint256[] memory ethAmounts = swap.swapExactTokensForTokens(value, 1e9, pathETH, sender, block.timestamp + 3600);
        return ethAmounts;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Converter {
    function stringToBytes32(string memory s) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            result := mload(add(s, 32))
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

interface ISwapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}