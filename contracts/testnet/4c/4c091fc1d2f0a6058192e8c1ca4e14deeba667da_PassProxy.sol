/**
 *Submitted for verification at Arbiscan on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Manager is Context {

    mapping(address => bool) private _accounts;

    modifier onlyManager {
        require(isManager(), "only manager");
        _;
    }

    constructor() {
        _accounts[_msgSender()] = true;
    }

    function isManager(address one) public view returns (bool) {
        return _accounts[one];
    }

    function isManager() public view returns (bool) {
        return isManager(_msgSender());
    }

    function setManager(address one, bool val) public onlyManager {
        require(one != address(0), "address is zero");
        _accounts[one] = val;
    }

    function setManagerBatch(address[] calldata list, bool val) public onlyManager {
        for (uint256 i = 0; i < list.length; i++) {
            setManager(list[i], val);
        }
    }
}

interface SpiderPass {
    function mint(address to, string calldata code) external;
}

contract PassProxy is Context, Manager {
    
    SpiderPass private _vip;
    SpiderPass private _svip;

    address private _beneficiary;
    uint256 private _priceVIP = 0.004 ether;
    uint256 private _priceSVIP = 0.02 ether;

    constructor(address vip, address svip) {
        _vip = SpiderPass(vip);
        _svip = SpiderPass(svip);
        _beneficiary = _msgSender();
    }

    function setBeneficiary(address one) public onlyManager {
        require(one != address(0), "address is zero");
        _beneficiary = one;
    }

    function setVip(address addr) public onlyManager {
        require(addr.code.length > 0);
        _vip = SpiderPass(addr);
    }

    function setSVIP(address addr) public onlyManager {
        require(addr.code.length > 0);
        _svip = SpiderPass(addr);
    }

    function getPrices() public view returns (uint256, uint256) {
        return (_priceVIP, _priceSVIP);
    }

    function setPrices(uint256 priceVIP, uint256 priceSVIP) public onlyManager {
        _priceVIP = priceVIP;
        _priceSVIP = priceSVIP;
    }

    function mintVIP(string memory code) public payable {
        require(msg.value >= _priceVIP, "not enough ETH");
        _vip.mint(_msgSender(), code);
    }

    function mintSVIP(string memory code) public payable {
        require(msg.value >= _priceSVIP, "not enough ETH");
        _svip.mint(_msgSender(), code);
    }

    function withdraw() public onlyManager {
        require(_beneficiary != address(0), "beneficiary is zero");
        uint256 balance = address(this).balance;
        require(balance > 0, "balance is zero");
        payable(_beneficiary).transfer(balance);
    }

}