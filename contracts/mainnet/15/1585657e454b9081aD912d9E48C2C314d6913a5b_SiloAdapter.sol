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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ISiloRouter, ISiloToken, ISiloRepository, ISiloLens, ISiloStrategy } from '../../interfaces/ISiloStrategy.sol';
import { TransferHelper } from '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

contract SiloAdapter {
    event Deposit(string label, address silo, address _asset, uint256 _amount);
    event Withdraw(string label, address silo, address _asset, uint256 _amount);
    event Borrow(string label, address silo, address _debtToken, address _debtPool, uint256 _amount);
    event Repay(string label, address silo, address _debtToken, uint256 _amount, address onBehalfOf);

    address immutable siloLens;

    constructor(address _siloLens) {
        siloLens = _siloLens;
    }

    function deposit(address _asset, uint256 _amount, address _market) external payable {
        address silo = ISiloToken(_market).silo();
        TransferHelper.safeApprove(_asset, silo, _amount);
        ISiloStrategy(silo).deposit(_asset, _amount, false);
        TransferHelper.safeApprove(_asset, silo, 0);

        emit Deposit('SILO', silo, _asset, _amount);
    }

    function depositAll(address _asset, address _market) external payable {
        address silo = ISiloToken(_market).silo();
        uint256 _amount = IERC20(_asset).balanceOf(address(this));

        TransferHelper.safeApprove(_asset, silo, _amount);
        ISiloStrategy(silo).deposit(_asset, _amount, false);
        TransferHelper.safeApprove(_asset, silo, 0);

        emit Deposit('SILO', silo, _asset, _amount);
    }

    function withdraw(address _asset, uint256 _amount, address _market) external payable {
        address silo = ISiloToken(_market).silo();
        ISiloStrategy(silo).withdraw(_asset, type(uint256).max, false);

        emit Withdraw('SILO', silo, _asset, _amount);
    }

    function withdrawAll(address _asset, address _market) external payable {
        address silo = ISiloToken(_market).silo();
        uint256 _amount = IERC20(_market).balanceOf(address(this));
        ISiloStrategy(silo).withdraw(_asset, type(uint256).max, false);

        emit Withdraw('SILO', silo, _asset, _amount);
    }

    function borrow(
        address _debtToken,
        address _debtPool,
        uint256 _amount,
        address _market
    ) external payable returns (bytes4, address) {
        address silo = ISiloToken(_market).silo();
        ISiloStrategy(silo).borrow(_debtToken, _amount);

        emit Borrow('SILO', silo, _debtToken, _debtPool, _amount);

        return (bytes4(keccak256('validateZeroBalance(address)')), _debtPool);
    }

    function repay(address _debtToken, uint256 _amount, address _market) external payable {
        address silo = ISiloToken(_market).silo();

        TransferHelper.safeApprove(_debtToken, silo, _amount);
        ISiloStrategy(silo).repay(_debtToken, _amount);
        TransferHelper.safeApprove(_debtToken, silo, 0);

        emit Repay('SILO', silo, _debtToken, _amount, address(this));
    }

    function repayOnBehalf(address _debtToken, uint256 _amount, address _market, address _onBehalfOf) external payable {
        address silo = ISiloToken(_market).silo();

        TransferHelper.safeApprove(_debtToken, silo, _amount);
        ISiloStrategy(silo).repayFor(_debtToken, _onBehalfOf, _amount);
        TransferHelper.safeApprove(_debtToken, silo, 0);

        emit Repay('SILO', silo, _debtToken, _amount, _onBehalfOf);
    }

    function repayAll(address _debtToken, address _debtPool, address _market) external payable {
        address silo = ISiloToken(_market).silo();
        ISiloStrategy(silo).accrueInterest(_debtToken);
        uint256 amount = _getRepayAmount(_debtToken, _debtPool, _market, address(this));

        TransferHelper.safeApprove(_debtToken, silo, amount);
        ISiloStrategy(silo).repayFor(_debtToken, address(this), amount);
        TransferHelper.safeApprove(_debtToken, silo, 0);

        emit Repay('SILO', silo, _debtToken, amount, address(this));
    }

    function repayAllOnBehalf(
        address _debtToken,
        address _debtPool,
        address _market,
        address _onBehalfOf
    ) external payable {
        address silo = ISiloToken(_market).silo();
        ISiloStrategy(silo).accrueInterest(_debtToken);
        uint256 amount = _getRepayAmount(_debtToken, _debtPool, _market, _onBehalfOf);

        TransferHelper.safeApprove(_debtToken, silo, amount);
        ISiloStrategy(silo).repayFor(_debtToken, _onBehalfOf, amount);
        TransferHelper.safeApprove(_debtToken, silo, 0);

        emit Repay('SILO', silo, _debtToken, amount, _onBehalfOf);
    }

    function _getRepayAmount(
        address _debtToken,
        address _debtPool,
        address _market,
        address onBehalfOf
    ) internal view returns (uint256) {
        address silo = ISiloToken(_market).silo();
        uint256 repayShare = IERC20(_debtPool).balanceOf(onBehalfOf);
        uint256 debtTokenTotalSupply = IERC20(_debtPool).totalSupply();
        uint256 totalBorrowed = ISiloLens(siloLens).totalBorrowAmount(silo, _debtToken);

        return toAmountRoundUp(repayShare, totalBorrowed, debtTokenTotalSupply);
    }

    function toAmountRoundUp(uint256 share, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        if (totalShares == 0 || totalAmount == 0) {
            return 0;
        }

        uint256 numerator = share * totalAmount;
        uint256 result = numerator / totalShares;

        // Round up
        if (numerator % totalShares != 0) {
            result += 1;
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISiloStrategy {
    struct AssetStorage {
        /// @dev Token that represents a share in totalDeposits of Silo
        address collateralToken;
        /// @dev Token that represents a share in collateralOnlyDeposits of Silo
        address collateralOnlyToken;
        /// @dev Token that represents a share in totalBorrowAmount of Silo
        address debtToken;
        /// @dev COLLATERAL: Amount of asset token that has been deposited to Silo with interest earned by depositors.
        /// It also includes token amount that has been borrowed.
        uint256 totalDeposits;
        /// @dev COLLATERAL ONLY: Amount of asset token that has been deposited to Silo that can be ONLY used
        /// as collateral. These deposits do NOT earn interest and CANNOT be borrowed.
        uint256 collateralOnlyDeposits;
        /// @dev DEBT: Amount of asset token that has been borrowed with accrued interest.
        uint256 totalBorrowAmount;
    }

    enum OperationMode {
        None,
        Supply,
        Repay
    }

    function assetStorage(address _asset) external view returns (AssetStorage memory);

    function deposit(
        address _asset,
        uint256 _amount,
        bool _collateralOnly
    ) external returns (uint256 collateralAmount, uint256 collateralShare);

    function withdraw(
        address _asset,
        uint256 _amount,
        bool _collateralOnly
    ) external returns (uint256 withdrawnAmount, uint256 withdrawnShare);

    function borrow(address _asset, uint256 _amount) external returns (uint256 debtAmount, uint256 debtShare);

    function repay(address _asset, uint256 _amount) external returns (uint256 repaidAmount, uint256 burnedShare);

    function repayFor(
        address _asset,
        address _borrower,
        uint256 _amount
    ) external returns (uint256 repaidAmount, uint256 burnedShare);

    function accrueInterest(address _asset) external;

    function getAssetsWithState() external view returns (address[] memory assets, AssetStorage[] memory assetsStorage);
}

interface ISiloLens {
    function depositAPY(ISiloStrategy _silo, address _asset) external view returns (uint256);

    function totalDepositsWithInterest(address _silo, address _asset) external view returns (uint256 _totalDeposits);

    function totalBorrowAmountWithInterest(
        address _silo,
        address _asset
    ) external view returns (uint256 _totalBorrowAmount);

    function collateralBalanceOfUnderlying(
        address _silo,
        address _asset,
        address _user
    ) external view returns (uint256);

    function debtBalanceOfUnderlying(address _silo, address _asset, address _user) external view returns (uint256);

    function balanceOfUnderlying(
        uint256 _assetTotalDeposits,
        address _shareToken,
        address _user
    ) external view returns (uint256);

    function calculateCollateralValue(address _silo, address _user, address _asset) external view returns (uint256);

    function calculateBorrowValue(
        address _silo,
        address _user,
        address _asset,
        uint256,
        uint256
    ) external view returns (uint256);

    function totalBorrowAmount(address _silo, address _asset) external view returns (uint256);
}

interface ISiloIncentiveController {
    function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);

    function getUserUnclaimedRewards(address user) external view returns (uint256);

    function REWARD_TOKEN() external view returns (address);
}

interface ISiloRepository {
    function isSiloPaused(address _silo, address _asset) external view returns (bool);

    function getSilo(address _asset) external view returns (address);

    function isSilo(address _silo) external view returns (bool);
}

interface ISiloToken {
    function silo() external view returns (address);
}

interface ISiloRouter {
    // @notice Action types that are supported
    enum ActionType {
        Deposit,
        Withdraw,
        Borrow,
        Repay
    }

    struct Action {
        // what do you want to do?
        uint8 actionType;
        // which Silo are you interacting with?
        address silo;
        // what asset do you want to use?
        address asset;
        // how much asset do you want to use?
        uint256 amount;
        // is it an action on collateral only?
        bool collateralOnly;
    }

    function execute(Action[] calldata _actions) external payable;
}