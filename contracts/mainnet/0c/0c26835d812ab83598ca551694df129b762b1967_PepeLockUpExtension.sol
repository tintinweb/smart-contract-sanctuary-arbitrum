//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title PepeLockUpExtension contract.
 * @dev This contract is used to lock up Balancer PEG80-WETH20 lp tokens based on exiting lock information in PepeLockUp.sol.
 */
import { Ownable2Step } from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import { PepeEsPegLPHelper } from "./PepeEsPegLPHelper.sol";
import { Lock, LockExtension } from "../Structs.sol";
import { IPepeProxyLpToken } from "../interfaces/IPepeProxyLpToken.sol";
import { IPepeLockUp } from "../interfaces/IPepeLockUp.sol";
import { IPepeLPTokenPool } from "../interfaces/IPepeLPTokenPool.sol";

contract PepeLockUpExtension is Ownable2Step, PepeEsPegLPHelper {
    IPepeProxyLpToken public immutable pPlpToken;

    IPepeLockUp public pepeLockUp;
    IPepeLPTokenPool public pLpTokenPool;

    mapping(address user => LockExtension) public extensionLockDetails;

    event LockedProxyLp(address indexed user, uint256 amount);
    event UnlockedProxyLp(address indexed user, uint256 amount);
    event PepeLockUpUpdated(address indexed pepeLockUp);
    event LpTokenPoolUpdated(address indexed pLpTokenPool);
    event PepeLockUnlockFailed(address indexed user);

    constructor(address _pepeLockUp, address _pLpToken, address _pLpTokenPool) {
        pepeLockUp = IPepeLockUp(_pepeLockUp);
        pPlpToken = IPepeProxyLpToken(_pLpToken);
        pLpTokenPool = IPepeLPTokenPool(_pLpTokenPool);
    }

    function lockProxyLp(uint256 amount) external {
        require(amount != 0, "amount is 0");
        require(pPlpToken.transferFrom(msg.sender, address(this), amount), "pplp transfer failed");
        Lock memory userPepeLockDetails = pepeLockUp.getLockDetails(msg.sender);
        uint48 currentLockDuration = pepeLockUp.lockDuration();

        if (userPepeLockDetails.totalLpShare == 0) {
            //user unlocked all their lp tokens
            //lock up their current share for current lock duration
            _lock(msg.sender, amount, uint48(block.timestamp + currentLockDuration));
            return;
        }
        if (userPepeLockDetails.unlockTimestamp > block.timestamp) {
            //user has an existing lock
            _lock(msg.sender, amount, uint48(userPepeLockDetails.unlockTimestamp));
            return;
        }
        if (userPepeLockDetails.unlockTimestamp < block.timestamp) {
            //user has an existing lock but is available to unlock
            //do not lock lp tokens.
            _lock(msg.sender, amount, uint48(block.timestamp));
            return;
        }
    }

    function _lock(address _user, uint256 _amount, uint48 _lockTime) private {
        //transfer lp tokens from pool
        pLpTokenPool.fundContractOperation(address(this), _amount);

        LockExtension memory lockExtension = extensionLockDetails[_user];

        if (lockExtension.user == address(0)) {
            //user has no existing lock
            //create a new lock
            extensionLockDetails[_user] = LockExtension(_user, _amount, _lockTime);
            emit LockedProxyLp(_user, _amount);
        } else {
            //user has an existing lock
            //add to existing lock
            extensionLockDetails[_user].amount += _amount;
            emit LockedProxyLp(_user, _amount);
        }
    }

    function unLockLpPegWeth() external {
        LockExtension memory lockExtension = extensionLockDetails[msg.sender];
        require(lockExtension.lockDuration <= uint48(block.timestamp), "lock not expired");
        uint256 amount = lockExtension.amount;
        require(lockExtension.user != address(0), "no lock in lock extension");
        require(amount != 0, "no lock in lock extension");

        pPlpToken.burn(address(this), amount);

        //remove lock
        delete extensionLockDetails[msg.sender];

        _exitPool(amount);

        emit UnlockedProxyLp(msg.sender, amount);
    }

    function updatePepeLockUp(address _pepeLockUp) external onlyOwner {
        require(_pepeLockUp != address(0), "zero address");

        pepeLockUp = IPepeLockUp(_pepeLockUp);
        emit PepeLockUpUpdated(_pepeLockUp);
    }

    function updateLpTokenPool(address _pLpTokenPool) external onlyOwner {
        require(_pLpTokenPool != address(0), "zero address");

        pLpTokenPool = IPepeLPTokenPool(_pLpTokenPool);
        emit LpTokenPoolUpdated(_pLpTokenPool);
    }

    function getUserExtensionLockDetails(address user) external view returns (LockExtension memory) {
        return extensionLockDetails[user];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IWeightedPoolFactory, IWeightedPool, IAsset, IVault } from "../interfaces/IWeightedPoolFactory.sol";
import { IPepeLockUp } from "../interfaces/IPepeLockUp.sol";

abstract contract PepeEsPegLPHelper {
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant PEG = 0x4fc2A3Fb655847b7B72E19EAA2F10fDB5C2aDdbe;
    address public constant VAULT_ADDRESS = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address public constant LP_TOKEN = 0x3eFd3E18504dC213188Ed2b694F886A305a6e5ed;
    bytes32 public constant POOL_ID = 0x3efd3e18504dc213188ed2b694f886a305a6e5ed00020000000000000000041d;

    event AddedLP(uint256 wethAmount, uint256 pegAmount, uint256 minBlpOut);

    function _joinPool(uint256 wethAmount, uint256 pegAmount, uint256 minBlpOut) internal {
        (address token0, address token1) = sortTokens(PEG, WETH);
        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(token0);
        assets[1] = IAsset(token1);

        uint256[] memory maxAmountsIn = new uint256[](2);
        if (token0 == WETH) {
            maxAmountsIn[0] = wethAmount;
            maxAmountsIn[1] = pegAmount;
        } else {
            maxAmountsIn[0] = pegAmount;
            maxAmountsIn[1] = wethAmount;
        }

        IERC20(PEG).approve(VAULT_ADDRESS, pegAmount);
        IERC20(WETH).approve(VAULT_ADDRESS, wethAmount);

        bytes memory userDataEncoded = abi.encode(
            IWeightedPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            maxAmountsIn,
            minBlpOut
        );
        IVault.JoinPoolRequest memory inRequest = IVault.JoinPoolRequest(assets, maxAmountsIn, userDataEncoded, false);
        IVault(VAULT_ADDRESS).joinPool(POOL_ID, address(this), address(this), inRequest);

        emit AddedLP(wethAmount, pegAmount, minBlpOut);
    }

    function _exitPool(uint256 lpAmount) internal {
        (address token0, address token1) = sortTokens(PEG, WETH);
        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(token0);
        assets[1] = IAsset(token1);

        uint256[] memory minAmountsOut = new uint256[](2);
        minAmountsOut[0] = 1;
        minAmountsOut[1] = 1;

        IERC20(LP_TOKEN).approve(VAULT_ADDRESS, lpAmount);

        bytes memory userData = abi.encode(IWeightedPool.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, lpAmount);

        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest(assets, minAmountsOut, userData, false);
        IVault(VAULT_ADDRESS).exitPool(POOL_ID, address(this), payable(msg.sender), request); //send both peg and weth to the locker (user).
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        require(tokenA != address(0), "ZERO_ADDRESS");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct User {
    uint256 totalPegPerMember;
    uint256 pegClaimed;
    bool exist;
}

struct Stake {
    uint256 amount; ///@dev amount of peg staked.
    int256 rewardDebt; ///@dev outstanding rewards that will not be included in the next rewards calculation.
}

struct StakeClass {
    uint256 id;
    uint256 minDuration;
    uint256 maxDuration;
    bool isActive;
}

struct Lock {
    uint256 pegLocked;
    uint256 wethLocked;
    uint256 totalLpShare;
    int256 rewardDebt;
    uint48 lockedAt; // locked
    uint48 lastLockedAt; // last time user increased their lock allocation
    uint48 unlockTimestamp; // unlockable
}

struct EsPegLock {
    uint256 esPegLocked;
    uint256 wethLocked;
    uint256 totalLpShare;
    int256 rewardDebt;
    uint48 lockedAt; // locked
    uint48 unlockTimestamp; // unlockable
}

struct FeeDistributorInfo {
    uint256 accumulatedUsdcPerContract; ///@dev usdc allocated to the three contracts in the fee distributor.
    uint256 lastBalance; ///@dev last balance of usdc in the fee distributor.
    uint256 currentBalance; ///@dev current balance of usdc in the fee distributor.
    int256 stakingContractDebt; ///@dev outstanding rewards of this contract (staking) that will not be included in the next rewards calculation.
    int256 lockContractDebt; ///@dev outstanding rewards of this contract (lock) that will not be included in the next rewards calculation.
    int256 plsAccumationContractDebt; ///@dev outstanding rewards of this contract (pls accumulator) that will not be included in the next rewards calculation.
    uint48 lastUpdateTimestamp; ///@dev last time the fee distributor rewards were updated.
}

struct StakeDetails {
    int256 rewardDebt;
    uint112 plsStaked;
    uint32 epoch;
    address user;
}

struct StakedDetails {
    uint112 amount;
    uint32 lastCheckpoint;
}

struct EsPegStake {
    address user; //user who staked
    uint256 amount; //amount of esPeg staked
    uint256 amountClaimable; //amount of peg claimable
    uint256 amountClaimed; //amount of peg claimed
    uint256 pegPerSecond; //reward rate
    uint48 startTime; //time when the stake started
    uint48 fullVestingTime; //time when the stake is fully vested
    uint48 lastClaimTime; //time when the user last claimed
}

struct EsPegVest {
    address user; //user who staked
    uint256 amount; //amount of esPeg staked
    uint256 amountClaimable; //amount of peg claimable
    uint256 amountClaimed; //amount of peg claimed
    uint256 pegPerSecond; //reward rate
    uint48 startTime; //time when the stake started
    uint48 fullVestingTime; //time when the stake is fully vested
    uint48 lastClaimTime; //time when the user last claimed
}

struct Referrers {
    uint256 epochId;
    address[] referrers;
    uint256[] allocations;
}

struct Group {
    uint256 totalUsdcDistributed;
    uint256 accumulatedUsdcPerContract;
    uint256 pendingGroupUsdc;
    uint256 lastGroupBalance;
    int256 shareDebt;
    string name;
    uint16 feeShare;
    uint8 groupId; //1: staking , 2:locking , 3:plsAccumulator
}

struct Contract {
    uint256 totalUsdcReceived;
    int256 contractShareDebt;
    address contractAddress;
    uint16 feeShare;
    uint8 groupId; ///@dev group contract belongs to
}

struct GroupUpdate {
    uint8 groupId;
    uint16 newShare;
}

struct ContractUpdate {
    address contractAddress;
    uint16 newShare;
}

///@notice PepeBet structs
struct BetDetails {
    uint256 amount;
    uint256 wagerAmount;
    uint256 openingPrice;
    uint256 closingPrice;
    uint256 startTime;
    uint256 endTime;
    uint256 betId;
    address initiator;
    address betToken;
    address asset;
    bool isLong;
    bool active;
}

struct WagerTokenDetails {
    address token;
    uint256 minBetAmount;
    uint256 maxBetAmount;
}

///@notice PepeLockExtention structs
struct LockExtension {
    address user;
    uint256 amount;
    uint48 lockDuration;
}

///@notice PepeDegen struct
struct DegenEpoch {
    uint32 epochId;
    address[] users;
    uint256[] amounts;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IPepeProxyLpToken is IERC20 {
    function approveContract(address contract_) external;

    function revokeContract(address contract_) external;

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function retrieve(address _token) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Lock } from "../Structs.sol";

interface IPepeLockUp {
    function initializePool(uint256 wethAmount, uint256 pegAmount, address poolAdmin) external;

    function updateRewards() external;

    function lock(uint256 wethAmount, uint256 pegAmount, uint256 minBlpOut) external;

    function unLock() external;

    function claimUsdcRewards() external;

    function pendingUsdcRewards(address _user) external view returns (uint256);

    function getLockDetails(address _user) external view returns (Lock memory);

    function lockDuration() external view returns (uint48);

    function setLockDuration(uint48 _lockDuration) external;

    function setFeeDistributor(address _feeDistributor) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPepeLPTokenPool {
    function approveContract(address contract_) external;

    function revokeContract(address contract_) external;

    function fundContractOperation(address contract_, uint256 amount) external;

    function withdraw(uint256 amount) external;

    function retrieve(address _token) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
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

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
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

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
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

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IBasePool is IERC20 {
    function getSwapFeePercentage() external view returns (uint256);

    function setSwapFeePercentage(uint256 swapFeePercentage) external;

    function setAssetManagerPoolConfig(IERC20 token, IAssetManager.PoolConfig memory poolConfig) external;

    function setPaused(bool paused) external;

    function getVault() external view returns (IVault);

    function getPoolId() external view returns (bytes32);

    function getOwner() external view returns (address);
}

interface IWeightedPoolFactory {
    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256[] memory normalizedWeights,
        address[] memory rateProviders,
        uint256 swapFeePercentage,
        address owner,
        bytes32 salt
    ) external returns (address);
}

interface IWeightedPool is IBasePool {
    function getSwapEnabled() external view returns (bool);

    function getNormalizedWeights() external view returns (uint256[] memory);

    function getGradualWeightUpdateParams()
        external
        view
        returns (uint256 startTime, uint256 endTime, uint256[] memory endWeights);

    function setSwapEnabled(bool swapEnabled) external;

    function updateWeightsGradually(uint256 startTime, uint256 endTime, uint256[] memory endWeights) external;

    function withdrawCollectedManagementFees(address recipient) external;

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT
    }
    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT
    }
}

interface IAssetManager {
    struct PoolConfig {
        uint64 targetPercentage;
        uint64 criticalPercentage;
        uint64 feePercentage;
    }

    function setPoolConfig(bytes32 poolId, PoolConfig calldata config) external;
}

interface IAsset {}

interface IVault {
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    function setRelayerApproval(address sender, address relayer, bool approved) external;

    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    enum UserBalanceOpKind {
        DEPOSIT_INTERNAL,
        WITHDRAW_INTERNAL,
        TRANSFER_INTERNAL,
        TRANSFER_EXTERNAL
    }
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    function registerTokens(bytes32 poolId, IERC20[] memory tokens, address[] memory assetManagers) external;

    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    function getPoolTokenInfo(
        bytes32 poolId,
        IERC20 token
    ) external view returns (uint256 cash, uint256 managed, uint256 lastChangeBlock, address assetManager);

    function getPoolTokens(
        bytes32 poolId
    ) external view returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind {
        JOIN,
        EXIT
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    enum PoolBalanceOpKind {
        WITHDRAW,
        DEPOSIT,
        UPDATE
    }
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    function setPaused(bool paused) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}