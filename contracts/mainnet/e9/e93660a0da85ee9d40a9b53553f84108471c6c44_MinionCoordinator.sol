// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Minion, ITimeToken } from "./Minion.sol";
import { ITVault } from "./ITVault.sol";

/// @title MinionCoordinator contract
/// @author Einar Cesar - TIME Token Finance - https://timetoken.finance
/// @notice Coordinates the creation and calling of Minions in order to produce TIME in a larger scale
/// @dev It is attached and managed by the WorkerVault
contract MinionCoordinator {
    struct MinionInstance {
        address prevInstance;
        address nextInstance;
    }

    bool private _isOperationLocked;

    ITVault private _worker;

    address public currentMinionInstance;
    address public firstMinionInstance;
    address public lastMinionInstance;

    uint256 public constant MAX_NUMBER_OF_MINIONS = 300_000;

    uint256 public activeMinions;
    uint256 public batchSize;
    uint256 public dedicatedAmount;
    uint256 public timeProduced;

    mapping(address => uint256) private _currentBlock;

    mapping(address => MinionInstance instance) public minions;
    mapping(address => uint256) public blockToUnlock;

    /// @notice Instantiates the contract
    /// @dev It is automatically instantiated by the WorkerVault contract
    /// @param worker The main instance of the WorkerVault contract
    constructor(ITVault worker) {
        _worker = worker;
        batchSize = 15;
    }

    receive() external payable {
        if (msg.value > 0) {
            dedicatedAmount += msg.value;
        }
    }

    fallback() external payable {
        require(msg.data.length == 0);
        if (msg.value > 0) {
            dedicatedAmount += msg.value;
        }
    }

    /// @notice Modifier used to avoid reentrancy attacks
    modifier nonReentrant() {
        require(!_isOperationLocked, "Coordinator: this operation is locked for security reasons");
        _isOperationLocked = true;
        _;
        _isOperationLocked = false;
    }

    /// @notice Modifier to make a function runs only once per block (also avoids reentrancy, but in a different way)
    modifier onlyOncePerBlock() {
        require(block.number != _currentBlock[tx.origin], "Coordinator: you cannot perform this operation again in this block");
        _currentBlock[tx.origin] = block.number;
        _;
    }

    /// @notice Modifier used to allow function calling only by ITVault contract
    modifier onlyWorker() {
        require(msg.sender == address(_worker), "Coordinator: only ITVault contract can perform this operation");
        _;
    }

    /// @notice Registers a Minion in the contract
    /// @dev Add an instance of the Minion contract into the internal linked list of the ITVault contract. It also adjusts information about previous instances registered
    /// @param minion The instance of the recently created Minion contract
    function _addMinionInstance(Minion minion) private {
        if (lastMinionInstance != address(0)) {
            minions[lastMinionInstance].nextInstance = address(minion);
        }
        minions[address(minion)].prevInstance = lastMinionInstance;
        minions[address(minion)].nextInstance = address(0);
        if (firstMinionInstance == address(0)) {
            firstMinionInstance = address(minion);
            if (currentMinionInstance == address(0)) {
                currentMinionInstance = firstMinionInstance;
            }
        }
        lastMinionInstance = address(minion);
    }

    /// @notice Creates one Minion given a dedicated amount provided
    /// @dev Creates an instance of the Minion contract, registers it into the contract, and activates it for TIME token production
    /// @param dedicatedAmountForFee The dedicated amount for creation of the new Minion instance
    /// @return newDedicatedAmountForFee The remaining from dedicated amount after Minion creation
    /// @return success Returns true if the Minion was created correctly
    function _createMinionInstance(uint256 dedicatedAmountForFee) private returns (uint256 newDedicatedAmountForFee, bool success) {
        uint256 fee = ITimeToken(_worker.timeToken()).fee();
        if (fee <= dedicatedAmountForFee && activeMinions < MAX_NUMBER_OF_MINIONS) {
            Minion minionInstance = new Minion(address(this), _worker.timeToken());
            try minionInstance.enableMining{ value: fee }() returns (bool enableSuccess) {
                _addMinionInstance(minionInstance);
                activeMinions++;
                newDedicatedAmountForFee = dedicatedAmountForFee - fee;
                success = enableSuccess;
            } catch { }
        }
    }

    /// @notice Creates several Minions from a given amount of fee dedicated for the task
    /// @dev It iterates over the amount of fee dedicated for Minion activation until this value goes to zero, the number of active Minions reach the maximum level, or it reverts for some cause
    /// @param totalFeeForCreation The native amount dedicated for Minion activation for TIME production
    function _createMinions(uint256 totalFeeForCreation) private {
        require(
            totalFeeForCreation <= address(this).balance, "Coordinator: there is no enough amount for enabling minion activation for TIME production"
        );
        bool success;
        uint256 count;
        do {
            (totalFeeForCreation, success) = _createMinionInstance(totalFeeForCreation);
            count++;
        } while (totalFeeForCreation > 0 && success && count < batchSize);
    }

    /// @notice Performs production of TIME token
    /// @dev It calls the mining() function of TIME token from all active Minions' instances
    /// @return amountTime The amount of TIME tokens produced
    function _work() private returns (uint256 amountTime) {
        if (activeMinions > 0) {
            uint256 timeBalanceBeforeWork = ITimeToken(_worker.timeToken()).balanceOf(address(this));
            uint256 count;
            do {
                Minion(currentMinionInstance).produceTime();
                currentMinionInstance = minions[currentMinionInstance].nextInstance;
                count++;
            } while (currentMinionInstance != address(0) && count < batchSize);
            if (currentMinionInstance == address(0)) {
                currentMinionInstance = firstMinionInstance;
            }
            uint256 timeBalanceAfterWork = ITimeToken(_worker.timeToken()).balanceOf(address(this));
            amountTime = (timeBalanceAfterWork - timeBalanceBeforeWork);
            timeProduced += amountTime;
            ITimeToken(_worker.timeToken()).transfer(address(_worker), amountTime);
        }
    }

    /// @notice Receive specific resources coming from ITVault to create new Minions
    /// @dev It should be called only by the ITVault contract
    /// @return success Informs if the function was called and executed correctly
    function addResourcesForMinionCreation() external payable onlyWorker returns (bool success) {
        if (msg.value > 0) {
            dedicatedAmount += msg.value;
            success = true;
        }
    }

    /// @notice The ITVault contract calls this function to create Minions on demand given some amount of native tokens paid/passed (msg.value parameter)
    /// @dev It performs some additional checks and redirects to the _createMinions() function
    /// @param addressToSendRebate The address that should receive the remaining value after Minions are created
    /// @return numberOfMinionsCreated The number of active Minions created for TIME production
    function createMinions(address addressToSendRebate) external payable onlyWorker returns (uint256 numberOfMinionsCreated) {
        require(msg.value > 0, "Coordinator: please send some native tokens to create minions");
        numberOfMinionsCreated = activeMinions;
        _createMinions(msg.value);
        numberOfMinionsCreated = activeMinions - numberOfMinionsCreated;
        if (numberOfMinionsCreated == 0) {
            revert("Coordinator: the amount sent is not enough to create and activate new minions for TIME production");
        }
        if (address(this).balance > dedicatedAmount) {
            payable(addressToSendRebate).transfer(address(this).balance - dedicatedAmount);
        }
    }

    /// @notice Create Minions on demand given the dedicated amount inside the contract
    /// @dev Its behaviour is similar as the createMinions() function with some differences
    /// @return numberOfMinionsCreated The number of active Minions created for TIME production
    function createMinionsForFree() external nonReentrant onlyOncePerBlock returns (uint256 numberOfMinionsCreated) {
        if (dedicatedAmount > 0 && dedicatedAmount <= address(this).balance) {
            numberOfMinionsCreated = activeMinions;
            _createMinions(dedicatedAmount);
            numberOfMinionsCreated = activeMinions - numberOfMinionsCreated;
            dedicatedAmount = address(this).balance;
        }
    }

    /// @notice Change the batch size value (maximum number of minions to be created in one transaction)
    /// @dev It can only be called by ITVault contract, by delegation
    /// @param newBatchSize The new value of the batch size
    function updateBatchSize(uint256 newBatchSize) external onlyWorker {
        batchSize = newBatchSize;
    }
    
    /// @notice Call the Coordinator contract to produce TIME tokens
    /// @dev Can be called only by the ITVault contract
    function work() external onlyWorker returns (uint256) {
        return _work();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ITimeToken } from "./ITimeToken.sol";

/// @title Minion contract
/// @author Einar Cesar - TIME Token Finance - https://timetoken.finance
/// @notice Has the ability to produce TIME tokens for any contract which extends its behavior
/// @dev It should have being enabled to produce TIME before or it will not work as desired. Sometimes, the coordinator address is the contract itself
contract Minion {
    ITimeToken internal immutable _timeToken;
    address internal _coordinator;

    constructor(address coordinatorAddress, ITimeToken timeToken) {
        _coordinator = coordinatorAddress;
        _timeToken = timeToken;
    }

    /// @notice Produce TIME tokens and transfer them to the registered coordinator, if it has one
    /// @dev If the coordinator is an external contract, it maintains a fraction of the produced TIME as incentive for the protocol (which increases the number of token holders)
    function _produceTime() internal {
        _timeToken.mining();
        if (_coordinator != address(this)) {
            uint256 amountToTransfer = (_timeToken.balanceOf(address(this)) * 9_999) / 10_000;
            if (amountToTransfer > 0) {
                _timeToken.transfer(_coordinator, amountToTransfer);
            }
        }
    }

    /// @notice Enables the contract to produce TIME tokens
    /// @dev It should be called right after the creation of the contract
    /// @return success Informs if the operation was carried correctly
    function enableMining() external payable returns (bool success) {
        require(msg.value > 0);
        try _timeToken.enableMining{ value: msg.value }() {
            success = true;
        } catch { }
        return success;
    }

    /// @notice External call for the _produceTime() function
    /// @dev Sometimes, when the Minion contract is inherited from another contract, it can calls the private function. Otherwise, the external function should exist in order to produce TIME for the contract
    function produceTime() external {
        _produceTime();
    }

    /// @notice Alters the coordinator address
    /// @dev Depending on the strategy, a new coordinator may be necessary for the Minion... Only the old coordinator must be responsible to designate the new one
    /// @param newCoordinator The new coordinator address
    function updateCoordinator(address newCoordinator) external {
        require(msg.sender == _coordinator, "Minion: only coordinator can call this function");
        _coordinator = newCoordinator;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ITimeToken } from "./ITimeToken.sol";

interface ITVault {
    function timeToken() external view returns (ITimeToken);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITimeToken {
    function DEVELOPER_ADDRESS() external view returns (address);
    function BASE_FEE() external view returns (uint256);
    function COMISSION_RATE() external view returns (uint256);
    function SHARE_RATE() external view returns (uint256);
    function TIME_BASE_LIQUIDITY() external view returns (uint256);
    function TIME_BASE_FEE() external view returns (uint256);
    function TOLERANCE() external view returns (uint256);
    function dividendPerToken() external view returns (uint256);
    function firstBlock() external view returns (uint256);
    function isMiningAllowed(address account) external view returns (bool);
    function liquidityFactorNative() external view returns (uint256);
    function liquidityFactorTime() external view returns (uint256);
    function numberOfHolders() external view returns (uint256);
    function numberOfMiners() external view returns (uint256);
    function sharedBalance() external view returns (uint256);
    function poolBalance() external view returns (uint256);
    function totalMinted() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
    function averageMiningRate() external view returns (uint256);
    function donateEth() external payable;
    function enableMining() external payable;
    function enableMiningWithTimeToken() external;
    function fee() external view returns (uint256);
    function feeInTime() external view returns (uint256);
    function mining() external;
    function saveTime() external payable returns (bool success);
    function spendTime(uint256 timeAmount) external returns (bool success);
    function swapPriceNative(uint256 amountNative) external view returns (uint256);
    function swapPriceTimeInverse(uint256 amountTime) external view returns (uint256);
    function accountShareBalance(address account) external view returns (uint256);
    function withdrawableShareBalance(address account) external view returns (uint256);
    function withdrawShare() external;
    receive() external payable;
}