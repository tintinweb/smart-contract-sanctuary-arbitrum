/**
 *Submitted for verification at Arbiscan.io on 2023-12-14
*/

// File: contracts\interfaces\ILendingVaultV1.sol

pragma solidity >=0.5.0;

interface ILendingVaultV1 {

	/*** Impermax ERC20 ***/
	
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	
	function name() external pure returns (string memory);
	function symbol() external pure returns (string memory);
	function decimals() external pure returns (uint8);
	function totalSupply() external view returns (uint);
	function balanceOf(address owner) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint value) external returns (bool);
	function transfer(address to, uint value) external returns (bool);
	function transferFrom(address from, address to, uint value) external returns (bool);
	
	function DOMAIN_SEPARATOR() external view returns (bytes32);
	function PERMIT_TYPEHASH() external pure returns (bytes32);
	function nonces(address owner) external view returns (uint);
	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
	
	/*** Pool Token ***/
	
	event Mint(address indexed sender, address indexed minter, uint mintAmount, uint mintTokens);
	event Redeem(address indexed sender, address indexed redeemer, uint redeemAmount, uint redeemTokens);
	event Sync(uint totalBalance);
	
	function underlying() external view returns (address);
	function factory() external view returns (address);
	function totalBalance() external view returns (uint);
	function MINIMUM_LIQUIDITY() external pure returns (uint);

	function exchangeRate() external returns (uint);
	function mint(address minter) external returns (uint mintTokens);
	function redeem(address redeemer) external returns (uint redeemAmount);
	function skim(address to) external;
	function sync() external;
	
	function _setFactory() external;
	
	/*** Lending Vault V1 ***/
	
	event AddBorrowable(address indexed borrowable);
	event RemoveBorrowable(address indexed borrowable);
	event EnableBorrowable(address indexed borrowable);
	event DisableBorrowable(address indexed borrowable);
	event UnwindBorrowable(address indexed borrowable, uint256 underlyingBalance, uint256 actualRedeemAmount);
	event AllocateIntoBorrowable(address indexed borrowable, uint256 mintAmount, uint256 mintTokens);
	event DeallocateFromBorrowable(address indexed borrowable, uint256 redeemAmount, uint256 redeemTokens);

	function borrowables(uint) external view returns (address borrowable);
	function borrowableInfo(address borrowable) external view returns (
		bool enabled,
		bool exists
	);
	function getBorrowablesLength() external view returns (uint);
	function indexOfBorrowable(address borrowable) external view returns (uint);

	function reserveFactor() external view returns (uint);
	function exchangeRateLast() external view returns (uint);
	
	function addBorrowable(address borrowable) external;
	function removeBorrowable(address borrowable) external;
	function disableBorrowable(address borrowable) external;
	function enableBorrowable(address borrowable) external;
	function unwindBorrowable(address borrowable) external;
	
	function reallocate() external;
		
	/*** Lending Vault Setter ***/

	event NewReserveFactor(uint newReserveFactor);

	function RESERVE_FACTOR_MAX() external pure returns (uint);
	
	function _initialize (
		address _underlying,
		string calldata _name,
		string calldata _symbol
	) external;
	function _setReserveFactor(uint newReserveFactor) external;
}

// File: contracts\interfaces\IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: contracts\libraries\SafeMath.sol

pragma solidity =0.5.16;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts\libraries\Math.sol

pragma solidity =0.5.16;

// a library for performing various math operations
// forked from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/libraries/Math.sol

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: contracts\interfaces\IBorrowable.sol

pragma solidity >=0.5.0;

interface IBorrowable {

