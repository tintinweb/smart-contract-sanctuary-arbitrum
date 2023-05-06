/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

   
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract MarsDogToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    address public lastSwapUser;
    uint public lastSwapTime;
    uint public lotteryAmount;

    uint8 private _decimals = 18;
    uint256 private _tTotal = 1000000000000000 * 10 ** 18;

    string private _name = "MarsDog";
    string private _symbol = "MarsDog";
    
    uint public _mkFee = 40;
    uint public _lotteryFee = 10;
    uint public _burnFee = 10;
    uint public lotteryInterval = 120;
    
    mapping(address => bool) public ammPairs;

    address public constant mkAddress = address(0x5F58173bacA14FC62c771DC84Af14e3b8079043e);

    constructor (address _holder) public {
        _tOwned[_holder] = _tTotal;
        _isExcludedFromFee[_holder] = true;
        _isExcludedFromFee[address(this)] = true;
        _owner = msg.sender;
        emit Transfer(address(0), _holder, _tTotal);
    }

    function setLotteryInterval(uint _lotteryInterval)external onlyOwner{
        lotteryInterval = _lotteryInterval;
    }

    function setAmmPair(address pair,bool hasPair)external onlyOwner{
        ammPairs[pair] = hasPair;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

     function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    receive() external payable {}

    function _take(uint256 tValue,address from,address to) private {
        _tOwned[to] = _tOwned[to].add(tValue);
        emit Transfer(from, to, tValue);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    struct Param{
        bool takeFee;
        uint tTransferAmount;
        uint tMk;
        uint tLottery;
        uint tBurn;
    }

     function _initParam(uint256 tAmount,Param memory param) private view  {
        uint tFee = 0;
        if( param.takeFee ){
            param.tMk = tAmount * _mkFee / 1000;
            param.tLottery = tAmount * _lotteryFee / 1000;
            param.tBurn = tAmount * _burnFee / 1000;
            tFee = param.tMk + param.tLottery + param.tBurn;
        }
        param.tTransferAmount = tAmount.sub(tFee);
    }

    function _takeFee(Param memory param,address from)private {
        if( param.tMk > 0 ){
            _take(param.tMk, from, mkAddress);
        }

        if( param.tBurn > 0 ){
            _take(param.tBurn, from, address(0x0));
        }

        if( param.tLottery > 0 ){
            _take(param.tLottery, from, address(this));
            lotteryAmount += param.tLottery;
        }
    }

    function _doTransfer(address sender, address recipient, uint256 tAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
         emit Transfer(sender, recipient, tAmount);
    }

    function _sendLottery()private{
        uint award = lotteryAmount;
        lotteryAmount = 0;
        _doTransfer(address(this),lastSwapUser,award);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
           
        uint time = block.timestamp;
        if (
            from != address(this) 
            && lotteryAmount >= 1e18
            && lastSwapTime > 0
            && lastSwapUser != address(0) 
            && time >= lastSwapTime + lotteryInterval 
            && lotteryAmount <= balanceOf(address(this))
            && !_isContract(lastSwapUser) ) {

            _sendLottery();
            lastSwapTime = 0;
            lastSwapUser = address(0);
        }
        
        Param memory param;
       
        bool takeFee = false;

        if( ammPairs[to] && !_isExcludedFromFee[from]  ){
            takeFee = true;
            lastSwapTime = block.timestamp;
            lastSwapUser = from;
        }

        if( ammPairs[from] && !_isExcludedFromFee[to] ){
            takeFee = true;
            lastSwapTime = block.timestamp;
            lastSwapUser = to;
        }

        param.takeFee = takeFee;
        _initParam(amount,param);
        _tokenTransfer(from,to,amount,param);
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount,Param memory param) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(param.tTransferAmount);
         emit Transfer(sender, recipient, param.tTransferAmount);
        if(param.takeFee){
            _takeFee(param,sender);
        }
    }

     function donateDust(address addr, uint256 amount) external onlyOwner {
        TransferHelper.safeTransfer(addr, _msgSender(), amount);
    }

    function donateEthDust(uint256 amount) external onlyOwner {
        TransferHelper.safeTransferETH(_msgSender(), amount);
    }
     function _isContract(address a) internal view returns(bool){
        uint256 size;
        assembly {size := extcodesize(a)}
        return size > 0;
    }
}