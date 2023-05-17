// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

pragma solidity =0.8.4;

interface ICreditAggregator {
    function getGlpPrice(bool _isBuying) external view returns (uint256);

    function getBuyGlpToAmount(address _fromToken, uint256 _tokenAmountIn) external view returns (uint256, uint256);

    function getSellGlpToAmount(address _toToken, uint256 _glpAmountIn) external view returns (uint256, uint256);

    function getBuyGlpFromAmount(address _toToken, uint256 _glpAmountIn) external view returns (uint256, uint256);

    function getSellGlpFromAmount(address _fromToken, uint256 _tokenAmountIn) external view returns (uint256, uint256);

    function getSellGlpFromAmounts(address[] calldata _tokens, uint256[] calldata _amounts) external view returns (uint256 totalAmountOut, uint256[] memory);

    function getTokenPrice(address _token) external view returns (uint256);

    function adjustForDecimals(
        uint256 _amountIn,
        uint256 _divDecimals,
        uint256 _mulDecimals
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface ICreditCaller {
     function openLendCredit(
        address _depositor,
        uint256 _amountIn,
        address[] calldata _borrowedTokens,
        uint256[] calldata _ratios,
        address _recipient
    ) external payable;

    function repayCredit(uint256 _borrowedIndex) external returns (uint256);

    function liquidate(address _recipient, uint256 _borrowedIndex) external;

    event LendCredit(
        address indexed _recipient,
        uint256 _borrowedIndex,
        address _depositor,
        address _token,
        uint256 _amountIn,
        address[] _borrowedTokens,
        uint256[] _ratios,
        uint256 _timestamp
    );
    event CalcBorrowAmount(address indexed _borrowedToken, uint256 _borrowedIndex, uint256 _borrowedAmountOuts, uint256 _borrowedMintedAmount);
    event RepayCredit(address indexed _recipient, uint256 _borrowedIndex, address _collateralToken, uint256 _collateralAmountOut, uint256 _timestamp);
    event RepayDebts(address indexed _recipient, uint256 _borrowedIndex, uint256 _amountOut, uint256 _borrowedAmountOut);
    event Liquidate(address _recipient, uint256 _borrowedIndex, uint256 _health, uint256 _timestamp);
    event LiquidatorFee(address _liquidator, uint256 _fee, uint256 _borrowedIndex);
    event AddStrategy(address _depositor, address _collateralReward, address[] _vaults, address[] _vaultRewards);
    event AddVaultManager(address _underlying, address _creditManager);
    event SetCreditUser(address _creditUser);
    event SetCreditTokenStaker(address _creditTokenStaker);
    event SetLiquidateThreshold(uint256 _threshold);
    event SetLiquidatorFee(uint256 _fee);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface ICreditUser {
    struct UserLendCredit {
        address depositor;
        address token;
        uint256 amountIn;
        uint256 reservedLiquidatorFee;
        address[] borrowedTokens;
        uint256[] ratios;
        bool terminated;
    }

    struct UserBorrowed {
        address[] creditManagers;
        uint256[] borrowedAmountOuts;
        uint256 collateralMintedAmount;
        uint256[] borrowedMintedAmount;
        uint256 borrowedAt;
    }

    function accrueSnapshot(address _recipient) external returns (uint256);

    function createUserLendCredit(
        address _recipient,
        uint256 _borrowedIndex,
        address _depositor,
        address _token,
        uint256 _amountIn,
        uint256 _reservedLiquidatorFee,
        address[] calldata _borrowedTokens,
        uint256[] calldata _ratios
    ) external;

    function createUserBorrowed(
        address _recipient,
        uint256 _borrowedIndex,
        address[] calldata _creditManagers,
        uint256[] calldata _borrowedAmountOuts,
        uint256 _collateralMintedAmount,
        uint256[] calldata _borrowedMintedAmount
    ) external;

    function destroy(
        address _recipient,
        uint256 _borrowedIndex,
        address _liquidator
    ) external;

    function hasPassedSinceLastTerminated(address _recipient, uint256 _duration) external view returns (bool);

    function isTerminated(address _recipient, uint256 _borrowedIndex) external view returns (bool);

    function isTimeout(
        address _recipient,
        uint256 _borrowedIndex,
        uint256 _duration
    ) external view returns (bool);

    function getUserLendCredit(address _recipient, uint256 _borrowedIndex)
        external
        view
        returns (
            address depositor,
            address token,
            uint256 amountIn,
            uint256 _reservedLiquidatorFee,
            address[] memory borrowedTokens,
            uint256[] memory ratio
        );

    function getUserBorrowed(address _user, uint256 _borrowedIndex)
        external
        view
        returns (
            address[] memory creditManagers,
            uint256[] memory borrowedAmountOuts,
            uint256 collateralMintedAmount,
            uint256[] memory borrowedMintedAmount,
            uint256 mintedAmount
        );

    function getUserCounts(address _recipient) external view returns (uint256);

    function getLendCreditUsers(uint256 _borrowedIndex) external view returns (address);

    event CreateUserLendCredit(
        address indexed _recipient,
        uint256 _borrowedIndex,
        address _depositor,
        address _token,
        uint256 _amountIn,
        address[] _borrowedTokens,
        uint256[] _ratios
    );

    event CreateUserBorrowed(
        address indexed _recipient,
        uint256 _borrowedIndex,
        address[] _creditManagers,
        uint256[] _borrowedAmountOuts,
        uint256 _collateralMintedAmount,
        uint256[] _borrowedMintedAmount,
        uint256 _borrowedAt
    );

    event Destroy(address indexed _recipient, uint256 _borrowedIndex);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { ICreditCaller as IOriginCreditCaller } from "../credit/interfaces/ICreditCaller.sol";
import { ICreditUser } from "../credit/interfaces/ICreditUser.sol";
import { ICreditAggregator } from "../credit/interfaces/ICreditAggregator.sol";

interface IGmxGlpManager {
    function getAum(bool maximise) external view returns (uint256);
}

interface IGmxVault {
    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);
}

interface IGmxStakedGlp {
    function totalSupply() external view returns (uint256);
}

interface IGmxRewardTracker {
    function tokensPerInterval() external view returns (uint256);
}

interface ICreditCaller is IOriginCreditCaller {
    function creditUser() external view returns (address);

    function getUserCreditHealth(address _recipient, uint256 _borrowedIndex) external view returns (uint256);
}

interface IVaultRewardDistributors {
    function borrowedRewardPoolRatio() external view returns (uint256);
}

contract CreditPagination is Ownable {
    uint256 private constant ONE_YEAR = 31536000;
    address private constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address private constant STAKED_GLP = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;

    address public gmxGlpManager = 0x3963FfC9dff443c2A94f21b129D429891E32ec18;
    address public gmxStakedGlp = 0x4277f8F2c384827B5273592FF7CeBd9f2C1ac258;
    address public gmxRewardTracker = 0x4e971a87900b931fF39d1Aad67697F49835400b6;
    address public gmxVault = 0x489ee077994B6658eAfA855C308275EAd8097C4A;
    address public creditAggregator = 0xeD36E66ad87dE148A908e8a51b78888553D87E16;

    mapping(address => address) public vaultRewardsDistributors;

    struct UserLendCredit {
        address depositor;
        address token;
        uint256 amountIn;
        uint256 reservedLiquidatorFee;
        address[] borrowedTokens;
        uint256[] ratios;
        uint256 health;
        bool terminated;
    }

    struct UserBorrowed {
        address[] creditManagers;
        uint256[] borrowedAmountOuts;
        uint256 collateralMintedAmount;
        uint256[] borrowedMintedAmount;
        uint256 mintedAmount;
    }

    struct UserPosition {
        address creditCaller;
        uint256 borrowedIndex;
        UserLendCredit userLendCredit;
        UserBorrowed userBorrowed;
    }

    struct GeneralPosition {
        uint256 totalPositions;
        uint256[] userCounts;
        LendCreditMapping[] lendCreditMappings;
        uint256 size;
        bool hasNext;
    }

    struct LendCreditMapping {
        address creditCaller;
        address creditUser;
        uint256 borrowedIndex;
        address recipient;
    }

    struct ReturnPosition {
        uint256 positionApr;
        uint256 gmxApr;
        uint256 withdrawBalance;
        address creditCaller;
        uint256 borrowedIndex;
        UserLendCredit userLendCredits;
        UserBorrowed userBorroweds;
    }

    function _getCreditUsers(address[] calldata _creditCallers) internal view returns (address[] memory) {
        address[] memory creditUsers = new address[](_creditCallers.length);

        for (uint256 i = 0; i < _creditCallers.length; i++) {
            creditUsers[i] = ICreditCaller(_creditCallers[i]).creditUser();
        }

        return creditUsers;
    }

    function _getGeneralPosition(
        address[] memory _creditCallers,
        address[] memory _creditUsers,
        address _recipient,
        uint256 _offset,
        uint256 _size
    ) internal view returns (GeneralPosition memory generalPosition) {
        generalPosition.userCounts = new uint256[](_creditUsers.length);

        for (uint256 i = 0; i < _creditUsers.length; i++) {
            generalPosition.userCounts[i] = ICreditUser(_creditUsers[i]).getUserCounts(_recipient);
            generalPosition.totalPositions += generalPosition.userCounts[i];
        }

        (generalPosition.size, generalPosition.hasNext) = _getCursor(generalPosition.totalPositions, _offset, _size);

        generalPosition.lendCreditMappings = _getLendCreditMapping(
            generalPosition.totalPositions,
            generalPosition.userCounts,
            _creditCallers,
            _creditUsers,
            _recipient
        );
    }

    function _getCursor(uint256 _totalSize, uint256 _offset, uint256 _size) internal pure returns (uint256 size, bool hasNext) {
        if (_offset >= _totalSize) {
            size = 0;
            hasNext = false;
        } else if (_offset + _size > _totalSize) {
            size = _totalSize - _offset;
            hasNext = false;
        } else {
            size = _size;
            hasNext = true;
        }
    }

    function getCreditPagination(
        address[] calldata _creditCallers,
        address _recipient,
        uint256 _offset,
        uint256 _size
    ) public view returns (ReturnPosition[] memory, uint256, bool) {
        require(_creditCallers.length > 0, "CreditPagination: Length mismatch");
        require(_recipient != address(0), "CreditPagination: _recipient cannot be 0x0");
        require(_size > 0, "CreditPagination: _size cannot be 0");

        address[] memory creditUsers = _getCreditUsers(_creditCallers);
        GeneralPosition memory generalPosition = _getGeneralPosition(_creditCallers, creditUsers, _recipient, _offset, _size);
        UserPosition[] memory userPositions = _getPagination(generalPosition.lendCreditMappings, _offset, generalPosition.size);

        return (_calcUserPositions(userPositions), generalPosition.size, generalPosition.hasNext);
    }

    function _getPagination(LendCreditMapping[] memory _lendCreditMappings, uint256 _offset, uint256 _size) internal view returns (UserPosition[] memory) {
        UserPosition[] memory userPositions = new UserPosition[](_size);

        uint256 borrowedIndex = 0;

        for (uint256 i = 0; i < _lendCreditMappings.length; i++) {
            if (i < _offset) continue;
            if (borrowedIndex == _size) break;

            userPositions[borrowedIndex].creditCaller = _lendCreditMappings[i].creditCaller;
            userPositions[borrowedIndex].borrowedIndex = _lendCreditMappings[i].borrowedIndex;
            userPositions[borrowedIndex].userLendCredit = _getUserLendCredit(
                _lendCreditMappings[i].creditCaller,
                _lendCreditMappings[i].creditUser,
                _lendCreditMappings[i].recipient,
                _lendCreditMappings[i].borrowedIndex
            );
            userPositions[borrowedIndex].userBorrowed = _getUserBorrowed(
                _lendCreditMappings[i].creditUser,
                _lendCreditMappings[i].recipient,
                _lendCreditMappings[i].borrowedIndex
            );

            borrowedIndex++;
        }

        return userPositions;
    }

    function _getLendCreditMapping(
        uint256 _totalPositions,
        uint256[] memory _userCount,
        address[] memory _creditCallers,
        address[] memory _creditUsers,
        address _recipient
    ) internal pure returns (LendCreditMapping[] memory) {
        LendCreditMapping[] memory lendCreditMappings = new LendCreditMapping[](_totalPositions);
        uint256 borrowedIndex = 0;

        for (uint256 i = 0; i < _creditCallers.length; i++) {
            for (uint256 j = 0; j < _userCount[i]; j++) {
                lendCreditMappings[borrowedIndex].creditCaller = _creditCallers[i];
                lendCreditMappings[borrowedIndex].creditUser = _creditUsers[i];
                lendCreditMappings[borrowedIndex].borrowedIndex = j + 1;
                lendCreditMappings[borrowedIndex].recipient = _recipient;
                borrowedIndex++;
            }
        }

        return lendCreditMappings;
    }

    function _calcUserPositions(UserPosition[] memory userPositions) internal view returns (ReturnPosition[] memory) {
        ReturnPosition[] memory returnPositions = new ReturnPosition[](userPositions.length);

        uint256 gmxApr = fetchGmxApr();

        for (uint256 i = 0; i < userPositions.length; i++) {
            uint256 positionApr = 0;
            uint256 withdrawBalance = 0;

            if (!userPositions[i].userLendCredit.terminated) {
                positionApr = _calcPositionApr(gmxApr, userPositions[i].userLendCredit);
                withdrawBalance = _calcWithdrawBalance(userPositions[i].userLendCredit, userPositions[i].userBorrowed);
            }

            returnPositions[i] = ReturnPosition({
                gmxApr: gmxApr,
                creditCaller: userPositions[i].creditCaller,
                borrowedIndex: userPositions[i].borrowedIndex,
                positionApr: positionApr,
                withdrawBalance: withdrawBalance,
                userLendCredits: userPositions[i].userLendCredit,
                userBorroweds: userPositions[i].userBorrowed
            });
        }

        return returnPositions;
    }

    function _calcPositionApr(uint256 _gmxApr, UserLendCredit memory _lendCredit) internal view returns (uint256 apr) {
        apr = _gmxApr;

        for (uint256 i = 0; i < _lendCredit.ratios.length; i++) {
            address borrowedToken = _lendCredit.borrowedTokens[i];
            uint256 baseApr = (_gmxApr * IVaultRewardDistributors(vaultRewardsDistributors[borrowedToken]).borrowedRewardPoolRatio()) / 1000;
            apr += (_lendCredit.ratios[i] * baseApr) / 100;
        }
    }

    function _calcWithdrawBalance(UserLendCredit memory _lendCredit, UserBorrowed memory _borrowed) internal view returns (uint256) {
        uint256 totalMintedAmounts = _borrowed.mintedAmount;

        for (uint256 i = 0; i < _lendCredit.borrowedTokens.length; i++) {
            (uint256 amountOut, ) = ICreditAggregator(creditAggregator).getSellGlpFromAmount(_lendCredit.borrowedTokens[i], _borrowed.borrowedAmountOuts[i]);

            if (totalMintedAmounts > amountOut) {
                totalMintedAmounts -= amountOut;
            } else {
                totalMintedAmounts = 0;
                break;
            }
        }

        if (_lendCredit.token == STAKED_GLP || totalMintedAmounts == 0) {
            return totalMintedAmounts;
        }

        (uint256 amounts, ) = ICreditAggregator(creditAggregator).getSellGlpToAmount(_lendCredit.token, totalMintedAmounts);

        return amounts;
    }

    function _getUserLendCredit(
        address _creditCaller,
        address _creditUser,
        address _recipient,
        uint256 _borrowedIndex
    ) internal view returns (UserLendCredit memory) {
        (
            address depositor,
            address token,
            uint256 amountIn,
            uint256 reservedLiquidatorFee,
            address[] memory borrowedTokens,
            uint256[] memory ratios
        ) = ICreditUser(_creditUser).getUserLendCredit(_recipient, _borrowedIndex);

        bool terminated = ICreditUser(_creditUser).isTerminated(_recipient, _borrowedIndex);

        return
            UserLendCredit({
                depositor: depositor,
                token: token,
                amountIn: amountIn,
                reservedLiquidatorFee: reservedLiquidatorFee,
                borrowedTokens: borrowedTokens,
                ratios: ratios,
                terminated: terminated,
                health: !terminated ? ICreditCaller(_creditCaller).getUserCreditHealth(_recipient, _borrowedIndex) : 0
            });
    }

    function _getUserBorrowed(address _creditUser, address _recipient, uint256 _borrowedIndex) internal view returns (UserBorrowed memory) {
        (
            address[] memory creditManagers,
            uint256[] memory borrowedAmountOuts,
            uint256 collateralMintedAmount,
            uint256[] memory borrowedMintedAmount,
            uint256 mintedAmount
        ) = ICreditUser(_creditUser).getUserBorrowed(_recipient, _borrowedIndex);

        return
            UserBorrowed({
                creditManagers: creditManagers,
                borrowedAmountOuts: borrowedAmountOuts,
                collateralMintedAmount: collateralMintedAmount,
                borrowedMintedAmount: borrowedMintedAmount,
                mintedAmount: mintedAmount
            });
    }

    function fetchGmxApr() public view returns (uint256 apr) {
        uint256 totalGlpSupply = IGmxStakedGlp(gmxStakedGlp).totalSupply();
        uint256 tokensPerInterval = IGmxRewardTracker(gmxRewardTracker).tokensPerInterval();
        uint256 wethPrice = IGmxVault(gmxVault).getMinPrice(WETH);
        uint256 glpPrice = ICreditAggregator(creditAggregator).getGlpPrice(false);
        uint256 glpSupplyUsd = totalGlpSupply * glpPrice;

        uint256 annualRewardsUsd = tokensPerInterval * ONE_YEAR * wethPrice;

        apr = (annualRewardsUsd * 10000) / glpSupplyUsd; // 1242
    }

    function setVaultRewardsDistributor(address _borrowedToken, address _rewardDistributor) public onlyOwner {
        require(_borrowedToken != address(0), "CreditPagination: _borrowedToken cannot be 0x0");
        require(_rewardDistributor != address(0), "CreditPagination: _rewardDistributor cannot be 0x0");

        vaultRewardsDistributors[_borrowedToken] = _rewardDistributor;
    }
}