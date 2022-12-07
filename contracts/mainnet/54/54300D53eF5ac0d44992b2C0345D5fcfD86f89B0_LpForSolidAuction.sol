// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

interface IVeV2 {
    function locked(uint256) external view returns (int128 amount, uint256 end);

    function merge(uint256 _from, uint256 _to) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function split(uint256 _from, uint256 _amount) external returns (uint256);
}

interface IVeDistV2 {
    function claim(uint256 _tokenId) external returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}

contract LpForSolidAuction {
    // addresses
    address public owner;
    IVeV2 public ve;
    IVeDistV2 public veDist;

    // Auction states
    struct AuctionData {
        uint128 solidAmount; // Total amount of SOLID to be auctioned
        uint128 minLpBid; // Minimum amount of LP for the auction
        uint128 lpBids;
        uint128 startingExpansionFactor; // SOLID expansion ratio when the auction was made
        address lpToken;
        bool cancelled;
        uint40 auctionStart;
        uint40 auctionEnd;
        uint40 lockEnd;
    }
    mapping(address => uint256[]) public tokenToAuctionDataIndex; // lp address => auction indices
    AuctionData[] public auctionData; // index => auction data

    // User states
    mapping(uint256 => mapping(address => uint256)) public userBids; // auction index => user address => user bid amount
    mapping(uint256 => mapping(address => bool)) public userClaimed; // auction index => user address => user claimed

    // veNFT states
    uint256 public primaryTokenId;
    uint256 public allocatedSolid;
    uint256 public lastExpansionClaimPeriod;
    uint256 public expansionFactor = 1e18;
    bool internal _receiving;

    // Simple re-entracy check
    uint256 internal _unlocked = 1;

    /**************************************** 
                    Events
     ****************************************/
    event DepositVeNFT(uint256 amount);

    event RecoverVeNFT(uint256 amount);

    event ClaimExpansion(
        uint256 amount,
        uint256 expansionFactorBefore,
        uint256 expansionFactorAfter
    );

    event NewAuction(
        uint256 indexed auctionIndex,
        address indexed lpToken,
        uint256 solidAmount,
        uint256 lpThreshold,
        uint256 auctionStart,
        uint256 auctionEnd,
        uint256 lockEnd
    );

    event CancelAuction(uint256 indexed auctionIndex, address indexed lpToken);

    event PlaceBid(
        address indexed bidder,
        uint256 indexed auctionIndex,
        address indexed lpToken,
        uint256 amount
    );

    event RevokeBid(
        address indexed bidder,
        uint256 indexed auctionIndex,
        address indexed lpToken,
        uint256 amount
    );

    event Claim(
        address indexed bidder,
        uint256 indexed auctionIndex,
        address indexed lpToken,
        uint256 amount
    );

    event Withdraw(
        address indexed bidder,
        uint256 indexed auctionIndex,
        address indexed lpToken,
        uint256 amount
    );

    /**************************************** 
                   Constructor
     ****************************************/

    constructor(IVeV2 _ve, IVeDistV2 _veDist) {
        owner = msg.sender;
        ve = _ve;
        veDist = _veDist;
    }

    /**************************************** 
                    Modifiers
     ****************************************/

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Allows the contract to receive veNFTs
    modifier allowNftDeposit() {
        _receiving = true;
        _;
        _receiving = false;
    }

    // simple re-entrancy check
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    /**************************************** 
                   View Methods
     ****************************************/

    function tokenToAuctionDataIndexList(address lpToken)
        external
        view
        returns (uint256[] memory)
    {
        return tokenToAuctionDataIndex[lpToken];
    }

    /**************************************** 
                Authorized Methods
     ****************************************/

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function depositVeNft(uint256 tokenId) external onlyOwner allowNftDeposit {
        // transfer veNFT
        ve.safeTransferFrom(msg.sender, address(this), tokenId);
        (int256 _delta, ) = ve.locked(tokenId);

        // set primaryTokenId if not set
        if (primaryTokenId == 0) {
            primaryTokenId = tokenId;
        }

        // merge veNFTs if not primary
        if (primaryTokenId != tokenId) {
            ve.merge(tokenId, primaryTokenId);
        }

        emit DepositVeNFT(uint256(_delta));
    }

    function recoverVeNft(uint256 amount) external onlyOwner {
        // Check if recovery amount eats into allocated amounts
        uint256 locked = _locked();
        require(locked - amount >= allocatedSolid, "Too much SOLID allocated");

        // Split off a veNFT if amount < locked, transfer whole veNFT if amount = locked
        if (amount < locked) {
            uint256 splitTokenId = _split(amount);
            ve.safeTransferFrom(address(this), msg.sender, splitTokenId);
        } else {
            ve.safeTransferFrom(address(this), msg.sender, primaryTokenId);
            primaryTokenId = 0;
        }

        emit RecoverVeNFT(amount);
    }

    function newAuction(
        address lpToken,
        uint256 solidAmount,
        uint256 lpThreshold,
        uint256 startTime,
        uint256 auctionDuration,
        uint256 lockDuration
    ) external onlyOwner {
        // Check if there's enough SOLID for the auction
        uint256 _totalLocked = _locked();
        require(
            _totalLocked - allocatedSolid >= solidAmount,
            "Not enough SOLID locked for this auction"
        );

        // Check if auction is in the future
        require(startTime > block.timestamp, "Start time too early");

        // Increment allocatedSolid
        allocatedSolid += solidAmount;

        // Record auction data
        uint40 _auctionEnd = uint40(startTime + auctionDuration);
        uint40 _lockEnd = uint40(_auctionEnd + lockDuration);
        AuctionData memory _auctionData = AuctionData({
            solidAmount: uint128(solidAmount),
            minLpBid: uint128(lpThreshold),
            lpBids: 0,
            startingExpansionFactor: uint128(expansionFactor),
            lpToken: lpToken,
            auctionStart: uint40(startTime),
            auctionEnd: _auctionEnd,
            lockEnd: _lockEnd,
            cancelled: false
        });

        uint256 auctionIndex = auctionData.length;
        tokenToAuctionDataIndex[lpToken].push(auctionIndex);
        auctionData.push(_auctionData);

        emit NewAuction(
            auctionIndex,
            lpToken,
            solidAmount,
            lpThreshold,
            startTime,
            _auctionEnd,
            _lockEnd
        );
    }

    function cancelAuction(uint256 auctionIndex) external onlyOwner {
        // Load states into memory
        AuctionData memory _auctionData = auctionData[auctionIndex];

        // Check auction states
        require(
            block.timestamp < _auctionData.auctionEnd,
            "Auction already ended"
        );
        require(!_auctionData.cancelled, "Auction already cancelled");

        // Update auction state
        auctionData[auctionIndex].cancelled = true;

        // Update global state
        allocatedSolid -=
            (_auctionData.solidAmount * expansionFactor * 1e18) /
            _auctionData.startingExpansionFactor /
            1e18;

        emit CancelAuction(auctionIndex, _auctionData.lpToken);
    }

    function cancelUnsuccessfulAuction(uint256 auctionIndex)
        external
        onlyOwner
    {
        // Load states into memory
        AuctionData memory _auctionData = auctionData[auctionIndex];

        // Check auction states
        require(!_auctionData.cancelled, "Auction cancelled");
        require(block.timestamp > _auctionData.auctionEnd, "Auction not ended");
        require(
            _auctionData.lpBids < _auctionData.minLpBid,
            "Auction was successful"
        );

        // Update auction state
        auctionData[auctionIndex].cancelled = true;

        // Update global state
        allocatedSolid -=
            (_auctionData.solidAmount * expansionFactor * 1e18) /
            _auctionData.startingExpansionFactor /
            1e18;

        emit CancelAuction(auctionIndex, _auctionData.lpToken);
    }

    /**************************************** 
              Maintenance Methods
     ****************************************/

    /**
     * @notice Claims anti-dilution expansion for the veNFT
     */
    function claimExpansion() public {
        // Record locked amounts before, claim, record locked amounts after
        uint256 lockedBefore = _locked();
        veDist.claim(primaryTokenId);
        uint256 lockedAfter = _locked();

        // Calculate ratio change
        uint256 ratio = (lockedAfter * 1e18) / lockedBefore;

        // Apply ratio change to expansionFactor
        uint256 _expansionFactorBefore = expansionFactor;
        expansionFactor = (_expansionFactorBefore * ratio) / 1e18;

        // Apply ratio change to allocatedSolid
        allocatedSolid = (allocatedSolid * ratio) / 1e18;

        emit ClaimExpansion(
            lockedAfter - lockedAfter,
            _expansionFactorBefore,
            expansionFactor
        );
    }

    /**************************************** 
                  User Interaction
     ****************************************/

    /**
     * @notice Users can place bids before the auction is finalized
     */
    function placeBid(uint256 auctionIndex, uint256 amount) external lock {
        // Load states into memory
        AuctionData memory _auctionData = auctionData[auctionIndex];

        // Check auction states
        require(!_auctionData.cancelled, "Auction cancelled");
        require(
            block.timestamp > _auctionData.auctionStart,
            "Auction not started"
        );
        require(block.timestamp < _auctionData.auctionEnd, "Auction ended");

        // Transfer lp tokens
        _safeTransferFrom(
            _auctionData.lpToken,
            msg.sender,
            address(this),
            amount
        );

        // Record user data
        userBids[auctionIndex][msg.sender] += amount;

        // Update auction states
        auctionData[auctionIndex].lpBids =
            _auctionData.lpBids +
            uint128(amount);

        emit PlaceBid(msg.sender, auctionIndex, _auctionData.lpToken, amount);
    }

    /**
     * @notice Users can revoke bids before the auction is finalized
     */
    function revokeBid(uint256 auctionIndex, uint256 amount) external lock {
        // Load states into memory
        AuctionData memory _auctionData = auctionData[auctionIndex];

        // Check auction states
        require(
            !_auctionData.cancelled,
            "Auction cancelled, withdraw() instead"
        );
        require(block.timestamp < _auctionData.auctionEnd, "Auction ended");

        // Update user data
        userBids[auctionIndex][msg.sender] -= amount; // This step checks whether the user has enough lp deposited

        // Update auction states
        auctionData[auctionIndex].lpBids =
            _auctionData.lpBids -
            uint128(amount);

        // Transfer lp tokens
        _safeTransferFrom(
            _auctionData.lpToken,
            msg.sender,
            address(this),
            amount
        );

        emit RevokeBid(msg.sender, auctionIndex, _auctionData.lpToken, amount);
    }

    /**
     * @notice Claim veNFT if an auction was successful
     */
    function claim(uint256 auctionIndex) external lock {
        // Load states into memory
        AuctionData memory _auctionData = auctionData[auctionIndex];

        // Check auction states
        require(!_auctionData.cancelled, "Auction cancelled");
        require(
            block.timestamp > _auctionData.auctionEnd,
            "Auction not finalized"
        );
        require(
            _auctionData.lpBids >= _auctionData.minLpBid,
            "Minimum bid not met, withdraw instead"
        );

        // Fetch user data
        uint256 bidAmount = userBids[auctionIndex][msg.sender];

        // Check user states
        require(!userClaimed[auctionIndex][msg.sender], "Already claimed");
        require(bidAmount > 0, "No bid");

        // Update user states
        userClaimed[auctionIndex][msg.sender] = true;

        // Amount of SOLID to split off, accounts for anti-dilution expansions
        uint256 amount = (_auctionData.solidAmount *
            expansionFactor *
            bidAmount *
            1e18) /
            _auctionData.lpBids /
            _auctionData.startingExpansionFactor /
            1e18;

        // Update global states
        allocatedSolid -= amount;

        // Split and send user veNFT
        uint256 splitTokenId = _split(amount);
        ve.safeTransferFrom(address(this), msg.sender, splitTokenId);

        emit Claim(msg.sender, auctionIndex, _auctionData.lpToken, amount);
    }

    /**
     * @notice withdraw LP tokens after locking period ends or if an auction was not successful
     */
    function withdraw(uint256 auctionIndex) external lock {
        // Load states into memory
        AuctionData memory _auctionData = auctionData[auctionIndex];

        // Check auction states
        if (!_auctionData.cancelled) {
            require(
                block.timestamp > _auctionData.auctionEnd,
                "Auction not finalized, revokeBid() instead"
            );
            if (_auctionData.lpBids >= _auctionData.minLpBid) {
                require(
                    block.timestamp > _auctionData.lockEnd &&
                        userClaimed[auctionIndex][msg.sender],
                    "Lock end not reached"
                );
            }
        }

        // Fetch user data
        uint256 amount = userBids[auctionIndex][msg.sender];

        // Update user data
        userBids[auctionIndex][msg.sender] = 0;

        // Send LP tokens to user
        if (amount > 0) {
            _safeTransfer(_auctionData.lpToken, msg.sender, amount);
            emit Withdraw(
                msg.sender,
                auctionIndex,
                _auctionData.lpToken,
                amount
            );
        }
    }

    /**************************************** 
                Internal Methods
     ****************************************/

    function _locked() internal view returns (uint256) {
        (int256 locked, ) = ve.locked(primaryTokenId);
        return uint256(locked); //SafeCast not needed since locked can't be <0
    }

    function _split(uint256 amount) internal allowNftDeposit returns (uint256) {
        uint256 splitTokenId = ve.split(primaryTokenId, amount);
        return splitTokenId;
    }

    /**************************************** 
                     ERC721
     ****************************************/

    /**
     * @notice Mandatory ERC721 receiver
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if (_receiving) {
            return this.onERC721Received.selector;
        } else {
            revert("Do not send veNFT directly");
        }
    }

    /**************************************** 
                    Safe ERC20
     ****************************************/

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}