// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./CloneFactory.sol";

library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20Permit {

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}

interface IMarketFactory {
    function _tokenIds() external view returns (uint256);

    function uri(uint256 tokenId) external view returns (string memory);

    function setSize(uint256 _size) external;

    function setCollectionInfo(string memory _uri) external;

    function mintNFT(uint tokenId, address taker, uint amount) external returns (uint);

    function setMarketplace(address _marketplace) external;

    function transferOwnership(address newOwner) external;

    function initialize(address newOnwer) external;
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function getUserInfo(uint tokenId) external view returns(uint8 royaltyFee, uint8 royaltyShare, uint8 nftType, uint tier0Cnt, address admin);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IOwnerable {
    function owner() external view returns(address);
}

interface IRedeemAndFee {
    function accumulateTransactionFee(address user, uint royaltyFee, uint amount) external returns(uint transactionFee, uint, uint income);
    function unCliamedReward(address user) external view returns(uint amount);
    function claim(address user) external;
    function getBlackList (address user) external view returns(bool);
    function unclassifiedList(address user) external view returns (bool);
    function flatFee() external view returns (uint);
    function ableToViewALLPrivateMetadata(address user) external view returns(bool);
}

interface IFactory {
    // function decreaseTier0(uint tokenId, address user) external returns(uint8, uint256);
    // function initialTier0(uint tokenId) external;
    function tier0TokenId() external view returns(uint256);
    function getUserInfo(uint tokenId) external view returns(uint8 royaltyFee, uint8 royaltyShare, uint8 nftType, address tier0, address admin);
}

interface ITier0 {
    function setType(uint8 _type) external;
    function getState() external view returns(uint256 total, uint256 current);
    function mint(address user, uint256 amount) external;
    function disput(address user, uint256 amount) external;
    function cancelList() external;
    function isSaleOver() external view returns(bool);
    function requireValidAmount(uint256 amount) external view;
}

contract FNFT_Market is Ownable, CloneFactory {
    using SafeERC20 for IERC20;

    address public marketFactory;
    address public redeemAndFee;
    address immutable WETH; // 0xEe01c0CD76354C383B8c7B4e65EA88D00B06f36f;     // for test
    address public treasury;

    struct PutOnSaleInfo {
        address maker;
        address collectionId;
        uint256 tokenId;
        uint8 royaltyFee;
        uint8 royaltyShare;
        address admin;
        address coin;
        uint256 price;
        uint256 bookingFee;
        uint256 duration;
        uint256 procDay;
        uint256 total;
        uint256 current;
        address taker;
        bool state;
        bool listerState;
        bool buyerState;
    }

    struct WithdrawInfo {
        uint lockedAmount;
        uint withdrawAmount;
    }

    mapping(bytes32 => PutOnSaleInfo) listInfo;
    mapping(bytes32 => WithdrawInfo) withdrawInfo;
    mapping(address => uint8) royaltyFeeForExternal;
    // bytes32[] public hashList;

    event PutOnSaleEvent(
        bytes32 _key,
        uint8 royaltyFee,
        uint8 royaltyShare,
        address admin
    );

    event mintNFTEvent(
        uint id
    );

    modifier isBlackList() {
        require(false == IRedeemAndFee(redeemAndFee).getBlackList(msg.sender), "FNFT:blackLiser");
        _;
    }

    constructor(address _WETH) {
        WETH = _WETH;
    }

    function _makeHash(
        address user,
        address collectionId,
        uint256 tokenId,
        uint currentTime
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, collectionId, tokenId, currentTime));
    }

    function setTreasury(address wallet) external onlyOwner {
        treasury = wallet;
    }

    function setMarketFactory(address factory) external onlyOwner {
        marketFactory = factory;
    }

    function setRedeemFeeContract(address _contract) external onlyOwner {
        redeemAndFee = _contract;
    }

    function putOnSale(
        address collectionId,
        uint256 tokenId,
        address coin,
        uint256 price,
        uint256 bookingFee,
        uint8 royaltyFee,
        bool setRoyaltyFee,
        address user,
        uint256 duration     // expirate time (unit days)
    ) external payable isBlackList {
        if(user != msg.sender)
            require(IRedeemAndFee(redeemAndFee).ableToViewALLPrivateMetadata(msg.sender), "FNFT:no angel");
        if(user != detectOwner(collectionId))
            require(msg.value == IRedeemAndFee(redeemAndFee).flatFee(), "FNFT:wrong flatfee");

        require(price > bookingFee, "FNFT:IV wrong booking fee");

        address collectionOwner = detectOwner(collectionId);

        if(setRoyaltyFee) {
            require(collectionOwner == user, "FNFT:721-no owner");
            royaltyFeeForExternal[user] = royaltyFee;
        }

        bytes32 _key = _makeHash(user, collectionId, tokenId, block.timestamp);

        require((listInfo[_key].maker == address(0)) && (listInfo[_key].collectionId == address(0)), "FNFT: alreay listed");

        // hashList.push(_key);
        listInfo[_key].maker = user;
        listInfo[_key].collectionId = collectionId;
        listInfo[_key].tokenId = tokenId;

        (,,,address tier0,) = IFactory(marketFactory).getUserInfo(tokenId);

        listInfo[_key].coin = coin;
        listInfo[_key].price = price;
        listInfo[_key].bookingFee = bookingFee;
        listInfo[_key].duration = duration;
        listInfo[_key].procDay = 0;

        uint256 _total = 0;
        uint256 _current = 0;

        (_total, _current) = ITier0(tier0).getState();
        listInfo[_key].total = _total;
        listInfo[_key].current = 0;
        listInfo[_key].state = false;
        listInfo[_key].listerState = true;
        listInfo[_key].buyerState = false;
        withdrawInfo[_key].withdrawAmount = 0;
        withdrawInfo[_key].lockedAmount = 0;

        if(collectionOwner != address(0) && royaltyFeeForExternal[user] != 0) {         // But when the original contract owner will come and verify and set the roatlity fee...
             listInfo[_key].admin = collectionOwner;
             listInfo[_key].royaltyFee = royaltyFeeForExternal[user];
        }
        _putonSaleFor1155(_key, collectionId, tokenId); // lock this FNFT when put on sale

        if(msg.sender != user) {        // lazy mode
            listInfo[_key].royaltyShare = 50;       // 50% will be left in this contract and the other %50 fee will go to the nft angel
            listInfo[_key].admin = msg.sender;      // NFT angel
        }   

        if(msg.value > 0)
            payable (treasury).transfer(msg.value);

        emit PutOnSaleEvent(
            _key,
            listInfo[_key].royaltyFee,
            listInfo[_key].royaltyShare,
            listInfo[_key].admin
        );
    }

    function _putonSaleFor1155(bytes32 _key, address collectionId, uint tokenId) private {
        try IERC1155(collectionId).getUserInfo(tokenId) returns(uint8 _royaltyFee, uint8 _royaltyShare, uint8 nftType, uint, address admin) {
            require(nftType == 1, "FNFT:no trade");
            listInfo[_key].royaltyFee = _royaltyFee;
            listInfo[_key].royaltyShare = _royaltyShare;
            listInfo[_key].admin = admin;
            IERC1155(collectionId).safeTransferFrom(msg.sender, address(this), tokenId, 1, ""); // lock this FNFT when put on sale
        } catch {
            require(false, "FNFT:no FNFT");
        }
    }

    function cancelList (bytes32 _key) external isBlackList {
        require(listInfo[_key].maker == msg.sender, "FNFT:not Lister");
        require(!listInfo[_key].state || ((listInfo[_key].procDay < block.timestamp) && (listInfo[_key].total > listInfo[_key].current)), "FNFT:booking duration");

        (,,,address tier0,) = IFactory(marketFactory).getUserInfo(listInfo[_key].tokenId);

        if(listInfo[_key].current > 0)
        {
            ITier0(tier0).disput(listInfo[_key].taker, listInfo[_key].current);
            IERC20(listInfo[_key].coin).safeTransferFrom(address(this), listInfo[_key].taker, withdrawInfo[_key].lockedAmount);
        }
        ITier0(tier0).cancelList();

        IERC1155(listInfo[_key].collectionId).safeTransferFrom(address(this), msg.sender, listInfo[_key].tokenId, 1, "");
        
        delete withdrawInfo[_key];
        delete listInfo[_key];
    }

    function claimOwner (bytes32 _key) external isBlackList {
        require((listInfo[_key].taker == msg.sender) && listInfo[_key].state && (listInfo[_key].current == listInfo[_key].total), "FNFT:not avalible");
        
        (,,,address tier0,) = IFactory(marketFactory).getUserInfo(listInfo[_key].tokenId);

        ITier0(tier0).disput(msg.sender, listInfo[_key].current);
        ITier0(tier0).cancelList();
        
        IERC1155(listInfo[_key].collectionId).safeTransferFrom(address(this), msg.sender, listInfo[_key].tokenId, 1, "");

        (,, uint income) = IRedeemAndFee(redeemAndFee).accumulateTransactionFee(listInfo[_key].maker, 0, withdrawInfo[_key].lockedAmount);

        address coin = listInfo[_key].coin;
        uint fee = (withdrawInfo[_key].lockedAmount - income) * 10 / 100;
        IERC20(coin).safeTransfer(treasury, fee);
        
        if(listInfo[_key].listerState)
            listInfo[_key].buyerState = false;
        else
        {
            delete withdrawInfo[_key];
            delete listInfo[_key];
        }
    }

    /* 
    * withdraw funds from sold tier0
    */
    function claimFund(bytes32 _key) external isBlackList {
        require(listInfo[_key].maker == msg.sender, "FNFT:no owner");
        require(listInfo[_key].current == listInfo[_key].total, "FNFT:not all sold");

        (,, uint income) = IRedeemAndFee(redeemAndFee).accumulateTransactionFee(listInfo[_key].maker, 0, withdrawInfo[_key].lockedAmount);
        
        address coin = listInfo[_key].coin;
        IERC20(coin).safeTransfer(listInfo[_key].maker, income);
        
        if(listInfo[_key].buyerState)
            listInfo[_key].listerState = false;
        else
        {
            delete withdrawInfo[_key];
            delete listInfo[_key];
        }
          
    }

    function detectOwner(address _contract) public view returns (address) {
        try IOwnerable(_contract).owner() returns (address owner) {
            return owner;
        } catch {
            return address(0);
        }
    }

    function buyTier0 (bytes32 _key, address user, uint256 amount, uint price) external isBlackList {
        require(listInfo[_key].procDay >= block.timestamp && listInfo[_key].taker == user, "FNFT: not available");
        require((listInfo[_key].total - listInfo[_key].current) >= amount, "FNFT: invalid amount");
        
        // (uint8 step, uint amount) = ITier0(tier0).decreaseTier0(listInfo[_key].tokenId, user);
        withdrawInfo[_key].lockedAmount += price;
        listInfo[_key].current += amount; 

        address coin = listInfo[_key].coin;

        IERC20(coin).safeTransferFrom(user, address(this), price);
        (,,,address tier0,) = IFactory(marketFactory).getUserInfo(listInfo[_key].tokenId);
        ITier0(tier0).mint(user, amount);
    }

    function sellTier0(bytes32 _key, address taker) external isBlackList returns(uint id) {
        uint ids = 0;
        require(listInfo[_key].taker == taker, "not taker");

        if(listInfo[_key].current != listInfo[_key].total)
        {
            address coin = listInfo[_key].coin;
            address tier0;
            (,,, tier0,) = IFactory(marketFactory).getUserInfo(listInfo[_key].tokenId);
            IERC20(coin).safeTransferFrom(address(this), taker, withdrawInfo[_key].lockedAmount);
            ITier0(tier0).disput(taker, listInfo[_key].current);
            withdrawInfo[_key].lockedAmount = 0;
            listInfo[_key].current = 0;
        }
        else{
            ids = IMarketFactory(listInfo[_key].collectionId).mintNFT(listInfo[_key].tokenId, taker, listInfo[_key].total);

            emit mintNFTEvent(ids);
            
            if(listInfo[_key].listerState)
                listInfo[_key].buyerState = false;
            else
            {
                delete withdrawInfo[_key];
                delete listInfo[_key];
            }
        }
        return ids;
    }

    function reserve(bytes32 _key, address taker) external isBlackList{
        require(!listInfo[_key].state && listInfo[_key].current == 0, "already booking");

        listInfo[_key].state = true;
        listInfo[_key].taker = taker;
        listInfo[_key].procDay = block.timestamp + listInfo[_key].duration * 1 days;
        listInfo[_key].buyerState = true;
        address coin = listInfo[_key].coin;
        IERC20(coin).safeTransferFrom(taker, listInfo[_key].maker, listInfo[_key].bookingFee);
    }
    
    function UnClassifiedList(address user) private view returns(bool) {
        return IRedeemAndFee(redeemAndFee).unclassifiedList(user);
    }

    function ListInfo(bytes32 _key) external view returns(PutOnSaleInfo memory info, bool isValid) {
        if(UnClassifiedList(listInfo[_key].maker)) {
            return (info, false);
        }
        return (listInfo[_key], true);
    }

    function getWithdrawInfo(bytes32 _key) external view returns (WithdrawInfo memory info) {
        return withdrawInfo[_key];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}