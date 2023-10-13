/**
 *Submitted for verification at Arbiscan.io on 2023-10-12
*/

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

// File: contracts\ImpermaxERC20.sol

pragma solidity =0.5.16;


// This contract is basically UniswapV2ERC20 with small modifications
// src: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol

contract ImpermaxERC20 {
	using SafeMath for uint;
	
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	uint public totalSupply;
	mapping(address => uint) public balanceOf;
	mapping(address => mapping(address => uint)) public allowance;
	
	bytes32 public DOMAIN_SEPARATOR;
	mapping(address => uint) public nonces;
	
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);

	constructor() public {}	
	
	function _setName(string memory _name, string memory _symbol) internal {
		name = _name;
		symbol = _symbol;
		uint chainId;
		assembly {
			chainId := chainid
		}
		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
				keccak256(bytes(_name)),
				keccak256(bytes("1")),
				chainId,
				address(this)
			)
		);
	}

	function _mint(address to, uint value) internal {
		totalSupply = totalSupply.add(value);
		balanceOf[to] = balanceOf[to].add(value);
		emit Transfer(address(0), to, value);
	}

	function _burn(address from, uint value) internal {
		balanceOf[from] = balanceOf[from].sub(value);
		totalSupply = totalSupply.sub(value);
		emit Transfer(from, address(0), value);
	}

	function _approve(address owner, address spender, uint value) private {
		allowance[owner][spender] = value;
		emit Approval(owner, spender, value);
	}

	function _transfer(address from, address to, uint value) internal {
		balanceOf[from] = balanceOf[from].sub(value, "Impermax: TRANSFER_TOO_HIGH");
		balanceOf[to] = balanceOf[to].add(value);
		emit Transfer(from, to, value);
	}

	function approve(address spender, uint value) external returns (bool) {
		_approve(msg.sender, spender, value);
		return true;
	}

	function transfer(address to, uint value) external returns (bool) {
		_transfer(msg.sender, to, value);
		return true;
	}

	function transferFrom(address from, address to, uint value) external returns (bool) {
		if (allowance[from][msg.sender] != uint(-1)) {
			allowance[from][msg.sender] = allowance[from][msg.sender].sub(value, "Impermax: TRANSFER_NOT_ALLOWED");
		}
		_transfer(from, to, value);
		return true;
	}
	
	function _checkSignature(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s, bytes32 typehash) internal {
		require(deadline >= block.timestamp, "Impermax: EXPIRED");
		bytes32 digest = keccak256(
			abi.encodePacked(
				'\x19\x01',
				DOMAIN_SEPARATOR,
				keccak256(abi.encode(typehash, owner, spender, value, nonces[owner]++, deadline))
			)
		);
		address recoveredAddress = ecrecover(digest, v, r, s);
		require(recoveredAddress != address(0) && recoveredAddress == owner, "Impermax: INVALID_SIGNATURE");	
	}

	// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
		_checkSignature(owner, spender, value, deadline, v, r, s, PERMIT_TYPEHASH);
		_approve(owner, spender, value);
	}
}

// File: contracts\interfaces\IPoolToken.sol

pragma solidity >=0.5.0;

interface IPoolToken {

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
}

// File: contracts\libraries\SafeToken.sol

