// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./Feeable.sol";

interface ERC20 {
    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool ok);
}

contract U9ClubMultiplexer is Feeable {
    function sendEth(address[] calldata _to, uint256[] calldata _value)
        external
        payable
        returns (bool _success)
    {
        // input validation
        assert(_to.length == _value.length);
        assert(_to.length <= 255);
        // uint256 fee = minFee();
        // require(msg.value > fee);

        uint256 remain_value = msg.value;

        // loop through to addresses and send value
        for (uint8 i = 0; i < _to.length; i++) {
            require(remain_value >= _value[i]);
            remain_value = remain_value - _value[i];

            payable(_to[i]).transfer(_value[i]);
        }

        return true;
    }

    function sendErc20(
        address _tokenAddress,
        address[] calldata _to,
        uint256[] calldata _value
    ) external payable returns (bool _success) {
        // input validation
        assert(_to.length == _value.length);
        assert(_to.length <= 255);
        // require(msg.value >= minFee());

        // use the erc20 abi
        ERC20 token = ERC20(_tokenAddress);
        // loop through to addresses and send value
        for (uint8 i = 0; i < _to.length; i++) {
            assert(token.transferFrom(msg.sender, _to[i], _value[i]) == true);
        }
        return true;
    }

    function claim(address _token) public onlyOwner {
        if (_token == address(0x0)) {
            payable(owner).transfer(address(this).balance);
            return;
        }
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner, balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
import "./Ownable.sol";

contract Feeable is Ownable {
    uint8 public feePercent;

    constructor() {
        feePercent = 80;
    }

    function setFeePercent(uint8 _feePercent) public onlyOwner {
        feePercent = _feePercent;
    }

    function minFee() public view returns (uint256) {
        return (tx.gasprice * gasleft() * feePercent) / 100;
    }
}