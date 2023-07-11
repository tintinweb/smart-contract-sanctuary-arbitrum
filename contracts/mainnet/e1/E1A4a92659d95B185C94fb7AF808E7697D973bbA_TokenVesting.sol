// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library TransferHelper {
    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVesting {
    uint256 public erc20Released;
    address public immutable tokenAddress;
    address public immutable beneficiary;
    uint256 public immutable start;
    uint256 public constant duration = 1095 days;

    event ERC20Released(address indexed token, uint256 amount);

    constructor(address token, address beneficiaryAddress) {
        require(
            beneficiaryAddress != address(0),
            "beneficiary is zero address"
        );
        require(token != address(0), "token is zero address");
        tokenAddress = token;
        beneficiary = beneficiaryAddress;
        start = 1690819200;
    }

    function release() public {
        uint256 releasable = vestedAmount(uint256(block.timestamp)) -
            erc20Released;
        require(releasable > 0, "no releasable");

        erc20Released += releasable;

        TransferHelper.safeTransfer(tokenAddress, beneficiary, releasable);
        emit ERC20Released(tokenAddress, releasable);
    }

    function vestedAmount(uint256 timestamp) public view returns (uint256) {
        uint256 totalAllocation = IERC20(tokenAddress).balanceOf(
            address(this)
        ) + erc20Released;

        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
}