// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IMetapoolFactory.sol";
import "./interfaces/IStableSwap.sol";
import "./interfaces/IRouter.sol";
import "./utils/BaseRouter.sol";
import "./utils/HpsmUtils.sol";
import "./RouterHpsmHlpV2.sol";

/**
 * This contract swaps a pegged token in the handle.fi Peg Stability Module (hPSM) to
 * a token in a specified handle curve metapool, via a token in the handle.fi
 * Liquidity Pool (hLP) if applicable.
 *
 * @dev safeApprove is intentionally not used, as since this contract should not store
 * funds between transactions, the approval race vulnerability does not apply.
 *
 *                ,.-"""-.,                       *
 *               /   ===   \                      *
 *              /  =======  \                     *
 *           __|  (o)   (0)  |__                  *
 *          / _|    .---.    |_ \                 *
 *         | /.----/ O O \----.\ |                *
 *          \/     |     |     \/                 *
 *          |                   |                 *
 *          |                   |                 *
 *          |                   |                 *
 *          _\   -.,_____,.-   /_                 *
 *      ,.-"  "-.,_________,.-"  "-.,             *
 *     /          |       |  ╭-╮     \            *
 *    |           l.     .l  ┃ ┃      |           *
 *    |            |     |   ┃ ╰━━╮   |           *
 *    l.           |     |   ┃ ╭╮ ┃  .l           *
 *     |           l.   .l   ┃ ┃┃ ┃  | \,         *
 *     l.           |   |    ╰-╯╰-╯ .l   \,       *
 *      |           |   |           |      \,     *
 *      l.          |   |          .l        |    *
 *       |          |   |          |         |    *
 *       |          |---|          |         |    *
 *       |          |   |          |         |    *
 *       /"-.,__,.-"\   /"-.,__,.-"\"-.,_,.-"\    *
 *      |            \ /            |         |   *
 *      |             |             |         |   *
 *       \__|__|__|__/ \__|__|__|__/ \_|__|__/    *
 */
