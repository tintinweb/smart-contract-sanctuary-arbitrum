// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import "./IBalancerVault.sol";

interface IBalancerHelper {
	function queryExit(
		bytes32 poolId,
		address sender,
		address payable recipient,
		IBalancerVault.ExitPoolRequest memory request
	) external returns(uint256, uint256[] memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IBalancerVault {
	enum SwapKind { GIVEN_IN, GIVEN_OUT }

	struct SingleSwap {
		bytes32 poolId;
		SwapKind kind;
		address assetIn;
		address assetOut;
		uint256 amount;
		bytes userData;
	}

	struct FundManagement {
		address sender;
		bool fromInternalBalance;
		address payable recipient;
		bool toInternalBalance;
	}

	struct JoinPoolRequest {
		address[] assets;
		uint256[] maxAmountsIn;
		bytes userData;
		bool fromInternalBalance;
	}

	struct ExitPoolRequest {
		address[] assets;
		uint256[] minAmountsOut;
		bytes userData;
		bool toInternalBalance;
	}
	
	struct BatchSwapStep {
		bytes32 poolId;
		uint256 assetInIndex;
		uint256 assetOutIndex;
		uint256 amount;
		bytes userData;
	}

	function swap(
		SingleSwap memory singleSwap,
		FundManagement memory funds,
		uint256 limit,
		uint256 deadline
	) external payable returns (uint256);

	function queryBatchSwap(
		SwapKind kind, 
		BatchSwapStep[] memory swaps, 
		address[] memory assets, 
		FundManagement memory funds
	) external returns (int256[] memory);

	function joinPool(
		bytes32 poolId,
		address sender,
		address recipient,
		JoinPoolRequest memory request
	) external payable;

	function exitPool(
		bytes32 poolId,
		address sender,
		address payable recipient,
		ExitPoolRequest memory request
	) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interface/IBalancerVault.sol";
import "../interface/IBalancerHelper.sol";

library Balancer {
  struct BalancerSwapOutParam {
    uint256 amount;
    address assetIn;
    address assetOut;
    address recipient;
    bytes32 poolId;
    uint256 maxAmountIn;
  }

  enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

  function balancerJoinPool(IBalancerVault balancerVault, address[] memory tokens, uint256[] memory maxAmountsIn, bytes32 poolId) external {
    bytes memory userData = abi.encode(1, maxAmountsIn, 0); // JoinKind: 1
    balancerVault.joinPool(
      poolId,
      address(this),
      address(this),
      IBalancerVault.JoinPoolRequest(tokens, maxAmountsIn, userData, false)
    );
  }

  // balancer exit pool with bptAmountIn
  function balancerExitPool(IBalancerVault balancerVault, address[] memory tokens, uint256[] memory minAmountsOut, bytes32 poolId, uint256 bptAmountIn, uint256 tokenIndex) external {
    balancerVault.exitPool(
      poolId,
      address(this),
      payable(address(this)),
      IBalancerVault.ExitPoolRequest(tokens, minAmountsOut, abi.encode(ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptAmountIn, tokenIndex), false)
    );
  }

  // balancer exit pool with custom tokenOut amount
  function balancerCustomExitPool(IBalancerVault balancerVault, address[] memory tokens, uint256[] memory minAmountsOut, bytes32 poolId, uint256[] memory amountsOut, uint256 maxBPTAmountIn) external {
    balancerVault.exitPool(
      poolId,
      address(this),
      payable(address(this)),
      IBalancerVault.ExitPoolRequest(tokens, minAmountsOut, abi.encode(ExitKind.BPT_IN_FOR_EXACT_TOKENS_OUT, amountsOut, maxBPTAmountIn), false)
    );
  }

  function balancerQueryExit(IBalancerHelper balancerHelper, address[] memory tokens, uint256[] memory minAmountsOut, bytes32 poolId, uint256 bptAmountIn, uint256 tokenIndex) external returns (uint256) {
    uint256 bptIn;
    uint256[] memory amountsOut;
    (bptIn, amountsOut) = balancerHelper.queryExit(
      poolId,
      address(this),
      payable(address(this)),
      IBalancerVault.ExitPoolRequest(tokens, minAmountsOut, abi.encode(ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptAmountIn, tokenIndex), false)
    );
    return amountsOut[tokenIndex];
  }

  function balancerSwapIn(IBalancerVault balancerVault, uint256 amount, address assetIn, address assetOut, address recipient, bytes32 poolId) external returns (uint256) {
    IERC20Upgradeable(assetIn).approve(address(balancerVault), amount);
    bytes memory userData;
    uint256 value = balancerVault.swap(
      IBalancerVault.SingleSwap(poolId, IBalancerVault.SwapKind.GIVEN_IN, assetIn, assetOut, amount, userData),
      IBalancerVault.FundManagement(address(this), true, payable(recipient), false),
      0,
      2**256 - 1
    );
    return value;
  }

  function balancerSwapOut(IBalancerVault balancerVault, BalancerSwapOutParam memory param) internal returns (uint256) {
    IERC20Upgradeable(param.assetIn).approve(address(balancerVault), param.maxAmountIn);
    return balancerVault.swap(
      IBalancerVault.SingleSwap(param.poolId, IBalancerVault.SwapKind.GIVEN_OUT, param.assetIn, param.assetOut, param.amount, ""),
      IBalancerVault.FundManagement(address(this), true, payable(param.recipient), false),
      param.maxAmountIn,
      2**256 - 1
    );
  }

  function getAddress() external view returns (address) {
    return address(this);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./libraries/Balancer.sol";

contract TestVault {
  function getAddress() external view returns(address) {
    return Balancer.getAddress();
  }
}