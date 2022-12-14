// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "ICryptoPool.sol";
import "ICurvePool.sol";
import "ICLPCurve.sol";
import "ICurveDepositZap.sol";
import "ICurveDepositMetapoolZap.sol";
import "CLPBase.sol";

contract CLPCurve is CLPBase, ICLPCurve {
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function _getContractName() internal pure override returns (string memory) {
        return "CLPCurve";
    }

    function deposit(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        CurveLPDepositParams calldata params
    ) external payable {
        _requireMsg(amounts.length == tokens.length, "amounts+tokens length not equal");
        uint256 ethAmount = 0;
        // for loop `i` cannot overflow, so we use unchecked block to save gas
        unchecked {
            for (uint256 i; i < tokens.length; ++i) {
                if (amounts[i] > 0) {
                    if (address(tokens[i]) == ETH_ADDRESS) {
                        ethAmount = amounts[i];
                    } else {
                        _approveToken(tokens[i], params.curveDepositAddress, amounts[i]);
                    }
                }
            }
        }
        if (amounts.length == 2) {
            uint256[2] memory _tokenAmounts = [amounts[0], amounts[1]];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity{value: ethAmount}(
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity(
                    _tokenAmounts,
                    params.minReceivedLiquidity,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else if (amounts.length == 3) {
            uint256[3] memory _tokenAmounts = [amounts[0], amounts[1], amounts[2]];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity{value: ethAmount}(
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveDepositAddress).add_liquidity(
                    params.metapool,
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity(
                    _tokenAmounts,
                    params.minReceivedLiquidity,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else if (amounts.length == 4) {
            uint256[4] memory _tokenAmounts = [amounts[0], amounts[1], amounts[2], amounts[3]];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity{value: ethAmount}(
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveDepositAddress).add_liquidity(
                    params.metapool,
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity(
                    _tokenAmounts,
                    params.minReceivedLiquidity,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else if (amounts.length == 5) {
            uint256[5] memory _tokenAmounts = [
                amounts[0],
                amounts[1],
                amounts[2],
                amounts[3],
                amounts[4]
            ];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity{value: ethAmount}(
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveDepositAddress).add_liquidity(
                    params.metapool,
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity(
                    _tokenAmounts,
                    params.minReceivedLiquidity,
                    true
                );
            }
        } else if (amounts.length == 6) {
            uint256[6] memory _tokenAmounts = [
                amounts[0],
                amounts[1],
                amounts[2],
                amounts[3],
                amounts[4],
                amounts[5]
            ];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity{value: ethAmount}(
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveDepositAddress).add_liquidity(
                    params.metapool,
                    _tokenAmounts,
                    params.minReceivedLiquidity
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveDepositAddress).add_liquidity(
                    _tokenAmounts,
                    params.minReceivedLiquidity,
                    true
                );
            }
        } else {
            _revertMsg("unsupported length");
        }
    }

    function withdraw(
        IERC20 LPToken,
        uint256 liquidity,
        CurveLPWithdrawParams calldata params
    ) external payable {
        if (params.lpType == CurveLPType.HELPER || params.lpType == CurveLPType.METAPOOL_HELPER) {
            _approveToken(LPToken, params.curveWithdrawAddress, liquidity);
        }
        if (params.minimumReceived.length == 2) {
            uint256[2] memory _tokenAmounts = [
                params.minimumReceived[0],
                params.minimumReceived[1]
            ];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else if (params.minimumReceived.length == 3) {
            uint256[3] memory _tokenAmounts = [
                params.minimumReceived[0],
                params.minimumReceived[1],
                params.minimumReceived[2]
            ];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveWithdrawAddress).remove_liquidity(
                    params.metapool,
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else if (params.minimumReceived.length == 4) {
            uint256[4] memory _tokenAmounts = [
                params.minimumReceived[0],
                params.minimumReceived[1],
                params.minimumReceived[2],
                params.minimumReceived[3]
            ];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveWithdrawAddress).remove_liquidity(
                    params.metapool,
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else if (params.minimumReceived.length == 5) {
            uint256[5] memory _tokenAmounts = [
                params.minimumReceived[0],
                params.minimumReceived[1],
                params.minimumReceived[2],
                params.minimumReceived[3],
                params.minimumReceived[4]
            ];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveWithdrawAddress).remove_liquidity(
                    params.metapool,
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else if (params.minimumReceived.length == 6) {
            uint256[6] memory _tokenAmounts = [
                params.minimumReceived[0],
                params.minimumReceived[1],
                params.minimumReceived[2],
                params.minimumReceived[3],
                params.minimumReceived[4],
                params.minimumReceived[5]
            ];
            if (params.lpType == CurveLPType.BASE || params.lpType == CurveLPType.HELPER) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.METAPOOL_HELPER) {
                ICurveDepositMetapoolZap(params.curveWithdrawAddress).remove_liquidity(
                    params.metapool,
                    liquidity,
                    _tokenAmounts
                );
            } else if (params.lpType == CurveLPType.UNDERLYING) {
                ICurveDepositZap(params.curveWithdrawAddress).remove_liquidity(
                    liquidity,
                    _tokenAmounts,
                    true
                );
            } else {
                _revertMsg("invalid lpType");
            }
        } else {
            _revertMsg("unsupported length");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICryptoPool {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICurvePool {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[5] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[6] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[7] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[8] calldata amounts, uint256 min_mint_amount) external;

    function calc_token_amount(uint256[2] calldata amounts, bool deposit)
        external
        view
        returns (uint256 liquidity);

    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256 liquidity);

    function calc_token_amount(uint256[4] calldata amounts, bool deposit)
        external
        view
        returns (uint256 liquidity);

    function calc_token_amount(uint256[5] calldata amounts, bool deposit)
        external
        view
        returns (uint256 liquidity);

    function calc_token_amount(uint256[6] calldata amounts, bool deposit)
        external
        view
        returns (uint256 liquidity);

    function calc_token_amount(uint256[7] calldata amounts, bool deposit)
        external
        view
        returns (uint256 liquidity);

    function calc_token_amount(uint256[8] calldata amounts, bool deposit)
        external
        view
        returns (uint256 liquidity);

    function remove_liquidity(uint256 _amount, uint256[2] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[5] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[6] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[7] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[8] calldata min_amounts) external;
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

interface ICLPCurve {
    /**
        @notice Used to specify the necessary parameters for a Curve interaction
        @dev Users may either deposit/withdraw 'base' assets or 'underlying' assets into/from a Curve pool.
            Some Curve pools allow directly depositing 'underlying' assets, whilst other Curve pools necessitate
            the usage of a 'helper' contract. 
            In order to accomodate different behaviour between different Curve pools, the caller of this contract
            must explicitly state the desired behaviour:

            If depositing/withdrawing 'base' assets, this parameter MUST be BASE and the `curveDepositAddress`/`curveWithdrawAddress` parameter MUST be the address of the Curve contract.

            If depositing/withdrawing 'underlying assets', check whether the Curve contract supports underlying assets:
                If underlying assets are supported, this parameter MUST be UNDERLYING and the `curveDepositAddress`/`curveWithdrawAddress` parameter MUST be the address of the Curve contract.
                If underlying assets are not supported, this parameter MUST be CONTRACT and the `curveDepositAddress`/`curveWithdrawAddress` parameter MUST be the address of the helper 'Deposit.vy' contract.

        @param BASE The user is interacting directly with the Curve contract and depositing base assets.
        @param UNDERLYING The user is interacting directly with the Curve contract and depositing underlying assets.
        @param HELPER The user is interacting with a Curve `Deposit.vy` contract, and depositing underlying assets.
        @param METAPOOL_HELPER The user is interacting with a Curve 'metapool_helper' contract, and depositing underlying assets.
    */
    enum CurveLPType {
        BASE,
        UNDERLYING,
        HELPER,
        METAPOOL_HELPER
    }

    struct CurveLPDepositParams {
        uint256 minReceivedLiquidity;
        CurveLPType lpType;
        address curveDepositAddress;
        address metapool;
    }
    struct CurveLPWithdrawParams {
        uint256[] minimumReceived;
        CurveLPType lpType;
        address curveWithdrawAddress;
        address metapool;
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

interface ICurveDepositZap {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[5] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[6] calldata amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external payable;

    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external payable;

    function add_liquidity(
        uint256[4] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external payable;

    function add_liquidity(
        uint256[5] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external payable;

    function add_liquidity(
        uint256[6] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external payable;

    function remove_liquidity(uint256 amount, uint256[2] calldata min_amounts) external payable;

    function remove_liquidity(uint256 amount, uint256[3] calldata min_amounts) external payable;

    function remove_liquidity(uint256 amount, uint256[4] calldata min_amounts) external payable;

    function remove_liquidity(uint256 amount, uint256[5] calldata min_amounts) external payable;

    function remove_liquidity(uint256 amount, uint256[6] calldata min_amounts) external payable;

    function remove_liquidity(
        uint256 amount,
        uint256[2] calldata min_amounts,
        bool use_underlying
    ) external payable;

    function remove_liquidity(
        uint256 amount,
        uint256[3] calldata min_amounts,
        bool use_underlying
    ) external payable;

    function remove_liquidity(
        uint256 amount,
        uint256[4] calldata min_amounts,
        bool use_underlying
    ) external payable;

    function remove_liquidity(
        uint256 amount,
        uint256[5] calldata min_amounts,
        bool use_underlying
    ) external payable;

    function remove_liquidity(
        uint256 amount,
        uint256[6] calldata min_amounts,
        bool use_underlying
    ) external payable;
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

interface ICurveDepositMetapoolZap {
    function add_liquidity(
        address pool,
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        address pool,
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        address pool,
        uint256[5] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        address pool,
        uint256[6] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity(
        address pool,
        uint256 amount,
        uint256[3] calldata min_amounts
    ) external;

    function remove_liquidity(
        address pool,
        uint256 amount,
        uint256[4] calldata min_amounts
    ) external;

    function remove_liquidity(
        address pool,
        uint256 amount,
        uint256[5] calldata min_amounts
    ) external;

    function remove_liquidity(
        address pool,
        uint256 amount,
        uint256[6] calldata min_amounts
    ) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "SafeERC20.sol";

abstract contract CLPBase {
    using SafeERC20 for IERC20;

    function _getContractName() internal pure virtual returns (string memory);

    function _revertMsg(string memory message) internal {
        revert(string(abi.encodePacked(_getContractName(), ":", message)));
    }

    function _requireMsg(bool condition, string memory message) internal {
        if (!condition) {
            revert(string(abi.encodePacked(_getContractName(), ":", message)));
        }
    }

    function _approveToken(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.safeApprove(spender, 0);
        }
        token.safeApprove(spender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
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

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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