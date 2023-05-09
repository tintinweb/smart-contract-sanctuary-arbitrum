// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibraryStorage as ls} from "../libraries/LibraryStorage.sol";
import {LibDiamond as ds} from "../libraries/LibDiamond.sol";
import "../IFaucet1.sol";
import  "../interface/IV2Contract.sol";
import "../IGemChest.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "hardhat/console.sol";


contract Faucet2 {
    
    IGemChest public gemChest;
    IV2Contract public iv2Contract;

    uint public getAmountOutMinState;

    event Deposit(string uuid, uint tokenId, uint _amountforDeposit,int price, string str);
    event Log(bool message);

    /** @dev Modifier to ensure that the caller has a specific role before executing a function.
     * The `role` parameter is a bytes32 hash that represents the role that the caller must have.   
     */
    modifier onlyRole(bytes32 role) {
        ds._checkRole(role);
        _;
    }

    /**
     * @dev Modifier to ensure that the contract is active
     */
    modifier isActive {
        require(ls.libStorage().isActive == true, "v2 isn't actived");
        _;
    }

    /**
     * @dev Returns information about a token.
     * @param _tokenAddress The address of the token to get information for.
     * @return The token's address, minimum amount, balance ,pricefeed address, number of decimals, and status.
     */
    function getToken(address _tokenAddress) external view returns(address, uint256, uint, address , uint, ls.Status){        
        return ls.getToken(_tokenAddress);
    }   

    /**
     * @dev Returns information about a locked asset.
     * @param assetid The ID of the locked asset to get information for.
     * @return The asset's locked tolen address, owner, beneficiary, creator, amount, fee rate, end date, claimed token amount ,lock price nn USD, target rate, features and status.
     */
    function getLockedAsset(uint256 assetid) external view returns (address, address, address ,uint256, uint256, uint256,uint256,int,uint, bool[] memory, ls.Status){
        return ls.getLockedAsset(assetid);    
    }

    /** 
     * @dev Adds a new token to the contract with the specified parameters.
     * Only the ADMIN role can call this function.
     * The token's status is set to OPEN by default.
     *
     * @param _address Address of the token contract to be added
     * @param _minAmount The minimum amount of the token that can be deposited
     * @param _priceFeedAddress Price feed address of token pair
     * @param _decimal The number of decimal places used by the token. 
     */
    function addToken(address _address, uint256 _minAmount, address _priceFeedAddress, uint8 _decimal) external onlyRole(ds.ADMIN) {
        ls.LibStorage storage lib = ls.libStorage();
        lib._tokenVsIndex[_address] = ls.Token({tokenAddress : _address, minAmount : _minAmount,
        priceFeedAddress : _priceFeedAddress, balance : 0, decimal : _decimal, status : ls.Status.OPEN});
    }

    function addTokenn(address[] memory _address, address[] memory _priceFeedAddress , uint256[] memory _minAmount, uint8[] memory _decimal) external onlyRole(ds.ADMIN) {
        ls.LibStorage storage lib = ls.libStorage();
        for(uint i=0; i < _address.length; i++){
            lib._tokenVsIndex[_address[i]] = ls.Token({tokenAddress : _address[i], minAmount : _minAmount[i],
            priceFeedAddress : _priceFeedAddress[i], balance : 0, decimal : _decimal[i], status : ls.Status.OPEN});
        }
    }

    /** @dev Adds a new token to the contract with the specified parameters.
     * Only the ADMIN role can call this function.
     * The token's status is set to OPEN by default.
     *
     * @param _token The address of the token contract to be added.
     * @param _priceFeedAddress Price feed address of token pair.
     * @param _minAmount The minimum amount of the token that can be deposited.
     * @param _isActive the boolean for token status
     * @param _decimal The number of decimal places used by the token.
     */
    function setToken(address _token, address _priceFeedAddress, uint _minAmount, bool _isActive, uint8 _decimal) external onlyRole(ds.ADMIN) {  
        ls.LibStorage storage lib = ls.libStorage();  
        ls.Token storage token = lib._tokenVsIndex[_token];
        token.priceFeedAddress = _priceFeedAddress;
        token.minAmount = _minAmount;
        token.decimal = _decimal; 
        token.status = _isActive  ? ls.Status.OPEN : ls.Status.CLOSE;
    }

    /**
     * @dev Sets the fee parameters for the contract.
     * Only the ADMIN role can call this function.
     * 
     * @param _startFee The starting fee for the contract.
     * @param _endFee The ending fee for the contract.
     * @param _affiliateRate The affiliate rate for the contract.
     * @param _arr array representing the fixed fees for the contract.
     */
    function setFee(uint8 _startFee, uint8 _endFee, uint8 _affiliateRate, uint8 _slippage, uint8 _rewardRate, uint[][] memory _arr) external onlyRole(ds.ADMIN) {
        ls.LibStorage storage lib = ls.libStorage();  
        lib.startFee = _startFee;
        lib.endFee = _endFee;
        lib.slippage = _slippage;
        lib.affiliateRate = _affiliateRate;
        lib.fixedFees = _arr;
        lib.rewardRate = _rewardRate;
    }
    
    /**
     * @dev This function swaps the balance of collected fees and transfer, but only if the caller has the ADMIN role.
     * @param _tokenIn The address of the token to swap from.
     */
    // */address _tokenOut*/
    //  * @param _tokenOut The address of the token to swap to.
    function swapTokenBalance(address _tokenIn) public onlyRole(ds.ADMIN) {
        ls.LibStorage storage lib = ls.libStorage();  
        ls.Token storage token = lib._tokenVsIndex[_tokenIn];
        uint swapingAmount = token.balance;
        token.balance = 0;
        // if (_tokenIn == _tokenOut) {
        ls.transferFromContract(_tokenIn, msg.sender, swapingAmount);
        // } else {
            // require(IFaucet1(payable(address(this))).swap( _tokenIn, _tokenOut, swapingAmount,  msg.sender)); 
        // }
    }

    /**
     * @dev This function checks if an array of assets can be claimed.
     * @param _arr The array of asset IDs to check.
     * @return ids An array of asset IDs, checked A boolean array representing whether each asset is claimable or not.
     */
    function checkClaim(uint[] calldata _arr) public view returns(uint[] memory ids, bool[] memory checked){
        ids = new uint[](_arr.length);
        checked = new bool[](_arr.length);
        for (uint i=0; i < _arr.length; i++){
            ids[i] = _arr[i];
            checked[i] = ls.claimable(_arr[i]);
        }
    }

    /**
     * @dev Migrates an asset to V2.
     * Only assets with an `OPEN` status, is not gift and is owned features can be migrated.
     * Only the beneficiary can call this function.
     * 
     * @param assetId The ID of the asset to be migrated.
     * 
     * The function sets the status of the asset to `CLOSE`, calls the `Migrate` function of the V2 contract to create a new asset,
     * burns the old asset, and transfers the asset amount to the V2 contract. If the asset token is ETH, the transfer is made via a call
     * with the ETH value in the transaction. Otherwise, the transfer is made using the `transfer` function of the token.
     */
    function migrateAsset(uint assetId) public isActive {
        ls.LibStorage storage lib = ls.libStorage();
        ls.LockedAsset storage asset = lib._idVsLockedAsset[assetId];        
        require(asset.status == ls.Status.OPEN && asset.features[0] && !asset.features[1] );
        require(msg.sender == asset.beneficiary);
        asset.status = ls.Status.CLOSE;
        iv2Contract.Migrate(
        asset.token, asset.beneficiary, asset.creator, asset.amount, asset.endDate,
        asset.feeRate, asset.priceInUSD, asset.target, asset.features);
        gemChest.burn(assetId);
        (bool sent,) = ls.libStorage().ETH == asset.token ?  lib.v2Contract.call{value: asset.amount} (""):
        (IERC20(asset.token).transfer(lib.v2Contract, asset.amount), bytes(""));
        require(sent);
    }

    // @notice this functions just used for tests. 
    function executeGetAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) public {
        getAmountOutMinState = ls.getAmountOutMin(_tokenIn,_tokenOut, _amountIn);
    }   

    function getAmountOutMin() public view returns(uint){
        return getAmountOutMinState;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFaucet1 { 

    function deposit(
        address payable[] memory addr,
        uint amount,
        uint otherFees, 
        uint endDate,
        uint target, 
        bool[] memory features,
        string memory uuid
    ) 
        external payable;

    // function swapBeforeDeposit(
    //     address _token,
    //     address payable[] memory addr,
    //     uint _amount,
    //     uint _otherFees,
    //     uint _endDate,
    //     uint _target,
    //     bool [] memory features,
    //     string memory uuid)  external;

    function submitBeneficiary(uint id, string memory message, bytes memory signature, address signer,address _stableCoin,address receiver) external;

    function bulkClaim(uint[] memory ids, address SWAPTOKEN) external returns(bool);

    function claim(uint256 id, address SWAPTOKEN) external;

    // function swap (address _tokenIn, address _tokenOut,uint _amount, address _to) internal returns (bool success);

    function transferBeneficiary(address _newBeneficiary, uint _assetId) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGemChest {

    function safeMint(address to, uint256 tokenId) external; 

    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);
    
    function approve(address to, uint256 tokenId) external;
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    
    function safeTransferFrom(address from, address to, uint tokenId) external;

    function safeTransferFrom(address from, address to, uint tokenId, bytes memory data) external;
   

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interface/AggregatorV3Interface.sol";
import "contracts/interface/IQuoter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// import "hardhat/console.sol";


// Define the LibraryStorage library.
library LibraryStorage {

    // The LIB_STORAGE_POSITION constant represents the storage slot of the library.
    bytes32 constant LIB_STORAGE_POSITION = keccak256("diamond.standard.lib.storage");

    // The Status enum represents the possible status values for a Token or LockedAsset.
    enum Status {x, CLOSE, OPEN}

    // The Deposit event is emitted when a deposit is made.
    event Deposit( uint indexed num, address ETH, string str);
    
    // The Claim event is emitted when a claim is made.
    event Claim(string success);


    /**
     * @dev This struct represents a token, which includes its address, price feed address,
     * minimum amount to lock, collected fee balance, decimal, and status.
     */
    struct Token {
        address tokenAddress;
        address priceFeedAddress;
        uint minAmount;
        uint balance;
        uint8 decimal;
        Status status;
    }


    struct depositParams {
        address[] _addr ;
        uint _amount;
        uint _otherFees; 
        uint _endDate;
        uint _target;
        bool[] _features;
        string _uuid;
    }

    /** The LockedAsset struct represents a locked asset.
     * @dev This struct represents a locked asset, which includes the token being locked,
     * the beneficiary who will receive the asset after the lockup period, the creator of the lock, 
     * the amount being locked, the claimed amount, the end date of the lockup period, the fee rate 
     * (expressed as a percentage), the price of the asset in USD at the time of creation, 
     * the target rate (expressed as a percentage) the asset, an array of boolean is gift and 
     * is owned features, and the status of the lock.
     */
    struct LockedAsset {
        address token;
        address beneficiary;
        address creator;
        uint amount;
        uint claimedAmount;
        uint endDate;
        uint8 feeRate;
        int priceInUSD;
        uint target;
        bool[] features;
        Status status;
    }

    // The LibStorage struct represents the storage for the LibraryStorage library.
    struct LibStorage {
        address UNISWAP_V3_ROUTER;
        address QUOTER_ADDRESS;
        address ETH;
        address WETH;
        address SIGNER;
        address GemChestAddress;
        uint8 startFee;
        uint8 endFee;
        uint8 affiliateRate;
        uint8 slippage;
        uint8 rewardRate;
        uint24  routerSwapFee;
        uint _lockId;
        Token Token;
        Status status;
        mapping(address => Token) _tokenVsIndex;
        mapping(uint256 => LockedAsset) _idVsLockedAsset;
        uint[][] fixedFees;
        address v2Contract;
        bool isActive;
        bool initialized;
    }

    // The libStorage function returns the storage for the LibraryStorage library.
    function libStorage() internal pure returns (LibStorage storage lib) {
        bytes32 position = LIB_STORAGE_POSITION;
        assembly {
            lib.slot := position
        }
    }
    
    // The getToken function returns information about a token.
    function getToken(address _tokenAddress) internal view returns(
        address tokenAddress, 
        uint256 minAmount, 
        uint balance, 
        address priceFeedAddress,
        uint8 decimal,
        Status status
    )
    {
        LibStorage storage lib = libStorage();
        Token memory token = lib._tokenVsIndex[_tokenAddress];
        return (token.tokenAddress, token.minAmount, token.balance, token.priceFeedAddress, token.decimal, token.status);
    }

    // The getLockedAsset function returns information about a locked asset
    function getLockedAsset(uint256 assetId) internal view returns(
        address token,
        address beneficiary,
        address creator,
        uint256 amount,
        uint8 feeRate,
        uint256 endDate,
        uint256 claimedAmount,
        int priceInUSD,
        uint target,
        bool[] memory features,
        Status status
    )
    {
        LibStorage storage lib = libStorage();
        LockedAsset memory asset = lib._idVsLockedAsset[assetId];
        token = asset.token;
        beneficiary = asset.beneficiary;
        creator = asset.creator;
        amount = asset.amount;
        feeRate = asset.feeRate;
        endDate = asset.endDate;
        claimedAmount = asset.claimedAmount;
        priceInUSD = asset.priceInUSD;
        target = asset.target;
        features = asset.features;
        status = asset.status;
        return(
            token,                          
            beneficiary,
            creator,
            amount,
            feeRate,
            endDate,
            claimedAmount,
            priceInUSD,
            target,
            features,
            status       
        );
    }

    /** 
     * @dev This function calculates a fee based on a given amount, a percentage, and a boolean to indicate whether to add or subtract the fee.
     */
    function _calculateFee(uint amount, bool plus, uint procent) internal pure returns(uint256 calculatedAmount) { 
        // Calculate the fee based on the given percentage.
        uint reminder = amount * procent / 100;
        // If the percentage is 0, the calculated amount is just the original amount.
        calculatedAmount = procent == 0 ? amount : (plus) ? amount + reminder : amount - reminder;
    }

    /**
     * @dev This function calculates a fixed fee based on the current price of the token.
     */
    function _calculateFixedFee(address _token, uint amount, bool plus) internal view returns(uint256 calculatedAmount) { 
        LibStorage storage lib = libStorage();
        Token memory token = lib._tokenVsIndex[_token];        
        uint fixedAmount = (uint(getLatestPrice(token.priceFeedAddress)) * amount) / (10**token.decimal);        

        uint fee = lib.fixedFees[lib.fixedFees.length-1][1];
        for(uint i; i < lib.fixedFees.length; i++) {
            if (fixedAmount <= lib.fixedFees[i][0]){
                fee = lib.fixedFees[i][1];
                break;
            }
        }
        calculatedAmount = _calculateFee(amount, plus, fee);
    }

    /**
     *@dev Gets the latest price for a given price feed address.
     *@param _priceFeedAddress The address of the price feed.
     *@return The latest price.
     */
    function getLatestPrice(address _priceFeedAddress) internal view returns (int) {   
        AggregatorV3Interface priceFeed;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        ( /*uint80 roundID*/,
        int price,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return price;
    }

    /**
     * @dev Helper function to get the path of token pairs for later actions.
     * @param _tokenIn The address of the token to swap from.
     * @param _tokenOut The address of the token to swap to.
     * @return path of tokens.
     */
    function getPath(address _tokenIn, address _tokenOut) internal view returns(address[] memory path){
        LibStorage storage lib = libStorage();
        path = new address[](2);
        if (_tokenIn == lib.ETH){
            path[0] = lib.WETH;
            path[1] = _tokenOut;
        } else if (_tokenOut == lib.ETH) {
            path[0] = _tokenIn;
            path[1] = lib.WETH;
        } else {
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        }
    }

    // The getMessageHash function takes a message string and returns its keccak256 hash.
    function getMessageHash(string memory _message) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(_message));
    }

    // The getEthSignedMessageHash function takes a message hash and returns its hash as an Ethereum signed message.
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    // The verify function takes a message, signature, and signer address and returns a boolean indicating whether the signature is valid for the given message and signer.
    function verify(string memory message, bytes memory signature, address signer) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    // The recoverSigner function takes an Ethereum signed message hash and a signature and returns the address that signed the message.
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // The recoverSigner function takes an Ethereum signed message hash and a signature and returns the address that signed the message.
    function splitSignature(bytes memory sig) internal pure returns (bytes32 r,bytes32 s,uint8 v){
        require(sig.length == 65, "invalid signature length");
        assembly { 
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /** 
     * @dev This function calculates the estimated minimum amount of `_tokenOut` tokens that can be received for a given `_amountIn` of `_tokenIn` tokens
     */
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) internal returns(uint256 amountOut) {
        address[] memory path = getPath(_tokenIn, _tokenOut);
        try IQuoter(libStorage().QUOTER_ADDRESS).quoteExactInputSingle(path[0],path[1], libStorage().routerSwapFee ,_amountIn,0)
        returns (uint _amountOut) {
            return _amountOut;
        } catch {
            amountOut=0;
        }
    }


    /**
     * @dev This helper function checks if a locked asset with the given `id` can be claimed
     */
    function claimable(uint256 id) internal view returns(bool success){
        LockedAsset memory asset = libStorage()._idVsLockedAsset[id];
        // Check if the claim period has ended or if the asset has already been claimed, and if the status of the asset is open
        success = (asset.endDate <= block.timestamp || _eventIs(id)) &&  asset.status == Status.OPEN ? true : false;
    }

    /**
     * @dev This function Check if the given asset current price greater or equal to the target price  
     * @param id locked asset id
     */
    function _eventIs(uint id) internal view returns(bool success) { 
        LockedAsset memory asset = libStorage()._idVsLockedAsset[id];
        if (asset.status == Status.CLOSE || asset.status == Status.x){
            return false;
        }
        else {
            ( /*address tokenAddress*/,
                /*uint256 minAmount*/,
                /*uint balance*/,
                address _priceFeedAddress,
                /* uint8 decimal*/,
                /*Status status*/
            ) = getToken(asset.token);
            // Get the latest price of the token from the price feed using the oracle contract
            int oraclePrice = getLatestPrice(_priceFeedAddress);
            // Check if the current price of the token is greater than or equal to the target price of the asset amount
            success = oraclePrice * 5 >= (asset.priceInUSD * int(asset.target)) / 100 ? true : false;
        } 
    }

    /**
     * 
     * @dev Internal function to transfer funds from the contract to a given receiver.
     * @param _token The address of the token to transfer.
     * @param _receiver The address to receive the funds.
     * @param _value The amount of funds to transfer.
     */
    function transferFromContract (address _token, address _receiver, uint _value) internal {
        (bool sent,) = (_token == libStorage().ETH) ?  payable(_receiver).call{value: _value} ("") : (IERC20(_token).transfer(_receiver,_value), bytes(""));
        require(sent, "tx failed");
    } 

    function getAmountOraclePrice (address _token, address _swapToken, uint newAmount) internal view returns(uint amountOraclePrice) {
        LibStorage storage lib = libStorage();
        Token memory token = lib._tokenVsIndex[_token];
        uint8 oraclePriceLenght = uint8(bytes(Strings.toString( uint(getLatestPrice(token.priceFeedAddress)))).length);
        oraclePriceLenght = (oraclePriceLenght >= 8 ) ? 8 : (17 - oraclePriceLenght);
        amountOraclePrice = ((( uint(getLatestPrice(token.priceFeedAddress)) * newAmount ) / 10** token.decimal )  
        * 10**lib._tokenVsIndex[_swapToken].decimal) / 10 ** oraclePriceLenght;
        amountOraclePrice -= (amountOraclePrice * lib.slippage) / 100;
    } 
}



/** 
                                                         \                           /      
                                                          \                         /      
                                                           \                       /       
                                                            ]                     [    ,'| 
                                                            ]                     [   /  | 
                                                            ]___               ___[ ,'   | 
                                                            ]  ]\             /[  [ |:   | 
                                                            ]  ] \           / [  [ |:   | 
                                                            ]  ]  ]         [  [  [ |:   | 
                                                            ]  ]  ]__     __[  [  [ |:   | 
                                                            ]  ]  ] ]\ _ /[ [  [  [ |:   | 
                                                            ]  ]  ] ] (#) [ [  [  [ :====' 
                                                            ]  ]  ]_].nHn.[_[  [  [        
                                                            ]  ]  ]  HHHHH. [  [  [        
                                                            ]  ] /   `HH("N  \ [  [        
                                                            ]__]/     HHH  "  \[__[        
                                                            ]         NNN         [        
                                                            ]         N "         [          
                                                            ]         N H         [        
                                                           /          N            \        
                                                          /     how far you can     \       
                                                         /        go mr.Green ?      \          
                                                    
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import { IDiamondCut } from "../interface/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant ADMIN = keccak256("ADMIN");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }


    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        mapping(bytes4 => bool) supportedInterfaces;
        // roles
        mapping(bytes32 => RoleData) _roles;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress == address(0), "Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "_init address has no code");        
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }


    // Access control
    function hasRole(bytes32 role, address account) internal view  returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        return ds._roles[role].members[account];
    }

    function getRoleAdmin(bytes32 role) internal view  returns (bytes32) {
        DiamondStorage storage ds = diamondStorage();
        return ds._roles[role].adminRole;
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            DiamondStorage storage ds = diamondStorage();
            ds._roles[role].members[account] = true;
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            DiamondStorage storage ds = diamondStorage();
            ds._roles[role].members[account] = false;
        }
    }

    function _checkRole(bytes32 role) internal view {
        _checkRole(role, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(string(abi.encodePacked("account is missing role ")));
        }
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IV2Contract {
    
    function Migrate(
        address token,
        address beneficiary ,address creator,uint amount,uint endDate,uint8 feeRate, int priceInUSD, uint target,bool[] memory features)
         external payable;
         

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
  function getRoundData(uint80 _roundId) external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound);
  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}