// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

import "./base/ABaseTreasureSmolSweepSwapper.sol";

contract TreasureSmolSweepSwapper is ABaseTreasureSmolSweepSwapper {
    constructor(
        address _treasureMarketplace,
        address _defaultPaymentToken,
        IUniswapV2Router02[] memory _swapRouters
    )
        ABaseTreasureSmolSweepSwapper(
            _treasureMarketplace,
            _defaultPaymentToken,
            _swapRouters
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../token/ANFTReceiver.sol";
import "../libraries/SettingsBitFlag.sol";
import "../libraries/Math.sol";
import "../../treasure/interfaces/ITreasureMarketplace.sol";

import "../base/ABaseTreasureSmolSweeper.sol";
import "../base/ABaseSwapper.sol";
import "../interfaces/ITreasureSmolSweepSwapper.sol";

import "../libraries/ArrayUtils.sol";

abstract contract ABaseTreasureSmolSweepSwapper is
    ITreasureSmolSweepSwapper,
    ABaseTreasureSmolSweeper,
    ABaseSwapper
{
    using SafeERC20 for IERC20;
    using SettingsBitFlag for uint16;
    using MemoryArrayUtilsForAddress for address[];

    constructor(
        address _treasureMarketplace,
        address _defaultPaymentToken,
        IUniswapV2Router02[] memory _swapRouters
    )
        ABaseTreasureSmolSweeper(_treasureMarketplace, _defaultPaymentToken)
        ABaseSwapper(_swapRouters)
    {}

    // here the max ETH spend is msg.value. assume msg.value will be all spent
    function buyUsingETH(
        BuyOrder[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        address[] calldata _path,
        uint32 _routerId,
        uint256 _deadline
    ) external payable nonReentrant {
        IUniswapV2Router02 router = swapRouters[_routerId];
        uint256[] memory amountsIn = router.swapExactETHForTokens{
            value: msg.value
        }(0, _path, address(this), _deadline);
        uint256 maxSpendIncFees = amountsIn[amountsIn.length - 1];

        (
            uint256 totalSpentAmount,
            uint256 successCount
        ) = _buyUsingPaymentToken(
                _buyOrders,
                _inputSettingsBitFlag,
                _calculateAmountWithoutFees(maxSpendIncFees)
            );

        // transfer back failed payment tokens to the buyer
        if (successCount == 0) revert AllReverted();

        uint256 feeAmount = _calculateFee(totalSpentAmount);
        uint256 refundAmount = maxSpendIncFees - (totalSpentAmount + feeAmount);
        if (
            _inputSettingsBitFlag.checkSetting(
                SettingsBitFlag.REFUND_IN_INPUT_TOKEN
            )
        ) {
            address[] memory reversePath = _path.reverse();
            IERC20(defaultPaymentToken).approve(address(router), refundAmount);
            uint256[] memory amounts = router.swapExactTokensForETH(
                refundAmount,
                0,
                reversePath,
                address(this),
                _deadline
            );
            payable(msg.sender).transfer(amounts[amounts.length - 1]);
        } else {
            defaultPaymentToken.safeTransfer(msg.sender, refundAmount);
        }
    }

    function buyUsingOtherToken(
        BuyOrder[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        uint256 _maxInputTokenAmount,
        address[] calldata _path,
        uint32 _routerId,
        uint256 _deadline
    ) external nonReentrant {
        IUniswapV2Router02 router = swapRouters[_routerId];
        IERC20(_path[0]).approve(address(router), _maxInputTokenAmount);
        uint256[] memory amountsIn = router.swapExactTokensForTokens(
            _maxInputTokenAmount,
            0,
            _path,
            address(this),
            _deadline
        );
        uint256 maxSpendIncFees = amountsIn[amountsIn.length - 1];

        (
            uint256 totalSpentAmount,
            uint256 successCount
        ) = _buyUsingPaymentToken(
                _buyOrders,
                _inputSettingsBitFlag,
                _calculateAmountWithoutFees(maxSpendIncFees)
            );

        // transfer back failed payment tokens to the buyer
        if (successCount == 0) revert AllReverted();

        uint256 feeAmount = _calculateFee(totalSpentAmount);
        uint256 refundAmount = maxSpendIncFees - (totalSpentAmount + feeAmount);
        if (
            _inputSettingsBitFlag.checkSetting(
                SettingsBitFlag.REFUND_IN_INPUT_TOKEN
            )
        ) {
            address[] memory reversePath = _path.reverse();
            IERC20(defaultPaymentToken).approve(address(router), refundAmount);
            uint256[] memory amounts = router.swapExactTokensForTokens(
                refundAmount,
                0,
                reversePath,
                address(this),
                _deadline
            );
            payable(msg.sender).transfer(amounts[amounts.length - 1]);
        } else {
            defaultPaymentToken.safeTransfer(
                msg.sender,
                maxSpendIncFees - (totalSpentAmount + feeAmount)
            );
        }
    }

    function sweepUsingETH(
        BuyOrder[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        uint32 _maxSuccesses,
        uint32 _maxFailures,
        uint256 _minSpend,
        address[] calldata _path,
        uint32 _routerId,
        uint256 _deadline
    ) external payable nonReentrant {
        IUniswapV2Router02 router = swapRouters[_routerId];
        uint256 maxSpendIncFees;
        {
            uint256[] memory amountsIn = router.swapExactETHForTokens{
                value: msg.value
            }(0, _path, address(this), _deadline);
            maxSpendIncFees = amountsIn[amountsIn.length - 1];
        }

        (
            uint256 totalSpentAmount,
            uint256 successCount
        ) = _sweepUsingPaymentToken(
                _buyOrders,
                _inputSettingsBitFlag,
                _maxSuccesses,
                _maxFailures,
                _calculateAmountWithoutFees(maxSpendIncFees),
                _minSpend
            );

        // transfer back failed payment tokens to the buyer
        if (successCount == 0) revert AllReverted();

        uint256 feeAmount = _calculateFee(totalSpentAmount);
        uint256 refundAmount = maxSpendIncFees - (totalSpentAmount + feeAmount);
        if (
            _inputSettingsBitFlag.checkSetting(
                SettingsBitFlag.REFUND_IN_INPUT_TOKEN
            )
        ) {
            address[] memory reversePath = _path.reverse();
            IERC20(defaultPaymentToken).approve(address(router), refundAmount);
            uint256[] memory amounts = router.swapExactTokensForETH(
                refundAmount,
                0,
                reversePath,
                address(this),
                _deadline
            );
            payable(msg.sender).transfer(amounts[amounts.length - 1]);
        } else {
            defaultPaymentToken.safeTransfer(
                msg.sender,
                maxSpendIncFees - (totalSpentAmount + feeAmount)
            );
        }
    }

    function sweepUsingOtherToken(
        BuyOrder[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        uint32 _maxSuccesses,
        uint32 _maxFailures,
        uint256 _maxInputTokenAmount,
        uint256 _minSpend,
        address[] calldata _path,
        uint32 _routerId,
        uint256 _deadline
    ) external nonReentrant {
        IUniswapV2Router02 router = swapRouters[_routerId];
        uint256 maxSpendIncFees;
        {
            IERC20(_path[0]).approve(address(router), _maxInputTokenAmount);
            uint256[] memory amountsIn = router.swapExactTokensForTokens(
                _maxInputTokenAmount,
                0,
                _path,
                address(this),
                _deadline
            );
            maxSpendIncFees = amountsIn[amountsIn.length - 1];
        }
        (
            uint256 totalSpentAmount,
            uint256 successCount
        ) = _sweepUsingPaymentToken(
                _buyOrders,
                _inputSettingsBitFlag,
                _maxSuccesses,
                _maxFailures,
                _calculateAmountWithoutFees(maxSpendIncFees),
                _minSpend
            );

        // transfer back failed payment tokens to the buyer
        if (successCount == 0) revert AllReverted();

        if (
            _inputSettingsBitFlag.checkSetting(
                SettingsBitFlag.REFUND_IN_INPUT_TOKEN
            )
        ) {
            uint256 refundAmount = maxSpendIncFees -
                (totalSpentAmount + _calculateFee(totalSpentAmount));
            address[] memory reversePath = _path.reverse();
            IERC20(defaultPaymentToken).approve(address(router), refundAmount);
            uint256[] memory amounts = router.swapExactTokensForTokens(
                refundAmount,
                0,
                reversePath,
                address(this),
                _deadline
            );
            payable(msg.sender).transfer(amounts[amounts.length - 1]);
        } else {
            defaultPaymentToken.safeTransfer(
                msg.sender,
                maxSpendIncFees -
                    (totalSpentAmount + _calculateFee(totalSpentAmount))
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
pragma solidity ^0.8.11;
import "../token/ERC1155/AERC1155Receiver.sol";

import "../token/ERC721/AERC721Receiver.sol";

abstract contract ANFTReceiver is AERC721Receiver, AERC1155Receiver {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @dev Settings for a buy order.
 */

library SettingsBitFlag {
    // default action is 0b00000000
    uint16 internal constant NONE = 0x00;

    // if marketplace fails to buy an item for some reason
    // default: will skip the item.
    // if 0x04 is set, will revert the buy transaction.
    uint16 internal constant MARKETPLACE_BUY_ITEM_REVERTED = 0x0001;

    // if the quantity of an item is less than the requested quantity (for ERC1155)
    // default: will skip the item.
    // if 0x02 is set, will buy as many items as possible (all listed items)
    uint16 internal constant INSUFFICIENT_QUANTITY_ERC1155 = 0x0002;

    // if total spend allowance is exceeded
    // default: will skip the item and continue.
    // if 0x08 is set, will skill the item and stop the transaction.
    uint16 internal constant MAX_SPEND_ALLOWANCE_EXCEEDED = 0x0004;

    // refund in the input token
    // default: refunds in the payment token
    // if 0x10 is set, refunds in the input token
    uint16 internal constant REFUND_IN_INPUT_TOKEN = 0x0008;

    // turn on success event logging
    // default: will not log success events.
    // if 0x20 is set, will log success events.
    uint16 internal constant EMIT_SUCCESS_EVENT_LOGS = 0x000C;

    // turn on failure event logging
    // default: will not log failure events.
    // if 0x40 is set, will log failure events.
    uint16 internal constant EMIT_FAILURE_EVENT_LOGS = 0x0010;

    function checkSetting(uint16 _inputSettings, uint16 _settingBit)
        internal
        pure
        returns (bool)
    {
        return (_inputSettings & _settingBit) == _settingBit;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ITreasureMarketplace {
    struct Listing {
        uint256 quantity;
        uint256 pricePerItem;
        uint256 expirationTime;
    }

    function listings(
        address _nftAddress,
        uint256 _tokenId,
        address _seller
    ) external view returns (Listing memory);

    function createListing(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _pricePerItem,
        uint256 _expirationTime
    ) external;

    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newQuantity,
        uint256 _newPricePerItem,
        uint256 _newExpirationTime
    ) external;

    function cancelListing(address _nftAddress, uint256 _tokenId) external;

    /// @notice Buy a listed item. You must authorize this marketplace with your payment token to completed the buy.
    /// @param  _nftAddress      which token contract holds the offered token
    /// @param  _tokenId         the identifier for the token to be bought
    /// @param  _owner           current owner of the item(s) to be bought
    /// @param  _quantity        how many of this token identifier to be bought (or 1 for a ERC-721 token)
    /// @param  _maxPricePerItem the maximum price (in units of the paymentToken) for each token offered
    function buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address _owner,
        uint64 _quantity,
        uint128 _maxPricePerItem
    ) external;

    function addToWhitelist(address _nft) external;

    function removeFromWhitelist(address _nft) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../token/ANFTReceiver.sol";
import "../libraries/SettingsBitFlag.sol";
import "../libraries/Math.sol";
import "../../treasure/interfaces/ITreasureMarketplace.sol";
import "../structs/BuyOrder.sol";
import "../interfaces/ITreasureSmolSweeper.sol";
import "./ABaseSmolSweeper.sol";

// Ownable,
abstract contract ABaseTreasureSmolSweeper is
    ReentrancyGuard,
    ABaseSmolSweeper,
    ITreasureSmolSweeper
{
    using SafeERC20 for IERC20;

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    IERC20 public defaultPaymentToken;
    ITreasureMarketplace public marketplace;

    constructor(address _treasureMarketplace, address _defaultPaymentToken) {
        marketplace = ITreasureMarketplace(_treasureMarketplace);
        defaultPaymentToken = IERC20(_defaultPaymentToken);

        _approveERC20TokenToContract(
            IERC20(_defaultPaymentToken),
            _treasureMarketplace,
            type(uint256).max
        );
    }

    function setMarketplaceContract(ITreasureMarketplace _treasureMarketplace)
        external
        onlyOwner
    {
        marketplace = _treasureMarketplace;
    }

    function setDefaultPaymentToken(IERC20 _defaultPaymentToken)
        external
        onlyOwner
    {
        defaultPaymentToken = _defaultPaymentToken;
    }

    // approve token to TreasureMarketplace contract address
    function approveDefaultPaymentTokensToTreasureMarketplace()
        external
        onlyOwner
    {
        _approveERC20TokenToContract(
            defaultPaymentToken,
            address(marketplace),
            type(uint256).max
        );
    }

    function sumTotalPrice(BuyOrder[] memory _buyOrders)
        internal
        pure
        returns (uint256 totalPrice)
    {
        for (uint256 i = 0; i < _buyOrders.length; i++) {
            totalPrice +=
                _buyOrders[i].quantity *
                _buyOrders[i].maxPricePerItem;
        }
    }

    function tryBuyItem(
        BuyOrder memory _buyOrder,
        uint16 _inputSettingsBitFlag,
        uint256 _maxSpendAllowanceLeft
    )
        internal
        returns (
            uint256 totalPrice,
            bool success,
            uint16 failReason
        )
    {
        uint256 quantityToBuy = _buyOrder.quantity;
        // check if the listing exists
        ITreasureMarketplace.Listing memory listing = marketplace.listings(
            _buyOrder.assetAddress,
            _buyOrder.tokenId,
            _buyOrder.seller
        );

        // // check if the price is correct
        // if (listing.pricePerItem > _buyOrder.maxPricePerItem) {
        //     // skip this item
        //     return (0, false, SettingsBitFlag.MAX_PRICE_PER_ITEM_EXCEEDED);
        // }

        // not enough listed items
        if (listing.quantity < quantityToBuy) {
            if (
                SettingsBitFlag.checkSetting(
                    _inputSettingsBitFlag,
                    SettingsBitFlag.INSUFFICIENT_QUANTITY_ERC1155
                )
            ) {
                // else buy all listed items even if it's less than requested
                quantityToBuy = listing.quantity;
            } else {
                // skip this item
                return (
                    0,
                    false,
                    SettingsBitFlag.INSUFFICIENT_QUANTITY_ERC1155
                );
            }
        }

        // check if total price is less than max spend allowance left
        if ((listing.pricePerItem * quantityToBuy) > _maxSpendAllowanceLeft) {
            // skip this item
            return (0, false, SettingsBitFlag.MAX_SPEND_ALLOWANCE_EXCEEDED);
        }

        uint256 totalSpent = 0;
        try
            marketplace.buyItem(
                _buyOrder.assetAddress,
                _buyOrder.tokenId,
                _buyOrder.seller,
                uint64(quantityToBuy),
                uint128(_buyOrder.maxPricePerItem)
            )
        {
            if (
                SettingsBitFlag.checkSetting(
                    _inputSettingsBitFlag,
                    SettingsBitFlag.EMIT_SUCCESS_EVENT_LOGS
                )
            ) {
                emit SuccessBuyItem(
                    _buyOrder.assetAddress,
                    _buyOrder.tokenId,
                    _buyOrder.seller,
                    msg.sender,
                    quantityToBuy,
                    listing.pricePerItem
                );
            }

            if (
                IERC165(_buyOrder.assetAddress).supportsInterface(
                    INTERFACE_ID_ERC721
                )
            ) {
                IERC721(_buyOrder.assetAddress).safeTransferFrom(
                    address(this),
                    msg.sender,
                    _buyOrder.tokenId
                );
            } else if (
                IERC165(_buyOrder.assetAddress).supportsInterface(
                    INTERFACE_ID_ERC1155
                )
            ) {
                IERC1155(_buyOrder.assetAddress).safeTransferFrom(
                    address(this),
                    msg.sender,
                    _buyOrder.tokenId,
                    quantityToBuy,
                    bytes("")
                );
            } else revert InvalidNFTAddress();

            totalSpent = listing.pricePerItem * quantityToBuy;
        } catch (bytes memory errorReason) {
            if (
                SettingsBitFlag.checkSetting(
                    _inputSettingsBitFlag,
                    SettingsBitFlag.EMIT_FAILURE_EVENT_LOGS
                )
            ) {
                emit CaughtFailureBuyItem(
                    _buyOrder.assetAddress,
                    _buyOrder.tokenId,
                    _buyOrder.seller,
                    msg.sender,
                    quantityToBuy,
                    listing.pricePerItem,
                    errorReason
                );
            }

            if (
                SettingsBitFlag.checkSetting(
                    _inputSettingsBitFlag,
                    SettingsBitFlag.MARKETPLACE_BUY_ITEM_REVERTED
                )
            ) revert FirstBuyReverted(errorReason);
            // skip this item
            return (0, false, SettingsBitFlag.MARKETPLACE_BUY_ITEM_REVERTED);
        }

        return (totalSpent, true, SettingsBitFlag.NONE);
    }

    function buyUsingPaymentToken(
        BuyOrder[] memory _buyOrders,
        uint16 _inputSettingsBitFlag,
        uint256 _maxSpendIncFees
    ) external nonReentrant {
        // transfer payment tokens to this contract
        defaultPaymentToken.safeTransferFrom(
            msg.sender,
            address(this),
            _maxSpendIncFees
        );

        (
            uint256 totalSpentAmount,
            uint256 successCount
        ) = _buyUsingPaymentToken(
                _buyOrders,
                _inputSettingsBitFlag,
                _calculateAmountWithoutFees(_maxSpendIncFees)
            );

        // transfer back failed payment tokens to the buyer
        if (successCount == 0) revert AllReverted();

        uint256 feeAmount = _calculateFee(totalSpentAmount);
        defaultPaymentToken.safeTransfer(
            msg.sender,
            _maxSpendIncFees - (totalSpentAmount + feeAmount)
        );
    }

    function _buyUsingPaymentToken(
        BuyOrder[] memory _buyOrders,
        uint16 _inputSettingsBitFlag,
        uint256 _maxSpendIncFees
    ) internal returns (uint256 totalSpentAmount, uint256 successCount) {
        // buy all assets
        for (uint256 i = 0; i < _buyOrders.length; i++) {
            (
                uint256 spentAmount,
                bool spentSuccess,
                uint16 spentError
            ) = tryBuyItem(
                    _buyOrders[i],
                    _inputSettingsBitFlag,
                    _maxSpendIncFees - totalSpentAmount
                );

            if (spentSuccess) {
                totalSpentAmount += spentAmount;
                successCount++;
            } else {
                if (
                    spentError ==
                    SettingsBitFlag.MAX_SPEND_ALLOWANCE_EXCEEDED &&
                    SettingsBitFlag.checkSetting(
                        _inputSettingsBitFlag,
                        SettingsBitFlag.MAX_SPEND_ALLOWANCE_EXCEEDED
                    )
                ) break;
            }
        }
    }

    function sweepUsingPaymentToken(
        BuyOrder[] memory _buyOrders,
        uint16 _inputSettingsBitFlag,
        uint256 _maxSuccesses,
        uint256 _maxFailures,
        uint256 _maxSpendIncFees,
        uint256 _minSpend
    ) external nonReentrant {
        // transfer payment tokens to this contract
        defaultPaymentToken.safeTransferFrom(
            msg.sender,
            address(this),
            _maxSpendIncFees
        );

        (
            uint256 totalSpentAmount,
            uint256 successCount
        ) = _sweepUsingPaymentToken(
                _buyOrders,
                _inputSettingsBitFlag,
                _maxSuccesses,
                _maxFailures,
                _calculateAmountWithoutFees(_maxSpendIncFees),
                _minSpend
            );

        // transfer back failed payment tokens to the buyer
        if (successCount == 0) revert AllReverted();

        uint256 feeAmount = _calculateFee(totalSpentAmount);
        defaultPaymentToken.safeTransfer(
            msg.sender,
            _maxSpendIncFees - (totalSpentAmount + feeAmount)
        );
    }

    function _sweepUsingPaymentToken(
        BuyOrder[] memory _buyOrders,
        uint16 _inputSettingsBitFlag,
        uint256 _maxSuccesses,
        uint256 _maxFailures,
        uint256 _maxSpendIncFees,
        uint256 _minSpend
    ) internal returns (uint256 totalSpentAmount, uint256 successCount) {
        // buy all assets
        uint256 failCount = 0;
        for (uint256 i = 0; i < _buyOrders.length; i++) {
            if (successCount >= _maxSuccesses || failCount >= _maxFailures)
                break;

            if (totalSpentAmount >= _minSpend) break;

            (
                uint256 spentAmount,
                bool spentSuccess,
                uint16 spentError
            ) = tryBuyItem(
                    _buyOrders[i],
                    _inputSettingsBitFlag,
                    _maxSpendIncFees - totalSpentAmount
                );

            if (spentSuccess) {
                totalSpentAmount += spentAmount;
                successCount++;
            } else {
                if (
                    spentError ==
                    SettingsBitFlag.MAX_SPEND_ALLOWANCE_EXCEEDED &&
                    SettingsBitFlag.checkSetting(
                        _inputSettingsBitFlag,
                        SettingsBitFlag.MAX_SPEND_ALLOWANCE_EXCEEDED
                    )
                ) break;
                failCount++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";

error UniswapV2Router02NotFound(uint256 _id);

abstract contract ABaseSwapper is Ownable {
    using SafeERC20 for IERC20;

    IUniswapV2Router02[] public swapRouters;

    constructor(IUniswapV2Router02[] memory _swapRouters) {
        swapRouters = _swapRouters;
    }

    function getSwapRouterCount() public view returns (uint256) {
        return swapRouters.length;
    }

    function addSwapRouter(IUniswapV2Router02 _router) external onlyOwner {
        swapRouters.push(_router);
    }

    function setSwapRouter(uint256 routerId, IUniswapV2Router02 _router)
        external
        onlyOwner
    {
        if (swapRouters.length < type(uint256).max)
            revert UniswapV2Router02NotFound(routerId);
        swapRouters[routerId] = _router;
    }

    // _routerId: 0 for uniswap, 1 for sushiswap
    function _calculateMinETHInputForOutputTokens(
        address _outputERC20,
        uint256 _outputERC20Amount,
        uint256 _routerId
    ) internal view returns (uint256[] memory) {
        address[] memory path = new address[](2);
        IUniswapV2Router02 router = swapRouters[_routerId];
        path[0] = router.WETH();
        path[1] = _outputERC20;
        return router.getAmountsIn(_outputERC20Amount, path);
    }

    // _routerId: 0 for uniswap, 1 for sushiswap
    function _calculateMinTokensInputForOutputTokens(
        address _inputERC20,
        address _outputERC20,
        uint256 _outputERC20Amount,
        uint256 _routerId
    ) internal view returns (uint256[] memory) {
        address[] memory path = new address[](2);
        IUniswapV2Router02 router = swapRouters[_routerId];
        path[0] = _inputERC20;
        path[1] = address(_outputERC20);
        return router.getAmountsIn(_outputERC20Amount, path);
    }

    // _routerId: 0 for uniswap, 1 for sushiswap
    function _swapTokensForExactTokens(
        address _inputERC20,
        address _outputERC20,
        uint256 _amountOut,
        uint256 _amountInMax,
        uint256 _routerId,
        uint256 _deadline
    ) internal returns (uint256[] memory) {
        address[] memory path = new address[](2);
        IUniswapV2Router02 router = swapRouters[_routerId];
        path[0] = _inputERC20;
        path[1] = address(_outputERC20);
        IERC20(_inputERC20).approve(address(router), _amountInMax);
        return
            router.swapTokensForExactTokens(
                _amountOut,
                _amountInMax,
                path,
                address(this),
                _deadline
            );
    }

    // _routerId: 0 for uniswap, 1 for sushiswap
    function _swapExactTokensForTokens(
        address _inputERC20,
        address _outputERC20,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _routerId,
        uint256 _deadline
    ) internal returns (uint256[] memory) {
        address[] memory path = new address[](2);
        IUniswapV2Router02 router = swapRouters[_routerId];
        path[0] = _inputERC20;
        path[1] = address(_outputERC20);
        IERC20(_inputERC20).approve(address(router), _amountIn);
        return
            router.swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                path,
                address(this),
                _deadline
            );
    }

    // _routerId: 0 for uniswap, 1 for sushiswap
    function _swapExactETHForTokens(
        address _outputERC20,
        uint256 _amountOutMin,
        uint256 _routerId,
        uint256 _deadline
    ) internal returns (uint256[] memory) {
        address[] memory path = new address[](2);
        IUniswapV2Router02 router = swapRouters[_routerId];
        path[0] = router.WETH();
        path[1] = address(_outputERC20);
        return
            router.swapExactETHForTokens{value: msg.value}(
                _amountOutMin,
                path,
                address(this),
                _deadline
            );
    }

    // _routerId: 0 for uniswap, 1 for sushiswap
    function _swapETHForExactTokens(
        address _outputERC20,
        uint256 _amountOut,
        uint256 _routerId,
        uint256 _deadline
    ) internal returns (uint256[] memory) {
        address[] memory path = new address[](2);
        IUniswapV2Router02 router = swapRouters[_routerId];
        path[0] = router.WETH();
        path[1] = address(_outputERC20);
        return
            router.swapETHForExactTokens{value: msg.value}(
                _amountOut,
                path,
                address(this),
                _deadline
            );
    }

    // _routerId: 0 for uniswap, 1 for sushiswap
    function _swapExactTokensForETH(
        address _inputERC20,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _routerId,
        uint256 _deadline
    ) internal returns (uint256[] memory) {
        address[] memory path = new address[](2);
        IUniswapV2Router02 router = swapRouters[_routerId];
        path[0] = address(_inputERC20);
        path[1] = router.WETH();
        IERC20(_inputERC20).approve(address(router), _amountIn);
        return
            router.swapExactTokensForETH(
                _amountIn,
                _amountOutMin,
                path,
                address(this),
                _deadline
            );
    }

    // _routerId: 0 for uniswap, 1 for sushiswap
    function _swapTokensForExactETH(
        address _inputERC20,
        uint256 _amountIn,
        uint256 _amountOutMax,
        uint256 _routerId,
        uint256 _deadline
    ) internal returns (uint256[] memory) {
        address[] memory path = new address[](2);
        IUniswapV2Router02 router = swapRouters[_routerId];
        path[0] = address(_inputERC20);
        path[1] = router.WETH();
        IERC20(_inputERC20).approve(address(router), _amountIn);
        return
            router.swapTokensForExactETH(
                _amountIn,
                _amountOutMax,
                path,
                address(this),
                _deadline
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

import "../structs/BuyOrder.sol";
import "./ITreasureSmolSweeper.sol";

interface ITreasureSmolSweepSwapper is ITreasureSmolSweeper {
    function buyUsingETH(
        BuyOrder[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        address[] calldata _path,
        uint32 _routerId,
        uint256 _deadline
    ) external payable;

    function buyUsingOtherToken(
        BuyOrder[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        uint256 _maxInputTokenAmount,
        address[] calldata _path,
        uint32 _routerId,
        uint256 _deadline
    ) external;

    function sweepUsingETH(
        BuyOrder[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        uint32 _maxSuccesses,
        uint32 _maxFailures,
        uint256 _minSpend,
        address[] calldata _path,
        uint32 _routerId,
        uint256 _deadline
    ) external payable;

    function sweepUsingOtherToken(
        BuyOrder[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        uint32 _maxSuccesses,
        uint32 _maxFailures,
        uint256 _maxInputTokenAmount,
        uint256 _minSpend,
        address[] calldata _path,
        uint32 _routerId,
        uint256 _deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library MemoryArrayUtilsForAddress {
    function reverse(address[] memory input)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory output = new address[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            output[i] = input[input.length - 1 - i];
        }
        return output;
    }

    function indexOf(address[] memory input, address value)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < input.length; i++) {
            if (input[i] == value) {
                return i;
            }
        }
        return input.length;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

abstract contract AERC1155Receiver is IERC1155Receiver {
    /**
     * Always returns `IERC1155Receiver.onERC1155ReceivedFrom.selector`.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * Always returns `IERC1155Receiver.onERC1155BatchReceived.selector`.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

abstract contract AERC721Receiver is IERC721Receiver {
    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

struct BuyOrder {
    address assetAddress;
    uint256 tokenId;
    address seller;
    uint256 quantity;
    uint256 maxPricePerItem;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

import "../structs/BuyOrder.sol";

interface ITreasureSmolSweeper {
    event SuccessBuyItem(
        address indexed _nftAddress,
        uint256 _tokenId,
        address indexed _seller,
        address indexed _buyer,
        uint256 _quantity,
        uint256 _price
    );

    event CaughtFailureBuyItem(
        address indexed _nftAddress,
        uint256 _tokenId,
        address indexed _seller,
        address indexed _buyer,
        uint256 _quantity,
        uint256 _price,
        bytes _errorReason
    );

    function buyUsingPaymentToken(
        BuyOrder[] memory _buyOrders,
        uint16 _inputSettingsBitFlag,
        uint256 _maxSpendIncFees
    ) external;

    function sweepUsingPaymentToken(
        BuyOrder[] memory _buyOrders,
        uint16 _inputSettingsBitFlag,
        uint256 _maxSuccesses,
        uint256 _maxFailures,
        uint256 _maxSpendIncFees,
        uint256 _minSpend
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../../token/ANFTReceiver.sol";

error InvalidNFTAddress();
error FirstBuyReverted(bytes message);
error AllReverted();

abstract contract ABaseSmolSweeper is Ownable, ANFTReceiver, ERC165 {
    using SafeERC20 for IERC20;

    uint256 public constant FEE_BASIS_POINTS = 1_000_000;
    // uint256 public constant MINIMUM_SWEEP_AMOUNT_FOR_FEE = 1_000_000;
    uint256 public sweepFee = 0;

    function _calculateFee(uint256 _amount) internal view returns (uint256) {
        return (_amount / FEE_BASIS_POINTS) * sweepFee;
    }

    function calculateFee(uint256 _amount) external view returns (uint256) {
        return _calculateFee(_amount);
    }

    function _calculateAmountWithoutFees(uint256 _amountWithFee)
        internal
        view
        returns (uint256)
    {
        return
            (_amountWithFee / (FEE_BASIS_POINTS + sweepFee)) * FEE_BASIS_POINTS;
    }

    function calculateAmountAmountWithoutFees(uint256 _amountWithFee)
        external
        view
        returns (uint256)
    {
        return _calculateAmountWithoutFees(_amountWithFee);
    }

    function _setFee(uint256 _fee) internal {
        sweepFee = _fee;
    }

    function setFee(uint256 _fee) external {
        _setFee(_fee);
    }

    function _approveERC20TokenToContract(
        IERC20 _token,
        address _contract,
        uint256 _amount
    ) internal {
        _token.safeApprove(address(_contract), uint256(_amount));
    }

    function approveERC20TokenToContract(
        IERC20 _token,
        address _contract,
        uint256 _amount
    ) external onlyOwner {
        _approveERC20TokenToContract(_token, _contract, _amount);
    }

    // rescue functions
    // those have not been tested yet
    function transferETHTo(address payable _to, uint256 _amount)
        external
        onlyOwner
    {
        _to.transfer(_amount);
    }

    function transferERC20TokenTo(
        IERC20 _token,
        address _address,
        uint256 _amount
    ) external onlyOwner {
        _token.safeTransfer(address(_address), uint256(_amount));
    }

    function transferERC721To(
        IERC721 _token,
        address _to,
        uint256 _tokenId
    ) external onlyOwner {
        _token.safeTransferFrom(address(this), _to, _tokenId);
    }

    function transferERC1155To(
        IERC1155 _token,
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external onlyOwner {
        _token.safeBatchTransferFrom(
            address(this),
            _to,
            _tokenIds,
            _amounts,
            _data
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}