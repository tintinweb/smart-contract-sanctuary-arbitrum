// SPDX-License-Identifier: MIT

/**
 * DAppCrypto2
 * GitHub Website: https://dappcrypto.github.io/
 * GitHub: https://github.com/dappcrypto
 */

/**
 * MultiTokens allows you to create simple tokens
 */

pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./SimpleToken.sol";
import "./Wallet.sol";
import "./TaxCreationBlock.sol";

interface iSimpleToken {
    function initToken(string memory t_name, string memory t_symbol, uint8 t_decimals, uint256 t_totalSupply, address addressOwner) external returns (bool);
}

contract MultiTokens is Wallet, TaxCreationBlock {

    event NewContractTokenDeployed(address indexed newContractTokenAddress, uint256 indexed numberToken);

    uint256 public amountTokens = 0;

    // mappingTokensContracts[addressContractToken] = numberToken
    mapping(address => uint256) public mappingTokensContracts;

    struct TokenData {
        uint256 numberToken;
        uint256 timeToken;
        address addressContractToken;
    }
    // mappingTokensData[numberToken] = TokenData
    mapping(uint256 => TokenData) public mappingTokensData;

    function getTokenAllData(uint256 _numberToken, address _addressAccount, address _addressSpender) public view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory) {
        uint256[] memory uintArr = new uint256[](40);
        address[] memory addressArr = new address[](40);
        bool[] memory boolArr = new bool[](40);
        string[] memory stringArr = new string[](40);

        if(mappingTokensData[_numberToken].numberToken==0){
            return (uintArr, addressArr, boolArr, stringArr);
        }

        (uintArr, addressArr, stringArr) = getTokenInfo(mappingTokensData[_numberToken].addressContractToken, _addressAccount, _addressSpender);

        // uintArr
        uintArr[10] = mappingTokensData[_numberToken].numberToken;
        uintArr[11] = mappingTokensData[_numberToken].timeToken;

        // addressArr
        addressArr[10] = mappingTokensData[_numberToken].addressContractToken;

        return (uintArr, addressArr, boolArr, stringArr);
    }

    function getTokenInfo(address _addressToken, address _addressAccount, address addressSpender) public view returns (uint256[] memory, address[] memory, string[] memory) {
        uint256[] memory uintArr = new uint256[](40);
        address[] memory addressArr = new address[](40);
        string[] memory stringArr = new string[](40);

        // uintArr
        uintArr[0] = IERC20(_addressToken).decimals();
        uintArr[1] = IERC20(_addressToken).totalSupply();

        uintArr[2] = IERC20(_addressToken).balanceOf(_addressAccount);
        uintArr[3] = IERC20(_addressToken).allowance(_addressAccount, addressSpender);

        // addressArr
        addressArr[0] = IERC20(_addressToken).owner();

        // stringArr
        stringArr[0] = IERC20(_addressToken).name();
        stringArr[1] = IERC20(_addressToken).symbol();


        return (uintArr, addressArr, stringArr);
    }


    function getTokenAllDataByContract(address _addressContractToken, address _addressOwner, address _addressSpender) public view returns (uint256[] memory, address[] memory, bool[] memory, string[] memory) {
        uint256 _numberToken = mappingTokensContracts[_addressContractToken];
        return getTokenAllData(_numberToken, _addressOwner, _addressSpender);
    }

    function deployContractToken(string memory t_name, string memory t_symbol, uint8 t_decimals, uint256 t_totalSupply, address addressOwner) payable public {
        sendTaxCreation();

        amountTokens++;

        SimpleToken SimpleToken1 = new SimpleToken();
        address addressContractToken = address(SimpleToken1);

        iSimpleToken(addressContractToken).initToken(t_name, t_symbol, t_decimals, t_totalSupply, addressOwner);

        mappingTokensContracts[addressContractToken] = amountTokens;

        mappingTokensData[amountTokens].timeToken = block.timestamp;
        mappingTokensData[amountTokens].numberToken = amountTokens;
        mappingTokensData[amountTokens].addressContractToken = addressContractToken;

        emit NewContractTokenDeployed(addressContractToken, amountTokens);
    }
}

// SPDX-License-Identifier: MIT

