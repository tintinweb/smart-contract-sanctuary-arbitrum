// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {IERC20Metadata} from "./IERC20Metadata.sol";
import {IMUSD} from "./IMUSD.sol";
import {Allowed} from "./Allowed.sol" ;

contract MUSD is IMUSD, IERC20Metadata, Allowed {
    uint256 private totalShares;
    uint256 private totalMUSDCirculation;

     // User level balances
    mapping(address => uint256) private shares;
    mapping(address => mapping(address => uint256)) private allowances;

    // Events
    event SharesBurnt(address indexed account, uint256 pre, uint256 post, uint256 sharesAmount);
    event TransferShares(address indexed from, address indexed to, uint256 sharesValue);

    address public  mUSDManager;

    // Constructor
    constructor() Allowed(msg.sender) {}

    modifier onlyManager() {
        require(msg.sender == mUSDManager, "mUSD: Invalid caller");
        _;
    } 

    function setmUSDManager(address _mUSDManager) external onlyOwner {
        require(_mUSDManager != address(0) && _mUSDManager != address(this), "mUSD: Invalid address");
        mUSDManager = _mUSDManager;
    }

    function getSharesByMintedMUSD(uint256 _mUSDAmount) public view returns (uint256) {
        if (totalMUSDCirculation == 0) {
            return _mUSDAmount;
        } 
        return (_mUSDAmount * totalShares) / totalMUSDCirculation;
    }

    function getMintedMUSDByShares(uint256 _sharesAmount) public view returns (uint256) {
        if (totalShares == 0) {
            return _sharesAmount;
        }
        return (_sharesAmount * totalMUSDCirculation) / totalShares;
    }

    function name() external pure override returns (string memory) {
        return "mUSD Token";
    }

    function symbol() external pure override returns (string memory) {
        return "mUSD";
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function sharesOf(address _account) public view returns (uint256) {
        return shares[_account];
    }

    function totalSupply() external view override returns (uint256) {
        return totalMUSDCirculation;
    }

    function getTotalShares() external view returns (uint256) {
        return totalShares;
    }

    function balanceOf(address _account) external view override returns (uint256) {
        return getMintedMUSDByShares(sharesOf(_account));
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_spender != address(0) && _owner != address(0), "mUSD: Invalid address");
        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

     function _transfer(address _sender, address _recipient, uint256 _amount) internal virtual {
        uint256 _sharesToTransfer = getSharesByMintedMUSD(_amount);
        _transferShares(_sender, _recipient, _sharesToTransfer);
        emit Transfer(_sender, _recipient, _amount);
        emit TransferShares(_sender, _recipient, _sharesToTransfer);
    }

    function _transferShares(address _sender, address _recipient, uint256 _sharesAmount) internal virtual {
        require(_recipient != address(0) && _sender != address(0), "mUSD: Invalid address");

        uint256 currentSenderShares = shares[_sender];
        require(_sharesAmount <= currentSenderShares, "mUSD: Insufficient shares");

        shares[_sender] = currentSenderShares - _sharesAmount;
        shares[_recipient] = shares[_recipient] + _sharesAmount;
    }

    function mintShares(address _recipient, uint256 _sharesAmount, uint256 _amount) external override onlyManager returns (uint256) {
        require(_recipient != address(0), "mUSD: Invalid address");
        require(getSharesByMintedMUSD(_amount) == _sharesAmount, "mUSD: incorrect amount");
        totalShares += _sharesAmount;
        shares[_recipient] = shares[_recipient] + _sharesAmount;
        totalMUSDCirculation += _amount;
        return totalShares;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external override returns (bool) {
        uint256 currentAllowance = allowances[_sender][msg.sender];
        require(currentAllowance >= _amount, "mUSD: Insufficient allowance");

        _approve(_sender, msg.sender, (currentAllowance - _amount));
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function burnShares(address _account, uint256 _sharesAmount, uint256 _amount) external override onlyManager returns (uint256) {
        require(_account != address(0), "mUSD: Invalid address");
        uint256 accountShares = shares[_account];
        require(_sharesAmount <= accountShares, "mUSD: Insufficient balance");

        uint256 preRebaseTokenAmount = getMintedMUSDByShares(_sharesAmount);
        totalShares -= _sharesAmount;
        shares[_account] -= _sharesAmount;
        totalMUSDCirculation -= _amount;
        uint256 postRebaseTokenAmount = getMintedMUSDByShares(_sharesAmount);

        emit SharesBurnt(_account, preRebaseTokenAmount, postRebaseTokenAmount, _sharesAmount);
        return totalShares;
    }

    function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256) {
        address caller = msg.sender;
        _transferShares(caller, _recipient, _sharesAmount);
        emit TransferShares(caller, _recipient, _sharesAmount);
        uint256 tokensAmount = getMintedMUSDByShares(_sharesAmount);
        emit Transfer(caller, _recipient, tokensAmount);
        return tokensAmount;
    }
}