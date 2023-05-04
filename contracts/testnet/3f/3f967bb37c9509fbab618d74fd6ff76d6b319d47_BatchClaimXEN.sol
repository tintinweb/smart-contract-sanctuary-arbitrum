/**
 *Submitted for verification at Arbiscan on 2023-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
//批量minit合约



interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}
contract BatchClaimXEN {
    string public constant PROXY_FUNCTION = "callXEN(bytes)";
    string public constant XEN_MINT_FUNCTION = "claimRank(uint256)";
    string public constant XEN_CLAIM_FUNCTION ="claimMintRewardAndShare(address,uint256)";
    uint256 public constant SHARE_PCT = 100;
    address public owner;
	// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
	bytes miniProxy;			  // = 0x363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3;
    address private immutable original;
	
	//address private constant XEN = 0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8;
    // xen合约地址
	//address public constant XEN = 0xca41f293A32d25c2216bC4B30f5b0Ab61b6ed2CB;
   address public constant XEN = 0xac8b0a55ee3055C2E88523b0F8e3f65113649cB2;
    //用户与索引与合约对应关系，通过索引找合约
	mapping (address=>mapping (uint256=>address)) public userIndexContract;
  
    //所有mint的总数
    uint256 public mintCount;

    //用户名下的mint的总数
    mapping (address=>uint256) public userMintCount;

    //用户名下的mint的所有索引inxdex
    mapping (address=>uint256[]) public userToIndexArray;
    //每个用户下索引是否在mint true在mint
    mapping (address=>mapping(uint256=>bool)) public UserToIndexBool;

    //每次查询最大返回数量
    uint256 public getMaxCount=200;

	constructor() {
		miniProxy = bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(this)), bytes15(0x5af43d82803e903d91602b57fd5bf3));
        original = address(this);		
        owner = tx.origin;
	}

//批量mint,times数量，term天数
	function batchClaimRank(uint256 times, uint256 term) external {
        bytes memory bytecode = miniProxy;
		address proxy;		
  
		for(uint256 i=0; i<times; i++) {
            mintCount=mintCount+1;
	        bytes32 salt = keccak256(abi.encodePacked(msg.sender, mintCount));
             bytes memory data = abi.encodeWithSignature(
                            PROXY_FUNCTION,
                            abi.encodeWithSignature(XEN_MINT_FUNCTION, term)
                            );
			assembly {
	            proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)

                let success := call(
                    gas(),
                    proxy,
                    0,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
			}
		//BatchClaimXEN(proxy).claimRank(term);           

            userIndexContract[msg.sender][mintCount]=proxy;

            userMintCount[msg.sender]=userMintCount[msg.sender]+1;

            userToIndexArray[msg.sender].push(mintCount);
            UserToIndexBool[msg.sender][mintCount]=true;

		}

	}



//根据索引批量提取 
	function batchClaimReward(uint256[]memory indexArray) external {
    	for(uint i=0; i<indexArray.length; i++) {
            if(userIndexContract[msg.sender][indexArray[i]]!=address(0)){   
                address proxy=userIndexContract[msg.sender][indexArray[i]];
                 bytes memory proxy_data = abi.encodeWithSignature(
                    PROXY_FUNCTION,
                    abi.encodeWithSignature(XEN_CLAIM_FUNCTION, msg.sender, SHARE_PCT)
                );
                assembly {
                    let success := call(
                        gas(),
                        proxy,
                        0,
                        add(proxy_data, 0x20),
                        mload(proxy_data),
                        0,
                        0
                    )
                }
               // BatchClaimXEN(userIndexContract[msg.sender][indexArray[i]]).claimMintRewardTo(msg.sender);
                UserToIndexBool[msg.sender][indexArray[i]]=false;                
            } 
		}
    }

    //批量提取加复投indexArray用户的索引数组，天数term
    function batchClaimRewardOrMint(uint256[]memory indexArray,uint256 term) external {
         	
    	for(uint i=0; i<indexArray.length; i++) {
            if(userIndexContract[msg.sender][indexArray[i]]!=address(0)){  
                 address proxy=userIndexContract[msg.sender][indexArray[i]];
                 bytes memory data = abi.encodeWithSignature(
                            PROXY_FUNCTION,
                            abi.encodeWithSignature(XEN_MINT_FUNCTION, term)
                            );
                 bytes memory proxy_data = abi.encodeWithSignature(
                            PROXY_FUNCTION,
                            abi.encodeWithSignature(XEN_CLAIM_FUNCTION, msg.sender, SHARE_PCT)
                            );
                assembly {
                    let success := call(
                        gas(),
                        proxy,
                        0,
                        add(proxy_data, 0x20),
                        mload(proxy_data),
                        0,
                        0
                    )
              
                    let success2 := call(
                        gas(),
                        proxy,
                        0,
                        add(data, 0x20),
                        mload(data),
                        0,
                        0
                    )
                } 
            } 
		}
    }


  //通过用户数组下标返回用户批量mint的合约索引和最大下标
    function getUserIndex(address mintAddress,uint256 index) external  view returns (uint256 [] memory userIndexArray,uint256 userIndex) {
        userIndexArray=new uint256[](getMaxCount);
        uint256 i=index;
        uint256 j=0;
        for(;i<userMintCount[mintAddress];i++) {
            if(UserToIndexBool[mintAddress][userToIndexArray[mintAddress][i]]==true){
                userIndexArray[j]=userToIndexArray[mintAddress][i]; 
                j++;               
            }
            if(j==getMaxCount){
                break;
            }
        }
        userIndex=i;
        return (userIndexArray,userIndex);
    }






//通过用户数组下标返回用户批量mint的合约地址数组，和最大下标
    function getUserIndexAddress(address mintAddress,uint256 index) external  view returns (address [] memory userIndexArray,uint256 userIndex) {
        userIndexArray=new address[](getMaxCount);
        uint256 i=index;
        uint256 j=0;
        for(;i<userMintCount[mintAddress];i++) {
            if(UserToIndexBool[mintAddress][userToIndexArray[mintAddress][i]]==true){
                userIndexArray[j]=userIndexContract[mintAddress][userToIndexArray[mintAddress][i]]; 
                j++;               
            }
            if(j==getMaxCount){
                break;
            }
        }
        userIndex=i;
        return (userIndexArray,userIndex);
    }

//通过用户的合约索引数组获得地址列表
   function getIndexOfAddress(address mintAddress,uint256[] memory index) external  view returns (address [] memory userIndexArray) {
        userIndexArray=new address[](getMaxCount);       
        uint256 j=0;
        for( uint256 i=0;i<index.length;i++) {
            if(userIndexContract[mintAddress][index[i]] != address(0)){
                userIndexArray[j]=userIndexContract[mintAddress][index[i]]; 
                j++;               
            }
            if(j==getMaxCount){
                break;
            }
        }
       
        return userIndexArray;
    }
    
struct BatchInfo {
        uint256 i;//下标
        uint256 index;//合约索引
        address constructorAddress; //合约地址     
    }
//返回用户批量mint的合约对象数组
    function getBatchInfo(address mintAddress,uint256 index) external  view returns (BatchInfo [] memory batchInfos) {
        batchInfos=new BatchInfo[](getMaxCount);        
        uint256 j=0;
        for(uint256 i=index;i<userMintCount[mintAddress];i++) {
            if(UserToIndexBool[mintAddress][userToIndexArray[mintAddress][i]]==true){
                batchInfos[j]=BatchInfo(i,userToIndexArray[mintAddress][i],userIndexContract[mintAddress][userToIndexArray[mintAddress][i]]); 
                j++;               

            }
            if(j==getMaxCount){
                break;
            }
        }
      
        return batchInfos;
    }


    function callXEN(bytes memory data) external {
        require(msg.sender == original, "invalid caller");
       // address xenAddress = XEN;
        assembly {
            let succeeded := call(
                gas(),
                XEN,
                0,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
    }

      function claimTokens(address _token) external  {
        require(owner == msg.sender);
        if (_token == address(0x0)) {
           payable (owner).transfer(address(this).balance);
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner, balance);
    }

}