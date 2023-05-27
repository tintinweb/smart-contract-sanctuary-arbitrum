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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "../interfaces/IChainsigtAdapter.sol";
import "../interfaces/ILendingPool.sol";
import "../interfaces/ICreditToken.sol";

contract ChainsightAdapter is IChainsigtAdapter {
    address public lendingPool;

    constructor(address _lendingPool) {
        lendingPool = _lendingPool;
    }

    function symbolToAddress(
        string calldata symbol
    ) external view override returns (address) {
        return _symbolToAddress(symbol);
    }

    function _symbolToAddress(
        string memory symbol
    ) internal view returns (address) {
        return ILendingPool(lendingPool).assetAddresses(symbol);
    }

    function unlockAssetOf(
        address user,
        address to,
        string memory symbol,
        uint256 amount,
        uint256 srcChainId
    ) external override {
        address asset = _symbolToAddress(symbol);
        require(asset != address(0), "invalid asset");
        address creditTokenAddress = ILendingPool(lendingPool)
            .creditTokenAddress(asset);
        ICreditToken(creditTokenAddress).burnLockedFor(
            user,
            to,
            amount,
            srcChainId
        );
    }

    function onLockCreated(
        address user,
        string memory symbol,
        uint256 amount,
        uint256 srcChainId
    ) external override {
        address asset = _symbolToAddress(symbol);
        require(asset != address(0), "invalid asset");
        address creditTokenAddress = ILendingPool(lendingPool)
            .creditTokenAddress(asset);
        require(creditTokenAddress != address(0), "invalid credit token");
        ICreditToken(creditTokenAddress).onLockCreated(
            user,
            amount,
            srcChainId
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IChainsigtAdapter {
    function onLockCreated(
        address user,
        string memory symbol,
        uint256 amount,
        uint256 srcChainId
    ) external;

    // unlock withdraw of asset.
    function unlockAssetOf(
        address user,
        address to,
        string memory symbol,
        uint256 amount,
        uint256 srcChainId
    ) external;

    function symbolToAddress(
        string calldata symbol
    ) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICreditToken is IERC20 {
    struct CrossChainAsset {
        uint256 amountLockedFor;
        uint256 amountLockedFrom;
    }

    function chainIds() external view returns (uint256[] memory);

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function mint(address account, uint256 amount) external;

    function transferUnderlyingTo(address account, uint256 amount) external;

    function burn(address account, address receiver, uint256 amount) external;

    function collateralAmountOf(
        address account
    ) external view returns (uint256);

    function lockedBalanceOf(address account) external view returns (uint256);

    function unlockedBalanceOf(address account) external view returns (uint256);

    function burnLockedFor(
        address account,
        address receiver,
        uint256 amount,
        uint256 srcChainId
    ) external;

    function crossChainAssetOf(
        address account,
        uint256 chainId
    ) external view returns (CrossChainAsset memory);

    event LockCreated(
        address indexed account,
        uint256 amount,
        uint256 dstChainId
    );

    event Received(address indexed account, uint256 amount, uint256 srcChainId);

    function lockFor(
        address account,
        uint256 amount,
        uint256 dstChainId
    ) external;

    function unlockFor(
        address account,
        uint256 amount,
        uint256 srcChainId
    ) external;

    function setLendingPool(address _lendingPool) external;

    function setChainsight(address _chainsight) external;

    function onLockCreated(
        address account,
        uint256 amount,
        uint256 srcChainId
    ) external;

    function transferOnLiquidation(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILendingPool {
    event LockCreated(
        address indexed account,
        address indexed asset,
        string symbol,
        uint256 amount,
        uint256 dstChainId
    );
    event LockReleased(
        address indexed account,
        address indexed asset,
        string symbol,
        uint256 amount,
        uint256 dstChainId,
        address indexed to
    );

    function deposit(address asset, uint256 amount) external;

    function withdraw(address asset, uint256 amount) external returns (uint256);

    function borrow(address asset, uint256 amount) external;

    function repay(address asset, uint256 amount) external;

    function healthFactorOf(address user) external view returns (uint256);

    function unLockFor(
        address asset,
        uint256 amount,
        uint256 srcChainId
    ) external;

    function initReserve(
        address reserve,
        address creditToken,
        address debtToken
    ) external;

    function liquidationCall(
        address collateral,
        address debt,
        address user,
        uint256 debtToCover
    ) external;

    function chainsight() external view returns (address);

    // return actualDebtToLiquidate
    function liquidationCallByChainsight(
        address collateral,
        address debt,
        address user,
        uint256 debtToCover,
        address onBehalfOf
    ) external returns (uint256);

    function assetAddresses(
        string memory symbol
    ) external view returns (address);

    function creditTokenAddress(address asset) external returns (address);

    function debtTokenAddress(address asset) external returns (address);

    function lockFor(
        address asset,
        uint256 amount,
        uint256 dstChainId
    ) external;

    // returns amount of underlying token of debt asset needed to liquidate debt
    function amountNeededToLiquidate(
        address collateral,
        address debt,
        address user,
        uint256 debtToCover
    ) external view returns (uint256);
}