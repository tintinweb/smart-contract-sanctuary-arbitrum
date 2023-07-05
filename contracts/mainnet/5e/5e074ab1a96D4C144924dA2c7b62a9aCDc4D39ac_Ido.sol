/**
 *Submitted for verification at Arbiscan on 2023-07-05
*/

//  Created By: ChainTool
//  Website: https://chaintool.app
//  Telegram: https://t.me/chaintool_app

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;


library AddressUpgradeable {
    
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        if (returndata.length > 0) {
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

pragma solidity ^0.8.2;

abstract contract Initializable {
   
    uint8 private _initialized;

    bool private _initializing;

    event Initialized(uint8 version);

    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

pragma solidity ^0.8.0;

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity ^0.8.0;

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
 
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
library Address {
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

 
interface ERC20 {
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function locked(address account, uint256 amount, uint256 time) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
 
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
 
    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
 
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
 
    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
 
    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
 
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Ido is OwnableUpgradeable{
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 mToken;

    uint256 public supply;
    uint256 public soldToken;
    uint256 public invalidToken;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public minAmount; 
    uint256 public maxAmount;
    uint256 public enableClaim;

    uint256 public priceNumerator; 
    uint256 public priceDenominator;

    uint256 [] public generationFees;
    uint256 public feeDenominator;

    mapping(address => uint256) public sales;
    mapping(address => bool) public bounds;   
    mapping(address => address) public inviters;

    event BuyToken(address account, uint256 amount);
    
    function initialize(
        address _mToken,
        uint256 _supply,
        uint256 _enableClaim,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _priceNumerator,
        uint256 _startTime,
        uint256 _endTime,
        uint256 [] memory _genFees,
        address service
    )  external initializer payable {
        __Ownable_init();

        mToken = ERC20(_mToken);
        supply = _supply;
        enableClaim = _enableClaim;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        startTime = _startTime;
        endTime = _endTime;
        priceNumerator = _priceNumerator;
        if (_genFees.length > 0) generationFees = _genFees;
        payable(service).transfer(msg.value);
        priceDenominator = 10 ** 22;
        feeDenominator = 1000;
    }

    receive() external payable {}

    function preSale(address inviter) external payable {
        require(block.timestamp > startTime && block.timestamp < endTime, "Is disable");
        require(bounds[msg.sender] == false, "Only one purchase per address");
        require(msg.value >= minAmount && msg.value <= maxAmount, "Amount is out of range");
        uint256 mTokenDecimals = uint256(mToken.decimals());
        uint256 tokenNum;
        uint256 factor;
        if (mTokenDecimals > 18) {
            factor = 10 ** (mTokenDecimals - 18);
            tokenNum = msg.value.mul(factor).mul(priceDenominator).div(priceNumerator);    
        }else {
            factor = 10 ** (18 - mTokenDecimals);
            tokenNum = msg.value.mul(priceDenominator).div(priceNumerator).div(factor);    
        }
        require(poolLeft() >= tokenNum, "Insufficient pool");

        soldToken = soldToken.add(tokenNum);
        sales[msg.sender] = tokenNum;
        emit BuyToken(msg.sender, tokenNum);

        _inviteFee(inviter, address(msg.sender), msg.value);
    }

    function _inviteFee(address sharer, address from, uint256 amount) internal {
        if (bounds[from]) return;
        bounds[from] = true;
        if (generationFees.length == 0) return;
        if (bounds[sharer] == false) return;
        address invitee = from;
        uint256 reward;
        inviters[from] = sharer;
        for (uint i=0; i<generationFees.length; i++) {
            address inviter = inviters[invitee];
            if (inviter == address(0) || inviter == invitee){
                return;
            }
            reward = amount.mul(generationFees[i]).div(feeDenominator);
            payable(inviter).transfer(reward);
            invitee = inviter;
        }
    }

    function withdrawFunds(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    function withdrawAllFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken() external {
        uint256 receiveToken = sales[msg.sender];
        require(receiveToken > 0, "Amount to withdraw too high");
        require(withdrawable(), "Cannot take");
        mToken.safeTransfer(address(msg.sender), receiveToken);
        sales[msg.sender] = 0;
    }

    function withdrawable() public view returns(bool) {
        return enableClaim > 0 || block.timestamp > endTime;
    }

    function burnToken() external onlyOwner {
        invalidToken = poolLeft();
        mToken.safeTransfer(0x000000000000000000000000000000000000dEaD, invalidToken);
    }

    function takeToken() external onlyOwner {
        invalidToken = poolLeft();
        mToken.safeTransfer(msg.sender, invalidToken);
    }

    function setSupply(uint256 value) external onlyOwner {
       require(soldToken == 0, "Pool has started");
       supply = value;
    }

    function setPrice(uint256 valueNumerator) external onlyOwner {
       require(soldToken == 0, "Pool has started");
       priceNumerator = valueNumerator;
    }

    function updateStartAndEndTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(soldToken == 0, "Pool has started");
        require(_startTime < _endTime, "New startTime must be lower than new endTime");
        require(block.timestamp < _startTime, "New startTime must be higher than current time");

        startTime = _startTime;
        endTime = _endTime;
    }

    function updateMinAndMaxAmount(uint256 _minAmount, uint256 _maxAmount) external onlyOwner {
        require(soldToken == 0, "Pool has started");
        require(_minAmount < _maxAmount, "New minAmount must be lower than new maxAmount");

        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }

    function stopIdo() external onlyOwner {
        endTime = block.timestamp;
    }

    function setGenerationFees(uint256 [] memory genFees) external onlyOwner {
        require(soldToken == 0, "Pool has started");
        generationFees = genFees;
    }

    function getGenerationFees() external view returns (uint256[] memory) {
        return generationFees;
    }

    function poolLeft() public view returns(uint256) {
        uint256 unableToken = soldToken.add(invalidToken);
        if (supply > unableToken){
            return supply.sub(unableToken);
        }
        return 0;
    }

    function getIdoInfos() external view returns(uint256[] memory, uint256[] memory, string[] memory, address[] memory){
        uint256[] memory array = new uint256[](12);
        array[0] = supply;
        array[1] = soldToken;
        array[2] = poolLeft();
        array[3] = minAmount;
        array[4] = maxAmount;
        array[5] = priceNumerator;
        array[6] = startTime;
        array[7] = endTime;
        array[8] = mToken.decimals();
        array[9] = 18;
        array[10] = mToken.totalSupply();
        array[11] = address(this).balance;
        string[] memory strs = new string[](2);
        strs[0] = mToken.symbol();
        strs[1] = '';
        address[] memory addresses = new address[](1);
        addresses[0] = address(mToken);
        return (array, generationFees, strs, addresses);
    }

    function getUserInfos(address account) external view returns(uint256[] memory){
        uint256[] memory array = new uint256[](4);
        array[0] = bounds[account] ? 1 : 0;
        array[1] = withdrawable() ? 1 : 0;
        array[2] = sales[account];
        array[3] = account.balance;
        return array;
    }
}