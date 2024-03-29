/**
 *Submitted for verification at Arbiscan on 2023-05-18
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Generated by : https://www.cues.sg
 * Cues.sg : We make technology accessible.
 * Contract Type : Staking
*/
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
	/**
	 * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
	 * by `operator` from `from`, this function is called.
	 *
	 * It must return its Solidity selector to confirm the token transfer.
	 * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
	 *
	 * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
	 */
	function onERC721Received(
		address operator,
		address from,
		uint256 tokenId,
		bytes calldata data
	) external returns (bytes4);
}

interface ERC20{
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ERC721{
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract Staking {

	address owner;
	struct record { address staker; uint256 stakeBlock; uint256 lastUpdateBlock; uint256 accumulatedInterestToUpdateBlock; uint256 amtWithdrawn; }
	mapping(uint256 => record) public informationAboutStakeScheme;
	mapping(uint256 => uint256) public tokenStore;
	uint256 public numberOfTokensCurrentlyStaked = uint256(0);
	uint256 public perBlockInterestRate = uint256(100);
	uint256 public totalWithdrawals = uint256(0);
	event Staked (uint256 indexed tokenId);
	event Unstaked (uint256 indexed tokenId);

	constructor() {
		owner = msg.sender;
	}

	//This function allows the owner to specify an address that will take over ownership rights instead. Please double check the address provided as once the function is executed, only the new owner will be able to change the address back.
	function changeOwner(address _newOwner) public onlyOwner {
		owner = _newOwner;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}	

	function onERC721Received( address, address, uint256, bytes calldata ) public pure returns (bytes4) {
		return this.onERC721Received.selector;
	}

/**
 * Function stake
 * Per Block Interest Rate : Variable perBlockInterestRate
 * Address Map : informationAboutStakeScheme
 * The function takes in 1 variable, (zero or a positive integer) _tokenId. It can be called by functions both inside and outside of this contract. It does the following :
 * updates informationAboutStakeScheme (Element _tokenId) as Struct comprising (the address that called this function), current time, current time, 0, 0
 * calls ERC721(Address 0x6090f340C99e46d8C22c3228849Fe2358983aA31)'s at safeTransferFrom function  with variable sender as (the address that called this function), variable recipient as (the address of this contract), variable amount as _tokenId
 * emits event Staked with inputs _tokenId
 * updates tokenStore (Element numberOfTokensCurrentlyStaked) as _tokenId
 * updates numberOfTokensCurrentlyStaked as (numberOfTokensCurrentlyStaked) + (1)
*/
	function stake(uint256 _tokenId) public {
		informationAboutStakeScheme[_tokenId]  = record (msg.sender, block.number, block.number, uint256(0), uint256(0));
		ERC721(address(0x6090f340C99e46d8C22c3228849Fe2358983aA31)).safeTransferFrom(msg.sender, address(this), _tokenId);
		emit Staked(_tokenId);
		tokenStore[numberOfTokensCurrentlyStaked]  = _tokenId;
		numberOfTokensCurrentlyStaked  = (numberOfTokensCurrentlyStaked + uint256(1));
	}

/**
 * Function unstake
 * The function takes in 1 variable, (zero or a positive integer) _tokenId. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value informationAboutStakeScheme with element _tokenId
 * creates an internal variable interestToRemove with initial value (thisRecord with element accumulatedInterestToUpdateBlock) + (((current time) - (thisRecord with element lastUpdateBlock)) * (perBlockInterestRate) * (100000000000000))
 * checks that (ERC20(Address 0x236A2f42a0A7Ed5A2f3d0bA08A1CbeE0C803D8Ba)'s at balanceOf function  with variable recipient as (the address of this contract)) is greater than or equals to interestToRemove
 * if interestToRemove is strictly greater than 0 then (calls ERC20(Address 0x236A2f42a0A7Ed5A2f3d0bA08A1CbeE0C803D8Ba)'s at transfer function  with variable recipient as (the address that called this function), variable amount as interestToRemove)
 * updates totalWithdrawals as (totalWithdrawals) + (interestToRemove)
 * checks that (thisRecord with element staker) is equals to (the address that called this function)
 * deletes item _tokenId from mapping informationAboutStakeScheme
 * calls ERC721(Address 0x6090f340C99e46d8C22c3228849Fe2358983aA31)'s at safeTransferFrom function  with variable sender as (the address of this contract), variable recipient as (the address that called this function), variable amount as _tokenId
 * emits event Unstaked with inputs _tokenId
 * repeat numberOfTokensCurrentlyStaked times with loop variable i0 :  (if (tokenStore with element Loop Variable i0) is equals to _tokenId then (updates tokenStore (Element Loop Variable i0) as tokenStore with element (numberOfTokensCurrentlyStaked) - (1); then updates numberOfTokensCurrentlyStaked as (numberOfTokensCurrentlyStaked) - (1); and then terminates the for-next loop))
*/
	function unstake(uint256 _tokenId) public {
		record memory thisRecord = informationAboutStakeScheme[_tokenId];
		uint256 interestToRemove = (thisRecord.accumulatedInterestToUpdateBlock + ((block.number - thisRecord.lastUpdateBlock) * perBlockInterestRate * uint256(100000000000000)));
		require((ERC20(address(0x236A2f42a0A7Ed5A2f3d0bA08A1CbeE0C803D8Ba)).balanceOf(address(this)) >= interestToRemove), "Insufficient amount of the token in this contract to transfer out. Please contact the contract owner to top up the token.");
		if ((interestToRemove > uint256(0))){
			ERC20(address(0x236A2f42a0A7Ed5A2f3d0bA08A1CbeE0C803D8Ba)).transfer(msg.sender, interestToRemove);
		}
		totalWithdrawals  = (totalWithdrawals + interestToRemove);
		require((thisRecord.staker == msg.sender), "You do not own this token");
		delete informationAboutStakeScheme[_tokenId];
		ERC721(address(0x6090f340C99e46d8C22c3228849Fe2358983aA31)).safeTransferFrom(address(this), msg.sender, _tokenId);
		emit Unstaked(_tokenId);
		for (uint i0 = 0; i0 < numberOfTokensCurrentlyStaked; i0++){
			if ((tokenStore[i0] == _tokenId)){
				tokenStore[i0]  = tokenStore[(numberOfTokensCurrentlyStaked - uint256(1))];
				numberOfTokensCurrentlyStaked  = (numberOfTokensCurrentlyStaked - uint256(1));
				break;
			}
		}
	}

/**
 * Function multipleStake
 * The function takes in 1 variable, (a list of zeros or positive integers) tokenIds. It can be called by functions both inside and outside of this contract. It does the following :
 * repeat length of tokenIds times with loop variable i0 :  (calls stake with variable _tokenId as (tokenIds with element Loop Variable i0))
*/
	function multipleStake(uint256[] memory tokenIds) public {
		for (uint i0 = 0; i0 < (tokenIds).length; i0++){
			stake(tokenIds[i0]);
		}
	}

/**
 * Function multipleUnstake
 * The function takes in 1 variable, (a list of zeros or positive integers) tokenIds. It can be called by functions both inside and outside of this contract. It does the following :
 * repeat length of tokenIds times with loop variable i0 :  (calls unstake with variable _tokenId as (tokenIds with element Loop Variable i0))
*/
	function multipleUnstake(uint256[] memory tokenIds) public {
		for (uint i0 = 0; i0 < (tokenIds).length; i0++){
			unstake(tokenIds[i0]);
		}
	}

/**
 * Function unstakeAllThatIOwn
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * repeat numberOfTokensCurrentlyStaked times with loop variable i0 :  (creates an internal variable _tokenID with initial value tokenStore with element Loop Variable i0; and then if (informationAboutStakeScheme with element _tokenID with element staker) is equals to (the address that called this function) then (calls unstake with variable _tokenId as _tokenID))
*/
	function unstakeAllThatIOwn() public {
		for (uint i0 = numberOfTokensCurrentlyStaked - 1; i0 >= 0; i0--){
			uint256 _tokenID = tokenStore[i0];
			if ((informationAboutStakeScheme[_tokenID].staker == msg.sender)){
				unstake(_tokenID);
			}
		}
	}

/**
 * Function multipleWithdrawInterest
 * The function takes in 1 variable, (a list of zeros or positive integers) tokenIds. It can be called by functions both inside and outside of this contract. It does the following :
 * repeat length of tokenIds times with loop variable i0 :  (calls withdrawInterestWithoutUnstaking with variable _withdrawalAmt as (interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn with variable _tokenId as (tokenIds with element Loop Variable i0)), variable _tokenId as (tokenIds with element Loop Variable i0))
*/
	function multipleWithdrawInterest(uint256[] memory tokenIds) public {
		for (uint i0 = 0; i0 < (tokenIds).length; i0++){
			withdrawInterestWithoutUnstaking(interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(tokenIds[i0]), tokenIds[i0]);
		}
	}

/**
 * Function withdrawAllInterestWithoutUnstaking
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * repeat numberOfTokensCurrentlyStaked times with loop variable i0 :  (creates an internal variable _tokenID with initial value tokenStore with element Loop Variable i0; and then if (informationAboutStakeScheme with element _tokenID with element staker) is equals to (the address that called this function) then (calls withdrawInterestWithoutUnstaking with variable _withdrawalAmt as (interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn with variable _tokenId as _tokenID), variable _tokenId as _tokenID))
*/
	function withdrawAllInterestWithoutUnstaking() public {
		for (uint i0 = 0; i0 < numberOfTokensCurrentlyStaked; i0++){
			uint256 _tokenID = tokenStore[i0];
			if ((informationAboutStakeScheme[_tokenID].staker == msg.sender)){
				withdrawInterestWithoutUnstaking(interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(_tokenID), _tokenID);
			}
		}
	}

/**
 * Function updateRecordsWithLatestInterestRates
 * The function takes in 0 variables. It can only be called by other functions in this contract. It does the following :
 * repeat numberOfTokensCurrentlyStaked times with loop variable i0 :  (creates an internal variable thisRecord with initial value informationAboutStakeScheme with element tokenStore with element Loop Variable i0; and then updates informationAboutStakeScheme (Element tokenStore with element Loop Variable i0) as Struct comprising (thisRecord with element staker), (thisRecord with element stakeBlock), current time, ((thisRecord with element lastUpdateBlock) + (((current time) - (thisRecord with element lastUpdateBlock)) * (perBlockInterestRate) * (100000000000000))), (thisRecord with element amtWithdrawn))
*/
	function updateRecordsWithLatestInterestRates() internal {
		for (uint i0 = 0; i0 < numberOfTokensCurrentlyStaked; i0++){
			record memory thisRecord = informationAboutStakeScheme[tokenStore[i0]];
			informationAboutStakeScheme[tokenStore[i0]]  = record (thisRecord.staker, thisRecord.stakeBlock, block.number, (thisRecord.lastUpdateBlock + ((block.number - thisRecord.lastUpdateBlock) * perBlockInterestRate * uint256(100000000000000))), thisRecord.amtWithdrawn);
		}
	}

/**
 * Function numberOfStakedTokenIDsOfAnAddress
 * The function takes in 1 variable, (an address) _address. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable _counter with initial value 0
 * repeat numberOfTokensCurrentlyStaked times with loop variable i0 :  (creates an internal variable _tokenID with initial value tokenStore with element Loop Variable i0; and then if (informationAboutStakeScheme with element _tokenID with element staker) is equals to _address then (updates _counter as (_counter) + (1)))
 * returns _counter as output
*/
	function numberOfStakedTokenIDsOfAnAddress(address _address) public view returns (uint256) {
		uint256 _counter = uint256(0);
		for (uint i0 = 0; i0 < numberOfTokensCurrentlyStaked; i0++){
			uint256 _tokenID = tokenStore[i0];
			if ((informationAboutStakeScheme[_tokenID].staker == _address)){
				_counter  = (_counter + uint256(1));
			}
		}
		return _counter;
	}

/**
 * Function stakedTokenIDsOfAnAddress
 * The function takes in 1 variable, (an address) _address. It can only be called by other functions in this contract. It does the following :
 * creates an internal variable tokenIDs
 * creates an internal variable _counter with initial value 0
 * repeat numberOfTokensCurrentlyStaked times with loop variable i0 :  (creates an internal variable _tokenID with initial value tokenStore with element Loop Variable i0; and then if (informationAboutStakeScheme with element _tokenID with element staker) is equals to _address then (updates tokenIDs (Element _counter) as _tokenID; and then updates _counter as (_counter) + (1)))
 * returns tokenIDs as output
*/
	function stakedTokenIDsOfAnAddress(address _address) internal view returns (uint256[] memory) {
		uint256[] memory tokenIDs;
		uint256 _counter = uint256(0);
		for (uint i0 = 0; i0 < numberOfTokensCurrentlyStaked; i0++){
			uint256 _tokenID = tokenStore[i0];
			if ((informationAboutStakeScheme[_tokenID].staker == _address)){
				tokenIDs[_counter]  = _tokenID;
				_counter  = (_counter + uint256(1));
			}
		}
		return tokenIDs;
	}

/**
 * Function whichStakedTokenIDsOfAnAddress
 * The function takes in 2 variables, (an address) _address, and (zero or a positive integer) _counterIn. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable _counter with initial value 0
 * repeat numberOfTokensCurrentlyStaked times with loop variable i0 :  (creates an internal variable _tokenID with initial value tokenStore with element Loop Variable i0; and then if (informationAboutStakeScheme with element _tokenID with element staker) is equals to _address then (if _counterIn is equals to _counter then (returns _tokenID as output); and then updates _counter as (_counter) + (1)))
 * returns 9999999 as output
*/
	function whichStakedTokenIDsOfAnAddress(address _address, uint256 _counterIn) public view returns (uint256) {
		uint256 _counter = uint256(0);
		for (uint i0 = 0; i0 < numberOfTokensCurrentlyStaked; i0++){
			uint256 _tokenID = tokenStore[i0];
			if ((informationAboutStakeScheme[_tokenID].staker == _address)){
				if ((_counterIn == _counter)){
					return _tokenID;
				}
				_counter  = (_counter + uint256(1));
			}
		}
		return uint256(9999999);
	}

/**
 * Function interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn
 * The function takes in 1 variable, (zero or a positive integer) _tokenId. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value informationAboutStakeScheme with element _tokenId
 * returns (thisRecord with element accumulatedInterestToUpdateBlock) + (((current time) - (thisRecord with element lastUpdateBlock)) * (perBlockInterestRate) * (100000000000000)) as output
*/
	function interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(uint256 _tokenId) public view returns (uint256) {
		record memory thisRecord = informationAboutStakeScheme[_tokenId];
		return (thisRecord.accumulatedInterestToUpdateBlock + ((block.number - thisRecord.lastUpdateBlock) * perBlockInterestRate * uint256(100000000000000)));
	}

/**
 * Function withdrawInterestWithoutUnstaking
 * The function takes in 2 variables, (zero or a positive integer) _withdrawalAmt, and (zero or a positive integer) _tokenId. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable totalInterestEarnedTillNow with initial value interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn with variable _tokenId as _tokenId
 * checks that _withdrawalAmt is less than or equals to totalInterestEarnedTillNow
 * creates an internal variable thisRecord with initial value informationAboutStakeScheme with element _tokenId
 * checks that (thisRecord with element staker) is equals to (the address that called this function)
 * updates informationAboutStakeScheme (Element _tokenId) as Struct comprising (thisRecord with element staker), (thisRecord with element stakeBlock), current time, ((totalInterestEarnedTillNow) - (_withdrawalAmt)), ((thisRecord with element amtWithdrawn) + (_withdrawalAmt))
 * checks that (ERC20(Address 0x236A2f42a0A7Ed5A2f3d0bA08A1CbeE0C803D8Ba)'s at balanceOf function  with variable recipient as (the address of this contract)) is greater than or equals to _withdrawalAmt
 * if _withdrawalAmt is strictly greater than 0 then (calls ERC20(Address 0x236A2f42a0A7Ed5A2f3d0bA08A1CbeE0C803D8Ba)'s at transfer function  with variable recipient as (the address that called this function), variable amount as _withdrawalAmt)
 * updates totalWithdrawals as (totalWithdrawals) + (_withdrawalAmt)
*/
	function withdrawInterestWithoutUnstaking(uint256 _withdrawalAmt, uint256 _tokenId) public {
		uint256 totalInterestEarnedTillNow = interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(_tokenId);
		require((_withdrawalAmt <= totalInterestEarnedTillNow), "Withdrawn amount must be less than withdrawable amount");
		record memory thisRecord = informationAboutStakeScheme[_tokenId];
		require((thisRecord.staker == msg.sender), "You do not own this token");
		informationAboutStakeScheme[_tokenId]  = record (thisRecord.staker, thisRecord.stakeBlock, block.number, (totalInterestEarnedTillNow - _withdrawalAmt), (thisRecord.amtWithdrawn + _withdrawalAmt));
		require((ERC20(address(0x236A2f42a0A7Ed5A2f3d0bA08A1CbeE0C803D8Ba)).balanceOf(address(this)) >= _withdrawalAmt), "Insufficient amount of the token in this contract to transfer out. Please contact the contract owner to top up the token.");
		if ((_withdrawalAmt > uint256(0))){
			ERC20(address(0x236A2f42a0A7Ed5A2f3d0bA08A1CbeE0C803D8Ba)).transfer(msg.sender, _withdrawalAmt);
		}
		totalWithdrawals  = (totalWithdrawals + _withdrawalAmt);
	}

/**
 * Function withdrawAllInterestFromATokenWithoutUnstaking
 * The function takes in 1 variable, (zero or a positive integer) _tokenId. It can only be called by functions outside of this contract. It does the following :
 * calls withdrawInterestWithoutUnstaking with variable _withdrawalAmt as (interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn with variable _tokenId as _tokenId), variable _tokenId as _tokenId
*/
	function withdrawAllInterestFromATokenWithoutUnstaking(uint256 _tokenId) external {
		withdrawInterestWithoutUnstaking(interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(_tokenId), _tokenId);
	}

/**
 * Function totalAccumulatedInterest
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable total with initial value 0
 * repeat numberOfTokensCurrentlyStaked times with loop variable i0 :  (updates total as (total) + (interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn with variable _tokenId as (Loop Variable i0)))
 * returns total as output
*/
	function totalAccumulatedInterest() public view returns (uint256) {
		uint256 total = uint256(0);
		for (uint i0 = 0; i0 < numberOfTokensCurrentlyStaked; i0++){
			total  = (total + interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(i0));
		}
		return total;
	}

/**
 * Function modifyPerBlockInterestRate
 * Notes for _perBlockInterestRate : 10000 is one coin
 * The function takes in 1 variable, (zero or a positive integer) _perBlockInterestRate. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls updateRecordsWithLatestInterestRates
 * updates perBlockInterestRate as _perBlockInterestRate
*/
	function modifyPerBlockInterestRate(uint256 _perBlockInterestRate) public onlyOwner {
		updateRecordsWithLatestInterestRates();
		perBlockInterestRate  = _perBlockInterestRate;
	}

/**
 * Function withdrawToken
 * The function takes in 1 variable, (zero or a positive integer) _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * checks that (ERC20(Address 0x236A2f42a0A7Ed5A2f3d0bA08A1CbeE0C803D8Ba)'s at balanceOf function  with variable recipient as (the address of this contract)) is greater than or equals to ((_amt) + (totalAccumulatedInterest))
 * if _amt is strictly greater than 0 then (calls ERC20(Address 0x236A2f42a0A7Ed5A2f3d0bA08A1CbeE0C803D8Ba)'s at transfer function  with variable recipient as (the address that called this function), variable amount as _amt)
*/
	function withdrawToken(uint256 _amt) public onlyOwner {
		require((ERC20(address(0x236A2f42a0A7Ed5A2f3d0bA08A1CbeE0C803D8Ba)).balanceOf(address(this)) >= (_amt + totalAccumulatedInterest())), "Insufficient amount of the token in this contract to transfer out. Please contact the contract owner to top up the token.");
		if ((_amt > uint256(0))){
			ERC20(address(0x236A2f42a0A7Ed5A2f3d0bA08A1CbeE0C803D8Ba)).transfer(msg.sender, _amt);
		}
	}
}