contract RouterHpsmHlpCurve is BaseRouter, HpsmUtils {
    using SafeERC20 for IERC20;

    /** @notice Address of the handle.fi RouterHpsmHlp */
    address public routerHpsmHlp;

    event ChangeRouterHpsmHlp(address routerHpsmHlp);

    constructor(address _hpsm, address _routerHpsmHlp) HpsmUtils(_hpsm) {
        routerHpsmHlp = _routerHpsmHlp;
        emit ChangeRouterHpsmHlp(_routerHpsmHlp);
    }

    /** @notice Sets the address of the handle.fi RouterHpsmHlp */
    function setRouterHpsmHlp(address _routerHpsmHlp) external onlyOwner {
        require(routerHpsmHlp != _routerHpsmHlp, "Address already set");
        routerHpsmHlp = _routerHpsmHlp;
        emit ChangeRouterHpsmHlp(_routerHpsmHlp);
    }

    /**
     * @notice Swaps tokens in a curve.fi metapool
     * @param from the token to be sent
     * @param to the token to be received
     * @param amount the amount of {from} to send
     * @param metapoolFactory curve.fi metapool factory (the factory that deployed {pool})
     * @param pool The metapool that has {from} and {to} as either tokens or underlying tokens
     * @return the amount of {to} received from the swap
     */
    function _curvePoolSwap(
        address from,
        address to,
        uint256 amount,
        address metapoolFactory,
        address pool
    ) internal returns (uint256) {
        (
            int128 fromIndex,
            int128 toIndex,
            bool useUnderlying
        ) = IMetapoolFactory(metapoolFactory).get_coin_indices(pool, from, to);

        IERC20(from).approve(pool, amount);

        // min out is not handled here, which is why the last param is zero
        if (useUnderlying) {
            return
                IStableSwap(pool).exchange_underlying(
                    fromIndex,
                    toIndex,
                    amount,
                    0
                );
        }

        return IStableSwap(pool).exchange(fromIndex, toIndex, amount, 0);
    }

    /**
     * @notice swaps {peggedToken} for {curveToken}, using the hPSM and hLP (if applicable) as intermediate steps
     * @param peggedToken the pegged token in the hPSM to be sent
     * @param fxToken the token in the hPSM that is pegged against {peggedToken}
     * @param hlpToken the token received when swapping {fxToken} in the hLP
     * @dev if {fxToken} is the same as {hlpToken}, no swap between the two will occur
     * @param tokenOut the token received when swapping {hlpToken} in the curve.fi metapool.
     * This token will be sent to {receiver}
     * @param amountIn the amount of {peggedToken} to be sent
     * @param receiver the address that will receive {curveToken} at the end of the transaction
     * @param minOut the minimum amount of {curveToken} that will be sent to {receiver}
     * @dev If the amount out is less than {minOut}, the transaction will revert
     * @param metapoolFactory curve.fi metapool factory (the factory that deployed {pool})
     * @param pool The metapool that has {hlpToken} and {curveToken} as either tokens or underlying tokens
     * @param signedQuoteData The signed quote data to be sent to the handle.fi fast oracles
     * @dev {signedQuoteData} is only required if {fxToken} is not the same as {hlpToken}
     */
    function swapPeggedTokenToCurveToken(
        address peggedToken,
        address fxToken,
        address hlpToken,
        address tokenOut,
        uint256 amountIn,
        address receiver,
        uint256 minOut,
        address metapoolFactory,
        address pool,
        bytes calldata signedQuoteData
    ) external {
        require(peggedToken != tokenOut, "Token in cannot be token out");
        require(amountIn > 0, "Amount in cannot be zero");

        _transferIn(peggedToken, amountIn); // transfer in funds

        if (fxToken == hlpToken) {
            // if fxToken and hlpToken are the same, only one swap in the
            // hpsm needs to be made
            _hpsmDeposit(peggedToken, fxToken, amountIn);
        } else {
            // use multi step router if fx token and hlp token are different
            IERC20(peggedToken).approve(routerHpsmHlp, amountIn);
            RouterHpsmHlpV2(routerHpsmHlp).swapPeggedTokenToHlpToken(
                peggedToken,
                fxToken,
                hlpToken,
                amountIn,
                0, // min out handled at end of function
                _self,
                signedQuoteData
            );
        }

        uint256 curveTokenAmountIn = _balanceOfSelf(hlpToken);
        _curvePoolSwap(
            hlpToken,
            tokenOut,
            curveTokenAmountIn,
            metapoolFactory,
            pool
        );

        uint256 amountOut = _balanceOfSelf(tokenOut);
        require(amountOut >= minOut, "Insufficient amount out");

        IERC20(tokenOut).safeTransfer(receiver, amountOut);
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.7;

/**
 * Documentation based on https://curve.readthedocs.io/factory-deployer.html
 */
interface IMetapoolFactory {
    /**
     * Convert coin addresses into indices for use with pool methods.
     *
     * Returns the index of _from, index of _to, and a boolean indicating
     * if the coins are considered underlying in the given pool.
     *
     * @dev Example:
     *      >>> factory.get_coin_indices(pool, token1, token2)
     *      (0, 2, true)
     *
     * Based on the above call, we know:
     *  - the index of the coin we are swapping out of is 2
     *  - the index of the coin we are swapping into is 1
     *  - the coins are considred underlying, so we must call exchange_underlying
     *
     * From this information we can perform a token swap:
     *      >>> swap = Contract('0xFD9f9784ac00432794c8D370d4910D2a3782324C')
     *      >>> swap.exchange_underlying(2, 1, 1e18, 0, {'from': alice})
     */
    function get_coin_indices(
        address pool,
        address _from,
        address _to
    )
        external
        view
        returns (
            int128,
            int128,
            bool
        );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.7;

/**
 * Documentation based on https://curve.readthedocs.io/factory-pools.html
 */
interface IStableSwap {
    /**
     * Perform an exchange between two underlying coins.
     * Index values can be found using get_underlying_coins within the factory contract.
     *
     * @param i Index value of the underlying token to send.
     * @param j Index value of the underlying token to receive.
     * @param _dx: The amount of i being exchanged.
     * @param _min_dy: The minimum amount of j to receive. If the swap would result in
     * less, the  * transaction will revert.
     *
     * @return the amount of j received in the exchange.
     */
    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);

    /**
     * Performs an exchange between two tokens.
     * Index values can be found using the coins public getter method,
     * or get_coins within the factory contract.
     *
     * @param i Index value of the token to send.
     * @param j Index value of the token to receive.
     * @param _dx: The amount of i being exchanged.
     * @param _min_dy: The minimum amount of j to receive. If the swap would result in
     * less, the  * transaction will revert.
     *
     * @return the amount of j received in the exchange.
     */
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.7;

interface IRouter {
    function weth() external returns (address);

    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver,
        bytes calldata signedQuoteData
    ) external;

    function swapTokensToETH(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address payable _receiver,
        bytes calldata signedQuoteData
    ) external;

    function swapETHToTokens(
        address[] memory _path,
        uint256 _minOut,
        address _receiver,
        bytes calldata signedQuoteData
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BaseRouter {
    using SafeERC20 for IERC20;

    address internal immutable _self;

    constructor() {
        _self = address(this);
    }

    /** @notice Transfers in an ERC20 token */
    function _transferIn(address token, uint256 amount) internal {
        IERC20(token).safeTransferFrom(msg.sender, _self, amount);
    }

    /** @return the {token} balance of this contract */
    function _balanceOfSelf(address token) internal view returns (uint256) {
        return IERC20(token).balanceOf(_self);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@handle-fi/handle-psm/contracts/hPSM.sol";

/*
 * @dev safeApprove is intentionally not used, as since this contract should not store
 * funds between transactions, the approval race vulnerability does not apply.
 */
abstract contract HpsmUtils is Ownable {
    using SafeERC20 for IERC20;

    address public hpsm;

    event ChangeHpsm(address newPsm);

    constructor(address _hpsm) {
        hpsm = _hpsm;
        emit ChangeHpsm(hpsm);
    }

    /** @notice Sets the peg stability module address*/
    function setHpsm(address _hpsm) external onlyOwner {
        require(hpsm != _hpsm, "Address already set");
        hpsm = _hpsm;
        emit ChangeHpsm(hpsm);
    }

    /**
     * @notice Deposits pegged token for fxToken in the hPSM
     * @param peggedToken the token to be deposited
     * @param fxToken the token to receive
     * @param amount the amount of {peggedToken} to deposit
     */
    function _hpsmDeposit(
        address peggedToken,
        address fxToken,
        uint256 amount
    ) internal {
        // approve hPSM for amount
        IERC20(peggedToken).approve(hpsm, amount);

        // deposit in hPSM
        hPSM(hpsm).deposit(fxToken, peggedToken, amount);
    }

    /**
     * @notice Withdraws peggedToken for fxToken in
     * @param fxToken the token to burn
     * @param peggedToken the token to receive
     * @param amount the amount of {fxToken} to burn
     */
    function _hpsmWithdraw(
        address fxToken,
        address peggedToken,
        uint256 amount
    ) internal {
        // No approval is needed as the hpsm can mint/burn fxtokens
        hPSM(hpsm).withdraw(fxToken, peggedToken, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@handle-fi/handle-psm/contracts/hPSM.sol";
import "./interfaces/IRouter.sol";
import "./utils/HlpRouterUtils.sol";
import "./utils/BaseRouter.sol";
import "./utils/HpsmUtils.sol";

/**
 * This contract:
 *     - swaps a pegged token in the handle.fi Peg Stability Module (hPSM) to
 *         a token (or ETH, if applicable) in the handle.fi Liquidity Pool (hLP)
 *     - swaps a token (or ETH) in the hLP for a pegged token in the hPSM
 *
 * @dev safeApprove is intentionally not used, as since this contract should not store
 * funds between transactions, the approval race vulnerability does not apply.
 *
 *                ,.-"""-.,                       *
 *               /   ===   \                      *
 *              /  =======  \                     *
 *           __|  (o)   (0)  |__                  *
 *          / _|    .---.    |_ \                 *
 *         | /.----/ O O \----.\ |                *
 *          \/     |     |     \/                 *
 *          |                   |                 *
 *          |                   |                 *
 *          |                   |                 *
 *          _\   -.,_____,.-   /_                 *
 *      ,.-"  "-.,_________,.-"  "-.,             *
 *     /          |       |  ╭-╮     \            *
 *    |           l.     .l  ┃ ┃      |           *
 *    |            |     |   ┃ ╰━━╮   |           *
 *    l.           |     |   ┃ ╭╮ ┃  .l           *
 *     |           l.   .l   ┃ ┃┃ ┃  | \,         *
 *     l.           |   |    ╰-╯╰-╯ .l   \,       *
 *      |           |   |           |      \,     *
 *      l.          |   |          .l        |    *
 *       |          |   |          |         |    *
 *       |          |---|          |         |    *
 *       |          |   |          |         |    *
 *       /"-.,__,.-"\   /"-.,__,.-"\"-.,_,.-"\    *
 *      |            \ /            |         |   *
 *      |             |             |         |   *
 *       \__|__|__|__/ \__|__|__|__/ \_|__|__/    *
 */
contract RouterHpsmHlpV2 is BaseRouter, HpsmUtils, HlpRouterUtils {
    using SafeERC20 for IERC20;

    constructor(address _hpsm, address _hlpRouter)
        HpsmUtils(_hpsm)
        HlpRouterUtils(_hlpRouter)
    {}

    /**
     * @notice Swaps a pegged token for a fx token.
     * @return the amount of fxToken available after swapping
     */
    function _swapPeggedTokenToFxToken(
        address peggedToken,
        address fxToken,
        uint256 amountIn
    ) internal returns (uint256) {
        // swap pegged token for fxToken
        _hpsmDeposit(peggedToken, fxToken, amountIn);
        // it is safe to use the balance here, as this contract should
        // not hold funds between calls
        return _balanceOfSelf(fxToken);
    }

    /**
     * @notice Swaps a fx token for a pegged token
     * @return the amount of pegged token available after swapping
     */
    function _swapFxTokenToPeggedToken(
        address fxToken,
        address peggedToken,
        uint256 amountIn
    ) internal returns (uint256) {
        // swap pegged token for fxToken
        _hpsmWithdraw(fxToken, peggedToken, amountIn);
        // it is safe to use the balance here, as this contract should
        // not hold funds between calls
        return _balanceOfSelf(peggedToken);
    }

    /**
     * @notice Swaps a pegged token for a hlpToken.
     * @dev this first swaps a pegged token for the fxToken it is pegged against,
     * then swaps the fxToken for the desired hlpToken using the hLP.
     */
    function swapPeggedTokenToHlpToken(
        address peggedToken,
        address fxToken,
        address tokenOut,
        uint256 amountIn,
        uint256 minOut,
        address receiver,
        bytes calldata signedQuoteData
    ) external {
        require(peggedToken != tokenOut, "Cannot convert to same token");
        require(fxToken != tokenOut, "Must use hPSM directly");

        _transferIn(peggedToken, amountIn);

        // swap pegged token to fx token
        uint256 fxTokenAmount = _swapPeggedTokenToFxToken(
            peggedToken,
            fxToken,
            amountIn
        );

        // approve router to access funds
        IERC20(fxToken).approve(hlpRouter, fxTokenAmount);

        address[] memory path = new address[](2);
        path[0] = fxToken;
        path[1] = tokenOut;

        // swap fx token to hlp token
        IRouter(hlpRouter).swap(
            path,
            fxTokenAmount,
            minOut,
            receiver,
            signedQuoteData
        );
    }

    /**
     * @notice Swaps a pegged token for a hlpToken.
     * @dev this first swaps a hlp token for the fx token in the hLP, then swaps
     * the fx token for the pegged token in the hPSM
     * @param hlpToken the token input
     * @param fxToken the intermediate step in the hPSM
     * @param tokenOut the pegged token in the hPSM, for the receiver to receive
     */
    function swapHlpTokenToPeggedToken(
        address hlpToken,
        address fxToken,
        address tokenOut,
        uint256 amountIn,
        uint256 minOut,
        address receiver,
        bytes calldata signedQuoteData
    ) external {
        require(hlpToken != tokenOut, "Cannot convert to same token");
        require(fxToken != tokenOut, "Must use HlpRouter directly");

        _transferIn(hlpToken, amountIn);

        // approve router to access funds
        IERC20(hlpToken).approve(hlpRouter, amountIn);

        address[] memory path = new address[](2);
        path[0] = hlpToken;
        path[1] = fxToken;

        // swap hlp token to fx token
        IRouter(hlpRouter).swap(
            path,
            amountIn,
            0, // no min out needed, will be handled when transferring out
            _self,
            signedQuoteData
        );

        uint256 tokenOutAmount = _swapFxTokenToPeggedToken(
            fxToken,
            tokenOut,
            _balanceOfSelf(fxToken)
        );

        require(tokenOutAmount >= minOut, "Insufficient amount out");
        IERC20(tokenOut).safeTransfer(receiver, tokenOutAmount);
    }

    /**
     * @notice Swaps a pegged token for ETH.
     * @dev this first swaps a pegged token for the fxToken it is pegged against,
     * then swaps the fxToken for ETH.
     */
    function swapPeggedTokenToEth(
        address peggedToken,
        address fxToken,
        uint256 amountIn,
        uint256 minOut,
        address payable receiver,
        bytes calldata signedQuoteData
    ) external {
        _transferIn(peggedToken, amountIn);

        // swap pegged token to fx token
        uint256 fxTokenAmount = _swapPeggedTokenToFxToken(
            peggedToken,
            fxToken,
            amountIn
        );

        // approve router to access funds
        IERC20(fxToken).approve(hlpRouter, fxTokenAmount);

        address[] memory path = new address[](2);
        path[0] = fxToken;
        path[1] = IRouter(hlpRouter).weth(); // router requires last element to be weth for eth swap

        // swap fx token to eth
        IRouter(hlpRouter).swapTokensToETH(
            path,
            fxTokenAmount,
            minOut,
            receiver,
            signedQuoteData
        );
    }

    /**
     * @notice Swaps a ETH for a pegged token.
     * @dev this first swaps eth for the fx token in the hLP, then swaps the fx token
     * for the pegged token in the hPSM
     * @param fxToken the intermediate step in the hPSM
     * @param tokenOut the pegged token in the hPSM, for the receiver to receive
     */
    function swapEthToPeggedToken(
        address fxToken,
        address tokenOut,
        uint256 minOut,
        address receiver,
        bytes calldata signedQuoteData
    ) external payable {
        require(fxToken != tokenOut, "Must use HlpRouter directly");
        require(msg.value > 0, "msg.value must not be zero");

        address[] memory path = new address[](2);
        path[0] = IRouter(hlpRouter).weth();
        path[1] = fxToken;

        // swap hlp token to fx token
        IRouter(hlpRouter).swapETHToTokens{value: msg.value}(
            path,
            0, // no min out needed, will be handled when transferring out
            _self,
            signedQuoteData
        );

        uint256 tokenOutAmount = _swapFxTokenToPeggedToken(
            fxToken,
            tokenOut,
            _balanceOfSelf(fxToken)
        );

        require(tokenOutAmount >= minOut, "Insufficient amount out");
        IERC20(tokenOut).safeTransfer(receiver, tokenOutAmount);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IHandle.sol";
import "./interfaces/fxToken.sol";

/*                                                *\
 *                ,.-"""-.,                       *
 *               /   ===   \                      *
 *              /  =======  \                     *
 *           __|  (o)   (0)  |__                  *
 *          / _|    .---.    |_ \                 *
 *         | /.----/ O O \----.\ |                *
 *          \/     |     |     \/                 *
 *          |                   |                 *
 *          |                   |                 *
 *          |                   |                 *
 *          _\   -.,_____,.-   /_                 *
 *      ,.-"  "-.,_________,.-"  "-.,             *
 *     /          |       |  ╭-╮     \            *
 *    |           l.     .l  ┃ ┃      |           *
 *    |            |     |   ┃ ╰━━╮   |           *
 *    l.           |     |   ┃ ╭╮ ┃  .l           *
 *     |           l.   .l   ┃ ┃┃ ┃  | \,         *
 *     l.           |   |    ╰-╯╰-╯ .l   \,       *
 *      |           |   |           |      \,     *
 *      l.          |   |          .l        |    *
 *       |          |   |          |         |    *
 *       |          |---|          |         |    *
 *       |          |   |          |         |    *
 *       /"-.,__,.-"\   /"-.,__,.-"\"-.,_,.-"\    *
 *      |            \ /            |         |   *
 *      |             |             |         |   *
 *       \__|__|__|__/ \__|__|__|__/ \_|__|__/    *
\*                                                 */

contract hPSM is Ownable {
    using SafeERC20 for ERC20;
    IHandle public handle;

    /** @dev This contract's address. */
    address private immutable self;
    /** @dev Transaction fee with 18 decimals. */
    uint256 public transactionFee;
    /** @dev Mapping from pegged token address to total deposit supported. */
    mapping(address => uint256) public collateralCap;
    /** @dev Mapping from pegged token address to accrued fee amount. */
    mapping(address => uint256) public accruedFees;
    /** @dev Mapping from fxToken to peg token address to whether the peg is set. */
    mapping(address => mapping(address => bool)) public isFxTokenPegged;
    /** @dev Mapping from fxToken to peg token to deposit amount. */
    mapping(address => mapping(address => uint256)) public fxTokenDeposits;
    /** @dev Whether deposits are paused. */
    bool public areDepositsPaused;

    event SetPauseDeposits(bool isPaused);

    event SetTransactionFee(uint256 fee);
    
    event SetMaximumTokenDeposit(address indexed token, uint256 amount);
    
    event SetFxTokenPeg(
        address indexed fxToken,
        address indexed peggedToken,
        bool isPegged
    );

    event Deposit(
        address indexed fxToken,
        address indexed peggedToken,
        address indexed account,
        uint256 amountIn,
        uint256 amountOut
    );
 
    event Withdraw(
        address indexed fxToken,
        address indexed peggedToken,
        address indexed account,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(IHandle _handle) {
        require(address(_handle) != address(0), "PSM: handle cannot be null");
        self = address(this);
        handle = _handle;
    }
    
    function collectAccruedFees(address collateralToken) external onlyOwner {
        uint256 amount = accruedFees[collateralToken];
        require(amount > 0, "PSM: no fee accrual");
        ERC20(collateralToken).transfer(msg.sender, amount);
        accruedFees[collateralToken] -= amount;
    }

    /** @dev Sets the transaction fee. */
    function setTransactionFee(uint256 fee) external onlyOwner {
        require(fee < 1 ether, "PSM: fee must be < 100%");
        transactionFee = fee;
        emit SetTransactionFee(transactionFee);
    }

    /** @dev Sets whether deposits are paused. */
    function setPausedDeposits(bool isPaused) external onlyOwner {
        areDepositsPaused = isPaused;
        emit SetPauseDeposits(isPaused);
    }

    /** @dev Configures a fxToken peg to a collateral token. */
    function setFxTokenPeg(
        address fxTokenAddress,
        address peggedTokenAddress,
        bool isPegged
    ) external onlyOwner {
        fxToken _fxToken = fxToken(fxTokenAddress);
        assert(isFxTokenPegged[fxTokenAddress][peggedTokenAddress] != isPegged);
        require(
            handle.isFxTokenValid(fxTokenAddress),
            "PSM: not a valid fxToken"
        );
        bytes32 operatorRole = _fxToken.OPERATOR_ROLE();
        require(
            !isPegged || _fxToken.hasRole(operatorRole, self),
            "PSM: not an fxToken operator"
        );
        require(
            !handle.isFxTokenValid(peggedTokenAddress),
            "PSM: not a valid peg token"
        );
        isFxTokenPegged[fxTokenAddress][peggedTokenAddress] = isPegged;
        if (!isPegged)
            _fxToken.renounceRole(operatorRole, self);
        emit SetFxTokenPeg(fxTokenAddress, peggedTokenAddress, isPegged);
    }

    /** @dev Sets the maximum total deposit for a pegged token. */
    function setCollateralCap(
        address peggedToken,
        uint256 capWithPeggedTokenDecimals
    ) external onlyOwner {
        collateralCap[peggedToken] = capWithPeggedTokenDecimals;
        emit SetMaximumTokenDeposit(peggedToken, capWithPeggedTokenDecimals);
    }

    /** @dev Receives a pegged token in exchange for minting fxToken for an account. */
    function deposit(
        address fxTokenAddress,
        address peggedTokenAddress,
        uint256 amount
    ) external {
        require(!areDepositsPaused, "PSM: deposits are paused");
        require(
            isFxTokenPegged[fxTokenAddress][peggedTokenAddress],
            "PSM: fxToken not pegged to peggedToken"
        );
        require(
            amount > 0,
            "PSM: amount must be > 0"
        );
        ERC20 peggedToken = ERC20(peggedTokenAddress);
        require(
            collateralCap[peggedTokenAddress] == 0 ||
                amount + peggedToken.balanceOf(self)
                    <= collateralCap[peggedTokenAddress],
            "PSM: collateral cap exceeded"
        );
        peggedToken.safeTransferFrom(
            msg.sender,
            self,
            amount
        );
        uint256 amountOutGross = calculateAmountForDecimalChange(
            peggedTokenAddress,
            fxTokenAddress,
            amount
        );
        uint256 amountOutNet = calculateAmountAfterFees(
          amountOutGross  
        );
        require(amountOutNet > 0, "PSM: prevented nil transfer");
        updateFeeForCollateral(
            peggedTokenAddress,
            amount,
            calculateAmountAfterFees(amount)
        );
        // Increase fxToken (input) amount from deposits.
        fxTokenDeposits[fxTokenAddress][peggedTokenAddress] += amount;
        fxToken(fxTokenAddress).mint(msg.sender, amountOutNet);
        emit Deposit(
            fxTokenAddress,
            peggedTokenAddress,
            msg.sender,
            amount,
            amountOutNet
        );
    }

    /** @dev Burns an account's fxToken balance in exchange for a pegged token. */
    function withdraw(
        address fxTokenAddress,
        address peggedTokenAddress,
        uint256 amount
    ) external {
        require(
            isFxTokenPegged[fxTokenAddress][peggedTokenAddress],
            "PSM: fxToken not pegged to peggedToken"
        );
        ERC20 peggedToken = ERC20(peggedTokenAddress);
        uint256 amountOutGross = calculateAmountForDecimalChange(
            fxTokenAddress,
            peggedTokenAddress,
            amount
        );
        // While deposits are paused:
        //  - users can still withdraw all the pegged token liquidity currently in the contract
        //  - once the pegged token liquidity runs out, users can no longer call withdraw
        require(
            !areDepositsPaused ||
                fxTokenDeposits[fxTokenAddress][peggedTokenAddress] >= amountOutGross,
            "PSM: paused + no liquidity"
        );
        require(
            peggedToken.balanceOf(self) >= amountOutGross,
            "PSM: contract lacks liquidity"
        );
        fxToken fxToken = fxToken(fxTokenAddress);
        require(
            fxToken.balanceOf(msg.sender) >= amount,
            "PSM: insufficient fx balance"
        );
        fxToken.burn(msg.sender, amount);
        uint256 amountOutNet = calculateAmountAfterFees(
            amountOutGross
        );
        require(amountOutNet > 0, "PSM: prevented nil transfer");
        updateFeeForCollateral(
            peggedTokenAddress,
            amountOutGross,
            amountOutNet
        );
        // Reduce fxToken (amount out, gross) amount from deposits.
        fxTokenDeposits[fxTokenAddress][peggedTokenAddress] -= amountOutGross;
        peggedToken.safeTransfer(msg.sender, amountOutNet);
        emit Withdraw(
            fxTokenAddress,
            peggedTokenAddress,
            msg.sender,
            amount,
            amountOutNet
        );
    }

    /** @dev Converts an input amount to after fees. */
    function calculateAmountAfterFees(uint256 amount) private returns (uint256) {
        return amount * (1 ether - transactionFee) / 1 ether;
    }

    function updateFeeForCollateral(
        address collateralToken,
        uint256 amountGross,
        uint256 amountNet
    ) private{
        if (amountNet == amountGross) return;
        assert(amountNet < amountGross);
        accruedFees[collateralToken] += amountGross - amountNet;
    }

    /** @dev Converts an amount to match a different decimal count. */
    function calculateAmountForDecimalChange(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) private returns (uint256) {
        uint256 decimalsIn = uint256(ERC20(tokenIn).decimals());
        uint256 decimalsOut = uint256(ERC20(tokenOut).decimals());
        if (decimalsIn == decimalsOut) return amountIn;
        uint256 decimalsDiff;
        if (decimalsIn > decimalsOut) {
            decimalsDiff = decimalsIn - decimalsOut;
            return amountIn / (10 ** decimalsDiff);
        }
        decimalsDiff = decimalsOut - decimalsIn;
        return amountIn * (10 ** decimalsDiff);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

pragma abicoder v2;

interface IHandle {
    struct Vault {
        // Collateral token address => balance
        mapping(address => uint256) collateralBalance;
        uint256 debt;
        // Collateral token address => R0
        mapping(address => uint256) R0;
    }

    struct CollateralData {
        uint256 mintCR;
        uint256 liquidationFee;
        uint256 interestRate;
    }

    event UpdateDebt(address indexed account, address indexed fxToken);

    event UpdateCollateral(
        address indexed account,
        address indexed fxToken,
        address indexed collateralToken
    );

    event ConfigureCollateralToken(address indexed collateralToken);

    event ConfigureFxToken(address indexed fxToken, bool removed);

    function setCollateralUpperBoundPCT(uint256 ratio) external;

    function setPaused(bool value) external;

    function setFxToken(address token) external;

    function removeFxToken(address token) external;

    function setCollateralToken(
        address token,
        uint256 mintCR,
        uint256 liquidationFee,
        uint256 interestRatePerMille
    ) external;

    function removeCollateralToken(address token) external;

    function getAllCollateralTypes()
        external
        view
        returns (address[] memory collateral);

    function getCollateralDetails(address collateral)
        external
        view
        returns (CollateralData memory);

    function WETH() external view returns (address);

    function treasury() external view returns (address payable);

    function comptroller() external view returns (address);

    function vaultLibrary() external view returns (address);

    function fxKeeperPool() external view returns (address);

    function pct() external view returns (address);

    function liquidator() external view returns (address);

    function interest() external view returns (address);

    function referral() external view returns (address);

    function forex() external view returns (address);

    function rewards() external view returns (address);

    function pctCollateralUpperBound() external view returns (uint256);

    function isFxTokenValid(address fxToken) external view returns (bool);

    function isCollateralValid(address collateral) external view returns (bool);

    function setComponents(address[] memory components) external;

    function updateDebtPosition(
        address account,
        uint256 amount,
        address fxToken,
        bool increase
    ) external;

    function updateCollateralBalance(
        address account,
        uint256 amount,
        address fxToken,
        address collateralToken,
        bool increase
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFees(
        uint256 withdrawFeePerMille,
        uint256 depositFeePerMille,
        uint256 mintFeePerMille,
        uint256 burnFeePerMille
    ) external;

    function getCollateralBalance(
        address account,
        address collateralType,
        address fxToken
    ) external view returns (uint256 balance);

    function getBalance(address account, address fxToken)
        external
        view
        returns (address[] memory collateral, uint256[] memory balances);

    function getDebt(address owner, address fxToken)
        external
        view
        returns (uint256 _debt);

    function getPrincipalDebt(address owner, address fxToken)
        external
        view
        returns (uint256 _debt);

    function getCollateralR0(
        address account,
        address fxToken,
        address collateral
    ) external view returns (uint256 R0);

    function getTokenPrice(address token) external view returns (uint256 quote);

    function setOracle(address fxToken, address oracle) external;

    function FeeRecipient() external view returns (address);

    function mintFeePerMille() external view returns (uint256);

    function burnFeePerMille() external view returns (uint256);

    function withdrawFeePerMille() external view returns (uint256);

    function depositFeePerMille() external view returns (uint256);

    function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IfxToken.sol";

/*                                                *\
 *                ,.-"""-.,                       *
 *               /   ===   \                      *
 *              /  =======  \                     *
 *           __|  (o)   (0)  |__                  *
 *          / _|    .---.    |_ \                 *
 *         | /.----/ O O \----.\ |                *
 *          \/     |     |     \/                 *
 *          |                   |                 *
 *          |                   |                 *
 *          |                   |                 *
 *          _\   -.,_____,.-   /_                 *
 *      ,.-"  "-.,_________,.-"  "-.,             *
 *     /          |       |  ╭-╮     \            *
 *    |           l.     .l  ┃ ┃      |           *
 *    |            |     |   ┃ ╰━━╮   |           *
 *    l.           |     |   ┃ ╭╮ ┃  .l           *
 *     |           l.   .l   ┃ ┃┃ ┃  | \,         *
 *     l.           |   |    ╰-╯╰-╯ .l   \,       *
 *      |           |   |           |      \,     *
 *      l.          |   |          .l        |    *
 *       |          |   |          |         |    *
 *       |          |---|          |         |    *
 *       |          |   |          |         |    *
 *       /"-.,__,.-"\   /"-.,__,.-"\"-.,_,.-"\    *
 *      |            \ /            |         |   *
 *      |             |             |         |   *
 *       \__|__|__|__/ \__|__|__|__/ \_|__|__/    *
\*                                                 */

contract fxToken is IfxToken, AccessControl, ERC20 {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    modifier onlyOperator() {
        require(
            hasRole(OPERATOR_ROLE, msg.sender) ||
                hasRole(ADMIN_ROLE, msg.sender),
            "fxToken: caller not an operator"
        );
        _;
    }

    function mint(address account, uint256 amount)
        external
        override
        onlyOperator
    {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount)
        external
        override
        onlyOperator
    {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IfxToken is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@handle-fi/handle-psm/contracts/hPSM.sol";

abstract contract HlpRouterUtils is Ownable {
    address public hlpRouter;

    event ChangeHlpRouter(address newHlpRouter);

    constructor(address _hlpRouter) {
        hlpRouter = _hlpRouter;

        emit ChangeHlpRouter(_hlpRouter);
    }

    /** @notice Sets the router address */
    function setHlpRouter(address _hlpRouter) external onlyOwner {
        require(hlpRouter != _hlpRouter, "Address already set");
        hlpRouter = _hlpRouter;
        emit ChangeHlpRouter(hlpRouter);
    }
}