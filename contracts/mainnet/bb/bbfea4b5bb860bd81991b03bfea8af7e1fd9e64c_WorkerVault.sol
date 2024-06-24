// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IEmployer } from "./IEmployer.sol";
import { InvestmentCoordinator } from "./InvestmentCoordinator.sol";
import { ITimeIsUp } from "./ITimeIsUp.sol";
import { ITimeToken } from "./ITimeToken.sol";
import { IWorker } from "./IWorker.sol";
import { MinionCoordinator } from "./MinionCoordinator.sol";

/// @title WorkerVault contract - It follows the ERC-4626 standard
/// @author Einar Cesar - TIME Token Finance - https://timetoken.finance
/// @notice Main contract for the Worker vault which receives TUP tokens in order to produce TIME from Minion contracts
/// @dev It receives TUP tokens and mints vWORK tokens for the depositants. It allows its holders to earn from other vaults and also to produce TIME used as collateral for TUP (only)
contract WorkerVault is ERC4626, Ownable, IWorker {
    using Math for uint256;

    bool private _isOperationLocked;

    bool public isEmergencyWithdrawEnabled;

    InvestmentCoordinator public investmentCoordinator;
    ITimeToken public timeToken;
    MinionCoordinator public minionCoordinator;

    address public constant DONATION_ADDRESS = 0xbF616B8b8400373d53EC25bB21E2040adB9F927b;

    uint256 public constant DONATION_FEE = 25;
    uint256 public constant CALLER_FEE = 50;
    uint256 public constant FACTOR = 10 ** 18;
    uint256 public constant INVESTMENT_FEE = 50;
    uint256 public constant MAX_PERCENTAGE_ALLOCATION_OF_TIME = 4_900;
    uint256 public constant MINION_CREATION_FEE = 75;

    uint256 private _callerComission;
    uint256 private _donations;
    uint256 private _minionCreation;

    uint256 public baseTimeFrame;
    uint256 public earnedAmount;

    mapping(address => uint256) private _currentBlock;
    mapping(address => uint256) private _lastCalculatedTimeToLock;

    mapping(address => uint256) public availableTimeAsCaller;
    mapping(address => uint256) public blockToUnlock;
    mapping(address => uint256) public consumedShares;

    // Deposit can not be zero
    error DepositEqualsToZero();
    // This operation is not allowed in this context
    error NotAllowed(string message);
    // Contract does not have enough balance to perform the called operation
    error NotHaveEnoughBalance(uint256 amountAsked, uint256 amountAvailable);
    // Contract does not have enough TIME tokens to perform the called operation
    error NotHaveEnoughTime(uint256 timeAsked, uint256 balanceInTime);
    // No TUP tokens were minted in this operation. The transaction will be reverted
    error NoTupMinted();
    // This operation is locked for security reasons
    error OperationLocked(address sender, uint256 blockNumber);
    // The informed native amount is less than the value of TIME tokens in terms of native currency
    error TimeValueConsumedGreaterThanNative(uint256 timeValue, uint256 native);
    // The withdraw is current locked
    error WithdrawLocked(uint256 currentBlock, uint256 blockToWithdraw);

    // POST-CONDITIONS:
    // IMPORTANT (at deployment):
    //      * deposit a minimum amount of TUP in the contract to avoid frontrunning "donation" attack
    //      * "burn" the share of the minimum amount deposited - send to a dead address
    constructor(address _asset, address _timeTokenAddress, address _employerAddress, address _owner)
        ERC20("Worker Vault", "vWORK")
        ERC4626(ERC20(_asset))
        Ownable(_owner)
    {
        timeToken = ITimeToken(payable(_timeTokenAddress));
        IEmployer employer = IEmployer(payable(_employerAddress));
        minionCoordinator = new MinionCoordinator(this);
        baseTimeFrame = employer.ONE_YEAR().mulDiv(1, employer.D().mulDiv(365, 1));
        investmentCoordinator = new InvestmentCoordinator(address(this), _owner);
    }

    receive() external payable { }

    fallback() external payable {
        require(msg.data.length == 0);
    }

    /// @notice Modifier used to avoid reentrancy attacks
    modifier nonReentrant() {
        if (_isOperationLocked) {
            revert OperationLocked(_msgSender(), block.number);
        }
        _isOperationLocked = true;
        _;
        _isOperationLocked = false;
    }

    /// @notice Modifier to make a function runs only once per block (also avoids reentrancy, but in a different way)
    modifier onlyOncePerBlock() {
        if (block.number == _currentBlock[tx.origin]) {
            revert OperationLocked(tx.origin, block.number);
        }
        _currentBlock[tx.origin] = block.number;
        _;
    }

    /// @notice Transfer some amount of TIME to be staked
    /// @dev Transfer TIME to InvestmentCoordinator and then to vaults which run on TIME
    /// @param amountTime The amount of TIME passed
    function _addTimeToInvest(uint256 amountTime) private {
        if (amountTime > 0) {
            try timeToken.transfer(address(investmentCoordinator), amountTime) {
                try investmentCoordinator.depositAssetOnVault(address(timeToken)) { } catch { }
            } catch { }
        }
    }

    /// @notice Dedicate some TUP tokens for investments which should add value to the whole platform and will be distributed to users
    /// @dev Transfer TUP to InvestmentCoordinator and then to vaults which run on TUP
    /// @param amountTup The amount of TUP tokens to be transferred to InvestmentCoordinator
    function _addTupToInvest(uint256 amountTup) private {
        if (amountTup > 0) {
            try ITimeIsUp(asset()).transfer(address(investmentCoordinator), amountTup) {
                try investmentCoordinator.depositAssetOnVault(asset()) { } catch { }
            } catch { }
        }
    }

    /// @notice Defines for how long the TUP token of the user should be locked
    /// @dev It calculates the number of blocks the TUP tokens of depositant will be locked in this contract. The depositant CAN NOT anticipate this time using TIME tokens
    /// @param depositant Address of the depositant of TUP tokens
    function _adjustBlockToUnlock(address depositant) private {
        uint256 currentCalculatedTimeToLock = calculateTimeToLock(convertToAssets(balanceOf(depositant)));
        uint256 blockAdjustment = block.number + currentCalculatedTimeToLock;
        if (currentCalculatedTimeToLock < _lastCalculatedTimeToLock[depositant]) {
            if (blockToUnlock[depositant] > blockAdjustment || blockToUnlock[depositant] == 0) {
                blockToUnlock[depositant] = blockAdjustment;
            }
        } else {
            blockToUnlock[depositant] = blockAdjustment;
        }
        _lastCalculatedTimeToLock[depositant] = currentCalculatedTimeToLock;
    }

    /// @notice Calculates the correct amount of consumed shares in case of transferring of the vWORK tokens
    /// @dev Consumed shares are always passed to the address which receives the tokens
    /// @param from The address that will send the value
    /// @param to The address that will receive the value
    /// @param value The amount of shares transferred
    function _adjustConsumedShares(address from, address to, uint256 value) private {
        uint256 shareToTransfer = (value > consumedShares[from] || consumedShares[from] == 0) ? consumedShares[from] : value;
        consumedShares[to] += shareToTransfer;
        consumedShares[from] -= shareToTransfer;
    }

    /// @notice Hook called after deposit of TUP tokens in the Worker vault
    /// @dev It calculates the block to unlock, call MinionCoordinator for TIME production, check for earnings and profit, create new Minions automatically, and transfer some TUP to InvestmentCoordinator
    /// @param receiver The address of the receiver of vWORK tokens
    /// @param assets The deposited amount in terms of assets
    /// @param shares The deposited amount in terms of shares
    function _afterDeposit(address receiver, uint256 assets, uint256 shares) private {
        assets = assets == 0 ? convertToAssets(shares) : assets;
        _adjustBlockToUnlock(receiver);
        _earn();
        if (_minionCreation > 0) {
            minionCoordinator.addResourcesForMinionCreation{ value: _minionCreation }();
            _minionCreation = 0;
        }
        if (_donations > 0) {
            payable(DONATION_ADDRESS).call{ value: _donations }("");
            _donations = 0;
        }
        if (minionCoordinator.dedicatedAmount() > 0) {
            try minionCoordinator.createMinionsForFree() { } catch { }
        }
        _callToProduction(false);
        try investmentCoordinator.checkProfitAndWithdraw() { } catch { }
        _addTupToInvest(assets.mulDiv(INVESTMENT_FEE, 10_000));
    }

    /// @notice Hook called after the withdraw of TUP tokens from the Worker vault
    /// @dev It calls MinionCoordinator for TIME production, check for earnings and profit, create new Minions automatically, and transfer some TUP to InvestmentCoordinator
    /// @param assets The withdrawn amount in terms of assets
    /// @param shares The withdrawn amount in terms of shares
    function _afterWithdraw(uint256 assets, uint256 shares) private {
        _earn();
        if (_minionCreation > 0) {
            minionCoordinator.addResourcesForMinionCreation{ value: _minionCreation }();
            _minionCreation = 0;
        }
        if (_donations > 0) {
            payable(DONATION_ADDRESS).call{ value: _donations }("");
            _donations = 0;
        }
        if (minionCoordinator.dedicatedAmount() > 0) {
            try minionCoordinator.createMinionsForFree() { } catch { }
        }
        _callToProduction(false);
        uint256 balanceInShares = balanceOf(_msgSender());
        if (consumedShares[_msgSender()] > balanceInShares) {
            consumedShares[_msgSender()] = balanceInShares;
        }
    }

    /// @notice Hook called before the deposit of TUP tokens into the Worker vault
    /// @dev It just check if the deposit is equals to zero
    /// @param assets The deposited amount in terms of assets
    /// @param shares The deposited amount in terms of shares
    function _beforeDeposit(uint256 assets, uint256 shares) private {
        assets = assets == 0 ? convertToAssets(shares) : assets;
        if (assets == 0) {
            revert DepositEqualsToZero();
        }
    }

    /// @notice Hook called before the withdrawn of TUP tokens from the Worker vault
    /// @dev It just check if the withdrawn is locked or not
    /// @param assets The withdrawn amount in terms of assets
    /// @param shares The withdrawn amount in terms of shares
    function _beforeWithdraw(uint256 assets, uint256 shares) private {
        if (block.number < blockToUnlock[_msgSender()] && !isEmergencyWithdrawEnabled) {
            revert WithdrawLocked(block.number, blockToUnlock[_msgSender()]);
        }
    }

    /// @notice Call the Worker contract to produce TIME and earn resources. It redirects the call to work() function of MinionCoordinator contract
    /// @dev Private function used to avoid onlyOncePerBlock modifier internally
    /// @param chargeFeeForCaller Informs whether the function should charge some fee for the caller
    /// @return production The amount of TIME produced in the call
    function _callToProduction(bool chargeFeeForCaller) private returns (uint256 production) {
        if (chargeFeeForCaller) {
            production = minionCoordinator.work().mulDiv(CALLER_FEE, 10_000);
        } else {
            try minionCoordinator.work() returns (uint256 amount) {
                production = amount;
            } catch {
                production = 0;
            }
        }
        if (production > 0) {
            _addTimeToInvest(production.mulDiv(INVESTMENT_FEE, 10_000));
        }
    }

    /// @notice Performs routine to earn additional resources from InvestmentCoordinator contract, TIME and TUP tokens
    /// @dev It takes advantage of some features of TIME and TUP tokens in order to earn native tokens of the underlying network
    function _earn() private {
        if (timeToken.withdrawableShareBalance(address(this)) > 0) {
            uint256 balanceBefore = address(this).balance;
            try timeToken.withdrawShare() {
                if (address(this).balance > balanceBefore) {
                    _splitEarnings(address(this).balance - balanceBefore);
                }
            } catch { }
        }
        uint256 tupDividends = ITimeIsUp(asset()).accountShareBalance(address(this));
        _addTupToInvest(tupDividends);
    }

    /// @notice Returns the factor information about an informed amount of TUP tokens
    /// @dev It calculates the factor information from the amount of TUP and returns to the caller
    /// @param amountTup The amount of TUP tokens used to calculate factor
    /// @return factor The information about TUP total supply over the amount of TUP tokens informed
    function _getFactor(uint256 amountTup) private view returns (uint256) {
        return ITimeIsUp(asset()).totalSupply().mulDiv(10, amountTup + 1);
    }

    /// @notice Performs TUP token mint for a minter address given the amount of native and TIME tokens informed
    /// @dev Public and external functions can point to this private function since it can be reused for different purposes
    /// @param minter The address that will receive minted TUP tokens
    /// @param amountNative The amount of native tokens to be used in order to mint TUP tokens
    /// @param amountTime The amount of TIME tokens to be used in order to mint TUP tokens
    /// @param reinvestTup Checks whether the minted TUP will be reinvested in the contract
    function _mintTup(address minter, uint256 amountNative, uint256 amountTime, bool reinvestTup) private {
        if (ITimeIsUp(asset()).queryNativeFromTimeAmount(amountTime) > amountNative) {
            revert TimeValueConsumedGreaterThanNative(ITimeIsUp(asset()).queryNativeFromTimeAmount(amountTime), amountNative);
        }
        if (amountTime > timeToken.balanceOf(address(this))) {
            revert NotHaveEnoughTime(amountTime, timeToken.balanceOf(address(this)));
        }
        if (amountNative > address(this).balance) {
            revert NotHaveEnoughBalance(amountNative, address(this).balance);
        }
        timeToken.approve(asset(), amountTime);
        uint256 tupBalanceBefore = ITimeIsUp(asset()).balanceOf(address(this)) - ITimeIsUp(asset()).accountShareBalance(address(this));
        ITimeIsUp(asset()).mint{ value: amountNative }(amountTime);
        uint256 tupBalanceAfter = ITimeIsUp(asset()).balanceOf(address(this)) - ITimeIsUp(asset()).accountShareBalance(address(this));
        uint256 mintedTup = tupBalanceAfter - tupBalanceBefore;
        if (mintedTup == 0) {
            revert NoTupMinted();
        }
        uint256 shares = convertToShares(mintedTup);
        if (balanceOf(minter) > 0 && queryAvailableTimeForDepositant(minter) > 0) {
            consumedShares[minter] += shares;
        }
        if (reinvestTup) {
            _mint(minter, shares);
            _adjustBlockToUnlock(minter);
            emit Deposit(minter, minter, mintedTup, shares);
        } else {
            if (minter != address(this)) {
                ITimeIsUp(asset()).transfer(minter, mintedTup);
            }
        }
    }

    /// @notice It returns the remaining balance in terms of native tokens
    /// @dev It is called to avoid having unused balance in the contract
    /// @return remainingBalance The amount remaining after all comissions
    function _remainingBalance() private view returns (uint256) {
        uint256 total = earnedAmount + _callerComission + _donations + _minionCreation;
        if (address(this).balance > total) {
            return address(this).balance - total;
        } else {
            return 0;
        }
    }

    /// @notice Hook called during a transfer
    /// @dev It recalculates blocks for unlocking of TUP tokens together with the amount of consumed shares 
    /// @param from The address that will send the value
    /// @param to The address that will receive the value
    /// @param value The amount of shares transferred
    function _update(address from, address to, uint256 value) internal override {
        super._update(from, to, value);
        _adjustBlockToUnlock(from);
        _adjustBlockToUnlock(to);
        _adjustConsumedShares(from, to, value);
        if (balanceOf(from) == 0) {
            blockToUnlock[from] = 0;
            _lastCalculatedTimeToLock[from] = 0;
        }
        if (balanceOf(to) == 0) {
            blockToUnlock[to] = 0;
            _lastCalculatedTimeToLock[to] = 0;
        }
    }

    /// @notice Splits the amount earned from this contract into comissions
    /// @param earned The amount earned from this contract at the moment
    function _splitEarnings(uint256 earned) private returns (uint256) {
        uint256 currentCallerComission = earned.mulDiv(CALLER_FEE, 10_000);
        uint256 currentDonation = earned.mulDiv(DONATION_FEE, 10_000);
        uint256 currentMinionCreationFee = earned.mulDiv(MINION_CREATION_FEE, 10_000);
        _donations += currentDonation;
        _minionCreation += currentMinionCreationFee;
        _callerComission += currentCallerComission;
        earned -= (currentDonation + currentMinionCreationFee + currentCallerComission);
        earnedAmount += earned;
        return earned;
    }

    /// @notice Calculates the amount of blocks needed to unlock TUP tokens of the depositants
    /// @dev It must consider the initial base timeframe, which can be altered by calling the updateBaseTimeFrame() function (admin only)
    /// @param amountTup The amount of TUP tokens deposited
    function calculateTimeToLock(uint256 amountTup) public view returns (uint256) {
        return _getFactor(amountTup).mulDiv(baseTimeFrame, 10);
    }

    /// @notice Externally calls the Worker contract and redirects this call to private function _callToProduction(bool chargeFeeForCaller) in order to produce TIME and earn resources
    /// @dev Anyone can call this function and receive part of the produced TIME (available in the contract only for TUP mint) and resources earned. _callerComission receives zero before transferring all the comission value
    /// @param callerAddress The address of the receiver of comission. It is used instead of msg.sender to avoid some types of MEV front running. If address zero is informed, all resources are sent to DEVELOPER_ADDRESS
    function callToProduction(address callerAddress) external nonReentrant onlyOncePerBlock {
        callerAddress = callerAddress == address(0) ? timeToken.DEVELOPER_ADDRESS() : callerAddress;
        availableTimeAsCaller[callerAddress] += _callToProduction(true);
        _earn();
        if (_callerComission > 0) {
            _mintTup(callerAddress, _callerComission, 0, false);
            _callerComission = 0;
        }
    }

    /// @notice Externally calls the Worker contract to create Minions on demand given some amount of native tokens paid/passed (msg.value parameter)
    /// @dev It performs some additional checks and redirects to the _createMinions() function
    /// @return numberOfMinionsCreated The number of active Minions created for TIME production
    function createMinions() external payable nonReentrant onlyOncePerBlock returns (uint256) {
        return minionCoordinator.createMinions{ value: msg.value }(_msgSender());
    }

    /// @notice Overrided deposit function from the parent ERC4626 contract
    /// @dev It just includes the hooks called before and after the whole operation
    /// @param assets The deposited amount in terms of assets
    /// @return shares The deposited amount in terms of shares (confirmed after deposit)
    function deposit(uint256 assets, address receiver) public override nonReentrant onlyOncePerBlock returns (uint256 shares) {
        _beforeDeposit(assets, shares);
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }
        shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        _afterDeposit(receiver, assets, shares);
    }

    /// @notice Disables all emergency withdrawals (admin only)
    /// @dev Adjusts the flag to disable emergency withdrawals
    function disableEmergencyWithdraw() external onlyOwner {
        isEmergencyWithdrawEnabled = false;
    }

    /// @notice Enables all emergency withdrawals (admin only)
    /// @dev Adjusts the flag to allow emergency withdrawals
    function enableEmergencyWithdraw() external onlyOwner {
        isEmergencyWithdrawEnabled = true;
    }

    /// @notice Call the Worker contract to earn resources, pay a given comission to the caller and reinvest comission in the contract
    /// @dev Call Minions for TIME production and this contract to earn resources from TIME and TUP tokens. It reinvests the earned comission with no cost for the caller
    function investWithNoCapital() external nonReentrant onlyOncePerBlock {
        availableTimeAsCaller[_msgSender()] += _callToProduction(true);
        _earn();
        if (_callerComission > 0) {
            uint256 amountTimeNeeded = queryAvailableTimeForTupMint(_callerComission);
            uint256 amountNativeNeeded = ITimeIsUp(asset()).queryNativeFromTimeAmount(availableTimeAsCaller[_msgSender()]);
            if (_callerComission >= amountNativeNeeded) {
                // mint and reinvest TUP with _callerComission and availableTimeAsCaller[_msgSender()] - nothing remains
                _mintTup(_msgSender(), _callerComission, availableTimeAsCaller[_msgSender()], true);
                _callerComission = 0;
                availableTimeAsCaller[_msgSender()] = 0;
            } else if (availableTimeAsCaller[_msgSender()] >= amountTimeNeeded) {
                // mint and reinvest TUP with _callerComission and amountTimeNeeded - it remains some amount of availableTimeAsCaller[_msgSender()]
                availableTimeAsCaller[_msgSender()] -= amountTimeNeeded;
                _mintTup(_msgSender(), _callerComission, amountTimeNeeded, true);
                _callerComission = 0;
            }
        }
    }

    /// @notice Overrided mint function from the parent ERC4626 contract
    /// @dev It just includes the hooks called before and after the whole operation
    /// @param shares The minted amount in terms of shares
    /// @return assets The minted amount in terms of assets (confirmed after deposit)
    function mint(uint256 shares, address receiver) public override nonReentrant onlyOncePerBlock returns (uint256 assets) {
        _beforeDeposit(assets, shares);
        uint256 maxShares = maxMint(receiver);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
        }
        assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);
        _afterDeposit(receiver, assets, shares);
    }

    /// @notice Performs TUP minting as depositant, using the TIME produced from Minions as part of collateral needed
    /// @dev It must use the available TIME from depositant to mint TUP according to the amount of native tokens passed into this function
    /// @param reinvestTup Checks whether the minted TUP will be reinvested in the contract
    function mintTupAsDepositant(bool reinvestTup) external payable nonReentrant onlyOncePerBlock {
        if (msg.value == 0) {
            revert DepositEqualsToZero();
        }
        if (convertToAssets(balanceOf(_msgSender())) == 0) {
            revert NotAllowed("Worker: please refer the depositant should have some deposited TUP tokens in advance");
        }
        uint256 amountNative = _splitEarnings(msg.value);
        uint256 amountTimeAvailable = queryAvailableTimeForDepositant(_msgSender());
        uint256 amountTimeNeeded = queryAvailableTimeForTupMint(amountNative);
        if (amountTimeAvailable < amountTimeNeeded) {
            amountTimeNeeded = amountTimeAvailable;
        }
        if (availableTimeAsCaller[_msgSender()] < amountTimeNeeded) {
            availableTimeAsCaller[_msgSender()] = 0;
        } else {
            availableTimeAsCaller[_msgSender()] -= amountTimeNeeded;
        }
        _mintTup(_msgSender(), amountNative, amountTimeNeeded, reinvestTup);
        earnedAmount -= amountNative;
        if (_remainingBalance() > 0) {
            _mintTup(address(this), _remainingBalance(), 0, false);
            earnedAmount = 0;
        }
    }

    /// @notice Performs TUP minting as a third party involved
    /// @dev It should calculate the correct amount to mint before internal calls
    /// @param minter The address that should receive TUP tokens minted
    /// @param reinvestTup Checks whether the minted TUP will be reinvested in the contract
    function mintTupAsThirdParty(address minter, bool reinvestTup) external payable nonReentrant onlyOncePerBlock {
        if (msg.value == 0) {
            revert DepositEqualsToZero();
        }
        uint256 amountNativeForTimeAllocation = msg.value.mulDiv(MAX_PERCENTAGE_ALLOCATION_OF_TIME, 10_000);
        uint256 amountTime = queryAvailableTimeForTupMint(amountNativeForTimeAllocation);
        uint256 amountNative = _splitEarnings(msg.value - amountNativeForTimeAllocation);
        if (amountTime > timeToken.balanceOf(address(this))) {
            amountTime = timeToken.balanceOf(address(this));
        }
        _mintTup(minter, amountNative, amountTime, reinvestTup);
        earnedAmount -= amountNative;
        if (availableTimeAsCaller[minter] > 0) {
            if (availableTimeAsCaller[minter] < amountTime) {
                availableTimeAsCaller[minter] = 0;
            } else {
                availableTimeAsCaller[minter] -= amountTime;
            }
        }
        if (_remainingBalance() > 0) {
            _mintTup(address(this), _remainingBalance(), 0, false);
            earnedAmount = 0;
        }
    }

    /// @notice Query the amount of TIME available for a depositant address
    /// @dev It should reflect the amount of TIME a TUP depositant has after TIME being producted
    /// @param depositant The address of an user who has deposited and locked TUP in the contract or have called the contract to produce TIME before
    /// @return amountTimeAvailable Amount of TIME available for depositant
    function queryAvailableTimeForDepositant(address depositant) public view returns (uint256) {
        uint256 balanceInShares = balanceOf(depositant);
        if (balanceInShares <= consumedShares[depositant]) {
            return availableTimeAsCaller[depositant];
        } else {
            return (timeToken.balanceOf(address(this)).mulDiv(convertToAssets(balanceInShares - consumedShares[depositant]), totalAssets() + 1)).mulDiv(
                10_000 - (CALLER_FEE + INVESTMENT_FEE), 10_000
            ) + availableTimeAsCaller[depositant];
        }
    }

    /// @notice Query the amount of TIME available to mint new TUP tokens given some amount of native tokens
    /// @dev It must consider the current price of TIME tokens
    /// @param amountNative The amount of native tokens an user wants to spend
    /// @return amountTimeAvailable The available amount of TIME tokens to be used
    function queryAvailableTimeForTupMint(uint256 amountNative) public view returns (uint256) {
        return amountNative.mulDiv(timeToken.swapPriceNative(amountNative), FACTOR);
    }

    /// @notice Queries the contract for the estimated amount needed to activate new Minions given an expected number of them
    /// @dev It should query the TIME token contract for the estimated fees to cover new activations
    /// @param numberOfMinions The number of new Minions an user wants to query
    /// @return amountNative The amount neeed to cover expenses, in terms of native tokens
    function queryFeeAmountToActivateMinions(uint256 numberOfMinions) public view returns (uint256) {
        return timeToken.fee().mulDiv(numberOfMinions, 1);
    }

    /// @notice Queries the amount of a given asset invested in the InvestmentCoordinator contract
    /// @dev The InvestmentCoordinator can invest in several assets (TUP and TIME for instance). So, this function allows anyone to query for the invested amount
    /// @param _asset The address of asset's contract
    /// @return amountInvested The amount of assets invested
    function queryInvestedAmountForAsset(address _asset) external view returns (uint256) {
        return investmentCoordinator.queryTotalInvestedAmountForAsset(_asset);
    }

    /// @notice Queries the minimum amount need to mint TUP tokens given the amount of ALL TIME tokens in the contract
    function queryMinNativeAmountToMintTup() public view returns (uint256) {
        return ITimeIsUp(asset()).queryNativeFromTimeAmount(timeToken.balanceOf(address(this)));
    }

    /// @notice Returns the estimated number of Minions should be created given an amount of native tokens informed
    /// @param amount The amount of native tokens that should be considered to create new Minions
    /// @return estimatedNumberOfMinions The estimated number of Minions
    function queryNumberOfMinionsToActivateFromAmount(uint256 amount) public view returns (uint256) {
        return amount.mulDiv(1, timeToken.fee() + 1);
    }

    /// @notice Overrided redeem function from the parent ERC4626 contract
    /// @dev It just includes the hooks called before and after the whole operation
    /// @param shares The redeemed amount in terms of shares
    /// @param receiver The address that will receive the redeemed assets
    /// @param owner The address owner of the vWORK tokens
    /// @return assets The redeemed amount in terms of assets (confirmed after withdrawn)
    function redeem(uint256 shares, address receiver, address owner) public override nonReentrant onlyOncePerBlock returns (uint256 assets) {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }
        assets = previewRedeem(shares);
        _beforeWithdraw(assets, shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);
        _afterWithdraw(assets, shares);
    }

    /// @notice Change the batch size value (maximum number of minions to be created or called in one transaction) of MinionCoordinator
    /// @dev It delegates the change to the contract, once the MinionCoordinator contract does not have admin functions
    /// @param newBatchSize The new value of the batch size
    function updateBatchSize(uint256 newBatchSize) external onlyOwner {
        minionCoordinator.updateBatchSize(newBatchSize);
    }

    /// @notice Adjusts the base time frame adopted to calculate time lock from deposits
    /// @dev Accessible only by admin/owner
    /// @param newBaseTimeFrame The new value that should be passed
    function updateBaseTimeFrame(uint256 newBaseTimeFrame) external onlyOwner {
        baseTimeFrame = newBaseTimeFrame;
    }

    /// @notice Overrided withdraw function from the parent ERC4626 contract
    /// @dev It just includes the hooks called before and after the whole operation
    /// @param assets The withdraw amount in terms of assets
    /// @param receiver The address that will receive the assets withdrawn
    /// @param owner The address owner of the vWORK tokens
    /// @return shares The withdraw amount in terms of shares (confirmed after withdrawn)
    function withdraw(uint256 assets, address receiver, address owner) public override nonReentrant onlyOncePerBlock returns (uint256 shares) {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }
        shares = previewWithdraw(assets);
        _beforeWithdraw(assets, shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);
        _afterWithdraw(assets, shares);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.20;