pragma solidity =0.5.16;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call.value(value)(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

// File: contracts\PoolToken.sol

pragma solidity =0.5.16;




contract PoolToken is IPoolToken, ImpermaxERC20 {
	using SafeToken for address;
	
   	uint internal constant initialExchangeRate = 1e18;
	address public underlying;
	address public factory;
	uint public totalBalance;
	uint public constant MINIMUM_LIQUIDITY = 1000;
	
	event Mint(address indexed sender, address indexed minter, uint mintAmount, uint mintTokens);
	event Redeem(address indexed sender, address indexed redeemer, uint redeemAmount, uint redeemTokens);
	event Sync(uint totalBalance);
	
	/*** Initialize ***/
	
	// called once by the factory
	function _setFactory() external {
		require(factory == address(0), "Impermax: FACTORY_ALREADY_SET");
		factory = msg.sender;
	}
	
	/*** PoolToken ***/
	
	function _update() internal {
		totalBalance = underlying.myBalance();
		emit Sync(totalBalance);
	}

	function exchangeRate() public returns (uint) 
	{
		uint _totalSupply = totalSupply; // gas savings
		uint _totalBalance = totalBalance; // gas savings
		if (_totalSupply == 0 || _totalBalance == 0) return initialExchangeRate;
		return _totalBalance.mul(1e18).div(_totalSupply);
	}
	
	// this low-level function should be called from another contract
	function mint(address minter) external nonReentrant update returns (uint mintTokens) {
		uint balance = underlying.myBalance();
		uint mintAmount = balance.sub(totalBalance);
		mintTokens = mintAmount.mul(1e18).div(exchangeRate());

		if(totalSupply == 0) {
			// permanently lock the first MINIMUM_LIQUIDITY tokens
			mintTokens = mintTokens.sub(MINIMUM_LIQUIDITY);
			_mint(address(0), MINIMUM_LIQUIDITY);
		}
		require(mintTokens > 0, "Impermax: MINT_AMOUNT_ZERO");
		_mint(minter, mintTokens);
		emit Mint(msg.sender, minter, mintAmount, mintTokens);
	}

	// this low-level function should be called from another contract
	function redeem(address redeemer) external nonReentrant update returns (uint redeemAmount) {
		uint redeemTokens = balanceOf[address(this)];
		redeemAmount = redeemTokens.mul(exchangeRate()).div(1e18);

		require(redeemAmount > 0, "Impermax: REDEEM_AMOUNT_ZERO");
		require(redeemAmount <= totalBalance, "Impermax: INSUFFICIENT_CASH");
		_burn(address(this), redeemTokens);
		underlying.safeTransfer(redeemer, redeemAmount);
		emit Redeem(msg.sender, redeemer, redeemAmount, redeemTokens);		
	}

	// force real balance to match totalBalance
	function skim(address to) external nonReentrant {
		underlying.safeTransfer(to, underlying.myBalance().sub(totalBalance));
	}

	// force totalBalance to match real balance
	function sync() external nonReentrant update {}
	
	/*** Utilities ***/
	
	// prevents a contract from calling itself, directly or indirectly.
	bool internal _notEntered = true;
	modifier nonReentrant() {
		require(_notEntered, "Impermax: REENTERED");
		_notEntered = false;
		_;
		_notEntered = true;
	}
	
	// update totalBalance with current balance
	modifier update() {
		_;
		_update();
	}
}

// File: contracts\LVStorageV1.sol

pragma solidity =0.5.16;

contract LVStorageV1 {
	address[] public borrowables;
	struct BorrowableInfo {
		bool enabled;
		bool exists;
	}
	mapping(address => BorrowableInfo) public borrowableInfo;
	function getBorrowablesLength() external view returns (uint) {
		return borrowables.length;
	}
	function indexOfBorrowable(address borrowable) public view returns (uint) {
		for (uint i = 0; i < borrowables.length; i++) {
			if (borrowables[i] == borrowable) {
				return i;
			}
		}
		require(false, "LendingVaultV1: BORROWABLE_NOT_FOUND");
	}

	uint public exchangeRateLast;

	uint public reserveFactor = 0.10e18; //10%
}

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
	
	/*** Lending Aggregator V1 ***/
	
	event AddBorrowable(address indexed borrowable);
	event RemoveBorrowable(address indexed borrowable);
	event EnableBorrowable(address indexed borrowable);
	event DisableBorrowable(address indexed borrowable);
	event UnwindBorrowable(address indexed borrowable, uint256 redeemAmount, uint256 actualRedeemAmount);
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
	
	/*** Borrowable Interest Rate Model ***/
	
	/*** Borrowable Setter ***/

	event NewReserveFactor(uint newReserveFactor);

	function RESERVE_FACTOR_MAX() external pure returns (uint);
	
	function _initialize (
		address _underlying,
		string calldata _name,
		string calldata _symbol
	) external;
	function _setReserveFactor(uint newReserveFactor) external;
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

// File: contracts\libraries\BorrowableHelpers.sol

pragma solidity =0.5.16;




library BorrowableHelpers {
	using SafeMath for uint256;

	function borrowableValueOf(address borrowable, uint256 underlyingAmount) internal returns (uint256) {
		uint256 exchangeRate = IBorrowable(borrowable).exchangeRate();
		return underlyingAmount.mul(1e18).div(exchangeRate);
	}

	function underlyingValueOf(address borrowable, uint256 borrowableAmount) internal returns (uint256) {
		uint256 exchangeRate = IBorrowable(borrowable).exchangeRate();
		return borrowableAmount.mul(exchangeRate).div(1e18);
	}

	function underlyingBalanceOf(address borrowable, address account) internal returns (uint256) {
		return underlyingValueOf(borrowable, IBorrowable(borrowable).balanceOf(account));
	}

	function myUnderlyingBalance(address borrowable) internal returns (uint256) {
		return underlyingValueOf(borrowable, IBorrowable(borrowable).balanceOf(address(this)));
	}
	
	/*** AMOUNT TO TOKENS CONVERSION ***/
	
	/*** V1 ***/
	
	function tokensFor(uint redeemAmount, uint exchangeRate, bool atMost) internal pure returns (uint redeemTokens) {
		uint redeemTokensLow = redeemAmount.mul(1e18).div(exchangeRate);
		uint redeemTokensHigh = redeemTokensLow.add(1);
		uint actualRedeemAmountLow = redeemTokensLow.mul(exchangeRate).div(1e18);
		uint actualRedeemAmountHigh = redeemTokensHigh.mul(exchangeRate).div(1e18);
		
		if (atMost) {
			return actualRedeemAmountHigh <= redeemAmount ? redeemTokensHigh : redeemTokensLow;
		} else {
			return actualRedeemAmountLow >= redeemAmount ? redeemTokensLow : redeemTokensHigh;
		}
	}
	
	function tokensForAtMost(uint redeemAmount, uint exchangeRate) internal pure returns (uint redeemTokens) {
		return tokensFor(redeemAmount, exchangeRate, true);
	}
	
	function tokensForAtLeast(uint redeemAmount, uint exchangeRate) internal pure returns (uint redeemTokens) {
		return tokensFor(redeemAmount, exchangeRate, false);
	}
	
	/*** V2 ***/
/*
	function tokensForAtMost(uint redeemAmount, uint exchangeRate) internal pure returns (uint redeemTokens) {
		uint y = redeemAmount.mul(1e18).div(exchangeRate).mul(exchangeRate).mod(1e18).add(exchangeRate).div(1e18);
		uint adjX = redeemAmount.mul(1e18).mod(exchangeRate).mod(1e18) == 0 ? 0 : 1;
		uint x = redeemAmount.mul(1e18).mod(exchangeRate).div(1e18).add(adjX);
		uint adjustment = y <= x ? 1 : 0;
		redeemTokens = redeemAmount.mul(1e18).div(exchangeRate).add(adjustment);
	}

	function tokensForAtLeast(uint redeemAmount, uint exchangeRate) internal pure returns (uint redeemTokens) {
		uint adjustment = redeemAmount.mul(1e18).mod(exchangeRate) == 0 ? 0 : 1;
		redeemTokens = redeemAmount.mul(1e18).div(exchangeRate).add(adjustment);
	}*/
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

// File: contracts\libraries\BorrowableObject.sol

pragma solidity =0.5.16;
pragma experimental ABIEncoderV2;




// TODO: IN GENERALE DEVO CONTROLLARE TUTTA LA MATEMATIC PER CONVERSIONE TOKEN AMOUNT E IN GENERALE CHECKARE CHE NON CI SIANO ERRORI CHE POSSANO SALTARE FUORI IN CASISTICHE PARTICOLARI (PER QUANTO RIGUARDA ALGORITMO REALLOCATE)

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
		uint cachedSupplyAPR;
	}

	function newBorrowable(IBorrowable borrowableContract) internal returns (Borrowable memory borrowable) {
		borrowableContract.sync();
		uint exchangeRate = borrowableContract.exchangeRate();
		uint totalSupplyInTokens = borrowableContract.totalSupply();
		uint ownedSupplyInTokens = borrowableContract.balanceOf(address(this));
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
			cachedSupplyAPR: 0
		});
		borrowable.cachedSupplyAPR = supplyAPR(borrowable);
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

	function kinkAPR(Borrowable memory borrowable) internal pure returns (uint) {
		return borrowable.kinkUtilizationRate
			.mul(borrowable.kinkBorrowRate).div(1e18)
			.mul(uint(1e18).sub(borrowable.reserveFactor)).div(1e18);
	}

	function supplyAPR(Borrowable memory borrowable) internal pure returns (uint APR) {
		uint utilizationRate_ = utilizationRate(borrowable);
		if (utilizationRate_ < borrowable.kinkUtilizationRate) {
			uint ratio = utilizationRate_.mul(1e18).div(borrowable.kinkUtilizationRate);
			APR = ratio.mul(ratio).div(1e18).mul(kinkAPR(borrowable)).div(1e18);
		} else {
			APR = utilizationRate_.sub(borrowable.kinkUtilizationRate)
				.mul(1e18).div(uint(1e18).sub(borrowable.kinkUtilizationRate))
				.mul(borrowable.kinkMultiplier.sub(1))
				.add(1e18)
				.mul(kinkAPR(borrowable)).div(1e18);
		}
	}

	function allocate(Borrowable memory borrowable, uint amount) internal pure returns (Borrowable memory) {
		borrowable.ownedSupply = borrowable.ownedSupply.add(amount);
		borrowable.cachedSupplyAPR = supplyAPR(borrowable);
		return borrowable;
	}

	function deallocate(Borrowable memory borrowable, uint amount) internal pure returns (Borrowable memory) {
		borrowable.ownedSupply = borrowable.ownedSupply.sub(amount);
		borrowable.cachedSupplyAPR = supplyAPR(borrowable);
		return borrowable;
	}

	function deallocateMax(Borrowable memory borrowable) internal pure returns (Borrowable memory, uint) {
		uint amount = borrowable.externalSupply >= borrowable.totalBorrows
			? borrowable.ownedSupply
			: totalSupply(borrowable).sub(borrowable.totalBorrows); // TODO CAPIRE COSA SUCCEDE ESATTAMENTE IN QUESTO CALCOLO
		return (deallocate(borrowable, amount), amount);
	}

	function calculateAmountForAPR(Borrowable memory borrowable, uint APR) internal pure returns (uint) {
		require(APR > 0, "ERROR: APR = 0");
		require(APR <= borrowable.cachedSupplyAPR, "ERROR: TARGET APR > CACHED APR");
		uint targetUtilizationRate;
		if (APR <= kinkAPR(borrowable)) {
			targetUtilizationRate = Math.sqrt(
				APR.mul(1e18).div(kinkAPR(borrowable)).mul(1e18)
			).mul(borrowable.kinkUtilizationRate).div(1e18);
		} else {
			uint tmp = APR.mul(1e18).div(kinkAPR(borrowable))
				.sub(1e18)
				.mul(uint(1e18).sub(borrowable.kinkUtilizationRate)).div(1e18);
			targetUtilizationRate = tmp
				.div(borrowable.kinkMultiplier.sub(1))
				.add(borrowable.kinkUtilizationRate);
		}
		require(targetUtilizationRate <= utilizationRate(borrowable), "ERROR: TARGET UTILIZATION > CURRENT UTILIZATION");
		uint targetSupply = borrowable.totalBorrows.mul(1e18).div(targetUtilizationRate);
		return targetSupply.sub(totalSupply(borrowable), "ERROR: TARGET SUPPLY > TOTAL SUPPLY");
	}

	function compare(Borrowable memory borrowableA, Borrowable memory borrowableB) internal pure returns (bool) {
		return borrowableA.cachedSupplyAPR > borrowableB.cachedSupplyAPR;
	}
}

