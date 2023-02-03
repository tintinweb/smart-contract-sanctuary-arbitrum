// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "AclPriceFeedAggregatorBASE.sol";



contract AclPriceFeedAggregatorArbitrum is AclPriceFeedAggregatorBASE {
    
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    constructor() {
        tokenMap[ETH] = WETH;   //nativeToken to wrappedToken
        tokenMap[address(0)] = WETH;

        priceFeedAggregator[address(0)] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeedAggregator[ETH] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;// ETH
        priceFeedAggregator[WETH] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;// WETH
        priceFeedAggregator[0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f] = 0xd0C7101eACbB49F3deCcCc166d238410D6D46d57;// WBTC
        priceFeedAggregator[0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8] = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;// USDC
        priceFeedAggregator[0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9] = 0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7;// USDT
        priceFeedAggregator[0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0] = 0x9C917083fDb403ab5ADbEC26Ee294f6EcAda2720;// UNI
        priceFeedAggregator[0xf97f4df75117a78c1A5a0DBb814Af92458539FB4] = 0x86E53CF1B870786351Da77A57575e79CB55812CB;// LINK
        priceFeedAggregator[0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F] = 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8;// FRAX
        priceFeedAggregator[0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1] = 0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB;// DAI
        priceFeedAggregator[0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978] = 0xaebDA2c976cfd1eE1977Eac079B4382acb849325;// CRV
        priceFeedAggregator[0x13Ad51ed4F1B7e9Dc168d8a00cB3f4dDD85EfA60] = address(0);// LDO
        priceFeedAggregator[0x6694340fc020c5E6B96567843da2df01b2CE1eb6] = address(0);// STG
        priceFeedAggregator[0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a] = 0xDB98056FecFff59D032aB628337A4887110df3dB;// GMX
        priceFeedAggregator[0x539bdE0d7Dbd336b79148AA742883198BBF60342] = 0x47E55cCec6582838E173f252D08Afd8116c2202d;// MAGIC
        priceFeedAggregator[0x5979D7b546E38E414F7E9822514be443A4800529] = address(0);// wstETH
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "Ownable.sol";

interface AggregatorV3Interface {
    function latestRoundData() external view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint8);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}


contract AclPriceFeedAggregatorBASE is TransferOwnable{
    
    uint256 public constant DECIMALS_BASE = 18;
    mapping(address => address) public priceFeedAggregator;
    mapping(address => address) public tokenMap;

    struct PriceFeedAggregator {
        address token; 
        address priceFeed; 
    }

    event PriceFeedUpdated(address indexed token, address indexed priceFeed);
    event TokenMap(address indexed nativeToken, address indexed wrappedToken);

    function getUSDPrice(address _token) public view returns (uint256,uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAggregator[_token]);
        require(address(priceFeed) != address(0), "priceFeed not found");
        (uint80 roundId, int256 price, , uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        require(price > 0, "Chainlink: price <= 0");
        require(answeredInRound >= roundId, "Chainlink: answeredInRound <= roundId");
        require(updatedAt > 0, "Chainlink: updatedAt <= 0");
        return (uint256(price) , uint256(priceFeed.decimals()));
    }

    function getUSDValue(address _token , uint256 _amount) public view returns (uint256) {
        if (tokenMap[_token] != address(0)) {
            _token = tokenMap[_token];
        } 
        (uint256 price, uint256 priceFeedDecimals) = getUSDPrice(_token);
        uint256 usdValue = (_amount * uint256(price) * (10 ** DECIMALS_BASE)) / ((10 ** IERC20(_token).decimals()) * (10 ** priceFeedDecimals));
        return usdValue;
    }

    function setPriceFeed(address _token, address _priceFeed) public onlyOwner {    
        require(_priceFeed != address(0), "_priceFeed not allowed");
        require(priceFeedAggregator[_token] != _priceFeed, "_token _priceFeed existed");
        priceFeedAggregator[_token] = _priceFeed;
        emit PriceFeedUpdated(_token,_priceFeed);
    }

    function setPriceFeeds(PriceFeedAggregator[] calldata _priceFeedAggregator) public onlyOwner {    
        for (uint i=0; i < _priceFeedAggregator.length; i++) { 
            priceFeedAggregator[_priceFeedAggregator[i].token] = _priceFeedAggregator[i].priceFeed;
        }
    }

    function setTokenMap(address _nativeToken, address _wrappedToken) public onlyOwner {    
        require(_wrappedToken != address(0), "_wrappedToken not allowed");
        require(tokenMap[_nativeToken] != _wrappedToken, "_nativeToken _wrappedToken existed");
        tokenMap[_nativeToken] = _wrappedToken;
        emit TokenMap(_nativeToken,_wrappedToken);
    }


    fallback() external {
        revert("Unauthorized access");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function _transferOwnership(address newOwner) internal virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract TransferOwnable is Ownable {
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
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