import {IERC20, IERC20Metadata, ERC20} from "../ERC20.sol";
import {SafeERC20} from "../utils/SafeERC20.sol";
import {IERC4626} from "../../../interfaces/IERC4626.sol";
import {Math} from "../../../utils/math/Math.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * [CAUTION]
 * ====
 * In empty (or nearly empty) ERC-4626 vaults, deposits are at high risk of being stolen through frontrunning
 * with a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
 * attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
 * deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
 * similarly be affected by slippage. Users can protect against this attack as well as unexpected slippage in general by
 * verifying the amount received is as expected, using a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * Since v4.9, this implementation uses virtual assets and shares to mitigate that risk. The `_decimalsOffset()`
 * corresponds to an offset in the decimal representation between the underlying asset's decimals and the vault
 * decimals. This offset also determines the rate of virtual shares to virtual assets in the vault, which itself
 * determines the initial exchange rate. While not fully preventing the attack, analysis shows that the default offset
 * (0) makes it non-profitable, as a result of the value being captured by the virtual shares (out of the attacker's
 * donation) matching the attacker's expected gains. With a larger offset, the attack becomes orders of magnitude more
 * expensive than it is profitable. More details about the underlying math can be found
 * xref:erc4626.adoc#inflation-attack[here].
 *
 * The drawback of this approach is that the virtual shares do capture (a very small) part of the value being accrued
 * to the vault. Also, if the vault experiences losses, the users try to exit the vault, the virtual shares and assets
 * will cause the first user to exit to experience reduced losses in detriment to the last users that will experience
 * bigger losses. Developers willing to revert back to the pre-v4.9 behavior just need to override the
 * `_convertToShares` and `_convertToAssets` functions.
 *
 * To learn more, check out our xref:ROOT:erc4626.adoc[ERC-4626 guide].
 * ====
 */
