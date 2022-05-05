/**
 *Submitted for verification at Arbiscan on 2022-05-05
*/

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface TokenInterface {
	function approve(address, uint256) external;

	function transfer(address, uint256) external;

	function transferFrom(
		address,
		address,
		uint256
	) external;

	function deposit() external payable;

	function withdraw(uint256) external;

	function balanceOf(address) external view returns (uint256);

	function decimals() external view returns (uint256);
}

interface MemoryInterface {
	function getUint(uint256 id) external returns (uint256 num);

	function setUint(uint256 id, uint256 val) external;
}

interface InstaMapping {
	function cTokenMapping(address) external view returns (address);

	function gemJoinMapping(bytes32) external view returns (address);
}

interface AccountInterface {
	function enable(address) external;

	function disable(address) external;

	function isAuth(address) external view returns (bool);
}

abstract contract Stores {
	/**
	 * @dev Return ethereum address
	 */
	address internal constant ethAddr =
		0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

	/**
	 * @dev Return Wrapped ETH address
	 */
	address internal constant wethAddr =
		0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

	/**
	 * @dev Return memory variable address
	 */
	MemoryInterface internal constant instaMemory =
		MemoryInterface(0xc109f7Ef06152c3a63dc7254fD861E612d3Ac571);

	/**
	 * @dev Get Uint value from InstaMemory Contract.
	 */
	function getUint(uint256 getId, uint256 val)
		internal
		returns (uint256 returnVal)
	{
		returnVal = getId == 0 ? val : instaMemory.getUint(getId);
	}

	/**
	 * @dev Set Uint value in InstaMemory Contract.
	 */
	function setUint(uint256 setId, uint256 val) internal virtual {
		if (setId != 0) instaMemory.setUint(setId, val);
	}
}

interface IHopRouter {
	function swapAndSend(
		uint256 chainId,
		address recipient,
		uint256 amount,
		uint256 bonderFee,
		uint256 amountOutMin,
		uint256 deadline,
		uint256 destinationAmountOutMin,
		uint256 destinationDeadline
	) external;
}

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
	 * @dev Returns the addition of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryAdd(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		uint256 c = a + b;
		if (c < a) return (false, 0);
		return (true, c);
	}

	/**
	 * @dev Returns the substraction of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function trySub(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		if (b > a) return (false, 0);
		return (true, a - b);
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryMul(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) return (true, 0);
		uint256 c = a * b;
		if (c / a != b) return (false, 0);
		return (true, c);
	}

	/**
	 * @dev Returns the division of two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryDiv(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		if (b == 0) return (false, 0);
		return (true, a / b);
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryMod(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		if (b == 0) return (false, 0);
		return (true, a % b);
	}

	/**
	 * @dev Returns the addition of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
	 *
	 * - Addition cannot overflow.
	 */
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a, "SafeMath: subtraction overflow");
		return a - b;
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `*` operator.
	 *
	 * Requirements:
	 *
	 * - Multiplication cannot overflow.
	 */
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) return 0;
		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0, "SafeMath: division by zero");
		return a / b;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * reverting when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0, "SafeMath: modulo by zero");
		return a % b;
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
	 *
	 * CAUTION: This function is deprecated because it requires allocating memory for the error
	 * message unnecessarily. For custom revert reasons use {trySub}.
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		return a - b;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting with custom message on
	 * division by zero. The result is rounded towards zero.
	 *
	 * CAUTION: This function is deprecated because it requires allocating memory for the error
	 * message unnecessarily. For custom revert reasons use {tryDiv}.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		return a / b;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * reverting with custom message when dividing by zero.
	 *
	 * CAUTION: This function is deprecated because it requires allocating memory for the error
	 * message unnecessarily. For custom revert reasons use {tryMod}.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		return a % b;
	}
}

contract DSMath {
	uint256 constant WAD = 10**18;
	uint256 constant RAY = 10**27;

	function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(x, y);
	}

	function sub(uint256 x, uint256 y)
		internal
		pure
		virtual
		returns (uint256 z)
	{
		z = SafeMath.sub(x, y);
	}

	function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.mul(x, y);
	}

	function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.div(x, y);
	}

	function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
	}

	function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
	}

	function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
	}

	function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
	}

	function toInt(uint256 x) internal pure returns (int256 y) {
		y = int256(x);
		require(y >= 0, "int-overflow");
	}

	function toRad(uint256 wad) internal pure returns (uint256 rad) {
		rad = mul(wad, 10**27);
	}
}

