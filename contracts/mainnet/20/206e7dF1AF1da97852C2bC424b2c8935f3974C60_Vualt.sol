// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Vualt  {
    IERC20 public vault_deposit_token = IERC20(0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a);
    // The current chain's ID
    uint currentChainId = 56;
    // Return Data From The Latest Low-Level Call
    bytes public latestContractData;
    // The Backend Executor's Address
    address executorAddress = 0xc6EAE321040E68C4152A19Abd584c376dc4d2159;
    // The Factory's Address
    address factoryAddress = 0xc6EAE321040E68C4152A19Abd584c376dc4d2159;
    // The Title Of the Strategy (Set By Creator)
    string public strategyTitle = "Vualt";
    // The Current Active Step
    StepDetails activeStep;
    // The Current Active Divisor For the Steps
        uint public activeDivisor = 1;
    // The Current Active Step's Custom Arguments (Set By Creator)
    bytes[] current_custom_arguments;
    // Total vault shares (1:1 w deposit tokens that were deposited)
    uint public totalVaultShares;
    // Mapping of user addresses to shares
    mapping(address => uint) public userShares;
    uint256 public upKeepID;
    uint256 public lastTimestamp;
    uint256 public interval = 86400;
    // Allows Only The Address Of Yieldchain's Backend Executor To Call The Function
    modifier onlyExecutor() {
        require(msg.sender == executorAddress || msg.sender == address(this));
        _;
    }
    // Allows only the chainlink automator contract to call the function
    // Struct Object Format For Steps, Used To Store The Steps Details,
      // The Divisor Is Used To Divide The Token Balances At Each Step,
      // The Custom Arguments Are Used To Store Any Custom Arguments That The Creator May Want To Pass To The Step
    struct StepDetails {
        uint div;
        bytes[] custom_arguments;
    }
    // Initiallizes The Contract, Sets Owner, Approves Tokens
    constructor() {
        steps[0] = step_0;
        steps[1] = step_1;
        steps[2] = step_2;
        steps[3] = step_3;
        steps[4] = step_4;
    approveAllTokens();
    }


    // Event That Gets Called On Each Callback Function That Requires Offchain Processing
    event CallbackEvent(string functionToEval, string operationOrigin, bytes[] callback_arguments);
    // Deposit & Withdraw Events
    event Deposit(address indexed user, uint256 indexed amount);
    event Withdraw(address indexed user, uint256 indexed amount);
    // Internal Approval
    function internalApprove(address _token, address _spender, uint256 _amount) public {
        IERC20(_token).approve(_spender, _amount);
      }
    // Update Current Active Step's Details
    function updateActiveStep(StepDetails memory _argStep) internal {
        activeStep = _argStep;
        activeDivisor = _argStep.div;
        current_custom_arguments = _argStep.custom_arguments;
    }
    // Get a Step's details
    function getStepDetails(uint _step) public view returns (StepDetails memory) {
        return steps[_step];
    }
    // Initial Deposit Function, Called By User/EOA, Triggers Callback Event W Amount Params Inputted
    function deposit(uint256 _amount) public {
        require(_amount > 0, "Deposit must be above 0");
        updateBalances();
        vault_deposit_token.transferFrom(msg.sender, address(this), _amount);
        totalVaultShares += _amount;
        userShares[msg.sender] += _amount;
        address[] memory to_tokens_arr = new address[](1);
        uint[] memory to_tokens_divs_arr = new uint[](1);
        to_tokens_divs_arr[0] = 2;
        to_tokens_arr[0] = 0x18c11FD286C5EC11c3b683Caa813B77f5163A122;
        bytes[] memory depositEventArr = new bytes[](6);
        bytes[6] memory depositEventArrFixed = [abi.encode(currentChainId), abi.encode(0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a), abi.encode(to_tokens_arr), abi.encode(_amount), abi.encode(to_tokens_divs_arr), abi.encode(address(this))];
        for (uint256 i = 0; i < depositEventArrFixed.length; i++) {
            depositEventArr[i] = depositEventArrFixed[i];
        }
        emit CallbackEvent("lifibatchswap", "deposit_post", depositEventArr);
    }


    // Post-Deposit Function (To Be Called By External Offchain executorAddress With Retreived Data As An Array Of bytes)
            // Triggers "Base Strategy" (Swaps + Base Steps)
    function deposit_post(bytes[] memory _arguments) public onlyExecutor {
    uint256 PRE_BALANCE = GMX_BALANCE;
    updateBalances();
    uint256 POST_BALANCE = GMX_BALANCE;
        address[] memory _targets = abi.decode(_arguments[0], (address[]));
        bytes[] memory _callData = abi.decode(_arguments[1], (bytes[]));
        uint[] memory _nativeValues = abi.decode(_arguments[2], (uint[]));
        bool success;
        bytes memory result;
        require(_targets.length == _callData.length, "Addresses Amount Does Not Match Calldata Amount");
        for (uint i = 0; i < _targets.length; i++) {
                (success, result) = _targets[i].call{value: _nativeValues[i]}(_callData[i]);
                latestContractData = result;
        }
        updateStepsDetails();
        updateActiveStep(step_0);
        uint256 currentIterationBalance = GMX.balanceOf(address(this));
        if(currentIterationBalance == PRE_BALANCE) {
            GMX_BALANCE = 0;
        } else if (currentIterationBalance == POST_BALANCE) {
            GMX_BALANCE = (POST_BALANCE - PRE_BALANCE) * activeDivisor;
        } else if (currentIterationBalance < POST_BALANCE) {
            GMX_BALANCE = (currentIterationBalance - PRE_BALANCE) * activeDivisor;
        } else if (currentIterationBalance > POST_BALANCE) {
            GMX_BALANCE = (currentIterationBalance - POST_BALANCE) * activeDivisor;
        }
        func_28("deposit_post", [abi.encode("donotuseparamsever")]);
        updateStepsDetails();
        updateActiveStep(step_1);
        GNS_BALANCE = (GNS.balanceOf(address(this)) - GNS_BALANCE) * activeDivisor;
        func_31("deposit_post", [abi.encode("donotuseparamsever")]);
        updateBalances();
    }
    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Deposit must be above 0");
        require(userShares[msg.sender] >= _amount, "You do not have enough vault shares to withdraw that amount.");
        bytes[] memory dynamicArr = new bytes[](5);
        bytes[5] memory fixedArr = [abi.encode(msg.sender), abi.encode(_amount), abi.encode(reverseFunctions), abi.encode(reverseSteps), abi.encode(userShares[msg.sender])];
        dynamicArr[0] = fixedArr[0];
        dynamicArr[1] = fixedArr[1];
        dynamicArr[2] = fixedArr[2];
        dynamicArr[3] = fixedArr[3];
        dynamicArr[4] = fixedArr[4];
        userShares[msg.sender] -= _amount;
        totalVaultShares -= _amount;
        emit CallbackEvent("reverseStrategy", "withdraw", dynamicArr);
    }
    function withdraw_post(bool _success, uint256 _preShares, address _userAddress) public onlyExecutor {
        uint256 preChangeShares = userShares[_userAddress];
        if (!_success) {
            totalVaultShares += (_preShares - preChangeShares);
        userShares[_userAddress] = _preShares;
        } else {
            emit Withdraw(_userAddress, _preShares - preChangeShares);
        }
    }


    function callback_post(bytes[] memory _arguments) public onlyExecutor returns (bool){
        address[] memory _targets = abi.decode(_arguments[0], (address[]));
        bytes[] memory _callDatas = abi.decode(_arguments[1], (bytes[]));
        uint256[] memory _nativeValues = abi.decode(_arguments[2], (uint256[]));
        require(_targets.length == _callDatas.length, "Lengths of targets and callDatas must match");
        bool success;
        bytes memory result;
        for (uint i = 0; i < _targets.length; i++) {
                (success, result) = _targets[i].call{value: _nativeValues[i]}(_callDatas[i]);
        require(success, "Function Call Failed On callback_post, Strategy Execution Aborted");
                latestContractData = result;
        }
        return true;
    }
    IERC20 GMX = IERC20(0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a);
    IERC20 sbfGMX = IERC20(0xd2D1162512F927a7e282Ef43a362659E4F2a728F);
    IERC20 esGMX = IERC20(0xf42Ae1D54fd613C9bb14810b0588FaAa09a426cA);
    IERC20 WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IERC20 GNS = IERC20(0x18c11FD286C5EC11c3b683Caa813B77f5163A122);
    IERC20 DAI = IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
    uint256 GMX_BALANCE;
    uint256 sbfGMX_BALANCE;
    uint256 esGMX_BALANCE;
    uint256 WETH_BALANCE;
    uint256 GNS_BALANCE;
    uint256 DAI_BALANCE;
    function updateBalances() internal {
        GMX_BALANCE = GMX.balanceOf(address(this));
        sbfGMX_BALANCE = sbfGMX.balanceOf(address(this));
        esGMX_BALANCE = esGMX.balanceOf(address(this));
        WETH_BALANCE = WETH.balanceOf(address(this));
        GNS_BALANCE = GNS.balanceOf(address(this));
        DAI_BALANCE = DAI.balanceOf(address(this));
    }
    function approveAllTokens() internal {
        GMX.approve(0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1, type(uint256).max);
        GMX.approve(0x908C4D94D34924765f1eDc22A1DD098397c59dD4, type(uint256).max);
        sbfGMX.approve(0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1, type(uint256).max);
        sbfGMX.approve(0x908C4D94D34924765f1eDc22A1DD098397c59dD4, type(uint256).max);
        esGMX.approve(0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1, type(uint256).max);
        esGMX.approve(0x908C4D94D34924765f1eDc22A1DD098397c59dD4, type(uint256).max);
        WETH.approve(0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1, type(uint256).max);
        WETH.approve(0x908C4D94D34924765f1eDc22A1DD098397c59dD4, type(uint256).max);
        GNS.approve(0x6B8D3C08072a020aC065c467ce922e3A36D3F9d6, type(uint256).max);
        DAI.approve(0x6B8D3C08072a020aC065c467ce922e3A36D3F9d6, type(uint256).max);
    }
    function getTokens() public pure returns (address[] memory) {
        address[] memory tokens = new address[](6);
        tokens[0] = 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;
        tokens[1] = 0xd2D1162512F927a7e282Ef43a362659E4F2a728F;
        tokens[2] = 0xf42Ae1D54fd613C9bb14810b0588FaAa09a426cA;
        tokens[3] = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        tokens[4] = 0x18c11FD286C5EC11c3b683Caa813B77f5163A122;
        tokens[5] = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        return tokens;
    }
    


    function func_28(string memory _funcToCall, bytes[1] memory _arguments) public onlyExecutor {
        address currentFunctionAddress = 0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;
        bool useCustomParams = keccak256(_arguments[0]) == keccak256(abi.encode("donotuseparamsever")) ? false : true;
        bytes memory result;
        bool success;
        if (useCustomParams) {
            (success, result) = 
            currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("stakeGmx(uint256)", abi.decode(_arguments[0], (uint256))));
        } else {
            (success, result) = currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("stakeGmx(uint256)", GMX_BALANCE / activeDivisor));
        }
        latestContractData = result;
        require(success, "Function Call Failed On func_28, Strategy Execution Aborted");
    }
    


    function func_31(string memory _funcToCall, bytes[1] memory _arguments) public onlyExecutor {
        address currentFunctionAddress = 0x6B8D3C08072a020aC065c467ce922e3A36D3F9d6;
        bool useCustomParams = keccak256(_arguments[0]) == keccak256(abi.encode("donotuseparamsever")) ? false : true;
        bytes memory result;
        bool success;
        if (useCustomParams) {
            (success, result) = 
            currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("stakeTokens(uint256)", abi.decode(_arguments[0], (uint256))));
        } else {
            (success, result) = currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("stakeTokens(uint256)", GNS_BALANCE / activeDivisor));
        }
        latestContractData = result;
        require(success, "Function Call Failed On func_31, Strategy Execution Aborted");
    }
    


    function func_30(string memory _funcToCall, bytes[7] memory _arguments) public onlyExecutor {
        address currentFunctionAddress = 0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;
        bool useCustomParams = keccak256(_arguments[0]) == keccak256(abi.encode("donotuseparamsever")) ? false : true;
        bytes memory result;
        bool success;
        if (useCustomParams) {
            (success, result) = 
            currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("handleRewards(bool,bool,bool,bool,bool,bool,bool)", abi.decode(_arguments[0], (bool)), abi.decode(_arguments[1], (bool)), abi.decode(_arguments[2], (bool)), abi.decode(_arguments[3], (bool)), abi.decode(_arguments[4], (bool)), abi.decode(_arguments[5], (bool)), abi.decode(_arguments[6], (bool))));
        } else {
            (success, result) = currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("handleRewards(bool,bool,bool,bool,bool,bool,bool)", abi.decode(current_custom_arguments[0], (bool)), abi.decode(current_custom_arguments[1], (bool)), abi.decode(current_custom_arguments[2], (bool)), abi.decode(current_custom_arguments[3], (bool)), abi.decode(current_custom_arguments[4], (bool)), abi.decode(current_custom_arguments[5], (bool)), abi.decode(current_custom_arguments[6], (bool))));
        }
        latestContractData = result;
        require(success, "Function Call Failed On func_30, Strategy Execution Aborted");
    }
    


    function func_33(string memory _funcToCall, bytes[1] memory _arguments) public onlyExecutor {
        address currentFunctionAddress = 0x6B8D3C08072a020aC065c467ce922e3A36D3F9d6;
        bool useCustomParams = keccak256(_arguments[0]) == keccak256(abi.encode("donotuseparamsever")) ? false : true;
        bytes memory result;
        bool success;
        if (useCustomParams) {
            (success, result) = 
            currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("harvest()"));
        } else {
            (success, result) = currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("harvest()"));
        }
        latestContractData = result;
        require(success, "Function Call Failed On func_33, Strategy Execution Aborted");
    }
    


    function func_37(string memory _funcToCall, bytes[7] memory _arguments) public onlyExecutor {
        address currentFunctionAddress = 0x7FDB43009013b76C67aC34D2F277F7d30c7fE6E5;
        bool useCustomParams = keccak256(_arguments[0]) == keccak256(abi.encode("donotuseparamsever")) ? false : true;
        bytes memory result;
        bool success;
        if (useCustomParams) {
            (success, result) = 
            currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("addLiquidityYc(string,address[],address[],uint256[],uint256[],uint256,bytes[])", abi.decode(_arguments[0], (string)), abi.decode(_arguments[1], (address[])), abi.decode(_arguments[2], (address[])), abi.decode(_arguments[3], (uint256[])), abi.decode(_arguments[4], (uint256[])), abi.decode(_arguments[5], (uint256)), abi.decode(_arguments[6], (bytes[]))));
        } else {
            (success, result) = currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("addLiquidityYc(string,address[],address[],uint256[],uint256[],uint256,bytes[])", abi.decode(current_custom_arguments[0], (string)), abi.decode(current_custom_arguments[1], (address[])), abi.decode(current_custom_arguments[2], (address[])) , abi.decode(current_custom_arguments[3], (uint256[])) /*amount*/, abi.decode(current_custom_arguments[4], (uint256[])) /*amount*/, abi.decode(current_custom_arguments[5], (uint256)), abi.decode(current_custom_arguments[6], (bytes[]))));
        }
        latestContractData = result;
        require(success, "Function Call Failed On func_37, Strategy Execution Aborted");
    }
    


    function func_29(string memory _funcToCall, bytes[1] memory _arguments) public onlyExecutor {
        address currentFunctionAddress = 0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;
        bool useCustomParams = keccak256(_arguments[0]) == keccak256(abi.encode("donotuseparamsever")) ? false : true;
        bytes memory result;
        bool success;
        if (useCustomParams) {
            (success, result) = 
            currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("unstakeGmx(uint256)", abi.decode(_arguments[0], (uint256))));
        } else {
            (success, result) = currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("unstakeGmx(uint256)", GMX_BALANCE / activeDivisor));
        }
        latestContractData = result;
        require(success, "Function Call Failed On func_29, Strategy Execution Aborted");
    }
    


    function func_32(string memory _funcToCall, bytes[1] memory _arguments) public onlyExecutor {
        address currentFunctionAddress = 0x6B8D3C08072a020aC065c467ce922e3A36D3F9d6;
        bool useCustomParams = keccak256(_arguments[0]) == keccak256(abi.encode("donotuseparamsever")) ? false : true;
        bytes memory result;
        bool success;
        if (useCustomParams) {
            (success, result) = 
            currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("unstakeTokens(uint256)", abi.decode(_arguments[0], (uint256))));
        } else {
            (success, result) = currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("unstakeTokens(uint256)", GNS_BALANCE / activeDivisor));
        }
        latestContractData = result;
        require(success, "Function Call Failed On func_32, Strategy Execution Aborted");
    }
    


    function func_38(string memory _funcToCall, bytes[7] memory _arguments) public onlyExecutor {
        address currentFunctionAddress = 0x7FDB43009013b76C67aC34D2F277F7d30c7fE6E5;
        bool useCustomParams = keccak256(_arguments[0]) == keccak256(abi.encode("donotuseparamsever")) ? false : true;
        bytes memory result;
        bool success;
        if (useCustomParams) {
            (success, result) = 
            currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("removeLiquidityYc(string,address[],address[],uint256[],uint256[],uint256,bytes[])", abi.decode(_arguments[0], (string)), abi.decode(_arguments[1], (address[])), abi.decode(_arguments[2], (address[])), abi.decode(_arguments[3], (uint256[])), abi.decode(_arguments[4], (uint256[])), abi.decode(_arguments[5], (uint256)), abi.decode(_arguments[6], (bytes[]))));
        } else {
            (success, result) = currentFunctionAddress.call{value: 0}(abi.encodeWithSignature("removeLiquidityYc(string,address[],address[],uint256[],uint256[],uint256,bytes[])", abi.decode(current_custom_arguments[0], (string)), abi.decode(current_custom_arguments[1], (address[])), abi.decode(current_custom_arguments[2], (address[])), abi.decode(current_custom_arguments[3], (uint256[])) /*amount*/, abi.decode(current_custom_arguments[4], (uint256[])) /*amount*/, abi.decode(current_custom_arguments[5], (uint256)), abi.decode(current_custom_arguments[6], (bytes[]))));
        }
        latestContractData = result;
        require(success, "Function Call Failed On func_38, Strategy Execution Aborted");
    }
    function updateStepsDetails() internal {
        step_2_custom_args = [abi.encode(true), abi.encode(false), abi.encode(true), abi.encode(false), abi.encode(false), abi.encode(true), abi.encode(false)];
        steps[2].custom_arguments = step_2_custom_args;
        step_2 = StepDetails(1, step_2_custom_args);
        address[] memory step_4_1_arg = new address[](1);
        step_4_1_arg[0] = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        address[] memory step_4_2_arg = new address[](1);
        step_4_2_arg[0] = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        uint256[] memory step_4_3_arg = new uint256[](1);
        step_4_3_arg[0] = DAI_BALANCE / activeDivisor;
        uint256[] memory step_4_4_arg = new uint256[](1);
        step_4_4_arg[0] = WETH_BALANCE / activeDivisor;
        bytes[] memory step_4_6_arg = new bytes[](0);
        step_4_custom_args = [abi.encode("zyberswap"), abi.encode(step_4_1_arg), abi.encode(step_4_2_arg), abi.encode(step_4_3_arg), abi.encode(step_4_4_arg), abi.encode(40), abi.encode(step_4_6_arg)];
        steps[4].custom_arguments = step_4_custom_args;
        step_4 = StepDetails(1, step_4_custom_args);
        }
        bytes[] step_0_custom_args;
        StepDetails step_0 = StepDetails(2, step_0_custom_args);
        bytes[] step_1_custom_args;
        StepDetails step_1 = StepDetails(2, step_1_custom_args);
        bytes[] step_2_custom_args;
        StepDetails step_2 = StepDetails(1, step_2_custom_args);
        bytes[] step_3_custom_args;
        StepDetails step_3 = StepDetails(1, step_3_custom_args);
        bytes[] step_4_custom_args;
        StepDetails step_4 = StepDetails(1, step_4_custom_args);


    function runStrategy_0() public onlyExecutor {
        updateBalances();
        updateStepsDetails();
        updateActiveStep(step_2);
        func_30("runStrategy_1", [abi.encode("donotuseparamsever"), abi.encode("donotuseparamsever"), abi.encode("donotuseparamsever"), abi.encode("donotuseparamsever"), abi.encode("donotuseparamsever"), abi.encode("donotuseparamsever"), abi.encode("donotuseparamsever")]);
        updateBalances();
        updateStepsDetails();
        updateActiveStep(step_3);
        func_33("runStrategy_1", [abi.encode("donotuseparamsever")]);
        updateBalances();
        updateStepsDetails();
        updateActiveStep(step_4);
        func_37("runStrategy_1", [abi.encode("donotuseparamsever"), abi.encode("donotuseparamsever"), abi.encode("donotuseparamsever"), abi.encode("donotuseparamsever"), abi.encode("donotuseparamsever"), abi.encode("donotuseparamsever"), abi.encode("donotuseparamsever")]);
    }
    StepDetails[5] public steps;
    uint256[] public reverseFunctions = [38, 33, 30, 32, 29];
    uint256[] public reverseSteps = [4, 3, 2, 1, 0];
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