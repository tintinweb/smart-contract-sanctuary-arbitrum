// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.9;

// imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IStargateRouter.sol";
import "./interfaces/IStargatePool.sol";
import "./interfaces/IStargateLpStaking.sol";
import "./interfaces/IStargateFactory.sol";
import "./interfaces/IPlugin.sol";

/// @title StargatePlugin.sol
/// @notice Core trading logic for stake, unstake of Stargate pools
contract StargatePlugin is IPlugin, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// CONSTANTS
    uint256 public constant BP_DENOMINATOR   = 10000;
    bytes32 public constant CONFIG_SLOT = keccak256("StargateDriver.config");
    uint8 internal constant MOZAIC_DECIMALS  = 6;

    ///@dev Used to define StargatePlugin config
    struct StargatePluginConfig {
        address stgRouter;
        address stgLPStaking;
        address stargateToken;
    }

    /* ========== STATE VARIABLES ========== */
    address public localVault;
    address public localTreasury;
    address public localInsurance;
    StargatePluginConfig public config;
    uint256 public mozaicFeeBP;
    uint256 public treasuryFeeBP;
    mapping(address => uint256) public stackedAmountPerToken;

    /* ========== EVENTS =========== */
    event StakeToken (
        address token,
        uint256 amountLD
    );

    event UnstakeToken (
        address token,
        uint256 amountLP
    );
    
    event GetStakedAmountLDPerToken (
        address token,
        uint256 amountLP
    );
    event GetTotalAsset(uint256 totalAssetsMD);
    /* ========== MODIFIERS ========== */

    /// @notice Modifier to check if caller is the vault.
    modifier onlyVault() {
        require(msg.sender == localVault, "StargatePlugin: caller is not the vault");
        _;
    }

    /* ========== CONFIGURATION ========== */
    constructor(
        address _localVault
    ) {
        require(_localVault != address(0x0), "ERROR: Invalid addr");
        localVault = _localVault;
    }

    /// @notice Set the vault address.
    /// @param _localVault - the address of the vault.
    function setVault(address _localVault) external onlyOwner {
        require(_localVault != address(0x0), "ERROR: Invalid addr");
        localVault = _localVault;
    }

    /// @notice Set the treasury and insurance.
    /// @param _treasury - the address of the treasury.
    /// @param _insurance - the address of the treasury.
    /// @dev Must only be called by the owner
    function setTreasury(address _treasury, address _insurance) external onlyOwner {
        require(_treasury != address(0x0), "StargatePlugin: Error Invalid addr");
        require(_insurance != address(0x0), "StargatePlugin: Error Invalid addr");
        localTreasury = _treasury;
        localInsurance = _insurance;
    }

    /// @notice Set the treasury and insurance.
    /// @param _mozaicFeeBP - The mozaic fee percent of total fee. 100 = 1%
    /// @param _treasuryFeeBP - The treasury fee percent of mozaic fee. 100 = 1%
    function setFee(uint256 _mozaicFeeBP, uint256 _treasuryFeeBP) external onlyOwner {
        require(_mozaicFeeBP <= BP_DENOMINATOR, "StargatePlugin: fees > 100%");
        require(_treasuryFeeBP <= BP_DENOMINATOR, "StargatePlugin: fees > 100%");

        mozaicFeeBP = _mozaicFeeBP;
        treasuryFeeBP = _treasuryFeeBP;
    }

    /// @notice Config plugin with the params.
    /// @param _stgRouter - The address of router.
    /// @param _stgLPStaking - The address of LPStaking.
    /// @param _stgToken - The address of stargate token.
    function configPlugin(address _stgRouter, address _stgLPStaking, address _stgToken) public onlyOwner {
        config.stgRouter = _stgRouter;
        config.stgLPStaking = _stgLPStaking;
        config.stargateToken = _stgToken;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    /// @notice Main StargatePlugin function. Execute the action to StargatePlugin depending on Action passed in.
    /// @param _actionType - The type of the action to be executed.
    /// @param _payload - a custom bytes payload to execute the action.
    function execute(ActionType _actionType, bytes calldata _payload) public onlyVault returns (bytes memory response) {
        if (_actionType == ActionType.Stake) {
            response = _stake(_payload);
        }
        else if (_actionType == ActionType.Unstake) {
            response = _unstake(_payload);
        }
        else if (_actionType == ActionType.GetStakedAmountLD) {
            response = _getStakedAmountLDPerToken(_payload);
        }
        else if (_actionType == ActionType.GetTotalAssetsMD) {
            response = _getTotalAssetsMD(_payload);
        }
        else {
            revert("StargatePlugin: Undefined Action");
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /// @notice Main staking function.
    /// @dev the action function called by execute.
    function _stake(bytes calldata _payload) private returns (bytes memory) {
        (uint256 _amountLD, address _token) = abi.decode(_payload, (uint256, address));
        require (_amountLD > 0, "StargatePlugin: Cannot stake zero amount");
        
        // Get pool and poolId
        address _pool = _getStargatePoolFromToken(_token);
        require(_pool != address(0), "StargatePlugin: Invalid token");
        uint256 _poolId = IStargatePool(_pool).poolId();

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amountLD);
        // Approve token transfer from vault to STG.Pool
        address _stgRouter = config.stgRouter;
        IERC20(_token).safeApprove(_stgRouter, 0);
        IERC20(_token).approve(_stgRouter, _amountLD);

        // Stake token from vault to STG.Pool and get LPToken
        // 1. Pool.LPToken of vault before
        uint256 balanceBefore = IStargatePool(_pool).balanceOf(address(this));

        // 2. Vault adds liquidity
        IStargateRouter(_stgRouter).addLiquidity(_poolId, _amountLD, address(this));

        // 3. Pool.LPToken of vault after
        uint256 balanceAfter = IStargatePool(_pool).balanceOf(address(this));
        // 4. Increased LPToken of vault
        uint256 amountLPToken = balanceAfter - balanceBefore;

        // Find the Liquidity Pool's index in the Farming Pool.
        (bool found, uint256 stkPoolIndex) = _getPoolIndexInFarming(_poolId);
        require(found, "StargatePlugin: The LP token not acceptable.");
        
        // Approve LPToken transfer from vault to LPStaking
        address _stgLPStaking = config.stgLPStaking;
        IStargatePool(_pool).approve(_stgLPStaking, 0);
        IStargatePool(_pool).approve(_stgLPStaking, amountLPToken);

        // Stake LPToken from vault to LPStaking
        IStargateLpStaking(_stgLPStaking).deposit(stkPoolIndex, amountLPToken);

        // Update the staked amount per token
        uint256 _amountLPStaked = IStargateLpStaking(_stgLPStaking).userInfo(stkPoolIndex, address(this)).amount;
        stackedAmountPerToken[_token] = (_amountLPStaked  == 0) ? 0 : IStargatePool(_pool).amountLPtoLD(_amountLPStaked);

        //Transfer token to localVault
        uint256 _tokenAmount = IERC20(_token).balanceOf(address(this));
        if(_tokenAmount > 0) {
            IERC20(_token).safeTransfer(localVault, _tokenAmount);
        }

        // Transfer stargateToken to localVault
        _distributeReward();
        emit StakeToken(_token, _amountLD);
    }

    /// @notice Main unstaking function.
    /// @dev the action function called by execute.
    function _unstake(bytes calldata _payload) private returns (bytes memory) {
        (uint256 _amountLPToken, address _token) = abi.decode(_payload, (uint256, address));
        require (_amountLPToken > 0, "StargatePlugin: Cannot unstake zero amount");

        // Get pool and poolId
        address _pool = _getStargatePoolFromToken(_token);
        require(_pool != address(0), "StargatePlugin: Invalid token");

        uint256 _poolId = IStargatePool(_pool).poolId();
        
        // Find the Liquidity Pool's index in the Farming Pool.
        (bool found, uint256 stkPoolIndex) = _getPoolIndexInFarming(_poolId);
        require(found, "StargatePlugin: The LP token not acceptable.");

        // Withdraw LPToken from LPStaking to vault
        // 1. Pool.LPToken of vault before
        uint256 balanceBefore = IStargatePool(_pool).balanceOf(address(this));

        // 2. Withdraw LPToken from LPStaking to vault
        address _stgLPStaking = config.stgLPStaking;
        
        uint256 _stakedLP = IStargateLpStaking(_stgLPStaking).userInfo(stkPoolIndex, address(this)).amount;

        if(_stakedLP < _amountLPToken) _amountLPToken = _stakedLP;
        
        IStargateLpStaking(_stgLPStaking).withdraw(stkPoolIndex, _amountLPToken);

        // 3. Pool.LPToken of vault after
        // uint256 balanceAfter = ;
        // 4. Increased LPToken of vault
        uint256 _amountLPTokenWithdrawn = IStargatePool(_pool).balanceOf(address(this)) - balanceBefore;

        // Give LPToken and redeem token from STG.Pool to vault
        address _stgRouter = config.stgRouter;
        IStargateRouter(_stgRouter).instantRedeemLocal(uint16(_poolId), _amountLPTokenWithdrawn, address(this));

        // Stake remained LP token 
        uint256 _balance = IStargatePool(_pool).balanceOf(address(this));
        IStargatePool(_pool).approve(_stgLPStaking, 0);
        IStargatePool(_pool).approve(_stgLPStaking, _balance);
        IStargateLpStaking(_stgLPStaking).deposit(stkPoolIndex, _balance);

        // Update the staked amount per token
        uint256 _amountLPStaked = IStargateLpStaking(_stgLPStaking).userInfo(stkPoolIndex, address(this)).amount;
        stackedAmountPerToken[_token] = (_amountLPStaked  == 0) ? 0 : IStargatePool(_pool).amountLPtoLD(_amountLPStaked);

        //Transfer token to localVault
        uint256 _tokenAmount = IERC20(_token).balanceOf(address(this));
        if(_tokenAmount > 0) {
            IERC20(_token).safeTransfer(localVault, _tokenAmount);
        }

        // Transfer stargateToken to localVault
        _distributeReward();
        
        emit UnstakeToken(_token, _amountLPTokenWithdrawn);
    }
    
    /// @notice Gets staked amount per token.
    /// @dev the action function called by execute.
    function _getStakedAmountLDPerToken(bytes calldata _payload) private returns (bytes memory) {
        (address _token) = abi.decode(_payload, (address));

        // Get pool address
        address _pool = _getStargatePoolFromToken(_token);
        bytes memory result;
        if(_pool == address(0)) {
            result = abi.encode(0);
            return result;
        }
        // Get pool id: _poolId = _pool.poolId()
        uint256 _poolId = IStargatePool(_pool).poolId();

        // Find the Liquidity Pool's index in the Farming Pool.
        (bool found, uint256 poolIndex) = _getPoolIndexInFarming(_poolId);
        if(found == false) {
            result = abi.encode(0);
            return result;
        }

        // Collect pending STG rewards: _stgLPStaking = config.stgLPStaking.withdraw(poolIndex, 0)
        address _stgLPStaking = config.stgLPStaking;
        IStargateLpStaking(_stgLPStaking).withdraw(poolIndex, 0);

        // Get amount LP staked
        uint256 _amountLP = IStargateLpStaking(_stgLPStaking).userInfo(poolIndex, address(this)).amount;

        // Get amount LD staked
        uint256 _amountLD = (_amountLP  == 0) ? 0 : IStargatePool(_pool).amountLPtoLD(_amountLP);
        result = abi.encode(_amountLD);

        //Transfer token to localVault
        uint256 _tokenAmount = IERC20(_token).balanceOf(address(this));
        if(_tokenAmount > 0) {
            IERC20(_token).safeTransfer(localVault, _tokenAmount);
        }
        // Transfer stargateToken to localVault
        _distributeReward();
        emit GetStakedAmountLDPerToken(_token, _amountLD);
        return result;
    }

    /// @notice Gets total assets per token.
    /// @dev the action function called by execute.
    function _getTotalAssetsMD(bytes calldata _payload) private returns (bytes memory) {
        (address[] memory _tokens) = abi.decode(_payload, (address[]));

        // The total stablecoin amount with mozaic deciaml
        uint256 _totalAssetsMD;
        for (uint i; i < _tokens.length; ++i) {
            address _token = _tokens[i];

            // Get assets LD in vault
            uint256 _assetsLD = IERC20(_token).balanceOf(address(this));
            
            if(_assetsLD > 0) {
                //Transfer token to localVault
                IERC20(_token).safeTransfer(localVault, _assetsLD); 
            }

            // Get assets LD staked in LPStaking
            // Get pool address
            address _pool = _getStargatePoolFromToken(_token);
            if(_pool == address(0)) continue;

            // Get pool id: _poolId = _pool.poolId()
            uint256 _poolId = IStargatePool(_pool).poolId();
            
            // Find the Liquidity Pool's index in the Farming Pool.
            (bool found, uint256 poolIndex) = _getPoolIndexInFarming(_poolId);
            if(found == false) continue;

            // // Collect pending STG rewards: _stgLPStaking = config.stgLPStaking.withdraw(poolIndex, 0)
            // address _stgLPStaking = config.stgLPStaking;
            // // IStargateLpStaking(_stgLPStaking).withdraw(poolIndex, 0);

            // // Get amount LP staked
            // uint256 _amountLPStaked = IStargateLpStaking(_stgLPStaking).userInfo(poolIndex, address(this)).amount;
            // stackedAmountPerToken[_token] = (_amountLPStaked  == 0) ? 0 : IStargatePool(_pool).amountLPtoLD(_amountLPStaked);
            
            // // Get amount LD for token.
            // _assetsLD = _assetsLD + stackedAmountPerToken[_token];
            // uint256 _assetsMD = convertLDtoMD(_token, _assetsLD);
            // _totalAssetsMD = _totalAssetsMD + _assetsMD;
        }
        bytes memory result = abi.encode(_totalAssetsMD);
        // Transfer stargateToken to localVault
        // _distributeReward();
        emit GetTotalAsset(_totalAssetsMD);
        return result;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /// @notice Gets pool from the token address.
    function _getStargatePoolFromToken(address _token) internal returns (address) {
        address _router = config.stgRouter;
        
        (bool success, bytes memory response) = address(_router).call(abi.encodeWithSignature("factory()"));
        // require(success, "StargatePlugin: factory failed");
        if(success == false) return address(0);
        address _factory = abi.decode(response, (address));
        uint256 _allPoolsLength = IStargateFactory(_factory).allPoolsLength();

        for (uint i; i < _allPoolsLength; ++i) {
            address _pool = IStargateFactory(_factory).allPools(i);
            address _poolToken = IStargatePool(_pool).token();
            if (_poolToken == _token) {
                return _pool;
            } else {
                continue;
            }
        }
        return address(0);
    }

    /// @notice Gets pool index in farming.
    function _getPoolIndexInFarming(uint256 _poolId) internal returns (bool, uint256) {
        address _pool = _getPool(_poolId);
        address _lpStaking = config.stgLPStaking;
        uint256 _poolLength = IStargateLpStaking(_lpStaking).poolLength();

        // for (uint256 poolIndex; poolIndex < _poolLength; poolIndex++) {
        //     address _pool__ = IStargateLpStaking(_lpStaking).getPoolInfo(poolIndex);
        //     if (_pool__ == _pool) {
        //         return (true, poolIndex);
        //     } else {
        //         continue;
        //     }
        // }
        return (false, 0);
    }

    /// @notice Gets pool from the pool id.
    function _getPool(uint256 _poolId) internal returns (address _pool) {
        address _router = config.stgRouter;

         (bool success, bytes memory response) = _router.call(abi.encodeWithSignature("factory()"));
        require(success, "StargatePlugin: factory failed");
        address _factory = abi.decode(response, (address));
        
        _pool = IStargateFactory(_factory).getPool(_poolId);
        require(address(_pool) != address(0x0), "StargatePlugin:  Invalid pool Id");
    }

    /// @notice  convert local decimal to mozaic decimal.
    function convertLDtoMD(address _token, uint256 _amountLD) internal view returns (uint256) {
        uint256 _localDecimals = IERC20Metadata(_token).decimals();
        if (MOZAIC_DECIMALS >= _localDecimals) {
            return _amountLD * (10**(MOZAIC_DECIMALS - _localDecimals));
        } else {
            return _amountLD / (10**(_localDecimals - MOZAIC_DECIMALS));
        }
    }

    /// @notice  distribute the stargateToken to vault, treasury and insurance.
    function _distributeReward() internal {
        address _stargateToken = config.stargateToken;
        uint256 _stgAmount = IERC20(_stargateToken).balanceOf(address(this));
        if(_stgAmount == 0) return;
        uint256 _mozaicAmount = _stgAmount.mul(mozaicFeeBP).div(BP_DENOMINATOR);
        _stgAmount = _stgAmount.sub(_mozaicAmount);
        uint256 _treasuryAmount = _mozaicAmount.mul(treasuryFeeBP).div(BP_DENOMINATOR);
        uint256 _insuranceAmount = _mozaicAmount.sub(_treasuryAmount);

        IERC20(_stargateToken).safeTransfer(localVault, _stgAmount);
        IERC20(_stargateToken).safeTransfer(localTreasury, _treasuryAmount);
        IERC20(_stargateToken).safeTransfer(localInsurance, _insuranceAmount);
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IStargatePool {    

    function poolId() external view returns (uint256);

    function token() external view returns (address);

    function convertRate() external view returns (uint256);

    function balanceOf(address account) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function amountLPtoLD(uint256 _amountLP) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStargateLpStaking {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function balanceOf(address _owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalLiquidity() external view returns (uint256);

    function poolLength() external view returns (uint256);

    function getPoolInfo(uint256) external view returns (address);
    
    function userInfo(uint256, address) external view returns (UserInfo calldata);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IStargateFactory {    

    function allPoolsLength() external view returns (uint256);

    function allPools(uint256) external view returns (address);

    function getPool(uint256) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IPlugin {
    enum ActionType {
        // Action types
        Stake,
        Unstake,
        GetStakedAmountLD,
        GetTotalAssetsMD
    }

    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function execute(ActionType _actionType, bytes calldata _payload) external returns (bytes memory);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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