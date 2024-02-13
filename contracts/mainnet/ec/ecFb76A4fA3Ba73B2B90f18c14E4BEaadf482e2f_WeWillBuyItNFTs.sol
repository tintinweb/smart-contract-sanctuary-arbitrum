/**
 *Submitted for verification at Arbiscan.io on 2024-02-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: IERC721Receiver.sol

pragma solidity ^0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.4;

contract WeWillBuyItNFTs is Ownable, IERC721Receiver  {
    IERC721 public nft;

    uint256 public countOfOverallStakers;

    // Mapping
    mapping(address => mapping(address => mapping(uint256 => uint256))) public tokenStakedTime;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public tokenStakedDuration;
    mapping(address => mapping(uint256 => address)) public stakedTokenOwner;
    mapping(address => mapping(address => uint256[])) public stakedTokens;
    mapping(address => uint256) public countOfMyStakedTokens;
    mapping(uint256 => address) public stakers;
    mapping(uint256 => address) public nftOwner;

    uint256[] public depositedAmount;
    uint256 public serviceChargePerNFT = 10000; //added 4 decimals to the actual value
    uint256 public maxNFTsPerTransaction = 1000;
    uint256 public rewardPerNFT = 100 ; //added 4 decimals to the actual value
    uint256 public decimalCorrector = 8;
    uint256 public decimalCorrector2 = 14;

    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeedAddress) {

        priceFeed = AggregatorV3Interface(_priceFeedAddress);

    }

    function deposit() external payable {
        depositedAmount.push(msg.value);
    }

    function stakeNFTs(uint256[] memory _tokenIDs, address[] memory _contractAddresses) public payable {
        require(_tokenIDs.length == _contractAddresses.length, "Arrays length mismatch");
        require(_tokenIDs.length <= maxNFTsPerTransaction, "Exceeded maximum NFTs per transaction");

        //matic price for 1 NFT
        uint256 serviceChargePerNFTinETH = usdToEth(serviceChargePerNFT);
       
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];
            address _contractAddress = _contractAddresses[i];
            IERC721 nftContract = IERC721(_contractAddress);

            require(nftContract.ownerOf(_tokenID) == msg.sender, "Not the owner");

            // Transfer the NFT to the staking contract
            countOfMyStakedTokens[msg.sender]++;
            nftContract.safeTransferFrom(msg.sender, address(this), _tokenID);

            // Record the staking information
            stakedTokenOwner[_contractAddress][_tokenID] = msg.sender;
            tokenStakedTime[msg.sender][_contractAddress][_tokenID] = block.timestamp;

            // Record the staker
            stakers[countOfOverallStakers] = msg.sender;
            countOfOverallStakers++;
        }

         // Ensure the correct fee is sent
        uint256 totalServiceCharge;

        if(countOfMyStakedTokens[msg.sender] <= 50){      

        if (countOfMyStakedTokens[msg.sender] + _tokenIDs.length >= 50) { 

           totalServiceCharge = (50 - countOfMyStakedTokens[msg.sender]) * serviceChargePerNFTinETH * (10 ** (decimalCorrector2));
        } else {

            totalServiceCharge = (serviceChargePerNFTinETH * _tokenIDs.length) * (10 ** (decimalCorrector2));
        }

        } else {

            totalServiceCharge = 0;
        }
        require(msg.value >= totalServiceCharge, "Incorrect fee amount");
        
        // Transfer reward to the staker
        (bool rewardSuccess,) = payable(msg.sender).call{value: (usdToEth(rewardPerNFT) * _tokenIDs.length) * (10 ** (decimalCorrector2))}("");
        require(rewardSuccess, "Failed to transfer reward to the staker");
        }

        function usdToEth(uint256 amount) public view returns (uint256) {
        require(amount > 0, "Amount must be greater than 0");
        return (amount * 10**(decimalCorrector)) / getLatestPrice();
        }

        /**
        * Returns the latest price and # of decimals to use
        */
        function getLatestPrice() public view virtual returns (uint256) {
            int256 price;
            (, price, , , ) = priceFeed.latestRoundData();
            return uint256(price); // 0.78 * 10 ** 8 (USD/MATIC)
        }
    

    function unstakeNFTs(uint256[] memory _tokenIDs, address[] memory _contractAddresses) public onlyOwner {
        require(_tokenIDs.length == _contractAddresses.length, "Arrays length mismatch");

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];
            address _contractAddress = _contractAddresses[i];
            IERC721 nftContract = IERC721(_contractAddress); // Use a separate variable

            nftContract.safeTransferFrom(address(this), msg.sender, _tokenID);

            delete tokenStakedTime[msg.sender][_contractAddress][_tokenID];
            delete stakedTokenOwner[_contractAddress][_tokenID];

            for (uint256 j = 0; j < stakedTokens[msg.sender][_contractAddress].length; j++) {
                if (stakedTokens[msg.sender][_contractAddress][j] == _tokenID) {
                    stakedTokens[msg.sender][_contractAddress][j] = 0;
                    break;
                }
            }
        }
    }


    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setDecimalCorrector(uint256 _decimalCorrector) public onlyOwner {
        decimalCorrector = _decimalCorrector;
    }

    function setRewardPerNFT(uint256 _rewardPerNFT) public onlyOwner {
        rewardPerNFT = _rewardPerNFT;
    }

    function setDecimalCorrector2(uint256 _decimalCorrector2) public onlyOwner {
        decimalCorrector2 = _decimalCorrector2;
    }

    function setMaxNFTsPerTransaction(uint256 _maxNFTsPerTransaction) public onlyOwner {
        maxNFTsPerTransaction = _maxNFTsPerTransaction;
    }

    function setServiceChargePerNFT(uint256 _serviceChargePerNFT) public onlyOwner {
        serviceChargePerNFT = _serviceChargePerNFT;
    }

    function setPriceFeedAddress(address _priceFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function setNFTContract(address _nftContract) public onlyOwner {
        nft = IERC721(_nftContract);
    }

    function withdrawal() public onlyOwner {
        (bool main, ) = payable(owner()).call{value: address(this).balance}("");
        require(main, "Failed to withdraw funds");
    }

}