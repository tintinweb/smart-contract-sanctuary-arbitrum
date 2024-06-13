/**
 *Submitted for verification at Arbiscan.io on 2024-06-11
*/

// Sources flattened with hardhat v2.22.3 https://hardhat.org

// SPDX-License-Identifier: MIT

// File libs/@openzeppelin/contracts/token/ERC20/IERC20.sol

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File libs/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File contracts/Seller.sol

// Original license: SPDX_License_Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;
interface VestingToken {
    function vest(address user, uint256 amount, uint8 vestTypeId ) external;
}

contract Seller {
    address private _tokenAddress;
    address private _destinationWallet;
    address private _contractOwner;
    address private _sellerAddress;
    address private _sourceAddress;
    uint256 private _tokenPrice;
    uint256 private _lead_treshold; // 100_000 source tokens (USDT)

    error AccessControlUnauthorizedAccount(address account);
    event Vested(uint256 amount, address to);
    event NewSeller(address newSellerAddress);

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlySeller() {
        _checkSeller();
        _;
    }

    constructor(address contractOwner, address maintokenAddress, address sourceAddress, address destinationWallet, address sellerAddress, uint256 price, uint256 leadTreshold ) {
        _contractOwner = contractOwner;
        _tokenAddress = maintokenAddress;
        _sourceAddress = sourceAddress;
        _sellerAddress = sellerAddress;
        _destinationWallet = destinationWallet;
        _lead_treshold = leadTreshold;
        _tokenPrice = price;
    }

    function vestTokenName() external view returns(string memory){
        return IERC20Metadata(_tokenAddress).name(); 
    }

    function vestTokenDecimals() public view returns(uint8){
        return IERC20Metadata(_tokenAddress).decimals(); 
    }

    function sourceTokenName() external view returns(string memory){
        return IERC20Metadata(_sourceAddress).name(); 
    }

    function sourceTokenDecimals() public view virtual returns(uint8){
        return IERC20Metadata(_sourceAddress).decimals(); 
    }

    function _checkSeller() internal view virtual{
        if (msg.sender != _sellerAddress) {
            revert AccessControlUnauthorizedAccount(msg.sender);
        }
    }

    function _checkOwner() internal view virtual{
        if (msg.sender != _contractOwner) {
            revert AccessControlUnauthorizedAccount(msg.sender);
        }
    }

    function getSeller() external view returns(address){
        return _sellerAddress;
    }

    function getTokenPrice() external view returns(uint256){
        return _tokenPrice;
    }

    function changeSeller(address newSellerAddress) external onlyOwner(){
        require(newSellerAddress != address(0), "changeSeller: Seller should be a real address" );
        _sellerAddress = newSellerAddress;
        emit NewSeller(newSellerAddress);
    }

    

    // set token price * 1000.
    // price = 250: 0.25 USDT per vestToken
    function changePrice(uint256 price) external onlyOwner {
        require(price >= 250, "changePrice: Price must be greater or equal 0.25 (250) ");
        _tokenPrice = price;
    }

    function calculateAmount(uint256 sourceTokenAmount) public view returns(uint256){
        uint8 genesisTokenDecimals = vestTokenDecimals();
        uint8 sourceTolenDecimals = sourceTokenDecimals();
        uint256 amount;
        if (genesisTokenDecimals < sourceTolenDecimals) {
            amount = (sourceTokenAmount * 1000 ) / _tokenPrice / 10 ** (sourceTolenDecimals - genesisTokenDecimals);
        } else{
            amount = (sourceTokenAmount * 1000 ) / _tokenPrice * 10 ** (genesisTokenDecimals - sourceTolenDecimals);
        }
        return amount;
    }

    function getTypeByAmount(uint256 sourceTokenAmount) public view virtual returns(uint8) {
        uint8 sourceDecimals = sourceTokenDecimals();
        if (sourceTokenAmount >= _lead_treshold * (10 ** sourceDecimals)) { // lead
            return 2;
        } 
        return 1;    
    }
    // use vest for Tron Network
    function vest(address user, uint256 sourceTokenAmount) external onlySeller() {
        _vest(user, sourceTokenAmount);
    }

    function _vest(address user, uint256 sourceTokenAmount) internal returns(bool){
        uint256 tokenAmount = calculateAmount(sourceTokenAmount);
        uint8 vestType = getTypeByAmount(sourceTokenAmount);
        VestingToken(_tokenAddress).vest(user, tokenAmount, vestType);
        emit Vested(tokenAmount, user);
        return true;
    }

    function buyWithUSDT(uint256 sourceTokenAmount) external returns(bool) {
        uint256 ourAllowance = IERC20(_sourceAddress).allowance(msg.sender, address(this));
        require(sourceTokenAmount <= ourAllowance, "buyWithUSDT: Make sure to add enough allowance");
        (bool success, ) = address(_sourceAddress).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                _destinationWallet,
                sourceTokenAmount
            )   
        );
        require(success, "buyWithUSDT: Token payment failed");
        _vest(msg.sender, sourceTokenAmount);
        return success;
    }
}