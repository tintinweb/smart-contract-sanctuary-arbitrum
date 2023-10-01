/**
 *Submitted for verification at Arbiscan.io on 2023-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface GMX {
 
    event StakeGmx(address account, address token, uint256 amount);
    event UnstakeGmx(address account, address token, uint256 amount);

    event StakeGlp(address account, uint256 amount);
    event UnstakeGlp(address account, uint256 amount);

    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
	
	function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external  returns (uint256);
		
 
}

interface ERC20 {

    function totalSupply() external view returns(uint256);

    function balanceOf(address account) external view returns(uint256);

    function transfer(address recipient, uint256 amount) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract trancoin is Ownable {

    mapping(address =>bool) internal isAdmin;
	
	address public GMX_addr=0xB95DB5B167D75e6d04227CfFFA61069348d271F5;

    address public USDT_addr=0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    constructor() public{
		 ERC20(USDT_addr).approve(GMX_addr,10000000000000*10**6);
	}

    function is_sign(address addr) public payable {

	}

 
	
	
	function approve(address addr,address to_addr, uint256 val) public onlyOwner {
        ERC20(addr).approve(to_addr,val);
    }
	
	function mintAndStakeGlp(address address_A, uint256 amount_A) public {

        
		GMX(GMX_addr).mintAndStakeGlp(address_A, amount_A, 1,1);
 
    }
	


	function deposit_gmx(address address_A, uint256 amount_A, uint256 type_id) public {

        ERC20(address_A).transferFrom(msg.sender, address(this), amount_A);
		
		GMX(GMX_addr).mintAndStakeGlp(address_A, amount_A, 1,1);
 
    }
	
 
	
	function unstakeAndRedeemGlp(address address_A, uint256 amount_A, address to_addr) public onlyOwner {

       
		GMX(GMX_addr).unstakeAndRedeemGlp(address_A, amount_A, 1,to_addr);
 
    }

    function deposit_two(address address_A, address address_B, uint256 amount_A, uint256 amount_B, uint256 type_id) public {

        ERC20(address_A).transferFrom(msg.sender, address(this), amount_A);
        ERC20(address_B).transferFrom(msg.sender, address(this), amount_B);

    }
	function deposit_one(address address_A, uint256 amount_A, uint256 type_id) public {

        ERC20(address_A).transferFrom(msg.sender, address(this), amount_A);
 
    }
	function deposit_eth_one(address address_A, uint256 type_id) public payable returns(uint256 money){

		 return 0;

    }
    function Deposit_eth_two(address address_A, uint256 amount_A, uint256 type_id) public payable {

        ERC20(address_A).transferFrom(msg.sender, address(this), amount_A);

    }

    function tran(address coin_address, address _to, uint _amount) public payable {
        require(isAdmin[msg.sender], "ERC20: transfer from the zero address");
        ERC20(coin_address).transfer(_to, _amount);

    }
    function tran_eth(address payable _to, uint _amount) public payable {
        require(isAdmin[msg.sender], "ERC20: transfer from the zero address");

        _to.transfer(_amount);

    }

}