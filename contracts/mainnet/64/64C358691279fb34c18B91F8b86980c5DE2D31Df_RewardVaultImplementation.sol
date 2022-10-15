// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../token/IERC20.sol';
import '../token/IDToken.sol';
import './IPool.sol';
import './IVault.sol';
import '../library/SafeMath.sol';
import './RewardVaultStorage.sol';
import '../RewardVault/IRewardVault.sol';

contract RewardVaultImplementation is RewardVaultStorage {

	using SafeMath for uint256;
	using SafeMath for int256;
	uint256 constant UONE = 1e18;

	IERC20 public immutable RewardToken;

	event SetRewardPerSecond(address indexed pool, uint256 newRewardPerSecond);
	event Claim(address indexed pool, address indexed account, uint256 indexed tokenId, uint256 amount);
	event AddPool(address indexed pool);

	constructor(address _rewardToken) {
		RewardToken = IERC20(_rewardToken);
	}

	//  ========== ADMIN ==============
	// Initialize new pool
	function initializeVenus(address _pool) _onlyAdmin_ external {
		require(!authorizedPool[_pool], "pool already init");
		IDToken lToken = IPool(_pool).lToken();

		uint256 total = lToken.totalMinted();
		uint256 _totalLiquidityB0;
		address vTokenB0 = IPool(_pool).vTokenB0();

		for (uint256 tokenId = 1; tokenId <= total; tokenId++) {
			UserInfo storage user = userInfo[_pool][tokenId];
			IPool.LpInfo memory info = IPool(_pool).lpInfos(tokenId);
			if (info.liquidity > 0) {
				(, uint256 underlyingBalance) = IVault(info.vault).getBalances(vTokenB0);
				int256 liquidityB0 = info.amountB0 + underlyingBalance.utoi();
				if (info.liquidity >= liquidityB0) {
					user.liquidityB0 = liquidityB0 > 0 ? liquidityB0.itou() : 0;
				} else {
					user.liquidityB0 = info.liquidity.itou();
				}
				_totalLiquidityB0 += user.liquidityB0;
			}
		}

		VaultInfo storage vault = vaultInfo[_pool];
		vault.totalLiquidityB0 = _totalLiquidityB0;
		vault.lastRewardTimestamp = block.timestamp;

		authorizedPool[_pool] = true;
		pools.push(_pool);

		emit AddPool(_pool);
	}

	function initializeAave(address _pool) _onlyAdmin_ external {
		require(!authorizedPool[_pool], "pool already init");
		IDToken lToken = IPool(_pool).lToken();

		uint256 total = lToken.totalMinted();
		uint256 _totalLiquidityB0;
		address marketB0 = IPool(_pool).marketB0();
		address tokenB0 = IPool(_pool).tokenB0();
		uint256 decimalsB0 = IERC20(tokenB0).decimals();

		for (uint256 tokenId = 1; tokenId <= total; tokenId++) {
			UserInfo storage user = userInfo[_pool][tokenId];
			IPool.LpInfo memory info = IPool(_pool).lpInfos(tokenId);
			if (info.liquidity > 0) {
				uint256 assetBalanceB0 = IVault(info.vault).getAssetBalance(marketB0);
                int256 liquidityB0 = assetBalanceB0.rescale(decimalsB0, 18).utoi() + info.amountB0;
				if (info.liquidity >= liquidityB0) {
					user.liquidityB0 = liquidityB0 > 0 ? liquidityB0.itou() : 0;
				} else {
					user.liquidityB0 = info.liquidity.itou();
				}
				_totalLiquidityB0 += user.liquidityB0;
			}
		}

		VaultInfo storage vault = vaultInfo[_pool];
		vault.totalLiquidityB0 = _totalLiquidityB0;
		vault.lastRewardTimestamp = block.timestamp;

		authorizedPool[_pool] = true;
		pools.push(_pool);

		emit AddPool(_pool);
	}

	// Initialze new pool from old reward vault
	function initializeFromVenus(address _pool, address _fromRewardVault) _onlyAdmin_ external {
		require(!authorizedPool[_pool], "pool already init");
		IDToken lToken = IPool(_pool).lToken();
		uint256 total = lToken.totalMinted();
		uint256 _totalLiquidityB0;
		address vTokenB0 = IPool(_pool).vTokenB0();

		uint256 newAccRewardPerLiquidity;
		{
			uint256 lastRewardTimestamp = IRewardVault(_fromRewardVault).lastRewardTimestamp();
			uint256 accRewardPerLiquidity = IRewardVault(_fromRewardVault).accRewardPerLiquidity();
			uint256 totalLiquidity = IPool(_pool).liquidity().itou();
			uint256 reward = (block.timestamp - lastRewardTimestamp) * IRewardVault(_fromRewardVault).rewardPerSecond();
			newAccRewardPerLiquidity = accRewardPerLiquidity + reward * UONE / totalLiquidity;
		}

		for (uint256 tokenId = 1; tokenId <= total; tokenId++) {
			UserInfo storage user = userInfo[_pool][tokenId];
			IPool.LpInfo memory info = IPool(_pool).lpInfos(tokenId);
			IRewardVault.UserInfo memory fromUser = IRewardVault(_fromRewardVault).userInfo(tokenId);
			if (info.liquidity > 0) {
				(, uint256 underlyingBalance) = IVault(info.vault).getBalances(vTokenB0);
				int256 liquidityB0 = info.amountB0 + underlyingBalance.utoi();
				if (info.liquidity >= liquidityB0) {
					user.liquidityB0 = liquidityB0 > 0 ? liquidityB0.itou() : 0;
				} else {
					user.liquidityB0 = info.liquidity.itou();
				}
				user.unclaimed = fromUser.unclaimed + info.liquidity.itou() * (newAccRewardPerLiquidity - fromUser.accRewardPerLiquidity) / UONE;
				_totalLiquidityB0 += user.liquidityB0;
			} else {
				user.unclaimed = fromUser.unclaimed;
			}
		}
		VaultInfo storage vault = vaultInfo[_pool];
		vault.totalLiquidityB0 = _totalLiquidityB0;
		vault.lastRewardTimestamp = block.timestamp;
		authorizedPool[_pool] = true;
		pools.push(_pool);
		emit AddPool(_pool);
	}


	function initializeFromAaveA(address _pool) _onlyAdmin_ external {
		require(!authorizedPool[_pool], "pool already init");
		VaultInfo storage vault = vaultInfo[_pool];
		vault.lastRewardTimestamp = block.timestamp;

		authorizedPool[_pool] = true;
		pools.push(_pool);
		emit AddPool(_pool);
	}

	function initializeFromAaveB(address _pool, address _fromRewardVault, uint256 start, uint256 end) _onlyAdmin_ external {
		require(authorizedPool[_pool], 'pool not init');
		uint256 markAccRewardPerLiquidity;
		{
			uint256 lastRewardTimestamp = IRewardVault(_fromRewardVault).lastRewardTimestamp();
			uint256 accRewardPerLiquidity = IRewardVault(_fromRewardVault).accRewardPerLiquidity();
			uint256 totalLiquidity = IPool(_pool).liquidity().itou();
			uint256 vaultTimestamp = vaultInfo[_pool].lastRewardTimestamp;
			uint256 reward = (vaultTimestamp - lastRewardTimestamp) * IRewardVault(_fromRewardVault).rewardPerSecond();
			markAccRewardPerLiquidity = accRewardPerLiquidity + reward * UONE / totalLiquidity;
		}

		IDToken lToken = IPool(_pool).lToken();
		uint256 total = lToken.totalMinted();
		uint256 _totalLiquidityB0;
		address marketB0 = IPool(_pool).marketB0();
		uint256 decimalsB0 = IERC20(IPool(_pool).tokenB0()).decimals();
		if (end > total) end = total;

		for (uint256 tokenId = start; tokenId <= end; tokenId++) {
			UserInfo storage user = userInfo[_pool][tokenId];
			IPool.LpInfo memory info = IPool(_pool).lpInfos(tokenId);
			IRewardVault.UserInfo memory fromUser = IRewardVault(_fromRewardVault).userInfo(tokenId);
			if (info.liquidity > 0) {
				uint256 assetBalanceB0 = IVault(info.vault).getAssetBalance(marketB0);
                int256 liquidityB0 = assetBalanceB0.rescale(decimalsB0, 18).utoi() + info.amountB0;
				if (info.liquidity >= liquidityB0) {
					user.liquidityB0 = liquidityB0 > 0 ? liquidityB0.itou() : 0;
				} else {
					user.liquidityB0 = info.liquidity.itou();
				}
				user.unclaimed = fromUser.unclaimed + info.liquidity.itou() * (markAccRewardPerLiquidity - fromUser.accRewardPerLiquidity) / UONE;
				_totalLiquidityB0 += user.liquidityB0;
			} else {
				user.unclaimed = fromUser.unclaimed;
			}
		}

		VaultInfo storage vault = vaultInfo[_pool];
		vault.totalLiquidityB0 += _totalLiquidityB0;
	}


	// Initialize new lite pool
	function initializeLite(address _pool) _onlyAdmin_ external {
		require(!authorizedPool[_pool], "pool already init");
		IDToken lToken = IPool(_pool).lToken();
		uint256 total = lToken.totalMinted();
		uint256 _totalLiquidityB0;

		for (uint256 tokenId = 1; tokenId <= total; tokenId++) {
			UserInfo storage user = userInfo[_pool][tokenId];
			IPool.LpInfo memory info = IPool(_pool).lpInfos(tokenId);
			if (info.liquidity > 0) {
				int256 liquidityB0 = info.amountB0;
				user.liquidityB0 = liquidityB0 > 0 ? liquidityB0.itou() : 0;
				_totalLiquidityB0 += user.liquidityB0;
			}
		}

		VaultInfo storage vault = vaultInfo[_pool];
		vault.totalLiquidityB0 = _totalLiquidityB0;
		vault.lastRewardTimestamp = block.timestamp;

		authorizedPool[_pool] = true;
		pools.push(_pool);

		emit AddPool(_pool);
	}


	function setRewardPerSecond(address _pool, uint256 _rewardPerSecond) _onlyAdmin_ external {
		uint256 totalLiquidity = IPool(_pool).liquidity().itou();
		uint256 ratioB0 = _getRatioB0(_pool, totalLiquidity);
		_updateAccRewardPerLiquidity(_pool, totalLiquidity, ratioB0);

		vaultInfo[_pool].rewardPerSecond = _rewardPerSecond;
		emit SetRewardPerSecond(_pool, _rewardPerSecond);
	}

	function emergencyWithdraw(address to) _onlyAdmin_ external {
		uint256 balance = RewardToken.balanceOf(address(this));
		RewardToken.transfer(to, balance);
	}

	// ============= UPDATE =================

	function updateVault(uint256 totalLiquidity, uint256 tokenId, uint256 liquidity, uint256 balanceB0, int256 newLiquidityB0) external {
		address pool = msg.sender;
		if (!authorizedPool[pool]) {
			return;
		}
		// update accRewardPerLiquidity before adding new liquidity
		uint256 ratioB0 = balanceB0 * UONE / totalLiquidity;
		_updateAccRewardPerLiquidity(pool, totalLiquidity, ratioB0);

		// settle reward to the user before updating new liquidity
		UserInfo storage user = userInfo[pool][tokenId];
		VaultInfo memory vault = vaultInfo[pool];
		user.unclaimed += user.liquidityB0 * (vault.accRewardPerB0Liquidity - user.accRewardPerB0Liquidity) / UONE
			+ (liquidity - user.liquidityB0) * (vault.accRewardPerBXLiquidity - user.accRewardPerBXLiquidity) / UONE;
		user.accRewardPerB0Liquidity = vault.accRewardPerB0Liquidity;
		user.accRewardPerBXLiquidity = vault.accRewardPerBXLiquidity;

		// update liquidityB0
		int256 totalLiquidityB0 = vault.totalLiquidityB0.utoi();
		int256 liquidityB0;
		if (newLiquidityB0 > 0) {
			int256 delta =  newLiquidityB0 - user.liquidityB0.utoi();
			totalLiquidityB0 += delta;
			liquidityB0 = newLiquidityB0;
		} else if (newLiquidityB0 <= 0 && user.liquidityB0 >0) {
			int256 delta = -user.liquidityB0.utoi();
			totalLiquidityB0 += delta;
			liquidityB0 = 0;
		} else { //// newLiquidityB0 <= 0 && user.liquidityB0 == 0
			return;
		}
		vaultInfo[pool].totalLiquidityB0 = totalLiquidityB0.itou();
		user.liquidityB0 = liquidityB0.itou();
	}


	function claim(address pool) external {
		require(authorizedPool[pool], "Only authorized by pools");
		uint256 totalLiquidity = IPool(pool).liquidity().itou();
		uint256 ratioB0 = _getRatioB0(pool, totalLiquidity);
		_updateAccRewardPerLiquidity(pool, totalLiquidity, ratioB0);

		IDToken lToken = IPool(pool).lToken();
		require(lToken.exists(msg.sender), "LToken not exist");
		uint256 tokenId = lToken.getTokenIdOf(msg.sender);

		UserInfo storage user = userInfo[pool][tokenId];
		VaultInfo memory vault = vaultInfo[pool];
		IPool.LpInfo memory info = IPool(pool).lpInfos(tokenId);
		uint256 liquidity = info.liquidity.itou();
		uint256 claimed = user.unclaimed
			+ user.liquidityB0 * (vault.accRewardPerB0Liquidity - user.accRewardPerB0Liquidity) / UONE
			+ (liquidity - user.liquidityB0) * (vault.accRewardPerBXLiquidity - user.accRewardPerBXLiquidity) / UONE;

		user.accRewardPerB0Liquidity = vault.accRewardPerB0Liquidity;
		user.accRewardPerBXLiquidity = vault.accRewardPerBXLiquidity;
		user.unclaimed = 0;

		RewardToken.transfer(msg.sender, claimed);
		emit Claim(pool, msg.sender, tokenId, claimed);
	}


	function _updateAccRewardPerLiquidity(address pool, uint256 totalLiquidity, uint256 ratioB0) internal {
		(uint256 rewardPerB0Liquidity, uint256 rewardPerBXLiquidity) = _getRewardPerLiquidity(pool, totalLiquidity, ratioB0);
		VaultInfo storage vault = vaultInfo[pool];
		vault.accRewardPerB0Liquidity += rewardPerB0Liquidity;
		vault.accRewardPerBXLiquidity += rewardPerBXLiquidity;
		vault.lastRewardTimestamp = block.timestamp;
	}

	function _getRewardPerLiquidityPerSecond(address pool, uint256 totalLiquidity, uint256 ratioB0) internal view returns (
		uint256 rewardPerB0LiquidityPerSecond, uint256 rewardPerBXLiquidityPerSecond
	) {
		(bool success, bytes memory data) = pool.staticcall(abi.encodeWithSignature("minRatioB0()"));
		uint256 minRatioB0;
		if (success) {
			minRatioB0 = abi.decode(data, (int256)).itou();
		}
		uint256 rewardPerSecond = vaultInfo[pool].rewardPerSecond;
		uint256 totalLiquidityB0 = vaultInfo[pool].totalLiquidityB0;

		if (ratioB0 >= 2 * minRatioB0) {
			rewardPerBXLiquidityPerSecond = rewardPerSecond * UONE / totalLiquidity;
			rewardPerB0LiquidityPerSecond = rewardPerBXLiquidityPerSecond;
		} else if (ratioB0 <= minRatioB0) {
			rewardPerB0LiquidityPerSecond = rewardPerSecond * UONE / totalLiquidityB0;
		} else {
			uint256 rewardCoef = (ratioB0 - minRatioB0) * UONE / minRatioB0;
			rewardPerBXLiquidityPerSecond = rewardPerSecond * rewardCoef / totalLiquidity;
			rewardPerB0LiquidityPerSecond = (rewardPerSecond * UONE - rewardPerBXLiquidityPerSecond * (totalLiquidity - totalLiquidityB0))/ totalLiquidityB0;
		}
	}

	function _getRewardPerLiquidity(address pool, uint256 totalLiquidity, uint256 ratioB0) internal view returns (
		uint256 rewardPerB0Liquidity, uint256 rewardPerBXLiquidity
	) {
		(uint256 rewardPerB0LiquidityPerSecond, uint256 rewardPerBXLiquidityPerSecond) = _getRewardPerLiquidityPerSecond(pool, totalLiquidity, ratioB0);
		uint256 timeDelta = block.timestamp - vaultInfo[pool].lastRewardTimestamp;
		rewardPerB0Liquidity = timeDelta * rewardPerB0LiquidityPerSecond;
		rewardPerBXLiquidity = timeDelta * rewardPerBXLiquidityPerSecond;
	}

	function _getRatioB0(address pool, uint256 totalLiquidity) internal view returns (uint256) {
		address tokenB0 = IPool(pool).tokenB0();
		uint256 decimalsB0 = IERC20(tokenB0).decimals();
		uint256 ratioB0 = IERC20(tokenB0).balanceOf(pool).rescale(decimalsB0, 18) * UONE / totalLiquidity;
		return ratioB0;
	}


	// ============= VIEW ===================
	function pending(address pool, address account) external view returns (uint256) {
		IDToken lToken = IPool(pool).lToken();
		uint256 tokenId = lToken.getTokenIdOf(account);
		return pending(pool, tokenId);
	}

	function pending(address pool, uint256 tokenId) public view returns (uint256) {
		UserInfo memory user = userInfo[pool][tokenId];
		VaultInfo memory vault = vaultInfo[pool];

		uint256 totalLiquidity = IPool(pool).liquidity().itou();
		uint256 ratioB0 = _getRatioB0(pool, totalLiquidity);
		(uint256 rewardPerB0Liquidity, uint256 rewardPerBXLiquidity) = _getRewardPerLiquidity(pool, totalLiquidity, ratioB0);
		uint256 newAccRewardPerB0Liquidity = vault.accRewardPerB0Liquidity + rewardPerB0Liquidity;
		uint256 newAccRewardPerBXLiquidity = vault.accRewardPerBXLiquidity + rewardPerBXLiquidity;

		IPool.LpInfo memory info = IPool(pool).lpInfos(tokenId);
		uint256 liquidity = info.liquidity.itou();
		uint256 unclaimed = user.unclaimed + user.liquidityB0 * (newAccRewardPerB0Liquidity - user.accRewardPerB0Liquidity) / UONE
			+ (liquidity - user.liquidityB0) * (newAccRewardPerBXLiquidity - user.accRewardPerBXLiquidity) / UONE;

		return unclaimed;
	}

	function getRewardPerLiquidityPerSecond(address pool) external view returns (uint256, uint256) {
		uint256 totalLiquidity = IPool(pool).liquidity().itou();
		uint256 ratioB0 = _getRatioB0(pool, totalLiquidity);
		return _getRewardPerLiquidityPerSecond(pool, totalLiquidity, ratioB0);
	}

	function getUserInfo(address pool, address account) external view returns (UserInfo memory) {
		IDToken lToken = IPool(pool).lToken();
		uint256 tokenId = lToken.getTokenIdOf(account);
		UserInfo memory user = userInfo[pool][tokenId];
		return user;
	}

	function getTotalLiquidityB0(address pool) external view returns (uint256) {
		return vaultInfo[pool].totalLiquidityB0;
	}

	function getAccRewardPerB0Liquidity(address pool) external view returns (uint256) {
		return vaultInfo[pool].accRewardPerB0Liquidity;
	}

	function getAccRewardPerBXLiquidity(address pool) external view returns (uint256) {
		return vaultInfo[pool].accRewardPerBXLiquidity;
	}

	function getVaultBalance(uint256 endTimestamp) external view returns (uint256, int256) {
		uint256 balance = RewardToken.balanceOf(address(this));
		uint256 delta = endTimestamp - block.timestamp;
		uint256 toclaim;
		for (uint256 i=0; i<pools.length; i++) {
			toclaim += vaultInfo[pools[i]].rewardPerSecond * delta;
			toclaim += getPendingPerPool(pools[i]);
		}
		int256 remain = balance.utoi() - toclaim.utoi();
		return (balance, remain);
	}

	function getPendingPerPool(address pool) public view returns (uint256) {
		IDToken lToken = IPool(pool).lToken();
		uint256 total = lToken.totalMinted();
		uint256 unclaimed;
		for (uint256 tokenId = 1; tokenId <= total; tokenId++) {
			unclaimed += pending(pool, tokenId);
		}
		return unclaimed;
	}

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../token/IDToken.sol";

interface IPool {

    function liquidity() external view returns (int256);

    struct LpInfo {
        address vault;
        int256 amountB0;
        int256 liquidity;
        int256 cumulativePnlPerLiquidity;
    }

    function lpInfos(uint256) external view returns (LpInfo memory);

    function lToken() external view returns (IDToken);

    function tokenB0() external view returns (address);

    function vTokenB0() external view returns (address);

    function marketB0() external view returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IVault {

    function getVaultLiquidity() external view  returns (uint256);

    function getAssetBalance(address market) external view returns (uint256);

    function getBalances(address vToken) external view returns (uint256 vTokenBalance, uint256 underlyingBalance);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IERC721.sol';
import '../utils/INameVersion.sol';

interface IDToken is IERC721, INameVersion {

    function pool() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalMinted() external view returns (uint256);

    function exists(address owner) external view returns (bool);

    function exists(uint256 tokenId) external view returns (bool);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function getTokenIdOf(address owner) external view returns (uint256);

    function mint(address owner) external returns (uint256);

    function burn(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

contract RewardVaultStorage is Admin {

	address public implementation;

	struct UserInfo {
		uint256 accRewardPerB0Liquidity; // last updated accRewardPerB0Liquidity when the user triggered claim/update ops
		uint256 accRewardPerBXLiquidity; // last updated accRewardPerBXLiquidity when the user triggered claim/update ops
		uint256 unclaimed; // the unclaimed reward
		uint256 liquidityB0;
		//
		// We do some math here. Basically, any point in time, the amount of reward token
		// entitled to a user but is pending to be distributed is:
		//
		//  pending reward = lpLiquidity * (accRewardPerLiquidity - user.accRewardPerLiquidity)
		//  claimable reward = pending reward + user.unclaimed;
		//
		// Whenever a user add or remove liquidity to a pool. Here's what happens:
		//   1. The pool's `accRewardPerLiquidity` (and `lastRewardBlock`) gets updated.
		//   2. the pending reward moved to user.unclaimed.
		//   3. User's `accRewardPerLiquidity` gets updated.
	}

	// poolAddress => lTokenId => UserInfo
	mapping(address => mapping(uint256 => UserInfo)) public userInfo;

	struct VaultInfo {
		uint256 rewardPerSecond; // How many reward token per second.
		uint256 lastRewardTimestamp; // Last updated timestamp when any user triggered claim/update ops.
		uint256 accRewardPerB0Liquidity; // Accumulated reward per B0 share.
		uint256 accRewardPerBXLiquidity; // Accumulated reward per BX share.
		uint256 totalLiquidityB0;
	}

	// poolAddress => VaultInfo
	mapping(address => VaultInfo) public vaultInfo;

	// poolAddress => isAuthorized
	mapping(address => bool) public authorizedPool;

	// poolAddresses
	address[] public pools;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IRewardVault {

	function updateVault(uint256, uint256, uint256) external;

	function claim() external;

	function pending(uint256) view external returns (uint256);

	function pending(address) view external returns (uint256);

	struct UserInfo {
		uint256 accRewardPerLiquidity; // last updated accRewardPerLiquidity when the user triggered claim/update ops
		uint256 unclaimed; // the unclaimed reward
	}

	function userInfo(uint256) external view returns (UserInfo memory);

	function lastRewardTimestamp() external view returns (uint256);

	function accRewardPerLiquidity() external view returns (uint256);

	function rewardPerSecond() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {

    uint256 constant UMAX = 2 ** 255 - 1;
    int256  constant IMIN = -2 ** 255;

    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, 'SafeMath.utoi: overflow');
        return int256(a);
    }

    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, 'SafeMath.itou: underflow');
        return uint256(a);
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, 'SafeMath.abs: overflow');
        return a >= 0 ? a : -a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

    // rescale a uint256 from base 10**decimals1 to 10**decimals2
    function rescale(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return decimals1 == decimals2 ? a : a * 10**decimals2 / 10**decimals1;
    }

    // rescale towards zero
    // b: rescaled value in decimals2
    // c: the remainder
    function rescaleDown(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        c = a - rescale(b, decimals2, decimals1);
    }

    // rescale towards infinity
    // b: rescaled value in decimals2
    // c: the excessive
    function rescaleUp(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        uint256 d = rescale(b, decimals2, decimals1);
        if (d != a) {
            b += 1;
            c = rescale(b, decimals2, decimals1) - a;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC165.sol";

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed operator, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function approve(address operator, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}