// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

import "./Claimable.sol";

contract Token is ERC20, Claimable {
    uint256 public buyBurn = 200;
    uint256 public buyFee1 = 100;
    uint256 public buyFee2 = 200;
    uint256 public sellBurn = 200;
    uint256 public sellFee1 = 100;
    uint256 public sellFee2 = 200;
    address public feeTo1;
    address public feeTo2;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public pairs;

    constructor() ERC20("ArbApe AI", "AIAPE") {
        _mint(msg.sender, 210000000000000000 * 10 ** decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function setFee(
        uint256 _buyBurn,
        uint256 _buyFee1,
        uint256 _buyFee2,
        uint256 _sellBurn,
        uint256 _sellFee1,
        uint256 _sellFee2
    ) public onlyOwner {
        buyBurn = _buyBurn;
        buyFee1 = _buyFee1;
        buyFee2 = _buyFee2;
        sellBurn = _sellBurn;
        sellFee1 = _sellFee1;
        sellFee2 = _sellFee2;
    }

    function setFeeTo(address _feeTo1, address _feeTo2) public onlyOwner {
        feeTo1 = _feeTo1;
        feeTo2 = _feeTo2;
    }

    function setWhitelist(address _address, bool _state) public onlyOwner {
        whitelist[_address] = _state;
    }

    function setWhitelistBatch(address[] memory _addresses, bool _state) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = _state;
        }
    }

    function addPair(address pair) public onlyOwner {
        pairs[pair] = true;
    }

    function delPair(address pair) public onlyOwner {
        pairs[pair] = false;
    }

    function isPair(address pair) public view returns (bool) {
        return pairs[pair];
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        if (isPair(from) && whitelist[to] == false) {
            uint256 burn;
            if (buyBurn != 0) {
                burn = (amount * buyBurn) / 10000;
                super._transfer(from, 0x000000000000000000000000000000000000dEaD, burn);
            }
            uint256 fee1;
            if (buyFee1 != 0 && feeTo1 != address(0)) {
                fee1 = (amount * buyFee1) / 10000;
                super._transfer(from, feeTo1, fee1);
            }
            uint256 fee2;
            if (buyFee2 != 0 && feeTo2 != address(0)) {
                fee2 = (amount * buyFee2) / 10000;
                super._transfer(from, feeTo2, fee2);
            }
            super._transfer(from, to, amount - burn - fee1 - fee2);
            return;
        }

        if (isPair(to) && whitelist[from] == false) {
            uint256 burn;
            if (sellBurn != 0) {
                burn = (amount * sellBurn) / 10000;
                super._transfer(from, 0x000000000000000000000000000000000000dEaD, burn);
            }
            uint256 fee1;
            if (buyFee1 != 0 && feeTo1 != address(0)) {
                fee1 = (amount * buyFee1) / 10000;
                super._transfer(from, feeTo1, fee1);
            }
            uint256 fee2;
            if (buyFee2 != 0 && feeTo2 != address(0)) {
                fee2 = (amount * buyFee2) / 10000;
                super._transfer(from, feeTo2, fee2);
            }
            super._transfer(from, to, amount - burn - fee1 - fee2);
            return;
        }

        super._transfer(from, to, amount);
    }
}