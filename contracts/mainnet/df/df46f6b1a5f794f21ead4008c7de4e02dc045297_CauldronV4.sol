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
import {Owned} from "solmate/auth/Owned.sol";
import {IERC20} from "BoringSolidity/interfaces/IERC20.sol";
import {IOracle} from "interfaces/IOracle.sol";
import {ISwapperV2} from "interfaces/ISwapperV2.sol";
import {IBentoBoxV1} from "interfaces/IBentoBoxV1.sol";
import {IMasterContract} from "BoringSolidity/interfaces/IMasterContract.sol";
import {RebaseLibrary, Rebase} from "BoringSolidity/libraries/BoringRebase.sol";
import {BoringMath, BoringMath128} from "BoringSolidity/libraries/BoringMath.sol";

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

/// @title Cauldron
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract CauldronV4 is Owned, IMasterContract {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
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
    event LogLiquidationMultiplierChanged(uint256 previous, uint256 current);
    event LogBorrowOpeningFeeChanged(uint256 previous, uint256 current);
    event LogCollateralizationRateChanged(uint256 previous, uint256 current);
    
    event LogLiquidation(
        address indexed from,
        address indexed user,
        address indexed to,
        uint256 collateralShare,
        uint256 borrowAmount,
        uint256 borrowPart
    );

    error ErrNotClone();

    // Immutables (for MasterContract and all clones)
    IBentoBoxV1 public immutable bentoBox;
    CauldronV4 public immutable masterContract;
    IERC20 public immutable magicInternetMoney;

    // MasterContract variables
    address public feeTo;

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

    // User balances
    mapping(address => uint256) public userCollateralShare;
    mapping(address => uint256) public userBorrowPart;

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

    modifier onlyClones() {
        if (address(this) == address(masterContract)) {
            revert ErrNotClone();
        }
        _;
    }

    /// @notice The constructor is only used for the initial master contract. Subsequent clones are initialised via `init`.
    constructor(IBentoBoxV1 bentoBox_, IERC20 magicInternetMoney_) Owned(msg.sender) {
        bentoBox = bentoBox_;
        magicInternetMoney = magicInternetMoney_;
        masterContract = this;
        
        blacklistedCallees[address(bentoBox)] = true;
        blacklistedCallees[address(this)] = true;
        blacklistedCallees[Owned(address(bentoBox)).owner()] = true;
    }

    /// @notice Serves as the constructor for clones, as clones can't have a regular constructor
    /// @dev `data` is abi encoded in the format: (IERC20 collateral, IERC20 asset, IOracle oracle, bytes oracleData)
    function init(bytes calldata data) public virtual onlyClones payable override {
        require(address(collateral) == address(0), "Cauldron: already initialized");
        (collateral, oracle, oracleData, accrueInfo.INTEREST_PER_SECOND, LIQUIDATION_MULTIPLIER, COLLATERIZATION_RATE, BORROW_OPENING_FEE) = abi.decode(data, (IERC20, IOracle, bytes, uint64, uint256, uint256, uint256));
        borrowLimit = BorrowCap(type(uint128).max, type(uint128).max);
        require(address(collateral) != address(0), "Cauldron: bad pair");

        magicInternetMoney.approve(address(bentoBox), type(uint256).max);

        blacklistedCallees[address(bentoBox)] = true;
        blacklistedCallees[address(this)] = true;
        blacklistedCallees[Owned(address(bentoBox)).owner()] = true;

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
        uint128 extraAmount = (uint256(_totalBorrow.elastic).mul(_accrueInfo.INTEREST_PER_SECOND).mul(elapsedTime) / 1e18).to128();
        _totalBorrow.elastic = _totalBorrow.elastic.add(extraAmount);

        _accrueInfo.feesEarned = _accrueInfo.feesEarned.add(extraAmount);
        totalBorrow = _totalBorrow;
        accrueInfo = _accrueInfo;

        emit LogAccrue(extraAmount);
    }

    /// @notice Concrete implementation of `isSolvent`. Includes a third parameter to allow caching `exchangeRate`.
    /// @param _exchangeRate The exchange rate. Used to cache the `exchangeRate` between calls.
    function _isSolvent(address user, uint256 _exchangeRate) virtual internal view returns (bool) {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return true;
        uint256 collateralShare = userCollateralShare[user];
        if (collateralShare == 0) return false;

        Rebase memory _totalBorrow = totalBorrow;

        return
            bentoBox.toAmount(
                collateral,
                collateralShare.mul(EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION).mul(COLLATERIZATION_RATE),
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            borrowPart.mul(_totalBorrow.elastic).mul(_exchangeRate) / _totalBorrow.base;
    }

    function isSolvent(address user) public view returns (bool) {
        return _isSolvent(user, exchangeRate);
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
    function _addTokens(
        IERC20 token,
        uint256 share,
        uint256 total,
        bool skim
    ) internal {
        if (skim) {
            require(share <= bentoBox.balanceOf(token, address(this)).sub(total), "Cauldron: Skim too much");
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
    function addCollateral(
        address to,
        bool skim,
        uint256 share
    ) public virtual {
        userCollateralShare[to] = userCollateralShare[to].add(share);
        uint256 oldTotalCollateralShare = totalCollateralShare;
        totalCollateralShare = oldTotalCollateralShare.add(share);
        _addTokens(collateral, share, oldTotalCollateralShare, skim);
        _afterAddCollateral(to, share);
        emit LogAddCollateral(skim ? address(bentoBox) : msg.sender, to, share);
    }

    function _afterRemoveCollateral(address from, address to, uint256 collateralShare) internal virtual {}

    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(address to, uint256 share) internal virtual {
        userCollateralShare[msg.sender] = userCollateralShare[msg.sender].sub(share);
        totalCollateralShare = totalCollateralShare.sub(share);
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

    function _preBorrowAction(address to, uint256 amount, uint256 newBorrowPart, uint256 part) internal virtual {

    }

    /// @dev Concrete implementation of `borrow`.
    function _borrow(address to, uint256 amount) internal returns (uint256 part, uint256 share) {
        uint256 feeAmount = amount.mul(BORROW_OPENING_FEE) / BORROW_OPENING_FEE_PRECISION; // A flat % fee is charged for any borrow
        (totalBorrow, part) = totalBorrow.add(amount.add(feeAmount), true);

        BorrowCap memory cap =  borrowLimit;

        require(totalBorrow.elastic <= cap.total, "Borrow Limit reached");

        accrueInfo.feesEarned = accrueInfo.feesEarned.add(uint128(feeAmount));
        
        uint256 newBorrowPart = userBorrowPart[msg.sender].add(part);
        require(newBorrowPart <= cap.borrowPartPerAddress, "Borrow Limit reached");
        _preBorrowAction(to, amount, newBorrowPart, part);

        userBorrowPart[msg.sender] = newBorrowPart;

        // As long as there are tokens on this contract you can 'mint'... this enables limiting borrows
        share = bentoBox.toShare(magicInternetMoney, amount, false);
        bentoBox.transfer(magicInternetMoney, address(this), to, share);

        emit LogBorrow(msg.sender, to, amount.add(feeAmount), part);
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(address to, uint256 amount) public solvent returns (uint256 part, uint256 share) {
        accrue();
        (part, share) = _borrow(to, amount);
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(
        address to,
        bool skim,
        uint256 part
    ) internal returns (uint256 amount) {
        (totalBorrow, amount) = totalBorrow.sub(part, true);
        userBorrowPart[to] = userBorrowPart[to].sub(part);

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
    function repay(
        address to,
        bool skim,
        uint256 part
    ) public returns (uint256 amount) {
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

    // Custom cook actions
    uint8 internal constant ACTION_CUSTOM_START_INDEX = 100;

    int256 internal constant USE_VALUE1 = -1;
    int256 internal constant USE_VALUE2 = -2;

    /// @dev Helper function for choosing the correct value (`value1` or `value2`) depending on `inNum`.
    function _num(
        int256 inNum,
        uint256 value1,
        uint256 value2
    ) internal pure returns (uint256 outNum) {
        outNum = inNum >= 0 ? uint256(inNum) : (inNum == USE_VALUE1 ? value1 : value2);
    }

    /// @dev Helper function for depositing into `bentoBox`.
    function _bentoDeposit(
        bytes memory data,
        uint256 value,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        amount = int256(_num(amount, value1, value2)); // Done this way to avoid stack too deep errors
        share = int256(_num(share, value1, value2));
        return bentoBox.deposit{value: value}(token, msg.sender, to, uint256(amount), uint256(share));
    }

    /// @dev Helper function to withdraw from the `bentoBox`.
    function _bentoWithdraw(
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        return bentoBox.withdraw(token, msg.sender, to, _num(amount, value1, value2), _num(share, value1, value2));
    }

    /// @dev Helper function to perform a contract call and eventually extracting revert messages on failure.
    /// Calls to `bentoBox` are not allowed for obvious security reasons.
    /// This also means that calls made from this contract shall *not* be trusted.
    function _call(
        uint256 value,
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (bytes memory, uint8) {
        (address callee, bytes memory callData, bool useValue1, bool useValue2, uint8 returnValues) =
            abi.decode(data, (address, bytes, bool, bool, uint8));

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

    struct CookStatus {
        bool needsSolvencyCheck;
        bool hasAccrued;
    }

    function _additionalCookAction(uint8 action, CookStatus memory, uint256 value, bytes memory data, uint256 value1, uint256 value2) internal virtual returns (bytes memory, uint8, CookStatus memory) {}

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
                require((!must_update || updated) && rate > minRate && (maxRate == 0 || rate < maxRate), "Cauldron: rate not ok");
            } else if (action == ACTION_BENTO_SETAPPROVAL) {
                (address user, address _masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) =
                    abi.decode(datas[i], (address, address, bool, uint8, bytes32, bytes32));
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
            } else {
                (bytes memory returnData, uint8 returnValues, CookStatus memory returnStatus) = _additionalCookAction(action, status, values[i], datas[i], value1, value2);
                status = returnStatus;
                
                if (returnValues == 1) {
                    (value1) = abi.decode(returnData, (uint256));
                } else if (returnValues == 2) {
                    (value1, value2) = abi.decode(returnData, (uint256, uint256));
                }
            }
        }

        if (status.needsSolvencyCheck) {
            (, uint256 _exchangeRate) = updateExchangeRate();
            require(_isSolvent(msg.sender, _exchangeRate), "Cauldron: user insolvent");
        }
    }

    function _cookActionLiquidate(bytes calldata data) internal {
         (address[] memory users, uint256[] memory maxBorrowParts, address to, ISwapperV2 swapper, bytes memory swapperData) = abi.decode(data, (address[], uint256[], address, ISwapperV2, bytes));
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
                uint256 availableBorrowPart = userBorrowPart[user];
                borrowPart = maxBorrowParts[i] > availableBorrowPart ? availableBorrowPart : maxBorrowParts[i];

                uint256 borrowAmount = totalBorrow.toElastic(borrowPart, false);
                uint256 collateralShare =
                    bentoBoxTotals.toBase(
                        borrowAmount.mul(LIQUIDATION_MULTIPLIER).mul(_exchangeRate) /
                            (LIQUIDATION_MULTIPLIER_PRECISION * EXCHANGE_RATE_PRECISION),
                        false
                    );

                _beforeUserLiquidated(user, borrowPart, borrowAmount, collateralShare);
                userBorrowPart[user] = availableBorrowPart.sub(borrowPart);
                userCollateralShare[user] = userCollateralShare[user].sub(collateralShare);
                _afterUserLiquidated(user, collateralShare);

                emit LogRemoveCollateral(user, to, collateralShare);
                emit LogRepay(msg.sender, user, borrowAmount, borrowPart);
                emit LogLiquidation(msg.sender, user, to, collateralShare, borrowAmount, borrowPart);

                // Keep totals
                allCollateralShare = allCollateralShare.add(collateralShare);
                allBorrowAmount = allBorrowAmount.add(borrowAmount);
                allBorrowPart = allBorrowPart.add(borrowPart);
            }
        }
        require(allBorrowAmount != 0, "Cauldron: all are solvent");
        totalBorrow.elastic = totalBorrow.elastic.sub(allBorrowAmount.to128());
        totalBorrow.base = totalBorrow.base.sub(allBorrowPart.to128());
        totalCollateralShare = totalCollateralShare.sub(allCollateralShare);

        // Apply a percentual fee share to sSpell holders
        
        {
            uint256 distributionAmount = (allBorrowAmount.mul(LIQUIDATION_MULTIPLIER) / LIQUIDATION_MULTIPLIER_PRECISION).sub(allBorrowAmount).mul(DISTRIBUTION_PART) / DISTRIBUTION_PRECISION; // Distribution Amount
            allBorrowAmount = allBorrowAmount.add(distributionAmount);
            accrueInfo.feesEarned = accrueInfo.feesEarned.add(distributionAmount.to128());
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
        uint256 _feesEarned = accrueInfo.feesEarned;
        uint256 share = bentoBox.toShare(magicInternetMoney, _feesEarned, false);
        bentoBox.transfer(magicInternetMoney, address(this), _feeTo, share);
        accrueInfo.feesEarned = 0;

        emit LogWithdrawFees(_feeTo, _feesEarned);
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
        accrue();
        emit LogInterestChange(accrueInfo.INTEREST_PER_SECOND, newInterestRate);
        accrueInfo.INTEREST_PER_SECOND = newInterestRate;
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

    /// Allows to change the liquidation multiplier
    /// @param _liquidationMultiplier new liquidation multiplier.
    /// To convert from bips: liquidationFeeBips * 1e1 + 1e5
    function setLiquidationMultiplier(uint256 _liquidationMultiplier) public onlyMasterContractOwner {
        emit LogLiquidationMultiplierChanged(LIQUIDATION_MULTIPLIER, _liquidationMultiplier);
        LIQUIDATION_MULTIPLIER = _liquidationMultiplier;
    }

    /// Allows to change the borrow opening fee
    /// @param _borrowOpeningFee new borrow opening fee.
    /// To convert from bips: borrowOpeningFeeBips * 1e1
    function setBorrowOpeningFee(uint256 _borrowOpeningFee) public onlyMasterContractOwner {
        emit LogBorrowOpeningFeeChanged(BORROW_OPENING_FEE, _borrowOpeningFee);
        BORROW_OPENING_FEE = _borrowOpeningFee;
    }

    /// Allows to change the collateralization rate
    /// @param _collateralizationRate new collateralization rate.
    /// To convert from bips: collateralizationRateBips * 1e1
    function setCollateralizationRate(uint256 _collateralizationRate) public onlyMasterContractOwner {
        emit LogCollateralizationRateChanged(COLLATERIZATION_RATE, _collateralizationRate);
        COLLATERIZATION_RATE = _collateralizationRate;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
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
pragma solidity >=0.8.0;

interface IOracle {
    function decimals() external view returns (uint8);

    function get(bytes calldata data) external returns (bool success, uint256 rate);

    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    function symbol(bytes calldata data) external view returns (string memory);

    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISwapperV2 {
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

import {IERC20} from "BoringSolidity/interfaces/IERC20.sol";
import {Rebase} from "BoringSolidity/libraries/BoringRebase.sol";
import {IStrategy} from "interfaces/IStrategy.sol";

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
import {BoringMath, BoringMath128} from "./BoringMath.sol";

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    using BoringMath for uint256;
    using BoringMath128 for uint128;

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
        total.elastic += elastic.to128();
        total.base += base.to128();
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
        total.elastic -= elastic.to128();
        total.base -= base.to128();
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic += elastic.to128();
        total.base += base.to128();
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic -= elastic.to128();
        total.base -= base.to128();
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic += elastic.to128();
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic -= elastic.to128();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library BoringMath {
    error ErrOverflow();

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function to32(uint256 a) internal pure returns (uint32) {
        if (a > type(uint32).max) {
            revert ErrOverflow();
        }
        return uint32(a);
    }

    function to40(uint256 a) internal pure returns (uint40) {
        if (a > type(uint40).max) {
            revert ErrOverflow();
        }
        return uint40(a);
    }

    function to64(uint256 a) internal pure returns (uint64) {
        if (a > type(uint64).max) {
            revert ErrOverflow();
        }
        return uint64(a);
    }

    function to112(uint256 a) internal pure returns (uint112) {
        if (a > type(uint112).max) {
            revert ErrOverflow();
        }
        return uint112(a);
    }

    function to128(uint256 a) internal pure returns (uint128) {
        if (a > type(uint128).max) {
            revert ErrOverflow();
        }
        return uint128(a);
    }

    function to208(uint256 a) internal pure returns (uint208) {
        if (a > type(uint208).max) {
            revert ErrOverflow();
        }
        return uint208(a);
    }

    function to216(uint256 a) internal pure returns (uint216) {
        if (a > type(uint216).max) {
            revert ErrOverflow();
        }
        return uint216(a);
    }

    function to224(uint256 a) internal pure returns (uint224) {
        if (a > type(uint224).max) {
            revert ErrOverflow();
        }
        return uint224(a);
    }
}

library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        return a + b;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        return a - b;
    }

    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        return a * b;
    }

    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        return a / b;
    }
}

library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64) {
        return a + b;
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64) {
        return a - b;
    }

    function mul(uint64 a, uint64 b) internal pure returns (uint64) {
        return a * b;
    }

    function div(uint64 a, uint64 b) internal pure returns (uint64) {
        return a / b;
    }
}

library BoringMath112 {
    function add(uint112 a, uint112 b) internal pure returns (uint112) {
        return a + b;
    }

    function sub(uint112 a, uint112 b) internal pure returns (uint112) {
        return a - b;
    }

    function mul(uint112 a, uint112 b) internal pure returns (uint112) {
        return a * b;
    }

    function div(uint112 a, uint112 b) internal pure returns (uint112) {
        return a / b;
    }
}

library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        return a + b;
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        return a - b;
    }

    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        return a * b;
    }

    function div(uint128 a, uint128 b) internal pure returns (uint128) {
        return a / b;
    }
}

library BoringMath224 {
    function add(uint224 a, uint224 b) internal pure returns (uint224) {
        return a + b;
    }

    function sub(uint224 a, uint224 b) internal pure returns (uint224) {
        return a - b;
    }

    function mul(uint224 a, uint224 b) internal pure returns (uint224) {
        return a * b;
    }

    function div(uint224 a, uint224 b) internal pure returns (uint224) {
        return a / b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IStrategy {
    function skim(uint256 amount) external;

    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    function exit(uint256 balance) external returns (int256 amountAdded);
}