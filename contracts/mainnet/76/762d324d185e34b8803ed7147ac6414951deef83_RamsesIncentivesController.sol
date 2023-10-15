/**
 *Submitted for verification at Arbiscan.io on 2023-10-15
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/RamsesIncentivesController.sol


pragma solidity ^0.8.16;


interface IFeeDistributor {
    function bribe(address _token, uint256 _amount) external;
}

interface IVotingEscrow {
    function deposit_for(uint256 _veID, uint256 _amount) external;

    function create_lock_for(
        uint256 _amount,
        uint256 _length,
        address _for
    ) external;
}

interface IVoter {
    function gauges(address _pool) external view returns (address);

    function feeDistributers(address _gauge) external view returns (address);
}

interface IGauge {
    function notifyRewardAmount(address _token, uint256 _amount) external;
}

interface IXORam {
    function convertRam(uint256 _amount) external;
}

contract RamsesIncentivesController {
    uint256 public constant MAX_LOCK = 126144000; // 4 years

    address public immutable timelock =
        0x9314fC5633329d285F744108D637E1222CEbae1c;
    address public immutable multisig =
        0x20D630cF1f5628285BfB91DfaC8C89eB9087BE1A;
    IERC20 public immutable RAM =
        IERC20(0xAAA6C1E32C55A7Bfa8066A6FAE9b42650F262418);
    IVotingEscrow public immutable veRAM =
        IVotingEscrow(0xAAA343032aA79eE9a6897Dab03bef967c3289a06);
    IVoter public immutable voter =
        IVoter(0xAAA2564DEb34763E3d05162ed3f5C2658691f499);
    IXORam public immutable xoRAM =
        IXORam(0xAAA1eE8DC1864AE49185C368e8c64Dd780a50Fb7);

    address public operator;

    event Rebase(uint256 _veID, uint256 _amount);
    event AddNewNFT(address _for, uint256 _amount);
    event VoteIncentives(address _feedist, uint256 _amount);
    event LPIncentives(address _gauge, uint256 _amount);

    modifier onlyRamsesTimelock() {
        require(msg.sender == timelock, "!TL");
        _;
    }

    modifier onlyRamsesAuthorized() {
        require(msg.sender == multisig || msg.sender == operator, "!AUTH");
        _;
    }

    constructor() {
        operator = msg.sender;
        RAM.approve(address(veRAM), type(uint256).max);
        RAM.approve(address(xoRAM), type(uint256).max);
    }

    ///@dev send a direct rebase to an NFT ID
    function rebase(uint256 _veID, uint256 _amount)
        external
        onlyRamsesAuthorized
    {
        veRAM.deposit_for(_veID, _amount);
        emit Rebase(_veID, _amount);
    }

    ///@dev initiate a new veNFT using amounts in the contract
    function newLock(uint256 _amount, address _for)
        external
        onlyRamsesAuthorized
    {
        veRAM.create_lock_for(_amount, MAX_LOCK, _for);
        emit AddNewNFT(_for, _amount);
    }

    ///@dev distribute as xoRAM voting incentives for a pool
    function incentivizeVotes(address _pool, uint256 _xTokenAmount)
        external
        onlyRamsesAuthorized
    {
        xoRAM.convertRam(_xTokenAmount);
        IFeeDistributor _feeDist = IFeeDistributor(
            voter.feeDistributers(voter.gauges(_pool))
        );
        IERC20(address(xoRAM)).approve(address(_feeDist), _xTokenAmount);
        _feeDist.bribe(address(xoRAM), _xTokenAmount);
        emit VoteIncentives(address(_feeDist), _xTokenAmount);
    }

    ///@dev distribute as xoRAM LP incentives for a pool
    function incentivizePool(address _pool, uint256 _xTokenAmount)
        external
        onlyRamsesAuthorized
    {
        xoRAM.convertRam(_xTokenAmount);
        IGauge gauge = IGauge(voter.gauges(_pool));
        IERC20(address(xoRAM)).approve(address(gauge), _xTokenAmount);
        gauge.notifyRewardAmount(address(xoRAM), _xTokenAmount);
        emit LPIncentives(_pool, _xTokenAmount);
    }

    ///@dev change the operator address
    function changeOperator(address _newOperator) external onlyRamsesTimelock {
        operator = _newOperator;
    }

    ///@dev timelock call to withdraw liquid RAM in case of an emergency
    function timelockWithdraw(
        address token,
        uint256 amount,
        address to
    ) external onlyRamsesTimelock {
        IERC20(token).transfer(to, amount);
    }
}