	/*** Impermax ERC20 ***/
	
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	
	function name() external pure returns (string memory);
	function symbol() external pure returns (string memory);
	function decimals() external pure returns (uint8);
	function totalSupply() external view returns (uint);
	function balanceOf(address owner) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint value) external returns (bool);
	function transfer(address to, uint value) external returns (bool);
	function transferFrom(address from, address to, uint value) external returns (bool);
	
	function DOMAIN_SEPARATOR() external view returns (bytes32);
	function PERMIT_TYPEHASH() external pure returns (bytes32);
	function nonces(address owner) external view returns (uint);
	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
	
	/*** Pool Token ***/
	
	event Mint(address indexed sender, address indexed minter, uint mintAmount, uint mintTokens);
	event Redeem(address indexed sender, address indexed redeemer, uint redeemAmount, uint redeemTokens);
	event Sync(uint totalBalance);
	
	function underlying() external view returns (address);
	function factory() external view returns (address);
	function totalBalance() external view returns (uint);
	function MINIMUM_LIQUIDITY() external pure returns (uint);

	function exchangeRate() external returns (uint);
	function mint(address minter) external returns (uint mintTokens);
	function redeem(address redeemer) external returns (uint redeemAmount);
	function skim(address to) external;
	function sync() external;
	
	function _setFactory() external;
	
	/*** Borrowable ***/

	event BorrowApproval(address indexed owner, address indexed spender, uint value);
	event Borrow(address indexed sender, address indexed borrower, address indexed receiver, uint borrowAmount, uint repayAmount, uint accountBorrowsPrior, uint accountBorrows, uint totalBorrows);
	event Liquidate(address indexed sender, address indexed borrower, address indexed liquidator, uint seizeTokens, uint repayAmount, uint accountBorrowsPrior, uint accountBorrows, uint totalBorrows);
	
	function BORROW_FEE() external pure returns (uint);
	function collateral() external view returns (address);
	function reserveFactor() external view returns (uint);
	function exchangeRateLast() external view returns (uint);
	function borrowIndex() external view returns (uint);
	function totalBorrows() external view returns (uint);
	function borrowAllowance(address owner, address spender) external view returns (uint);
	function borrowBalance(address borrower) external view returns (uint);	
	function borrowTracker() external view returns (address);
	
	function BORROW_PERMIT_TYPEHASH() external pure returns (bytes32);
	function borrowApprove(address spender, uint256 value) external returns (bool);
	function borrowPermit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
	function borrow(address borrower, address receiver, uint borrowAmount, bytes calldata data) external;
	function liquidate(address borrower, address liquidator) external returns (uint seizeTokens);
	function trackBorrow(address borrower) external;
	
	/*** Borrowable Interest Rate Model ***/

	event AccrueInterest(uint interestAccumulated, uint borrowIndex, uint totalBorrows);
	event CalculateKink(uint kinkRate);
	event CalculateBorrowRate(uint borrowRate);
	
	function KINK_BORROW_RATE_MAX() external pure returns (uint);
	function KINK_BORROW_RATE_MIN() external pure returns (uint);
	function KINK_MULTIPLIER() external pure returns (uint);
	function borrowRate() external view returns (uint);
	function kinkBorrowRate() external view returns (uint);
	function kinkUtilizationRate() external view returns (uint);
	function adjustSpeed() external view returns (uint);
	function rateUpdateTimestamp() external view returns (uint32);
	function accrualTimestamp() external view returns (uint32);
	
	function accrueInterest() external;
	
	/*** Borrowable Setter ***/

	event NewReserveFactor(uint newReserveFactor);
	event NewKinkUtilizationRate(uint newKinkUtilizationRate);
	event NewAdjustSpeed(uint newAdjustSpeed);
	event NewBorrowTracker(address newBorrowTracker);

	function RESERVE_FACTOR_MAX() external pure returns (uint);
	function KINK_UR_MIN() external pure returns (uint);
	function KINK_UR_MAX() external pure returns (uint);
	function ADJUST_SPEED_MIN() external pure returns (uint);
	function ADJUST_SPEED_MAX() external pure returns (uint);
	
	function _initialize (
		string calldata _name, 
		string calldata _symbol,
		address _underlying, 
		address _collateral
	) external;
	function _setReserveFactor(uint newReserveFactor) external;
	function _setKinkUtilizationRate(uint newKinkUtilizationRate) external;
	function _setAdjustSpeed(uint newAdjustSpeed) external;
	function _setBorrowTracker(address newBorrowTracker) external;
}

// File: contracts\libraries\BorrowableObject.sol

