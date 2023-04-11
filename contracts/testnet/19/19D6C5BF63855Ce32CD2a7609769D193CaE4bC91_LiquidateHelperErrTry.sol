/**
 *Submitted for verification at Arbiscan on 2023-04-10
*/

pragma solidity ^0.8.0;


interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address to, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}





pragma solidity >=0.8.4;



interface CToken {   
    function underlying() external view returns (address);
    function symbol() external view returns (string memory);
    function transfer(address dst, uint256 amount) external returns (bool);
}

interface ILiquidateHelperV2 { 
     struct TokenInfo {
        address cTokenAddr;
        address underlying;
        uint amount;     
        uint processedAmtInUSD; 
        uint processedAmt; 
        string  tokenName;
        uint decimals;
        uint price;
    }

    function getLiquidateInfo(address _borrower) 
                           external view returns 
                          (uint, TokenInfo[] memory, TokenInfo[] memory);
    function getexchangeRateStored(address _ctoken) external view returns (uint);
    function amountToBeLiquidatedSieze(
                                    address _cToken, 
                                    address _cTokenCollateral, 
                                    uint    _actualRepayAmount) 
                                    external view returns (uint) ;
    function liquidateForNativeToken(  
                                    address _borrower, 
                                    address _cTokenCollateral,
                                    bool    isRedeem) 
                                    external payable returns (uint256);
    function liquidateForErc20(
                              address _borrower,
                              address _cRepayToken, 
                              address _cTokenCollateral,
                              uint    _repayAmount,
                              bool    isRedeem) 
                              external returns (uint256);
}


