/**
 *Submitted for verification at Arbiscan.io on 2024-06-20
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


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
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// File: contracts/$Cripbot.sol


pragma solidity ^0.8.0;


interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract $CripbotAi is Ownable{
    address public admin;
    IERC20 public token;
    IUniswapV2Pair public uniswapPair;
    uint256 public tokensSold;
    // uint256 public saleEnd;
    uint256 public totalTokensForSale;

    event TokensPurchased(address indexed buyer, uint256 amount);


    constructor (
        address _admin,
        address _token,
        address _uniswapPair,
        uint256 _totalTokensForSale
    ) Ownable(msg.sender){
        //  uint256 _saleDuration
        admin = _admin; // msg.sender;
        token = IERC20(_token);
        uniswapPair = IUniswapV2Pair(_uniswapPair);
        totalTokensForSale = _totalTokensForSale;
        //  saleEnd = block.timestamp + _saleDuration;
    }

    function getTokenPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = uniswapPair.getReserves();
        address token0 = uniswapPair.token0();
        address token1 = uniswapPair.token1();

        if (token0 == address(token)) {
            // Price in terms of the other token in the pair (token1)
            require(reserve0 > 0, "Insufficient liquidity for token0");
            require(reserve1 > 0, "Insufficient liquidity for token1");
            return (uint256(reserve1) * 1e18) / uint256(reserve0);
        } else if (token1 == address(token)) {
            // Price in terms of the other token in the pair (token0)
            require(reserve1 > 0, "Insufficient liquidity for token1");
            require(reserve0 > 0, "Insufficient liquidity for token0");
            return (uint256(reserve0) * 1e18) / uint256(reserve1);
        } else {
            revert("Token not found in Uniswap pair");
        }
    }

    function buyTokens() external payable {
        //   require(block.timestamp < saleEnd, "Sale has ended");
        uint256 tokenPrice = getTokenPrice();
        uint256 tokensToBuy = (msg.value * 1e18) / tokenPrice;
        require(
            tokensSold + tokensToBuy <= totalTokensForSale,
            "Not enough tokens left for sale"
        );

        // Transfer received ETH to the seller (admin)
        payable(admin).transfer(msg.value);

        tokensSold += tokensToBuy;
        token.transfer(msg.sender, tokensToBuy);

        emit TokensPurchased(msg.sender, tokensToBuy);
    }

    function buyTokensByETH(uint256 tokenAmount) external payable {
        uint256 tokenPrice = getTokenPrice();
        uint256 requiredETH = (tokenAmount * tokenPrice) / 1e18;
        require(msg.value >= requiredETH, "Insufficient ETH sent");
        require(
            tokensSold + tokenAmount <= totalTokensForSale,
            "Not enough tokens left for sale"
        );

        // Transfer received ETH to the seller (admin)
        payable(admin).transfer(msg.value);

        tokensSold += tokenAmount;
        token.transfer(msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, tokenAmount);

        // Refund excess ETH if any
        if (msg.value > requiredETH) {
            payable(msg.sender).transfer(msg.value - requiredETH);
        }
    }

    /* function endSale() external onlyAdmin {
        require(block.timestamp >= saleEnd, "Sale not yet ended");
        token.transfer(admin, token.balanceOf(address(this)));
        payable(admin).transfer(address(this).balance);
    }
 */
    function withdrawFunds() external onlyOwner {
        payable(admin).transfer(address(this).balance);
    }

    function withdrawUnsoldTokens() external onlyOwner {
        //  require(block.timestamp >= saleEnd, "Sale not yet ended");
        token.transfer(admin, token.balanceOf(address(this)));
    }
}