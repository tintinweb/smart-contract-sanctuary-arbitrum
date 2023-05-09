/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
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

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


contract HappBridge is ERC20, Ownable {

    using Counters for Counters.Counter;
    string public btc_bridge_address;

    /**Maximum minting amount per address*/
    uint256 private  MAX_CLAIM_COUNT = 24;

    uint256 public  TOTAL_MAX_CLAIM_COUNT = 18900;
    uint256 public  TOTAL_CLAIM_COUNT = 0;



    mapping (address => uint256) private _balances;
    mapping (address => bool) private _claimed;
    mapping (address => string) private _btcAddresses;
    mapping(string => address) private _btcToAddress;
    mapping (address => uint256) private _claimCount;
    mapping(uint256 => Order) private _orders;
    mapping(address => uint256[]) private  _userOrderIds;
    mapping (address => bool) private contractRegister;

    /**Fees required for brc20 transfer*/
    uint256 private bridgeEthToBtc_fee = 0.01 ether;

    /**The fee required to receive the token for the first time*/
    uint256 private claimHapp_fee = 0.01 ether;

    Counters.Counter private _orderIds;

    event DepositToOrder(
        uint256 indexed orderId,
        address indexed depositor,
        address indexed destinationCoin,
        uint256 amount
    );

    event CompleteOrder(uint256 indexed orderId, address indexed sender, address destinationCoin, uint256 amount);

    struct Order {
        address sender;
        address destinationCoin;
        uint256 amount;
        string btcAddress;
        uint256 status; // 0: Pending, 1: Completed, 2: Failed
    }
    
    constructor() ERC20("BRC20 Bridge HAPP", "HAPP") {
       _mint(address(this), 18900000 * (10 ** decimals()));
       _mint(msg.sender, 2100000 * (10 ** decimals()));
    }

    /**
     *claimHapp_fee：claimHapp_fee is mainly used to add initial liquidity and transfer fees
     *brc20Address：brc20Address is used to bind with erc20 address
     *mintCount: The amount that needs to be minted, cannot exceed the maximum minting per address
    */
    function mintTokenHapp(string memory brc20Address, uint256 mintCount) public payable {
        uint256 claimAmount = mintCount * 1000 * (10 ** decimals());
        require(TOTAL_CLAIM_COUNT + mintCount <= TOTAL_MAX_CLAIM_COUNT, "Maximum supply reached");
        require(balanceOf(address(this)) >= claimAmount, "Contract balance is not enough.");
        require(msg.value == claimHapp_fee * mintCount, "You need to pay ETH for each claim.");
        require(mintCount > 0 && mintCount <= MAX_CLAIM_COUNT, "You can only claim between 1 and 24 times.");
        require(_claimCount[msg.sender] + mintCount <= MAX_CLAIM_COUNT, "You can only claim up to 24 times.");
        _balances[msg.sender] += claimAmount;
        _btcAddresses[msg.sender] = brc20Address;
        _btcToAddress[brc20Address] = msg.sender;
        _claimCount[msg.sender] += mintCount;
        _transfer(address(this), msg.sender, claimAmount);
        TOTAL_CLAIM_COUNT += mintCount;
        emit Transfer(address(this), msg.sender, claimAmount);
    }

    /**
     *Cross-chain your erc20 token to brc20 
     *bridgeEthToBtc_fee:Fees for brc20 transfers
     *btcAddress:Receive BRC20 address
     *erc20ConractAddress: The contract address of the erc20 to be cross-chain
     *amount:Number of cross-chains，Accurate to 18 bits
    */
    function bridgeErc20ToBrc20(string memory brc20Address,address erc20ConractAddress, uint256 amount) public payable{
        require(bytes(_btcAddresses[msg.sender]).length != 0, "Please set your BTC address first.");
        require(msg.value >= bridgeEthToBtc_fee, "Insufficient fee.");
        require(contractRegister[erc20ConractAddress], "Contract address is not registered");
        require(amount > 0, "Amount should be greater than zero.");
        ERC20 token = ERC20(erc20ConractAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
        uint256 orderId = uint256(keccak256(abi.encodePacked(block.timestamp, block.number)));
        _orders[orderId] = Order(msg.sender, erc20ConractAddress, amount,brc20Address, 0);
        _userOrderIds[msg.sender].push(orderId);
        emit DepositToOrder(orderId, msg.sender, erc20ConractAddress, amount);
    }

    /**
    *Please send your brc20 token to this address, then you will receive the erc20 token
    *Notice：Make sure to set the btc address through the setAccountBrc20Address method
    */
    function bridgeBrc20ToErc20() public view returns (string memory) {
        return btc_bridge_address;
    }

    function withdrawErc20TokenToUser(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(tokenAddress != address(0), "Token address cannot be zero.");
        require(recipient != address(0), "Recipient address cannot be zero.");
        require(amount > 0, "Amount must be greater than zero.");    
        ERC20 token = ERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance.");    
        bool success = token.transfer(recipient, amount);
        require(success, "Transfer failed.");
    }

    function getMyOrder(uint256  orderId) public view returns (Order memory) {
        return _orders[orderId];
    }

    function completeOrder(uint256 orderId) public onlyOwner {
        require(_orders[orderId].status == 0, "Order is not pending.");
        _orders[orderId].status = 1;
        ERC20 token = ERC20(_orders[orderId].destinationCoin);
        require(token.transfer(_orders[orderId].sender, _orders[orderId].amount), "Token transfer failed.");
        emit CompleteOrder(orderId, _orders[orderId].sender, _orders[orderId].destinationCoin, _orders[orderId].amount);
    }

    function setAccountBrc20Address(string memory brc20Address) public {
        require(bytes(brc20Address).length > 0, "BTC address can't be empty");
        _btcAddresses[msg.sender] = brc20Address;
        _btcToAddress[brc20Address] = msg.sender;
    }

    function getMyErc20AddressByBrc20Address(string memory brc20Address) public view returns (address) {
        return _btcToAddress[brc20Address];
    }

    function getMyBrc20AddressByErc20Address(address  erc20Address) public view returns (string memory) {
        return _btcAddresses[erc20Address];
    }

    function setBrc20BridgeAddress(string memory btcAddress) public onlyOwner {
        btc_bridge_address = btcAddress;
    }

    function withdrawAllETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no ETH balance.");
        address payable sender = payable(msg.sender);
        sender.transfer(balance);
    }

    function registerContract(address newContract) public onlyOwner {
        contractRegister[newContract] = true;
    }

    function isRegistered(address contractAddress) public view returns (bool) {
        return contractRegister[contractAddress];
    }

    function setBridgeEthToBtcFee(uint256 bridgeEthToBtcFee) public onlyOwner {
        bridgeEthToBtc_fee = bridgeEthToBtcFee;
    }

    function getBridgeEthToBtcFee() public view returns (uint256) {
        return bridgeEthToBtc_fee;
    }

    function setMintAmount(uint256 mintAmount) public onlyOwner {
        MAX_CLAIM_COUNT = mintAmount;
    }


    function getMintAmount() public view returns (uint256) {
        return MAX_CLAIM_COUNT;
    }

    function setClaimHappFee(uint256 claimHappFee) public onlyOwner {
        claimHapp_fee = claimHappFee;
    }

    function getClaimHappFee() public view returns (uint256) {
        return claimHapp_fee;
    }

    function getUserOrderIds(address user) public view returns (uint256[] memory) {
        return _userOrderIds[user];
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    receive() external payable {}

}