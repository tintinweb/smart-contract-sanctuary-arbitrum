// SPDX-License-Identifier: MIT

/**
 * DAppCrypto
 * GitHub Website: https://dappcrypto.github.io/
 * GitHub: https://github.com/dappcrypto
 */

/**
 * MultiTransfers allows you to send tokens and ETH in bulk
 */

pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Wallet.sol";
import "./SafeMath.sol";
import "./TokenInfo.sol";
import "./TaxCreationBlock.sol";

contract MultiTransfers is Context, Ownable, Wallet, TokenInfo, TaxCreationBlock {
    using SafeMath for uint256;

    function getSumByArr(uint256[] memory _uintArr) internal pure returns (uint256) {
        uint256 uintSum = 0;
        for (uint i; i < _uintArr.length; i++) {
            uintSum = uintSum.add(_uintArr[i]);
        }
        return uintSum;
    }
    
    function multiTransfersEth(address[] memory  _addressesArray, uint256[] memory  _amountsArray) payable public returns (bool) {
        require(_addressesArray.length == _amountsArray.length, "_addressesArray.length, _amountsArray.length");
        //require(msg.value >= (getSumByArr(_amountsArray)).add(taxCreation), "You must send eth"); // Reducing gas costs
        for (uint i; i < _addressesArray.length; i++) {
            payable(_addressesArray[i]).transfer(_amountsArray[i]);
        }
        sendTaxCreation();
        return true;
    }

    function multiTransfersEthEqualAmount(address[] memory  _addressesArray, uint256 _amount) payable public returns (bool) {
        //require(msg.value >= (_amount.mul(_addressesArray.length)).add(taxCreation), "You must send eth"); // Reducing gas costs
        for (uint i; i < _addressesArray.length; i++) {
            payable(_addressesArray[i]).transfer(_amount);
        }
        sendTaxCreation();
        return true;
    }

    function multiTransfersTokens(address _token, address[] memory  _addressesArray, uint256[] memory  _amountsArray) payable public returns (bool) {
        require(_addressesArray.length == _amountsArray.length, "_addressesArray.length, _amountsArray.length");
        for (uint i; i < _addressesArray.length; i++) {
            IERC20(_token).transferFrom(_msgSender(), _addressesArray[i], _amountsArray[i]);
        }
        sendTaxCreation();
        return true;
    }

    function multiTransfersTokensEqualAmount(address _token, address[] memory  _addressesArray, uint256 _amount) payable public returns (bool) {
        for (uint i; i < _addressesArray.length; i++) {
            IERC20(_token).transferFrom(_msgSender(), _addressesArray[i], _amount);
        }
        sendTaxCreation();
        return true;
    }

    function multiTransfers(address _token, address[] memory  _addressesArray, uint256[] memory  _amountsArray) payable public returns (bool) {
        if(_token==address(0)){
            multiTransfersEth(_addressesArray, _amountsArray);
        } else {
            multiTransfersTokens(_token, _addressesArray, _amountsArray);
        }
        return true;
    }

    function multiTransfersEqualAmount(address _token, address[] memory  _addressesArray, uint256 _amount) payable public returns (bool) {
        if(_token==address(0)){
            multiTransfersEthEqualAmount(_addressesArray, _amount);
        } else {
            multiTransfersTokensEqualAmount(_token, _addressesArray, _amount);
        }
        return true;
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

import "./IERC20.sol";

contract TokenInfo {

    constructor () {}

    function isContract(address _aToken) public view returns (bool) {
        uint32 size;
        assembly { size := extcodesize(_aToken) }
        return (size > 0);
    }
    
    function hasMethod(address _cAddress, string memory _nameMethod) public view returns (bool) {
        (bool success, ) = _cAddress.staticcall(abi.encodeWithSignature(_nameMethod));
        return success;
    }

    function isLiquidityPool(address _aToken) public view returns (bool) {
        if(!hasMethod(_aToken, "price1CumulativeLast()")){ return false; }
        return true;
    }

    function getTokenOwner(address _aToken) public view returns (address) {
        (bool success, bytes memory result) = address(_aToken).staticcall(abi.encodeWithSignature("owner()"));

        if (success && result.length > 0) {
            return abi.decode(result, (address));
        } else {
            return address(0);
        }
    }

    function getFunStr(address _aToken, string memory nameFun) public view returns (string memory) {
        (bool success, bytes memory result) = address(_aToken).staticcall(abi.encodeWithSignature(nameFun));

        if (success && result.length > 0) {
            return abi.decode(result, (string));
        } else {
            return '';
        }
    }

    function getFunNum(address _aToken, string memory nameFun) public view returns (uint256) {
        (bool success, bytes memory result) = address(_aToken).staticcall(abi.encodeWithSignature(nameFun));

        if (success && result.length > 0) {
            return abi.decode(result, (uint256));
        } else {
            return 0;
        }
    }

    function getFunAddr(address _aToken, string memory nameFun) public view returns (address) {
        (bool success, bytes memory result) = address(_aToken).staticcall(abi.encodeWithSignature(nameFun));

        if (success && result.length > 0) {
            return abi.decode(result, (address));
        } else {
            return address(0);
        }
    }

    function getTokenName(address _aToken) public view returns (string memory) {
        return getFunStr(_aToken, "name()");
    }

    function getTokenSymbol(address _aToken) public view returns (string memory) {
        return getFunStr(_aToken, "symbol()");
    }

    function getTokenDecimals(address _aToken) public view returns (uint256) {
        return getFunNum(_aToken, "decimals()");
    }

    function getTokenTotalSupply(address _aToken) public view returns (uint256) {
        return getFunNum(_aToken, "totalSupply()");
    }

    function getTokenBalanceOf(address _aToken, address _aAccount) public view returns (uint256) {
        (bool success, bytes memory result) = address(_aToken).staticcall(abi.encodeWithSignature("balanceOf(address)", _aAccount));

        if (success && result.length > 0) {
            return abi.decode(result, (uint256));
        } else {
            return 0;
        }
    }

    function getTokenAllowance(address _aToken, address _aAccount, address _aSpender) public view returns (uint256) {
        (bool success, bytes memory result) = address(_aToken).staticcall(abi.encodeWithSignature("allowance(address,address)", _aAccount, _aSpender));

        if (success && result.length > 0) {
            return abi.decode(result, (uint256));
        } else {
            return 0;
        }
    }

    function getPairFactory(address _aToken) public view returns (address) {
        return getFunAddr(_aToken, "factory()");
    }

    function getPairToken0(address _aToken) public view returns (address) {
        return getFunAddr(_aToken, "token0()");
    }

    function getPairToken1(address _aToken) public view returns (address) {
        return getFunAddr(_aToken, "token1()");
    }

    function getTokenInfoSimple(address _aToken, address _aAccount, address _aSpender) public view returns (uint256[] memory, address[] memory, string[] memory) {
        uint256[] memory iArr = new uint256[](50);
        address[] memory aArr = new address[](50);
        string[] memory sArr = new string[](50);

        // aArr
        aArr[0] = getTokenOwner(_aToken);

        // iArr
        iArr[0] = getTokenDecimals(_aToken);
        iArr[1] = getTokenTotalSupply(_aToken);

        iArr[2] = getTokenBalanceOf(_aToken, _aAccount);
        iArr[3] = getTokenAllowance(_aToken, _aAccount, _aSpender);

        // sArr
        sArr[0] = getTokenName(_aToken);
        sArr[1] = getTokenSymbol(_aToken);

        return (iArr, aArr, sArr);
    }

    function getTokenInfo(address _aToken, address _aAccount, address _aSpender) public view returns (uint256[] memory, address[] memory, string[] memory) {
        uint256[] memory iArr = new uint256[](50);
        address[] memory aArr = new address[](50);
        string[] memory sArr = new string[](50);

        uint256 _typeToken = 0;
        if(isLiquidityPool(_aToken)){
            _typeToken = 1;
        }

        // aArr
        if(_typeToken==1){
            aArr[1] = getPairFactory(_aToken);
            aArr[2] = getPairToken0(_aToken);
            aArr[3] = getPairToken1(_aToken);

            aArr[4] = getTokenOwner(aArr[2]);
            aArr[5] = getTokenOwner(aArr[3]);
        } else {
            aArr[0] = getTokenOwner(_aToken);
        }
        // iArr
        iArr[0] = getTokenDecimals(_aToken);
        iArr[1] = getTokenTotalSupply(_aToken);

        iArr[2] = getTokenBalanceOf(_aToken, _aAccount);
        iArr[3] = getTokenAllowance(_aToken, _aAccount, _aSpender);

        iArr[5] = _typeToken;

        if(_typeToken==1){ // LP
            iArr[6] = getTokenDecimals(aArr[2]);
            iArr[7] = getTokenTotalSupply(aArr[2]);

            iArr[8] = getTokenBalanceOf(aArr[2], _aAccount);
            iArr[9] = getTokenAllowance(aArr[2], _aAccount, _aSpender);

            iArr[10] = getTokenDecimals(aArr[3]);
            iArr[11] = getTokenTotalSupply(aArr[3]);

            iArr[12] = getTokenBalanceOf(aArr[3], _aAccount);
            iArr[13] = getTokenAllowance(aArr[3], _aAccount, _aSpender);
        }

        // sArr
        sArr[0] = getTokenName(_aToken);
        sArr[1] = getTokenSymbol(_aToken);

        if(_typeToken==1){ // LP
            sArr[2] = getTokenName(aArr[2]);
            sArr[3] = getTokenSymbol(aArr[2]);

            sArr[4] = getTokenName(aArr[3]);
            sArr[5] = getTokenSymbol(aArr[3]);
        }

        return (iArr, aArr, sArr);
    }
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