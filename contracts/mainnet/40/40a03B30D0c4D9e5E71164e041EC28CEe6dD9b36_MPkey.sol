/**
 *Submitted for verification at Arbiscan on 2023-05-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.19;

abstract contract Adminable {
    address public admin;
    address public candidate;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event AdminCandidateRegistered(address indexed admin, address indexed candidate);

    constructor(address _admin) {
        require(_admin != address(0), "admin is the zero address");
        admin = _admin;
        emit AdminChanged(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return account == admin;
    }

    function registerAdminCandidate(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "new admin is the zero address");
        candidate = _newAdmin;
        emit AdminCandidateRegistered(admin, _newAdmin);
    }

    function confirmAdmin() external {
        require(msg.sender == candidate, "only candidate");
        emit AdminChanged(admin, candidate);
        admin = candidate;
        candidate = address(0);
    }
}


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool); //
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); //
    function balanceOf(address account) external view returns (uint256); //
    function mint(address account, uint256 amount) external returns (bool); //
    function approve(address spender, uint256 amount) external returns (bool); //
    function allowance(address owner, address spender) external view returns (uint256); //
}


interface IBaseToken is IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function setMinter(address _minter) external;
    function removeMinter(address _minter) external;
    function isMinter(address _account) external view returns (bool);
    function burn(uint256 _amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event MinterSet(address indexed minter);
    event MinterRemoved(address indexed minter);
}



/**
 * @title BaseToken
 * @notice A customizable simple ERC20 contract with minters
 */
contract BaseToken is IBaseToken, Adminable {

    // constants
    uint8 public constant decimals = 18;

    // state variables
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) private minters;

    constructor(address _admin, string memory _name, string memory _symbol) Adminable(_admin) {
        name = _name;
        symbol = _symbol;
        emit Transfer(address(0), msg.sender, 0);
    }

    // - config functions - //

    /**
     * @notice Add minter role to the specified address
     * @param _minter The address to grant minting authority
     */
    function setMinter(address _minter) external onlyAdmin {
        require(_minter != address(0), "invalid address");
        if (!minters[_minter]) {
            minters[_minter] = true;
            emit MinterSet(_minter);
        }
    }

    /**
     * @notice Remove minter role from the specified address
     * @param _minter The address to revoke minting authority
     */
    function removeMinter(address _minter) external onlyAdmin {
        require(minters[_minter], "only minter");
        delete minters[_minter];
        emit MinterRemoved(_minter);
    }

    /**
     * Returns true if the address is a minter
     * @param _account The address to check
     */
    function isMinter(address _account) external view returns (bool) {
        return minters[_account];
    }

    // - external state-changing functions - //

    /**
     * @notice Grant the allowance to a specified address
     * @param _spender The address to grant the allowance to
     * @param _value The amount to be allowed
     */
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0), "invalid address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @notice Increase the allowance to a specified address
     * @param _spender The address whose allowance will be increased
     * @param _addedValue The amount to be added to the allowance
     */
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool) {
        require(_spender != address(0), "invalid address");
        allowance[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    /**
     * @notice Decrease the allowance to a specified address
     * @param _spender The address whose allowance will be decreased
     * @param _subtractedValue The amount to be subtracted from the allowance
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {
        require(_spender != address(0), "invalid address");
        uint256 oldValue = allowance[msg.sender][_spender];
        require(_subtractedValue <= oldValue, "decreased allowance below zero");
        unchecked {
            allowance[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    /**
        @notice Transfer tokens to a specified address
        @param _to The address to transfer tokens to
        @param _value The amount to be transferred
        @return Success boolean
     */
    function transfer(address _to, uint256 _value) external returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @notice Transfer tokens from one address to another
        @param _from The address from which you want to send tokens
        @param _to The address to which you want to transfer tokens
        @param _value The amount of tokens to be transferred
        @return Success boolean
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    external
    returns (bool)
    {
        if (allowance[_from][msg.sender] != type(uint256).max) {
            require(allowance[_from][msg.sender] >= _value, "insufficient allowance");
            unchecked {
                allowance[_from][msg.sender] -= _value;
            }
        }
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * @notice Mint tokens and send them to the specified address
     * @param _to The address to receive the minted tokens
     * @param _value The amount of tokens to mint
     */
    function mint(address _to, uint256 _value) external returns (bool) {
        require(minters[msg.sender], "only minter");
        require(_to != address(0), "invalid address");
        totalSupply += _value;
        unchecked {
            balanceOf[_to] += _value;
        }
        emit Transfer(address(0), _to, _value);
        return true;
    }

    /**
     * @notice Burn own tokens
     * @param _value The amount of tokens to burn
     */
    function burn(uint256 _value) external returns (bool) {
        uint256 accountBalance = balanceOf[msg.sender];
        require(accountBalance >= _value, "burn amount exceeds balance");
        unchecked {
            balanceOf[msg.sender] = accountBalance - _value;
            // Overflow not possible: _value <= accountBalance <= totalSupply.
            totalSupply -= _value;
        }

        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    // - internal functions - //

    /**
     * @notice Transfer tokens
     * @dev Shared logic for transfer and transferFrom
     * @param _from The address sending tokens
     * @param _to The address receiving tokens
     * @param _value The amount of tokens to transfer
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_from != address(0), "invalid address: from");
        require(_to != address(0), "invalid address: to");
        uint256 accountBalance = balanceOf[_from];
        require(accountBalance >= _value, "insufficient balance");
        unchecked {
            balanceOf[_from] = accountBalance - _value;
            balanceOf[_to] += _value;
        }
        emit Transfer(_from, _to, _value);
    }

}


/**
 * @title MPkey
 * @notice
 * A simple ERC20 contract with minters
 * This token will be issued at a 1:1 ratio, corresponding to the amount of Multiplier Points held.
 */
contract MPkey is BaseToken {
    constructor(address _admin) BaseToken(_admin, "MP-KEY Token", "MPkey") {}
}