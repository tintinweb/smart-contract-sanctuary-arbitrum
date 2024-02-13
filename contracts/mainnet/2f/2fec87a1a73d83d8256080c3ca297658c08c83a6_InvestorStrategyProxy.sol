// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IStrategy {
    function mint(uint256 amount) external returns (uint256 shares);
    function burn(uint256 shares) external returns (uint256 amount);
    function kill(uint256 shares, address to) external returns (bytes memory);
}

contract InvestorStrategyProxy {
    IERC20 public asset;
    mapping(address => bool) public exec;

    event File(bytes32 indexed what, address data);

    error InvalidFile();
    error Unauthorized();

    constructor(address _asset) {
        asset = IERC20(_asset);
        exec[msg.sender] = true;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function file(bytes32 what, address data) public auth {
        if (what == "exec") {
          exec[data] = !exec[data];
        } else {
            revert InvalidFile();
        }
        emit File(what, data);
    }

    function mint(address strategy, uint256 amount) public auth returns (uint256) {
        asset.approve(strategy, amount);
        return IStrategy(strategy).mint(amount);
    }

    function burn(address strategy, uint256 shares) public auth returns (uint256) {
        uint256 amount = IStrategy(strategy).burn(shares);
        asset.transfer(msg.sender, amount);
        return amount;
    }

    function kill(address strategy, uint256 shares, address target) public auth returns (bytes memory) {
        return IStrategy(strategy).kill(shares, target);
    }

    function call(address strategy, uint256 value, bytes calldata data) public auth {
        (bool success,) = strategy.call{value: value}(data);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}