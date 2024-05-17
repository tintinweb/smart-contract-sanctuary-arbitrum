// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IUniversalOracle} from "../interfaces/IUniversalOracle.sol";
import {IDodoMiningPool} from "./interfaces/IDodoMiningPool.sol";
import {IDODO} from "./interfaces/IDodo.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DodoPoolStrategy {
    IUniversalOracle public universalOracle;
    IDODO public dodoProtocol;
    IDodoMiningPool public miningPool;
    address public lpTokenBase;
    address public lpTokenQuote;
    address public baseToken;
    address public quoteToken;
    address public rewardsToken;
    address public usdc;

    constructor(
        address _dodoProtocol,
        address _miningPool,
        address _universalOracle,
        address _usdc,
        address _rewardToken
    ) {
        universalOracle = IUniversalOracle(_universalOracle);
        dodoProtocol = IDODO(_dodoProtocol);
        miningPool = IDodoMiningPool(_miningPool);
        lpTokenBase = dodoProtocol._BASE_CAPITAL_TOKEN_();
        lpTokenQuote = dodoProtocol._QUOTE_CAPITAL_TOKEN_();
        baseToken = dodoProtocol._BASE_TOKEN_();
        quoteToken = dodoProtocol._QUOTE_TOKEN_();
        rewardsToken = _rewardToken;
        usdc = _usdc;
    }

    function getBalance(address strategist) external view returns (uint256) {
        address lpTokenBaseCache = lpTokenBase;
        address lpTokenQuoteCache = lpTokenQuote;
        uint256 lpBaseBalanceInMiningPool = miningPool.getUserLpBalance(
            lpTokenBaseCache,
            strategist
        );
        uint256 lpQouteBalanceInMiningPool = miningPool.getUserLpBalance(
            lpTokenQuoteCache,
            strategist
        );
        uint256 userBalanceLpBase = IERC20(lpTokenBaseCache).balanceOf(
            strategist
        );
        uint256 userBalanceLpQoute = IERC20(lpTokenQuoteCache).balanceOf(
            strategist
        );
        uint256 totalBaseLpInUsdc = _getBaseInUsdc(
            lpBaseBalanceInMiningPool + userBalanceLpBase
        );
        uint256 totalQuoteLpInUsdc = _getQuoteInUsdc(
            lpQouteBalanceInMiningPool + userBalanceLpQoute
        );
        uint256 totalRewardsInUsdc = _getRewardsInUsdc(
            strategist,
            lpTokenBaseCache,
            lpTokenQuoteCache
        );
        return totalBaseLpInUsdc + totalQuoteLpInUsdc;
    }

    function _getRewardsInUsdc(
        address _strategist,
        address _lpTokenBase,
        address _lpTokenQuote
    ) internal view returns (uint256) {
        uint256 rewardsForBaseLp = miningPool.getPendingReward(
            _lpTokenBase,
            _strategist
        );
        uint256 rewardsForQouteLp = miningPool.getPendingReward(
            _lpTokenQuote,
            _strategist
        );
        if (rewardsForBaseLp + rewardsForQouteLp == 0) {
            return 0;
        } else {
            return
                universalOracle.getValue(
                    rewardsToken,
                    rewardsForBaseLp + rewardsForQouteLp,
                    usdc
                );
        }
    }

    function _getQuoteInUsdc(uint256 amount) private view returns (uint256) {
        (, uint256 quoteTarget) = dodoProtocol.getExpectedTarget();
        uint256 totalQuoteCapital = dodoProtocol.getTotalQuoteCapital();

        uint256 requireQuoteCapital = (amount * totalQuoteCapital) /
            quoteTarget;
        return universalOracle.getValue(quoteToken, requireQuoteCapital, usdc);
    }

    function _getBaseInUsdc(uint256 amount) private view returns (uint256) {
        (uint256 baseTarget, ) = dodoProtocol.getExpectedTarget();
        uint256 totalBaseCapital = dodoProtocol.getTotalBaseCapital();
        uint256 requireBaseCapital = (amount * totalBaseCapital) / baseTarget;
        return universalOracle.getValue(baseToken, requireBaseCapital, usdc);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IDODO {
    function init(
        address owner,
        address supervisor,
        address maintainer,
        address baseToken,
        address quoteToken,
        address oracle,
        uint256 lpFeeRate,
        uint256 mtFeeRate,
        uint256 k,
        uint256 gasPriceLimit
    ) external;

    function transferOwnership(address newOwner) external;

    function claimOwnership() external;

    function getLpQuoteBalance(address user) external view returns (uint256);

    function getLpBaseBalance(address user) external view returns (uint256);

    function sellBaseToken(
        uint256 amount,
        uint256 minReceiveQuote,
        bytes calldata data
    ) external returns (uint256);

    function buyBaseToken(
        uint256 amount,
        uint256 maxPayQuote,
        bytes calldata data
    ) external returns (uint256);

    function querySellBaseToken(
        uint256 amount
    ) external view returns (uint256 receiveQuote);

    function queryBuyBaseToken(
        uint256 amount
    ) external view returns (uint256 payQuote);

    function getExpectedTarget()
        external
        view
        returns (uint256 baseTarget, uint256 quoteTarget);

    function depositBaseTo(
        address to,
        uint256 amount
    ) external returns (uint256);

    function withdrawBase(uint256 amount) external returns (uint256);

    function withdrawAllBase() external returns (uint256);

    function depositQuoteTo(
        address to,
        uint256 amount
    ) external returns (uint256);

    function getTotalBaseCapital() external view returns (uint256);

    function getTotalQuoteCapital() external view returns (uint256);

    function withdrawQuote(uint256 amount) external returns (uint256);

    function withdrawAllQuote() external returns (uint256);

    function _BASE_CAPITAL_TOKEN_() external view returns (address);

    function _QUOTE_CAPITAL_TOKEN_() external view returns (address);

    function _BASE_TOKEN_() external returns (address);

    function _QUOTE_TOKEN_() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDodoMiningPool {
    function getPendingReward(
        address _lpToken,
        address _user
    ) external view returns (uint256);

    function getUserLpBalance(
        address _lpToken,
        address _user
    ) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

interface IUniversalOracle {
    function getValue(
        address baseAsset,
        uint256 amount,
        address quoteAsset
    ) external view returns (uint256 value);

    function getValues(
        address[] calldata baseAssets,
        uint256[] calldata amounts,
        address quoteAsset
    ) external view returns (uint256);

    function WETH() external view returns (address);

    function isSupported(address asset) external view returns (bool);

    function getPriceInUSD(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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