/**
 *Submitted for verification at Arbiscan on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract ContextAirdropNFT {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract OwnableAirdropNFT is ContextAirdropNFT {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC721A {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IERC20AirdropNFT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

}

contract AirdropNFT is OwnableAirdropNFT {

    struct User {
        uint256 claimAt;
        bool isClaimed;
    }

    mapping(address => User) public users;

    address public nftForAirdrop;
    address public tokenForAirdrop;
    uint256 public totalClaimAirdrop;
    uint256 public maximumTotalClaimAirdrop;
    uint256 public amountAirdrop;
    bool public isClaimEnabled;

    event UpdateTokenForAirdrop(address oldToken, address newToken);
    event UpdateNFTForAirdrop(address oldToken, address newToken);
    event UpdateTokenForReward(address oldToken, address newToken);
    event ResetTotalClaimAirdrop(uint256 total);
    event UpdateMaximumTotalAirdrop(uint256 oldValue,uint256 amount);
    event UpdateAmountAirdrop(uint256 oldValue,uint256 amount);
    event ToggleAirdrop(bool state);
    event ClaimAirdrop(address account, uint256 userBalance, uint256 amount);

    constructor() {
        nftForAirdrop = 0xFD6A27703eB1beDE70eF3F030A138254AdcCEBB3;
        tokenForAirdrop = 0x4faA2C69a759D7f0C66c256FfD2E306CcAe2cbB1;
        maximumTotalClaimAirdrop = 1000;
        amountAirdrop = 1 ether;
        isClaimEnabled = true;
    }

    function updateTokenForAirdrop(address token) external onlyOwner{
        address oldToken = token;
        tokenForAirdrop = token;
        emit UpdateTokenForAirdrop(oldToken,token);
    }

    function updateNFTForAirdrop(address token) external onlyOwner{
        address oldToken = token;
        nftForAirdrop = token;
        emit UpdateNFTForAirdrop(oldToken,token);
    }

    function resetTotalClaimAirdrop() external onlyOwner {
        require(totalClaimAirdrop > 0,"Currently is zero value");
        uint256 lastTotal = totalClaimAirdrop;
        totalClaimAirdrop = 0;
        emit ResetTotalClaimAirdrop(lastTotal);
    }

    function updateMaximumTotalAirdrop(uint256 amount) external onlyOwner {
        uint256 oldValue = maximumTotalClaimAirdrop;
        maximumTotalClaimAirdrop = amount;
        emit UpdateMaximumTotalAirdrop(oldValue,amount);
    }

    function updateAmountAirdrop(uint256 amount) external onlyOwner {
        require(amount > 0,"Cannot set amount to zero");
        uint256 oldValue = amountAirdrop;
        amountAirdrop = amount;
        emit UpdateAmountAirdrop(oldValue,amount);
    }

    function claim() external {
        require(isClaimEnabled,"Airdrop is not enabled");
        require(totalClaimAirdrop <= maximumTotalClaimAirdrop,"Airdrop has reached maximum");
        require(!users[_msgSender()].isClaimed,"Cannot claim multiple times");

        uint256 userNftBalance = IERC721A(nftForAirdrop).balanceOf(_msgSender());

        

        uint256 totalAirdrop = userNftBalance * amountAirdrop;
        totalClaimAirdrop += 1;
        users[_msgSender()].claimAt = block.timestamp;
        users[_msgSender()].isClaimed = true;
        IERC20AirdropNFT(tokenForAirdrop).transfer(_msgSender(),totalAirdrop);
        emit ClaimAirdrop(_msgSender(),userNftBalance,totalAirdrop);
    }

    function calculateAirdrop(address account) external view returns(uint256) {
        uint256 userNftBalance = IERC721A(nftForAirdrop).balanceOf(account);
        uint256 totalAirdrop = userNftBalance * amountAirdrop;
        return totalAirdrop;
    }

    function claimStuckTokens(address token) external onlyOwner {
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20AirdropNFT ERC20token = IERC20AirdropNFT(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function toggleAirdrop(bool state) external onlyOwner {
        isClaimEnabled = state;
        emit ToggleAirdrop(state);
    }
}