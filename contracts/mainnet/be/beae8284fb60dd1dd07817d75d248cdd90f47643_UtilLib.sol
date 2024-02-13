// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library UtilLib {
    /// @notice zero address check modifier
    function checkNonZeroAddress(address _address) internal pure {
        require(_address != address(0), "empty address");
    }

    // function checkExecutionFee(
    //     uint256 _fee,
    //     address _weth,
    //     address vault
    // ) internal view returns (bool) {
    //     if (_fee > IERC20(_weth).balanceOf(vault)) return true;
    //     else return false;
    // }

    // function checkLeverage(
    //     uint256 leverage,
    //     uint256 maxLeverage,
    //     uint256 minLeverage
    // ) internal pure returns (uint256) {
    //     uint256 _leverage = leverage / 10e25;
    //     if (_leverage / 10e25 > maxLeverage) return maxLeverage * 10e25;
    //     else if (_leverage < minLeverage) return minLeverage * 10e25;
    //     else return leverage;
    // }

    /**
     * @notice Create and return an array of 1 item.
     * @param _token Address of the token.
     * @return path
     */
    function get1TokenSwapPath(
        address _token
    ) internal pure returns (address[] memory path) {
        path = new address[](1);
        path[0] = _token;
    }

    /**
     * @notice Create and return an 2 item array of addresses used for
     *         swapping.
     * @param _token1 Token in or input token.
     * @param _token2 Token out or output token.
     * @return path
     */
    function get2TokenSwapPath(
        address _token1,
        address _token2
    ) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = _token1;
        path[1] = _token2;
    }

    /**
     * @dev Hash function for the EIP712 domain separator
     */
    // function eip712domainSeparator() internal view returns (bytes32) {
    //     return
    //         keccak256(
    //             abi.encode(
    //                 keccak256(
    //                     "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    //                 ),
    //                 keccak256(bytes("AlgoTradeManager")),
    //                 keccak256(bytes("1")),
    //                 block.chainid,
    //                 address(this)
    //             )
    //         );
    // }

    function compareString(
        string memory s1,
        string memory s2
    ) public pure returns (bool) {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function getCollateralToken(
        address[] memory path,
        bytes4 selector
    ) internal pure returns (address collateralToken) {
        collateralToken = path[0];

        if (path.length == 2)
            if (
                selector == bytes4(0xf2ae372f) || selector == bytes4(0x5b88e8c6)
            ) collateralToken = path[1];
    }
}