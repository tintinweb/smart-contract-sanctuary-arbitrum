/**
 *Submitted for verification at Arbiscan.io on 2024-01-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

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

contract LevelDaoVesting {

    IERC20 public LVL;

    uint256 public constant start = 1705327200; // Sun Jan 15 2024 14:00:00 UTC
    uint256 public constant duration = 90 days; // 90 days

    struct UserInfo {
        uint256 amount;
        uint256 claimed;
    }

    mapping(address => UserInfo) public users;
    address public admin;
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor(address _lvl) {
        admin = msg.sender;
        LVL = IERC20(_lvl);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function _getUserClaimableLVL(address _addr) internal view returns (uint256) {
        if ( block.timestamp <= start) {
            return 0;
        }
        UserInfo memory _user = users[_addr];
        uint256 _vestedDuration = block.timestamp - start;
        if (_vestedDuration > duration) {
            _vestedDuration = duration;
        }
        return (_vestedDuration / duration) * _user.amount - _user.claimed;
    }
    

    function claimableLVL() public view returns (uint256) {
        return _getUserClaimableLVL(msg.sender);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function claim() external {
        UserInfo storage _user = users[msg.sender];
        require(_user.amount != 0, "Not found");
        uint256 _claimable = _getUserClaimableLVL(msg.sender);
        require(_claimable > 0, "All rewards were claimed");
        _user.claimed = _user.claimed + _claimable;
        LVL.transfer(msg.sender, _claimable);
    }

    /* ========== ADMIN FUNCTIONS ========== */

    function rescue(uint256 _amount) external onlyAdmin {
        LVL.transfer(admin, _amount);
    }

    function addAddresses(address[] calldata _addrs, uint256[] calldata _amounts) external onlyAdmin {
        require(_addrs.length == _amounts.length, "missmatch");
        for (uint8 i = 0; i < _addrs.length; i++) {
            UserInfo storage _user = users[_addrs[i]];
            _user.amount = _amounts[i];
        }
    }

    function removeAddress(address _addr) external onlyAdmin {
        UserInfo storage _user = users[_addr];
        _user.amount = 0;
        _user.claimed = 0;
    }

    function updateAddress(address _oldAddress, address _newAddress) external onlyAdmin {
        require(_newAddress != address(0) && _newAddress != _oldAddress, "invalid");
        UserInfo storage _oldUser = users[_oldAddress];
        UserInfo storage _newUser = users[_newAddress];
        _newUser.amount = _oldUser.amount;
        _newUser.claimed = _oldUser.claimed;
        _oldUser.amount = 0;
        _oldUser.claimed = 0;
    }

    function changeAdmin(address _address) external onlyAdmin {
        require(_address != address(0), "invalid");
        admin = _address;
    }
}