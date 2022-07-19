/**
 *Submitted for verification at Arbiscan on 2022-07-19
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/interfaces/IERC20.sol


pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// File: contracts/interfaces/IRewardPool.sol


pragma solidity 0.6.12;

interface IRewardPool {
  function pae() external view returns (address);
  function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
  function poolInfo(uint256 _pid) external view returns (address, uint256);
}

// File: contracts/interfaces/IVaultBeefy.sol


pragma solidity 0.6.12;

interface IVaultBeefy {
  function want() external view returns (address);
  function getPricePerFullShare() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
}

// File: contracts/interfaces/IUniswapV2Pair.sol


pragma solidity ^0.6.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/interfaces/IVaultYieldWolf.sol


pragma solidity 0.6.12;

interface IVaultYieldWolf {
  function stakedTokens(uint256 _pid, address _user) external view returns (uint256);
}

// File: contracts/interfaces/IMasonry.sol


pragma solidity 0.6.12;

interface IMasonry {
    function balanceOf(address _mason) external view returns (uint256);

    function earned(address _mason) external view returns (uint256);

    function canWithdraw(address _mason) external view returns (bool);

    function canClaimReward(address _mason) external view returns (bool);

    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getPegPrice() external view returns (uint256);

    function setOperator(address _operator) external;

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    function claimReward() external;

    function allocateSeigniorage(uint256 _amount) external;

    function governanceRecoverUnsupported(address _token, uint256 _amount, address _to) external;
}

// File: contracts/PaeBalancesSide.sol


pragma solidity 0.6.12;








contract PaeBalancesSide is Ownable {

    IMasonry[] public banks;
    IERC20 public pae;
    IUniswapV2Pair public paeLp;
    IRewardPool public genesisPool;
    IRewardPool public paeRewardPool;
    IVaultBeefy public paeBeefyVault;
    IVaultYieldWolf public wolfVault;
    uint256[] public wolfBankPids;
    uint256 public wolfLpPid;
    uint256 public genesisPoolIndex;
    uint256 public rewardPoolIndex;
    bool public isToken0;

    constructor (
        IERC20 _pae,
        IMasonry[] memory _banks,
        IRewardPool _genesisPool,
        IRewardPool _paeRewardPool,
        uint _genesisPoolIndex,
        uint _rewardPoolIndex,
        IVaultBeefy _beefyVault,
        IVaultYieldWolf _wolfLpVault,
        uint256 _wolfLpPid,
        uint256[] memory _wolfBankPids
    ) public {
        pae = _pae;
        banks = _banks;
        genesisPool = _genesisPool;
        paeRewardPool = _paeRewardPool;
        genesisPoolIndex = _genesisPoolIndex;
        rewardPoolIndex = _rewardPoolIndex;
        paeBeefyVault = _beefyVault;
        wolfVault = _wolfLpVault;
        wolfLpPid = _wolfLpPid;
        wolfBankPids = _wolfBankPids;

        setRewardPool(_paeRewardPool, _rewardPoolIndex);
    }

    function balanceOf(address account) external view returns (uint256) {
        return pae.balanceOf(account) + balanceOfLP(account) + balanceOfGenesis(account) + balanceOfBanks(account) + balanceWolfBank(account);
    }

    function balanceOfLP(address account) public view returns (uint256) {
        if (address(paeLp) != address(0)) {
            uint256 lpBalance = paeLp.balanceOf(account);
            if (address(paeRewardPool) != address(0)) {
                (uint256 poolBalance,) = paeRewardPool.userInfo(rewardPoolIndex, account);
                lpBalance = lpBalance + poolBalance + balanceBeefyLP(account) + balanceWolfLP(account);
            }
            return lpBalance * paePerLP() / 1e18;
        } else {
            return 0;
        }
    }

    function balanceOfGenesis(address account) public view returns (uint256 bal) {
        if (address(genesisPool) == address(0)) return 0;
        (bal,) = genesisPool.userInfo(genesisPoolIndex, account);
    }

    function balanceOfBanks(address account) public view returns (uint256) {
        uint256 bal;
        for (uint256 i; i < banks.length; i++) {
            bal += banks[i].balanceOf(account);
        }
        return bal;
    }

    function balanceBeefyLP(address account) public view returns (uint256) {
        if (address(paeBeefyVault) == address(0)) return 0;
        return paeBeefyVault.balanceOf(account) * paeBeefyVault.getPricePerFullShare() / 1e18;
    }

    function balanceWolfLP(address account) public view returns (uint256) {
        if (address(wolfVault) == address(0)) return 0;
        return wolfVault.stakedTokens(wolfLpPid, account);
    }

    function balanceWolfBank(address account) public view returns (uint256) {
        if (address(wolfVault) == address(0)) return 0;
        uint256 bal;
        for (uint256 i; i < wolfBankPids.length; i++) {
            bal += wolfVault.stakedTokens(wolfBankPids[i], account);
        }
        return bal;
    }

    function paePerLP() public view returns (uint256) {
        (uint256 reserveA, uint256 reserveB,) = paeLp.getReserves();
        uint256 paeBalance = isToken0 ? reserveA : reserveB;
        return paeBalance * 1e18 / paeLp.totalSupply();
    }

    function setGenesisPool(IRewardPool _genesisPool, uint _genesisPoolIndex) external onlyOwner {
        genesisPool = _genesisPool;
        genesisPoolIndex = _genesisPoolIndex;
    }

    function setRewardPool(IRewardPool _rewardPool, uint _rewardPoolIndex) public onlyOwner {
        paeRewardPool = _rewardPool;
        rewardPoolIndex = _rewardPoolIndex;

        if (address(paeRewardPool) != address(0)) {
            (address _paeLp,) = paeRewardPool.poolInfo(rewardPoolIndex);
            paeLp = IUniswapV2Pair(_paeLp);

            if (paeLp.token0() == address(pae)) isToken0 = true;
            else if (paeLp.token1() == address(pae)) isToken0 = false;
            else revert("not PAE LP");
        } else {
            paeLp = IUniswapV2Pair(address(0));
        }
    }

    function setBanks(IMasonry[] memory _banks) external onlyOwner {
        banks = _banks;
    }

    function setBeefyVault(IVaultBeefy _beefyVault) external onlyOwner {
        paeBeefyVault = _beefyVault;
    }

    function setYieldWolfVault(IVaultYieldWolf _wolfVault, uint256 _lpPid, uint256[] memory _bankPids) external onlyOwner {
        wolfVault = _wolfVault;
        wolfLpPid = _lpPid;
        wolfBankPids = _bankPids;
    }
}