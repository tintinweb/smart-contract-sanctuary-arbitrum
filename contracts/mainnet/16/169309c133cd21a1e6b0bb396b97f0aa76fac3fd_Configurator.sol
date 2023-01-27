// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IConfigurable {
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function setOracle(address, address) external;
    function setPath(address, address, address, bytes calldata) external;
    function setStrategy(uint256, address) external;
}

contract Configurator {
    error NoEmergency();
    error Unauthorized();
    error TransactionError();
    error ChangerNoExec();

    bool public emergencyRenounced = false;
    mapping(address => bool) public canOwn;
    mapping(address => bool) public canChange;
    mapping(address => bool) public canTweak;

    event SetOwner(address user, bool can);
    event SetChanger(address user, bool can);
    event SetTweaker(address user, bool can);
    event SetOracle(address strategyHelper, address asset, address oracle);
    event SetPath(address strategyHelper, address ast0, address ast1, address venue, bytes path);
    event SetStrategy(address investor, uint256 index, address strategy);
    event File(address target, bytes32 what, uint256 data);
    event FileAddress(address target, bytes32 what, address data);
    event Transaction(address target, uint256 value, bytes data);

    constructor() {
        canOwn[msg.sender] = true;
    }

    modifier owner() {
        if (!canOwn[msg.sender]) revert Unauthorized();
        _;
    }

    modifier changer() {
        if (!canOwn[msg.sender] && !canChange[msg.sender]) revert Unauthorized();
        _;
    }

    modifier tweaker() {
        if (!canOwn[msg.sender] && !canChange[msg.sender] && !canTweak[msg.sender]) revert Unauthorized();
        _;
    }

    function renounceEmergency() external owner {
        emergencyRenounced = true;
    }

    function setOwner(address user, bool can) external owner {
        canOwn[user] = can;
        emit SetOwner(user, can);
    }

    function setChanger(address user, bool can) external owner {
        canChange[user] = can;
        emit SetChanger(user, can);
    }

    function setTweaker(address user, bool can) external owner {
        canTweak[user] = can;
        emit SetTweaker(user, can);
    }

    function setOracle(address strategyHelper, address asset, address oracle) external tweaker {
        IConfigurable(strategyHelper).setOracle(asset, oracle);
        emit SetOracle(strategyHelper, asset, oracle);
    }

    function setPath(address strategyHelper, address ast0, address ast1, address venue, bytes calldata path) external tweaker {
        IConfigurable(strategyHelper).setPath(ast0, ast1, venue, path);
        emit SetPath(strategyHelper, ast0, ast1, venue, path);
    }

    function setStrategy(address investor, uint256 index, address strategy) external changer {
        IConfigurable(investor).setStrategy(index, strategy);
        emit SetStrategy(investor, index, strategy);
    }

    // Pool: paused, borrowMin, borrowFactor, liquidationFactor, amountCap
    // Strategy: cap, status, slippage
    // Investor: status
    // InvestorActor: performanceFee, originationFee, liquidationFee, softLiquidationSize, softLiquidationThreshold
    function file(address target, bytes32 what, uint256 data) external tweaker {
        IConfigurable(target).file(what, data);
        emit File(target, what, data);
    }

    // Pool: rateModel, oracle
    // Investor: pools, actor
    // InvestorActor: positionManager
    function fileAddress(address target, bytes32 what, address data) external changer {
        if (what == "exec") revert ChangerNoExec();
        IConfigurable(target).file(what, data);
        emit FileAddress(target, what, data);
    }

    // Pool: exec
    // Strategy: exec
    // Investor: exec
    // InvestorActor: exec
    function fileAddressExec(address target, bytes32 what, address data) external owner {
        IConfigurable(target).file(what, data);
        emit FileAddress(target, what, data);
    }

    // Arbitrary transaction, but disallow `emergencyForTesting` calls after renounced
    function transaction(address target, uint256 value, bytes calldata data) external owner {
        if (bytes4(data) == 0xddf99ceb && emergencyRenounced) revert NoEmergency();
        (bool success,) = target.call{value: value}(data);
        if (!success) revert TransactionError();
        emit Transaction(target, value, data);
    }
}