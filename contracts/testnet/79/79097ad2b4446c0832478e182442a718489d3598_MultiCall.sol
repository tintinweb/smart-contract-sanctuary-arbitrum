/**
 *Submitted for verification at Arbiscan on 2023-06-02
*/

/**
 *Submitted for verification at Arbiscan on 2023-04-01
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    // function transfer(address recipient, uint256 amount) external returns (bool);
    // function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }
}



contract MultiCall  {
    using SafeMath for uint256;
    IERC20 public ETH;
    struct tokenItem {
        address contractAddress;
        string name;
        string symbol;
        uint256 decimals;
        uint256 balance;
        uint256 balanceNew;
    }
    
    constructor (IERC20 _ETH) public {
        ETH = _ETH;
    }
    
    function getBalance(address _address) public view returns (tokenItem memory TokenInfo) {
        uint256 balance = _address.balance;
        TokenInfo = getTokenInfo(address(ETH),_address);
        uint256 balanceNew = balance.mul(10**18).div(10**TokenInfo.decimals);
        TokenInfo.balance = balance;
        TokenInfo.balanceNew = balanceNew;
    }
    
    function getTokenInfo(address _token,address _address) public view returns (tokenItem memory TokenInfo) {
        if (_token != address(0)) {
        TokenInfo.contractAddress = _token;
        TokenInfo.name = IERC20(_token).name();
        TokenInfo.symbol = IERC20(_token).symbol();
        TokenInfo.decimals = IERC20(_token).decimals();
        TokenInfo.balance = IERC20(_token).balanceOf(_address);
        TokenInfo.balanceNew = TokenInfo.balance.mul(10**18).div(10**TokenInfo.decimals);
        } else {
            TokenInfo = getBalance(_address);
        }
    }
    
    
    function massGetTokenInfo(address[] memory _tokenList,address _address) public view returns (tokenItem[] memory TokenInfoList) {
        uint256 num = _tokenList.length;
        TokenInfoList = new tokenItem[](num);
        for (uint256 i=0;i<num;i++) {
            address _token = _tokenList[i];
            TokenInfoList[i] = getTokenInfo(_token,_address);
        }
    }
    
    struct NftInfoItem {
        address contractAddress;
        uint256 tokenId;
        string name;
        string symbol;
        address owner;
        string tokenURI;
    }
    
    struct tokenIdItem {
        uint256 tokenID;
        string tokenURI;
    }
    
    struct NftInfoItem2 {
        address contractAddress;
        string name;
        string symbol;
        uint256 balance;
        tokenIdItem[] tokenIdList;
    }
    
    function getNftInfoByTokenId(address _nftAddress,uint256 _tokenId) public view returns (NftInfoItem memory NftInfo) {
        NftInfo.contractAddress = _nftAddress;
        NftInfo.tokenId = _tokenId;
        NftInfo.name = IERC721(_nftAddress).name();
        NftInfo.symbol = IERC721(_nftAddress).symbol();
        NftInfo.owner = IERC721(_nftAddress).ownerOf(_tokenId);
        NftInfo.tokenURI = IERC721(_nftAddress).tokenURI(_tokenId);
    }
    
     function getNftInfo(address _nftAddress,address _address) public view returns (NftInfoItem2 memory NftInfo) {
        NftInfo.contractAddress = _nftAddress;
        NftInfo.name = IERC721(_nftAddress).name();
        NftInfo.symbol = IERC721(_nftAddress).symbol();
        NftInfo.balance = IERC721(_nftAddress).balanceOf(_address);
        if (NftInfo.balance == 0) {
            NftInfo.tokenIdList = new  tokenIdItem[](0);
        } else {
             NftInfo.tokenIdList = new tokenIdItem[](NftInfo.balance);
             for (uint256 i=0;i<NftInfo.balance;i++) {
                 uint256 tokenID = IERC721(_nftAddress).tokenOfOwnerByIndex(_address,i);
                 NftInfo.tokenIdList[i] = tokenIdItem(tokenID,IERC721(_nftAddress).tokenURI(tokenID));
             }
        }
    }
    
    
    function MassGetNftInfo(address[] memory _nftAddressList,address _address) public view returns (NftInfoItem2[] memory NftInfoList) {
        uint256 num = _nftAddressList.length;
         NftInfoList = new NftInfoItem2[](num);
         for (uint256 i=0;i<num;i++) {
             NftInfoList[i] = getNftInfo(_nftAddressList[i],_address);
         }
    }
}