// File: contracts\LVAllocatorV1.sol

pragma solidity =0.5.16;






contract LVAllocatorV1 is ILendingVaultV1, PoolToken, LVStorageV1 {
	using BorrowableHelpers for address;
	using BorrowableObject for BorrowableObject.Borrowable;
	
	function _allocate(IBorrowable borrowable, uint mintAmount) internal returns (uint mintTokens) {
		underlying.safeTransfer(address(borrowable), mintAmount);
		mintTokens = borrowable.mint(address(this));

		emit AllocateIntoBorrowable(address(borrowable), mintAmount, mintTokens);
	}

	function _deallocate(IBorrowable borrowable, uint redeemTokens) internal returns (uint redeemAmount) {
		address(borrowable).safeTransfer(address(borrowable), redeemTokens);
		redeemAmount = borrowable.redeem(address(this));

		emit DeallocateFromBorrowable(address(borrowable), redeemAmount, redeemTokens);
	}
	
	function _deallocateAtMost(IBorrowable borrowable, uint redeemAmount, uint _exchangeRate) internal returns (uint actualRedeemAmount) {
		actualRedeemAmount = _deallocate(IBorrowable(borrowable), BorrowableHelpers.tokensForAtMost(redeemAmount, _exchangeRate));
		require(actualRedeemAmount <= redeemAmount, "LendingVaultV1: DEALLOCATED_TOO_MUCH");
	}
	function _deallocateAtMost(IBorrowable borrowable, uint redeemAmount) internal returns (uint actualRedeemAmount) {
		actualRedeemAmount = _deallocateAtMost(borrowable, redeemAmount, borrowable.exchangeRate());
	}
	
	function _deallocateAtLeast(IBorrowable borrowable, uint redeemAmount, uint _exchangeRate) internal returns (uint actualRedeemAmount) {
		actualRedeemAmount = _deallocate(IBorrowable(borrowable), BorrowableHelpers.tokensForAtLeast(redeemAmount, _exchangeRate));
		require(actualRedeemAmount >= redeemAmount, "LendingVaultV1: DEALLOCATED_NOT_ENOUGH");
	}
	function _deallocateAtLeast(IBorrowable borrowable, uint redeemAmount) internal returns (uint actualRedeemAmount) {
		actualRedeemAmount = _deallocateAtLeast(borrowable, redeemAmount, borrowable.exchangeRate());
	}

	function _withdrawAndReallocate(uint withdrawAmount) internal {
		BorrowableObject.Borrowable[] memory borrowablesObj = new BorrowableObject.Borrowable[](borrowables.length);
		uint borrowablesLength = borrowables.length;
		for(uint i = 0; i < borrowables.length; i++) {
			if (!borrowableInfo[borrowables[i]].enabled) {
				borrowablesLength--;
				continue;
			}
			uint delta = uint(borrowables.length).sub(borrowablesLength);
			borrowablesObj[i - delta] = BorrowableObject.newBorrowable(IBorrowable(borrowables[i]));
		}
		
		// deallocate everything
		uint amountToAllocate = underlying.myBalance();
		for(uint i = 0; i < borrowablesLength; i++) {
			uint amount;
			(borrowablesObj[i], amount) = borrowablesObj[i].deallocateMax();
			amountToAllocate = amountToAllocate.add(amount);
		}
		amountToAllocate = amountToAllocate.sub(withdrawAmount, "LendingVaultV1: INSUFFICIENT_LIQUIDITY");
		
		// bubblesort borrowablesObj
		for (uint i = 0; i < borrowablesLength - 1; i++) {
			for (uint j = 0; j < borrowablesLength - 1 - i; j++) {
				if (!borrowablesObj[j].compare(borrowablesObj[j+1])) {
					BorrowableObject.Borrowable memory tmp = borrowablesObj[j];
					borrowablesObj[j] = borrowablesObj[j+1];
					borrowablesObj[j+1] = tmp;
				}
			}
		}

		// Allocate in the pool with the highest APR an amount such that the next APR matches the one
		// of the pool with the second highest APR.
		// Repeat until all the pools with the highest APR has the same APR.
		uint lastCycle = borrowablesLength;
		for(uint i = 1; i < borrowablesLength; i++) {
			uint targetAPR = borrowablesObj[i].cachedSupplyAPR;
			uint amountThisCycle = 0;
			uint[] memory amounts = new uint[](i);
			if (targetAPR == 0) {
				// Unachievable APR
				lastCycle = i;
				break;
			}
			for (uint j = 0; j < i; j++) {
				if (borrowablesObj[j].cachedSupplyAPR <= targetAPR) break;
				amounts[j] = borrowablesObj[j].calculateAmountForAPR(targetAPR);
				amountThisCycle = amountThisCycle.add(amounts[j]);
			}
			if (amountThisCycle > amountToAllocate) {
				// We can't afford to complete this cycle
				lastCycle = i;
				break;
			}
			for (uint j = 0; j < i; j++) {
				if (amounts[j] == 0) continue;
				borrowablesObj[j] = borrowablesObj[j].allocate(amounts[j]);
				amountToAllocate = amountToAllocate.sub(amounts[j]);
			}
		}

		// distribute the amount left equally among pools with highest APR proportionally to their total supply
		uint globalTotalSupply = 0;
		uint totalAmountToAllocate = amountToAllocate;
		for (uint i = 0; i < lastCycle; i++) {
			globalTotalSupply = globalTotalSupply.add(borrowablesObj[i].totalSupply());
		}
		for (uint i = 0; i < lastCycle; i++) {
			uint amount = globalTotalSupply > 0 
				? borrowablesObj[i].totalSupply().mul(totalAmountToAllocate).div(globalTotalSupply)
				: amountToAllocate;
			if (amount > amountToAllocate) amount = amountToAllocate;
			borrowablesObj[i] = borrowablesObj[i].allocate(amount);
			amountToAllocate = amountToAllocate.sub(amount);
		}
		
		// redeem
		for(uint i = 0; i < borrowablesLength; i++) {
			if (borrowablesObj[i].ownedSupply < borrowablesObj[i].initialOwnedSupply) {
				// DEALLOCATE AT LEAST IS WRONG IN THE CASE WE ARE WITHDRAWING ALL THE  AVAILABLE LIQUIDITY
				uint redeemAmount = borrowablesObj[i].initialOwnedSupply.sub(borrowablesObj[i].ownedSupply);
				_deallocateAtMost(borrowablesObj[i].borrowableContract, redeemAmount, borrowablesObj[i].exchangeRate);
			}
		}
		// mint
		amountToAllocate = underlying.myBalance();
		for(uint i = 0; i < borrowablesLength; i++) {
			if (borrowablesObj[i].ownedSupply > borrowablesObj[i].initialOwnedSupply) {
				uint mintAmount = borrowablesObj[i].ownedSupply.sub(borrowablesObj[i].initialOwnedSupply);
				if (mintAmount > amountToAllocate) mintAmount = amountToAllocate;
				amountToAllocate = amountToAllocate.sub(mintAmount);
				_allocate(borrowablesObj[i].borrowableContract, mintAmount);
			}
		}
		
		/*// redeem
		for(uint i = 0; i < borrowablesLength; i++) {
			if (borrowablesObj[i].ownedSupply < borrowablesObj[i].initialOwnedSupply) {
				// DEALLOCATE AT LEAST IS WRONG IN THE CASE WE ARE WITHDRAWING ALL THE  AVAILABLE LIQUIDITY
				uint redeemAmount = borrowablesObj[i].initialOwnedSupply.sub(borrowablesObj[i].ownedSupply);
				_deallocateAtLeast(borrowablesObj[i].borrowableContract, redeemAmount, borrowablesObj[i].exchangeRate);
			}
		}
		// mint
		for(uint i = 0; i < borrowablesLength; i++) {
			if (borrowablesObj[i].ownedSupply > borrowablesObj[i].initialOwnedSupply) {
				uint mintAmount = borrowablesObj[i].ownedSupply.sub(borrowablesObj[i].initialOwnedSupply);
				_allocate(borrowablesObj[i].borrowableContract, mintAmount);
			}
		}*/
		
		// TODO WHICH EVENTS TO EMIT?
	}
}

