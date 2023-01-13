// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IGarbiswapTrade {
	function base() external view returns (address);
	function token() external view returns (address);
	function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
	function getTotalReserve() external view returns (uint256, uint256);
}
contract GarbiswapTradeInfo {
	struct LP {
		uint256 baseReserve;
		uint256 tokenReserve;
		uint256 totalLP;
		uint256 uLPBal;
		uint256 uBaseAllowedToPair;
		uint256 uTokenAllowedToPair; 
		uint256 uBaseAllowedToTradeMachine;
		uint256 uTokenAllowedToTradeMachine; 
	}
	function getData(address _owner, address _tradeMachine, IGarbiswapTrade[] calldata _lps) public view returns(LP[] memory data_)
	{
		data_ = new LP[](_lps.length);
		address _base;
		address _token;
		for (uint256 idx = 0; idx < _lps.length; idx++) {
			_base = _lps[idx].base();
			_token = _lps[idx].token();
            data_[idx].baseReserve = IERC20(_base).balanceOf(address(_lps[idx]));
            data_[idx].tokenReserve = IERC20(_token).balanceOf(address(_lps[idx]));
			data_[idx].totalLP = _lps[idx].totalSupply();
			data_[idx].uLPBal = _lps[idx].balanceOf(_owner);
			data_[idx].uBaseAllowedToPair = IERC20(_base).allowance(_owner, address(_lps[idx]));
			data_[idx].uTokenAllowedToPair = IERC20(_token).allowance(_owner, address(_lps[idx]));
			data_[idx].uBaseAllowedToTradeMachine = IERC20(_base).allowance(_owner, _tradeMachine);
			data_[idx].uTokenAllowedToTradeMachine = IERC20(_token).allowance(_owner, _tradeMachine);
		}
	}
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