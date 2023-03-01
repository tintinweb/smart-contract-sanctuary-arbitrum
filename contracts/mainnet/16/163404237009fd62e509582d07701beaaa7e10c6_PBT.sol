/**
 *Submitted for verification at Arbiscan on 2023-03-01
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File @pefish/solidity-lib/contracts/contract/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev init function sets the original `owner` of the contract to the sender
     * account.
     */
    function __Ownable_init () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "only owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File @pefish/solidity-lib/contracts/interface/[email protected]



pragma solidity >=0.8.0;

interface IErc20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address guy) external view returns (uint256);
    function allowance(address src, address guy) external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);
    function transfer(address dst, uint256 wad) external returns (bool);
    function transferFrom(
        address src, address dst, uint256 wad
    ) external returns (bool);

//    function mint(address account, uint256 amount) external returns (bool);
//    function burn(uint256 amount) external returns (bool);

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
}


// File contracts/token/pbt.sol


pragma solidity ^0.8.0;


contract PBT is Ownable, IErc20 {
    address public pool; // farm pool address
    bool public transferLock = true;
    address public lastPresale;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    string public name;
    string public symbol;
    uint8 public override decimals = 18;
    uint256 public override totalSupply;

    constructor(
        uint256 _initialSupply,
        string memory _name,
        string memory _symbol
    ) {
        Ownable.__Ownable_init();

        name = _name;
        symbol = _symbol;
        _mint(msg.sender, _initialSupply);
    }

    function mint(address account, uint256 amount)
        external
        onlyOwner
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }

    function setLastPresale(address _lastPresale) external onlyOwner {
        lastPresale = _lastPresale;
    }

    function burn(uint256 amount) external onlyOwner returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        require(!transferLock || msg.sender == owner() || msg.sender == lastPresale, "transfer:: transfer locked");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(!transferLock || msg.sender == owner() || msg.sender == lastPresale, "transfer:: transfer locked");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply = totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account] - amount;
        totalSupply = totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function changePool(address _newPool) external onlyOwner {
        pool = _newPool;
    }

    function mintByPool(address _account, uint256 _amount)
        external
        returns (bool)
    {
        require(
            msg.sender == pool,
            "mintByPool:: must be operated by pool address"
        );
        _mint(_account, _amount);
        return true;
    }

    function lockTransfer() external onlyOwner {
        transferLock = true;
    }

    function unlockTransfer() external onlyOwner {
        transferLock = false;
    }
}