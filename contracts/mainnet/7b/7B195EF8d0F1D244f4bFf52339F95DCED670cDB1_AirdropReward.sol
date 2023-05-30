// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {IERC20} from "./_external/IERC20.sol";
import "./_external/Ownable.sol";

interface IAirdropHelper {
    function userAirdrop(address user) external view returns (uint256);
}

interface IWFIRE {
    function deposit(uint256 fires) external returns (uint256);

    function burn(uint256 wfires) external returns (uint256);
}

/**
 * @title AirdropReward contract
 *
 * @notice Users can deposit upto their airdropped amount and receive 3x amount after endTime
 *
 */
contract AirdropReward is Ownable {
    IAirdropHelper public airdropHelper;
    IERC20 public WFIRE;
    IERC20 public FIRE;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public multiplier; // 3e18 => 3x

    mapping(address => uint256) public userInfo; // WFIRE amount

    event Deposit(address indexed user, uint256 amount, uint256 wfireAmount);
    event Withdraw(address indexed user, uint256 amount, uint256 wfireAmount, uint256 fireAmount);

    uint8 entered;
    modifier nonReentrant() {
        require(entered == 0, "Already entered");
        entered = 1;
        _;
        entered = 0;
    }

    constructor() {
        initialize(msg.sender);
    }

    function setTokens(IERC20 _FIRE, IERC20 _WFIRE) external onlyOwner {
        FIRE = _FIRE;
        WFIRE = _WFIRE;
    }

    function setAirdropHelper(IAirdropHelper _airdropHelper) external onlyOwner {
        airdropHelper = _airdropHelper;
    }

    function setStartTime(uint256 time) external onlyOwner {
        startTime = time;
    }

    function setEndTime(uint256 time) external onlyOwner {
        endTime = time;
    }

    function setMultiplier(uint256 _multiplier) external onlyOwner {
        multiplier = _multiplier;
    }

    function adminWFIREWithdraw(uint256 amount) external onlyOwner {
        WFIRE.transfer(msg.sender, amount);
    }

    function adminFIREWithdraw(uint256 amount) external onlyOwner {
        FIRE.transfer(msg.sender, amount);
    }

    /**
     * @notice deposit FIRE
     *
     * amount {uint256} FIRE token amount
     */
    function deposit(uint256 amount) external nonReentrant {
        require(block.timestamp <= startTime, "Can't deposit");
        FIRE.transferFrom(msg.sender, address(this), amount);
        FIRE.approve(address(WFIRE), amount);
        uint256 wfireAmount = IWFIRE(address(WFIRE)).deposit(amount);
        require(
            userInfo[msg.sender] + wfireAmount <= airdropHelper.userAirdrop(msg.sender),
            "Reached Max"
        );

        userInfo[msg.sender] += wfireAmount;

        emit Deposit(msg.sender, amount, wfireAmount);
    }

    /**
     * @notice withdraw all
     */
    function withdraw() external nonReentrant {
        require(block.timestamp >= endTime, "Can't withdraw");
        require(userInfo[msg.sender] > 0, "Nothing");

        uint256 totalWFireAmount = (userInfo[msg.sender] * multiplier) / 1 ether;
        uint256 totalFireAmount = IWFIRE(address(WFIRE)).burn(totalWFireAmount);
        FIRE.transfer(msg.sender, totalFireAmount);

        emit Withdraw(msg.sender, userInfo[msg.sender], totalWFireAmount, totalFireAmount);

        userInfo[msg.sender] = 0;
    }
}

pragma solidity 0.8.4;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity 0.8.4;

import "./Initializable.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize(address sender) public virtual initializer {
        _owner = sender;
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
        require(isOwner());
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
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

pragma solidity 0.8.4;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool wasInitializing = initializing;
        initializing = true;
        initialized = true;

        _;

        initializing = wasInitializing;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.

        // MINOR CHANGE HERE:

        // previous code
        // uint256 cs;
        // assembly { cs := extcodesize(address) }
        // return cs == 0;

        // current code
        address _self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(_self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}