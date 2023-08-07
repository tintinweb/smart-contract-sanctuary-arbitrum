// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// diy
import "../interfaces/IBondingCurve.sol";
import "../libraries/ABDKMath.sol";

contract SqrtMixedBondingSwap is IBondingCurve {
    using ABDKMath for uint256;
    string public constant BondingCurveType = "squareroot";

    function getParameter(bytes memory data) private pure returns (uint256 a) {
        a = abi.decode(data, (uint256));
    }

    // x => erc20, y => native
    // p(x) = a * sqrt(x)
    function calculateMintAmountFromBondingCurve(
        uint256 nativeTokenAmount,
        uint256 daoTokenCurrentSupply,
        bytes memory parameters
    ) public pure override returns (uint256 daoTokenAmount, uint256) {
        uint256 a = getParameter(parameters);
        uint256 sdb = daoTokenCurrentSupply.sqrt();
        uint256 cna = ((3e18 * nativeTokenAmount) / (2 * a) + sdb * sdb * sdb).cuberoot();
        daoTokenAmount = cna * cna - daoTokenCurrentSupply;
        return (daoTokenAmount, nativeTokenAmount);
    }

    function calculateBurnAmountFromBondingCurve(
        uint256 daoTokenAmount,
        uint256 daoTokenCurrentSupply,
        bytes memory parameters
    ) public pure override returns (uint256, uint256 nativeTokenAmount) {
        uint256 a = getParameter(parameters);
        uint256 sdb = daoTokenCurrentSupply.sqrt();
        uint256 sda = (daoTokenCurrentSupply - daoTokenAmount).sqrt();
        nativeTokenAmount = (2 * a * (sdb * sdb * sdb - sda * sda * sda)) / 3e18;
        return (daoTokenAmount, nativeTokenAmount);
    }

    function price(uint256 daoTokenCurrentSupply, bytes memory parameters) public pure override returns (uint256) {
        uint256 a = getParameter(parameters);
        return a * daoTokenCurrentSupply.sqrt();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// IBindingCurve contract
// ----------------------------------------------------------------------------

interface IBondingCurve {
    function BondingCurveType() external view returns (string memory);

    // Processing logic must implemented in subclasses

    function calculateMintAmountFromBondingCurve(
        uint256 tokens,
        uint256 totalSupply,
        bytes memory parameters
    ) external view returns (uint256 x, uint256 y);

    function calculateBurnAmountFromBondingCurve(
        uint256 tokens,
        uint256 totalSupply,
        bytes memory parameters
    ) external view returns (uint256 x, uint256 y);

    function price(uint256 totalSupply, bytes memory parameters) external view returns (uint256 price);
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

library ABDKMath {
    /**
     * copy of internal function sqrtu from
     * https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrt(uint256 x) internal pure returns (uint256) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) {
                    xx >>= 128;
                    r <<= 64;
                }
                if (xx >= 0x10000000000000000) {
                    xx >>= 64;
                    r <<= 32;
                }
                if (xx >= 0x100000000) {
                    xx >>= 32;
                    r <<= 16;
                }
                if (xx >= 0x10000) {
                    xx >>= 16;
                    r <<= 8;
                }
                if (xx >= 0x100) {
                    xx >>= 8;
                    r <<= 4;
                }
                if (xx >= 0x10) {
                    xx >>= 4;
                    r <<= 2;
                }
                if (xx >= 0x8) {
                    r <<= 1;
                }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return (r < r1 ? r : r1);
            }
        }
    }

    function cuberoot(uint256 y) internal pure returns (uint256 z) {
        if (y > 7) {
            z = y;
            uint256 x = y / 3 + 1;
            while (x < z) {
                z = x;
                x = (y / (x * x) + (2 * x)) / 3;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}