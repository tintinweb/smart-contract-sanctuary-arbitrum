// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

// import "forge-std/console2.sol";
import {GelatoOps} from "../../libs/GelatoOps.sol";

contract StaticCallExecutorMock {
    uint public count = 0;
    uint public lastTime = 0;
    address public gelatoExecutor;
    address public resolver;

    constructor() {
        gelatoExecutor = GelatoOps.getDedicatedMsgSender(msg.sender);
    }

    function setResolver(address _resolver) external {
        resolver = _resolver;
    }

    function incrementCounter(uint _minCount) external returns (uint256) {
        //require msg.sender == gelatoExecutor
        require(msg.sender == gelatoExecutor || msg.sender == resolver, "msg.sender is error");

        uint _count = count + 1;
        require(_count >= _minCount, "count < minCount");
        count = _count;
        lastTime = block.timestamp;
        return count;
    }
}

// SPDX-License-Identifier: UNLICENSED
//forked and minimize from https://github.com/gelatodigital/ops/blob/f6c45c81971c36e414afc31276481c47e202bdbf/contracts/integrations/OpsReady.sol
pragma solidity ^0.8.16;

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

/**
 * @dev Inherit this contract to allow your smart contract to
 * - Make synchronous fee payments.
 * - Have call restrictions for functions to be automated.
 */
library GelatoOps {
    address private constant OPS_PROXY_FACTORY = 0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    function getDedicatedMsgSender(address msgSender) external view returns (address dedicatedMsgSender) {
        (dedicatedMsgSender, ) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(msgSender);
    }
}