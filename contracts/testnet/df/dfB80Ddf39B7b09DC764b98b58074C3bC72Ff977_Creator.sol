/**
 *Submitted for verification at Arbiscan.io on 2023-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Creator {
    // Owner for admin rights
    address public owner;
    uint256 public totalBooks;

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // Subscriber mapping
    mapping(address => address[]) subscriptions;

    // Books metadata
    struct bookMetadata {
        string name;
        uint16 year;
        uint16 totalChapters;
        chapterMetadata[] chapters;
    }
    // Books contain chapters
    struct chapterMetadata {
        uint16 chapterNumber;
        string[] imageCIDR;
    }
    mapping(uint256 => bookMetadata) books;

    // Any creator has the following fields
    struct userMetadata {
        string name;
        uint256[] books;
        uint256 numberOfSubscribers;
    }
    mapping(address => userMetadata) users;

    // Balances to store donations to creators
    mapping (address => uint) balances;

    //------------------------------ Modifiers ------------------------------
    modifier isOwner() {
        require(
            owner == msg.sender,
            "Unauthorized operation! You are not admin!"
        );
        _;
    }
    modifier userAlreadyHasAccount() {
        require(keccak256(abi.encodePacked(users[msg.sender].name))==keccak256(abi.encodePacked("")), "You already have an account!");
        _;
    }
    modifier userDoesNotHaveAccount(address _userAddress) {
        require(keccak256(abi.encodePacked(users[_userAddress].name))!=keccak256(abi.encodePacked("")), "You do not have an account!");
        _;
    }
    modifier alreadySubscribed(address _creator) {
        require(msg.sender!=_creator, "You cannot subscribe to yourself!");
        for (uint256 i = 0; i < subscriptions[_creator].length; i++) {
            require(
                subscriptions[_creator][i] != msg.sender,
                "You are already subscribed!"
            );
        }
        _;
    }
    modifier userHasDonations(address _creatorAdddress, uint _amount) {
        require(balances[_creatorAdddress]<=_amount, "You do not have an account!");
        _;
    }
    //------------------------------ Modifiers ------------------------------

    //------------------------------ Events emitted ------------------------------
    // User related
    event userOnboarded(address user, uint256 timestamp);
    event userSubscribed(address creator, address subscriber);
    // Book related
    event addedBook(address creator, uint256 bookId);
    event addedChapter(address creator, uint256 bookId, uint256 chapterId);
    // Payment related
    event donationMade(address creator, address trustee, uint amount);
    event donationsWithDrawn(address creator, uint amount);

    //------------------------------ Events emitted ------------------------------

    //------------------------------ Functions ------------------------------
    // For users
    function addUser(string memory _name) public userAlreadyHasAccount {
        users[msg.sender].name = _name;
        users[msg.sender].numberOfSubscribers = 0;
        emit userOnboarded(msg.sender, block.timestamp);
    }
    function subscribeToUser(address _creator) public alreadySubscribed(_creator) {
        subscriptions[_creator].push(msg.sender);
        users[_creator].numberOfSubscribers += 1;
        emit userSubscribed(_creator, msg.sender);
    }
    function getUserDetails(address _userAddress)
        public
        view
        userDoesNotHaveAccount(_userAddress)
        returns (userMetadata memory)
    {
        return users[_userAddress];
    }
    // For payments
    function dontateToCreator(address payable _creatorAddress) public payable {
        // transfer to contract
        payable(msg.sender).transfer(msg.value);
        // increase balances mapping
        balances[_creatorAddress] += msg.value;
        emit donationMade(_creatorAddress, msg.sender, msg.value);
    }
    function withdrawDonations(address payable _creatorAddress, uint _amount) public userHasDonations(_creatorAddress, _amount) payable {
        // transfer from contract
        address payable to = payable(msg.sender);
        to.transfer(_amount);
        // increase balances mapping
        balances[_creatorAddress] -= _amount;
        emit donationsWithDrawn(_creatorAddress, _amount);
    }

    // For books
    function getBookDetails(uint256 _bookId)
        public
        view
        returns (bookMetadata memory)
    {
        return books[_bookId];
    }
    function addBook(string memory _name, uint16 _year) public {
        books[totalBooks + 1].name = _name;
        books[totalBooks + 1].year = _year;
        books[totalBooks + 1].totalChapters = 0;
        totalBooks = totalBooks + 1;
        emit addedBook(msg.sender, totalBooks);
    }
    function addChapter(uint256 _bookId, string[] memory _CIDR) public {
        // chapterMetadata[] memory _cMetadata;
        books[_bookId].chapters[books[_bookId].totalChapters + 1] =  chapterMetadata({ chapterNumber: books[_bookId].totalChapters + 1, imageCIDR: _CIDR});
        books[_bookId].totalChapters += 1;
        emit addedChapter(msg.sender, _bookId, books[_bookId].totalChapters);
    }
    //------------------------------ Functions related to users ------------------------------
}