// File: contracts\interfaces\ILendingVaultV1Factory.sol

pragma solidity >=0.5.0;

interface ILendingVaultV1Factory {
	event VaultCreated(address indexed underlying, address vault, uint);
	event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
	event NewAdmin(address oldAdmin, address newAdmin);
	event NewReservesPendingAdmin(address oldReservesPendingAdmin, address newReservesPendingAdmin);
	event NewReservesAdmin(address oldReservesAdmin, address newReservesAdmin);
	event NewReallocateManager(address oldReallocateManager, address newReallocateManager);
	event NewReservesManager(address oldReservesManager, address newReservesManager);
	
	function admin() external view returns (address);
	function pendingAdmin() external view returns (address);
	//function reallocateManager() external view returns (address);
	function reservesAdmin() external view returns (address);
	function reservesPendingAdmin() external view returns (address);
	function reservesManager() external view returns (address);

	function allVaults(uint) external view returns (address underlying);
	function allVaultsLength() external view returns (uint);

	function createVault(address underlying, string calldata _name, string calldata _symbol) external returns (address vault);

	function _setPendingAdmin(address newPendingAdmin) external;
	function _acceptAdmin() external;
	//function _setReallocateManager(address newReallocateManager) external;
	function _setReservesPendingAdmin(address newPendingAdmin) external;
	function _acceptReservesAdmin() external;
	function _setReservesManager(address newReservesManager) external;
}

