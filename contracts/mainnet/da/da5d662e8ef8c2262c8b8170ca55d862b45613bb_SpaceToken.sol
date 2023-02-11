/**
 *Submitted for verification at Arbiscan on 2023-02-11
*/

// SPDX-License-Identifier: MIT

//SpaceSwap DEX
//https://discord.gg/wCNSDd7QCH
pragma solidity ^0.8.11;

abstract contract Ownable {
    address private _owner;
    address private newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        newOwner = _newOwner;
    }

    function acceptOwnership() public virtual {
        require(msg.sender == newOwner, "Ownable: sender != newOwner");
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address _newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}

pragma solidity ^0.8.11;

contract SpaceToken is Ownable {
    string public constant name = "SpaceSwap Token";
    string public constant symbol = "SPACE";
    uint256 constant public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    struct MinterInfo {
        bool canMint;
        bool exists;
    }
    mapping(address => MinterInfo) public isMinter;
    //contains all addresses that are or were minters (not including the owner). Makes it much easier to check the current status.
    address[] public minterHistory;

    function minterHistoryLength() external view returns (uint) {
        return minterHistory.length;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burned(address indexed from, uint amount);
    event Mint(address indexed to, uint amount);
    event SetMinter(address indexed minter, bool enabled);

    //for permit()
    bytes32 immutable public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);

        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function setMinter(address minter, bool enabled) external onlyOwner {
        if(!isMinter[minter].exists) {
            minterHistory.push(minter);
        }
        isMinter[minter] = MinterInfo(enabled, true);
        emit SetMinter(minter, enabled);
    }

    function mint(address to, uint amount) external {
        require(owner() == msg.sender || isMinter[msg.sender].canMint, "mint: forbidden");
        totalSupply += amount;
        balances[to] += amount;
        emit Mint(to, amount);
    }

    /**
        @notice Getter to check the current balance of an address
        @param _owner Address to query the balance of
        @return Token balance
     */
    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    /**
        @notice Getter to check the amount of tokens that an owner allowed to a spender
        @param _owner The address which owns the funds
        @param _spender The address which will spend the funds
        @return The amount of tokens still available for the spender
     */
    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'SPACE: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))));
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'SPACE: INVALID_SIGNATURE');

        allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
        @notice Approve an address to spend the specified amount of tokens on behalf of msg.sender
        @param _spender The address which will spend the funds.
        @param _value The amount of tokens to be spent.
        @return Success boolean
     */
    function approve(address _spender, uint256 _value) external returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /** shared logic for transfer and transferFrom */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "Insufficient balance");
        unchecked {
            balances[_from] -= _value;
            if(_to != address(0)) {
                balances[_to] = balances[_to] + _value;
            }
            else {
                totalSupply -= _value;
                emit Burned(_from, _value);
            }
        }
        emit Transfer(_from, _to, _value);
    }

    /**
        @notice Burns tokens owned by msg.sender
        @param amount The amount to be burned
     */
    function burn(uint amount) external {
        _transfer(msg.sender, address(0), amount);
    }

    /**
        @notice Transfer tokens to a specified address
        @param _to The address to transfer to
        @param _value The amount to be transferred
        @return Success boolean
     */
    function transfer(address _to, uint256 _value) external returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @notice Transfer tokens from one address to another
        @param _from The address which you want to send tokens from
        @param _to The address which you want to transfer to
        @param _value The amount of tokens to be transferred
        @return Success boolean
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        unchecked {
            allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        }
        _transfer(_from, _to, _value);
        return true;
    }
}