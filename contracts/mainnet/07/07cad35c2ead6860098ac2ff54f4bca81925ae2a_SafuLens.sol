// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IRamsesNfpManager.sol";
import "./IRamsesClFactory.sol";
import "./IRamsesVoter.sol";
import "./IRamsesGaugeV2.sol";
import "./IRamsesV2Pool.sol";
import "./IERC20.sol";

struct ClData {
    uint256 nft_id;
    address token0;
    address token1;
    string symbol0;
    string symbol1;
    uint24 fee;
    address pool_address;
    address gauge_address;
    uint256 pool_liquidity;
    uint256 pool_boostedliq;
    uint256 boostedliq;
    int24 tick;
    int24 tick_lower;
    int24 tick_upper;
    uint128 liquidity;
    uint256 earned;
}

contract SafuLens {
    IRamsesNfpManager public ramsesNfpManager =
        IRamsesNfpManager(0xAA277CB7914b7e5514946Da92cb9De332Ce610EF);
    IRamsesClFactory public ramsesClFactory =
        IRamsesClFactory(0xAA2cd7477c451E703f3B9Ba5663334914763edF8);
    IRamsesVoter public ramsesVoter =
        IRamsesVoter(0xAAA2564DEb34763E3d05162ed3f5C2658691f499);
    address public constant RAM = 0xAAA6C1E32C55A7Bfa8066A6FAE9b42650F262418;

    function initialize() public {
        ramsesNfpManager = IRamsesNfpManager(
            0xAA277CB7914b7e5514946Da92cb9De332Ce610EF
        );
        ramsesClFactory = IRamsesClFactory(
            0xAA2cd7477c451E703f3B9Ba5663334914763edF8
        );
        ramsesVoter = IRamsesVoter(0xAAA2564DEb34763E3d05162ed3f5C2658691f499);
    }

    function nftIdsOfOwner(address owner) public view returns (uint256[] memory) {
        uint256[] memory nft_ids = new uint256[](
            ramsesNfpManager.balanceOf(owner)
        );
        for (uint256 i = 0; i < nft_ids.length; i++) {
            nft_ids[i] = ramsesNfpManager.tokenOfOwnerByIndex(owner, i);
        }

        return nft_ids;
    }

    function getClData(uint256 nft_id) public view returns (ClData memory) {
        ClData memory clData;

        (
            ,
            ,
            clData.token0,
            clData.token1,
            clData.fee,
            clData.tick_lower,
            clData.tick_upper,
            ,
            ,
            ,
            ,

        ) = ramsesNfpManager.positions(nft_id);

        clData.pool_address = ramsesClFactory.getPool(
            clData.token0,
            clData.token1,
            clData.fee
        );
        clData.gauge_address = ramsesVoter.gauges(clData.pool_address);
        (clData.liquidity, clData.boostedliq, ) = IRamsesGaugeV2(
            clData.gauge_address
        ).positionInfo(nft_id);

        clData.symbol0 = IERC20(clData.token0).symbol();
        clData.symbol1 = IERC20(clData.token1).symbol();
        clData.pool_liquidity = IRamsesV2Pool(clData.pool_address).liquidity();
        clData.pool_boostedliq = IRamsesV2Pool(clData.pool_address)
            .boostedLiquidity();
        (, clData.tick, , , , , ) = IRamsesV2Pool(clData.pool_address).slot0();
        clData.earned = IRamsesGaugeV2(clData.gauge_address).earned(
            RAM,
            nft_id
        );

        return clData;
    }

    function getClDataBatched(
        uint256[] memory nft_ids
    ) public view returns (ClData[] memory) {
        ClData[] memory clData = new ClData[](nft_ids.length);
        for (uint256 i = 0; i < nft_ids.length; i++) {
            clData[i] = getClData(nft_ids[i]);
        }

        return clData;
    }

    function clDataOfOwner(
        address owner
    ) public view returns (ClData[] memory) {
        uint256[] memory nft_ids = nftIdsOfOwner(owner);

        // Determine the starting index based on the length of the nft_ids array.
        uint256 startIndex = nft_ids.length > 200 ? nft_ids.length - 200 : 0;
        uint256 length = nft_ids.length - startIndex;

        // Create a new array to store the last 200 (or less) NFT IDs.
        uint256[] memory lastNftIds = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            lastNftIds[i] = nft_ids[startIndex + i];
        }

        return getClDataBatched(lastNftIds);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IRamsesNfpManager {
    function balanceOf(address) external view returns (uint256);
    function tokenOfOwnerByIndex(address, uint256) external view returns (uint256);
    function positions(uint256) external view returns (uint96,address,address,address,uint24,int24,int24,uint128,uint256,uint256,uint128,uint128);
    function ownerOf(uint256) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IRamsesClFactory {
    function getPool(address, address, uint24) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IRamsesVoter {
    function gauges(address) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IRamsesGaugeV2 {
    function positionInfo(uint256) external view returns (uint128, uint128, uint256);
    function earned(address, uint256) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IRamsesV2Pool {
    function liquidity() external view returns (uint128);
    function boostedLiquidity() external view returns (uint128);
    function slot0() external view returns (uint160, int24, uint16, uint16, uint16, uint8, bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.7.6;

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
    function symbol() external view returns (string memory);
}