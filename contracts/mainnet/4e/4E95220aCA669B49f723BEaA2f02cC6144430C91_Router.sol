// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity 0.8.11;

interface IMintable {
    function isMinter(address _account) external returns (bool);

    function setMinter(address _minter, bool _isActive) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);

    function stakedAmounts(address _account) external view returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;

    function tokensPerInterval() external view returns (uint256);

    function claim(address _receiver) external returns (uint256);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function averageStakedAmounts(address _account) external view returns (uint256);

    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IStrategyVault {
    function totalAssets() external view returns (uint256);

    function handleBuy(uint256 _amount) external payable returns (uint256);

    function handleSell(uint256 _amount, address _recipient) external payable;

    function harvest() external;

    function confirm() external;

    function totalValue() external view returns (uint256);

    function executePositions(bytes4[] calldata _selectors, bytes[] calldata _params) external payable;

    function confirmAndDealGlp(bytes4 _selector, bytes calldata _param) external;

    function executeDecreasePositions(bytes[] calldata _params) external payable;

    function executeIncreasePositions(bytes[] calldata _params) external payable;

    function buyNeuGlp(uint256 _amountIn) external returns (uint256);

    function sellNeuGlp(uint256 _glpAmount, address _recipient) external returns (uint256);

    function settle(uint256 _amount, address _recipient) external;
    
    function exited() external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { Governable } from "./libraries/Governable.sol";
import { IStrategyVault } from "./interfaces/IStrategyVault.sol";
import { IRewardTracker} from "./interfaces/IRewardTracker.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IMintable } from "./interfaces/IMintable.sol";

contract Router is ReentrancyGuard, Governable {
    bool public isSale;
    bool public initialDeposit;

    uint256 public constant PRICE_PRECISION = 1e30;
    address public strategyVault;
    uint256 public executionFee = 0.0001 ether;

    uint256 public wantBeforeCollateralIn;
    
    address public want;
    address public wbtc;
    address public weth;
    address public nGlp;

    address public feeNeuGlpTracker;
    address public stakedNeuGlpTracker;

    mapping(address => bool) public isHandler;
    mapping(address => uint256) public pendingAmounts;

    event ExecutePositionsBeforeDealGlpDeposit(uint256 amount, uint256 pendingAmountsWant);
    event ExecutePositionsBeforeDealGlpWithdraw(uint256 amount, uint256 wantBeforeCollateralIn);
    event ConfirmAndBuy(uint256 wantPendingAmount, uint256 mintAmount);
    event ConfirmAndSell(uint256 snGlpPendingAmount);
    event SetTrackers(address feeNeuGlpTracker, address stakedNeuGlpTracker);
    event SetExecutionFee(uint256 executionFee);
    event SetSale(bool isActive);
    event SetHandler(address handler, bool isActive);
    
    modifier onlyHandler() {
        _onlyHandler();
        _;
    }

    constructor(address _vault, address _want, address _wbtc, address _weth, address _nGlp) {
        strategyVault = _vault;
        want = _want;
        wbtc = _wbtc;
        weth = _weth;
        nGlp = _nGlp;

        IERC20(want).approve(_vault, type(uint256).max);
    }

    function _onlyHandler() internal view {
        require(isHandler[msg.sender], "Router: forbidden");
    }

    function approveToken(address _token, address _spender) external onlyGov {
        IERC20(_token).approve(_spender, type(uint256).max);
    } 

    function setHandler(address _handler, bool _isActive) public onlyGov {
        require(_handler != address(0), "Router: invalid address");
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    function setHandlers(address[] memory _handler, bool[] memory _isActive) external onlyGov {
        for(uint256 i = 0; i < _handler.length; i++){
            setHandler(_handler[i], _isActive[i]);
        }
    }

    /*
    NOTE:
    GMX requires two part transaction process to increase or decrease positions
    therefore, router has to conduct two transactions to finish the process
    always execute this function first then confirm and handle glp
    */
    function executePositionsBeforeDealGlp(uint256 _amount, bytes[] calldata _params, bool _isWithdraw) external payable onlyHandler {
        if (!_isWithdraw) {
            require(pendingAmounts[want] == 0, "Router: pending amount exists");
            IERC20(want).transferFrom(msg.sender, address(this), _amount);

            uint256 beforeBalance = IERC20(want).balanceOf(address(this));
            IStrategyVault(strategyVault).executeIncreasePositions{value: msg.value}(_params);
            uint256 usedAmount = beforeBalance - IERC20(want).balanceOf(address(this));
            pendingAmounts[want] = _amount - usedAmount;

            emit ExecutePositionsBeforeDealGlpDeposit(_amount, pendingAmounts[want]);
        } else {
            require(wantBeforeCollateralIn == 0, "Router: pending position exists");
            require(pendingAmounts[nGlp] == 0, "Router: pending amount exists");

            IERC20(nGlp).transferFrom(msg.sender, address(this), _amount);

            pendingAmounts[nGlp] = _amount;
            IStrategyVault(strategyVault).executeDecreasePositions{value: msg.value}(_params);
            wantBeforeCollateralIn = IERC20(want).balanceOf(address(this));

            emit ExecutePositionsBeforeDealGlpWithdraw(_amount, wantBeforeCollateralIn);
        }
    }

    /*
    NOTE:
    After positions execution, requires to confirm those postiions
    If positions are executed successfully, then buys glp
    */
    function confirmAndBuy(uint256 _wantAmount, address _recipient) external onlyHandler returns (uint256) {
        uint256 pendingAmountsWant = pendingAmounts[want];
        require(pendingAmountsWant == _wantAmount, "Router: want amount different with pending amount");
        IStrategyVault _vault = IStrategyVault(strategyVault);
        _vault.confirm();

        uint256 totalSupply = IERC20(nGlp).totalSupply();
        uint256 totalValue = _vault.totalValue();

        uint256 value = _vault.buyNeuGlp(pendingAmountsWant);
        pendingAmounts[want] = 0;
        uint256 decimals = IERC20(nGlp).decimals();
        uint256 mintAmount = totalSupply == 0 ? value * (10 ** decimals) / PRICE_PRECISION : value * totalSupply / totalValue;

        IMintable(nGlp).mint(_recipient, mintAmount);

        IRewardTracker(feeNeuGlpTracker).stakeForAccount(_recipient, _recipient, nGlp, mintAmount);
        IRewardTracker(stakedNeuGlpTracker).stakeForAccount(_recipient, _recipient, feeNeuGlpTracker, mintAmount);

        emit ConfirmAndBuy(pendingAmountsWant, mintAmount);

        return mintAmount;
    }
    
    /*
    NOTE:
    After positions execution, requires to confirm those postiions
    If positions are executed successfully, then sells glp
    */
    function confirmAndSell(uint256 _glpAmount, address _recipient) external onlyHandler returns (uint256) {
        uint256 pendingAmount = pendingAmounts[nGlp];
        require(pendingAmount > 0, "Router: no pending amounts to sell");
        IStrategyVault _vault = IStrategyVault(strategyVault);
        
        _vault.confirm();

        uint256 collateralIn = IERC20(want).balanceOf(address(this)) - wantBeforeCollateralIn;

        uint256 amountOut = _vault.sellNeuGlp(_glpAmount, address(this));
        IMintable(nGlp).burn(address(this), pendingAmount);

        pendingAmounts[nGlp] = 0;

        amountOut += collateralIn;

        IERC20(want).transfer(_recipient, amountOut);
        wantBeforeCollateralIn = 0;

        emit ConfirmAndSell(pendingAmount);

        return amountOut;
    }

    // call only if strategy is exited
    // make sure to withdraw insuranceFund and withdraw fees beforehand
    function settle(uint256 _amount) external {
        require(IStrategyVault(strategyVault).exited(), "Router: strategy not exited yet");
        IRewardTracker(stakedNeuGlpTracker).unstakeForAccount(msg.sender, feeNeuGlpTracker, _amount, msg.sender);
        IRewardTracker(feeNeuGlpTracker).unstakeForAccount(msg.sender, nGlp, _amount, address(this));
        IStrategyVault(strategyVault).settle(_amount, msg.sender);
        IMintable(nGlp).burn(address(this), _amount);
    }
    
    function setExecutionFee(uint256 _fee) external onlyGov {
        executionFee = _fee;
        emit SetExecutionFee(_fee);
    }

    function setSale(bool _isActive) external onlyGov {
        isSale = _isActive;
        emit SetSale(_isActive);
    }

    function setTrackers(address _feeNeuGlpTracker, address _stakedNeuGlpTracker) external onlyGov {
        require(_feeNeuGlpTracker != address(0) && _stakedNeuGlpTracker != address(0), "BatchRouter: invalid address");
        feeNeuGlpTracker = _feeNeuGlpTracker;
        stakedNeuGlpTracker = _stakedNeuGlpTracker;
        emit SetTrackers(_feeNeuGlpTracker, _stakedNeuGlpTracker);
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverFungibleTokens(address _token) external onlyGov {
        uint256 amountToRecover = IERC20(_token).balanceOf(address(this));
        require(amountToRecover != 0, "Operations: No token to recover");

        IERC20(_token).transfer(address(msg.sender), amountToRecover);
    }
}