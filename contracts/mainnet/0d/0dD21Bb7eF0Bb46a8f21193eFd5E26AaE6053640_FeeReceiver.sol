// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.20;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

contract FeeReceiver {
    // storage
    address internal s_setter;
    address internal s_collector;

    modifier onlySetter() {
        require(msg.sender == s_setter, "FeeReciever: NOT_SETTER");
        _;
    }

    modifier onlyCollector() {
        require(msg.sender == s_collector, "FeeReciever: NOT_COLLECTOR");
        _;
    }

    constructor(address setter) {
        s_setter = setter;
    }

    // accepting ETH
    receive() external payable {}

    function setSetter(address setter) external onlySetter {
        s_setter = setter;
    }

    function setCollector(address collector) external onlySetter {
        s_collector = collector;
    }

    function collect(
        address token,
        address recipient,
        uint256 amount
    ) external onlyCollector {
        if (token == address(0)) {
            TransferHelper.safeTransferETH(recipient, amount);
        } else {
            TransferHelper.safeTransfer(token, recipient, amount);
        }
    }

    function getSetter() external view returns (address) {
        return s_setter;
    }

    function getCollector() external view returns (address) {
        return s_collector;
    }
}