// File: contracts\LVSetterV1.sol

pragma solidity =0.5.16;



contract LVSetterV1 is LVAllocatorV1 {

	uint public constant RESERVE_FACTOR_MAX = 0.90e18; //90%

	function _initialize(
		address _underlying,
		string calldata _name,
		string calldata _symbol
	) external {
		require(factory == address(0), "LendingVaultV1: FACTORY_ALREADY_SET"); // sufficient check
		factory = msg.sender;
		_setName(_name, _symbol);
		underlying = _underlying;
		exchangeRateLast = initialExchangeRate;
	}
	
	function _setReserveFactor(uint newReserveFactor) external onlyAdmin nonReentrant {
		require(newReserveFactor <= RESERVE_FACTOR_MAX, "LendingVaultV1: INVALID_SETTING");
		reserveFactor = newReserveFactor;
		emit NewReserveFactor(newReserveFactor);
	}
	
	/*** Borrowables management ***/

	function addBorrowable(address borrowable) external onlyAdmin nonReentrant {
		require(IBorrowable(borrowable).underlying() == underlying, "LendingVaultV1: INVALID_UNDERLYING");
		require(!borrowableInfo[borrowable].exists, "LendingVaultV1: BORROWABLE_EXISTS");

		borrowableInfo[borrowable].exists = true;
		borrowableInfo[borrowable].enabled = true;
		borrowables.push(borrowable);

		emit AddBorrowable(address(borrowable));
	}

	function removeBorrowable(address borrowable) external onlyAdmin nonReentrant {
		require(borrowableInfo[borrowable].exists, "LendingVaultV1: BORROWABLE_DOESNT_EXISTS");
		require(!borrowableInfo[borrowable].enabled, "LendingVaultV1: BORROWABLE_ENABLED");
		require(borrowable.balanceOf(address(this)) == 0, "LendingVaultV1: NOT_EMPTY");

		uint lastIndex = borrowables.length - 1;
		uint index = indexOfBorrowable(borrowable);

		borrowables[index] = borrowables[lastIndex];
		borrowables.pop();
		delete borrowableInfo[borrowable];

		emit RemoveBorrowable(address(borrowable));
	}

	function disableBorrowable(address borrowable) external onlyAdmin nonReentrant {
		require(borrowableInfo[borrowable].exists, "LendingVaultV1: BORROWABLE_DOESNT_EXISTS");
		require(borrowableInfo[borrowable].enabled, "LendingVaultV1: BORROWABLE_DISABLED");

		borrowableInfo[borrowable].enabled = false;

		emit DisableBorrowable(address(borrowable));
	}

	function enableBorrowable(address borrowable) external onlyAdmin nonReentrant {
		require(borrowableInfo[borrowable].exists, "LendingVaultV1: BORROWABLE_DOESNT_EXISTS");
		require(!borrowableInfo[borrowable].enabled, "LendingVaultV1: BORROWABLE_ENABLED");

		borrowableInfo[borrowable].enabled = true;

		emit EnableBorrowable(address(borrowable));
	}

	function unwindBorrowable(address borrowable) external onlyAdmin nonReentrant update {
		require(borrowableInfo[borrowable].exists, "LendingVaultV1: BORROWABLE_DOESNT_EXISTS");
		require(!borrowableInfo[borrowable].enabled, "LendingVaultV1: BORROWABLE_ENABLED");	
		
		uint myBalance = borrowable.myUnderlyingBalance();
		uint availableLiquidity = underlying.balanceOf(address(borrowable));
		uint redeemAmount = Math.min(myBalance, availableLiquidity);
		require(redeemAmount > 0, "LendingVaultV1: ZERO_AMOUNT");
		
		uint actualRedeemAmount = myBalance <= availableLiquidity ? 
			_deallocateAtLeast(IBorrowable(borrowable), redeemAmount) : 
			_deallocateAtMost(IBorrowable(borrowable), redeemAmount);		

		emit UnwindBorrowable(address(borrowable), redeemAmount, actualRedeemAmount);
	}
	
	modifier onlyAdmin() {
		require(msg.sender == ILendingVaultV1Factory(factory).admin(), "LendingVaultV1: UNAUTHORIZED");
		_;
	}
}