abstract contract Basic is DSMath, Stores {
	function convert18ToDec(uint256 _dec, uint256 _amt)
		internal
		pure
		returns (uint256 amt)
	{
		amt = (_amt / 10**(18 - _dec));
	}

	function convertTo18(uint256 _dec, uint256 _amt)
		internal
		pure
		returns (uint256 amt)
	{
		amt = mul(_amt, 10**(18 - _dec));
	}

	function getTokenBal(TokenInterface token)
		internal
		view
		returns (uint256 _amt)
	{
		_amt = address(token) == ethAddr
			? address(this).balance
			: token.balanceOf(address(this));
	}

	function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr)
		internal
		view
		returns (uint256 buyDec, uint256 sellDec)
	{
		buyDec = address(buyAddr) == ethAddr ? 18 : buyAddr.decimals();
		sellDec = address(sellAddr) == ethAddr ? 18 : sellAddr.decimals();
	}

	function encodeEvent(string memory eventName, bytes memory eventParam)
		internal
		pure
		returns (bytes memory)
	{
		return abi.encode(eventName, eventParam);
	}

	function approve(
		TokenInterface token,
		address spender,
		uint256 amount
	) internal {
		try token.approve(spender, amount) {} catch {
			token.approve(spender, 0);
			token.approve(spender, amount);
		}
	}

	function changeEthAddress(address buy, address sell)
		internal
		pure
		returns (TokenInterface _buy, TokenInterface _sell)
	{
		_buy = buy == ethAddr ? TokenInterface(wethAddr) : TokenInterface(buy);
		_sell = sell == ethAddr
			? TokenInterface(wethAddr)
			: TokenInterface(sell);
	}

	function convertEthToWeth(
		bool isEth,
		TokenInterface token,
		uint256 amount
	) internal {
		if (isEth) token.deposit{ value: amount }();
	}

	function convertWethToEth(
		bool isEth,
		TokenInterface token,
		uint256 amount
	) internal {
		if (isEth) {
			approve(token, address(token), amount);
			token.withdraw(amount);
		}
	}
}

contract Helpers is DSMath, Basic {
	/**
	 * @param token The address of token to be bridged.(For USDC: 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)
	 * @param targetChainId The Id of the destination chain.(For MAINNET : 1)
	 * @param router The address of hop router.
	 * @param recipient The address to recieve the token on destination chain.
	 * @param amount The total amount sent by user (Includes bonder fee, destination chain Tx cost).
	 * @param bonderFee The fee to be recieved by bonder at destination chain.
	 * @param sourceAmountOutMin minimum amount of token out for swap on source chain.
	 * @param sourceDeadline The deadline for the source chain transaction (Recommended - Date.now() + 604800 (1 week))
	 * @param destinationAmountOutMin minimum amount of token out for bridge on target chain, zero for L1 bridging
	 * @param destinationDeadline The deadline for the target chain transaction (Recommended - Date.now() + 604800 (1 week)), zero for L1 bridging
	 */
	struct BridgeParams {
		address token;
		address router;
		address recipient;
		uint256 targetChainId;
		uint256 amount;
		uint256 bonderFee;
		uint256 sourceAmountOutMin;
		uint256 sourceDeadline;
		uint256 destinationAmountOutMin;
		uint256 destinationDeadline;
	}

	function _swapAndSend(BridgeParams memory params) internal {
		IHopRouter router = IHopRouter(params.router);

		TokenInterface tokenContract = TokenInterface(params.token);
		approve(tokenContract, params.router, params.amount);

		router.swapAndSend(
			params.targetChainId,
			params.recipient,
			params.amount,
			params.bonderFee,
			params.sourceAmountOutMin,
			params.sourceDeadline,
			params.destinationAmountOutMin,
			params.destinationDeadline
		);
	}
}

contract Events {
	event LogBridge(
		address token,
		uint256 chainId,
		address recipient,
		uint256 amount,
		uint256 bonderFee,
		uint256 amountOutMin,
		uint256 deadline,
		uint256 destinationAmountOutMin,
		uint256 destinationDeadline,
		uint256 getId
	);
}

/**
 * @title Hop.
 * @dev Cross chain Bridge.
 */

abstract contract Resolver is Helpers {
	/**
	 * @dev Bridge Token.
	 * @notice Bridge Token on HOP.
	 * @param params BridgeParams struct for bridging
	 * @param getId ID to retrieve amount from last spell.
	 */
	function bridge(BridgeParams memory params, uint256 getId)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		if (params.targetChainId == 1) {
			require(
				params.destinationAmountOutMin == 0,
				"destinationAmountOutMin != 0, sending to L1"
			);
			require(
				params.destinationDeadline == 0,
				"destinationDeadline != 0, sending to L1"
			);
		}

		params.amount = getUint(getId, params.amount);

		bool isEth = params.token == ethAddr;
		params.token = params.token == ethAddr ? wethAddr : params.token;

		TokenInterface tokenContract = TokenInterface(params.token);

		if (isEth) {
			params.amount = params.amount == uint256(-1)
				? address(this).balance
				: params.amount;
			convertEthToWeth(isEth, tokenContract, params.amount);
		} else {
			params.amount = params.amount == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: params.amount;
		}

		_swapAndSend(params);

		_eventName = "LogBridge(address,uint256,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			params.token,
			params.targetChainId,
			params.recipient,
			params.amount,
			params.bonderFee,
			params.sourceAmountOutMin,
			params.sourceDeadline,
			params.destinationAmountOutMin,
			params.destinationDeadline,
			getId
		);
	}
}

contract ConnectV2HopArbitrum is Resolver {
	string public constant name = "Hop-v1.0";
}