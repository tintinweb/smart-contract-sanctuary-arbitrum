/**
 *Submitted for verification at Arbiscan.io on 2023-08-29
*/

// File: contracts/interfaces/INOBIDnsAutomationCalculator.sol


pragma solidity ^0.8.0;

interface INOBIDnsAutomationCalculator {
    function calculateMinOut(
        address tokenAddress,
        address chainlinkPairAddress,
        uint256 sellGlpAmount,
        uint256 withdrawalFeePercentage
    ) external view returns (uint256 minOutToken);
}

// File: contracts/interfaces/INOBIDnsAutomationExecutor.sol


pragma solidity ^0.8.0;

interface INOBIDnsAutomationExecutor {
    function repayDebt(
        address payable tokenAddress,
        address payable debitorAddress,
        uint256 sellGlpAmount,
        uint256 minOut
    ) external;
}

// File: contracts/interfaces/INOBIDnsAutomationHelper.sol


pragma solidity ^0.8.0;

interface INOBIDnsAutomationHelper {
    function owner() external view returns (address);

    function PRICE_PRECISION() external view returns (uint256);

    function AAVE_POOL_PROXY_ADDRESS() external view returns (address);

    function GMX_GLP_MANAGER_ADDRESS() external view returns (address);

    function GMX_FSGLP_TOKEN_ADDRESS() external view returns (address);

    function aaveGetHealthFactor(address debitorAddress)
        external
        view
        returns (uint256 healthFactor);

    function chainlinkGetTokenOutUsdPrice(address chainlinkPairAddress)
        external
        view
        returns (int256 response);

    function chainlinkGetTokenOutUsdDecimal(address chainlinkPairAddress)
        external
        view
        returns (uint256 response);

    function erc20GetDecimal(address tokenAddress)
        external
        view
        returns (uint256 response);

    function gmxGetGlpAmount(address debitorAddress)
        external
        view
        returns (uint256 response);

    function gmxGetGlpPrice() external view returns (uint256 response);

    function gmxGetGlpPricePrecision() external view returns (uint256 response);

    function changeOwner(address newOwner) external;

    function setAAVEPoolProxyAddress(address _aavePoolProxyAddress) external;

    function setGMXGLPManagerAddress(address _gmxGlpManagerAddress) external;

    function setGMXFSGLPTokenAddress(address _gmxFSGLPTokenAddress) external;
}

// File: contracts/interfaces/IERC20.sol


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

    function decimals() external view returns (uint8) ;

}
// File: contracts/arbitrum/NOBIDnsAutomationResolver.sol



pragma solidity >=0.7.0 <0.9.0;





interface IResolver {
    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload);
}

contract NOBIDnsAutomationResolver is IResolver {
    address public EXECUTOR_CONTRACT_ADDRESS =
        0xD5eEe13d41A25e50E67E95c2B7836e44ba9Cf4a2;
    address public HELPER_CONTRACT_ADDRESS =
        0x87A9973d802a8ceB5c49EFB04D522B150Cf10E91;
    address public CALCULATOR_CONTRACT_ADDRESS =
        0x5Bde5e224f0123fe6Dfc13A4b6d4B983bD3314a7;

    address public owner;
    address public DEBITOR_ADDRESS = 0x36Ab9eCC6AcA30c774654af716119DC054031Bc7;
    uint256 public THRESHOLD_HEALTH = 1100000000000000000;
    uint256 public SLIPPAGE = 50;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function changeThreshold(uint256 _newThreshold) public onlyOwner {
        THRESHOLD_HEALTH = _newThreshold;
    }

    function changeDebtOwner(address _newDebtOwner) public onlyOwner {
        DEBITOR_ADDRESS = _newDebtOwner;
    }

    function changeSlippage(uint256 _newSlippage) public onlyOwner {
        SLIPPAGE = _newSlippage;
    }

    function changeExecutorContractAddress(address _newExecutorContractAddress)
        public
        onlyOwner
    {
        EXECUTOR_CONTRACT_ADDRESS = _newExecutorContractAddress;
    }

    function checker()
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        INOBIDnsAutomationHelper helper = INOBIDnsAutomationHelper(
            HELPER_CONTRACT_ADDRESS
        );
        INOBIDnsAutomationCalculator calculator = INOBIDnsAutomationCalculator(
            CALCULATOR_CONTRACT_ADDRESS
        );

        uint256 healthFactor = helper.aaveGetHealthFactor(DEBITOR_ADDRESS);

        if (healthFactor > THRESHOLD_HEALTH) {
            canExec = false;
            execPayload = "Skipped, Above Threshold";
        } else {
            uint256 glpAmount = helper.gmxGetGlpAmount(DEBITOR_ADDRESS);
            address tokenAddress = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
            address chainlinkPairAddress = 0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7;

            uint256 minOut = calculator.calculateMinOut(
                tokenAddress,
                chainlinkPairAddress,
                glpAmount,
                SLIPPAGE
            );

            canExec = true;
            execPayload = abi.encodeWithSelector(
                INOBIDnsAutomationExecutor.repayDebt.selector,
                tokenAddress,
                DEBITOR_ADDRESS,
                glpAmount,
                minOut
            );
        }
    }
}