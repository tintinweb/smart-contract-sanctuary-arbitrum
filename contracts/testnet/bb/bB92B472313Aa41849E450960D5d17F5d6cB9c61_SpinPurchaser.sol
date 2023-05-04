// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external returns (uint);
}

contract SpinPurchaser {
    mapping(address => uint8) public spinsPurchased;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public isWhitelisted; //tokens have to be stablecoins

    uint256 public amountPerSpin;
    uint8 public maxSpins;

    address internal owner;
    address internal nft;
    bool public auctionStarted;

    event SpinPurchased(uint amount, uint timestamp);

    error Unauthorized();
    error InvalidToken();
    error InvalidAmount();
    error InvalidOwner();
    error SpinOverflowError();

    modifier onlyOwner() {
        if (msg.sender != owner) revert InvalidOwner();
        _;
    }

    constructor(
        uint256 _amountPerSpin,
        address[] memory _whitelistedTokens,
        address _owner,
        uint8 _maxSpins,
        address _nft
    ) {
        // //for testing ONLY
        // address[] memory _addresses,
        // uint8[] memory _amounts
        amountPerSpin = _amountPerSpin;
        owner = _owner;
        maxSpins = _maxSpins;
        for (uint index = 0; index < _whitelistedTokens.length; index++) {
            isWhitelisted[_whitelistedTokens[index]] = true;
        }
        // for (uint index = 0; index < _addresses.length; index++) {
        //     spinsPurchased[_addresses[index]] = _amounts[index];
        // }
        auctionStarted = false;
        nft = _nft;
    }

    function purchaseSpin(address _token, uint256 _amount) public {
        if (IERC721(nft).balanceOf(msg.sender) == 0) revert Unauthorized();
        if (!isWhitelisted[_token]) revert InvalidToken();
        uint256 _spinsPurchased = _amount / amountPerSpin;
        spinsPurchased[msg.sender] = uint8(
            spinsPurchased[msg.sender] + _spinsPurchased
        );
        if (spinsPurchased[msg.sender] > maxSpins) revert SpinOverflowError();
        uint256 amountWithoutOverflow = _spinsPurchased * amountPerSpin;
        IERC20(_token).transferFrom(
            msg.sender,
            address(this),
            amountWithoutOverflow
        );

        balanceOf[msg.sender] = balanceOf[msg.sender] + amountWithoutOverflow;

        donateUserAmountToAuction();

        emit SpinPurchased(amountWithoutOverflow, block.timestamp);
    }

    //if the user bought spins before the auction started, they can call this to put that amount towards the auction
    function donateUserAmountToAuction() public {
        uint256 totalAmountToDonate = balanceOf[msg.sender];
        if (totalAmountToDonate > 0 && auctionStarted) {
            //call code here to donate this amount towards the auction
            balanceOf[msg.sender] = 0;
        }
    }

    //----------Only callable by contract owner----------

    function setAuctionState(bool _auctionStarted) public onlyOwner {
        auctionStarted = _auctionStarted;
    }

    function setAmountPerSpin(uint256 _amount) public onlyOwner {
        if (_amount <= 0) revert InvalidAmount();
        amountPerSpin = _amount;
    }

    function setMaxSpins(uint8 _maxSpins) public onlyOwner {
        if (_maxSpins <= 0) revert InvalidAmount();
        maxSpins = _maxSpins;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setWhitelistedStatus(
        address[] memory _addresses,
        bool[] memory _statuses
    ) public onlyOwner {
        for (uint index = 0; index < _addresses.length; index++) {
            isWhitelisted[_addresses[index]] = _statuses[index];
        }
    }
}