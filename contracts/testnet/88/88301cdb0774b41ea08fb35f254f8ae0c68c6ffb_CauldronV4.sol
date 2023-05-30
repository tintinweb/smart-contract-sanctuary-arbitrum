// SPDX-License-Identifier: UNLICENSED

// Cauldron

//    (                (   (
//    )\      )    (   )\  )\ )  (
//  (((_)  ( /(   ))\ ((_)(()/(  )(    (    (
//  )\___  )(_)) /((_) _   ((_))(()\   )\   )\ )
// ((/ __|((_)_ (_))( | |  _| |  ((_) ((_) _(_/(
//  | (__ / _` || || || |/ _` | | '_|/ _ \| ' \))
//   \___|\__,_| \_,_||_|\__,_| |_|  \___/|_||_|

pragma solidity >=0.8.0;
import "BoringSolidity/BoringOwnable.sol";
import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/interfaces/IMasterContract.sol";
import "BoringSolidity/libraries/BoringRebase.sol";
import "interfaces/IOracle.sol";
import "interfaces/ISwapperV2.sol";
import "interfaces/IBentoBoxV1.sol";
import "interfaces/IBentoBoxOwner.sol";
import "interfaces/IArvinDegenNFT.sol";
import "interfaces/IMasterChef.sol";

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

