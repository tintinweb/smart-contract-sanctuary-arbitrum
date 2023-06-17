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
}

contract ServiceMarket is Ownable, CloneFactory {
    using SafeERC20 for IERC20;

    address public redeemAndFee;
    address immutable WETH;  // 0xEe01c0CD76354C383B8c7B4e65EA88D00B06f36f  // for test
    address public treasury;

    struct ActionSNFTInfo {
        address taker;
        uint[] price;
    }

    struct ServiceNFTPutOnSale {
        address maker;
        address collectionId;
        uint256 tokenId;
        uint[] price;
        uint8 releaseId;
        uint8 acceptId;
        address coin;
        address confirmUser;
        ActionSNFTInfo[] auctionInfo;
    }

    event PutOnSale(
        bytes32 _key
    );

    mapping(bytes32 => ServiceNFTPutOnSale) sNftInfo;
    bytes32[] public sNFTList;

    enum ContractType {
        ERC721,
        ERC1155,
        Unknown
    }

    modifier isBlackList() {
        require(false == IRedeemAndFee(redeemAndFee).getBlackList(msg.sender), "SMain:blackLiser");
        _;
    }

    constructor(address _WETH) {
        WETH = _WETH;
    }

    function _makeHash(
        address user,
        address collectionId,
        uint256 tokenId
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, collectionId, tokenId));
    }

    function setTreasury(address wallet) external onlyOwner {
        treasury = wallet;
    }

    function setRedeemFeeContract(address _contract) external onlyOwner {
        redeemAndFee = _contract;
    }

    function sNFTPutOnSale(address collectionId, uint tokenId, address coin, uint[] memory price) external payable isBlackList {
        require(msg.value == IRedeemAndFee(redeemAndFee).flatFee(), "SMain:insuff flat fee");
        try IERC1155(collectionId).getUserInfo(tokenId) returns(uint8, uint8, uint8 nftType, uint, address) {
            require(nftType == 2, "SMain:Not sNFT");
        } catch {
            require(false, "SMain:throw-Not sNFT");
        }
        bytes32 _key = _makeHash(msg.sender, collectionId, tokenId);
        if (sNftInfo[_key].maker == address(0) && sNftInfo[_key].collectionId == address(0)) {
            sNFTList.push(_key);
            sNftInfo[_key].maker = msg.sender;
            sNftInfo[_key].collectionId = collectionId;
            sNftInfo[_key].tokenId = tokenId;
        }
        sNftInfo[_key].coin = coin;
        uint _totalPrice;
        sNftInfo[_key].price = price;
        for(uint i = 0; i < price.length; i++) {
            _totalPrice += price[i];
        }
        sNftInfo[_key].price = price;
        IERC20(coin).safeTransferFrom(msg.sender, address(this), _totalPrice);
        if(msg.value > 0)
            payable (treasury).transfer(msg.value);
            
        emit PutOnSale(_key);
    }

    function cancelSNFT(bytes32 _key) external isBlackList {
        require(sNftInfo[_key].maker == msg.sender, "SMain:not owner");

        sNftInfo[_key].maker = address(0);
        sNftInfo[_key].collectionId = address(0);
        sNftInfo[_key].tokenId = 0;

        uint _totalPrice;
        for(uint i = 0; i < sNftInfo[_key].price.length; i++) {
            _totalPrice += sNftInfo[_key].price[sNftInfo[_key].price.length-1];
            sNftInfo[_key].price.pop();
        }

        IERC20(sNftInfo[_key].coin).safeTransfer(msg.sender, _totalPrice);
    }

    function SNFTAuction(bytes32 _key, uint[] memory price) external isBlackList {
        require(sNftInfo[_key].price.length == price.length,"SMain:not matched milestone");
        require(sNftInfo[_key].maker != msg.sender,"SMain:can't auction");
        require(sNftInfo[_key].confirmUser == address(0), "SMain:already offered");
        ActionSNFTInfo[] storage auctionInfoList = sNftInfo[_key].auctionInfo;
        bool isExist = false;
        for(uint i = 0; i < auctionInfoList.length; i++) {
            if(auctionInfoList[i].taker == msg.sender) {
                auctionInfoList[i].price = price;
                isExist = true;
                break;
            }
        }
        if(!isExist) {
            sNftInfo[_key].auctionInfo.push(ActionSNFTInfo({taker: msg.sender, price: price}));
        }
    }

    function cancelSNFTAuction(bytes32 _key) external isBlackList {
        require(sNftInfo[_key].confirmUser == address(0), "SMain:already assigned");
        ActionSNFTInfo[] storage auctionInfoList = sNftInfo[_key].auctionInfo;
        bool isValid = false;
        for(uint i = 0; i < auctionInfoList.length; i++) {
            if(msg.sender == auctionInfoList[i].taker) {
                auctionInfoList[i] = auctionInfoList[auctionInfoList.length-1];
                auctionInfoList.pop();
                isValid = true;
                break;
            }
        }
        require(isValid, "SMain:not owner");
    }

    function confirmSNFT(bytes32 _key, address user) external isBlackList {
        require(sNftInfo[_key].confirmUser == address(0), "SMain:already assigned");
        sNftInfo[_key].releaseId = 0;
        sNftInfo[_key].acceptId = 0;
        if(msg.sender == sNftInfo[_key].maker) {
            // client gives an offer to the selected client
            ActionSNFTInfo[] storage auctionInfoList = sNftInfo[_key].auctionInfo;
            bool isValid = false;
            uint takerPrice;
            uint makerPrice;
            for(uint i = 0; i < auctionInfoList.length; i++) {
                if(user == auctionInfoList[i].taker) {
                    for(uint j = 0; j < auctionInfoList[i].price.length; j++) {
                        takerPrice += auctionInfoList[i].price[j];
                        makerPrice += sNftInfo[_key].price[j];
                    }
                    sNftInfo[_key].price = auctionInfoList[i].price;
                    isValid = true;
                    break;
                }
            }
            require(isValid, "SMain:invalid user");
            sNftInfo[_key].confirmUser = user;
            if(takerPrice > makerPrice) {
                IERC20(sNftInfo[_key].coin).safeTransferFrom(msg.sender, address(this), takerPrice - makerPrice);
            } else if (takerPrice < makerPrice) {
                IERC20(sNftInfo[_key].coin).safeTransfer(msg.sender, makerPrice - takerPrice);
            }
        } else {
            // lancer accepts this milestone
            sNftInfo[_key].confirmUser = msg.sender;
        }
    }

    function releaseMilestone(bytes32 _key) external isBlackList {
        require(msg.sender == sNftInfo[_key].maker, "SMain:not owner");
        require(sNftInfo[_key].releaseId+1 <= sNftInfo[_key].price.length, "SMain: exceed milestone");
        sNftInfo[_key].releaseId ++;
    }

    function takeMilestone(bytes32 _key) external isBlackList {
        require(msg.sender == sNftInfo[_key].confirmUser, "SMain:not taker");
        require(sNftInfo[_key].acceptId < sNftInfo[_key].releaseId, "SMain:no more");
        uint _price = 0;
        for (uint i = sNftInfo[_key].acceptId; i < sNftInfo[_key].releaseId; i++) {
            _price += sNftInfo[_key].price[i];
        }
        sNftInfo[_key].acceptId = sNftInfo[_key].releaseId;
        IERC20(sNftInfo[_key].coin).safeTransfer(msg.sender, _price * 97 / 100);
        IERC20(sNftInfo[_key].coin).safeTransfer(treasury, _price - _price * 97 / 100);
    }

    function _unClassifiedList(address user) private view returns(bool) {
        return IRedeemAndFee(redeemAndFee).unclassifiedList(user);
    }
    function SNftInfo(bytes32 _key) external view returns(ServiceNFTPutOnSale memory info, uint[] memory milestones, ActionSNFTInfo[] memory auctionInfo, bool isValid) {
        if(_unClassifiedList(sNftInfo[_key].maker)) {
            return (info, milestones, auctionInfo, false);
        }
        milestones = new uint[](sNftInfo[_key].price.length);
        auctionInfo = new ActionSNFTInfo[](sNftInfo[_key].auctionInfo.length);
        milestones = sNftInfo[_key].price;
        auctionInfo = sNftInfo[_key].auctionInfo;
        info = sNftInfo[_key];
        return(info, milestones, auctionInfo, true);
    }

    function withdrawTokens(address coin, address user, uint amount) external onlyOwner {
        IERC20(coin).safeTransfer(user, amount);
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