contract LiquidateHelperErrTry {
  event ErrorLogging(string reason);
  event Logging(string reason);
 
  address public cEthAddr;
  address public  _owner;
  address public liquidateHelperv2Addr;
  ILiquidateHelperV2 public liquidatev2Contract;

    modifier onlyOwner() {
    require(msg.sender == _owner, "Not owner");
    _;
  }

  constructor (address _liquidateHelperAddr,address _cEth) {
 require(_liquidateHelperAddr != address(0), "invalid LiquidateHelperAddr!");
 require(_cEth != address(0), "invalid _cEth!");
  _owner  = msg.sender;
 cEthAddr = _cEth;
 liquidateHelperv2Addr = _liquidateHelperAddr;
 liquidatev2Contract = ILiquidateHelperV2(liquidateHelperv2Addr);

} 

function getLiquidateInfo(address _borrower) 
                           external view returns 
                          (uint rhealth, 
                          ILiquidateHelperV2.TokenInfo[] memory returnBorrows, 
                          ILiquidateHelperV2.TokenInfo[] memory returnSupplys) {
    try liquidatev2Contract.getLiquidateInfo( _borrower) returns (uint health,
                          ILiquidateHelperV2.TokenInfo[] memory retBorrows, 
                          ILiquidateHelperV2.TokenInfo[] memory retSupplys) {
        rhealth = health;
        returnBorrows = retBorrows;
        returnSupplys = retSupplys;
    } catch {
        rhealth = 0;
        returnBorrows = new ILiquidateHelperV2.TokenInfo[](0);
        returnSupplys = new ILiquidateHelperV2.TokenInfo[](0);
    }    
}

function getAllowanceByCToken(address _ctoken, address spender) public view returns (uint256 allowblance){
    address erc20Token = CToken(_ctoken).underlying();
    allowblance = getAllowanceForContract(erc20Token, spender);
}

function getAllowanceForWallet(address erc20Token, address spender) public view returns (uint256 allowblance){
    allowblance = getAllowance(erc20Token, msg.sender, spender);
}

function getAllowanceForContract(address erc20Token, address spender) public view returns (uint256 allowblance){
    allowblance = getAllowance(erc20Token, address(this), spender);
}

function getAllowance(address erc20Token, address owner, address spender) public view returns (uint256 allowblance){
    IERC20 token = IERC20(erc20Token); 
    allowblance = token.allowance(owner, spender);
}

function approveByCtoken(address _ctoken, address spender, uint256 amount) public {
  address erc20Token = CToken(_ctoken).underlying();
  approveByErc20(erc20Token, spender,amount);
}

function approveByErc20(address erc20Token, address spender, uint256 amount) public{
    IERC20 token = IERC20(erc20Token);     
    require(token.approve(spender,amount), "failed to approve");
}

function getexchangeRateStored(address _ctoken) external view returns (uint) {      
      return liquidatev2Contract.getexchangeRateStored(_ctoken);
}

function amountToBeLiquidatedSieze(
                                    address _cToken, 
                                    address _cTokenCollateral, 
                                    uint    _actualRepayAmount) 
                                    external view returns (uint)  { 
  return liquidatev2Contract.amountToBeLiquidatedSieze(_cToken,_cTokenCollateral,_actualRepayAmount);
}

function liquidateForErc20(
                              address _borrower,
                              address _cRepayToken, 
                              address _cTokenCollateral,
                              uint    _repayAmount,
                              bool    isRedeem) 
                              external  {

    string memory info; 
    {
      address erc20Token = CToken(_cRepayToken).underlying();
      IERC20 token = IERC20(erc20Token); 
      token.transferFrom(msg.sender, address(this), _repayAmount); 
    }

    uint256 allowblance = getAllowanceByCToken(_cRepayToken, liquidateHelperv2Addr);
    if(allowblance < _repayAmount){
      approveByCtoken(_cRepayToken, liquidateHelperv2Addr, _repayAmount);
    }

    uint256 beforeBalance = address(this).balance;
    try liquidatev2Contract.liquidateForErc20( _borrower,
                                              _cRepayToken, 
                                              _cTokenCollateral,
                                              _repayAmount,
                                              isRedeem) returns (uint256 diff) {
        uint256 roseDiff= address(this).balance - beforeBalance;
        if(diff > 0){
          if(isRedeem){
              if(_cTokenCollateral == cEthAddr && roseDiff > 0){
                transferNativeToken(payable(msg.sender), roseDiff);  
              }else{
                IERC20 token = IERC20(CToken(_cTokenCollateral).underlying()); 
                transferErc20cToken(msg.sender, CToken(_cTokenCollateral).underlying(), token.balanceOf(address(this)));
              }
          }else{
            transferErc20cToken(msg.sender, _cTokenCollateral, diff);
          }
        }

        info = strConcat("Success liquidateForErc20 return ftoken:[",CToken(_cTokenCollateral).symbol(),"] Amt: [",uint2str(diff),"]");        
        emit Logging(info);
    } catch Error(string memory reason) {
        info = strConcat("external call [liquidateForErc20] failed: [", reason,"]");
        emit ErrorLogging(info);      
    }
  }

  function transferNativeToken(address payable receiver, uint amount) internal {
    receiver.transfer(amount);
  }

  function transferErc20cToken(address user, address erc20, uint amount) internal {
    IERC20 token = IERC20(erc20);
    token.transfer(user, amount);
  }

  function liquidateForNativeToken(  
                                    address _borrower, 
                                    address _cTokenCollateral,
                                    bool    isRedeem) 
                                    external payable {   
    string memory info;
    uint256 beforeBalance = address(this).balance;
    try liquidatev2Contract.liquidateForNativeToken{value:msg.value}( _borrower,                                        
                                                                      _cTokenCollateral,
                                                                      isRedeem) returns (uint256 diff) {
        uint256 roseDiff = address(this).balance - beforeBalance;
         if(diff > 0){
           if(isRedeem){
              if(_cTokenCollateral == cEthAddr && roseDiff > 0){
                transferNativeToken(payable(msg.sender), roseDiff);  
              }else{
                IERC20 token = IERC20(CToken(_cTokenCollateral).underlying()); 
                transferErc20cToken(msg.sender, CToken(_cTokenCollateral).underlying(), token.balanceOf(address(this)));
              }
          }else{
            transferErc20cToken(msg.sender, _cTokenCollateral, diff);
          }
        }
        info = strConcat("Success liquidateForNativeToken return ftoken:[",CToken(_cTokenCollateral).symbol(),"] Amt: [", uint2str(diff),"]"); 
        emit Logging(info);
    } catch Error(string memory reason) {
        info = strConcat("external call [liquidateForNativeToken] failed: [", reason,"]");
        emit ErrorLogging(info);
    }    
  }

function uint2str(uint256 _i) public pure returns (string memory str)
{
  if (_i == 0)
  {
    return "0";
  }
  uint256 j = _i;
  uint256 length;
  while (j != 0)
  {
    length++;
    j /= 10;
  }
  bytes memory bstr = new bytes(length);
  uint256 k = length;
  j = _i;
  while (j != 0)
  {
    bstr[--k] = bytes1(uint8(48 + j % 10));
    j /= 10;
  }
  str = string(bstr);
}

function strConcat(
    string memory _a, 
    string memory _b, 
    string memory _c, 
    string memory _d, 
    string memory _e) public pure returns (string memory){
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    uint i = 0;
    for (i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
}

function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) public pure returns (string memory) {
    return strConcat(_a, _b, _c, _d, "");
}

function strConcat(string memory _a, string memory _b, string memory _c) public pure returns (string memory) {
    return strConcat(_a, _b, _c, "", "");
}

function strConcat(string memory _a, string memory _b) public pure returns (string memory) {
    return strConcat(_a, _b, "", "", "");
}

 function withdraw(address[] memory tokens) external onlyOwner {
		for(uint i = 0;i<tokens.length;i++){
			address token = tokens[i];
			if(token == address(1)){
				payable(_owner).transfer(address(this).balance);
			}else{
				IERC20 erc20 = IERC20(token);
				erc20.transfer(_owner, erc20.balanceOf(address(this)));
			}
		}
	}

  receive() external payable {}
  fallback() external payable {}

}