abstract contract ERC4626 is ERC20, IERC4626 {
    using Math for uint256;

    IERC20 private immutable _asset;
    uint8 private immutable _underlyingDecimals;

    /**
     * @dev Attempted to deposit more assets than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxDeposit(address receiver, uint256 assets, uint256 max);

    /**
     * @dev Attempted to mint more shares than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxMint(address receiver, uint256 shares, uint256 max);

    /**
     * @dev Attempted to withdraw more assets than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxWithdraw(address owner, uint256 assets, uint256 max);

    /**
     * @dev Attempted to redeem more shares than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxRedeem(address owner, uint256 shares, uint256 max);

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(IERC20 asset_) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _underlyingDecimals = success ? assetDecimals : 18;
        _asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeCall(IERC20Metadata.decimals, ())
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     *
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _underlyingDecimals + _decimalsOffset();
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Ceil);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Ceil);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual returns (uint256) {
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(uint256 shares, address receiver) public virtual returns (uint256) {
        uint256 maxShares = maxMint(receiver);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
        }

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(uint256 assets, address receiver, address owner) public virtual returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256) {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256) {
        return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error ERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `requestedDecrease`.
     *
     * NOTE: Although this function is designed to avoid double spending with {approval},
     * it can still be frontrunned, preventing any attempt of allowance reduction.
     */
    function decreaseAllowance(address spender, uint256 requestedDecrease) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < requestedDecrease) {
            revert ERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
        }
        unchecked {
            _approve(owner, spender, currentAllowance - requestedDecrease);
        }

        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from` (or `to`) is
     * the zero address. All customizations to transfers, mints, and burns should be done by overriding this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, by transferring it to address(0).
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal virtual {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Alternative version of {_approve} with an optional flag that can enable or disable the Approval event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to true
     * using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IEmployer {
    function DEVELOPER_ADDRESS() external returns (address);
    function TIME_TOKEN_ADDRESS() external returns (address);
    function D() external returns (uint256);
    function FACTOR() external returns (uint256);
    function FIRST_BLOCK() external returns (uint256);
    function ONE_YEAR() external returns (uint256);
    function availableNative() external returns (uint256);
    function currentDepositedNative() external returns (uint256);
    function totalAnticipatedTime() external returns (uint256);
    function totalBurnedTime() external returns (uint256);
    function totalDepositedNative() external returns (uint256);
    function totalDepositedTime() external returns (uint256);
    function totalEarnedNative() external returns (uint256);
    function totalTimeSaved() external returns (uint256);
    function anticipationEnabled(address account) external returns (bool);
    function deposited(address account) external returns (uint256);
    function earned(address account) external view returns (uint256);
    function lastBlock(address account) external returns (uint256);
    function remainingTime(address account) external returns (uint256);
    function anticipate(uint256 timeAmount) external payable;
    function anticipationFee() external view returns (uint256);
    function compound(uint256 timeAmount, bool mustAnticipateTime) external;
    function deposit(uint256 timeAmount, bool mustAnticipateTime) external payable;
    function earn() external;
    function enableAnticipation() external payable;
    function getCurrentROI() external view returns (uint256);
    function getCurrentROIPerBlock() external view returns (uint256);
    function getROI() external view returns (uint256);
    function getROIPerBlock() external view returns (uint256);
    function queryAnticipatedEarnings(address depositant, uint256 anticipatedTime) external view returns (uint256);
    function queryEarnings(address depositant) external view returns (uint256);
    function withdrawEarnings() external;
    function withdrawDeposit() external;
    function withdrawDepositEmergency() external;
    receive() external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IWorker } from "./IWorker.sol";

/// @title InvestmentCoordinator contract
/// @author Einar Cesar - TIME Token Finance - https://timetoken.finance
/// @notice Coordinates the allocation of resources coming from the Worker vault and returns the profit in terms of TUP and TIME tokens
/// @dev It is attached and managed by the WorkerVault
contract InvestmentCoordinator is Ownable {
    using Math for uint256;

    error AddressNotAllowed(address sender);

    IWorker public worker;

    ERC4626[] public vaults;

    mapping(address => uint256) private _amountOnVault;
    mapping(address => uint256) private _assetCount;
    mapping(address => uint256) private _assetAmountPerVault;

    /// @notice Instantiates the contract
    /// @dev It is automatically instantiated by the WorkerVault contract
    /// @param _worker The address of the WorkerVault contract main instance
    /// @param _owner The address of the admin
    constructor(address _worker, address _owner) Ownable(_owner) {
        worker = IWorker(payable(_worker));
    }

    /// @notice Modifier used to allow function calling only by IWorker contract
    modifier onlyWorker() {
        _checkWorker();
        _;
    }

    /// @notice Verifies if the sender of a call is the WorkerVault contract
    function _checkWorker() private view {
        if (_msgSender() != address(worker)) {
            revert AddressNotAllowed(_msgSender());
        }
    }

    /// @notice Withdraw all the funds from an informed vault registered
    /// @dev It redeems all shares from the vault passed as parameter
    /// @param vault The instance of the vault contract
    /// @param receiver The address of the receiver of funds
    function _withdrawAllFromVault(ERC4626 vault, address receiver) private {
        try vault.redeem(vault.balanceOf(address(this)), receiver, address(this)) {
            _amountOnVault[address(vault)] = 0;
        } catch { }
    }

    /// @notice Add a new vault onto the InvestmentCoordinator
    /// @dev It pushes the new vault into the vault stack
    /// @param newVault The address of the new vault contract
    function addVault(address newVault) external onlyOwner {
        bool found;
        for (uint256 i = 0; i < numberOfVaults(); i++) {
            if (newVault == address(vaults[i])) {
                found = true;
                break;
            }
        }
        if (!found) {
            vaults.push(ERC4626(newVault));
        }
    }

    /// @notice Verifies if vaults have profit and withdraw assets to the Worker vault
    /// @dev It iterates over the vaults stack, check if each has profit, and then withdraw to the WorkerVault address
    function checkProfitAndWithdraw() external {
        for (uint256 i = 0; i < numberOfVaults(); i++) {
            uint256 updatedAmount = vaults[i].previewRedeem(vaults[i].balanceOf(address(this)));
            if (_amountOnVault[address(vaults[i])] < updatedAmount) {
                vaults[i].withdraw(updatedAmount - _amountOnVault[address(vaults[i])], address(worker), address(this));
            }
        }
    }

    /// @notice Sometimes, the Investor coordinator has most than one vault which operates with the same asset. In this case, this function distributes the asset equally among these vaults
    /// @dev Check which vaults operates in the asset informed and deposit what it has in balance
    /// @param asset The address of asset informed to be deposited
    function depositAssetOnVault(address asset) public onlyWorker {
        uint256 numberOfVaultsFound;
        for (uint256 i = 0; i < numberOfVaults(); i++) {
            if (vaults[i].asset() == asset) {
                numberOfVaultsFound++;
            }
        }
        if (numberOfVaultsFound > 0) {
            IERC20 token = IERC20(asset);
            uint256 shares = token.balanceOf(address(this)) / numberOfVaultsFound;
            for (uint256 i = 0; i < numberOfVaults(); i++) {
                if (vaults[i].asset() == asset) {
                    if (token.allowance(address(this), address(vaults[i])) < shares) {
                        token.approve(address(vaults[i]), shares);
                    }
                    vaults[i].deposit(shares, address(this));
                    _amountOnVault[address(vaults[i])] += shares;
                }
            }
        }
    }

    /// @notice Deposit all assets in all registered vaults
    /// @dev It iterates over all vaults and all assets in order to deposit everything it has as balance
    function depositOnAllVaults() public {
        for (uint256 i = 0; i < numberOfVaults(); i++) {
            _assetCount[vaults[i].asset()]++;
        }
        for (uint256 i = 0; i < numberOfVaults(); i++) {
            if (_assetAmountPerVault[vaults[i].asset()] == 0 && _assetCount[vaults[i].asset()] > 0) {
                uint256 tokenBalance = IERC20(vaults[i].asset()).balanceOf(address(this));
                if (tokenBalance > 0) {
                    _assetAmountPerVault[vaults[i].asset()] = tokenBalance / _assetCount[vaults[i].asset()];
                }
            }
        }
        bool[] memory isDeposited = new bool[](numberOfVaults());
        for (uint256 i = 0; i < numberOfVaults(); i++) {
            if (_assetAmountPerVault[vaults[i].asset()] > 0) {
                if (IERC20(vaults[i].asset()).allowance(address(this), address(vaults[i])) < _assetAmountPerVault[vaults[i].asset()]) {
                    IERC20(vaults[i].asset()).approve(address(vaults[i]), _assetAmountPerVault[vaults[i].asset()]);
                }
                try vaults[i].deposit(_assetAmountPerVault[vaults[i].asset()], address(this)) {
                    _amountOnVault[address(vaults[i])] += _assetAmountPerVault[vaults[i].asset()];
                    isDeposited[i] = true;
                } catch { }
            }
        }
        for (uint256 i = 0; i < numberOfVaults(); i++) {
            _assetCount[vaults[i].asset()] = 0;
            if (_assetAmountPerVault[vaults[i].asset()] > 0 && isDeposited[i]) {
                _assetAmountPerVault[vaults[i].asset()] = 0;
            }
        }
    }

    /// @notice Informs the number of vaults registered in the contract
    /// @dev It just returns the length/size of the vaults stack
    function numberOfVaults() public view returns (uint256) {
        return vaults.length;
    }

    /// @notice Query the total amount invested for a given asset
    /// @dev It just query for the amount registered for the informed asset address
    /// @param asset The address of the asset
    /// @return totalAmount The total amount returned after query
    function queryTotalInvestedAmountForAsset(address asset) external view onlyWorker returns (uint256 totalAmount) {
        for (uint256 i = 0; i < numberOfVaults(); i++) {
            if (vaults[i].asset() == asset) {
                totalAmount += _amountOnVault[address(vaults[i])];
            }
        }
    }

    /// @notice Removes an ERC-4626 vault from the Investment coordinator contract
    /// @dev It pushes part of the stack away when it founds the correct index of the contract
    /// @param vaultToRemove The address of the vault which will be removed
    function removeVault(address vaultToRemove) external onlyOwner {
        bool found;
        for (uint256 i = 0; i < numberOfVaults(); i++) {
            if (vaultToRemove == address(vaults[i])) {
                for (uint256 j = i; j < numberOfVaults() - 1; j++) {
                    vaults[j] = vaults[j + 1];
                }
                _withdrawAllFromVault(vaults[i], address(this));
                found = true;
                break;
            }
        }
        if (found) {
            vaults.pop();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITimeIsUp {
    function FLASH_MINT_FEE() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function accountShareBalance(address account) external view returns (uint256);
    function burn(uint256 amount) external;
    function mint(uint256 timeAmount) external payable;
    function queryAmountExternalLP(uint256 amountNative) external view returns (uint256);
    function queryAmountInternalLP(uint256 amountNative) external view returns (uint256);
    function queryAmountOptimal(uint256 amountNative) external view returns (uint256);
    function queryNativeAmount(uint256 tupAmount) external view returns (uint256);
    function queryNativeFromTimeAmount(uint256 timeAmount) external view returns (uint256);
    function queryPriceNative(uint256 amountNative) external view returns (uint256);
    function queryPriceInverse(uint256 tupAmount) external view returns (uint256);
    function queryRate() external view returns (uint256);
    function queryPublicReward() external view returns (uint256);
    function returnNative() external payable returns (bool);
    function splitSharesWithReward() external;
    function buy() external payable returns (bool success);
    function sell(uint256 tupAmount) external returns (bool success);
    function flashMint(uint256 tupAmountToBorrow, bytes calldata data) external;
    function payFlashMintFee() external payable;
    function poolBalance() external view returns (uint256);
    function toBeShared() external view returns (uint256);
    function receiveProfit() external payable;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ITVault } from "./ITVault.sol";
import { MinionCoordinator } from "./MinionCoordinator.sol";

interface IWorker is ITVault {
    function minionCoordinator() external view returns (MinionCoordinator);
    function DONATION_ADDRESS() external view returns (address);
    function DONATION_FEE() external view returns (uint256);
    function CALLER_FEE() external view returns (uint256);
    function FACTOR() external view returns (uint256);
    function INVESTMENT_FEE() external view returns (uint256);
    function MAX_PERCENTAGE_ALLOCATION_OF_TIME() external view returns (uint256);
    function MINION_CREATION_FEE() external view returns (uint256);
    function baseTimeFrame() external view returns (uint256);
    function earnedAmount() external view returns (uint256);
    function availableTimeAsCaller(address depositant) external view returns (uint256);
    function blockToUnlock(address depositant) external view returns (uint256);
    function calculateTimeToLock(uint256 amountTup) external view returns (uint256);
    function callToProduction(address callerAddress) external;
    function createMinions() external payable returns (uint256);
    function investWithNoCapital() external;
    function mintTupAsDepositant(bool reinvestTup) external payable;
    function mintTupAsThirdParty(address minter, bool reinvestTup) external payable;
    function queryAvailableTimeForDepositant(address depositant) external view returns (uint256);
    function queryAvailableTimeForTupMint(uint256 amountNative) external view returns (uint256);
    function queryFeeAmountToActivateMinions(uint256 numberOfMinions) external view returns (uint256);
    function queryMinNativeAmountToMintTup() external view returns (uint256);
    function queryNumberOfMinionsToActivateFromAmount(uint256 amount) external view returns (uint256);
    function updateBatchSize(uint256 newBatchSize) external;
    function updateBaseTimeFrame(uint256 newBaseTimeFrame) external;
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        if (nonceAfter != nonceBefore + 1) {
            revert SafeERC20FailedOperation(address(token));
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";
import {IERC20Metadata} from "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ITimeToken } from "./ITimeToken.sol";

interface ITVault {
    function timeToken() external view returns (ITimeToken);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}