/// @title Cauldron
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract CauldronV4 is BoringOwnable, IMasterContract {
    using RebaseLibrary for Rebase;

    event LogExchangeRate(uint256 rate);
    event LogAccrue(uint128 accruedAmount);
    event LogAddCollateral(address indexed from, address indexed to, uint256 share);
    event LogRemoveCollateral(address indexed from, address indexed to, uint256 share);
    event LogBorrow(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogRepay(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogFeeTo(address indexed newFeeTo);
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);
    event LogInterestChange(uint64 oldInterestRate, uint64 newInterestRate);
    event LogChangeBorrowLimit(uint128 newLimit, uint128 perAddressPart);
    event LogChangeBlacklistedCallee(address indexed account, bool blacklisted);
    event LogRepayForAll(uint256 amount, uint128 previousElastic, uint128 newElastic);

    event LogLiquidation(
        address indexed from,
        address indexed user,
        address indexed to,
        uint256 collateralShare,
        uint256 borrowAmount,
        uint256 borrowPart
    );

    // Immutables (for MasterContract and all clones)
    IBentoBoxV1 public immutable bentoBox;
    CauldronV4 public immutable masterContract;
    IERC20 public immutable magicInternetMoney;

    // MasterContract variables
    address public feeTo;
    address public immutable distributeTo;
    IArvinDegenNFT public immutable arvinDegenNFT;

    // Per clone variables
    // Clone init settings
    IERC20 public collateral;
    IOracle public oracle;
    bytes public oracleData;

    struct BorrowCap {
        uint128 total;
        uint128 borrowPartPerAddress;
    }

    BorrowCap public borrowLimit;

    // Total amounts
    uint256 public totalCollateralShare; // Total collateral supplied
    Rebase public totalBorrow; // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers
    uint256 public interestPerPart;

    // User balances
    mapping(address => uint256) public userCollateralShare;
    mapping(address => uint256) public userBorrowPart;
    mapping(address => uint256) public userBorrowInterestDebt;

    // Callee restrictions
    mapping(address => bool) public blacklistedCallees;

    /// @notice Exchange and interest rate tracking.
    /// This is 'cached' here because calls to Oracles can be very expensive.
    uint256 public exchangeRate;

    struct AccrueInfo {
        uint64 lastAccrued;
        uint128 feesEarned;
        uint64 INTEREST_PER_SECOND;
    }

    AccrueInfo public accrueInfo;

    uint64 internal constant ONE_PERCENT_RATE = 317097920;

    /// @notice tracking of last interest update
    uint256 internal lastInterestUpdate;

    // Settings
    uint256 public COLLATERIZATION_RATE;
    uint256 internal constant COLLATERIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)

    uint256 internal constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 public LIQUIDATION_MULTIPLIER;
    uint256 internal constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;

    uint256 public BORROW_OPENING_FEE;
    uint256 internal constant BORROW_OPENING_FEE_PRECISION = 1e5;

    uint256 internal constant DISTRIBUTION_PART = 10;
    uint256 internal constant DISTRIBUTION_PRECISION = 100;

    modifier onlyMasterContractOwner() {
        require(msg.sender == masterContract.owner(), "Caller is not the owner");
        _;
    }

    // /// @notice The constructor is only used for the initial master contract. Subsequent clones are initialised via `init`.
    constructor(IBentoBoxV1 bentoBox_, IERC20 magicInternetMoney_, address distributeTo_, address _arvinDegenNftAddress) {
        bentoBox = bentoBox_;
        magicInternetMoney = magicInternetMoney_;
        masterContract = this;
        distributeTo = distributeTo_;
        arvinDegenNFT = IArvinDegenNFT(_arvinDegenNftAddress);
        blacklistedCallees[address(bentoBox)] = true;
        blacklistedCallees[address(this)] = true;
        blacklistedCallees[distributeTo_] = true;
        blacklistedCallees[BoringOwnable(address(bentoBox)).owner()] = true;
    }

    /// @notice Serves as the constructor for clones, as clones can't have a regular constructor
    /// @dev `data` is abi encoded in the format: (IERC20 collateral, IERC20 asset, IOracle oracle, bytes oracleData)
    function init(bytes calldata data) public payable virtual override {
        require(address(collateral) == address(0), "Cauldron: already initialized");
        (
            collateral,
            oracle,
            oracleData,
            accrueInfo.INTEREST_PER_SECOND,
            LIQUIDATION_MULTIPLIER,
            COLLATERIZATION_RATE,
            BORROW_OPENING_FEE
        ) = abi.decode(data, (IERC20, IOracle, bytes, uint64, uint256, uint256, uint256));
        borrowLimit = BorrowCap(type(uint128).max, type(uint128).max);
        require(address(collateral) != address(0), "Cauldron: bad pair");

        magicInternetMoney.approve(address(bentoBox), type(uint256).max);

        blacklistedCallees[address(bentoBox)] = true;
        blacklistedCallees[address(this)] = true;
        blacklistedCallees[distributeTo] = true;
        blacklistedCallees[BoringOwnable(address(bentoBox)).owner()] = true;

        (, exchangeRate) = oracle.get(oracleData);

        accrue();
    }

    /// @notice Accrues the interest on the borrowed tokens and handles the accumulation of fees.
    function accrue() public {
        AccrueInfo memory _accrueInfo = accrueInfo;
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
        if (elapsedTime == 0) {
            return;
        }
        _accrueInfo.lastAccrued = uint64(block.timestamp);

        Rebase memory _totalBorrow = totalBorrow;
        if (_totalBorrow.base == 0) {
            accrueInfo = _accrueInfo;
            return;
        }

        // Accrue interest
        uint128 extraAmount = uint128((uint256(_totalBorrow.elastic) * _accrueInfo.INTEREST_PER_SECOND * elapsedTime) / 1e18);
        _totalBorrow.elastic = _totalBorrow.elastic + extraAmount;
        interestPerPart += (extraAmount * 1e20) / _totalBorrow.base;
        _accrueInfo.feesEarned = _accrueInfo.feesEarned + extraAmount;
        totalBorrow = _totalBorrow;
        accrueInfo = _accrueInfo;

        emit LogAccrue(extraAmount);
    }

    /// @notice Concrete implementation of `isSolvent`. Includes a third parameter to allow caching `exchangeRate`.
    /// @param _exchangeRate The exchange rate. Used to cache the `exchangeRate` between calls.
    function _isSolvent(address user, uint256 _exchangeRate) internal view returns (bool) {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return true;
        uint256 collateralShare = userCollateralShare[user];
        if (collateralShare == 0) return false;

        Rebase memory _totalBorrow = totalBorrow;

        return
            bentoBox.toAmount(
                collateral,
                ((collateralShare * EXCHANGE_RATE_PRECISION) / COLLATERIZATION_RATE_PRECISION) * COLLATERIZATION_RATE,
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            (borrowPart * _totalBorrow.elastic * _exchangeRate) / _totalBorrow.base;
    }

    /// @dev Checks if the user is solvent in the closed liquidation case at the end of the function body.
    modifier solvent() {
        _;
        (, uint256 _exchangeRate) = updateExchangeRate();
        require(_isSolvent(msg.sender, _exchangeRate), "Cauldron: user insolvent");
    }

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() public returns (bool updated, uint256 rate) {
        (updated, rate) = oracle.get(oracleData);

        if (updated) {
            exchangeRate = rate;
            emit LogExchangeRate(rate);
        } else {
            // Return the old rate if fetching wasn't successful
            rate = exchangeRate;
        }
    }

    /// @dev Helper function to move tokens.
    /// @param token The ERC-20 token.
    /// @param share The amount in shares to add.
    /// @param total Grand total amount to deduct from this contract's balance. Only applicable if `skim` is True.
    /// Only used for accounting checks.
    /// @param skim If True, only does a balance check on this contract.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    function _addTokens(IERC20 token, uint256 share, uint256 total, bool skim) internal {
        if (skim) {
            require(share <= bentoBox.balanceOf(token, address(this)) - total, "Cauldron: Skim too much");
        } else {
            bentoBox.transfer(token, msg.sender, address(this), share);
        }
    }

    function _afterAddCollateral(address user, uint256 collateralShare) internal virtual {}

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.x
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(address to, bool skim, uint256 share) public virtual {
        userCollateralShare[to] = userCollateralShare[to] + share;
        uint256 oldTotalCollateralShare = totalCollateralShare;
        totalCollateralShare = oldTotalCollateralShare + share;
        _addTokens(collateral, share, oldTotalCollateralShare, skim);
        _afterAddCollateral(to, share);
        emit LogAddCollateral(skim ? address(bentoBox) : msg.sender, to, share);
    }

    function _afterRemoveCollateral(address from, address to, uint256 collateralShare) internal virtual {}

    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(address to, uint256 share) internal virtual {
        userCollateralShare[msg.sender] = userCollateralShare[msg.sender] - share;
        totalCollateralShare = totalCollateralShare - share;
        _afterRemoveCollateral(msg.sender, to, share);
        emit LogRemoveCollateral(msg.sender, to, share);
        bentoBox.transfer(collateral, address(this), to, share);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(address to, uint256 share) public solvent {
        // accrue must be called because we check solvency
        accrue();
        _removeCollateral(to, share);
    }

    function _preBorrowAction(address to, uint256 amount, uint256 newBorrowPart, uint256 part) internal virtual {}

    /// @dev Concrete implementation of `borrow`.
    function _borrow(address to, uint256 amount) internal returns (uint256 part, uint256 share) {
        handleRefund(msg.sender);
        uint256 feeAmount = (amount * BORROW_OPENING_FEE) / BORROW_OPENING_FEE_PRECISION; // A flat % fee is charged for any borrow
        (Rebase memory _totalBorrow, uint256 temp) = totalBorrow.add(amount + feeAmount, true);
        part = temp;
        BorrowCap memory cap = borrowLimit;

        require(_totalBorrow.elastic <= cap.total, "Borrow Limit reached");

        accrueInfo.feesEarned = accrueInfo.feesEarned + (uint128(feeAmount));

        uint256 newBorrowPart = userBorrowPart[msg.sender] + (part);
        require(newBorrowPart <= cap.borrowPartPerAddress, "Borrow Limit reached");
        _preBorrowAction(to, amount, newBorrowPart, part);
        userBorrowPart[msg.sender] = newBorrowPart;
        userBorrowInterestDebt[msg.sender] = (newBorrowPart * interestPerPart) / 1e20;

        // As long as there are tokens on this contract you can 'mint'... this enables limiting borrows
        share = bentoBox.toShare(magicInternetMoney, amount, false);
        bentoBox.transfer(magicInternetMoney, address(this), to, share);
        IMasterChef(distributeTo).deposit(msg.sender);
        totalBorrow = _totalBorrow;
        emit LogBorrow(msg.sender, to, amount + feeAmount, part);
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(address to, uint256 amount) public solvent returns (uint256 part, uint256 share) {
        accrue();
        (part, share) = _borrow(to, amount);
    }

    function handleRefund(address user) private {
        uint256 _interestRefund = (((userBorrowPart[user] * interestPerPart) / 1e20 - userBorrowInterestDebt[user]) *
            arvinDegenNFT.getRefundRatio(user)) / 100;
        if (_interestRefund > 0) {
            // uint256 share = totalBorrow.toBase(_interestRefund, false);
            uint256 share = bentoBox.toShare(magicInternetMoney, _interestRefund, false);
            bentoBox.transfer(magicInternetMoney, (address(this)), user, share);
            accrueInfo.feesEarned -= uint128(_interestRefund);
        }
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(address to, bool skim, uint256 part) internal returns (uint256 amount) {
        handleRefund(to);
        userBorrowPart[to] = userBorrowPart[to] - (part);
        IMasterChef(distributeTo).withdraw(to);
        (totalBorrow, amount) = totalBorrow.sub(part, true);
        userBorrowInterestDebt[to] = (userBorrowPart[to] * interestPerPart) / 1e20;
        uint256 share = bentoBox.toShare(magicInternetMoney, amount, true);
        bentoBox.transfer(magicInternetMoney, skim ? address(bentoBox) : msg.sender, address(this), share);
        emit LogRepay(skim ? address(bentoBox) : msg.sender, to, amount, part);
    }

    /// @notice Repays a loan.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(address to, bool skim, uint256 part) public returns (uint256 amount) {
        accrue();
        amount = _repay(to, skim, part);
    }

    // Functions that need accrue to be called
    uint8 internal constant ACTION_REPAY = 2;
    uint8 internal constant ACTION_REMOVE_COLLATERAL = 4;
    uint8 internal constant ACTION_BORROW = 5;
    uint8 internal constant ACTION_GET_REPAY_SHARE = 6;
    uint8 internal constant ACTION_GET_REPAY_PART = 7;
    uint8 internal constant ACTION_ACCRUE = 8;

    // Functions that don't need accrue to be called
    uint8 internal constant ACTION_ADD_COLLATERAL = 10;
    uint8 internal constant ACTION_UPDATE_EXCHANGE_RATE = 11;

    // Function on BentoBox
    uint8 internal constant ACTION_BENTO_DEPOSIT = 20;
    uint8 internal constant ACTION_BENTO_WITHDRAW = 21;
    uint8 internal constant ACTION_BENTO_TRANSFER = 22;
    uint8 internal constant ACTION_BENTO_TRANSFER_MULTIPLE = 23;
    uint8 internal constant ACTION_BENTO_SETAPPROVAL = 24;

    // Any external call (except to BentoBox)
    uint8 internal constant ACTION_CALL = 30;
    uint8 internal constant ACTION_LIQUIDATE = 31;
    uint8 internal constant ACTION_RELEASE_COLLATERAL_FROM_STRATEGY = 33;

    // Custom cook actions
    uint8 internal constant ACTION_CUSTOM_START_INDEX = 100;

    int256 internal constant USE_VALUE1 = -1;
    int256 internal constant USE_VALUE2 = -2;

    /// @dev Helper function for choosing the correct value (`value1` or `value2`) depending on `inNum`.
    function _num(int256 inNum, uint256 value1, uint256 value2) internal pure returns (uint256 outNum) {
        outNum = inNum >= 0 ? uint256(inNum) : (inNum == USE_VALUE1 ? value1 : value2);
    }

    /// @dev Helper function for depositing into `bentoBox`.
    function _bentoDeposit(bytes memory data, uint256 value, uint256 value1, uint256 value2) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        amount = int256(_num(amount, value1, value2)); // Done this way to avoid stack too deep errors
        share = int256(_num(share, value1, value2));
        return bentoBox.deposit{value: value}(token, msg.sender, to, uint256(amount), uint256(share));
    }

    /// @dev Helper function to withdraw from the `bentoBox`.
    function _bentoWithdraw(bytes memory data, uint256 value1, uint256 value2) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        return bentoBox.withdraw(token, msg.sender, to, _num(amount, value1, value2), _num(share, value1, value2));
    }

    /// @dev Helper function to perform a contract call and eventually extracting revert messages on failure.
    /// Calls to `bentoBox` are not allowed for obvious security reasons.
    /// This also means that calls made from this contract shall *not* be trusted.
    function _call(uint256 value, bytes memory data, uint256 value1, uint256 value2) internal returns (bytes memory, uint8) {
        (address callee, bytes memory callData, bool useValue1, bool useValue2, uint8 returnValues) = abi.decode(
            data,
            (address, bytes, bool, bool, uint8)
        );

        if (useValue1 && !useValue2) {
            callData = abi.encodePacked(callData, value1);
        } else if (!useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value2);
        } else if (useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value1, value2);
        }

        require(!blacklistedCallees[callee], "Cauldron: can't call");

        (bool success, bytes memory returnData) = callee.call{value: value}(callData);
        require(success, "Cauldron: call failed");
        return (returnData, returnValues);
    }

    function _additionalCookAction(
        uint8 action,
        uint256 value,
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal virtual returns (bytes memory, uint8) {}

    struct CookStatus {
        bool needsSolvencyCheck;
        bool hasAccrued;
    }

    /// @notice Executes a set of actions and allows composability (contract calls) to other contracts.
    /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
    /// @param values A one-to-one mapped array to `actions`. ETH amounts to send along with the actions.
    /// Only applicable to `ACTION_CALL`, `ACTION_BENTO_DEPOSIT`.
    /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
    /// @return value1 May contain the first positioned return value of the last executed action (if applicable).
    /// @return value2 May contain the second positioned return value of the last executed action which returns 2 values (if applicable).
    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2) {
        CookStatus memory status;
        uint64 previousStrategyTargetPercentage = type(uint64).max;

        for (uint256 i = 0; i < actions.length; i++) {
            uint8 action = actions[i];
            if (!status.hasAccrued && action < 10) {
                accrue();
                status.hasAccrued = true;
            }
            if (action == ACTION_ADD_COLLATERAL) {
                (int256 share, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                addCollateral(to, skim, _num(share, value1, value2));
            } else if (action == ACTION_REPAY) {
                (int256 part, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                _repay(to, skim, _num(part, value1, value2));
            } else if (action == ACTION_REMOVE_COLLATERAL) {
                (int256 share, address to) = abi.decode(datas[i], (int256, address));
                _removeCollateral(to, _num(share, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_BORROW) {
                (int256 amount, address to) = abi.decode(datas[i], (int256, address));
                (value1, value2) = _borrow(to, _num(amount, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_UPDATE_EXCHANGE_RATE) {
                (bool must_update, uint256 minRate, uint256 maxRate) = abi.decode(datas[i], (bool, uint256, uint256));
                (bool updated, uint256 rate) = updateExchangeRate();
                require((!must_update || updated) && rate > minRate && (maxRate == 0 || rate > maxRate), "Cauldron: rate not ok");
            } else if (action == ACTION_BENTO_SETAPPROVAL) {
                (address user, address _masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) = abi.decode(
                    datas[i],
                    (address, address, bool, uint8, bytes32, bytes32)
                );
                bentoBox.setMasterContractApproval(user, _masterContract, approved, v, r, s);
            } else if (action == ACTION_BENTO_DEPOSIT) {
                (value1, value2) = _bentoDeposit(datas[i], values[i], value1, value2);
            } else if (action == ACTION_BENTO_WITHDRAW) {
                (value1, value2) = _bentoWithdraw(datas[i], value1, value2);
            } else if (action == ACTION_BENTO_TRANSFER) {
                (IERC20 token, address to, int256 share) = abi.decode(datas[i], (IERC20, address, int256));
                bentoBox.transfer(token, msg.sender, to, _num(share, value1, value2));
            } else if (action == ACTION_BENTO_TRANSFER_MULTIPLE) {
                (IERC20 token, address[] memory tos, uint256[] memory shares) = abi.decode(datas[i], (IERC20, address[], uint256[]));
                bentoBox.transferMultiple(token, msg.sender, tos, shares);
            } else if (action == ACTION_CALL) {
                (bytes memory returnData, uint8 returnValues) = _call(values[i], datas[i], value1, value2);

                if (returnValues == 1) {
                    (value1) = abi.decode(returnData, (uint256));
                } else if (returnValues == 2) {
                    (value1, value2) = abi.decode(returnData, (uint256, uint256));
                }
            } else if (action == ACTION_GET_REPAY_SHARE) {
                int256 part = abi.decode(datas[i], (int256));
                value1 = bentoBox.toShare(magicInternetMoney, totalBorrow.toElastic(_num(part, value1, value2), true), true);
            } else if (action == ACTION_GET_REPAY_PART) {
                int256 amount = abi.decode(datas[i], (int256));
                value1 = totalBorrow.toBase(_num(amount, value1, value2), false);
            } else if (action == ACTION_LIQUIDATE) {
                _cookActionLiquidate(datas[i]);
            } else if (action == ACTION_RELEASE_COLLATERAL_FROM_STRATEGY) {
                require(previousStrategyTargetPercentage == type(uint64).max, "Cauldron: strategy already released");

                (, previousStrategyTargetPercentage, ) = bentoBox.strategyData(collateral);
                IBentoBoxOwner(bentoBox.owner()).setStrategyTargetPercentageAndRebalance(collateral, 0);
            } else {
                (bytes memory returnData, uint8 returnValues) = _additionalCookAction(action, values[i], datas[i], value1, value2);
                if (returnValues == 1) {
                    (value1) = abi.decode(returnData, (uint256));
                } else if (returnValues == 2) {
                    (value1, value2) = abi.decode(returnData, (uint256, uint256));
                }
            }
        }

        if (previousStrategyTargetPercentage != type(uint64).max) {
            IBentoBoxOwner(bentoBox.owner()).setStrategyTargetPercentageAndRebalance(collateral, previousStrategyTargetPercentage);
        }

        if (status.needsSolvencyCheck) {
            (, uint256 _exchangeRate) = updateExchangeRate();
            require(_isSolvent(msg.sender, _exchangeRate), "Cauldron: user insolvent");
        }
    }

    function _cookActionLiquidate(bytes calldata data) internal {
        (address[] memory users, uint256[] memory maxBorrowParts, address to, ISwapperV2 swapper, bytes memory swapperData) = abi.decode(
            data,
            (address[], uint256[], address, ISwapperV2, bytes)
        );
        liquidate(users, maxBorrowParts, to, swapper, swapperData);
    }

    function _beforeUsersLiquidated(address[] memory users, uint256[] memory maxBorrowPart) internal virtual {}

    function _beforeUserLiquidated(address user, uint256 borrowPart, uint256 borrowAmount, uint256 collateralShare) internal virtual {}

    function _afterUserLiquidated(address user, uint256 collateralShare) internal virtual {}

    /// @notice Handles the liquidation of users' balances, once the users' amount of collateral is too low.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    /// @param to Address of the receiver in open liquidations if `swapper` is zero.
    function liquidate(
        address[] memory users,
        uint256[] memory maxBorrowParts,
        address to,
        ISwapperV2 swapper,
        bytes memory swapperData
    ) public virtual {
        // Oracle can fail but we still need to allow liquidations
        (, uint256 _exchangeRate) = updateExchangeRate();
        accrue();

        uint256 allCollateralShare;
        uint256 allBorrowAmount;
        uint256 allBorrowPart;
        Rebase memory bentoBoxTotals = bentoBox.totals(collateral);
        _beforeUsersLiquidated(users, maxBorrowParts);

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!_isSolvent(user, _exchangeRate)) {
                uint256 borrowPart;
                {
                    uint256 availableBorrowPart = userBorrowPart[user];
                    borrowPart = maxBorrowParts[i] > availableBorrowPart ? availableBorrowPart : maxBorrowParts[i];
                    userBorrowPart[user] = availableBorrowPart - borrowPart;
                    userBorrowInterestDebt[to] = (userBorrowPart[to] * interestPerPart) / 1e20;
                }
                uint256 borrowAmount = totalBorrow.toElastic(borrowPart, false);
                uint256 collateralShare = bentoBoxTotals.toBase(
                    ((borrowAmount * LIQUIDATION_MULTIPLIER * _exchangeRate) / LIQUIDATION_MULTIPLIER_PRECISION) * EXCHANGE_RATE_PRECISION,
                    false
                );

                _beforeUserLiquidated(user, borrowPart, borrowAmount, collateralShare);
                userCollateralShare[user] = userCollateralShare[user] - (collateralShare);
                _afterUserLiquidated(user, collateralShare);

                emit LogRemoveCollateral(user, to, collateralShare);
                emit LogRepay(msg.sender, user, borrowAmount, borrowPart);
                emit LogLiquidation(msg.sender, user, to, collateralShare, borrowAmount, borrowPart);

                // Keep totals
                allCollateralShare = allCollateralShare + collateralShare;
                allBorrowAmount = allBorrowAmount + borrowAmount;
                allBorrowPart = allBorrowPart + borrowPart;
            }
        }
        require(allBorrowAmount != 0, "Cauldron: all are solvent");
        IMasterChef(distributeTo).withdraw(users);
        totalBorrow.elastic = totalBorrow.elastic - uint128(allBorrowAmount);
        totalBorrow.base = totalBorrow.base - uint128(allBorrowPart);
        totalCollateralShare = totalCollateralShare - (allCollateralShare);

        // Apply a percentual fee share to sSpell holders

        {
            uint256 distributionAmount = (((allBorrowAmount * LIQUIDATION_MULTIPLIER) /
                LIQUIDATION_MULTIPLIER_PRECISION -
                allBorrowAmount) * DISTRIBUTION_PART) / DISTRIBUTION_PRECISION; // Distribution Amount
            allBorrowAmount = allBorrowAmount + distributionAmount;
            accrueInfo.feesEarned = accrueInfo.feesEarned + uint128(distributionAmount);
        }

        uint256 allBorrowShare = bentoBox.toShare(magicInternetMoney, allBorrowAmount, true);

        // Swap using a swapper freely chosen by the caller
        // Open (flash) liquidation: get proceeds first and provide the borrow after
        bentoBox.transfer(collateral, address(this), to, allCollateralShare);
        if (swapper != ISwapperV2(address(0))) {
            swapper.swap(address(collateral), address(magicInternetMoney), msg.sender, allBorrowShare, allCollateralShare, swapperData);
        }

        allBorrowShare = bentoBox.toShare(magicInternetMoney, allBorrowAmount, true);
        bentoBox.transfer(magicInternetMoney, msg.sender, address(this), allBorrowShare);
    }

    /// @notice Withdraws the fees accumulated.
    function withdrawFees() public {
        accrue();
        address _feeTo = masterContract.feeTo();
        address _distributeTo = distributeTo;
        uint256 share = bentoBox.toShare(magicInternetMoney, accrueInfo.feesEarned, false);
        uint256 shareNeedWithdraw = IMasterChef(_distributeTo).getShareThatShouldDistribute();
        if (shareNeedWithdraw > 0) {
            (uint256 amountOut, ) = bentoBox.withdraw(
                magicInternetMoney,
                address(this),
                address(this),
                0,
                (share * shareNeedWithdraw) / 100
            );
            magicInternetMoney.approve(_distributeTo, amountOut);
            IMasterChef(_distributeTo).addRewardToPool(amountOut);
        }
        accrueInfo.feesEarned = 0;

        bentoBox.transfer(magicInternetMoney, address(this), _feeTo, (share * (100 - shareNeedWithdraw)) / 100);
        emit LogWithdrawFees(_feeTo, (share * (100 - shareNeedWithdraw)) / 100);
        // if (shareNeedWithdraw > 0) {
        //     emit LogWithdrawFees(_distributeTo, (share * shareNeedWithdraw) / 100);
        // }
    }

    /// @notice Sets the beneficiary of interest accrued.
    /// MasterContract Only Admin function.
    /// @param newFeeTo The address of the receiver.
    function setFeeTo(address newFeeTo) public onlyOwner {
        feeTo = newFeeTo;
        emit LogFeeTo(newFeeTo);
    }

    /// @notice reduces the supply of MIM
    /// @param amount amount to reduce supply by
    function reduceSupply(uint256 amount) public onlyMasterContractOwner {
        uint256 maxAmount = bentoBox.toAmount(magicInternetMoney, bentoBox.balanceOf(magicInternetMoney, address(this)), false);
        amount = maxAmount > amount ? amount : maxAmount;
        bentoBox.withdraw(magicInternetMoney, address(this), msg.sender, amount, 0);
    }

    /// @notice allows to change the interest rate
    /// @param newInterestRate new interest rate
    function changeInterestRate(uint64 newInterestRate) public onlyMasterContractOwner {
        uint64 oldInterestRate = accrueInfo.INTEREST_PER_SECOND;

        require(
            newInterestRate < oldInterestRate + (oldInterestRate * 3) / 4 || newInterestRate <= ONE_PERCENT_RATE,
            "Interest rate increase > 75%"
        );
        require(lastInterestUpdate + 3 days < block.timestamp, "Update only every 3 days");

        lastInterestUpdate = block.timestamp;
        accrueInfo.INTEREST_PER_SECOND = newInterestRate;
        emit LogInterestChange(oldInterestRate, newInterestRate);
    }

    /// @notice allows to change the borrow limit
    /// @param newBorrowLimit new borrow limit
    /// @param perAddressPart new borrow limit per address
    function changeBorrowLimit(uint128 newBorrowLimit, uint128 perAddressPart) public onlyMasterContractOwner {
        borrowLimit = BorrowCap(newBorrowLimit, perAddressPart);
        emit LogChangeBorrowLimit(newBorrowLimit, perAddressPart);
    }

    /// @notice allows to change blacklisted callees
    /// @param callee callee to blacklist or not
    /// @param blacklisted true when the callee cannot be used in call cook action
    function setBlacklistedCallee(address callee, bool blacklisted) public onlyMasterContractOwner {
        require(callee != address(bentoBox) && callee != address(this), "invalid callee");

        blacklistedCallees[callee] = blacklisted;
        emit LogChangeBlacklistedCallee(callee, blacklisted);
    }

    /// @notice Used to auto repay everyone liabilities'.
    /// Transfer MIM deposit to DegenBox for this Cauldron and increase the totalBorrow base or skim
    /// all mim inside this contract
    function repayForAll(uint128 amount, bool skim) public returns (uint128) {
        accrue();

        if (skim) {
            // ignore amount and take every mim in this contract since it could be taken by anyone, the next block.
            amount = uint128(magicInternetMoney.balanceOf(address(this)));
            bentoBox.deposit(magicInternetMoney, address(this), address(this), amount, 0);
        } else {
            bentoBox.transfer(magicInternetMoney, msg.sender, address(this), bentoBox.toShare(magicInternetMoney, amount, true));
        }

        uint128 previousElastic = totalBorrow.elastic;

        require(previousElastic - amount > 1000 * 1e18, "Total Elastic too small");

        totalBorrow.elastic = previousElastic - amount;

        emit LogRepayForAll(amount, previousElastic, totalBorrow.elastic);
        return amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base++;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic++;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic += uint128(elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic -= uint128(elastic);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISwapperV2 {
    /// @notice Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for at least 'amountToMin' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain IERC20 transfer.
    /// Returns the amount of tokens 'to' transferred to BentoBox.
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swap(
        address fromToken,
        address toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom,
        bytes calldata data
    ) external returns (uint256 extraShare, uint256 shareReturned);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/libraries/BoringRebase.sol";
import "interfaces/IStrategy.sol";

interface IFlashBorrower {
    /// @notice The flashloan callback. `amount` + `fee` needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param token The address of the token that is loaned.
    /// @param amount of the `token` that is loaned.
    /// @param fee The fee that needs to be paid on top for this loan. Needs to be the same as `token`.
    /// @param data Additional data that was passed to the flashloan function.
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

interface IBatchFlashBorrower {
    /// @notice The callback for batched flashloans. Every amount + fee needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param tokens Array of addresses for ERC-20 tokens that is loaned.
    /// @param amounts A one-to-one map to `tokens` that is loaned.
    /// @param fees A one-to-one map to `tokens` that needs to be paid on top for each loan. Needs to be the same token.
    /// @param data Additional data that was passed to the flashloan function.
    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external;
}

interface IBentoBoxV1 {
    function balanceOf(IERC20, address) external view returns (uint256);

    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results);

    function batchFlashLoan(
        IBatchFlashBorrower borrower,
        address[] calldata receivers,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function claimOwnership() external;

    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable returns (address);

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function harvest(
        IERC20 token,
        bool balance,
        uint256 maxChangeAmount
    ) external;

    function masterContractApproved(address, address) external view returns (bool);

    function masterContractOf(address) external view returns (address);

    function nonces(address) external view returns (uint256);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingStrategy(IERC20) external view returns (IStrategy);

    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function registerProtocol() external;

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function setStrategy(IERC20 token, IStrategy newStrategy) external;

    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) external;

    function strategy(IERC20) external view returns (IStrategy);

    function strategyData(IERC20)
        external
        view
        returns (
            uint64 strategyStartDate,
            uint64 targetPercentage,
            uint128 balance
        );

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function totals(IERC20) external view returns (Rebase memory totals_);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) external;

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function whitelistMasterContract(address masterContract, bool approved) external;

    function whitelistedMasterContracts(address) external view returns (bool);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";

interface IBentoBoxOwner {
    function setStrategyTargetPercentageAndRebalance(IERC20 token, uint64 targetPercentage) external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;
import "OpenZeppelin/token/ERC1155/IERC1155.sol";

interface IArvinDegenNFT is IERC1155 {
    function getRefundRatio(address user) external view returns (uint256);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IMasterChef {
    struct LockDetail {
        uint256 lockAmount;
        uint256 unlockAmount;
        uint256 unlockTimestamp;
    }

    // Info of each user.
    struct VestingInfo {
        uint256 vestingReward;
        uint256 claimTime;
        bool isClaimed;
    }

    function addRewardToPool(uint256 amount) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function deposit(address to) external;

    function depositLock(uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function withdraw(address to) external;

    function withdraw(address[] calldata to) external;

    function withdrawLock(uint256 _amount) external;

    function getShareThatShouldDistribute() external view returns (uint256 share);

    function totalStake(uint256 _pid) external returns (uint256 stakeAmount);

    function pendingReward(uint256 _pid, address _user) external view returns (uint256);

    function userPendingReward(address user) external view returns (uint256 pendingReward);

    function userInfo(uint256 _pid, address user) external view returns (uint256 amount, uint256 debt);

    function poolInfo(
        uint256 _pid
    )
        external
        view
        returns (
            address stakeToken,
            address rewardToken,
            uint256 lastRewardTimestamp,
            uint256 rewardPerSecond,
            uint256 rewardPerShare, //multiply 1e20
            bool isDynamicReward
        );

    function getLockAmount(address user) external view returns (uint256 amount);

    function getLockInfo(address user) external view returns (LockDetail[] memory locks);

    function getUnlockableAmount(address user) external view returns (uint256 amount);

    function vestingPendingReward(bool claim) external;

    function claimVestingReward() external;

    function emergencyWithdraw(uint256 _pid) external;

    function estimateARVCirculatingSupply() external view returns (uint256 circulatingSupply);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

interface IStrategy {
    /// @notice Send the assets to the Strategy and call skim to invest them.
    /// @param amount The amount of tokens to invest.
    function skim(uint256 amount) external;

    /// @notice Harvest any profits made converted to the asset and pass them to the caller.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @param sender The address of the initiator of this transaction. Can be used for reimbursements, etc.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    /// @notice Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    /// @dev The `actualAmount` should be very close to the amount.
    /// The difference should NOT be used to report a loss. That's what harvest is for.
    /// @param amount The requested amount the caller wants to withdraw.
    /// @return actualAmount The real amount that is withdrawn.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    /// @notice Withdraw all assets in the safest way possible. This shouldn't fail.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function exit(uint256 balance) external returns (int256 amountAdded);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}