pragma solidity =0.5.16;
pragma experimental ABIEncoderV2;
library BorrowableObject {
	using SafeMath for uint;
	using BorrowableObject for Borrowable;

	struct Borrowable {
		IBorrowable borrowableContract;
		uint exchangeRate;
		uint totalBorrows;       // in underlyings
		uint externalSupply;     // in underlyings
		uint initialOwnedSupply; // in underlyings
		uint ownedSupply;        // in underlyings
		uint kinkBorrowRate;
		uint kinkUtilizationRate;
		uint reserveFactor;
		uint kinkMultiplier;
		uint cachedSupplyRate;
	}

	function newBorrowable(IBorrowable borrowableContract, address lendingVault) internal returns (Borrowable memory borrowable) {
		borrowableContract.sync();
		uint exchangeRate = borrowableContract.exchangeRate();
		uint totalSupplyInTokens = borrowableContract.totalSupply();
		uint ownedSupplyInTokens = borrowableContract.balanceOf(lendingVault);
		uint externalSupplyInTokens = totalSupplyInTokens.sub(ownedSupplyInTokens);
		borrowable = Borrowable({
			borrowableContract: borrowableContract,
			exchangeRate: exchangeRate,
			totalBorrows: borrowableContract.totalBorrows(),
			externalSupply: externalSupplyInTokens.mul(exchangeRate).div(1e18),
			initialOwnedSupply: ownedSupplyInTokens.mul(exchangeRate).div(1e18),
			ownedSupply: ownedSupplyInTokens.mul(exchangeRate).div(1e18),
			kinkBorrowRate: borrowableContract.kinkBorrowRate(),
			kinkUtilizationRate: borrowableContract.kinkUtilizationRate(),
			reserveFactor: borrowableContract.reserveFactor(),
			kinkMultiplier: borrowableContract.KINK_MULTIPLIER(),
			cachedSupplyRate: 0
		});
		borrowable.cachedSupplyRate = supplyRate(borrowable);
		return borrowable;
	}

	function totalSupply(Borrowable memory borrowable) internal pure returns (uint) {
		return borrowable.externalSupply.add(borrowable.ownedSupply);
	}

	function utilizationRate(Borrowable memory borrowable) internal pure returns (uint) {
		uint _totalSupply = totalSupply(borrowable);
		if (_totalSupply == 0) return 0;
		return borrowable.totalBorrows.mul(1e18).div(_totalSupply);
	}

	function kinkRate(Borrowable memory borrowable) internal pure returns (uint) {
		return borrowable.kinkUtilizationRate
			.mul(borrowable.kinkBorrowRate).div(1e18)
			.mul(uint(1e18).sub(borrowable.reserveFactor)).div(1e18);
	}

	function supplyRate(Borrowable memory borrowable) internal pure returns (uint rate) {
		uint utilizationRate_ = utilizationRate(borrowable);
		uint ratio = utilizationRate_.mul(1e18).div(borrowable.kinkUtilizationRate);
		uint borrowFactor; //borrowRate to kinkBorrowRate ratio
		if (utilizationRate_ < borrowable.kinkUtilizationRate) {
			borrowFactor = ratio;
		} else {
			uint excessRatio = utilizationRate_.sub(borrowable.kinkUtilizationRate)
				.mul(1e18).div(uint(1e18).sub(borrowable.kinkUtilizationRate));
			borrowFactor = excessRatio.mul(borrowable.kinkMultiplier.sub(1)).add(1e18);
		}
		rate = borrowFactor.mul(kinkRate(borrowable)).div(1e18).mul(ratio).div(1e18);
	}

	function allocate(Borrowable memory borrowable, uint amount) internal pure returns (Borrowable memory) {
		borrowable.ownedSupply = borrowable.ownedSupply.add(amount);
		borrowable.cachedSupplyRate = supplyRate(borrowable);
		return borrowable;
	}

	function deallocate(Borrowable memory borrowable, uint amount) internal pure returns (Borrowable memory) {
		uint availableLiquidity = totalSupply(borrowable).sub(borrowable.totalBorrows, "ERROR: NEGATIVE AVAILABLE LIQUIDITY");
		require(amount <= availableLiquidity, "ERROR: DEALLOCATE AMOUNT > AVAILABLE LIQUIDITY");
		borrowable.ownedSupply = borrowable.ownedSupply.sub(amount);
		borrowable.cachedSupplyRate = supplyRate(borrowable);
		return borrowable;
	}

	function deallocateMax(Borrowable memory borrowable) internal pure returns (Borrowable memory, uint) {
		if (totalSupply(borrowable) < borrowable.totalBorrows) return (borrowable, 0);
		uint availableLiquidity = totalSupply(borrowable).sub(borrowable.totalBorrows);
		uint amount = Math.min(borrowable.ownedSupply, availableLiquidity);
		return (deallocate(borrowable, amount), amount);
	}

	function calculateUtilizationForRate(Borrowable memory borrowable, uint rate) internal pure returns (uint targetUtilizationRate) {
		if (rate <= kinkRate(borrowable)) {
			targetUtilizationRate = Math.sqrt(
				rate.mul(1e18).div(kinkRate(borrowable)).mul(1e18)
			).mul(borrowable.kinkUtilizationRate).div(1e18);
		} else {
			uint a = borrowable.kinkMultiplier.sub(1);
			uint b = borrowable.kinkUtilizationRate.mul(borrowable.kinkMultiplier).sub(1e18);
			uint c = rate.mul(borrowable.kinkUtilizationRate).div(1e18)
				.mul(uint(1e18).sub(borrowable.kinkUtilizationRate)).div(kinkRate(borrowable));
			uint tmp = Math.sqrt(
				b.mul(b).div(1e18).add(a.mul(c).mul(4)).mul(1e18)
			);
			targetUtilizationRate = tmp.add(b).div(a).div(2);
		}
		require(targetUtilizationRate <= 1e18, "ERROR: TARGET UTILIZATION > 100%");
	}

	function calculateAmountForRate(Borrowable memory borrowable, uint rate) internal pure returns (uint) {
		require(rate > 0, "ERROR: rate = 0");
		require(rate <= borrowable.cachedSupplyRate, "ERROR: TARGET RATE > CACHED RATE");
		uint targetUtilizationRate = calculateUtilizationForRate(borrowable, rate);
		require(targetUtilizationRate <= utilizationRate(borrowable), "ERROR: TARGET UTILIZATION > CURRENT UTILIZATION");
		uint targetSupply = borrowable.totalBorrows.mul(1e18).div(targetUtilizationRate);
		return targetSupply.sub(totalSupply(borrowable), "ERROR: TARGET SUPPLY > TOTAL SUPPLY");
	}

	function compare(Borrowable memory borrowableA, Borrowable memory borrowableB) internal pure returns (bool) {
		return borrowableA.cachedSupplyRate > borrowableB.cachedSupplyRate;
	}
}

