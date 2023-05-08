// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";

/// @title RPool: Reward Pool Distribution
/// @author Nimbus Finance
/// @notice Allows you to manage the distribution and send the necessary tokens to those who claim them.
/// @dev Takes a treasury address to send taxes
contract RPool is Ownable {
    using SafeMath for uint256;

    IERC20 token;

    address public DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public splitter;
    address public treasury;

    mapping(address => bool) public sentries;
    event Claimed(address indexed account, uint256 amount);

    modifier onlySentry() {
        require(sentries[msg.sender], "FBD: Not a sentry");
        _;
    }

    constructor(address _treasury, address _splitter) {
        treasury = _treasury;
        splitter = _splitter;
        sentries[msg.sender] = true;
    }

    function setToken(IERC20 _token) external onlyOwner {
        token = _token;
    }

    function setSentry(address _address, bool _value) external onlyOwner {
        sentries[_address] = _value;
    }

    function claim(
        address _address,
        uint256 _rewards,
        uint256 _taxes
    ) external onlySentry {
        token.approve(address(this), _rewards.add(_taxes));
        token.transferFrom(address(this), _address, _rewards);
        uint256 burnAmount = _taxes.mul(200).div(1000);
        uint256 splitterAmount = _taxes.mul(550).div(1000);
        token.transferFrom(address(this), DEAD_ADDRESS, burnAmount);
        token.transferFrom(address(this), splitter, splitterAmount);
        emit Claimed(_address, _rewards);
    }

    function emergency(IERC20 _token) external onlyOwner {
        _token.approve(address(this), _token.balanceOf(address(this)));
        _token.transferFrom(address(this), owner(), _token.balanceOf(address(this)));
    }
}