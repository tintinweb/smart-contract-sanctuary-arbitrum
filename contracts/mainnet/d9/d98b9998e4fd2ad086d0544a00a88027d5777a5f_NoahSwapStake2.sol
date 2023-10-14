/**
 *Submitted for verification at Arbiscan.io on 2023-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
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
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner {
        require(isOwner(msg.sender));
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function isOwner(address addr) public view returns (bool) {
        return owner == addr;
    }
}

contract NoahSwapStake2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 constant chainId = 42161;
    address public _signer;
    address public _deputy;

    struct Order{
        address user;
        address token;
        uint256 amount;
        uint256 endTime;
        uint256 stakedAndRewards;
        uint8 status;
    }
    mapping (uint256 => Order) public _orderLists; 

    event Staked(uint256 id, address user, address token, uint256 amount, uint256 endTime);
    event Withdrawn(uint256 id, address user, address token, uint256 amount, uint256 endTime, uint256 stakedAndRewards);
    event Renewal(uint256 id, address user, address token, uint256 amount, uint256 endTime);
    event ChangeDeputy(address sender, address oldDeputy, address newDeputy);

    bytes32 constant salt = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;    
    string private constant EIP712_DOMAIN  = "EIP712Domain(string name,string version,uint256 chainId,bytes32 salt)";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    string private constant ORDER_TYPE = "Order(address user,address token,uint256 amount,uint256 endTime,uint256 stakedAndRewards,uint8 status)";
    bytes32 private constant ORDER_TYPEHASH = keccak256(abi.encodePacked(ORDER_TYPE));     
    bytes32 private constant DOMAIN_SEPARATOR = keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256("STAKE"),
        keccak256("1"),
        chainId,
        salt
    ));

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    event Received(address, uint);

    function stake(uint256 id, address token, uint256 amount, uint256 endTime) public {
        require(endTime > block.timestamp, "invalid endTime");
        require(amount > 0, "invalid amount");
        require(_orderLists[id].status == 0, "order exist");
        uint256 balance = IERC20(token).balanceOf(msg.sender);
        require(balance >= amount, "insufficient balance");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _orderLists[id] = Order(msg.sender, token, amount, endTime, 0, 1);
        emit Staked(id, msg.sender, token, amount, endTime);
    }

    function stakeEth(uint256 id, address token, uint256 amount, uint256 endTime) public payable{
        require(endTime > block.timestamp, "invalid endTime");
        require(token == address(0), "invalid token");
        require(amount > 0, "invalid amount");
        require(amount == msg.value, "invalid amount");
        require(_orderLists[id].status == 0, "order exist");
        _orderLists[id] = Order(msg.sender, token, amount, endTime, 0, 1);
        emit Staked(id, msg.sender, token, amount, endTime);
    }
    
    function getStakeInfo(uint256 id) public view returns(Order memory orderInfo) {
        return _orderLists[id];
    }

    function hashOrder(Order memory order) private pure returns (bytes32){
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                ORDER_TYPEHASH,
                order.user,                
                order.token,
                order.amount,
                order.endTime,
                order.stakedAndRewards,
                order.status
            ))
        ));
    }

    function verify(address signer, Order memory order, bytes32 sigR, bytes32 sigS, uint8 sigV) public pure returns (bool) {
        return signer == ecrecover(hashOrder(order), sigV, sigR, sigS);
    }

    function withdraw(uint256[] memory ids, Order[] memory orders, bytes32[] memory sigRs, bytes32[] memory sigSs, uint8[] memory sigVs) public {
        require(_signer != address(0), "wrong _signer.");
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            bytes32 sigR = sigRs[i];
            bytes32 sigS = sigSs[i];
            uint8 sigV = sigVs[i];
            require(_signer == ecrecover(hashOrder(orders[i]), sigV, sigR, sigS), "signature check failure.");
            Order storage order = _orderLists[id];
            require(order.amount == orders[i].amount, "signature data failure.");
            require(order.status == 1, "withdrawn or not exist");
            require(block.timestamp > order.endTime, "too eraly to withdraw");
            require(order.user == msg.sender, "the order not belong to you");
            IERC20(order.token).safeTransfer(msg.sender, orders[i].stakedAndRewards);
            order.status = 2;
            order.stakedAndRewards = orders[i].stakedAndRewards;
            emit Withdrawn(id, msg.sender, order.token, order.amount, order.endTime, order.stakedAndRewards);
        }
    }

    function withdrawEth(uint256[] memory ids, Order[] memory orders, bytes32[] memory sigRs, bytes32[] memory sigSs, uint8[] memory sigVs) public payable{
        require(_signer != address(0), "wrong _signer.");
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            bytes32 sigR = sigRs[i];
            bytes32 sigS = sigSs[i];
            uint8 sigV = sigVs[i];
            require(_signer == ecrecover(hashOrder(orders[i]), sigV, sigR, sigS), "signature check failure.");
            Order storage order = _orderLists[id];
            require(order.amount == orders[i].amount, "signature data failure.");
            require(order.status == 1, "withdrawn or not exist");
            require(block.timestamp > order.endTime, "too eraly to withdraw");
            require(order.user == msg.sender, "the order not belong to you");
            payable(msg.sender).transfer(orders[i].stakedAndRewards);
            order.status = 2;
            order.stakedAndRewards = orders[i].stakedAndRewards;
            emit Withdrawn(id, msg.sender, order.token, order.amount, order.endTime, order.stakedAndRewards);
        }
    }

    function renewal(uint256[] memory ids, uint256[] memory newEndTimes) public {
        require(msg.sender == _deputy, "only deputy can do this");
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 newEndTime = newEndTimes[i];
            Order storage order = _orderLists[id];
            require(order.status == 1, "withdrawn or not exist");
            require(newEndTime > order.endTime, "new endTime must larger than old endTime");
            order.endTime = newEndTime;
            emit Renewal(id, order.user, order.token, order.amount, order.endTime);
        }
    }

    function setSigner(address signer_) public {
        require(msg.sender == _deputy, "only deputy can do this");
        _signer = signer_;
    }

    function setDeputy(address deputy_) public onlyOwner{
        address oldDeputy = _deputy;
        _deputy = deputy_;        
        emit ChangeDeputy(msg.sender, oldDeputy, deputy_);
    }
}