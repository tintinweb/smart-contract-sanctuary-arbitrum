// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ShipePresale is Ownable {

    event SetMinContribution(uint256 _minContribution);
    event SetMaxContribution(uint256 _maxContribution);
    event SetTeamWallet(address _teamWallet);
    event Contribute(address contributor, uint256 usdcAmount, uint256 tokenAmount);
    event Withdraw(address receiver, address token, uint256 amount);

    IERC20 public usdcToken;
    address public teamWallet;

    uint256 public constant DENO = 6;
    uint256 public constant seedSalePrice = 8000; // $0.008

    uint256 public totalUsdcAmount = 0;
    uint256 public totalTokenAmount = 0;

    uint256 public hardcap = 5000000 * 10 ** 18;

    uint256 public minContribution = 500 * 10 ** DENO;
    uint256 public maxContribution = 2500 * 10 ** DENO;

    uint256 public isStarted = 0;
    
    struct CONTRIBUTOR {
        uint256 tokenAmount;
        uint256 usdcAmount;
    }

    mapping (address => CONTRIBUTOR) public contributors;

    constructor(address _usdc) {
        usdcToken = IERC20(_usdc);
        isStarted = 0;
        teamWallet = 0x2B669CD93055d8a48D1Dc4103592eb10a58659eA;
    }

    function setSaleStart(uint256 _started) external onlyOwner {
        isStarted = _started;
    }

    function setHardcap(uint256 _hardcap) external onlyOwner {
        hardcap = _hardcap;
    }

    function setMinContribution(uint256 _minContribution) external onlyOwner {
        minContribution = _minContribution;
        emit SetMinContribution(_minContribution);
    }

    function setMaxContribution(uint256 _maxContribution) external onlyOwner {
        maxContribution = _maxContribution;
        emit SetMaxContribution(_maxContribution);
    }

    function setTeamWallet(address _team) external onlyOwner {
        teamWallet = _team;
        emit SetTeamWallet(_team);
    }

    function getContributableAmount(address _user) external view returns (uint256) {
        return maxContribution - contributors[_user].usdcAmount;
    }

    function contribute(uint256 _usdcAmount) external {
        require(isStarted == 1, "ShipePresale: Not presale period");
        address user = msg.sender;
        CONTRIBUTOR storage _contributor = contributors[user];
        require(_usdcAmount >= minContribution, "ShipePresale: Should be deposit more than minContribution = 1000");
        require(_contributor.usdcAmount + _usdcAmount <= maxContribution, "ShipePresale: Should be deposit less than maxContribution = 5000");
        
        uint256 _tokenAmount = 0;
        _tokenAmount = _usdcAmount / seedSalePrice * 10 ** 18;

        require(totalTokenAmount + _tokenAmount <= hardcap, "ShipePresale: Presale has finished");
        // Receive USDC to the contract
        usdcToken.transferFrom(user, teamWallet, _usdcAmount);
        _contributor.usdcAmount = _contributor.usdcAmount + _usdcAmount;
        _contributor.tokenAmount = _contributor.tokenAmount + _tokenAmount;

        totalUsdcAmount = totalUsdcAmount + _usdcAmount;
        totalTokenAmount = totalTokenAmount + _tokenAmount;

        emit Contribute(user, _usdcAmount, _tokenAmount);
    }

    function withdraw(address to, address token) external onlyOwner {
        uint256 _amount;
        if (token == address(0)) {
            _amount = address(this).balance;
            require(_amount > 0, "No ETH to withdraw");

            (bool success, ) = payable(to).call{value: _amount}("");
            require(success, "Unable to withdraw");
        } else {
            _amount = IERC20(token).balanceOf(address(this));
            require (_amount > 0, "Nothing to withdraw");
            bool success = IERC20(token).transfer(to, _amount);
            require(success, "Unable to withdraw");
        }

        emit Withdraw(to, token, _amount);
    }

    receive() payable external {}
    fallback() payable external {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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