// File: contracts\LendingVaultV1.sol

pragma solidity =0.5.16;



contract LendingVaultV1 is LVSetterV1 {

	// TODO QUESTO PU0' ESSERE OTTIMIZZATO PORTANDOSI DIETRO BORROWABLE OBJECT
	function _getTotalSupplied() internal returns (uint totalSupplied) {
		for (uint i = 0; i < borrowables.length; i++) {
			address borrowable = borrowables[i];
			totalSupplied = totalSupplied.add(borrowable.myUnderlyingBalance());
		}
	}
	
	function _mintReserves(uint _exchangeRate, uint _totalSupply) internal returns (uint) {
		uint _exchangeRateLast = exchangeRateLast;
		if (_exchangeRate > _exchangeRateLast) {
			uint _exchangeRateNew = _exchangeRate.sub( _exchangeRate.sub(_exchangeRateLast).mul(reserveFactor).div(1e18) );
			uint liquidity = _totalSupply.mul(_exchangeRate).div(_exchangeRateNew).sub(_totalSupply);
			if (liquidity > 0) {
				address reservesManager = ILendingVaultV1Factory(factory).reservesManager();
				_mint(reservesManager, liquidity);
			}
			exchangeRateLast = _exchangeRateNew;
			return _exchangeRateNew;
		}
		else return _exchangeRate;
	}
	
	function exchangeRate() public returns (uint) {
		uint _totalSupply = totalSupply;
		uint _actualBalance = totalBalance.add(_getTotalSupplied());
		if (_totalSupply == 0 || _actualBalance == 0) return initialExchangeRate;
		uint _exchangeRate = _actualBalance.mul(1e18).div(_totalSupply);
		return _mintReserves(_exchangeRate, _totalSupply);
	}
	
	// this low-level function should be called from another contract
	function mint(address minter) external nonReentrant update returns (uint mintTokens) {
		uint balance = underlying.myBalance();
		uint mintAmount = balance.sub(totalBalance);
		mintTokens = mintAmount.mul(1e18).div(exchangeRate());

		if(totalSupply == 0) {
			// permanently lock the first MINIMUM_LIQUIDITY tokens
			mintTokens = mintTokens.sub(MINIMUM_LIQUIDITY);
			_mint(address(0), MINIMUM_LIQUIDITY);
		}
		require(mintTokens > 0, "Impermax: MINT_AMOUNT_ZERO");
		_mint(minter, mintTokens);
		_withdrawAndReallocate(0);
		emit Mint(msg.sender, minter, mintAmount, mintTokens);
	}

	// this low-level function should be called from another contract
	function redeem(address redeemer) external nonReentrant update returns (uint redeemAmount) {
		uint redeemTokens = balanceOf[address(this)];
		redeemAmount = redeemTokens.mul(exchangeRate()).div(1e18);

		require(redeemAmount > 0, "LendingVaultV1: REDEEM_AMOUNT_ZERO");
		_burn(address(this), redeemTokens);
		_withdrawAndReallocate(redeemAmount);
		underlying.safeTransfer(redeemer, redeemAmount);
		emit Redeem(msg.sender, redeemer, redeemAmount, redeemTokens);		
	}

	function reallocate() external nonReentrant update {
		_withdrawAndReallocate(0);
	}
	
	/*** Utilities ***/
	
	//modifier onlyReallocateManager() {
	//	require(msg.sender == ILendingVaultV1Factory(factory).reallocateManager(), "LendingVaultV1: UNAUTHORIZED");
	//	_;
	//}
}

// File: contracts\interfaces\ILVDeployerV1.sol

pragma solidity >=0.5.0;

interface ILVDeployerV1 {
	function deployVault() external returns (address vault);
}

// File: contracts\LVDeployerV1.sol

pragma solidity =0.5.16;



/*
 * This contract is used by the Factory to deploy LendingVaultV1
 * The bytecode would be too long to fit in the Factory
 */
 
contract LVDeployerV1 is ILVDeployerV1 {
	constructor () public {}
	
	function deployVault() external returns (address vault) {
		vault = address(new LendingVaultV1());
	}
}