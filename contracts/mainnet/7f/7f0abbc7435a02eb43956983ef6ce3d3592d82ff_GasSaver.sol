/**
 *Submitted for verification at Arbiscan on 2023-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

interface IZapLock {
    function zapOnBehalf(
		bool _borrow,
		uint256 _wethAmt,
		uint256 _rdntAmt,
		address _onBehalf
	) external payable returns (uint256);
}

interface IERC20 {
	function balanceOf(address) external returns (uint256);

	function approve(address guy, uint256 wad) external returns (bool);

	function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}

contract GasSaver {

    IZapLock zapLocker = IZapLock(0x8991C4C347420E476F1cf09C03abA224A76E2997);
    IERC20 WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    
    function zapOneMonthWallet(bytes32 _rndtAndWEth) external payable returns(uint256,uint256){   
        uint256 rdntAmount = uint256(_rndtAndWEth) >> 128;
        uint256 wethAmount = uint256(_rndtAndWEth) & uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        WETH.approve(address(zapLocker),wethAmount);
        WETH.transferFrom(msg.sender,address(this),wethAmount);
        zapLocker.zapOnBehalf(false,wethAmount,rdntAmount,msg.sender);
        return(rdntAmount,wethAmount);
    }

    function uintToBytes(uint128 _amountOne, uint128 _amountTwo) external pure returns(bytes32){   
        bytes32 packedAmounts = (bytes32(uint256(_amountOne)) << 128) | bytes32(uint256(_amountTwo));
        return(packedAmounts);
    }
}