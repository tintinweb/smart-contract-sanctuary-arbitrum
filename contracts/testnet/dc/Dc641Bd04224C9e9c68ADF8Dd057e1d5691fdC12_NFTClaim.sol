// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./INFTCore.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC721.sol";

contract NFTClaim is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    INFTCore public nftCore;
    IERC721 public nft;
    IERC20 public nftToken;

    uint256 public CURRENT_ID;

    event Claim(
        uint256 indexed tokenId,
        address userAddress,
        uint256 amount,
        uint256 campaignId
    );

    mapping(address => UserInfo) public userInfos;
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => uint256) public claimTimes;
    struct UserInfo {
        uint256 totalAmount;
        uint256 lastClaimed;
    }

    struct Campaign {
        uint256 start;
        uint256 finish;
        uint256 totalPool;
        uint256 currentPool;
    }

    mapping(uint256 => mapping(uint256 => uint256)) public rateCampaigns;
    mapping(uint256 => mapping(uint256 => uint256)) public claimTimeByCampaigns;

    constructor(address _nft, IERC20 _nftToken) {
        nftCore = INFTCore(_nft);
        nftToken = _nftToken;
        nft = IERC721(_nft);
        rateCampaigns[1][0] = 0.001 ether;
        rateCampaigns[1][1] = 0.01 ether;
        campaigns[1] = Campaign(
            block.timestamp,
            block.timestamp.add(90 days),
            1000000 ether,
            0
        );
        CURRENT_ID = 1;
    }

    function setRateCampaign(
        uint256 campId,
        uint256[] memory rares,
        uint256[] memory tokenQuantities
    ) external onlyOwner {
        require(rares.length == tokenQuantities.length, "length not match");
        for (uint256 index = 0; index < rares.length; index++) {
            rateCampaigns[campId][rares[index]] = tokenQuantities[index];
        }
    }

    function setNFTToken(IERC20 _address) external onlyOwner {
        nftToken = _address;
    }

    function addCampaign(Campaign memory campaign) external onlyOwner {
        CURRENT_ID = CURRENT_ID + 1;
        campaigns[CURRENT_ID] = campaign;
    }

    function modifyCampaign(uint256 campaignId, Campaign memory campaign)
        external
        onlyOwner
    {
        campaigns[campaignId] = campaign;
    }

    function setNFT(address _address) external onlyOwner {
        nftCore = INFTCore(_address);
        nft = IERC721(_address);
    }

    /**
     * @dev Claim Token
     */
    function claimToken(uint256[] memory tokenIds, uint256 campaignID)
        external
        nonReentrant
        whenNotPaused
    {
        require(
            block.timestamp >= campaigns[campaignID].start,
            "claim not start"
        );
        require(
            block.timestamp <= campaigns[campaignID].finish,
            "claim was ended"
        );
        UserInfo storage userInfo = userInfos[_msgSender()];
        require(tokenIds.length >= 1, "not enough nft");
        uint256 totalAmount = 0;
        for (uint256 index = 0; index < tokenIds.length; index++) {
            require(nft.ownerOf(tokenIds[index]) == _msgSender(), "not owner");
            require(
                    claimTimeByCampaigns[campaignID][tokenIds[index]] == 0,
                    "limit claim"
                );
            
            uint256 amountByCamp = rateCampaigns[campaignID][
                nftCore.getNFT(tokenIds[index]).rare
            ];
            
            totalAmount += amountByCamp;
            claimTimeByCampaigns[campaignID][tokenIds[index]] = block.timestamp;
            emit Claim(
                tokenIds[index],
                _msgSender(),
                amountByCamp,
                campaignID
            );
        }
        require(
            campaigns[campaignID].currentPool < campaigns[campaignID].totalPool,
            "limit claim pool"
        );
        if (
            totalAmount >
            (campaigns[campaignID].totalPool -
                campaigns[campaignID].currentPool)
        ) {
            totalAmount = (campaigns[campaignID].totalPool -
                campaigns[campaignID].currentPool);
        }
        userInfo.lastClaimed = block.timestamp;
        userInfo.totalAmount = userInfo.totalAmount.add(totalAmount);
        campaigns[campaignID].currentPool = campaigns[campaignID]
            .currentPool
            .add(totalAmount);
        nftToken.transfer(_msgSender(), totalAmount);
    }

    function calculateReward(
        uint256 tokenId,
        uint256 campaignID
    ) public view returns (uint256 totalAmount) {
        totalAmount = rateCampaigns[campaignID][
            nftCore.getNFT(tokenId).rare
        ];
    }

    /**
     * @dev Withdraw bnb from this contract (Callable by owner only)
     */
    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) public onlyOwner {
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IERC20(coinAddress).transfer(to, value);
    }
}