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
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract AlphaVaultSwap is Ownable {
    // AlphaVault custom events
    event WithdrawTokens(IERC20 buyToken, uint256 boughtAmount_);
    event EtherBalanceChange(uint256 wethBal_);
    event BadRequest(uint256 wethBal_, uint256 reqAmount_);
    event ZeroXCallSuccess(bool status, uint256 initialBuyTokenBalance);
    event buyTokenBought(uint256 buTokenAmount);
    event maxTransactionsChange(uint256 maxTransactions);

    /**
     * @dev Event to notify if transfer successful or failed
     * after account approval verified
     */
    event TransferSuccessful(
        address indexed from_,
        address indexed to_,
        uint256 amount_
    );

    error InvalidAddress();
    error Invalid_Multiswap_Data();
    error FillQuote_Swap_Failed(IERC20 buyToken,IERC20 sellToken);


    struct wethInfo{
        uint256 eth_balance;
        IWETH wETH;
    }
    // The WETH contract.
    IWETH public immutable WETH;
    // IERC20 ERC20Interface;

    uint256 public maxTransactions;
    uint256 public fee;
    // address private destination;

    constructor() {
        WETH = IWETH(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        maxTransactions = 25;
        fee = 5;
    }

    /**
     * @dev method that handles transfer of ERC20 tokens to other address
     * it assumes the calling address has approved this contract
     * as spender
     * @param amount numbers of token to transfer
     */
    function depositToken(IERC20 sellToken, uint256 amount) private {
        // require(amount > 0);
        // ERC20Interface = IERC20(sellToken);

        // if (amount > ERC20Interface.allowance(msg.sender, address(this))) {
        //     emit TransferFailed(msg.sender, address(this), amount);
        //     revert();
        // }

        // bool success = ERC20Interface.transferFrom(msg.sender, address(this), amount);
        sellToken.transferFrom(msg.sender, address(this), amount);
        emit TransferSuccessful(msg.sender, address(this), amount);
    }

    function setfee(uint256 num) external onlyOwner {
        fee = num;
    }

    function setMaxTransactionLimit(uint256 num) external onlyOwner {
        maxTransactions = num;
        emit maxTransactionsChange(maxTransactions);
    }

    // function withdrawFee(IERC20 token, uint256 amount) external onlyOwner{
    //     token.transfer(msg.sender, amount);
    // }

    // Transfer ETH held by this contrat to the sender/owner.
    function withdrawETH(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable {}

    fallback() external payable {}

    // Transfer tokens held by this contrat to the sender/owner.
    function withdrawToken(IERC20 token, uint256 amount) internal {
        token.transfer(msg.sender, amount);
    }

    //Sets destination address to msg.sender
    function setDestination() internal view returns (address) {
        // destination = msg.sender;
        return msg.sender;
    }

    // Transfer amount of ETH held by this contrat to the sender.
    function transferEth(uint256 amount, address msgSender) internal {
        payable(msgSender).transfer(amount);
    }

    // Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
    function fillQuote(
        // The `buyTokenAddress` field from the API response.
        IERC20 buyToken,
        IERC20 sellToken,
        // The `allowanceTarget` field from the API response.
        address spender,
        // The `to` field from the API response.
        address swapTarget,
        // The `data` field from the API response.
        bytes calldata swapCallData
    ) internal returns (uint256) {
        if(spender == address(0)) revert InvalidAddress();
        // Track our balance of the buyToken to determine how much we've bought.
        uint256 boughtAmount = buyToken.balanceOf(address(this));
        sellToken.approve(spender, type(uint128).max);
        (bool success, ) = swapTarget.call{value: 0}(swapCallData);
        emit ZeroXCallSuccess(success, boughtAmount);
        if(!success) revert FillQuote_Swap_Failed({buyToken:buyToken,sellToken:sellToken});
        boughtAmount = buyToken.balanceOf(address(this)) - boughtAmount;
        emit buyTokenBought(boughtAmount);
        return boughtAmount;
    }

    /**
     * @param sellToken addresses of sell tokens
     * @param buyToken addresses of sell tokens
     * @param amount numbers of token to transfer  in unit256
     * 
     */
    function multiSwap(
        IERC20[] calldata sellToken,
        IERC20[] calldata buyToken,
        address[] calldata spender,
        address payable[] calldata swapTarget,
        bytes[] calldata swapCallData,
        uint256[] memory amount
    ) external payable {
        if(!(
            sellToken.length <= maxTransactions &&
                sellToken.length == buyToken.length &&
                spender.length == buyToken.length &&
                swapTarget.length == spender.length))
            revert Invalid_Multiswap_Data();

        wethInfo memory WethInfo= wethInfo(0,WETH);

        if (msg.value > 0) {
            WethInfo.wETH.deposit{value: msg.value}();
            WethInfo.eth_balance = msg.value-fee;
            WethInfo.wETH.transfer(owner(), fee);
            emit EtherBalanceChange(WethInfo.eth_balance);
        }

        for (uint256 i = 0; i < spender.length; i++) {
            // ETHER & WETH Withdrawl request.
            if (spender[i] == address(0)) {
                if (WethInfo.eth_balance < amount[i]) {
                    emit BadRequest(WethInfo.eth_balance, amount[i]);
                    break;
                }
                if (amount[i] > 0) {
                    WethInfo.eth_balance -= amount[i];
                    WethInfo.wETH.withdraw(amount[i]);
                    transferEth(amount[i], setDestination());
                    emit EtherBalanceChange(WethInfo.eth_balance);
                }
                continue;
            }
            // Condition For using Deposited Ether before using WETH From user balance.
            if (sellToken[i] == WethInfo.wETH) {
                if (sellToken[i] == buyToken[i]) {
                    depositToken(sellToken[i], amount[i]);
                    WethInfo.eth_balance += amount[i];
                    emit EtherBalanceChange(WethInfo.eth_balance);
                    continue;
                }
                WethInfo.eth_balance -= amount[i];
                emit EtherBalanceChange(WethInfo.eth_balance);
            } else {
                depositToken(sellToken[i], amount[i]);
            }

            // Variable to store amount of tokens purchased.
            uint256 boughtAmount = fillQuote(
                buyToken[i],
                sellToken[i],
                spender[i],
                swapTarget[i],
                swapCallData[i]
            );

            if (buyToken[i] == WethInfo.wETH) {
                WethInfo.eth_balance += boughtAmount;
                emit EtherBalanceChange(WethInfo.eth_balance);
            } else {
                withdrawToken(buyToken[i], boughtAmount);
                emit WithdrawTokens(buyToken[i], boughtAmount);
            }
        }
        if (WethInfo.eth_balance > 0) {
            withdrawToken(WethInfo.wETH, WethInfo.eth_balance);
            emit EtherBalanceChange(0);
        }
    }
}