// File: contracts\LendingVaultWatcher01.sol

pragma solidity =0.5.16;
contract LendingVaultWatcher01 {	
	using SafeMath for uint;
	using BorrowableObject for BorrowableObject.Borrowable;

	function getAvailableLiquidity(address vault) external returns (uint availableLiquidity) {
		uint borrowablesLength = ILendingVaultV1(vault).getBorrowablesLength();
		address underlying = ILendingVaultV1(vault).underlying();
		for (uint i = 0; i < borrowablesLength; i++) {
			address borrowable = ILendingVaultV1(vault).borrowables(i);
			BorrowableObject.Borrowable memory borrowableObject = BorrowableObject.newBorrowable(IBorrowable(borrowable), vault);
			uint suppliedAmount = borrowableObject.ownedSupply;
			uint liquidity = IERC20(underlying).balanceOf(borrowable);
			availableLiquidity += Math.min(suppliedAmount, liquidity);
		}
	}

	function getSupplyRate(address vault) external returns (uint supplyRate) {
		uint borrowablesLength = ILendingVaultV1(vault).getBorrowablesLength();
		uint reserveFactor = ILendingVaultV1(vault).reserveFactor();
		uint totalSuppliedAmount;
		uint totalProfitsPerSecond;
		for (uint i = 0; i < borrowablesLength; i++) {
			address borrowable = ILendingVaultV1(vault).borrowables(i);
			BorrowableObject.Borrowable memory borrowableObject = BorrowableObject.newBorrowable(IBorrowable(borrowable), vault);
			uint borrowableRate = borrowableObject.cachedSupplyRate;
			uint suppliedAmount = borrowableObject.ownedSupply;
			totalSuppliedAmount += suppliedAmount;
			totalProfitsPerSecond += borrowableRate * suppliedAmount;
		}
		return totalProfitsPerSecond / totalSuppliedAmount * (uint(1e18).sub(reserveFactor)) / 1e18;
	}
}