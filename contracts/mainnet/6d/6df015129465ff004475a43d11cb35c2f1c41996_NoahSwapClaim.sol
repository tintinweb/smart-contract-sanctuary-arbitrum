/**
 *Submitted for verification at Arbiscan.io on 2023-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

contract NoahSwapClaim is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;    
    uint256 constant chainId = 42161;
    mapping(uint256 => uint256) private _orderClaimed;
    address public _signer;
    address public _deputy;

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    bytes32 constant salt = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;    
    string private constant EIP712_DOMAIN  = "EIP712Domain(string name,string version,uint256 chainId,bytes32 salt)";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    string private constant ORDER_TYPE = "Order(uint256 id,address user,uint256 amount,address currency,address nft,uint256 tokenId,uint256 endTime)";
    bytes32 private constant ORDER_TYPEHASH = keccak256(abi.encodePacked(ORDER_TYPE));     
    bytes32 private constant DOMAIN_SEPARATOR = keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256("CLAIM"),
        keccak256("1"),
        chainId,
        salt
    ));

    struct Order {
			uint256 id;         //order id(must be unique)
			address user;       //user
			uint256 amount;     //amount of tokens
			address currency;   //currency (e.g., WETH)
            address nft;        //nft address
			uint256 tokenId;    //tokenId
			uint256 endTime;		//end time
    }

    event ClaimOrder(uint256 id, address user, address currency, uint256 amount, address nft, uint256 tokenId, uint256 endTime,uint256 timestamp);
    event Withdrawn(address sender, address to, uint256 amount);
    event WithdrawnNft(address sender, address nft, uint256 tokenId, address to);
    event ChangeSigner(address sender, address oldSigner, address newSigner);
    event ChangeDeputy(address sender, address oldDeputy, address newDeputy);

    function hashOrder(Order memory order) private pure returns (bytes32){
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                ORDER_TYPEHASH,
                order.id,
                order.user,
                order.amount,
                order.currency,
                order.nft,
                order.tokenId,
                order.endTime
            ))
        ));
    }

    function getSignResult(Order memory order, bytes32 sigR, bytes32 sigS, uint8 sigV) public pure returns (address) {
        return ecrecover(hashOrder(order), sigV, sigR, sigS);
    }

    function claim(Order[] memory orders, bytes32[] memory sigRs, bytes32[] memory sigSs, uint8[] memory sigVs) public {
        require(_signer != address(0), "wrong _signer.");
        for(uint256 i = 0; i < orders.length; i++) {
            Order memory order = orders[i];
            bytes32 sigR = sigRs[i];
            bytes32 sigS = sigSs[i];
            uint8 sigV = sigVs[i];
            require(_orderClaimed[order.id] == 0, "order claimed.");
            require(order.endTime > block.timestamp, "wrong endTime.");
            require(_signer == ecrecover(hashOrder(order), sigV, sigR, sigS), "signature check failure.");
            require(order.user == msg.sender, "user not same with sender.");
            require(order.currency != address(0), "wrong currency.");
            uint256 balance = IERC20(order.currency).balanceOf(address(this));
            require(balance >= order.amount, "Insufficient balance."); 
            require(order.nft == address(0), "wrong order.nft");
            IERC20(order.currency).safeTransfer(msg.sender, order.amount);
            _orderClaimed[order.id] = 1;
            emit ClaimOrder(order.id, msg.sender, order.currency, order.amount, order.nft, order.tokenId, order.endTime, block.timestamp);
        }
    }

    function claimEth(Order[] memory orders, bytes32[] memory sigRs, bytes32[] memory sigSs, uint8[] memory sigVs) public payable {
        require(_signer != address(0), "wrong _signer.");
        for(uint256 i = 0; i < orders.length; i++) {
            Order memory order = orders[i];
            bytes32 sigR = sigRs[i];
            bytes32 sigS = sigSs[i];
            uint8 sigV = sigVs[i];
            require(order.endTime > block.timestamp, "wrong endTime.");
            require(_orderClaimed[order.id] == 0, "order claimed.");
            require(_signer == ecrecover(hashOrder(order), sigV, sigR, sigS), "signature check failure.");
            require(order.user == msg.sender, "user not same with sender.");        
            require(order.currency == address(0), "wrong currency.");
            require(address(this).balance >= order.amount, "Insufficient eth."); 
            require(order.nft == address(0), "wrong order.nft");       
            payable(msg.sender).transfer(order.amount);
            _orderClaimed[order.id] = 1;
            emit ClaimOrder(order.id, msg.sender, order.currency, order.amount, order.nft, order.tokenId, order.endTime, block.timestamp);
        }
    }

    function claimNft(Order[] memory orders, bytes32[] memory sigRs, bytes32[] memory sigSs, uint8[] memory sigVs) public {
        require(_signer != address(0), "wrong _signer.");
        for(uint256 i = 0; i < orders.length; i++) {
            Order memory order = orders[i];
            bytes32 sigR = sigRs[i];
            bytes32 sigS = sigSs[i];
            uint8 sigV = sigVs[i];
            require(order.endTime > block.timestamp, "wrong endTime.");
            require(_orderClaimed[order.id] == 0, "order claimed.");
            require(_signer == ecrecover(hashOrder(order), sigV, sigR, sigS), "signature check failure.");
            require(order.user == msg.sender, "user not same with sender.");
            require(order.currency == address(0), "wrong currency.");
            require(order.nft != address(0), "wrong order.nft");
            IERC721(order.nft).transferFrom(address(this), msg.sender, order.tokenId);
            _orderClaimed[order.id] = 1;
            emit ClaimOrder(order.id, msg.sender, order.currency, order.amount, order.nft, order.tokenId, order.endTime, block.timestamp);
        }
    }

    function setSigner(address signer_) public {
        require(msg.sender == _deputy, "only deputy can do this");
        address oldSigner = _signer;
        _signer = signer_;
        emit ChangeSigner(msg.sender, oldSigner, signer_);
    }

    function setDeputy(address deputy) public onlyOwner{
        address oldDeputy = _deputy;
        _deputy = deputy;        
        emit ChangeDeputy(msg.sender, oldDeputy, deputy);
    }
}