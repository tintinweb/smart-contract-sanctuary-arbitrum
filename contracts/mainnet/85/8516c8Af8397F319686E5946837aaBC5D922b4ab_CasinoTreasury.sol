/*
    Casino treasury contract - Arbitrum Gambling
    Developed by Kerry <TG: campermon>
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BasicLibraries/SafeMath.sol";
import "./BasicLibraries/Context.sol";
import "./BasicLibraries/Auth.sol";
import "./BasicLibraries/IBEP20.sol";
import "./Chainlink/IAggregator.sol";

contract CasinoTreasury is Context, Auth {
    using SafeMath for uint256;

    // Event deposit tokens
    event DepositTokens(address indexed adr, uint256 tokensDeposited, uint256 currentDepositDollars);
    // Event withdraw tokens
    event WithdrawTokens(address indexed adr, uint256 tokensWithdrawed, uint256 currentDepositDollars);

    // ETH each user has stored in contract balance
    mapping (address => uint256) public balances;

    // Casino contracts that can update contract treasury balance
    mapping (address => bool) public casinoContracts;

    // Total ETH users
    uint256 public totalETHUsers = 0;

    // A certain amount of each deposit will be send to owner
    uint8 public taxesPc = 5; 

    // People can not play if closed but will be able to withdraw their tokens
    bool public casinoOpen = false;

    // Custom error message
    string public withdrawError = "Wait till owners replenish the token pool or contact them @campermon on telegram";

    // Chainlink token price datafeed
    IAggregator public chainlinkPriceDF; // 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612 // arbitrum

    /**
     * Function modifier to require caller to be a whitelisted contract
     */
    modifier onlyCasino() {
        require(casinoContracts[msg.sender], "Only casino contracts can call this function"); _;
    }

    constructor (address _chainlinkPriceDF) Auth(msg.sender) { 
        chainlinkPriceDF = IAggregator(_chainlinkPriceDF); 
        require(getTokenPrice() != 0, "Error with datafeed: price");
        require(getTokenDecimals() != 0, "Error with datafeed: decimals");
    }

    receive() external payable { }

    //region VIEWS

    function getOwner() public view returns (address) {return owner;}
    function balanceOf(address _account) public view returns (uint256) { return balances[_account]; }
    function isContract(address _account) public view returns (bool) { return _account.code.length > 0; }
    function isEmptyString(string memory _string) public pure returns (bool) { return bytes(_string).length == 0; }
    function contractPool() public view returns(uint256) { return address(this).balance; }
    function contractPoolSubUsers() public view returns(uint256) { return contractPool().sub(totalETHUsers); }
 
    //endregion

    //region UTILS

    function _UpdateBalancesSub(address adr, uint256 _nTokens) internal {
        balances[adr] -= _nTokens;
        totalETHUsers -= _nTokens;
    }
    function UpdateBalancesSub(address adr, uint256 _nTokens) public onlyCasino { _UpdateBalancesSub(adr, _nTokens); }

    function _UpdateBalancesAdd(address adr, uint256 _nTokens) internal {
        balances[adr] += _nTokens;
        totalETHUsers += _nTokens;
    }
    function UpdateBalancesAdd(address adr, uint256 _nTokens) public onlyCasino { _UpdateBalancesAdd(adr, _nTokens); }

    function TaxPayment(uint256 _nTokens) public onlyCasino returns(bool) {
        // Will be send to they caller to pay link tokens
        (bool success,) = payable(msg.sender).call{value: _nTokens.mul(taxesPc).div(100)}("");
        require(success, "Error sending ETH to caller");
        return success;
    }    
   
    //endregion

    function depositTokens() public payable {
        require(casinoOpen, "You only can deposit if the casino is opened");
        require(!isContract(_msgSender()), "Contracts not allowed");
        _UpdateBalancesAdd(_msgSender(), msg.value);

        emit DepositTokens(_msgSender(), msg.value, calcDollars(msg.value));
    }

    function withdrawTokens(uint256 _nTokens) public {  
        require(balanceOf(_msgSender()) >= _nTokens, "You have not that number of tokens to withdraw");
        _UpdateBalancesSub(_msgSender(), _nTokens);
        (bool success,) = payable(_msgSender()).call{value: _nTokens}("");
        require(success, isEmptyString(withdrawError) ? "Wait till owners replenish the token pool" : withdrawError);

        emit WithdrawTokens(_msgSender(), _nTokens, calcDollars(_nTokens));
    }

    //endregion 

    //region ADMIN

    //region MAIN

    function OpenCasino(bool _open) public onlyOwner { casinoOpen = _open; }

    function setWithdrawError(string memory _string) public onlyOwner { withdrawError = _string; }

    function clearStuckToken(address _tokenAddress, uint256 _tokens) public onlyOwner returns (bool) {
        if(_tokens == 0){
            _tokens = IBEP20 (_tokenAddress).balanceOf(address(this));
        }
        return IBEP20 (_tokenAddress).transfer(msg.sender, _tokens);
    }
    
    //endregion

    //region TOKEN PRICE

    function calcTokensFromDollars(uint256 _dollars) public view returns(uint256) {
        return _dollars.mul(10 ** (getTokenDecimals() + 18)).div(getTokenPrice());
    }

    function calcDollars(uint256 _nTokens) public view returns(uint256) {
        return getTokenPrice().mul(_nTokens).div(10 ** getTokenDecimals());
    }

    function getTokenPrice() public view returns(uint256) {
        return uint256(chainlinkPriceDF.latestAnswer());
    }

    function getTokenDecimals() public view returns(uint8) {
        return chainlinkPriceDF.decimals();
    }

    //endregion

    function whitelistCasinoContract(address _adr, bool _allow) public onlyOwner { casinoContracts[_adr] = _allow; }

    //endregion
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAggregator {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
pragma solidity ^0.8.9;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}