/**
 *Submitted for verification at Arbiscan on 2023-05-16
*/

pragma solidity ^0.8.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Owner {
    address private _owner;
    address private _pendingOwner;

    event NewOwner(address indexed owner);
    event NewPendingOwner(address indexed pendingOwner);

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function setPendingOwner(address account) external onlyOwner {
        require(account != address(0), "zero address");
        _pendingOwner = account;
        emit NewPendingOwner(_pendingOwner);
    }

    function becomeOwner() external {
        require(msg.sender == _pendingOwner, "not pending owner");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit NewOwner(_owner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IFrog721 {
    function minerEnable(address miner_, bool enable) external;
    function mint(address recipient_) external returns (uint256);
}

contract Frog721Helper  is Owner {

    using SafeMath for uint256;

   
    IFrog721 public nftAddress;
    IERC20 public token;

    uint256 public price = 0.0003 ether;

    uint256 public amountPerMint = 100 * 10**18;
    uint256 public nftPerUser = 10;

    mapping(address=>uint256) public cnts;
    mapping(address=>uint256) public tokenAmount;


    constructor(address _nftAddress,address _token) {
       nftAddress=IFrog721(_nftAddress); 
       token=IERC20(_token);
    }

    function mintNFT(address _recipient,uint256 _nftAmount) external payable returns(uint256[] memory) {
        require(cnts[_recipient]+_nftAmount<=nftPerUser,"exceeded limit");
        require(msg.value >= price.mul(_nftAmount), "not enough eth");
        tokenAmount[_recipient]=tokenAmount[_recipient].add(amountPerMint.mul(_nftAmount));
        cnts[_recipient]=cnts[_recipient].add(_nftAmount);
       
          uint256[] memory nftIds = new uint256[](_nftAmount); 
         for(uint256 i=0;i<_nftAmount;i++) {
             uint256 id=nftAddress.mint(_recipient);
             nftIds[i]=id;
         }

         return nftIds;
    }

    function mintToken() external {
        require(tokenAmount[msg.sender]>0,"not token amount");
        uint256 _amount=tokenAmount[msg.sender];
        tokenAmount[msg.sender]=0;
        token.transfer(msg.sender, _amount);
    }

    function setnftPerUser(uint256 _nftPerUser) external onlyOwner {
        nftPerUser = _nftPerUser;
    }

    function setAmountPerMint(uint256 _amountPerMint) external onlyOwner {
        amountPerMint = _amountPerMint;
    }

   
    function setprice(uint256 _price) external onlyOwner {
        price = _price;
    }


    function rescueToken(
        address _token,
        address _recipient,
        uint256 _amount
    ) public onlyOwner {
        IERC20(_token).transfer(_recipient, _amount);
    }

    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sendStatus,)=_owner.call{value:amount}("");
        require(sendStatus,"Failed send");
    }
}