/**
 * DAppCrypto
 * GitHub Website: https://dappcrypto.github.io/
 * GitHub: https://github.com/dappcrypto
 */

pragma solidity >=0.8.0;

import "./Ownable.sol";

contract TaxCreationBlock is Ownable {
    uint256 public taxCreation = 10000000000000000; // 0.01
    address public taxCreationAddress = address(this); // 0.01

    function setTaxCreation(uint256 _amountTax) public onlyOwner {
        taxCreation = _amountTax;
        return;
    }

    function setTaxCreationAddress(address _addressTax) public onlyOwner {
        taxCreationAddress = _addressTax;
        return;
    }

    function sendTaxCreation() payable public {
        require(msg.value >= taxCreation, "taxCreation error");
        if(taxCreationAddress!=address(this)){
            payable(taxCreationAddress).transfer(taxCreation);
        }
        return;
    }
}

// SPDX-License-Identifier: MIT

/**
 * DAppCrypto
 * GitHub Website: https://dappcrypto.github.io/
 * GitHub: https://github.com/dappcrypto
 */

pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract Wallet is Ownable {
    receive() external payable {}
    fallback() external payable {}

    // Transfer Eth
    function transferEth(address _to, uint256 _amount) public onlyOwner {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    // Transfer Tokens
    function transferTokens(address addressToken, address _to, uint256 _amount) public onlyOwner {
        IERC20 contractToken = IERC20(addressToken);
        contractToken.transfer(_to, _amount);
    }

}

// SPDX-License-Identifier: MIT

/**
 * SimpleToken is a simple token contract without cheating
 * This contract contains the minimum functions required for the token to operate.
 * Read Contract: _decimals, decimals, _name, name, _symbol, symbol, allowance, balanceOf, getOwner, totalSupply, owner.
 * Write Contract: transfer, transferFrom, approve, decreaseAllowance, increaseAllowance.
 * Write Contract, only for owner: renounceOwnership, transferOwnership.
 * Token created using DAppCrypto https://dappcrypto.github.io/
 */

 /**
 * Important! Always check liquidity lock before investing.
 * Important! Always check if the token address is available in DAppCrypto https://dappcrypto.github.io/
 */

pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract SimpleToken is Ownable, IERC20 {
    using SafeMath for uint256;
    bool private initializeToken = false;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 public _decimals;
    string public _symbol;
    string public _name;

    constructor() {}

    // Token initialization is only available once
    function initToken(string memory t_name, string memory t_symbol, uint8 t_decimals, uint256 t_totalSupply, address addressOwner) public onlyOwner returns (bool) {
        require(initializeToken == false, "The token is already initialized");
        initializeToken = true;

        _name = t_name;
        _symbol = t_symbol;
        _decimals = t_decimals;
        _totalSupply = t_totalSupply;
        _balances[addressOwner] = _totalSupply;

        transferOwnership(addressOwner);

        emit Transfer(address(0), addressOwner, _totalSupply);

        return true;
    }

    function owner() external view returns (address) {
        return getOwner();
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address addressOwner, address spender) external view returns (uint256) {
        return _allowances[addressOwner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "Decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount <= _balances[sender], "Transfer amount exceeds balance");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address addressOwner, address spender, uint256 amount) internal {
        require(addressOwner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[addressOwner][spender] = amount;
        emit Approval(addressOwner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT

/**
 * contract Ownable
 */

pragma solidity >=0.8.0;

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "onlyOwner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

/**
 * interface IERC20
 */

pragma solidity >=0.8.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function owner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

/**
 * Library for mathematical operations
 */

pragma solidity >=0.8.0;

// @dev Wrappers over Solidity's arithmetic operations with added overflow * checks.
library SafeMath {
    // Counterpart to Solidity's `+` operator.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    // Counterpart to Solidity's `-` operator.
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    // Counterpart to Solidity's `-` operator.
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    // Counterpart to Solidity's `*` operator.
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    // Counterpart to Solidity's `/` operator.
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    // Counterpart to Solidity's `/` operator.
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    // Counterpart to Solidity's `%` operator.
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    // Counterpart to Solidity's `%` operator.
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

/**
 * abstract contract Context
 */

pragma solidity >=0.8.0;

abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    //constructor () { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}