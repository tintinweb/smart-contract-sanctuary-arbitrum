// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './PhotonPair.sol';
import './IERC20Minimal.sol';

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

contract PhotonRouter is Ownable {

	/// Maps pair to pair address
	mapping(address => mapping(address => mapping(uint256 => address))) public pairAddresses;

    /// Transfer failed error
	error TransferFailed();

	/// @dev Get the pair contract's balance of token
	/// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
	/// check
	function tokenBalance(address token, address pair) private view returns (uint256) {
		(bool success, bytes memory data) = token.staticcall(
			abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, pair)
		);
		require(success && data.length >= 32);
		return abi.decode(data, (uint256));
	}

	/// @dev Gets pair address for tokenX and tokenY
	/// @param tokenX the address of desired tokenX
	/// @param tokenY the address of desired tokenY
	function getPair(address tokenX, address tokenY, uint256 tickMode) external view returns (address pair) {
		return pairAddresses[tokenX][tokenY][tickMode];
	}

	/// @dev Creates a new pair for tokenX and tokenY
	/// @param tokenX the address of desired tokenX
	/// @param tokenY the address of desired tokenY
	function createPair(address tokenX, address tokenY, uint256 tickMode) public returns (address pair) {
		require(tokenX != address(0) && tokenY != address(0));
		pair = address(new PhotonPair{salt: keccak256(abi.encode(tokenX, tokenY, tickMode))}(address(this), tokenX, tokenY, tickMode));
		pairAddresses[tokenX][tokenY][tickMode] = pair;
	}

	function createLimitOrder(address pairAddress, uint256 tokenXAmount, int24 tick) external returns (uint256 orderId) {
		require(pairAddress != address(0));
		//transfer tokenX to pair contract, adjust tokenXAmount based on token transfer fees (if any)
        address tokenX = PhotonPair(pairAddress).tokenX();
		{
			uint256 preBalance = tokenBalance(tokenX, pairAddress);
			if (!IERC20Minimal(tokenX).transferFrom(msg.sender, pairAddress, tokenXAmount)) revert TransferFailed();
			tokenXAmount = tokenBalance(tokenX, pairAddress) - preBalance;
		}
		orderId = PhotonPair(pairAddress).createLimitOrder(tokenXAmount, tick, msg.sender);
	}

	function swapTokenYForExactTokenX(address pairAddress, uint256 tokenXAmount, uint256 maxTokenYAmount) external {
		require(pairAddress != address(0));
		//transfer tokenY to contract, adjust tokenXAmount based on token transfer fees (if any)
        address tokenY = PhotonPair(pairAddress).tokenY();
		{
			uint256 preBalance = tokenBalance(tokenY, pairAddress);
			if (!IERC20Minimal(tokenY).transferFrom(msg.sender, pairAddress, maxTokenYAmount)) revert TransferFailed();
			maxTokenYAmount = tokenBalance(tokenY, pairAddress) - preBalance;
		}
		PhotonPair(pairAddress).swapTokenYForExactTokenX(tokenXAmount, maxTokenYAmount, msg.sender);
	}

	function swapExactTokenYForTokenX(address pairAddress, uint256 tokenYAmount, uint256 minTokenXAmount) external {
		require(pairAddress != address(0));
		//transfer tokenY to contract, adjust tokenYAmount based on token transfer fees (if any)
        address tokenY = PhotonPair(pairAddress).tokenY();
		{
			uint256 preBalance = tokenBalance(tokenY, pairAddress);
			if (!IERC20Minimal(tokenY).transferFrom(msg.sender, pairAddress, tokenYAmount)) revert TransferFailed();
			tokenYAmount = tokenBalance(tokenY, pairAddress) - preBalance;
		}
		PhotonPair(pairAddress).swapExactTokenYForTokenX(tokenYAmount, minTokenXAmount, msg.sender);
	}

	function withdraw(address pairAddress, uint256 orderId) external {
		require(pairAddress != address(0));
		PhotonPair(pairAddress).withdraw(orderId, msg.sender);
	}

}