/**
 *Submitted for verification at Arbiscan on 2023-04-09
*/

/**

██╗   ██╗ ██████╗  ██████╗ ██╗
╚██╗ ██╔╝██╔═══██╗██╔════╝ ██║
 ╚████╔╝ ██║   ██║██║  ███╗██║
  ╚██╔╝  ██║   ██║██║   ██║██║
   ██║   ╚██████╔╝╚██████╔╝██║
   ╚═╝    ╚═════╝  ╚═════╝ ╚═╝
                              
*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;
}

contract YogiBridgeArb {
  address public admin;
  address public vault;
  address public feeAddress;
  IERC20 public token;
  uint256 public taxfee;

  constructor(address _token) {
    admin = msg.sender;
    vault = msg.sender;
    feeAddress = msg.sender;
    token = IERC20(_token);
    taxfee = 0;
  }

  function changeToken(address _token) external{
    require(msg.sender == admin, 'only admin');
    token = IERC20(_token);
  }

  function burn(uint amount) external {
    token.transferFrom(msg.sender, vault ,amount-(taxfee*(10**(token.decimals()))));
    token.transferFrom(msg.sender, feeAddress , (taxfee*(10**(token.decimals()))));
  }

  function mint(address to, uint amount) external {
    require(msg.sender == admin, 'only admin');
    token.transferFrom(vault, to, amount);
  }
  function getContractTokenBalance() external view returns (uint256) {
    return token.balanceOf(address(this));
  }
  function withdraw(uint amount) external {
    require(msg.sender == admin, 'only admin');
    token.transfer(msg.sender, amount);
  }
  function changeAdmin(address newAdmin) external {
    require(msg.sender == admin, 'only admin');
    admin = newAdmin;
  }
  function changeVault(address newVault) external {
    require(msg.sender == admin, 'only admin');
    vault = newVault;
  }
  function changefeeAddress(address newfeeAddress) external {
    require(msg.sender == admin, 'only admin');
    feeAddress = newfeeAddress;
  }
  function setTaxFee(uint newTaxFee) external {
    require(msg.sender == admin, 'only admin');
    taxfee = newTaxFee;
  }
  function withdrawStuckToken(IERC20 _token) external{
    require(msg.sender == admin, 'only admin');
    _token.transfer(msg.sender, _token.balanceOf(address(this)));
  }
}