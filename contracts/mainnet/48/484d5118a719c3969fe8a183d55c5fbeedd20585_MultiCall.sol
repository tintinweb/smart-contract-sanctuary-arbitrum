/**
 *Submitted for verification at Arbiscan on 2023-06-23
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.19;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint256);
}

interface Factory {
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

interface Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function totalSupply() external view returns (uint);
}

contract MultiCall {
    struct PairInfo {
        address pairAddress;
        uint256 reserve0;
        uint256 reserve1;
        uint256 totalSupply;
        address token0;
        address token1;
        string token0Name;
        string token1Name;
        string token0Symbol;
        string token1Symbol;
        uint256 userBal;
    }

    function getPairs(address account, address factory, uint from, uint to) public view returns (PairInfo[] memory) {
        uint pairLength = Factory(factory).allPairsLength();
        if (from > pairLength) { from = pairLength; }
        if (to > pairLength) { to = pairLength; }
        require(from <= to, "to must not be smaller than from");
        PairInfo[] memory userInfo = new PairInfo[](to - from + 1);
        uint count = 0;
        uint i = from;
        uint max = to;
        while(i <= max) {
            address addi = Factory(factory).allPairs(i);
            uint256 bal = IERC20(addi).balanceOf(account);
            if (bal > 0) {
                (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = Pair(addi).getReserves();
                address token0 = Pair(addi).token0();
                address token1 = Pair(addi).token1();
                blockTimestampLast = 0;
                userInfo[count] = PairInfo({
                    pairAddress : addi,
                    reserve0 : reserve0,
                    reserve1 : reserve1,
                    totalSupply : Pair(addi).totalSupply(),
                    token0 : token0,
                    token1 : token1,
                    token0Name : IERC20(token0).name(),
                    token1Name : IERC20(token1).name(),
                    token0Symbol : IERC20(token0).symbol(),
                    token1Symbol : IERC20(token1).symbol(),
                    userBal : bal
                });
                count++;
            }
            i++;
        }
        return userInfo;
    }
}