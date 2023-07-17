// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {IERC20} from "./IERC20.sol";
import {MerkleProof} from "./MerkleProof.sol";

import {IMeta} from "./IMeta.sol";
import {Allowed} from "./Allowed.sol";

import {Constants} from "./Constants.sol";

import "./console.sol";

contract IDO is Allowed {
    uint256 public totalSupply;
    uint256 public price;
    uint256 public minBuy;
    uint256 public maxBuy;
    uint256 public wlBoost;

    IERC20 public weth;
    IMeta public esMeta;

    uint256 public startTime; 
    uint256 public endTime;
    uint256 public claimTime;

    bytes32 public root;
    address public mulSig;

    bool public computedFinalPrice = false;

    mapping(address => uint256) public deposited;

    constructor(address _weth, address _esMeta, address _mulSig) Allowed(msg.sender) {
        totalSupply = 5_000_000 * Constants.PINT;
        price = 10_000 * Constants.PINT;
        minBuy = 0.1e18;
        maxBuy = 100 * Constants.PINT;
        wlBoost = 120 * Constants.PINT;

        weth = IERC20(_weth);
        esMeta = IMeta(_esMeta);

        mulSig = _mulSig;
    }

    function isValidProof(bytes32[] calldata _mProof) internal view returns (bool verified) {
        verified = MerkleProof.verify(_mProof, root, keccak256(abi.encodePacked(msg.sender)));
    }

    function verifyProof(address user, bytes32[] calldata _mProof) external view returns (bool) {
        bool verified = MerkleProof.verify(_mProof, root, keccak256(abi.encodePacked(user)));
        return verified;
    }

    function setESMeta(address _esMeta) external onlyOwner {
        require(_esMeta != address(0), "Invalid esMeta address");
        esMeta = IMeta(_esMeta);
    }

    function setWETH(address _weth) external onlyOwner {
        require(_weth != address(0), "Invalid esMeta address");
        weth = IERC20(_weth);
    }

    modifier onlyOnSale() {
        require(block.timestamp > startTime && block.timestamp < endTime, "IDO: Sale is not on");
        _;
    }

    modifier onlyAfterSale {
        require(block.timestamp >= endTime, "IDO : IDO is on going");
        _;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setPrice(uint256 _price) external onlyOwner {
        require(block.timestamp < startTime, "IDO: IDO has started");
        require(_price > price, "IDO: Price can only reduce"); // price is 10,000 META/ETH
        price = _price;
    }

    function setMinBuy(uint256 _minBuy) external onlyOwner {
        require(block.timestamp < startTime, "IDO: IDO has started");
        minBuy = _minBuy;
    }

    function setMaxBuy(uint256 _maxBuy) external onlyOwner {
        require(block.timestamp < startTime, "IDO: IDO has started");
        maxBuy = _maxBuy;
    }

    function setStartTime(uint256 _start) external onlyOwner {
        require(_start >= block.timestamp, "IDO: Invalid start time window");
        startTime = _start;
    }

    function setEndTime(uint256 _end) external onlyOwner {
        require(_end > startTime, "IDO: Invalid end time window");
        claimTime = _end + 3 hours;
        endTime = _end;
    }

    function setClaimTime(uint256 _claimTime) external onlyOwner{
        require(_claimTime > endTime, "IDO: Invalid claim time");
        claimTime = _claimTime;
    }

    function setWLBoost(uint256 _wlBoost) external onlyOwner {
        require(block.timestamp < startTime, "IDO: IDO has started");
        wlBoost = _wlBoost;
    }

    function setMulSigAcc(address _account) external onlyOwner {
        require(_account != address(0), "IDO: Invalid address");
        require(_account != address(this), "IDO: address can't be contract");
        mulSig = _account;
    }

    function setFinalPrice() internal {
        if(!computedFinalPrice) {
            uint256 totalDeposit = totalDeposits();
            if( totalDeposit > (totalSupply * Constants.PINT / price)) {
                price = (totalSupply * Constants.PINT) / totalDeposit;
            }
            computedFinalPrice = true;
        }
    }

    function deposit(uint256 _wethAmount) external payable onlyOnSale  {
        uint256 _ethAmount = msg.value;
        address caller = msg.sender;

        uint256 amount = _ethAmount + _wethAmount + deposited[caller];
        require(amount >= minBuy && amount <= maxBuy, "IDO: Invalid amount");

        if (_wethAmount > 0) {
            weth.transferFrom(caller, address(this), _wethAmount);
        }
        deposited[caller] = amount;
    }

    function mint(bytes32[] calldata _proof) external {
       _mint(msg.sender, isValidProof(_proof));
    }

    function _mint(address _user, bool isWhitelisted) internal {
        require(block.timestamp >= claimTime, "IDO: Too early to mint");
        if(!computedFinalPrice) setFinalPrice();
        uint256 amount = deposited[_user];
        deposited[_user] = 0;

        amount = isWhitelisted ? (amount * price * wlBoost)/1e38 : (amount * price)/Constants.PINT;
        esMeta.mint(_user, amount);
    }

    function totalDeposits() public view returns(uint256) {
        return balanceOfEth() + balanceOfWEth();
    }

    function balanceOfEth() public view returns(uint256) {
        return address(this).balance;
    }

    function balanceOfWEth() public view returns(uint256) {
        return weth.balanceOf(address(this));
    }

    function withdrawAll() external onlyAfterSale onlyOwner {
        if(!computedFinalPrice) setFinalPrice();
        if (balanceOfEth() > 0){
            (bool suceess, ) = payable(mulSig).call{value: balanceOfEth()}(""); // send ether
            require(suceess, "eth transfer failed");
        }
        if (balanceOfWEth() > 0) {
            weth.transfer(mulSig, balanceOfWEth()); // send wETH
        }
    }

    function withdrawEth() external onlyAfterSale onlyOwner {
        if(!computedFinalPrice) setFinalPrice();
        if (balanceOfEth() > 0){
            (bool suceess, ) = payable(mulSig).call{value: balanceOfEth()}(""); // send ether
            require(suceess, "eth transfer failed");
        }
    }

    function withdrawWEth() external onlyAfterSale onlyOwner {
        if(!computedFinalPrice) setFinalPrice();
        if (balanceOfWEth() > 0) {
            weth.transfer(mulSig, balanceOfWEth()); // send wETH
        }
    }

    function sendToken(address token, address to, uint256 amount) external onlyOwner {
        require(token != address(weth), "IDO: Not for WETH");
        require(block.timestamp >= endTime, "IDO: IDO is ongoing");
        IERC20(token).transfer(to, amount);
    }

    function getDepositOf(address _user) external view returns (uint256) {
        return deposited[_user];
    } 

    function ethBalance(address _user) external view returns (uint256) {
        return address(_user).balance;
    }
}