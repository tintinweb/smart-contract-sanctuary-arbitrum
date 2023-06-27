//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0<=0.8.9;

import "./IERC721Receiver.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";



contract Market is IERC721Receiver,Ownable {
    using SafeERC20 for IERC20;
    IERC721 public mercenary;
    IERC20 public token;

    struct StakeDetail {
        address payable author;
        uint256 price;
        uint256 tokenId;
    }

    event StakeNft(address indexed _from, uint256 _tokenId, uint256 _price);
    event UnstakeNft(address indexed _from,uint256 _tokenId);
    event BuyNft(address indexed _from,uint256 _tokenId, uint256 _price);

    uint256 public tax = 7; // percentage
    uint256[] public stakedNft;
    mapping ( uint256 => StakeDetail ) stakeDetail;

    constructor(IERC721 _mercenary, IERC20 _token) {
        mercenary = _mercenary;
        token = _token;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function getStakingAmount(address _address) view public returns (uint256) {
        uint256 total = 0;
        for (uint256 index = 0; index < stakedNft.length; index++) {
            if (stakeDetail[stakedNft[index]].author == _address) {
                total += 1;
            }
        }

        return total;
    }

    function getStakingAmount() view public returns (uint256) {
        return stakedNft.length;
    }

    function getStakedNft() view public returns (StakeDetail [] memory) {
        uint256 length = getStakingAmount();
        StakeDetail[] memory myNft = new StakeDetail[](length);
        uint count = 0;

        for (uint256 index = 0; index < stakedNft.length; index++) {
            myNft[count++] = stakeDetail[stakedNft[index]];
        }
        
        return myNft;
    }

    function getStakedNft(address _address) view public returns (StakeDetail [] memory) {
        uint256 length = getStakingAmount(_address);
        StakeDetail[] memory myNft = new StakeDetail[](length);
        uint count = 0;

        for (uint256 index = 0; index < stakedNft.length; index++) {
            if (stakeDetail[stakedNft[index]].author == _address) {
                myNft[count++] = stakeDetail[stakedNft[index]];
            }
        }
        
        return myNft;
    }

    function getAddress(uint256 _index) view public returns (address) {
        return stakeDetail[stakedNft[_index]].author;
    }

    function push(uint256[] storage array, uint256 element) private {
        for (uint256 index = 0; index < array.length; index++) {
            if (array[index] == element) {
                return;
            }
        }
        array.push(element);
    }

    function push(address[] storage array, address element) private {
        for (uint256 index = 0; index < array.length; index++) {
            if (array[index] == element) {
                return;
            }
        }
        array.push(element);
    }

    function pop(uint256[] storage array, uint256 element) private {
        for (uint256 index = 0; index < array.length; index++) {
            if (array[index] == element) {
                array[index] = array[array.length - 1];
                array.pop();
                // delete array[index];
                return;
            }
        }
    }

    function stakeNft(uint256 _tokenId, uint256 _price) public {
        require(mercenary.ownerOf(_tokenId) == msg.sender);
        require(mercenary.getApproved(_tokenId) == address(this));

        push(stakedNft, _tokenId);
        stakeDetail[_tokenId] = StakeDetail(payable(msg.sender), _price, _tokenId);

        mercenary.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit StakeNft(msg.sender,_tokenId, _price);
    }

    function unstakeNft(uint256 _tokenId) public {
        require(mercenary.ownerOf(_tokenId) == address(this), "This NFT doesn't exist on market");
        require(stakeDetail[_tokenId].author == msg.sender, "Only owner can unstake this NFT");

        pop(stakedNft, _tokenId);

        mercenary.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit UnstakeNft(msg.sender,_tokenId);
    }

    function buyNft(uint256 _tokenId, uint256 _price) public {
        require(token.balanceOf(msg.sender) >= _price, "Insufficient account balance");
        require(mercenary.ownerOf(_tokenId) == address(this), "This NFT doesn't exist on market");
        require(stakeDetail[_tokenId].price <= _price, "Minimum price has not been reached");
           
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), _price);
        token.transfer(stakeDetail[_tokenId].author, _price * (100 - tax) / 100);
          
        mercenary.safeTransferFrom(address(this), msg.sender, _tokenId);
        pop(stakedNft, _tokenId);
        emit BuyNft(msg.sender,_tokenId, _price);
    }
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawErc20(IERC20 _token) public onlyOwner {
        token.transfer(msg.sender, _token.balanceOf(address(this)));
    }
   


}