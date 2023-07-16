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

contract GasSaver {

    IZapLock zapLocker = IZapLock(0x8991C4C347420E476F1cf09C03abA224A76E2997);
    
    function zapOneMonthWallet(bytes32 _rndtAndWEth) external returns(uint256,uint256){   
        uint256 rdntAmount = uint256(_rndtAndWEth) >> 128;
        uint256 wethAmount = uint256(_rndtAndWEth) & uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        zapLocker.zapOnBehalf(false,wethAmount,rdntAmount,msg.sender);
        return(rdntAmount,wethAmount);
    }

    function uintToBytes(uint128 _amountOne, uint128 _amountTwo) external view returns(bytes32){   
        bytes32 packedAmounts = (bytes32(uint256(_amountOne)) << 128) | bytes32(uint256(_amountTwo));
        //(bytes32(_amountOne) << 128) | bytes32(_amountTwo)
        return(packedAmounts);
    }
}